# IRON OMEN

A 2D dark-arcade 1v1 fighting game in the spirit of 90s arcade fighters —
built with **Flutter + Flame**, 100% original or properly licensed content.

## Features

- Deterministic 60 Hz fixed-timestep combat: data-driven frame data,
  hitbox/hurtbox collision, hitstop, pushback, corner handling, screen shake
- 5 playable fighters (Ash Viper, Iron Ghost, Night Blade, Grave Warden,
  Void Drake) — each is one data file + sprite sheets, zero engine changes
  to add more
- Specials (quarter-circle-forward + punch, or the SPECIAL button),
  EX versions powered by a 3-segment super meter, projectiles,
  MK-style uppercut (down + heavy), combo counter with damage scaling
- Hit sparks, block sparks, blood bursts, white hit-flash — all frozen
  correctly during hitstop
- Game modes: Arcade (CPU with 3 difficulties), local VS, Training
- 3 stages with multi-layer PNG parallax, best-of-3 match flow with KO
  slow-mo, full menu loop, touch controls + keyboard

## Run

```sh
flutter run -d windows        # or -d <your device>
# straight into a fight, skipping menus:
flutter run -d windows -t lib/dev_fight_main.dart
```

## Controls (desktop)

| Action | P1 | P2 (VS mode) |
|---|---|---|
| Move / jump / crouch | WASD | Arrows |
| Punch (chain x2) | J | Numpad 1 |
| Kick (knockdown) | K | Numpad 2 |
| Special / EX | L | Numpad 3 |
| Block | ; | Numpad 0 |
| Uppercut | S + K | Down + Numpad 2 |

F1 = combat box debug overlay, F2 = dummy mode (training), Esc = pause.

## Asset tooling

Sprite packs are converted into the engine's 17-animation contract by
`tool/import_martial_hero.dart`; stages by `tool/import_stage.dart`; VFX and
the 9-slice UI by `tool/import_effects.dart`. `tool/preview_stage.dart`
composites stage layers offline for tuning. Raw downloaded packs live in
`assets_src/` (not committed — see its `LICENSE_NOTES.md`).

## Art credits

- Fighters: "Martial Hero" 1-3 and "Fantasy Warrior" by
  [LuizMelo](https://luizmelo.itch.io/) (CC0)
- Void Drake: original AI-generated sprite set (Higgsfield / Nano Banana
  Pro), repackaged by `tool/import_void_drake.dart`
- Stages: "Gothicvania Cemetery" and "Mountain Dusk" by
  [ansimuz](https://ansimuz.itch.io/) (free for commercial use)
- Hit/block sparks and smears: "Battle VFX" packs by
  [pimen](https://pimen.itch.io/) (free for commercial use)
- Blood effects: "Blood FX" by
  [JasonTomLee](https://jasontomlee.itch.io/blood-fx) (CC-BY 4.0)
- Everything else (engine, UI art, placeholder generator) is original.

This is a fan-spirit homage to the 90s arcade era. No assets, names, or
likenesses from any commercial fighting game franchise are used.
