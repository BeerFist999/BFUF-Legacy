# BFUF Changelog

## v0.1.0 — Stable Foundation

### Added

- Player Frame
- Target Frame
- Secure Target interaction
- Click handling
- Unit lifecycle management
- Health reaction colors
- 2D portrait renderer
- Square portrait crop
- Stable layout foundation

### Changed

- Removed experimental 3D portrait system
- Simplified portrait lifecycle
- Removed retry/timer logic
- Removed unused 3D portrait references

### Known limitations

- Portraits use Blizzard 2D portrait textures.
- No 3D portraits are included.

### Architecture

- BlizzardFrameController
- Event driven refresh lifecycle
- Secure Target root
