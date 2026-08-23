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
