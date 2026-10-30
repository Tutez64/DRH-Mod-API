package mods.api.dungeon;

/** One living enemy of the heroes on a floor, copied when read: anything of their foes' team. */
class Monster {
	/** Its object id on the floor, the same from one read to the next. */
	public var id(default, null):UInt;

	/** Its name in the game's data, such as `Golem Boss`. */
	public var name(default, null):String;

	/** World position, in the coordinates of `Hero.x` and `Hero.y`. */
	public var x(default, null):Float;

	public var y(default, null):Float;

	/** Whether the game shows a health bar over it, as it does for the big ones: not only bosses. */
	public var healthBar(default, null):Bool;

	@:allow(mods.api.dungeon.Floor)
	function new(id:UInt, name:String, x:Float, y:Float, healthBar:Bool) {
		this.id = id;
		this.name = name;
		this.x = x;
		this.y = y;
		this.healthBar = healthBar;
	}
}
