# yu_ni_player_base

Abstract base library for the `yu_ni_player` multi-engine Flutter video player plugin.

This package contains all abstract interfaces, data models, UI components, object pool, and registry. It has zero dependency on any specific video playback SDK, making it the perfect foundation for building custom video player engines.

## Features

- **Core Interfaces**: Defines `YuNiPlayerEngine` and other essential abstractions.
- **Unified UI Components**: Provides `YuNiPlayer` widget and default control UI.
- **Object Pool**: Implementation of `YuNiPlayerPool` for efficient player instance management (LRU).
- **Registry**: Plugin registry to manage platform-specific engine selection.

## Usage

This package is intended to be used as a dependency for specific engine implementations or as the core API for apps using `yu_ni_player`.

```yaml
dependencies:
  yu_ni_player_base: ^1.0.0
```

For more details, please refer to the main repository: [yu_ni_player](https://github.com/lurongshuang/yu_ni_player)
