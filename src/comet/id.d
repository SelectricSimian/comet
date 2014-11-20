module comet.id;

private alias integral_type = uint;

struct S_Id {
	private integral_type machine_readable;
	
	private static integral_type maxId;
	private static integral_type[string] cache;
	private static string[integral_type] human_readable_lookup;
	
	this(string strId) {
		integral_type* cached = strId in cache;
		if (cached !is null)
			machine_readable = *cached;
		else {
			integral_type result = maxId++;
			machine_readable = result;
			cache[strId] = result;
			human_readable_lookup[result] = strId;
		}
	}
	
	static S_Id genUnique(string human_readable) {
		integral_type result = maxId++;
		human_readable_lookup[result] = "$" ~ human_readable;
		S_Id idResult;
		idResult.machine_readable = result;
		return idResult;
	}
	
	string toString() {
		return ":" ~ human_readable_lookup[machine_readable];
	}
}

/// for use as a mixin
string useId(string id, bool dontNeedFn = false) {
	string d_id;
	switch (id) {
		case "=":
			d_id = "equals";
			break;
		case "+":
			d_id = "plus";
			break;
		case "-":
			d_id = "minus";
			break;
		case "*":
			d_id = "times";
			break;
		case "/":
			d_id = "divide";
			break;
		case "&":
			d_id = "and";
			break;
		case "|":
			d_id = "or";
			break;
		case ">":
			d_id = "greater";
			break;
		case "<":
			d_id = "less";
			break;
		case ">=":
			d_id = "greater_equal";
			break;
		case "<=":
			d_id = "less_equal";
			break;
		case "..":
			d_id = "join";
			break;
		default:
			d_id = id;
	}
	
	if (dontNeedFn) {
		string inited = d_id ~ "_id_INTERNAL_is_initialized";
		return
		"static bool " ~ inited ~ " = false;\n" ~
		"static S_Id " ~ d_id ~ "_id;\n" ~
		"if (!" ~ inited ~ ") {\n" ~
		inited ~ " = true;\n" ~
		d_id ~ "_id = S_Id(\"" ~ id ~ "\");\n" ~
		"}";
	} else {
		string inited = d_id ~ "_id_INTERNAL_is_initialized";
		return
		"static bool " ~ inited ~ " = false;\n" ~
		"static S_Id " ~ d_id ~ "_id;\n" ~
		"static S_Function " ~ id ~ "_fn;\n" ~
		"if (!" ~ inited ~ ") {\n" ~
		inited ~ " = true;\n" ~
		d_id ~ "_id = S_Id(\"" ~ id ~ "\");\n" ~
		d_id ~ "_fn = makeId(" ~ d_id ~ "_id);\n" ~
		"}";
	}
}

unittest
{
	import std.stdio;
	import comet.fn;
	import comet.primitive;
	mixin(useId("hello"));
	//writeln(hello_id);
	//writeln(S_Id("hello") == hello_id);
}
