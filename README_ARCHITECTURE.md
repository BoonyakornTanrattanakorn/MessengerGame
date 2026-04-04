# MessengerGame Architecture Guide

This guide explains where to place files so the project stays tidy and easy to navigate.
Everyone SHOULD follow this pattern to make working on this game easier for everyone.

## 1) Top-Level Folders

- `addons/`: Third-party or custom editor/runtime plugins.
- `assets/`: Raw game content (sprites, audio, portraits, tileset textures).
- `autoload/`: Global singleton scripts registered in `project.godot`.
- `features/`: Reusable gameplay systems and player-facing modules.
- `game/`: Level/chapter content, scene composition, map-specific logic.
- `ui/`: Shared menus and non-level-specific UI scenes.

## 2) Naming Rules (Important)

Use consistent lowercase snake_case for files and folders.

- Good: `player_hud.gd`, `level_3.tscn`, `cool_gauge.tscn`
- Avoid: `PlayerHUD.gd`, `Level_3.tscn`, `CoolGauge.tscn`

Reason:
- Windows may hide case mistakes, but Linux/macOS and CI treat case-sensitive paths strictly.
- Mixed naming causes broken resource references and hard-to-debug load errors.

## 3) Where To Put New Files

### Player and shared gameplay

Place under `features/player/`.

- `features/player/components/`: logic components (health, movement, skill, etc.)
- `features/player/hud/`: HUD scenes/scripts only
- `features/player/powers/<element>/`: element-specific scenes/scripts

### Chapter or map-specific content

Place under `game/chapter_<n>/node_<n>/`.

Suggested pattern:
- `level_<id>.tscn`: main level scene
- `<area>_level/`: scripts/scenes only used by that area
- `tres/`: map-specific TileSet and other resources
- `dialogue/`: local dialogue data

### Global UI and menus

Place under `ui/`.

- `ui/Menu/`, `ui/pause_menu/`, `ui/setting/`, etc.
- Keep UI that is used across multiple scenes here, not inside a chapter folder.

## 4) TileSet / TileSetAtlasSource Organization

When extracting or creating tileset resources, keep them close to the level that owns them.

For Node 3, use:
- `game/chapter_1/node_3/tres/tile.tres`
- `game/chapter_1/node_3/tres/bridge_shuffle.tres`
- `game/chapter_1/node_3/tres/hole.tres`
- `game/chapter_1/node_3/tres/rope.tres`
- `game/chapter_1/node_3/tres/switch.tres`

Tips:
- Save the full `TileSet` (`.tres`) rather than isolated atlas pieces when possible.
- Keep texture sources in `assets/sprites/maps/tilesets/`.
- Keep level-specific tileset logic in level-local folders under `game/chapter_...`.

## 5) Script Placement Rule of Thumb

- If a script is reusable across levels -> `features/`.
- If a script exists for one scene/level only -> same chapter/node folder under `game/`.

## 6) Quick Checklist Before Commit

- New files use lowercase snake_case.
- New scene/script is in the correct feature vs level folder.
- Resource paths in `.tscn` and `.tres` match exact filename case.
- No temporary files (`*.tmp`) are referenced.
- Level-specific resources are grouped in that level's `tres/` folder.

## 7) Example: Adding a New Level Mechanic

If adding a "crystal bridge" mechanic only for Chapter 1 Node 3:

1. Scene and logic:
   - `game/chapter_1/node_3/golem_level/crystal_bridge.tscn`
   - `game/chapter_1/node_3/golem_level/crystal_bridge.gd`
2. Local resources:
   - `game/chapter_1/node_3/tres/crystal_bridge_tiles.tres`
3. Shared UI (if needed globally):
   - `ui/...` (not in node folder)

This keeps chapter-specific content local and shared systems centralized.
