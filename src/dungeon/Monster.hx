package mods.api.dungeon;

/**
 * A living enemy of the heroes, copied when read or when an event hands it. The game has no reliable
 * notion of a boss: tell one by its `name`, and its dungeon by the floor's `map`.
 *
 * @since 1.1
 */
class Monster {
	/** Its object id on the floor, the same from one read to the next. */
	public var id(default, null):UInt;

	/** Its name in the game's data, such as `Golem Boss`. */
	public var name(default, null):String;

	/** World position, in the coordinates of `Hero.x` and `Hero.y`. */
	public var x(default, null):Float;
	public var y(default, null):Float;

	/** Whether the game shows a health bar over it, as it does for the big ones: bosses, minibosses, and some others. */
	public var healthBar(default, null):Bool;

	/**
	 * Its hit points, 0 once dead, and what they are when it is whole, with what its buffs add.
	 * @since 1.5
	 */
	public var hp(default, null):UInt;
	public var maxHp(default, null):UInt;

	@:allow(mods.api)
	function new(id:UInt, name:String, x:Float, y:Float, healthBar:Bool, hp:UInt, maxHp:UInt) {
		this.id = id;
		this.name = name;
		this.x = x;
		this.y = y;
		this.healthBar = healthBar;
		this.hp = hp;
		this.maxHp = maxHp;
	}
}
