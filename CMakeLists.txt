cmake_minimum_required(VERSION 3.20)
project(mynativelib C)

# Set C standard
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Set maximum optimizations for different build configurations
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    set(CMAKE_C_FLAGS_RELEASE "/O2 /Ob2 /Ot /Oy /GL /DNDEBUG" CACHE STRING "Release flags")
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "/LTCG /OPT:REF /OPT:ICF" CACHE STRING "Release linker flags")
    set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "/LTCG /OPT:REF /OPT:ICF" CACHE STRING "Release shared linker flags")
    set(CMAKE_STATIC_LINKER_FLAGS_RELEASE "/LTCG" CACHE STRING "Release static linker flags")
elseif(CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
    set(CMAKE_C_FLAGS_MINSIZEREL "/O1 /Ob1 /GL /DNDEBUG" CACHE STRING "MinSizeRel flags")
    set(CMAKE_EXE_LINKER_FLAGS_MINSIZEREL "/LTCG /OPT:REF /OPT:ICF" CACHE STRING "MinSizeRel linker flags")
    set(CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL "/LTCG /OPT:REF /OPT:ICF" CACHE STRING "MinSizeRel shared linker flags")
    set(CMAKE_STATIC_LINKER_FLAGS_MINSIZEREL "/LTCG" CACHE STRING "MinSizeRel static linker flags")
elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    set(CMAKE_C_FLAGS_RELWITHDEBINFO "/O2 /Ob2 /Ot /Oy /GL /Zi /DNDEBUG" CACHE STRING "RelWithDebInfo flags")
    set(CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "/LTCG /OPT:REF /OPT:ICF /DEBUG" CACHE STRING "RelWithDebInfo linker flags")
    set(CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "/LTCG /OPT:REF /OPT:ICF /DEBUG" CACHE STRING "RelWithDebInfo shared linker flags")
    set(CMAKE_STATIC_LINKER_FLAGS_RELWITHDEBINFO "/LTCG" CACHE STRING "RelWithDebInfo static linker flags")
endif()

# Option to build as shared or static library
option(BUILD_SHARED_LIB "Build shared library instead of static" OFF)

# Find all source files and headers recursively
file(GLOB_RECURSE SOURCES 
    "mynativelib/*.c"
)

file(GLOB_RECURSE HEADERS 
    "mynativelib/*.h"
)

# Create the library (static or shared based on option)
if(BUILD_SHARED_LIB)
    add_library(mynativelib SHARED ${SOURCES})
    # Set output name for shared library
    set_target_properties(mynativelib PROPERTIES OUTPUT_NAME "mynativelib")
else()
    add_library(mynativelib STATIC ${SOURCES})
    # Set output name for static library
    set_target_properties(mynativelib PROPERTIES OUTPUT_NAME "mynativelib")
endif()

# Additional optimizations for MSVC
if(MSVC)
    # Add optimizations for Release configuration
    target_compile_options(mynativelib PRIVATE
        $<$<CONFIG:Release>:/Qpar /arch:AVX2 /fp:fast>
        $<$<CONFIG:RelWithDebInfo>:/Qpar /arch:AVX2 /fp:fast>
        $<$<CONFIG:MinSizeRel>:/Qpar /arch:AVX2 /fp:fast>
    )
endif()

# Platform-specific configurations
if(WIN32)
    # Windows-specific settings
    target_compile_definitions(mynativelib PRIVATE _CRT_SECURE_NO_WARNINGS)

    # Fix processor name for Windows
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(PLATFORM_NAME "win-x64")
    else()
        set(PLATFORM_NAME "win-x86")
    endif()
elseif(APPLE)
    # macOS-specific settings
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
        set(PLATFORM_NAME "osx-arm64")
    else()
        set(PLATFORM_NAME "osx-x64")
    endif()
elseif(UNIX)
    # Linux-specific settings
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
        set(PLATFORM_NAME "linux-arm64")
    elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "arm")
        set(PLATFORM_NAME "linux-arm")
    else()
        set(PLATFORM_NAME "linux-x64")
    endif()
endif()

# Set output directory (no Release subdirectory)
set_target_properties(mynativelib PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
    ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
    LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
    ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
    LIBRARY_OUTPUT_DIRECTORY_RELEASE "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
    ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
    LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
    ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
    LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
    RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_CURRENT_SOURCE_DIR}/artifacts/runtimes/${PLATFORM_NAME}/native"
)
