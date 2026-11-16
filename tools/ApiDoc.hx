import haxe.macro.Expr;
import haxe.macro.Printer;
import haxeparser.Data;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

using StringTools;
using Lambda;

typedef Member = {
	var name:String;

	/** As the table shows it: `x`, or `contains(px:Float, py:Float)`. */
	var label:String;

	/** A variable's type or a function's return; `= value` for a constant without a written type. */
	var type:String;

	var doc:String;
	var isStatic:Bool;
	var isVar:Bool;

	/** Whether it has no comment and no blank line parts it from the member before: it shares its row. */
	var joins:Bool;
}

typedef ApiType = {
	var name:String;
	var pack:String;
	var doc:String;
	var members:Array<Member>;
}

/**
 * Writes the reference of `docs/api.md` from the doc comments of the public types of `src/`, between
 * its two markers. Run from the mod's folder: `haxe tools/apidoc.hxml`, or with `check` to only tell
 * whether the page is what the comments give.
 *
 * It reads syntax only, so it needs neither the game nor a compile. What it takes from the code:
 * - A type's comment, above the table of its public members; `_internal` and the mod's entry are left out.
 * - A member's comment, in its row. A member without one right under another, no blank line between,
 *   shares that one's row: `x`, `y`.
 * - `@since x.y` on a line of a comment: the version the type or the member came in. A type has one, a
 *   member has its type's unless it says otherwise, or its row's when it shares one.
 *
 * It refuses to write when the release tags contradict a `@since`, or when a member of the last
 * release is gone without a new major.
 */
class ApiDoc {
	static inline var START = "<!-- api:reference, written by tools/ApiDoc.hx from the comments of src/: change those -->";
	static inline var END = "<!-- /api:reference -->";
	static inline var PAGE = "docs/api.md";

	/** The sections of the page and the order of their types; a type not listed comes last in its package. */
	static var ORDER = [
		{pack: "mods.api", types: ["Mod", "Context", "State", "Subscription", "Dictionaries"]},
		{pack: "mods.api.dungeon", types: ["Floor", "Tile", "Monster", "Hero", "Player"]},
		{pack: "mods.api.account", types: ["Account", "Inventory", "OwnedHero", "Weapon", "Pet", "Stack"]},
		{pack: "mods.api.settings", types: ["Settings", "Flag", "Choice", "Slider", "Button", "Keys", "KeyAction"]}
	];

	static var printer = new Printer();
	static var types:Map<String, ApiType> = [];
	static var declared:Map<String, String> = [];
	static var errors:Array<String> = [];

	static function main() {
		var mod:{version:String, entry:String} = haxe.Json.parse(File.getContent("mod.json"));
		var found:Array<String> = [];
		for (file in sources("src", ""))
			for (type in parse(File.getContent("src/" + file), file))
				if (type.name != mod.entry) {
					types[type.name] = type;
					found.push(type.name);
				}
		declare();
		history(mod.version);

		var page = File.getContent(PAGE);
		var from = page.indexOf(START), to = page.indexOf(END);
		if (from < 0 || to < from)
			fail(['$PAGE: no "$START" followed by "$END"']);
		var written = page.substr(0, from) + START + "\n\n" + reference(found, page.substr(to)) + "\n\n" + page.substr(to);
		if (errors.length > 0)
			fail(errors);
		if (Sys.args().contains("check")) {
			if (written != page)
				fail(['$PAGE is not what the comments of src/ give: run haxe tools/apidoc.hxml']);
		} else
			File.saveContent(PAGE, written);
	}

	static function fail(lines:Array<String>) {
		for (line in lines)
			Sys.stderr().writeString(line + "\n");
		Sys.exit(1);
	}

	static function sources(dir:String, prefix:String):Array<String> {
		var found = [];
		var names = FileSystem.readDirectory(dir);
		names.sort(Reflect.compare);
		for (name in names) {
			if (FileSystem.isDirectory('$dir/$name')) {
				if (name != "_internal")
					found = found.concat(sources('$dir/$name', '$prefix$name/'));
			} else if (name.endsWith(".hx"))
				found.push(prefix + name);
		}
		return found;
	}

