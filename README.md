# Optimized_Plugin

Optimized_Plugin is a metaprogram plugin for the Jai language that improves Windows executable builds by switching to the RAD linker (radlink) from [raddebugger](https://github.com/EpicGames/raddebugger) and enforcing static runtime linking.

It focuses on producing faster-to-build, more portable, and less dependency-heavy executables.

## Features

- Uses the RAD linker (radlink) instead of MSVC link.exe (you must have radlink.exe in PATH)
- Forces static linking of Windows runtimes: (ucrt, vcruntime, msvcrt, msvcprt)
- Reduces dependency on external runtime DLLs
- Produces self-contained Windows .exe files
- Applies aggressive optimization flags during build
- Simplifies build invocation through Jai plugin syntax

## Usage

*First yout have to put Optimize.jai in* ***modules***

Enable the plugin during compilation:
```console
jai main.jai +Optimize
```

## Disclamer

Only works on Windows!

Not Everyone NEEDS it.
