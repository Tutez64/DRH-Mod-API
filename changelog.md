Working changelog for the next release. Update it as work lands.
At tag time, copy these sections into the GitHub release notes.

## Added

- `Weapon.uid`: the weapon's own id in the account, so a mod tells apart two weapons of the same kind, level, rarity and modifiers, which share their `id`. It is 0 for the weapons a hero carries in a dungeon, which the game only knows by their kind.

## Fixed

- `Monster.maxHp` in an infinite dungeon: its server gives monsters more hit points than the game's data says, which the game's maximum knows nothing of, so `hp` was above `maxHp`. `maxHp` is now at least the most hit points the monster has been seen with, its full health since it comes whole.

## Changed

- The reference says what `Weapon.id` is: the id of the weapon's kind, shared by every weapon of that kind.

Mods using what is added declare `"api": "1.6"`. See [docs/api.md](docs/api.md) for the details.
