package mods.api._internal;

import distributedObjects.NPCGameObject;

/**
 * An NPC ready on a floor, with what the game's data says of it once and for all. Not for mods: they
 * read `Floor.monsters`.
 */
@:allow(mods.api)
class Foe {
	var npc:NPCGameObject;

	var id:UInt;

	var name:String;

	var healthBar:Bool;

	function new(npc:NPCGameObject) {
		this.npc = npc;
		id = npc.id;
		var gm = npc.gmNpc;
		name = gm == null || gm.Name == null ? "" : gm.Name;
		healthBar = gm != null && gm.HasHealthbar;
	}
}
