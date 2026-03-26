# Main Map Art Integration

This folder is reserved for production art used by the Godot main map screen.

Recommended files:

- `main_map_background.png`
  - Base starfield or full map painting.
  - Target framing: 16:9.
  - Keep important islands inside the center-safe area.
- `main_map_foreground.png`
  - Optional foreground clouds, glow, particles, or frame elements.
  - Prefer transparent PNG.
- `main_map_route_overlay.png`
  - Optional painted route glow if you do not want to rely on procedural lines later.
- `main_map_lock_icon.png`
  - Optional lock icon if the current text treatment is replaced.

Current scene integration points:

- `res://scenes/quest_map_screen.tscn`
  - `StageFrame/BackgroundTexture`
  - `StageFrame/RouteLayer`
  - `StageFrame/HotspotLayer`
  - `StageFrame/ForegroundTexture`

Current hotspot anchors:

- `group-01`: left lane
- `group-02`: center lane
- `group-03`: right lane

Before importing final art, prepare:

1. Leave enough empty area around each island so the hotspot text or later clickable art can sit on top cleanly.
2. Keep the three route destinations visually aligned with the current card anchors, or update the card positions in `res://scenes/quest_map_screen.tscn`.
3. If the final version replaces text cards with art hotspots, keep the existing group ids and interaction flow in `res://scripts/map/quest_map_screen.gd`.
4. If the final map needs more than 3 stage anchors, extend the scene with more fixed hotspots before wiring new group content.
