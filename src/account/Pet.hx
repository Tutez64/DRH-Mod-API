package mods.api.account;

/**
 * A pet, copied when read.
 *
 * @since 1.0
 */
class Pet {
	/** The game's id of the pet's kind, and its name as the inventory shows it. */
	public var id(default, null):UInt;
	public var name(default, null):String;

	/**
	 * This pet's own id in the account, unlike `id`, which every pet of its kind shares.
	 * @since 1.2
	 */
	public var uid(default, null):UInt;

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
