package("mvgpu")
    set_homepage("https://github.com/move-engine/mvgpu")
    set_description("Move's low-level, memory-oriented GPU interface")

    add_urls("git@github.com:move-engine/mvgpu.git",
             "https://github.com/move-engine/mvgpu.git")
    add_versions("0.13.0", "465a59f53a62650571b6cfb26e0ffa96ffea7fbe")

    add_configs("backend_shared", {
        description = "Build graphics backends as runtime-loadable libraries",
        default = true,
        type = "boolean"
    })
    add_configs("vulkan", {
        description = "Build the Vulkan backend on supported platforms",
        default = true,
        type = "boolean"
    })
    add_configs("shader_toolchain", {
        description = "Build with Slang and SPIRV-Tools shader compilation",
        default = false,
        type = "boolean"
    })

    on_load(function (package)
        local hasVulkan = package:config("vulkan") and
            package:is_plat("windows", "mingw", "linux", "bsd", "android")
        if hasVulkan then
            package:add("deps", "vulkan-headers 1.4.335+0", {private = true})
            package:add("deps", "vulkan-memory-allocator v3.4.0",
                        {private = true})
            if package:is_plat("linux", "bsd") then
                package:add("deps", "libx11 1.8.13", {private = true})
            end
        end

        if package:config("shader_toolchain") then
            package:add("deps", "slang v2026.14", {configs = {
                shared = true,
                embed_stdlib_source = true,
                embed_stdlib = false,
                full_ir_validation = false,
                dxil = not package:is_plat("mingw"),
                gfx = false,
                slangd = false,
                slangi = false,
                slangc = not package:is_plat("mingw"),
                slangrt = false,
                slang_glslang = false,
                slang_rhi = false,
                proxy = false,
                replayer = false,
                slang_llvm_flavor = "DISABLE"
            }})
            package:add("deps", "spirv-tools 1.4.335+0",
                        {configs = {shared = false}})
        end

        package:add("links", "mvgpu")
        if package:config("shared") then
            package:add("defines", "MVGPU_FRONTEND_SHARED")
        elseif hasVulkan and not package:config("backend_shared") then
            package:add("links", "mvgpu_vulkan")
        end
        if package:config("backend_shared") then
            package:addenv("PATH", package:installdir("bin"))
            if package:is_plat("linux", "bsd") then
                package:addenv("LD_LIBRARY_PATH", package:installdir("lib"))
            elseif package:is_plat("macosx", "iphoneos") then
                package:addenv("DYLD_LIBRARY_PATH", package:installdir("lib"))
            end
        end
        if package:is_plat("linux", "bsd") then
            package:add("syslinks", "dl")
        end
    end)

    on_install("windows", "mingw", "macosx", "iphoneos", "linux", "bsd", "android", function (package)
        local hasVulkan = package:config("vulkan") and
            package:is_plat("windows", "mingw", "linux", "bsd", "android")
        local configs = {
            mvgpu_frontend_shared = package:config("shared"),
            mvgpu_backend_shared = package:config("backend_shared"),
            mvgpu_build_vulkan_backend = hasVulkan,
            mvgpu_build_tests = false,
            mvgpu_build_presentation_tests = false,
            mvgpu_enable_shader_toolchain = package:config("shader_toolchain"),
            mvgpu_warnings_as_errors = false,
            mvgpu_sanitize_address = false,
            mvgpu_sanitize_thread = false
        }
        import("package.tools.xmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:check_csnippets({test = [[
            #include <mvgpu/loader.h>

            static void test(void) {
                mvgpu_backend_library_desc desc = {0};
                mvgpu_backend_library library = {0};
                desc.size = sizeof(desc);
                (void)mvgpu_load_backend_library(&desc, &library);
            }
        ]]}, {configs = {languages = "c11"}}))
    end)
