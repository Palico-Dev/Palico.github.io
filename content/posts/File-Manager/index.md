+++
date = '2025-12-19T22:56:50-05:00'
draft = false
title = 'File Manager'

categories = ["Engine Development", "C++"]

+++

The File Manager aims to handle everything related to files and paths within the engine.

Its first responsibility is handling JSON. I have implemented several helper functions for reading and writing JSON files, which makes serialization much easier.

The second and most important responsibility is **Path Handling**. We need paths when loading assets like textures, fonts, and prefabs. In this post, I will focus specifically on how we find these paths. (The actual loading and unloading logic will be described in a future **Asset Manager** post).

## Shared Config

I have divided the solution into three distinct parts:

1. **Game Engine:** Contains general code and resources, compiled into a `.lib`.
2. **Game Project:** Contains specific project requirements and logic.
3. **Meta Generator:** Generates `.meta` files to link assets together.

To keep these synchronized, I need a global configuration to store settings and variables used throughout the entire solution. I added a Project Property File called `SharedConfig` used by all three projects.

Currently, it defines two specific Preprocessor Definitions:

```cpp
ASSET_DIR=R"($(SolutionDir)Assets)"
ENGINEASSET_DIR=R"($(SolutionDir)..\GameEngine\Assets)"
```

These definitions provide the relative paths for assets. Note that there are specific "Engine Assets" to provide defaults (like a default texture or font) to prevent the engine from crashing if a user asset returns a `nullptr`. Debug assets, like collider visualizations, are also stored here.

## Debug vs. Release Mode

In general, I want the project to be well-organized, with the assets folder located at the root of the game project. We need to let the file manager know exactly where the required assets are.

However, a problem arises during the build process. By default, the project is built into a separate "Build" folder. If I want to share my game with others, asking them to copy the Release application *and* match my specific folder structure manually is not a good user experience.

To solve this, I separated the logic for **Debug** mode and **Release** mode.

- **Debug Mode:** Keeps the default settings and locates assets using the `ASSET_DIR` macro.
- **Release Mode:** I want everything to appear in one folder, with assets copied into a subfolder.

The resulting structure for a release build looks like this:

Plaintext

```
- Project Root
    - Assets
    - Build
    - ...
    - Release
        - Project Assets
            - ...
        - Engine Assets
            - ...
        - MyGame.exe
        - .dlls
```

This allows me to simply zip the `Release` folder and share it with friends without worrying about missing resources.

## Path Handles

Since there are plenty of path operations in the code, I updated the project to **C++17** to utilize `std::filesystem`.

Here is how the path logic is implemented:

### Getting the Executable Directory

C++

```c++
fs::path FileManager::GetExecutableDir()
{
#ifdef _WIN32
    char buffer[MAX_PATH];
    GetModuleFileNameA(NULL, buffer, MAX_PATH);
    return fs::path(buffer).parent_path();
#else
    return fs::current_path();
#endif
}
```

*Note: I haven't implemented specific logic for Mac or Linux yet, so this defaults to compiling the `_WIN32` portion (x64 counts as `_WIN32`). This retrieves the actual path of the running executable.*

### Getting the Asset Folder

This function distinguishes between Debug and Release modes:

C++

```c++
fs::path FileManager::GetAssetFolderPath()
{
#ifdef _DEBUG
    return fs::path(ASSET_DIR);
#else
    return GetExecutableDir() / "ProjectAssets";
#endif
}
```

*There is an identical function for `GetEngineAssetFolderPath()` which points to the engine resources.*

### Getting the Specific Asset Path

This is the core function used by the Asset Manager. It takes a JSON meta object as input:

C++

```c++
fs::path FileManager::GetAssetPath(json::JSON meta)
{
    fs::path path;
    // Check if the asset is part of the Project or the Engine
    if (FileManager::JsonReadString(meta, "Location") == "Engine")
    {
        path = GetEngineAssetFolderPath();
    }
    else
    {
        path = FileManager::GetAssetFolderPath();
    }
    
    // Combine the base path with the relative asset path
    path = path / FileManager::JsonReadString(meta, "Asset");

    return path;
}
```

The input JSON (the meta file) looks like this:

JSON

```json
{
  "Asset" : "Prefabs/bullet.prefab",
  "FileName" : "bullet.prefab",
  "Guid" : "8f620113-5802-4092-b7dc-ab9a8340dc0f",
  "Location" : "Project",
  "Type" : "PrefabAsset"
}
```

The function reads the relative path (`"Prefabs/bullet.prefab"`) and the location type (`"Project"`), combines them with the correct root directory, and returns the absolute OS path.

## Conclusion

These are the essential functions within the File Manager. I have omitted some utilities like the `JsonReader` for brevity.

As engine development continues, more functions will be added here, such as `GetGameSettingPath` for the Render System and `GetSavePath` for the Save Game Manager.
