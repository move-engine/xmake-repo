package("move")
    set_kind("addon")
    set_homepage("https://github.com/move-engine/move")
    set_description("Move engine SDK and Xmake project integration")
    set_license("MIT")

    add_urls("https://github.com/move-engine/move.git")

    -- Keep each SDK version tied to the exact Move source revision that
    -- contains its Xmake facade, runtime, and modules.
    add_versions("0.1.0", "29821cfb20771ca13e13b1f92c4095e937ff4a5a")

    on_install(function (package)
        local project = package:installdir("includes", "project")
        os.cp("xmake/addon/includes/move/project/xmake.lua", project)
        os.cp("xmake/addon/toolchains/move_ucrt64_gcc/xmake.lua",
            package:installdir("toolchains", "move_ucrt64_gcc"))

        local sdk = path.join(project, "sdk")
        os.cp("xmake", path.join(sdk, "xmake"))
        os.cp("runtime", sdk)
        os.cp("common", sdk)
        os.cp("toolchain.toml", sdk)
    end)

    on_test(function (package)
        assert(os.isfile(package:installdir(
            "includes", "project", "xmake.lua")))
        assert(os.isfile(package:installdir(
            "includes", "project", "sdk", "xmake", "project.lua")))
        assert(package:has_addon({toolchains = "move_ucrt64_gcc"}))
    end)
