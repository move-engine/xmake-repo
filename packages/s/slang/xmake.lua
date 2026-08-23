package("slang")
    set_homepage("https://github.com/shader-slang/slang")
    set_description("Slang shader compiler and reflection library")
    set_license("Apache-2.0 WITH LLVM-exception")

    add_urls("https://github.com/shader-slang/slang.git")
    add_versions("v2026.14", "4265906358862245cb25f091cb47dc426c15267b")

    add_configs("shared", {
        description = "Build shared libraries",
        default = true,
        type = "boolean",
        readonly = true
    })
    add_configs("embed_stdlib_source", {
        description = "Embed the standard-library source",
        default = true,
        type = "boolean"
    })
    add_configs("embed_stdlib", {
        description = "Embed the compiled standard library",
        default = false,
        type = "boolean"
    })
    add_configs("full_ir_validation", {
        description = "Enable full Slang IR validation",
        default = false,
        type = "boolean"
    })
    add_configs("dxil", {
        description = "Enable DXIL generation through DXC",
        default = true,
        type = "boolean"
    })
    add_configs("gfx", {
        description = "Build Slang gfx targets",
        default = false,
        type = "boolean"
    })
    add_configs("slangd", {
        description = "Build the Slang language server",
        default = false,
        type = "boolean"
    })
    add_configs("slangi", {
        description = "Build the Slang interpreter",
        default = false,
        type = "boolean"
    })
    add_configs("slangc", {
        description = "Build the standalone Slang compiler",
        default = true,
        type = "boolean"
    })
    add_configs("slangrt", {
        description = "Build the Slang runtime target",
        default = false,
        type = "boolean"
    })
    add_configs("slang_glslang", {
        description = "Build the glslang wrapper",
        default = false,
        type = "boolean"
    })
    add_configs("slang_rhi", {
        description = "Build the Slang RHI dependency",
        default = true,
        type = "boolean"
    })
    add_configs("proxy", {
        description = "Build legacy Slang proxy outputs",
        default = true,
        type = "boolean"
    })
    add_configs("replayer", {
        description = "Build the Slang replay tool",
        default = false,
        type = "boolean"
    })
    add_configs("slang_llvm_flavor", {
        description = "Slang LLVM acquisition mode",
        default = "DISABLE",
        type = "string"
    })

    add_deps("cmake")
    add_deps("miniz")

    on_install("windows|x64", "mingw", "macosx", "linux|x86_64", function (package)
        io.replace(
            "cmake/SlangTarget.cmake",
            [[set_property(TARGET ${target} PROPERTY SUFFIX ".dylib")]],
            "",
            {plain = true})

        local configs = {
            "-DSLANG_ENABLE_TESTS=OFF",
            "-DSLANG_ENABLE_EXAMPLES=OFF",
            "-DSLANG_USE_SYSTEM_MINIZ=ON",
            "-DCMAKE_BUILD_TYPE=" .. (package:is_debug() and "Debug" or "Release"),
            "-DSLANG_LIB_TYPE=" .. (package:config("shared") and "SHARED" or "STATIC"),
            "-DSLANG_EMBED_STDLIB_SOURCE=" .. (package:config("embed_stdlib_source") and "ON" or "OFF"),
            "-DSLANG_EMBED_STDLIB=" .. (package:config("embed_stdlib") and "ON" or "OFF"),
            "-DSLANG_ENABLE_FULL_IR_VALIDATION=" .. (package:config("full_ir_validation") and "ON" or "OFF"),
            "-DSLANG_ENABLE_DXIL=" .. (package:config("dxil") and "ON" or "OFF"),
            "-DSLANG_ENABLE_ASAN=" .. (package:config("asan") and "ON" or "OFF"),
            "-DSLANG_ENABLE_GFX=" .. (package:config("gfx") and "ON" or "OFF"),
            "-DSLANG_ENABLE_SLANGD=" .. (package:config("slangd") and "ON" or "OFF"),
            "-DSLANG_ENABLE_SLANGI=" .. (package:config("slangi") and "ON" or "OFF"),
            "-DSLANG_ENABLE_SLANGC=" .. (package:config("slangc") and "ON" or "OFF"),
            "-DSLANG_ENABLE_SLANGRT=" .. (package:config("slangrt") and "ON" or "OFF"),
            "-DSLANG_ENABLE_SLANG_GLSLANG=" .. (package:config("slang_glslang") and "ON" or "OFF"),
            "-DSLANG_ENABLE_SLANG_RHI=" .. (package:config("slang_rhi") and "ON" or "OFF"),
            "-DSLANG_ENABLE_SLANG_PROXY=" .. (package:config("proxy") and "ON" or "OFF"),
            "-DSLANG_ENABLE_REPLAYER=" .. (package:config("replayer") and "ON" or "OFF"),
            "-DSLANG_SLANG_LLVM_FLAVOR=" .. package:config("slang_llvm_flavor")
        }

        io.replace(
            "CMakeLists.txt",
            [[find_package(Threads REQUIRED)]],
            [[find_package(Threads REQUIRED)
find_package(miniz CONFIG REQUIRED)
add_library(miniz ALIAS miniz::miniz)
get_target_property(MINIZ_INCLUDE_DIRS miniz::miniz INTERFACE_INCLUDE_DIRECTORIES)
include_directories(MINIZ_INCLUDE_DIRS)]],
            {plain = true})

        if package:is_plat("mingw") then
            io.replace(
                "source/slang-glsl-module/CMakeLists.txt",
                [[    EXCLUDE_FROM_ALL
    EXTRA_COMPILE_DEFINITIONS_PRIVATE SLANG_SHARED_LIBRARY_TOOL]],
                [[    EXTRA_COMPILE_DEFINITIONS_PRIVATE SLANG_SHARED_LIBRARY_TOOL]],
                {plain = true})
            io.replace(
                "source/slang-dispatcher/CMakeLists.txt",
                [[target_compile_definitions(slang-dispatcher PRIVATE "SLANG_VERSION_STRING=\"${PROJECT_VERSION}\"")]],
                [[target_compile_definitions(slang-dispatcher PRIVATE "SLANG_VERSION_STRING=\"${PROJECT_VERSION}\"")
target_link_options(slang-dispatcher PRIVATE -municode)]],
                {plain = true})
            io.replace(
                "tools/CMakeLists.txt",
                [[    Threads::Threads
)

slang_add_target(]],
                [[    Threads::Threads
)
target_link_options(slang-bootstrap PRIVATE -municode)

slang_add_target(]],
                {plain = true})
        end

        import("package.tools.cmake").install(package, configs)
        package:addenv("PATH", "bin")
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #include <slang-com-ptr.h>
            #include <slang.h>

            static void test() {
                Slang::ComPtr<slang::IGlobalSession> session;
                slang::createGlobalSession(session.writeRef());
            }
        ]]}, {configs = {languages = "c++20"}}))
    end)
