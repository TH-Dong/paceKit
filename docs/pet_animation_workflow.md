# Pet Animation Workflow

## Current Recommendation

For now, test generated pet animation sheets as preview GIFs before wiring them into Flutter.

The image model may output either:

- A real transparent PNG sprite sheet.
- A fake transparent PNG where the gray checkerboard is baked into the image.

Only the first option is suitable for the app. If the checkerboard is baked in, regenerate the asset and explicitly ask for `transparent background alpha, no checkerboard pattern`.

## Preview A Sprite Sheet

Save the generated image into the project, for example:

```text
pet/leafbuds/leafbuds_happy_sheet_12.png
```

Then generate a preview GIF:

```sh
scripts/make_pet_gif.sh pet/leafbuds/leafbuds_happy_sheet_12.png outputs/pet_previews/leafbuds_happy.gif 4 3 8
```

Parameters:

- `4`: columns
- `3`: rows
- `8`: delay in centiseconds, so `8` means 0.08s per frame, about 12.5 fps

For a 20-frame horizontal sheet:

```sh
scripts/make_pet_gif.sh pet/leafbuds/leafbuds_happy_sheet_20.png outputs/pet_previews/leafbuds_happy.gif 20 1 5
```

## Asset Direction

Preferred final app format:

- Keep sprite sheets as PNG assets.
- Add a Flutter `AnimatedPet` component that plays sprite sheets when available.
- Fall back to the current static `PetImage` when a sheet is missing or invalid.

This avoids video transparency compatibility issues and keeps pixel-art edges crisp.