	static function parse(source:String, file:String):Array<ApiType> {
		var bytes = byte.ByteData.ofString(source);

		// The parser drops comments, so they are read from the tokens: a doc comment belongs to the
		// declaration that starts after it with no `;`, `{` or `}` in between.
		var comments:Array<{max:Int, text:String}> = [];
		var breaks:Array<Int> = [];
		var lexer = new haxeparser.HaxeLexer(bytes, file);
		while (true) {
			var token = lexer.token(haxeparser.HaxeLexer.tok);
			switch token.tok {
				case Eof:
					break;
				case Comment(text) if (text.startsWith("*")):
					comments.push({max: token.pos.max, text: text.substr(1)});
				case Semicolon | BrOpen | BrClose:
					breaks.push(token.pos.min);
				default:
			}
		}
		function docBefore(start:Int):String {
			var last = null;
			for (comment in comments)
				if (comment.max <= start)
					last = comment;
			if (last == null || breaks.exists(b -> b >= last.max && b < start))
				return "";
			return last.text;
		}

		var parsed = new haxeparser.HaxeParser(bytes, file).parse();
		var found:Array<ApiType> = [];
		for (decl in parsed.decls)
			switch decl.decl {
				case EClass(c) if (!c.flags.contains(HPrivate)):
					var members = [];
					var before:Null<Field> = null;
					var listed = false;
					for (field in c.data) {
						var doc = docBefore(field.pos.min);
						// A constructor is a member only when its comment says what a mod makes with it.
						var lists = field.access.contains(APublic) && !field.access.contains(AOverride) && (field.name != "new" || doc != "");
						if (lists) {
							var apart = before == null || bytes.readString(before.pos.max, field.pos.min - before.pos.max).split("\n").length > 2;
							members.push(member(field, doc, listed && !apart));
						}
						before = field;
						listed = lists;
					}
					found.push({
						name: c.name,
						pack: parsed.pack.join("."),
						doc: docBefore(decl.pos.min),
						members: members
					});
				case EEnum(d) if (!d.flags.contains(EPrivate)):
					errors.push('$file: ${d.name} is an enum, which this does not write yet');
				case EAbstract(d) if (!d.flags.contains(AbPrivate)):
					errors.push('$file: ${d.name} is an abstract, which this does not write yet');
				case ETypedef(d) if (!d.flags.contains(TDPrivate)):
					errors.push('$file: ${d.name} is a typedef, which this does not write yet');
				default:
			}
		return found;
	}

	static function member(field:Field, doc:String, adjacent:Bool):Member {
		var label = field.name;
		var type = "";
		var isVar = true;
		switch field.kind {
			case FVar(t, e) | FProp(_, _, t, e):
				type = t != null ? compact(printer.printComplexType(t)) : e != null ? "= " + printer.printExpr(e) : "";
			case FFun(f):
				isVar = false;
				var params = [
					for (arg in f.args)
						(arg.opt ? "?" : "") + arg.name + (arg.type == null ? "" : ":" + compact(printer.printComplexType(arg.type)))
						+ (arg.value == null ? "" : " = " + printer.printExpr(arg.value))
				];
				label += "(" + params.join(", ") + ")";
				type = f.ret == null ? "" : compact(printer.printComplexType(f.ret));
		}
		return {
			name: field.name,
			label: label,
			type: type,
			doc: doc,
			isStatic: field.access.contains(AStatic),
			isVar: isVar,
			joins: adjacent && isVar && doc == ""
		};
	}

	static function compact(type:String):String {
		return type.replace(" -> ", "->").replace("StdTypes.", "");
	}

	/** Reads each `@since`: a type's own, a member's own, else its row's, else its type's. */
	static function declare() {
		for (type in types) {
			var own = sinceOf(type.doc);
			if (own == null)
				errors.push('${type.name}: no @since');
			else
				declared[type.name] = own;
			if (paragraphs(type.doc).length == 0)
				errors.push('${type.name}: no comment');
			var row = own;
			for (m in type.members) {
				if (!m.joins)
					row = sinceOf(m.doc) == null ? own : sinceOf(m.doc);
				if (row != null)
					declared[type.name + "." + m.name] = row;
				if (!m.isVar && paragraphs(m.doc).length == 0)
					errors.push('${type.name}.${m.name}: no comment');
			}
		}
	}

	static function sinceOf(doc:String):Null<String> {
		var tag = ~/^\s*\*?\s*@since\s+(\d+\.\d+)\s*$/m;
		return tag.match(doc) ? tag.matched(1) : null;
	}

	/** Sets each `@since` against the release tags, and what the last release had against what is there. */
	static function history(version:String) {
		var tags = git(["tag"]).split("\n").filter(t -> ~/^v\d+\.\d+\.\d+$/.match(t));
		if (tags.length == 0) {
			Sys.stderr().writeString("no release tag here: the @since are not checked\n");
			return;
		}
		tags.sort((a, b) -> compare(a.substr(1), b.substr(1)));
		var first:Map<String, String> = [];
		var last:Array<String> = [];
		for (tag in tags) {
			last = [];
			var minor = tag.substr(1).split(".").slice(0, 2).join(".");
			var entry:String = haxe.Json.parse(git(["show", '$tag:mod.json'])).entry;
			for (file in git(["ls-tree", "-r", "--name-only", tag, "src"]).split("\n"))
				if (file.endsWith(".hx") && file.indexOf("/_internal/") < 0)
					for (type in parse(git(["show", '$tag:$file']), '$tag:$file'))
						if (type.name != entry)
							for (key in [type.name].concat(type.members.map(m -> type.name + "." + m.name))) {
								last.push(key);
								if (!first.exists(key))
									first[key] = minor;
							}
		}

		var released = tags[tags.length - 1].substr(1);
		var upcoming = tags.contains("v" + version) ? null : version.split(".").slice(0, 2).join(".");
		var keys = [for (key in declared.keys()) key];
		keys.sort(Reflect.compare);
		for (key in keys) {
			var said = declared[key];
			if (first.exists(key)) {
				if (said != first[key])
					errors.push('$key: @since $said, but it came in ${first[key]}');
			} else if (upcoming != null ? said != upcoming : compare(said, released) <= 0)
				errors.push('$key: @since $said, but it is in no release: ' + (upcoming != null ? upcoming : 'a version after $released'));
		}
		if (version.split(".")[0] == released.split(".")[0])
			for (key in last)
				if (!declared.exists(key))
					errors.push('$key: in $released and gone, which is a major');
	}

