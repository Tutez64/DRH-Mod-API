Working changelog for the next release. Update it as work lands.
At tag time, copy these sections into the GitHub release notes.

## Added

- `onMonsterSpawned(handler)`, `onMonsterHurt(handler)` and `onMonsterDespawned(handler)`: a floor's monsters as they come, as their hit points change and as they go, so a mod showing them no longer has to look at `floor.monsters` on every frame.
  - Each hands a `Monster` copied at that moment: tell one from another by its `id`.
  - A monster is told as spawned after its floor's `onFloorEnter`, and as despawned once, when it dies, leaves or its floor ends, before that floor's `onFloorExit`.
- `Monster.hp` and `Monster.maxHp`: its hit points, and what they are when it is whole, with what its buffs add.
- `context.isActive(id)`: whether another mod runs, that is enabled, started and not failed since, so a mod that changes what it does beside another no longer has to look for that mod's classes. Ask from `ready` on.

## Improved

- `floor.monsters` costs about a third of what it did: about 33 µs a read with some fifty monsters, hit points included, where it took 109 µs without them. It lists the monsters told as spawned and not as despawned, where each read went through every actor of the floor.
- `floor.tiles` costs about a tenth of what it did: 2.5 µs a read for 23 µs with eleven tiles. A floor's tiles do not change, so they are read from the game once.
- The reference gives each member's type and the version it came in, in a table per type sorted by package. It is written from the comments of the code, so the two cannot differ.

Mods using what is added declare `"api": "1.5"`. See [docs/api.md](docs/api.md) for the details.
