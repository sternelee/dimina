# CMake minimum version requirement
cmake_minimum_required(VERSION 3.15)  # 使用较新的 CMake 版本

# Project name
project(quickjs)

# Define the root path for NativeRender
set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

# Include FetchContent for downloading dependencies
include(FetchContent)

include("${CMAKE_CURRENT_LIST_DIR}/../../../../../cmake/DependencyVersions.cmake")

set(DIMINA_REPO_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../..")
set(DIMINA_QUICKJS_DEBUGGER_DIR "${DIMINA_REPO_ROOT}/third_party/quickjs-debugger")
set(DIMINA_QUICKJS_DEBUGGER_INCLUDE_DIR "${DIMINA_QUICKJS_DEBUGGER_DIR}/include")
set(DIMINA_QUICKJS_DEBUGGER_SOURCE_DIR "${DIMINA_QUICKJS_DEBUGGER_DIR}/src")

string(TOLOWER "${CMAKE_BUILD_TYPE}" DIMINA_BUILD_TYPE_LOWER)
set(DIMINA_QUICKJS_DEBUGGER_DEFAULT OFF)
if(DIMINA_BUILD_TYPE_LOWER STREQUAL "debug")
    set(DIMINA_QUICKJS_DEBUGGER_DEFAULT ON)
endif()
option(DIMINA_ENABLE_QUICKJS_DEBUGGER "Build the QuickJS breakpoint debugger" ${DIMINA_QUICKJS_DEBUGGER_DEFAULT})

# Download QuickJS from GitHub
FetchContent_Declare(
    quickjs
    GIT_REPOSITORY https://github.com/bellard/quickjs.git
    GIT_TAG ${DIMINA_QUICKJS_GIT_TAG}
)
FetchContent_MakeAvailable(quickjs)

set(DIMINA_QUICKJS_SOURCE_DIR "${quickjs_SOURCE_DIR}")
if(DIMINA_ENABLE_QUICKJS_DEBUGGER)
    find_package(Git REQUIRED)
    set(DIMINA_QUICKJS_SOURCE_DIR "${CMAKE_CURRENT_BINARY_DIR}/quickjs_debugger_source")
    set(DIMINA_QUICKJS_DEBUGGER_PATCH "${DIMINA_QUICKJS_DEBUGGER_DIR}/patches/quickjs.patch")

    # Patch a build-local copy. A Debug configure must never contaminate the
    # FetchContent checkout later reused by a Release configure.
    file(REMOVE_RECURSE "${DIMINA_QUICKJS_SOURCE_DIR}")
    file(MAKE_DIRECTORY "${DIMINA_QUICKJS_SOURCE_DIR}")
    file(COPY "${quickjs_SOURCE_DIR}/"
        DESTINATION "${DIMINA_QUICKJS_SOURCE_DIR}"
        PATTERN ".git" EXCLUDE
    )
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E env "GIT_CEILING_DIRECTORIES=${DIMINA_REPO_ROOT}"
            ${GIT_EXECUTABLE} apply --check "${DIMINA_QUICKJS_DEBUGGER_PATCH}"
        WORKING_DIRECTORY "${DIMINA_QUICKJS_SOURCE_DIR}"
        RESULT_VARIABLE DIMINA_QUICKJS_PATCH_CHECK
        OUTPUT_VARIABLE DIMINA_QUICKJS_PATCH_OUTPUT
        ERROR_VARIABLE DIMINA_QUICKJS_PATCH_ERROR
    )
    if(NOT DIMINA_QUICKJS_PATCH_CHECK EQUAL 0)
        message(FATAL_ERROR
            "QuickJS source does not match the pinned debugger patch:\n"
            "${DIMINA_QUICKJS_PATCH_OUTPUT}${DIMINA_QUICKJS_PATCH_ERROR}"
        )
    endif()
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E env "GIT_CEILING_DIRECTORIES=${DIMINA_REPO_ROOT}"
            ${GIT_EXECUTABLE} apply "${DIMINA_QUICKJS_DEBUGGER_PATCH}"
        WORKING_DIRECTORY "${DIMINA_QUICKJS_SOURCE_DIR}"
        RESULT_VARIABLE DIMINA_QUICKJS_PATCH_RESULT
        OUTPUT_VARIABLE DIMINA_QUICKJS_PATCH_OUTPUT
        ERROR_VARIABLE DIMINA_QUICKJS_PATCH_ERROR
    )
    if(NOT DIMINA_QUICKJS_PATCH_RESULT EQUAL 0)
        message(FATAL_ERROR
            "Failed to apply the Dimina QuickJS debugger patch:\n"
            "${DIMINA_QUICKJS_PATCH_OUTPUT}${DIMINA_QUICKJS_PATCH_ERROR}"
        )
    endif()
endif()

# Brotli decoder used by FileSystemManager.readCompressedFile({ compressionAlgorithm: "br" }).
FetchContent_Declare(
    brotli
    GIT_REPOSITORY https://github.com/google/brotli.git
    GIT_TAG ${DIMINA_BROTLI_GIT_TAG}
)
FetchContent_GetProperties(brotli)
if(NOT brotli_POPULATED)
    FetchContent_Populate(brotli)
