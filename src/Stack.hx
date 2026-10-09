package mods.api;

/** Some of one stackable item, such as a potion or a bomb, copied when read. */
class Stack {
	/** GameMaster stackable id. */
	public var id(default, null):UInt;

	/** Display name, as the inventory shows it. */
	public var name(default, null):String;

	public var count(default, null):UInt;

	@:allow(mods.api.Inventory, mods.api.OwnedHero)
	function new(id:UInt, name:String, count:UInt) {
		this.id = id;
		this.name = name;
		this.count = count;
	}
}
