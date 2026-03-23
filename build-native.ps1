#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Cross-platform native library build script using CMake
.DESCRIPTION
    Builds the native library for all supported platforms using CMake
    Works on Windows, Linux, and macOS
#>

param(
  [Alias('p')]
  [Alias('Platform')]
  [string[]]$Platforms = @(),
  [switch]$Clean,
  [switch]$StaticOnly,
  [switch]$SharedOnly,
  [switch]$Help
)

function Show-Help
{
  Write-Host "Usage: ./build-native.ps1 [OPTIONS]"
  Write-Host ""
  Write-Host "Options:"
  Write-Host "  -Platforms <string[]>    Build specific platforms only (case-insensitive: windows-x64, windows-x86, win-x64, win-x86, linux-x64, linux-arm64, osx-x64, osx-arm64)"
  Write-Host "  -Platform <string[]>     Alias for Platforms parameter"
  Write-Host "  -p <string[]>            Short alias for Platforms parameter"
  Write-Host "  -Clean                   Clean up all build files and compiled artifacts (exit after cleaning)"
  Write-Host "  -StaticOnly              Build only static libraries (default: build both)"
  Write-Host "  -SharedOnly              Build only shared libraries (default: build both)"
  Write-Host "  -Help                    Show this help message"
  Write-Host ""
  Write-Host "Examples:"
  Write-Host "  ./build-native.ps1                    # Build both static and shared libraries for detected platforms"
  Write-Host "  ./build-native.ps1 -StaticOnly        # Build only static libraries for detected platforms"
  Write-Host "  ./build-native.ps1 -SharedOnly        # Build only shared libraries for detected platforms"
  Write-Host "  ./build-native.ps1 -Platforms windows-x64,linux-x64,osx-x64"
  Write-Host "  ./build-native.ps1 -Platform WINDOWS-X64,LINUX-X64,OSX-X64  # Case-insensitive"
  Write-Host "  ./build-native.ps1 -p windows-x64,linux-x64,osx-x64"
  Write-Host "  ./build-native.ps1 -p win-x64,win-x86  # Short platform names"
  Write-Host "  ./build-native.ps1 -Clean              # Clean up all build files and artifacts"
  Write-Host ""
  Write-Host "Platform Detection:"
  Write-Host "  Windows x64: Builds both windows-x64 and windows-x86"
  Write-Host "  Windows x86: Builds only windows-x86"
  Write-Host "  Linux: Builds for current architecture (GCC preferred, then Clang)"
  Write-Host "  macOS: Builds for current architecture (GCC preferred, then Clang)"
}

function Normalize-PlatformName
{
  param([string]$Platform)

  switch ( $Platform.ToLower())
  {
    "win-x86" {
      return "windows-x86"
    }
    "win-x64" {
      return "windows-x64"
    }
    "windows-x86" {
      return "windows-x86"
    }
    "windows-x64" {
      return "windows-x64"
    }
    "linux-x64" {
      return "linux-x64"
    }
    "linux-arm64" {
      return "linux-arm64"
    }
    "osx-x64" {
      return "osx-x64"
    }
    "osx-arm64" {
      return "osx-arm64"
    }
    default {
      return $Platform.ToLower()
    }
  }
}

function Get-CurrentPlatform
{
  # Auto-detect current platform and architecture
  if ($IsWindows)
  {
    $arch = if ([Environment]::Is64BitOperatingSystem)
    {
      "x64"
    }
    else
    {
      "x86"
    }
    return "windows-$arch"
  }
  elseif ($IsLinux)
  {
    $arch = $( uname -m )
    switch ($arch)
    {
      "x86_64" {
        return "linux-x64"
      }
      "aarch64" {
        return "linux-arm64"
      }
      "armv7l" {
        return "linux-arm"
      }
      default {
        return "linux-x64"
      }
    }
  }
  elseif ($IsMacOS)
  {
    $arch = $( uname -m )
    switch ($arch)
    {
      "x86_64" {
        return "osx-x64"
      }
      "arm64" {
        return "osx-arm64"
      }
      default {
        return "osx-x64"
      }
    }
  }
  else
  {
    throw "Unsupported operating system"
  }
}

