package mods.api.account;

/** Some of one stackable item, such as a potion or a bomb, copied when read. */
class Stack {
	/** GameMaster stackable id. */
	public var id(default, null):UInt;

	/** Display name, as the inventory shows it. */
	public var name(default, null):String;

	public var count(default, null):UInt;

	@:allow(mods.api.account.Inventory, mods.api.account.OwnedHero)
	function new(id:UInt, name:String, count:UInt) {
		this.id = id;
		this.name = name;
		this.count = count;
	}
}
