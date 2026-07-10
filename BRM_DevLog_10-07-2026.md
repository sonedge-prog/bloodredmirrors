# Blood Red Mirrors — Development Log

**Engine:** Godot 4
**Team:** Emily (Owner), Max (Developer), Aston Prime (Musician), mysterious_abyss (Musician), cinnamon.apples (Sprite maker/animator), and more people on the team!
**Genre:** Multiplayer asymmetric horror

This log covers everything built in Godot so far, from initial project setup through the current gameplay prototype.

---

## 1. Project Foundations

### Version Control
- Project set up with Git, `.gitignore` configured to exclude `.godot/`, `export_presets.cfg`, and OS-generated files, while keeping `project.godot` tracked.
- Folder convention established: one folder per scene, containing both the `.tscn` and matching `.gd` file. Global/autoload scripts live in `scenes/globals/`.

### Autoloads (Globals)
- **SaveManager** (`save_manager.gd`) — wraps Godot's `ConfigFile` for persistent local storage. Exposes `get_value(section, key, default)` and `set_value(section, key, value)`, writing to `user://settings.cfg`.
- **MusicManager** (`music_manager.gd`) — single `AudioStreamPlayer` routed through a dedicated `Music` audio bus. Holds a `TRACKS` dictionary mapping track names to file paths. Supports `play()`, `stop()`, `fade_in()`, `fade_out()`, `set_volume()`. Later extended with:
  - Per-track volume offsets (`TRACK_VOLUME_OFFSETS`) so individual tracks can be balanced relative to a shared base volume set by the Settings slider.
  - `set_muffled()` — drives an `AudioEffectLowPassFilter` on the `Music` bus, used for the low-health muffle effect.
  - `start_low_health_alarm()` / `stop_low_health_alarm()` — separate `AudioStreamPlayer` for a looping low-HP alarm, with its own independent volume offset.
  - `play_segment()` groundwork discussed (looping only part of a track between two timestamps) for future chase-theme layering, not yet implemented.

---

## 2. Front-End Flow (Warning → Menu → Gameplay)

Built in order, each as its own scene folder under `res://scenes/`:

### Warning Screen
- First-launch content warning (jumpscares, gore, epilepsy, dark themes).
- No skip option on first launch; a "don't show again" checkbox appears on subsequent launches, persisted via SaveManager.
- Root node had to be changed from `CanvasLayer` to `Control` early on to resolve a script/node type mismatch.

### Consent Screen (PC Name Handling)
- Added after a lengthy team discussion (see Section 3) about using the player's PC name for in-game horror flavor.
- Two-step flow:
  1. **Horror name choice** — Accept PC name as-is, redact it (`████████`), or type a custom name. This value is described as client-side only, used once, never stored or transmitted.
  2. **Display name** — a separate, mandatory field for the name shown to other players in lobbies/matches. Explicitly decoupled from the PC name to avoid any real-identity leakage into multiplayer contexts.
- Consent completion is tracked via `SaveManager` (`identity/consent_done`) so the screen only appears once.
- Later wired so that on **first launch only**, completing consent routes to Settings (forced setup) before the intro, rather than straight to the intro.

