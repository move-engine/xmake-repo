package("vulkan-memory-allocator")
    set_kind("library", {headeronly = true})
    set_homepage("https://gpuopen-librariesandsdks.github.io/VulkanMemoryAllocator/html/")
    set_description("Vulkan Memory Allocator")
    set_license("MIT")

    add_urls("https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator.git")
    add_versions("v3.4.0", "3aa921224c154a0d2c43912bc88e1c42ce1f7607")

    add_deps("vulkan-headers 1.4.335+0")

    on_install(function (package)
        os.cp("include/vk_mem_alloc.h", package:installdir("include"))
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #include <vk_mem_alloc.h>

            static void test() {
                (void)VMA_VULKAN_VERSION;
            }
        ]]}, {configs = {languages = "c++20"}}))
    end)
