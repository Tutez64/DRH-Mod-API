package mods.api.account;

/**
 * Some of one stackable item, such as a potion or a bomb.
 *
 * @since 1.0
 */
class Stack {
	/** The game's item id and its name. */
	public var id(default, null):UInt;
	public var name(default, null):String;

	public var count(default, null):UInt;

	@:allow(mods.api.account.Inventory, mods.api.account.OwnedHero)
	function new(id:UInt, name:String, count:UInt) {
		this.id = id;
		this.name = name;
		this.count = count;
	}
}
