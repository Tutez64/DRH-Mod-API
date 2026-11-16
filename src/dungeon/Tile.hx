package mods.api.dungeon;

/**
 * A square room of a floor, copied when read.
 *
 * @since 1.1
 */
class Tile {
	/** Side of every tile, in world units. */
	public static inline final SIZE = 900;

	/** World position of its top-left corner, in the coordinates of `Hero.x` and `Hero.y`. */
	public var x(default, null):Int;
	public var y(default, null):Int;

	/** Its id in the floor's tile library. */
	public var id(default, null):String;

	/**
	 * `STARTING_TILE`, `BASIC_TILE`, `EXIT_TILE`, `BOSS_TILE`, `PUZZLE_TILE`, `SECRET_TILE`, `TRAP_TILE`
	 * or `FILLER_TILE`, as the library says; empty when unknown.
	 */
	public var category(default, null):String;

	/**
	 * Its open sides, indexed by `UP`, `RIGHT`, `DOWN` and `LEFT`, as the library says. Two tiles are
	 * joined only when both facing sides are open; a boss arena spanning several tiles can have none and
	 * still be open.
	 */
	public var exits(default, null):Array<Bool>;

	/** The indexes of `exits`. */
	public static inline final UP = 0;
	public static inline final RIGHT = 1;
	public static inline final DOWN = 2;
	public static inline final LEFT = 3;

	@:allow(mods.api.dungeon.Floor)
	function new(x:Int, y:Int, id:String, category:String, exits:Array<Bool>) {
		this.x = x;
		this.y = y;
		this.id = id;
		this.category = category;
		this.exits = exits;
	}

	/** Whether a world point is inside it, such as a hero's position. */
	public function contains(px:Float, py:Float):Bool {
		return px >= x && px < x + SIZE && py >= y && py < y + SIZE;
	}
}
