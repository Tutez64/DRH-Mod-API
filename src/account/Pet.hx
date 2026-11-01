package mods.api.account;

/** One pet, copied when read. */
class Pet {
	/** GameMaster npc id of the pet's kind. */
	public var id(default, null):UInt;

	/** This pet's own id in the account, unlike `id`, which every pet of its kind shares. */
	public var uid(default, null):UInt;

	/** Display name, as the inventory shows it. */
	public var name(default, null):String;

	public var attackRating(default, null):UInt;

	public var defenseRating(default, null):UInt;

	public var speedRating(default, null):UInt;

	@:allow(mods.api.account.Inventory, mods.api.account.OwnedHero)
	function new(id:UInt, uid:UInt, name:String, attackRating:UInt, defenseRating:UInt, speedRating:UInt) {
		this.id = id;
		this.uid = uid;
		this.name = name;
		this.attackRating = attackRating;
		this.defenseRating = defenseRating;
		this.speedRating = speedRating;
	}
}
