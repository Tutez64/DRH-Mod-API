Working changelog for the next release. Update it as work lands.
At tag time, copy these sections into the GitHub release notes.

## Added

- `Weapon.uid`: the weapon's own id in the account, so a mod tells apart two weapons of the same kind, level, rarity and modifiers, which share their `id`. It is 0 for the weapons a hero carries in a dungeon, which the game only knows by their kind.

## Changed

- The reference says what `Weapon.id` is: the id of the weapon's kind, shared by every weapon of that kind.

Mods using what is added declare `"api": "1.6"`. See [docs/api.md](docs/api.md) for the details.
