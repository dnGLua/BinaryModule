# .NET Garry's Mod Lua Binary Module

A god-tier project template for developing cross-platform C# Garry's Mod (Lua) binary modules, built with .NET 10 and
CMake, featuring .NET NativeAOT (ahead-of-time compilation) and direct native interop with static/shared native C
library from C#... This is still WIP, but You are welcome to use it...

## Build System

This project uses a modern cross-platform build system:

- **Native Library**: Built with CMake
- **Managed Code**: Built with .NET SDK (`dotnet`)
- **Build Scripts**: PowerShell (`pwsh`)

### MSBuild Properties

The project supports several configurable MSBuild properties that can be set in the project file (.csproj) or passed via
command-line:

| Property                  | Default | Description                                                        |
|---------------------------|---------|--------------------------------------------------------------------|
| `IsClientModule`          | `true`  | Whether this is a client-side module (defines `CLIENT` constant)   |
| `DisableOptimization`     | `false` | Whether to disable code optimizations                              |
| `DisablePdb`              | `false` | Whether to disable PDB generation                                  |
| `BuildNativeLibrary`      | `false` | Whether to build the native C library (set to `true` to build)     |
| `CompileMyNativeLibAsDll` | `true`  | Whether to compile native library as DLL instead of static library |

#### Usage Examples

```xml

<PropertyGroup>
  <!-- Build the 'mynativelib' library -->
  <BuildNativeLibrary>true</BuildNativeLibrary>
  <!-- Compile it as static library instead of DLL (requires BuildNativeLibrary and PublishAot) -->
  <CompileMyNativeLibAsDll>false</CompileMyNativeLibAsDll>
</PropertyGroup>
```

## Conditional Compilation Constants

The project defines several constants that can be used for conditional compilation in C# code:

| Constant     | When Defined                     | Usage                                                 |
|--------------|----------------------------------|-------------------------------------------------------|
| `CLIENT`     | If IsClientModule is set to true | `#if CLIENT` for client-side code                     |
| `SERVER`     | When IsClientModule is false     | `#if SERVER` for server-side code                     |
| `NATIVE_AOT` | When building with `-Type aot`   | `#if NATIVE_AOT` to distinguish AOT vs managed builds |
| `X64`        | When building for x64 platform   | `#if X64` for platform-specific code                  |
| `X86`        | When building for x86 platform   | `#if X86` for platform-specific code                  |
| `WINDOWS`    | When building Windows version    | `#if WINDOWS` for OS-specific code                    |
| `LINUX`      | When building Linux version      | `#if LINUX` for OS-specific code                      |
| `MACOS`      | When building macOS version      | `#if MACOS` for OS-specific code                      |

#### Example Usage

```csharp
public static void M()
{
#if CLIENT
#if NATIVE_AOT
    // NativeAOT client-side code
#else
    // Managed client-side code
#endif
#else
    // Server-side code (when IsClientModule=false)
#endif

#if WINDOWS
    // Windows-specific code
#elif LINUX
    // Linux-specific code
#elif MACOS
    // macOS-specific code
#endif
}
```

## Build Script Features

### build-module.ps1 - C# Binary Module Builder

Builds the C# binary module with support for AOT and managed compilation.

#### Parameters

| Parameter | Short Form | Description                           | Values                             |
|-----------|------------|---------------------------------------|------------------------------------|
| `-Type`   | `-t`       | Build type (case-insensitive)         | `aot`, `managed`, `both` (default) |
| `-Clean`  | `-c`       | Clean build artifacts before building | Switch parameter                   |
| `-Help`   |            | Show help information                 | Switch parameter                   |

#### Key Features

- **Case-insensitive build types**: Use `AOT`, `aot`, `Managed`, `managed`, etc.
- **Short form parameters**: Use `-t` for `-Type` and `-c` for `-Clean`
- **Smart clean behavior**: `-Clean` alone only cleans, `-Clean` with `-Type` cleans then builds
- **Selective building**: Build only AOT or only managed versions as needed
- **Automatic cleanup**: Cleans all build artifacts including `bin-aot/`, `bin-managed/`, and `obj/` directories

#### Usage Examples