	static function compare(a:String, b:String):Int {
		var x = a.split(".").map(Std.parseInt), y = b.split(".").map(Std.parseInt);
		for (i in 0...x.length)
			if (i < y.length && x[i] != y[i])
				return x[i] - y[i];
		return 0;
	}

	static function git(args:Array<String>):String {
		var process = new Process("git", args);
		var out = process.stdout.readAll().toString();
		var error = process.stderr.readAll().toString();
		if (process.exitCode() != 0)
			fail(["git " + args.join(" ") + ": " + error]);
		process.close();
		return out.rtrim();
	}

	/** The contents, then a section per package and a heading per type. `after` is the page below, for its sections. */
	static function reference(found:Array<String>, after:String):String {
		var sections = ORDER.map(s -> {pack: s.pack, types: s.types.filter(name -> types.exists(name))});
		for (name in found) {
			if (sections.exists(s -> s.types.contains(name)))
				continue;
			var section = sections.find(s -> s.pack == types[name].pack);
			if (section == null)
				sections.push(section = {pack: types[name].pack, types: []});
			section.types.push(name);
		}
		var contents = [];
		var body = [];
		for (section in sections) {
			contents.push('- [`${section.pack}`](#${anchor(section.pack)}): ' + section.types.map(name -> '[$name](#${anchor(name)})').join(", "));
			body.push('## ${section.pack}');
			for (name in section.types)
				body.push('### $name\n\n' + render(types[name]));
		}
		var heading = ~/^## (.+)$/m;
		while (heading.match(after)) {
			contents.push('- [${heading.matched(1)}](#${anchor(heading.matched(1))})');
			after = heading.matchedRight();
		}
		return contents.join("\n") + "\n\n" + body.join("\n\n");
	}

	/** A heading's anchor as GitHub makes it. */
	static function anchor(heading:String):String {
		return ~/[^a-z0-9 _-]/g.replace(heading.toLowerCase(), "").replace(" ", "-");
	}

	static function render(type:ApiType):String {
		var out = new StringBuf();
		out.add('`${type.pack}.${type.name}`, since ${declared[type.name]}\n\n');
		out.add(paragraphs(type.doc).map(p -> link(p, type.name)).join("\n\n"));

		var rows:Array<Array<Member>> = [];
		for (m in type.members)
			if (m.joins)
				rows[rows.length - 1].push(m);
			else
				rows.push([m]);
		if (rows.length == 0)
			return out.toString();

		out.add("\n\n| Member | Type | Since | What |\n| --- | --- | --- | --- |\n");
		for (row in rows) {
			var names = row.map(m -> "`" + (m.isStatic ? type.name + "." : "") + cell(m.label) + "`").join(", ");
			// One type when the row's members share it, else each member's.
			var kinds = row.map(m -> m.type.startsWith("= ") ? "`" + cell(m.type.substr(2)) + "`" : typeLink(m.type, type.name));
			if (!row[0].type.startsWith("= ") && kinds.foreach(kind -> kind == kinds[0]))
				kinds = [kinds[0]];
			var what = cell(link(paragraphs(row[0].doc).join(" "), type.name));
			out.add('| $names | ${kinds.join(", ")} | ${declared[type.name + "." + row[0].name]} | $what |\n');
		}
		return out.toString().rtrim();
	}

	/** A comment's paragraphs, each on one line, without its `@since`. */
	static function paragraphs(doc:String):Array<String> {
		var found = [];
		var current = [];
		for (line in doc.split("\n")) {
			line = ~/^\s*\*?\s?/.replace(line, "").rtrim();
			if (line == "" || line.startsWith("@since ")) {
				if (current.length > 0)
					found.push(current.join(" "));
				current = [];
			} else
				current.push(line);
		}
		if (current.length > 0)
			found.push(current.join(" "));
		return found;
	}

	/** Links the code spans naming another type of the page, such as `Hero.x`. */
	static function link(text:String, from:String):String {
		return ~/`([A-Z]\w*)(\.\w+)?`/g.map(text, function(m) {
			var name = m.matched(1);
			return types.exists(name) && name != from ? '[${m.matched(0)}](#${anchor(name)})' : m.matched(0);
		});
	}

	/** A type as code, linked when it names one other type of the page. */
	static function typeLink(type:String, from:String):String {
		if (type == "")
			return "";
		var named = [];
		~/[A-Z]\w*/g.map(type, function(m) {
			if (types.exists(m.matched(0)) && m.matched(0) != from && !named.contains(m.matched(0)))
				named.push(m.matched(0));
			return "";
		});
		var code = "`" + cell(type) + "`";
		return named.length == 1 ? '[$code](#${anchor(named[0])})' : code;
	}

	static function cell(text:String):String {
		return text.replace("|", "\\|");
	}
}
