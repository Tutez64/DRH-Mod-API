package mods.api._internal;

import openfl.Vector;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormatAlign;
import settings.SettingsPopup;
import settings.view.SettingsList;
import settings.view.rows.SettingRow;
import stateMachine.mainStateMachine.TownState;

/**
 * Dresses the game's settings menu while it is open: a header with each mod's name above its rows,
 * which the game's list has no row for, and a label too long for its field brought to fit.
 *
 * The game builds its rows anew each time a tab is shown, and tells nobody: the list is looked at on
 * each frame while the menu is open, and dressed when its rows are new ones.
 */
@:allow(mods.api)
class OptionsMenu {
	static inline final HEADER_COLOR = 0xFFC400;

	/** A header's text against a row's label. */
	static inline final HEADER_SCALE = 0.62;

	/** How small a label may get to fit its field: past that it is cut, as the game cuts its own. */
	static inline final SMALLEST = 0.6;

	/** The rows last dressed, known by the first of them. */
	static var dressed:Null<SettingRow>;

	static var dressedCount:Int = 0;

	static var headers:Array<Sprite> = [];

	/** The game's menu could not be dressed: its rows name their mod themselves from then on. */
	static var failed:Bool = false;

	static function start():Void {
		if (Hub.core != null && Hub.core.overlay != null)
			Hub.core.overlay.addEventListener(Event.ENTER_FRAME, frame);
	}

	static function frame(event:Event):Void {
		if (failed || Options.model == null)
			return;
		try {
			var facade = Hub.facade();
			var layer = facade.menuNavigationController.getTopUILayer();
			if (layer != Options.MENU_LAYER && layer != Options.RESET_LAYER) {
				dressed = null;
				headers = [];
				return;
			}
			var list = shownList();
			var rows:Vector<SettingRow> = list == null ? null : @:privateAccess list.mRows;
			if (rows == null || rows.length == 0 || (rows[0] == dressed && rows.length == dressedCount))
				return;
			dressed = rows[0];
			dressedCount = rows.length;
			dress(list, rows);
		} catch (e:Dynamic) {
			failed = true;
			Hub.log("settings: the menu shows the mods' rows without their headers: " + Std.string(e));
			Options.nameRows();
		}
	}

	/** The list of the settings popup that is open, the town's or the dungeon's. */
	static function shownList():Null<SettingsList> {
		var facade = Hub.facade();
		var popup:Dynamic = null;
		var hud:Dynamic = facade.hud;
		if (hud != null)
			popup = Reflect.field(hud, "mSettingsPopup");
		if (popup == null) {
			var town = Std.downcast(facade.mainStateMachine.currentState, TownState);
			var home:Dynamic = town == null || town.townStateMachine == null ? null : Reflect.field(town.townStateMachine, "mHomeState");
			if (home != null)
				popup = Reflect.field(home, "mSettingsPopup");
		}
		var shown = Std.downcast(popup, SettingsPopup);
		return shown == null ? null : @:privateAccess shown.mList;
	}

	static function dress(list:SettingsList, rows:Vector<SettingRow>):Void {
		for (header in headers)
			if (header.parent != null)
				header.parent.removeChild(header);
		headers = [];
		var holder:DisplayObjectContainer = @:privateAccess list.mScrollPane.root;
		// Where the game's own labels start, the leftmost of them.
		var left = 1e9;
		for (i in 0...rows.length) {
			var label:TextField = @:privateAccess rows[i].mNameLabel;
			if (label != null && label.x < left)
				left = label.x;
		}
		if (left > 1e8)
			left = 0;
		var shift = 0.0;
		var above:Null<ModOptions> = null;
		for (i in 0...rows.length) {
			var row = rows[i];
			var entry = Options.entryOf(row.definition);
			var owner = entry == null ? null : entry.owner;
			if (owner != null && owner != above) {
				var header = makeHeader(owner.name, row, left);
				header.y = row.root.y + shift;
				holder.addChild(header);
				headers.push(header);
				shift += header.height + 4;
			}
			above = owner;
			row.root.y += shift;
			if (entry != null)
				fit(@:privateAccess row.mNameLabel);
		}
		if (shift > 0) {
			var height:Float = @:privateAccess list.mContentHeight;
			@:privateAccess list.mContentHeight = height + shift;
			@:privateAccess list.updateScrollRange();
		}
	}

	/** A mod's name over a line, in the lettering of the row under it. */
	static function makeHeader(name:String, row:SettingRow, left:Float):Sprite {
		var header = new Sprite();
		header.mouseEnabled = false;
		header.mouseChildren = false;
		var width:Float = row.root.width;
		var title = new TextField();
		var label:TextField = @:privateAccess row.mNameLabel;
		var size = 28.0;
		if (label != null) {
			var format = label.length > 0 ? label.getTextFormat(0, 1) : label.defaultTextFormat;
			if (format.size != null)
				size = format.size;
			format.size = Std.int(Math.max(10, size * HEADER_SCALE));
			format.color = HEADER_COLOR;
			format.align = TextFormatAlign.LEFT;
			title.embedFonts = label.embedFonts;
			title.defaultTextFormat = format;
			title.filters = label.filters;
		}
		title.selectable = false;
		title.mouseEnabled = false;
		title.text = name.toUpperCase();
		title.x = left;
		title.width = Math.max(40, width - left * 2);
		title.height = title.textHeight + 6;
		header.addChild(title);
		header.graphics.beginFill(HEADER_COLOR, 0.7);
		header.graphics.drawRect(left, title.height + 1, Math.max(40, width - left * 2), 2);
		header.graphics.endFill();
		return header;
	}

	/** A label wider than its field is made smaller in place, down to `SMALLEST`. */
	static function fit(label:Null<TextField>):Void {
		if (label == null || label.scaleX != 1 || label.scaleY != 1)
			return;
		var room = label.width - 4;
		var needed = label.textWidth;
		if (room <= 0 || needed <= room)
			return;
		var scale = Math.max(SMALLEST, room / needed);
		var width = label.width;
		var height = label.height;
		label.width = width / scale;
		label.scaleX = label.scaleY = scale;
		label.y += height * (1 - scale) / 2;
	}
}