```powershell
# Build both AOT and managed modules
./build-module.ps1

# Build specific module type (case-insensitive)
./build-module.ps1 -t aot
./build-module.ps1 -t managed
./build-module.ps1 -t AOT        # Case-insensitive
./build-module.ps1 -Type Managed # Case-insensitive

# Clean only (no build)
./build-module.ps1 -c
./build-module.ps1 -Clean

# Clean then build specific type
./build-module.ps1 -t aot -c
./build-module.ps1 -t managed -c
```

### build-native.ps1 - Native Library Builder

Builds the native C library using CMake with cross-platform support (optional, if you want to experiment with
static/shared C library).

#### Parameters

| Parameter     | Short Form        | Description                                      | Values                        |
|---------------|-------------------|--------------------------------------------------|-------------------------------|
| `-Platforms`  | `-p`, `-Platform` | Build specific platforms only (case-insensitive) | See supported platforms below |
| `-Clean`      |                   | Clean up all build files and artifacts           | Switch parameter              |
| `-StaticOnly` |                   | Build only static libraries                      | Switch parameter              |
| `-SharedOnly` |                   | Build only shared libraries                      | Switch parameter              |
| `-Help`       |                   | Show help information                            | Switch parameter              |

#### Supported Platforms

| Platform      | Short Form | Description          |
|---------------|------------|----------------------|
| `windows-x64` | `win-x64`  | Windows 64-bit       |
| `windows-x86` | `win-x86`  | Windows 32-bit       |
| `linux-x64`   |            | Linux 64-bit         |
| `osx-x64`     |            | macOS 64-bit (Intel) |

#### Key Features

- **Cross-platform support**: Works on Windows, Linux, and macOS
- **Auto-detection**: Automatically detects current platform and available architectures
- **Multiple platform builds**: Can build for multiple platforms in one command
- **Library type control**: Build static only, shared only, or both
- **Compiler detection**: Automatically detects and prefers GCC over Clang on Linux/macOS
- **Hidden build directories**: Uses `.build-*` directories to keep project clean
- **Case-insensitive platforms**: Use `WINDOWS-X64`, `linux-x64`, etc.

#### Platform Detection

The script automatically detects platforms:

- **Windows x64**: Builds both `windows-x64` and `windows-x86`
- **Windows x86**: Builds only `windows-x86`
- **Linux**: Builds for current architecture (x64)
- **macOS**: Builds for current architecture (x64)

#### Usage Examples

```powershell
# Build detected platforms (by default builds static + shared)
./build-native.ps1

# Build specific platforms (case-insensitive)
./build-native.ps1 -Platforms windows-x64,linux-x64,osx-x64
./build-native.ps1 -Platform WINDOWS-X64,LINUX-X64,OSX-X64
./build-native.ps1 -p windows-x64,linux-x64,osx-x64
./build-native.ps1 -p WIN-X64,win-x86  # Short platform names, mixed case

# Build only static or shared libraries
./build-native.ps1 -StaticOnly
./build-native.ps1 -SharedOnly

# Build specific platforms with library type control (case-insensitive)
./build-native.ps1 -p LINUX-X64 -StaticOnly
./build-native.ps1 -p windows-x64,win-x86 -SharedOnly

# Clean up all build files and artifacts
./build-native.ps1 -Clean
```

## Quick Start

### Prerequisites

**Windows:**

- Visual Studio 2022/2026 with Windows 10/11 SDK and build tools (C++ workload)
- .NET 10 SDK
- PowerShell 7+ (pwsh)
- Garry's Mod (and a pair of hands)

**Linux / macOS:**

- GCC (preferred) or Clang
- .NET 10 SDK
- PowerShell 7+ (pwsh)
- Garry's Mod (and a pair of hands)

### Building

```powershell
# Build C# binary module (both AOT and managed)
./build-module.ps1

# Build native library (detected platforms)
./build-native.ps1

# For more options and examples, see the Build Script Features section above
```

## Project Structure

```
├── dnGLua.BinaryModule/
│   ├── dnGLua.BinaryModule.csproj  # C# MSBuild project
│   ├── Main.cs                 # Main C# code, binary module entry-point
│   └── GlobalUsings.cs         # Global using statements
├── mynativelib/                # C native library
│   └── mynativelib.c           # Example native C source code
├── .build-*/                   # Intermediate build directory for native library
├── CMakeLists.txt              # CMake configuration for native C library
├── build-native.ps1            # Cross-platform native library build script
├── build-module.ps1            # Unified AOT and managed module build script
├── bin-aot/                    # AOT binary module output directory
├── bin-managed/                # Managed binary module output directory
└── artifacts/                  # Native reference directory
    └── runtimes/
        ├── win-x64/native/
        ├── win-x86/native/
        ├── linux-x64/native/
        └── osx-x64/native/
```