### Intro Screen
- `VideoStreamPlayer` playing a `.ogv` file (Godot 4's natively supported video format).
- Skippable with Space, guarded by a short `can_skip` delay to avoid instant-skip softlocks. Debugged a mixed tabs/spaces indentation issue that was breaking the script.

### Title Screen
- Simple `START` button leading to Main Menu.

### Main Menu
- Buttons: **Play**, **Server List**, **Tutorials**, **Information**, **Settings**, **Exit**.
- Tutorials and Information are same-scene panels (shown/hidden), not separate scenes — avoids duplicating a "just text" scene twice.
- **Play** button shows a development-build warning popup first (test zone is single-player only, content subject to change) before routing into Character Select. Cancel returns to the menu without proceeding.
- Plays `Scarlet Halls (by Aston Prime)` track via MusicManager on `_ready()`.

### Server List
- Fake server list (hardcoded array) to prove out the UI before any networking exists.
- Host / Join buttons currently print placeholders only.
- Back button added late (was initially missing).

### Settings
- Tabbed via `TabBar`: **Identity**, **Visual**, **Audio**, **Accessibility**.
- **Identity:** display name field, pronoun selection (originally four independent checkboxes, corrected to a `ButtonGroup` for mutually-exclusive single choice: they/them, she/her, he/him, any).
- **Visual:** resolution dropdown (auto-detects the player's actual screen resolution on first run via `DisplayServer.screen_get_size()`, falls back to closest fit), fullscreen toggle, VSync toggle. UI Placement deliberately deferred until an actual HUD exists to place.
- **Audio:** music volume slider (feeds `MusicManager.set_volume()`), harsh-noise volume slider with a test button (Kolo Scream, `.ogg`, played through a dedicated `AudioStreamPlayer`), subtitles toggle, lyrics toggle.
- **Accessibility:** no-gore toggle, text scale slider (applied via `add_theme_font_size_override` walked recursively across the scene tree, rather than `content_scale_factor` which was found to incorrectly resize the whole window instead of just text), epilepsy-safe-mode toggle.
- **Streaming app detection:** on Windows, runs `tasklist` via `OS.execute()` and checks for OBS/Streamlabs/XSplit process names. If found, epilepsy-safe mode is forced on and the toggle is disabled, with a visible warning label.
- Resolution changes only take visible effect in an exported build — the Godot editor's own window controls override `DisplayServer.window_set_size()` during in-editor testing.

---

## 3. Copyright & Privacy Decisions

Two significant non-coding decisions that shaped implementation:

### PC Name / Identity
Extended back-and-forth between Max and Emily about using the player's PC/machine name for in-game horror flavor (a killer referencing it directly). Concerns raised: shared family PCs showing a parent's name, data traveling through the server the moment it's used as a multiplayer-visible display name, server breach exposure, and RGPD/GDPR compliance (consent, documented purpose, deletion rights). Resolved as: strictly client-side, never stored or transmitted, used once and discarded, gated behind an explicit consent screen with redact/custom/decline options, and backed by a **separate mandatory display name** for anything actually shown to other players.

### Character/Franchise IP
Sonic-universe characters are used directly (Sega is broadly tolerant of free fangames). Other franchise-inspired teams (Mario/red, Pokémon/yellow, Kirby/pink) will be **original characters "inspired by" rather than direct reproductions** — different names, designs, and kits from the source material — since Nintendo does not tolerate fangames the way Sega does. This is treated as a hard constraint on future character design, not a stylistic preference.

---

## 4. Character Select Screen

- **Team select step** shown first (Blue / Red / Yellow / Pink), each team tinted via a shared `TEAM_DATA`/`TEAM_COLORS` dictionary (also mirrored later in the HUD for consistency).
- Selecting a team reveals a **character carousel**: LEFT/RIGHT arrow buttons or arrow keys cycle characters, ENTER confirms. Character name, description, and (when available) art are pulled from a `CHARACTERS` dictionary keyed by team and role (survivors/killers).
- Missing art/background textures are handled gracefully via `ResourceLoader.exists()` checks — hides the texture rather than erroring, so the scene stays usable before final art is ready.
- Background uses `Parallax2D` (Godot 4.3+ replacement for the deprecated `ParallaxLayer`/`ParallaxBackground`) with a continuously scrolling tiled texture per team, plus a semi-transparent bottom UI bar so character art can visually sit "behind" it.
- Selected team/character/role are written to `SaveManager` under a `match` section for the rest of the game to read.
- A dedicated Back button chain was added: character view → team select → main menu.

---

## 5. Test Zone (Gameplay Map)

- Built as a `Node2D` scene with a `TileMapLayer`, using a mix of:
  - **TileSet Physics Layers** for tiles needing precise/angled collision (slopes, stairs).
  - **Manual `CollisionShape2D` nodes** for simple flat geometry, since per-tile collision setup was found to be tedious for large flat areas.
- **One-way platforms** implemented via `StaticBody2D` + `CollisionShape2D` with **One Way Collision** enabled — solid from above, passable from below/sides.
- Camera follows the player via a `Camera2D` child on Sonic, with position smoothing enabled and 2x zoom for the pixel art.
- Texture filtering set to **Nearest** project-wide (`Project Settings → Rendering → Textures → Canvas Textures`) to fix blurring on pixel art sprites during movement — Godot defaults to linear filtering, which smudges low-res art.
- Plays the `______9 (Act 9 Map Theme by mysterious_abyss)` map track on load.

---

## 6. Player Character — Sonic

### Sprite & Animation
- Uses the **Sonic Battle** spritesheet (48×48 per frame) by SEGA and Sonic Team (ripped by QuadFactor) .
- Animations authored: `Idle`, `Run_Start` → `Run_Loop`, `Jump`, `Fall_Start` → `Fall_Loop`, `Land`, `Turn`, `Crouch` (placeholder using the sheet's "Guarding" pose, pending dedicated crouch art).
- Only right-facing frames are needed — `AnimatedSprite2D.flip_h` mirrors for left-facing movement automatically.
- Non-looping "start" animations chain into their looping counterparts via the `animation_finished` signal (`Run_Start → Run_Loop`, `Fall_Start → Fall_Loop`), rather than duplicating frames or relying on stacked `await` calls, to avoid animation-locking bugs from repeated calls in `_physics_process`.
- Landing and turning both lock into dedicated one-shot animations before returning control to normal state evaluation.

### Movement
- `CharacterBody2D` with standard `move_and_slide()`, gravity applied manually when airborne.
- Horizontal speed includes the +10% passive speed bonus baked in as a multiplier.
- Crouching reduces speed and is only available while grounded and not mid-turn.
- Jump only available grounded, not crouching, not mid-turn.

### Health System
- Originally hardcoded into the HUD; refactored so **the player owns its own health** (`max_health`, `current_health`, `take_damage()`, `heal()`, `set_max_health()`), emitting a `health_changed(current, max)` signal.
- HUD (and any other listener) subscribes to this signal rather than owning or duplicating health state — this was a deliberate architecture change to support future characters with different max HP or runtime max-HP buffs without touching HUD code.
- `set_max_health()` supports proportional scaling (keeps current HP ratio) or a hard reset.

### Low-Health Feedback
- Thresholds: alarm/muffle trigger at ≤27(?) HP (30% of 90), clear once healed back to ≥45 HP (50%).
- While low health **and** within range of a killer (checked continuously in `_physics_process`, not just on damage/heal events), the current music track is muffled via the `Music` bus's low-pass filter.
- A separate looping alarm sound plays independently of the muffle state, stopping once the recovery threshold is crossed.
- Both effects respect the player's Settings music volume as a relative offset rather than an absolute value (see Section 12).

---

## 7. HUD

- `CanvasLayer` scene, added as a child of `test_zone`, registered in a `hud` group for lookup by other systems.
- Reads `SaveManager`'s `match/selected_team` and `match/selected_character` to set the player's name label and tint a portrait frame using the same `TEAM_COLORS` mapping as Character Select — ensures visual consistency regardless of which character/team is active.
- **Health bar:** a `ProgressBar` plus an overlaid `Label` showing `current / max` as text, since ProgressBar's built-in display only shows a percentage by default. Fully driven by the player's `health_changed` signal.
- **Teammates panel:** a `VBoxContainer` with a helper `add_teammate(name, team)` that spawns a colored portrait + label per teammate — not yet wired to real multiplayer data.
- **Tasks panel:** described below (Section 8).
- **Abilities panel:** five slots in an `HBoxContainer`, each a `TextureRect` with a semi-transparent `ColorRect` cooldown overlay. `start_ability_cooldown(slot_index, duration)` tweens the overlay's alpha to fade out over the cooldown duration; `set_ability_icon(slot_index, texture)` swaps the icon. A later mockup added two labels per slot (ability name + keybind) — not yet wired into the script, planned as the next HUD update to support per-character ability data.

---

## 8. Tasks System

- `TaskManager` — a plain `Node` (child of HUD) rather than an autoload, since tasks are per-match rather than global.
- Supports two task types:
  - **Simple tasks** (`add_task`) — binary done/not-done.
  - **Progress tasks** (`add_progress_task`) — tracked against a target count (e.g. "Light Torches (0/4)"), completing once progress reaches the total.
- Emits `task_completed`, `task_progress`, and `all_tasks_completed` signals; HUD listens and re-renders the task list as plain `Label` rows.
- Initial bug: the task list only appeared after the first task interaction, because the display refresh was only ever triggered reactively by signals, never on initial scene load — fixed by calling the refresh once explicitly after tasks are registered in `_ready()`.
- **Torch** interactable built as its own small reusable scene (`Area2D` + `Sprite2D`/placeholder + `CollisionShape2D`), exporting a `task_id` so multiple instances can share progress toward one task. On player contact, calls `complete_task()` on the shared `TaskManager` and removes itself.
- **Repair Plane** (a more complex multi-step task) planned but not yet implemented.

---

## 9. Damage / Healing Zones

- `EffectZone` — reusable `Area2D` scene with `@export var is_healing`, `amount_per_tick`, `tick_interval`. Ticks on a timer while the player remains inside, calling `take_damage()` or `heal()` directly on the player body (found in the `player` group).
- Debugged two setup issues along the way: confusing the Inspector's per-node **exported variables** with a nonexistent "Metadata" concept, and initially calling into the HUD instead of the player before the health-ownership refactor (Section 6).

---

## 10. Killer Dummy & Chase Music

- Placeholder killer (`StaticBody2D`) using a single idle frame for 2011X, registered in a `killer` group.
- A large `Area2D` "chase radius" child triggers `MusicManager.play("2011x_chase")` on player entry and reverts to the map track on exit — used to validate the chase-music trigger pattern before any real killer AI exists.
- Exposes a `stun(duration)` function (flashes red via `modulate`, tweens back after the duration) so ability code has something concrete to call and visually confirm hits against.
- The current chase track is short (~27s of content, remainder silence) and was found to loop acceptably as a full file for now; timestamp-based segment looping (`play_segment`) was designed but deferred until intensity-layered tracks are actually in use.

---

## 11. Abilities

All five of Sonic's kit abilities are implemented against the killer dummy stub, bound to keys (Q/E/Shift/R/F):

| Ability | Key | Behavior implemented |
|---|---|---|
| Boost / Double Boost | Q | Rev-up delay, forward dash, stun-on-hit with duration penalty, cooldown |
| Rapid Beatdown | E | Startup delay, range check, combo timer, stun-on-connect |
| InstaShield / Sidestep | Shift | Air/ground branch, temporary invulnerability flag, short cooldown |
| Enerbeam | R | Charge-based (3 max, recharges over time independently of a cooldown timer), range check, pulls target toward the player as a placeholder for the real grapple/grab behavior |
| Windy Finish / Sonic Tornado | F | Tap vs. hold detected via a press-duration threshold; tap = single delayed AoE stun check, hold = a 10-second loop dealing periodic stuns to anything in range |

Real damage-to-killer and full grapple/platform-grab logic are stubbed with `print()` statements pending the killer having its own health system and the level having a "grappable" group. Ability icon art is not yet in place — slots are currently empty placeholders.

---

## 12. Audio Mixing Pass

After initial playtesting flagged the chase theme as too loud and the map ambience as too quiet:
- Introduced `TRACK_VOLUME_OFFSETS`, a per-track dB adjustment applied on top of the player's base Settings volume (chase reduced, map ambient boosted).
- Alarm given its own independent volume offset, separate from music track volume.
- Low-pass filter cutoff for the muffle effect raised from an overly harsh 500 Hz to a more balanced 1400 Hz.
- Confirmed the Settings music slider still scales everything proportionally, since all offsets are additive on top of the slider-driven base rather than replacing it — no player-facing behavior was lost by adding the per-track balancing.

---

## 13. Known Gaps / Explicitly Deferred

- Multiplayer/networking entirely unimplemented — server list, host/join, and teammate display are all UI-only stubs.
- Killer side has no dedicated character, kit, or HUD variant yet (next planned major task, using a Dark Super Sonic fan-sprite placeholder in place of the not-yet-ready 2011X).
- No damage system on the killer dummy (abilities print intended damage rather than applying it); no killer-invincibility toggle yet (`@export`-driven, planned).
- Spindash's floating world-space bar above the player model not yet built.
- No death/respawn flow beyond a single `print()` on `current_health <= 0`.
- Ability icons and dedicated ability animations are placeholder/absent.
- UI Placement settings deferred until a real HUD layout exists to reposition.
- Segment-based chase music looping (playing only part of a track) designed but not implemented.

---

## 14. Immediate Next Steps (as of this log)

1. **Repair Plane** — a more involved, multi-step task compared to the simple torch interaction.
2. **Killer-side infrastructure:**
   - Character Select updated to allow choosing a killer for this test build (full game will randomize killer assignment).
   - Test zone possibly reworked/expanded to better suit killer testing.
   - Killer HUD variant: single "eliminate all survivors" objective, no HP bar by default, with a future `@export` toggle for killable/invincible killers.
   - Dummy survivors added so killer abilities have something to test against, mirroring the killer dummy's role for survivor testing.
3. **HUD ability slots** updated to display two labels per slot (ability name + keybind), with per-character data driving both text and icon.
4. **First real killer kit** — built around Dark Super Sonic (Sonic X-inspired fan sprites) as a stand-in for the unfinished 2011X, to prove out killer-side ability design end-to-end.
