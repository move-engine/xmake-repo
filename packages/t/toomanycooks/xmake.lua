package("toomanycooks")
    set_kind("library", {headeronly = true})
    set_homepage("https://github.com/move-engine/TooManyCooks")
    set_description("C++20 coroutine and parallelism runtime")
    set_license("BSL-1.0")

    add_urls("https://github.com/move-engine/TooManyCooks.git")
    add_versions("1.7.0", "a0e17c9cbda0d369788617230e5e027f5097758e")
    add_versions("1.7.0-move.1", "c9965d9b84ab61e9ffacb6eced34386700164d04")

    add_configs("hwloc", {
        description = "Enable TooManyCooks hwloc integration",
        default = true,
        type = "boolean"
    })
    add_configs("boost_asio", {
        description = "Use Boost.Asio instead of standalone Asio",
        default = false,
        type = "boolean"
    })
    add_configs("trivial_task", {
        description = "Enable TMC_TRIVIAL_TASK",
        default = false,
        type = "boolean"
    })
    add_configs("nodiscard_await", {
        description = "Enable TMC_NODISCARD_AWAIT",
        default = false,
        type = "boolean"
    })
    add_configs("priority_count", {
        description = "Set TMC_PRIORITY_COUNT; 0 means runtime-configurable",
        default = 0,
        type = "number"
    })
    add_configs("more_threads", {
        description = "Enable TMC_MORE_THREADS",
        default = false,
        type = "boolean"
    })
    add_configs("work_item", {
        description = "Set TMC_WORK_ITEM",
        default = "CORO",
        type = "string",
        values = {"CORO", "FUNCORO"}
    })
    add_configs("standalone", {
        description = "Enable TMC_STANDALONE_COMPILATION",
        default = false,
        type = "boolean"
    })
    add_configs("shared_library", {
        description = "Keep TooManyCooks globals and TLS in one shared library",
        default = false,
        type = "boolean"
    })

    on_load(function (package)
        if package:config("hwloc") then
            package:add("deps", "hwloc")
            package:add("defines", "TMC_USE_HWLOC")
        end
        if package:config("boost_asio") then package:add("defines", "TMC_USE_BOOST_ASIO") end
        if package:config("trivial_task") then package:add("defines", "TMC_TRIVIAL_TASK") end
        if package:config("nodiscard_await") then package:add("defines", "TMC_NODISCARD_AWAIT") end
        local priority_count = tonumber(package:config("priority_count") or 0)
        if priority_count > 0 then
            package:add("defines", "TMC_PRIORITY_COUNT=" .. priority_count)
        end
        if package:config("more_threads") then package:add("defines", "TMC_MORE_THREADS") end
        if package:config("work_item") == "FUNCORO" then
            package:add("defines", "TMC_WORK_ITEM=FUNCORO")
        end
        if package:config("standalone") then
            package:add("defines", "TMC_STANDALONE_COMPILATION")
        end
        if package:config("shared_library") then package:add("defines", "TMC_SHARED_LIBRARY") end
        if package:is_plat("linux", "bsd") then package:add("syslinks", "pthread") end
    end)

    on_install(function (package)
        os.cp("include", package:installdir())
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #ifdef TMC_STANDALONE_COMPILATION
            #define TMC_IMPL
            #endif
            #include <tmc/all_headers.hpp>
            static void test() { (void)sizeof(tmc::task<int>); }
        ]]}, {configs = {languages = "c++20"}}))

        if package:version_str() == "1.7.0-move.1" then
            assert(package:check_cxxsnippets({notification = [[
                #ifdef TMC_STANDALONE_COMPILATION
                #define TMC_IMPL
                #endif
                #include <tmc/all_headers.hpp>
                static void notify(void* userdata) noexcept {
                    ++*static_cast<unsigned*>(userdata);
                }
                int main() {
                    unsigned notifications = 0;
                    tmc::ex_manual_st executor;
                    executor.set_post_notification(&notify, &notifications);
                    executor.init();
                    tmc::post(executor, [] {});
                    const bool ran = executor.run_one();
                    executor.teardown();
                    return notifications == 1 && ran ? 0 : 1;
                }
            ]]}, {
                configs = {languages = "c++20"},
                tryrun = not package:is_cross(),
                -- Also force a link check when target code cannot run here.
                binary_match = function () return true end
            }))
        end
    end)
