# ORPHOX: The Kingdom Beyond Dimensions

A 2D platform adventure starring the Fox King. Travel across four strange realms, master each realm's power, defeat its guardian, and rescue the Fox Queen from Varkhos, the Void Emperor.

## Gameplay

- Explore the Lava, Ocean, Jungle, and Void realms.
- Jump across moving, crumbling, hidden, and disappearing platforms while avoiding hazards.
- Use realm abilities to solve puzzles: reverse gravity, freeze time, or slow and rewind time.
- Collect cherries and keys, unlock the royal gun, and battle each realm's guardian.
- Continue a campaign with saved progress, checkpoints, a level select, and story cinematics.

## Realms and abilities

| Realm | Ability |
| --- | --- |
| Lava Realm | Gravity Reversal |
| Ocean Realm | Time Freeze |
| Jungle Realm | Time Slow & Rewind |
| Void Realm | Gravity Reversal |

## Controls

| Action | Keyboard / mouse |
| --- | --- |
| Move | `A` / `D` or `←` / `→` |
| Jump | `Space` |
| Interact or enter a portal | `E` |
| Use realm ability | `F` |
| Shoot (after collecting the gun) | Left mouse button |
| Restart level | `R` |
| Pause | `Esc` |

## Source code

The repository is written in GDScript for Godot 4. The main scripts include:

- [`fox_controller.gd`](fox_controller.gd) — player movement, jumping, combat, and abilities.
- [`ability_manager.gd`](ability_manager.gd) — timed realm abilities and cooldowns.
- [`levels.gd`](levels.gd) and [`level_base.gd`](level_base.gd) — realm data and level construction.
- [`game_state.gd`](game_state.gd) — campaign progress, collectibles, and save data.
- [`main_menu.gd`](main_menu.gd) and [`hud.gd`](hud.gd) — menus, controls, and in-game interface.
- [`story_data.gd`](story_data.gd) — story dialogue and cinematic sequences.

## Project status

The current repository contains the game's GDScript source files, but not the `project.godot` project file, scenes, or assets referenced by the scripts. A fresh clone is therefore not yet a complete, directly playable Godot project. Add the missing project resources before opening and running it in Godot.

## Getting the source

```bash
git clone https://github.com/shivmore13/ps.git
cd ps
```

---

Created by [shivmore13](https://github.com/shivmore13).