function Get-DefaultPlatforms
{
  # Get default platforms to build (auto-detected behavior)
  if ($IsWindows)
  {
    if ([Environment]::Is64BitOperatingSystem)
    {
      # On x64 Windows, build both x86 and x64
      return @("windows-x64", "windows-x86")
    }
    else
    {
      # On x86 Windows, only build x86
      return @("windows-x86")
    }
  }
  elseif ($IsLinux)
  {
    $platforms = @("linux-x64")
    $arch = $( uname -m )
    if ($arch -eq "aarch64")
    {
      $platforms += "linux-arm64"
    }
    return $platforms
  }
  elseif ($IsMacOS)
  {
    $platforms = @("osx-x64")
    $arch = $( uname -m )
    if ($arch -eq "arm64")
    {
      $platforms += "osx-arm64"
    }
    return $platforms
  }
  else
  {
    throw "Unsupported operating system"
  }
}

function Get-SupportedPlatforms
{
  # Get all platforms supported on current system
  $platforms = @()
  if ($IsWindows)
  {
    # Always include both x64 and x86 on Windows (x64 can build x86)
    $platforms += @("windows-x64", "windows-x86")
  }
  elseif ($IsLinux)
  {
    $platforms += "linux-x64"
    $arch = $( uname -m )
    if ($arch -eq "aarch64")
    {
      $platforms += "linux-arm64"
    }
  }
  elseif ($IsMacOS)
  {
    $platforms += "osx-x64"
    $arch = $( uname -m )
    if ($arch -eq "arm64")
    {
      $platforms += "osx-arm64"
    }
  }
  return $platforms
}

function Test-Command
{
  param($Command)
  try
  {
    Get-Command $Command -ErrorAction Stop | Out-Null
    return $true
  }
  catch
  {
    return $false
  }
}

function Get-VisualStudioPath
{
  if ($IsWindows)
  {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere)
    {
      $vsPath = & $vswhere -products * -latest -prerelease -requires Microsoft.Component.MSBuild -property installationPath | Select-Object -First 1
      return $vsPath.Trim()
    }
  }
  return $null
}

