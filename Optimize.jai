
get_plugin :: inline () -> *Metaprogram_Plugin { return *plugin; }

#scope_file

plugin: struct {
    #as using base: Metaprogram_Plugin;
    base.before_intercept  = before_intercept;
    base.message           = message;
};

crt_lib_to_static :: inline (original: string) -> string {
    if original == {
        case "ucrt.lib";       return "libucrt.lib";
        case "ucrtd.lib";      return "libucrtd.lib";
        case "vcruntime.lib";  return "libvcruntime.lib";
        case "vcruntimed.lib"; return "libvcruntimed.lib";
        case "msvcrt.lib";     return "libcmt.lib";
        case "msvcrtd.lib";    return "libcmtd.lib";
        case "msvcprt.lib";    return "libcpmt.lib";
        case "msvcprtd.lib";   return "libcpmtd.lib";
    }
    return original;
}

before_intercept :: inline (p: *Metaprogram_Plugin, _: *Intercept_Flags) {
    opts := get_build_options(p.workspace);
    assert(opts.os_target == .WINDOWS);
    assert(opts.cpu_target == .X64);
    opts.backend = .LLVM;
    opts.use_custom_link_command = true;
    opts.max_bytecode_instructions_for_inlined_initializer = 32;
    opts.x64_options.enable_unix_runtime_frame_information = false;
    opts.llvm_options.bitcode_optimization_setting         = .O3;
    opts.llvm_options.machine_code_optimization_setting    = .AGGRESSIVE;
    opts.array_bounds_check                                = .OFF;
    opts.cast_bounds_check                                 = .OFF;
    opts.null_pointer_check                                = .OFF;
    opts.arithmetic_overflow_check                         = .OFF;
    opts.shorten_filenames_in_error_messages               = true;
    opts.enable_bytecode_inliner                           = true;
    opts.enable_bytecode_deduplication                     = false;
    opts.runtime_support_definitions                       = .ENTRY_POINT_AND_INIT;
    opts.llvm_options.function_sections                    = true;
    opts.llvm_options.enable_tail_calls                    = true;
    opts.llvm_options.enable_loop_unrolling                = true;
    opts.llvm_options.enable_slp_vectorization             = true;
    opts.llvm_options.enable_loop_vectorization            = true;
    opts.llvm_options.preserve_debug_info                  = false;
    opts.llvm_options.merge_functions                      = true;
    opts.llvm_options.disable_inlining                     = false;
    opts.llvm_options.enable_split_modules                 = false;
    opts.stack_trace                                       = false;
    opts.use_ansi_color                                    = false;
    opts.enable_frame_pointers                             = false;
    opts.backtrace_on_crash                                = .OFF;
    opts.dead_code_elimination                             = .ALL;
    opts.emit_debug_info                                   = .NONE;
    set_build_options(opts, p.workspace);
}

message :: inline (p: *Metaprogram_Plugin, message: *Message) {
    opts := get_build_options(p.workspace);
    add :: inline (a: *[]string, x: string) {
        assert(a.count < 1024);
        a.count += 1;
        a.*[a.count - 1] = x;
    }
    if message.kind == {
    case .PHASE;
        phase_message := message.(*Message_Phase);
        phase := phase_message.phase;
        if phase == .READY_FOR_CUSTOM_LINK_COMMAND {
            arguments: []string = .{ 0, ARGUMENTS.data };
            add(*arguments, "lld-link.exe");
            add(*arguments, "/nologo");
            for phase_message.compiler_generated_object_files add(*arguments, it);
            for phase_message.support_object_files add(*arguments, it);
            add(*arguments, tprint("/OUT:%1%2.exe", opts.output_path, opts.output_executable_name));
            add(*arguments, "/MACHINE:AMD64");
            add(*arguments, "/INCREMENTAL:NO");
            add(*arguments, "/OPT:REF");
            add(*arguments, "/OPT:ICF");
            add(*arguments, "/RELEASE");
            add(*arguments, "/LTCG");
            add(*arguments, "/DEBUG:NONE");
            add(*arguments, "/SUBSYSTEM:WINDOWS");
            add(*arguments, "/ENTRY:mainCRTStartup");
            {
                vc_path := find_visual_studio_in_a_ridiculous_garbage_way();
                assert(vc_path.count > 1);
                add(*arguments, tprint("/libpath:\"%\"", vc_path));
                kit_root, windows_version := find_windows_kit_root();
                assert(kit_root.count > 1);
                add(*arguments, tprint("/libpath:\"%/um/x64\"", kit_root));
                add(*arguments, tprint("/libpath:\"%/ucrt/x64\"", kit_root));
                add(*arguments, "/nodefaultlib");
            }
            for phase_message.system_libraries add(*arguments, crt_lib_to_static(it));
            for phase_message.user_libraries add(*arguments, it);
            print("Link line: %\n", get_quoted_command_string(arguments));
            process_result, _, error_string, _ := run_command(..arguments);
            assert(!process_result.exit_code, error_string);
            compiler_custom_link_command_is_complete(p.workspace);
        }
    }
}

nothing :: inline (_: *Metaprogram_Plugin) { }

ARGUMENTS: [1024]string;

#import "Compiler";
#import "Basic";
#import "Windows_Resources";
#import "Process";