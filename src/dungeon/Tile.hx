package mods.api.dungeon;

/** One tile of a dungeon floor, a square room, copied when read. */
class Tile {
	/** Side of every tile, in world units. */
	public static inline final SIZE = 900;

	/** World position of the tile's top-left corner, in the coordinates of `Hero.x` and `Hero.y`. */
	public var x(default, null):Int;

	public var y(default, null):Int;

	/** The tile's id in its library. */
	public var id(default, null):String;

	/**
	 * Its category in the tile library: `STARTING_TILE`, `BASIC_TILE`, `EXIT_TILE`, `BOSS_TILE`,
	 * `PUZZLE_TILE`, `SECRET_TILE`, `TRAP_TILE`, `FILLER_TILE`. Empty when unknown.
	 */
	public var category(default, null):String;

	/**
	 * Its open sides, by `UP`, `RIGHT`, `DOWN` and `LEFT`, as the library says. Two tiles are joined only
	 * when both facing sides are open; a boss arena spanning several tiles can have none and still be open.
	 */
	public var exits(default, null):Array<Bool>;

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

	/** Whether the world point `(px, py)` is inside the tile. */
	public function contains(px:Float, py:Float):Bool {
		return px >= x && px < x + SIZE && py >= y && py < y + SIZE;
	}
}
