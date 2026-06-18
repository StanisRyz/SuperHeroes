# SuperHeroes

SuperHeroes is a Godot 4.x survivors-like / horde survival / bullet heaven game with an original superhero theme. The player will move through a large arena, survive enemy waves, collect XP, level up, and use active abilities in later gameplay milestones.

## Target Platform

- Godot 4.x
- GDScript
- Web / HTML5
- Yandex Games

## Supported Devices

- Desktop browser
- Mobile browser
- Landscape orientation

## Layout Assumptions

- Main target aspect ratio: 16:9.
- Wide landscape phones around 20:9 should not break the UI.
- Important UI should stay inside a central safe zone.

## Development Status

The project is currently in the foundation stage only. No gameplay has been implemented yet.

## Architecture Principles

- Separate runtime state, config data, UI, gameplay formulas, and Yandex SDK calls.
- Keep patches small and focused.
- Avoid broad rewrites unless explicitly requested.
- Keep the superhero theme original. Do not use copyrighted superhero names, brands, logos, or specific existing characters.

## Validation

Run the Godot editor validation from the repository root:

```sh
godot --headless --editor --quit
```

## Web Export Notes

The Web export preset should export to:

```text
export/index.html
```

Test exported builds through a local web server instead of opening the HTML file directly:

```sh
cd export
python -m http.server 8000
```

## Yandex Games Notes

- Yandex SDK integration will be added later through a wrapper.
- Ads, payments, monetization, leaderboards, saves, and meta-progression are not implemented yet.
- Localhost SDK unavailability during development is acceptable.
