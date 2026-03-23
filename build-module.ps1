<#
.SYNOPSIS
    Unified build script for compiling C# Binary Module (AOT and Managed)
.DESCRIPTION
    Easily build both/AOT/managed versions of the C# Binary Module
#>

param(
  [ValidateSet('aot', 'managed', 'both')]
  [Alias('t')]
  [string]$Type = 'both',
  [Alias('c')]
  [switch]$Clean,
  [switch]$Help
)

function Show-Help
{
  Write-Host "Usage: ./build-module.ps1 [OPTIONS]"
  Write-Host ""
  Write-Host "Options:"
  Write-Host "  -Type, -t <string>      Build type: aot, managed, or both (default: both)"
  Write-Host "  -Clean, -c              Clean build artifacts before building"
  Write-Host "  -Help                   Show this help message"
  Write-Host ""
  Write-Host "Examples:"
  Write-Host "  ./build-module.ps1                   # Build both AOT and managed"
  Write-Host "  ./build-module.ps1 -t aot            # Build only AOT version"
  Write-Host "  ./build-module.ps1 -Type managed     # Build only managed version"
  Write-Host "  ./build-module.ps1 -c                # Clean only"
  Write-Host "  ./build-module.ps1 -t AOT -c         # Clean then build AOT (case-insensitive)"
}

function Clean-BuildArtifacts
{
  Write-Host "Cleaning build artifacts..." -ForegroundColor Yellow

  # Clean bin directories
  if (Test-Path "bin")
  {
    Remove-Item -Recurse -Force "bin"
  }
  if (Test-Path "dnGLua.BinaryModule\bin")
  {
    Remove-Item -Recurse -Force "dnGLua.BinaryModule\bin"
  }

  # Clean output directories created by build script
  if (Test-Path "bin-aot")
  {
    Remove-Item -Recurse -Force "bin-aot"
  }
  if (Test-Path "bin-managed")
  {
    Remove-Item -Recurse -Force "bin-managed"
  }

  # Clean obj directories
  if (Test-Path "dnGLua.BinaryModule\obj")
  {
    Remove-Item -Recurse -Force "dnGLua.BinaryModule\obj"
  }

  Write-Host "Clean completed" -ForegroundColor Green
}

function Build-AotModule
{
  Write-Host "Building AOT module..." -ForegroundColor Cyan

  #Push-Location "dnGLua.BinaryModule"

  try
  {
    # Update NuGet
    #& nuget update -self
    #if ($LASTEXITCODE -ne 0) {
    #    Write-Host "Warning: NuGet update failed, continuing..." -ForegroundColor Yellow
    #}

    # Try NuGet restore (may fail)
    #& nuget restore
    #if ($LASTEXITCODE -ne 0) {
    #    Write-Host "NuGet restore not applicable, using dotnet restore..." -ForegroundColor Yellow
    #}

    # Force restore
    & dotnet restore --force
    if ($LASTEXITCODE -ne 0)
    {
      throw "dotnet restore failed"
    }

    # Build AOT binary module for current platform
    & dotnet publish -c Release /p:PublishAot=true -v detailed -o bin-aot
    if ($LASTEXITCODE -ne 0)
    {
      throw "AOT build failed"
    }

    Write-Host "AOT build completed successfully" -ForegroundColor Green
  }
  finally
  {
    #Pop-Location
  }
}

function Build-ManagedModule
{
  Write-Host "Building managed module..." -ForegroundColor Cyan

  #Push-Location "dnGLua.BinaryModule"

  try
  {
    # Update NuGet
    #& nuget update -self
    #if ($LASTEXITCODE -ne 0) {
    #    Write-Host "Warning: NuGet update failed, continuing..." -ForegroundColor Yellow
    #}

    # Try NuGet restore (may fail)
    #& nuget restore
    #if ($LASTEXITCODE -ne 0) {
    #    Write-Host "NuGet restore not applicable, using dotnet restore..." -ForegroundColor Yellow
    #}

    # Force restore
    & dotnet restore --force
    if ($LASTEXITCODE -ne 0)
    {
      throw "dotnet restore failed"
    }

    # Build managed binary module
    & dotnet build -c Release --no-restore --no-incremental -v detailed -o bin-managed
    if ($LASTEXITCODE -ne 0)
    {
      throw "Managed build failed"
    }

    Write-Host "Managed build completed successfully" -ForegroundColor Green
  }
  finally
  {
    #Pop-Location
  }
}

# Main execution
if ($Help)
{
  Show-Help
  exit 0
}

# Make Type parameter case-insensitive
$Type = $Type.ToLowerInvariant()

# Check if we're in the right directory
if (-not (Test-Path "dnGLua.BinaryModule\dnGLua.BinaryModule.csproj"))
{
  Write-Host "Error: dnGLua.BinaryModule.csproj not found!" -ForegroundColor Red
  Write-Host "Please run this script from the project root directory." -ForegroundColor Red
  exit 1
}

# Clean if requested
if ($Clean)
{
  Clean-BuildArtifacts

  # If only -Clean was specified (no -Type), exit after cleaning
  if ($Type -eq 'both' -and -not $PSBoundParameters.ContainsKey('Type'))
  {
    Write-Host "Clean completed. No build specified." -ForegroundColor Green
    exit 0
  }
}

# Build based on type
$buildAot = $Type -eq 'aot' -or $Type -eq 'both'
$buildManaged = $Type -eq 'managed' -or $Type -eq 'both'

Write-Host "Building: $Type" -ForegroundColor Cyan

if ($buildAot)
{
  Build-AotModule
}

if ($buildManaged)
{
  Build-ManagedModule
}

Write-Host "All builds completed successfully!" -ForegroundColor Green
