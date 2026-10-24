# ORPHOX — Testing Report

Engine: **Godot 4.7.2** · Windows x64 · 1280x720

## Verified automatically (real scenes, real physics, headless)

Every check below was performed by loading the actual scenes and stepping the real
Godot physics/timers.

| Test | Result |
|---|---|
| All four dimensions build with no runtime errors | PASS |
| Boss identities / HP / phases (Ignar 4, Thalassor 5, Razorclaw 6, Varkhos 12/3 phases) | PASS |
| Emberfall — Ember Seals sequence puzzle solves (wrong order resets) | PASS |
| Abyssara — Tidal Clock combination puzzle solves | PASS |
| Thornwild — Living Temple ordered puzzle solves | PASS |
| Fractured Void — Convergence Crystals puzzle solves (wake four, any order) | PASS |
| Solving a puzzle opens the vault gate | PASS |
| Cherries are required before a puzzle can be activated | PASS |
| Defeating a guardian drops its dimensional key (Ember/Tide/Thorn) | PASS |
| The Void Key is an optional collectible on a shift-revealed route | PASS |
| The Queen's cage is present in the Fractured Void | PASS |
| Varkhos enters phase 2 then phase 3 as his health falls | PASS |
| Varkhos dies and the portal activates | PASS |
| Entering the final portal starts the ending, sets queen_rescued + campaign_complete | PASS |
| The ending cinematic plays and the final stats screen appears | PASS |
| Cinematic intro pauses the game and Skip resumes it (nodes cleaned up) | PASS |
| Death still shows the game-over screen (from the earlier build, unchanged) | PASS |
| Save/load round-trips campaign data | PASS |

## Verified interactively

- Level 1 (Emberfall) was launched in the editor Game tab and rendered correctly
  (realm art, terrain, cherries, hazards, HUD and the control guide).

## Could not be run automatically

- A full four-dimension live playthrough and fresh screenshots of the main menu,
  the other realms, the boss fights and the ending could not be captured because the
  editor's Game tab was occupied by a user scene during this build. The scenes
  themselves are proven to load, build and run by the headless harness above.
- To validate locally: open `project.godot`, press F5, choose **New Game**, and play
  from the intro through the ending. Each dimension can be run directly with F6.

## Notes / limitations

- Boss HP was reduced 60% from the original balance: Ignar 4, Thalassor 5,
  Razorclaw 6, Varkhos 12. Adjust in `scripts/levels.gd` (`boss.hp`) if desired.
- "Platforms disappear / gravity changes" in Varkhos's phase 2 is expressed through
  escalating attack speed, teleportation and heavier projectiles rather than removing
  the floor, to guarantee the fight can never softlock.
- The Fox King's cape in gameplay is a generated overlay sprite on the animated fox;
  in cinematics/menus the King uses a dedicated full-body sprite.
- `Assets/generated/tile_jungle.png` was not import-processed at build time; the game
  decodes it directly (FX.load_tex), so Thornwild renders regardless.
- Legacy pre-ORPHOX scaffolding remains and is unused: `main.tscn`, `main.gd`,
  `BG.tscn`, `bg.gd`, `Frog.tscn`, `frog.gd`, `level_1.tscn`, `BOT/`, `PLAYER/`,
  `Character/`, `Mob/`, `HUD/`, `Assets/sprites/fox/` (the old white fox).