endif()

file(GLOB BROTLI_COMMON_SOURCES
    ${brotli_SOURCE_DIR}/c/common/*.c
)
file(GLOB BROTLI_DEC_SOURCES
    ${brotli_SOURCE_DIR}/c/dec/*.c
)
add_library(brotlicommon STATIC ${BROTLI_COMMON_SOURCES})
add_library(brotlidec STATIC ${BROTLI_DEC_SOURCES})
target_include_directories(brotlicommon PUBLIC ${brotli_SOURCE_DIR}/c/include)
target_include_directories(brotlidec PUBLIC ${brotli_SOURCE_DIR}/c/include)
target_link_libraries(brotlidec PUBLIC brotlicommon)

# Handle the VERSION file to prevent conflicts with C++ standard <version> header
# on case-insensitive filesystems (macOS). QuickJS ships a plain-text VERSION file
# which shadows the C++17/20 <version> header when quickjs_SOURCE_DIR is in the
# include path, causing "expected unqualified-id" errors in C++ compilations.
set(VERSION_FILE "${DIMINA_QUICKJS_SOURCE_DIR}/VERSION")
set(VERSION_H_FILE "${DIMINA_QUICKJS_SOURCE_DIR}/version.h")

if(EXISTS "${VERSION_FILE}")
    file(READ "${VERSION_FILE}" QJS_VERSION)
    string(STRIP "${QJS_VERSION}" QJS_VERSION)
    set(CONFIG_VERSION "${QJS_VERSION}")
    file(WRITE "${VERSION_H_FILE}" "#define QJS_VERSION \"${QJS_VERSION}\"\n")
    file(REMOVE "${VERSION_FILE}")
elseif(EXISTS "${VERSION_H_FILE}")
    file(STRINGS "${VERSION_H_FILE}" QJS_VERSION_DEFINE REGEX "^#define QJS_VERSION")
    string(REGEX REPLACE "^#define QJS_VERSION \"([^\"]+)\".*$" "\\1" CONFIG_VERSION "${QJS_VERSION_DEFINE}")
endif()

# Set build type to Release for optimization
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Add compiler options
add_compile_options(
    -DCONFIG_BIGNUM
    -DCONFIG_VERSION="${CONFIG_VERSION}"
    -O3              # 使用较高的优化级别
    -march=armv8-a    # 针对本地CPU架构优化
    -flto            # 启用链接时优化
)

# Include directories
include_directories(
    ${NATIVERENDER_ROOT_PATH}
    ${NATIVERENDER_ROOT_PATH}/include
    ${DIMINA_QUICKJS_SOURCE_DIR}  # Include the active QuickJS source directory
)

# Explicitly list source files for better control
file(GLOB sources
    ${NATIVERENDER_ROOT_PATH}/*.cpp
    ${NATIVERENDER_ROOT_PATH}/types/qjs_extension/*.c
)

# Add QuickJS source files directly
set(QUICKJS_SOURCES
    ${DIMINA_QUICKJS_SOURCE_DIR}/quickjs.c
    ${DIMINA_QUICKJS_SOURCE_DIR}/libregexp.c
    ${DIMINA_QUICKJS_SOURCE_DIR}/libunicode.c
    ${DIMINA_QUICKJS_SOURCE_DIR}/cutils.c
    ${DIMINA_QUICKJS_SOURCE_DIR}/dtoa.c
)

if(DIMINA_ENABLE_QUICKJS_DEBUGGER)
    list(APPEND QUICKJS_SOURCES
        ${DIMINA_QUICKJS_DEBUGGER_SOURCE_DIR}/quickjs-debugger.c
        ${DIMINA_QUICKJS_DEBUGGER_SOURCE_DIR}/transport-posix.c
    )
endif()

# Add shared library target
add_library(dimina SHARED ${sources} ${QUICKJS_SOURCES})

if(DIMINA_ENABLE_QUICKJS_DEBUGGER)
    target_compile_definitions(dimina PRIVATE DIMINA_ENABLE_QUICKJS_DEBUGGER=1)
    target_include_directories(dimina PRIVATE ${DIMINA_QUICKJS_DEBUGGER_INCLUDE_DIR})
endif()

# Link necessary libraries
target_link_libraries(dimina PUBLIC libace_napi.z.so libhilog_ndk.z.so libuv.so)
target_link_libraries(dimina PUBLIC brotlidec brotlicommon)

# Additional target properties for Release mode
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    set_target_properties(dimina PROPERTIES INTERPROCEDURAL_OPTIMIZATION TRUE)  # 启用 LTO
endif()

# Output configuration messages
message(STATUS "Project: ${PROJECT_NAME}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Optimization flags: -O3 -march=native -flto")
message(STATUS "QuickJS debugger: ${DIMINA_ENABLE_QUICKJS_DEBUGGER}")
