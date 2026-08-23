package("move-rtm")
    set_kind("library", {headeronly = true})
    set_homepage("https://github.com/nfrechette/rtm")
    set_description("Move exact-source Realtime Math dependency")
    set_license("MIT")

    add_urls("https://github.com/nfrechette/rtm.git", {submodules = false})
    add_versions("2.3.1", "745bd25673d93b46941eda55e0993327dbc12b53")

    on_install(function (package)
        os.cp("includes/rtm", package:installdir("include"))
    end)

    on_test(function (package)
        assert(package:has_cxxtypes(
            "rtm::vector4d",
            {configs = {languages = "c++11"}, includes = "rtm/types.h"}))
    end)