## Native Library Build

The CMake build system automatically:

- Detects the platform and architecture
- Auto-selects compiler (GCC preferred, then Clang on Linux/macOS)
- Configures appropriate compiler settings
- Outputs libraries to the correct `artifacts/runtimes/` directory
- Supports both static and shared library builds
- On Windows x64: Builds both x86 and x64 versions
- Creates hidden build directories in project root (`.build-*`) to keep `mynativelib/` clean
- CMakeLists.txt is located in project root for easier access

### Supported Platforms

- **Windows**: x64, x86* (MSVC, Visual Studio 2022/2026)
- **Linux / macOS**: x64 (GCC preferred, then Clang)

Note: NativeAOT compilation is not supported for 32-bit Windows/GMod (x86) - this is a .NET limitation (use 'managed'
version instead).

## Managed Code Build

The simplified MSBuild project:

- Uses modern .NET SDK style project
- Supports cross-platform building
- Automatically links with pre-built native library
- Generates assembly with proper Garry's Mod binary module naming

### Output Files

Note: Garry's Mod Lua binary modules always use the `.dll` file extension regardless of platform.

| Platform       | Client Module               | Server Module               |
|----------------|-----------------------------|-----------------------------|
| Windows 64-bit | `gmcl_mymodule_win64.dll`   | `gmsv_mymodule_win64.dll`   |
| Windows 32-bit | `gmcl_mymodule_win32.dll`   | `gmsv_mymodule_win32.dll`   |
| Linux 64-bit   | `gmcl_mymodule_linux64.dll` | `gmsv_mymodule_linux64.dll` |
| macOS 64-bit   | `gmcl_mymodule_osx64.dll`   | `gmsv_mymodule_osx64.dll`   |

## Development

### Adding Native Functions & Calling Static/Shared C Code From C# Code

1. Edit `mynativelib/mynativelib.c`
2. Rebuild native library with `build-native.ps1`
3. Rebuild binary module with `build-module.ps1`

### Adding NuGet Dependencies & Registering GMod Lua Functions

1. (TODO: write a guide)
2. Rebuild binary module with `build-module.ps1`

## Troubleshooting

### Module Loading Issues

- Ensure you build the binary module using the same target architecture as your Garry's Mod process/branch (x64 vs
  x86/Win32)
- Ensure you install it correctly by copying all relevant files into `.../garrysmod/lua/bin` folder (create the `bin`
  folder if you don't have it), it's helpful to use symlink for smoother experience "auto-update on build" (Google it)
- Ensure you don't rename the binary module file, it has to follow the Garry's Mod binary module naming convention
- Ensure you don't modify/break the csproj/msbuild code by accident
- Ensure you have the correct permissions to access the `.../garrysmod/lua/bin` folder

### Native Build Issues

- **Windows**: Ensure Visual Studio 2022/2026 with Windows 10/11 SDK and C++ build tools are installed
- **Linux**: Install `build-essential` or equivalent (GCC preferred)
- **macOS**: Install Xcode Command Line Tools: `xcode-select --install` (GCC preferred via Homebrew)
- **Build directories**: Build artifacts are stored in hidden `.build-*` directories in the project root, not in
  `mynativelib/`
- **Platform-specific issues**: Use `./build-native.ps1 -Help` to see supported platforms and options
- **Compiler detection**: Script automatically prefers GCC over Clang on Linux/macOS; install GCC if build fails
- **Multiple platforms**: When building for multiple platforms, ensure all required toolchains are installed

### Managed Build Issues

- Ensure .NET 10 SDK is installed
- Run `dotnet restore --force` before building
- Optionally, check that native library exist in `artifacts/runtimes/`
- Use `./build-module.ps1 -Help` to see all available options
- If build produces both `bin-aot` and `bin-managed` when you only want one, ensure you're specifying the correct
  `-Type` parameter
- Use `./build-module.ps1 -c` to clean all build artifacts including output directories
