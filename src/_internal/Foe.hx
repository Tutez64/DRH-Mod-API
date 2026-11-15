package mods.api._internal;

import dBGlobals.DBGlobal;
import distributedObjects.NPCGameObject;
import mods.api.dungeon.Monster;

/**
 * An NPC ready on a floor, with what the game's data says of it once and for all. Not for mods: they
 * read `Floor.monsters` and the monsters' events.
 */
@:allow(mods.api)
class Foe {
	var npc:NPCGameObject;

	var id:UInt;

	var name:String;

	var healthBar:Bool;

	/** Its hit points, kept from the game's event for them once the mods are told of it. */
	var hp:UInt;

	/** Told to the mods as spawned. */
	var told:Bool = false;

	/** Told to the mods as despawned. */
	var left:Bool = false;

	/** What listens to its hit points in the game, from spawned to despawned. */
	var listener:Null<Dynamic->Void>;

	function new(npc:NPCGameObject) {
		this.npc = npc;
		id = npc.id;
		var gm = npc.gmNpc;
		name = gm == null || gm.Name == null ? "" : gm.Name;
		healthBar = gm != null && gm.HasHealthbar;
		hp = npc.hitPoints;
	}

	/** Whether it is a living enemy of the heroes, whose team is `heroes`. */
	function living(heroes:Int):Bool {
		if (npc.isDestroyed || npc.isDead())
			return false;
		// Teams besides the heroes': props (environment), and traps that hurt everyone (the third team).
		var team = npc.team;
		return team != heroes && team != (DBGlobal.TEAM_ENVIRONMENT : Int) && team != (DBGlobal.TEAM_3 : Int);
	}

	/** What a mod is handed of one that may be gone already. */
	function last():Monster {
		return npc.isDestroyed ? new Monster(id, name, 0, 0, healthBar, 0, 0) : copy();
	}

	/** What a mod is handed, read now. */
	function copy():Monster {
		var position = npc.position;
		return new Monster(id, name, position == null ? 0 : position.x, position == null ? 0 : position.y, healthBar, hp, Std.int(npc.maxHitPoints));
	}
}
