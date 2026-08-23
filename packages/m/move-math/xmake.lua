package("move-math")
    set_kind("library", {headeronly = true})
    set_homepage("https://github.com/move-engine/move-vectormath")
    set_description("Header-only game and graphics math")
    set_license("MIT")

    add_urls("https://github.com/move-engine/move-vectormath.git")
    add_versions("0.5.0", "2f7792c176a1c36841c51517f82e61609ad025a2")

    add_configs("rtm_revision", {
        description = "Exact Move RTM source revision",
        default = "745bd25673d93b46941eda55e0993327dbc12b53",
        type = "string"
    })
    add_deps("move-rtm 2.3.1")

    on_install(function (package)
        os.cp("packages/move/math/include", package:installdir())

        local config_header = package:installdir(
            "include", "mv", "math", "Config.hpp")
        local upstream_config = io.readfile(config_header)
        assert(upstream_config:find("#include <cstdint>", 1, true),
               "reviewed Vectormath Config.hpp injection point changed")
        assert(not upstream_config:find(
                   "MV_MOVE_VECTORMATH_FORCE_SCALAR", 1, true),
               "upstream Vectormath already owns the Move backend contract")
        io.replace(config_header, "#include <cstdint>", [[
#include <cstdint>

#if !defined(MV_MOVE_VECTORMATH_FORCE_SCALAR)
#error "Move targets must declare the catalog-owned Vectormath backend"
#elif MV_MOVE_VECTORMATH_FORCE_SCALAR == 1 && \
    !defined(MV_MATH_FORCE_SCALAR)
#error "Move Vectormath scalar backend requires MV_MATH_FORCE_SCALAR"
#elif MV_MOVE_VECTORMATH_FORCE_SCALAR == 0 && \
    defined(MV_MATH_FORCE_SCALAR)
#error "MV_MATH_FORCE_SCALAR conflicts with the selected Move Vectormath backend"
#elif MV_MOVE_VECTORMATH_FORCE_SCALAR != 0 && \
    MV_MOVE_VECTORMATH_FORCE_SCALAR != 1
#error "Move target Vectormath backend expectation must be 0 or 1"
#endif
]], {plain = true})
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #define MV_MOVE_VECTORMATH_FORCE_SCALAR 0
            #include <mv/math/Math.hpp>
            static void test() {
                using namespace mv::math;
                const Vec3f value(1.0F, 2.0F, 3.0F);
                (void)value;
            }
        ]]}, {configs = {languages = "c++20"}}))
    end)
