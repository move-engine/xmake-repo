# Move Xmake package repository

This repository contains the Xmake package recipes maintained by the Move
project.

Add it once near the top of a consuming `xmake.lua`:

```lua
add_repositories("move-engine https://github.com/move-engine/xmake-repo.git")
```

Packages can then be declared with ordinary `add_requires()` calls. Recipes
pin source revisions and expose only configuration that has been qualified by
the corresponding Move library.

## mvgpu

```lua
add_requires("mvgpu 0.13.0")

target("example")
    set_kind("binary")
    add_files("src/**.cpp")
    add_packages("mvgpu")
```

The default package builds a static frontend and a runtime-loadable Vulkan
backend where Vulkan is supported. `xmake run` includes the installed backend
directory in the runtime search path; deployment remains free to copy the
plugin to a product-specific location. Available configurations are:

- `shared`: build the frontend as a shared library;
- `backend_shared`: build backends as runtime-loadable libraries;
- `vulkan`: include the Vulkan backend on supported platforms; and
- `shader_toolchain`: include Slang and SPIRV-Tools support.

For example:

```lua
add_requires("mvgpu 0.13.0", {configs = {
    shared = false,
    backend_shared = true,
    vulkan = true,
    shader_toolchain = false
}})
```