function Build-Platform
{
  param(
    [string]$Platform,
    [string]$InstallDir,
    [bool]$SharedLib
  )

  $libType = if ($SharedLib)
  {
    "shared"
  }
  else
  {
    "static"
  }
  Write-Host "Building for $Platform ($libType library)..." -ForegroundColor Green

  $buildDir = ".build-$Platform-$libType"
  if (Test-Path $buildDir)
  {
    Remove-Item -Recurse -Force $buildDir
  }
  New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

  # Don't clean individual files here - handled at script level

  Push-Location $buildDir

  try
  {
    switch -Wildcard ($Platform)
    {
      "windows-*" {
        if (-not $InstallDir)
        {
          throw "Visual Studio installation not found"
        }

        $arch = if ($Platform -eq "windows-x64")
        {
          "x64"
        }
        else
        {
          "Win32"
        }
        $vcvars = if ($Platform -eq "windows-x64")
        {
          "$InstallDir\VC\Auxiliary\Build\vcvars64.bat"
        }
        else
        {
          "$InstallDir\VC\Auxiliary\Build\vcvars32.bat"
        }

        if (-not (Test-Path $vcvars))
        {
          throw "vcvars batch file not found: $vcvars"
        }

        # Try Visual Studio 2026 first, then 2022
        $generators = @("Visual Studio 18 2026", "Visual Studio 17 2022")
        $generatorUsed = $null

        foreach ($gen in $generators)
        {
          Write-Host "Trying generator: $gen"
          $env:VSCMD_START_DIR = $PWD
          $cmakeArgs = @("..", "-G", "`"$gen`"", "-A", $arch)
          if ($SharedLib)
          {
            $cmakeArgs += "-DBUILD_SHARED_LIB=ON"
          }
          else
          {
            $cmakeArgs += "-DBUILD_SHARED_LIB=OFF"
          }
          & cmd /c "`"$vcvars`" && cmake $( $cmakeArgs -join ' ' ) 2>&1"
          if ($LASTEXITCODE -eq 0)
          {
            $generatorUsed = $gen
            break
          }
        }

        if (-not $generatorUsed)
        {
          throw "CMake configuration failed for $Platform"
        }

        & cmake --build . --config Release
        if ($LASTEXITCODE -ne 0)
        {
          throw "Build failed for $Platform"
        }
      }

      "linux-*" {
        # Find available compiler: prefer GCC, fallback to Clang
        $compiler = $null
        if (Test-Command "gcc")
        {
          $compiler = "gcc"
          Write-Host "Using GCC compiler" -ForegroundColor Cyan
        }
        elseif (Test-Command "clang")
        {
          $compiler = "clang"
          Write-Host "Using Clang compiler" -ForegroundColor Cyan
        }
        else
        {
          throw "Neither GCC nor Clang found. Please install build-essential or equivalent."
        }

        $cmakeArgs = @("..", "-DCMAKE_BUILD_TYPE=Release")
        if ($SharedLib)
        {
          $cmakeArgs += "-DBUILD_SHARED_LIB=ON"
        }
        else
        {
          $cmakeArgs += "-DBUILD_SHARED_LIB=OFF"
        }

        & cmake $cmakeArgs
        if ($LASTEXITCODE -ne 0)
        {
          throw "CMake configuration failed for $Platform"
        }

        & make -j$(Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty NumberOfLogicalProcessors)
        if ($LASTEXITCODE -ne 0)
        {
          throw "Build failed for $Platform"
        }
      }

      "osx-*" {
        # Find available compiler: prefer GCC, fallback to Clang
        $compiler = $null
        if (Test-Command "gcc")
        {
          $compiler = "gcc"
          Write-Host "Using GCC compiler" -ForegroundColor Cyan
        }
        elseif (Test-Command "clang")
        {
          $compiler = "clang"
          Write-Host "Using Clang compiler" -ForegroundColor Cyan
        }
        else
        {
          throw "Neither GCC nor Clang found. Please install Xcode Command Line Tools or Homebrew."
        }

        $cmakeArgs = @("..", "-DCMAKE_BUILD_TYPE=Release")
        if ($SharedLib)
        {
          $cmakeArgs += "-DBUILD_SHARED_LIB=ON"
        }
        else
        {
          $cmakeArgs += "-DBUILD_SHARED_LIB=OFF"
        }

        & cmake $cmakeArgs
        if ($LASTEXITCODE -ne 0)
        {
          throw "CMake configuration failed for $Platform"
        }

        & make -j$(sysctl -n hw.ncpu)
        if ($LASTEXITCODE -ne 0)
        {
          throw "Build failed for $Platform"
        }
      }

      default {
        throw "Unsupported platform: $Platform"
      }
    }

    Write-Host "Build completed for $Platform ($libType library)" -ForegroundColor Green
  }
  catch
  {
    Write-Host "Build failed for $Platform`: $_" -ForegroundColor Red
    throw
  }
  finally
  {
    Pop-Location
  }
}

# Main script execution
if ($Help)
{
  Show-Help
  exit 0
}

# Check if mynativelib directory exists
if (-not (Test-Path "mynativelib"))
{
  Write-Host "Error: mynativelib directory not found!" -ForegroundColor Red
  exit 1
}

if (-not (Test-Path "CMakeLists.txt"))
{
  Write-Host "Error: CMakeLists.txt not found!" -ForegroundColor Red
  exit 1
}

# Clean if requested
if ($Clean)
{
  Write-Host "Cleaning build artifacts and compiled files..." -ForegroundColor Yellow
  if (Test-Path ".build-*")
  {
    Remove-Item -Recurse -Force ".build-*"
  }
  if (Test-Path "artifacts")
  {
    Remove-Item -Recurse -Force "artifacts"
  }
  Write-Host "Clean completed" -ForegroundColor Green
  exit 0
}

# Clean when building only one library type to avoid mixing
if ($StaticOnly -or $SharedOnly)
{
  Write-Host "Cleaning build directories and artifacts to ensure clean build..." -ForegroundColor Yellow
  if (Test-Path ".build-*")
  {
    Remove-Item -Recurse -Force ".build-*"
  }
  if (Test-Path "artifacts")
  {
    Remove-Item -Recurse -Force "artifacts"
  }
  Write-Host "Clean completed" -ForegroundColor Green
}

# Determine platforms to build
if ($Platforms.Count -eq 0)
{
  # Auto-detect default platforms if no platforms specified
  $Platforms = Get-DefaultPlatforms
  Write-Host "Auto-detected platforms: $( $Platforms -join ', ' )" -ForegroundColor Green
}
else
{
  # Normalize platform names and validate
  $normalizedPlatforms = @()
  $supportedPlatforms = Get-SupportedPlatforms
  foreach ($platform in $Platforms)
  {
    # Handle comma-separated input
    $individualPlatforms = $platform -split ','
    foreach ($individualPlatform in $individualPlatforms)
    {
      $trimmedPlatform = $individualPlatform.Trim()
      $normalizedPlatform = Normalize-PlatformName $trimmedPlatform
      $normalizedPlatforms += $normalizedPlatform
      if ($normalizedPlatform -notin $supportedPlatforms)
      {
        Write-Host "Warning: Platform '$trimmedPlatform' may not be supported on this system" -ForegroundColor Yellow
      }
    }
  }
  $Platforms = $normalizedPlatforms
}

Write-Host "Building native libraries for platforms: $( $Platforms -join ', ' )" -ForegroundColor Cyan

# Get Visual Studio path for Windows builds
$vsInstallDir = $null
if ($IsWindows -and ($Platforms -like "windows-*").Count -gt 0)
{
  $vsInstallDir = Get-VisualStudioPath
  if (-not $vsInstallDir)
  {
    Write-Host "Warning: Visual Studio not found. Windows builds may fail." -ForegroundColor Yellow
  }
  else
  {
    Write-Host "Found Visual Studio at: $vsInstallDir" -ForegroundColor Green
  }
}

# Determine library types to build
$buildStatic = -not $SharedOnly
$buildShared = -not $StaticOnly

if ($StaticOnly -and $SharedOnly)
{
  Write-Host "Error: Cannot specify both -StaticOnly and -SharedOnly" -ForegroundColor Red
  exit 1
}

Write-Host "Library types: $( if ($buildStatic)
{
  'Static '
} )$( if ($buildShared)
{
  'Shared '
} )" -ForegroundColor Cyan

# Build each platform and library type
$failedPlatforms = @()
foreach ($platform in $Platforms)
{
  if ($buildStatic)
  {
    try
    {
      Build-Platform -Platform $platform -InstallDir $vsInstallDir -SharedLib $false
    }
    catch
    {
      $failedPlatforms += "$platform (static)"
    }
  }

  if ($buildShared)
  {
    try
    {
      Build-Platform -Platform $platform -InstallDir $vsInstallDir -SharedLib $true
    }
    catch
    {
      $failedPlatforms += "$platform (shared)"
    }
  }
}

# Summary
Write-Host ""
Write-Host "Build Summary:" -ForegroundColor Cyan
if ($failedPlatforms.Count -eq 0)
{
  Write-Host "All platforms built successfully!" -ForegroundColor Green
}
else
{
  Write-Host "Failed platforms: $( $failedPlatforms -join ', ' )" -ForegroundColor Red
  exit 1
}

# List generated artifacts
if (Test-Path "artifacts")
{
  Write-Host ""
  Write-Host "Generated artifacts:" -ForegroundColor Cyan
  Get-ChildItem -Path "artifacts" -Recurse -File | ForEach-Object {
    Write-Host "  $( $_.FullName )" -ForegroundColor White
  }
}
