module comet.primitive;

import comet.id;
import comet.fn;

import std.string : format;
import std.stdio;
import std.conv : to;

enum S_Function s_null_constant = null;

struct S_DirectDefObj {
	S_Function obj;
	alias obj this;
	
	S_Function[S_Id] methods;
}

S_DirectDefObj makeObj() {
	mixin(useId("def", true));
	
	S_Function[S_Id] methods;
	
	S_Function defDg(S_Function[] params) {
		S_Function idToDef = params[0];
		S_Function valToDef = params[1];
		methods[extract!S_Id(idToDef)] = valToDef;
		return s_null_constant;
	}
	
	methods[def_id] = curryHelper(2, &defDg);

	mixin(useId("is_defined", true));
	S_Function is_defined(S_Function sym) {
		S_Id toCheck = extract!S_Id(sym);
		S_Function* thisMatch = toCheck in methods;
		return makeBool(thisMatch !is null);
	}
	methods[is_defined_id] = new S_CompiledFunction(&is_defined);
	
	mixin(useId("get_defs", true));
	S_Function get_defs(S_Function param) {
		assert(isNull(param), "get_defs takes no params");
		S_Function[] result = new S_Function[methods.length];
		foreach (i, methodId; methods.keys) {
			result[i] = makeId(methodId);
		}
		return makeLst(result);
	}
	methods[get_defs_id] = new S_CompiledFunction(&get_defs);
	
	mixin(useId("undef", true));
	S_Function undef(S_Function sym) {
		S_Id idToUndef = extract!S_Id(sym);
		methods.remove(idToUndef);
		return s_null_constant;
	}
	methods[undef_id] = new S_CompiledFunction(&undef);
	
	S_Function resultDg(S_Function idToGet) {
		import std.conv : to;
		S_Function* methodMatch = extract!S_Id(idToGet) in methods;
		assert(methodMatch !is null, "Method " ~ to!string(extract!S_Id(idToGet)) ~ " is not defined!");
		return *methodMatch;
	}
	
	return S_DirectDefObj(new S_CompiledFunction(&resultDg), methods);
}

S_DirectDefObj makeDataObj(S_DataFunction data) {
	S_DirectDefObj objBase = makeObj();
	
	S_Function result(S_Function idToGet) {
		S_DataRequestDataFunction dataRequest = cast(S_DataRequestDataFunction)idToGet;
		if (dataRequest !is null) {
			return data;
		}
		return objBase.obj.call(idToGet);
	}
	
	return S_DirectDefObj(new S_CompiledFunction(&result), objBase.methods);
}

private class S_Wrapper(T) : S_DataFunction {
	T val;
}

T extract(T)(S_Function dataContainer) {
	S_DataFunction data = cast(S_DataFunction)dataContainer.call(dataRequest);
	assert(data !is null, "Object is not a data container!");
	S_Wrapper!T wrapper = cast(S_Wrapper!T)data;
	assert(wrapper !is null, "Object %s does not wrap data of correct type (%s)!".format(dataContainer, T.stringof));
	return wrapper.val;
}

S_Wrapper!T wrap(T)(T val) {
	S_Wrapper!T result = new S_Wrapper!T;
	result.val = val;
	return result;
}

private class S_DataRequestDataFunction : S_DataFunction {}

private S_DataRequestDataFunction dataRequest() {
	return new S_DataRequestDataFunction;
}

S_Function makeId(S_Id id) {
	// to be implemented
	//mixin(useId("=", true))
	//mixin(useId("to_string", true));
	
	S_DirectDefObj result = makeDataObj(wrap(id));
	
	mixin(useId("to_str", true));
	S_Function to_str(S_Function param) {
		assert(isNull(param), "to_str takes no arguments!");
		return makeStr(id.toString());
	}
	result.methods[to_str_id] = new S_CompiledFunction(&to_str);
	
	return result;
}

alias num_type = double;
S_Function makeNum(num_type val) {
	S_DirectDefObj result = makeDataObj(wrap(val));
	
	mixin(useId("+", true));
	S_Function add(S_Function other) {
		num_type num = extract!num_type(other);
		return makeNum(num + val);
	}
	result.methods[plus_id] = new S_CompiledFunction(&add);
	
	mixin(useId("-", true));
	S_Function sub(S_Function other) {
		num_type num = extract!num_type(other);
		return makeNum(val - num);
	}
	result.methods[minus_id] = new S_CompiledFunction(&sub);
	
	mixin(useId("*", true));
	S_Function mul(S_Function other) {
		num_type num = extract!num_type(other);
		return makeNum(val * num);
	}
	result.methods[times_id] = new S_CompiledFunction(&mul);
	
	mixin(useId("/", true));
	S_Function div(S_Function other) {
		num_type num = extract!num_type(other);
		return makeNum(val / num);
	}
	result.methods[divide_id] = new S_CompiledFunction(&div);
	
	mixin(useId("to_str", true));
	S_Function to_str(S_Function param) {
		assert(isNull(param), "to_str takes no parameters!");
		import std.conv : to;
		return makeStr(to!string(val));
	}
	result.methods[to_str_id] = new S_CompiledFunction(&to_str);
	
	mixin(useId("=", true));
	S_Function equals(S_Function other) {
		num_type num = extract!num_type(other);
		return makeBool(val == num);
	}
	result.methods[equals_id] = new S_CompiledFunction(&equals);
	
	mixin(useId(">", true));
	S_Function greater(S_Function other) {
		num_type num = extract!num_type(other);
		return makeBool(val > num);
	}
	result.methods[greater_id] = new S_CompiledFunction(&greater);
	
	mixin(useId("<", true));
	S_Function less(S_Function other) {
		num_type num = extract!num_type(other);
		return makeBool(val < num);
	}
	result.methods[less_id] = new S_CompiledFunction(&less);
	
	return result;
}

size_t toIndex(size_t length, S_Function param) {
	num_type num = extract!num_type(param);
	assert(isInt(num), "Index must be an integer!");
	if (num > 0) {
		assert(num < length, "Index not within bounds");
		return cast(size_t)num;
	}
	else {
		assert(num >= -length, "Index not within bounds");
		return cast(size_t)(length + num);
	}
}

S_Function makeStr(string val) {
	S_DirectDefObj result = makeDataObj(wrap(val));
	
	mixin(useId("to_str", true));
	S_Function to_str(S_Function param) {
		assert(isNull(param), "to_str takes no parameters!");
		return result;
	}
	result.methods[to_str_id] = new S_CompiledFunction(&to_str);
	
	mixin(useId("=", true));
	S_Function equals(S_Function other) {
		string str = extract!string(other);
		return makeBool(val == str);
	}
	result.methods[equals_id] = new S_CompiledFunction(&equals);
	
	mixin(useId("sub", true));
	S_Function sub(S_Function[] params) {
		size_t i = toIndex(val.length, params[0]);
		size_t j = toIndex(val.length, params[1]);
		return makeStr(val[i..j]);
	}
	result.methods[sub_id] = curryHelper(2, &sub);
	
	mixin(useId("..", true));
	S_Function join(S_Function other) {
		string str = extract!string(other);
		return makeStr(val ~ str);
	}
	result.methods[join_id] = new S_CompiledFunction(&join);
	
	mixin(useId("byte", true));
	S_Function get_byte(S_Function param) {
		assert(isNull(param), "byte takes no parameters!");
		assert(val.length == 1, "Cannot take byte of anything but a single character!");
		return makeNum(val[0]);
	}
	result.methods[byte_id] = new S_CompiledFunction(&get_byte);
	
	return result;
}

S_Function makeBool(bool b) {
	static bool initialized = false;
	static S_DirectDefObj trueConst;
	static S_DirectDefObj falseConst;
	if (!initialized) {
		trueConst = makeDataObj(wrap(true));
		falseConst = makeDataObj(wrap(false));
		
		mixin(useId("if", true));
		mixin(useId("if_else", true));
		
		S_Function trueIf(S_Function then) {
			return then.call(s_null_constant);
		}
		trueConst.methods[if_id] = new S_CompiledFunction(&trueIf);
		
		S_Function falseIf(S_Function then) {
			return s_null_constant;
		}
		falseConst.methods[if_id] = new S_CompiledFunction(&falseIf);
		
		S_Function trueIfElse(S_Function[] clauses) {
			return clauses[0].call(s_null_constant);
		}
		trueConst.methods[if_else_id] = curryHelper(2, &trueIfElse);
		
		S_Function falseIfElse(S_Function[] clauses) {
			return clauses[1].call(s_null_constant);
		}
		falseConst.methods[if_else_id] = curryHelper(2, &falseIfElse);
		
		mixin(useId("to_str", true));
		S_Function toStrTrue(S_Function param) {
			assert(isNull(param), "to_str takes no parameters!");
			return makeStr("true");
		}
		trueConst.methods[to_str_id] = new S_CompiledFunction(&toStrTrue);
		
		S_Function toStrFalse(S_Function param) {
			assert(isNull(param), "to_str takes no parameters!");
			return makeStr("false");
		}
		falseConst.methods[to_str_id] = new S_CompiledFunction(&toStrFalse);
		
		mixin(useId("not", true));
		trueConst.methods[not_id] = falseConst;
		falseConst.methods[not_id] = trueConst;
		
		initialized = true;
	}
	
	if (b) {
		return trueConst;
	} else {
		return falseConst;
	}
}

S_Function makeLst(S_Function[] vals) {
	size_t length = 0;
	
	S_DirectDefObj result = makeObj();
	
	mixin(useId("get", true));
	S_Function get(S_Function param) {
		//num_type i = extract!num_type(param);
		//if (i != cast(num_type)cast(int)i) {
		//	throw new Exception("List index must be a non-negative integer!");
		//}
		return vals[toIndex(vals.length, param)];
	}
	result.methods[get_id] = new S_CompiledFunction(&get);
	
	mixin(useId("length", true));
	S_Function get_length(S_Function param) {
		assert(isNull(param), "length takes no parameters!");
		return makeNum(length);
	}
	result.methods[length_id] = new S_CompiledFunction(&get_length);
	
	mixin(useId("give", true));
	S_Function give(S_Function param) {
		if (vals.length <= length) {
			if (vals.length)
				vals.length *= 2;
			else
				vals.length = 1;
		}
		length++;
		vals[length - 1] = param;
		return s_null_constant;
	}
	result.methods[give_id] = new S_CompiledFunction(&give);
	
	mixin(useId("set", true));
	S_Function set(S_Function[] params) {
		//num_type i = extract!num_type(param[0]);
		S_Function val = params[1];
		return vals[toIndex(vals.length, params[0])];
		
		//assert(isInt(i), "Index must be an integer!");
		//if (i > 0) {
		//	assert(i < length, "Index out of bounds!");
		//	return vals[i];
		//}
		//else {
		//	assert(i >= -length, "Index out of bounds!");
		//	return vals[length + i];
		//}
	}
	result.methods[set_id] = curryHelper(2, &set);
	
	mixin(useId("each", true));
	S_Function each(S_Function blk) {
		foreach (i; 0..length) {
			blk.call(vals[i]);
		}
		return s_null_constant;
	}
	result.methods[each_id] = new S_CompiledFunction(&each);
	
	mixin(useId("to_str", true));
	S_Function to_str(S_Function param) {
		assert(isNull(param), "to_str takes no parameters!");
		return makeStr(to!string(vals[0..length]));
	}
	result.methods[to_str_id] = new S_CompiledFunction(&to_str);
	
	return result;
}

S_Function makeLst() {
	return makeLst([]);
}

S_DirectDefObj makeEnv(S_Function parent) {
	S_Function[S_Id] defs;
	
	mixin(useId("def"));
	mixin(useId("is_defined"));
	
	S_Function def(S_Function[] params) {
		//writeln("Params to def: ", params);
		S_Id idToDef = extract!S_Id(params[0]);
		S_Function valToDef = params[1];
		S_Function* thisMatch = idToDef in defs;
		if (thisMatch !is null) {
			*thisMatch = valToDef;
			return s_null_constant;
		}
		if (extract!bool(parent.call(is_defined_fn).call(params[0]))) {
			return parent.call(def_fn).call(params[0]).call(params[1]);
		} else {
			defs[idToDef] = valToDef;
			return s_null_constant;
		}
	}
	defs[def_id] = curryHelper(2, &def);
	
	mixin(useId("def_shadow", true));
	S_Function def_shadow(S_Function[] params) {
		S_Id idToDef = extract!S_Id(params[0]);
		S_Function valToDef = params[1];
		defs[idToDef] = valToDef;
		return s_null_constant;
	}
	defs[def_shadow_id] = curryHelper(2, &def_shadow);
	
	S_Function is_defined(S_Function sym) {
		S_Id id = extract!S_Id(sym);
		S_Function* thisMatch = id in defs;
		if (thisMatch !is null) {
			return makeBool(true);
		}
		return parent.call(is_defined_fn).call(sym);
	}
	defs[is_defined_id] = new S_CompiledFunction(&is_defined);
	
	mixin(useId("undef"));
	S_Function undef(S_Function param) {
		S_Id idToUndef = extract!S_Id(param);
		S_Function* thisMatch = idToUndef in defs;
		if (thisMatch !is null) {
			defs.remove(idToUndef);
			return s_null_constant;
		} else {
			return parent.call(undef_fn).call(param);
		}
	}
	defs[undef_id] = new S_CompiledFunction(&undef);
	
	mixin(useId("get_defs", true));
	S_Function get_defs(S_Function param) {
		S_Function[] result = new S_Function[defs.length];
		foreach (i, key; defs.keys) {
			result[i] = makeId(key);
		}
		return makeLst(result);
	}
	defs[get_defs_id] = new S_CompiledFunction(&get_defs);
	
	S_Function result(S_Function sym) {
		S_Id id = extract!S_Id(sym);
		S_Function* thisMatch = id in defs;
		if (thisMatch !is null) {
			return *thisMatch;
		}
		return parent.call(sym);
	}
	
	mixin(useId("to_str", true));
	S_Function to_str(S_Function param) {
		assert(isNull(param), "to_str takes no parameters!");
		return makeStr("env");
	}
	defs[to_str_id] = new S_CompiledFunction(&to_str);
	
	S_Function resultFn = new S_CompiledFunction(&result);
	
	mixin(useId("instantiate", true));
	S_Function instantiate(S_Function param) {
		assert(isNull(param), "Instantiate takes no parameters!");
		return makeEnv(resultFn);
	}
	defs[instantiate_id] = new S_CompiledFunction(&instantiate);
	
	return S_DirectDefObj(resultFn, defs);
}

S_Function makeSyntax(S_Expr[] ops) {
	S_DirectDefObj result = makeObj();
	
	mixin(useId("bind"));
	S_Function bind(S_Function[] params) {
		S_Function paramId = params[0];
		S_Function env = params[1];
		S_InterpretedFunction result = new S_InterpretedFunction(env, ops);
		result.paramNameIdFn = paramId;
		return result;
	}
	result.methods[bind_id] = curryHelper(2, &bind);

	mixin(useId("bind_nullary"));
	S_Function bind_nullary(S_Function env) {
		S_InterpretedFunction result = new S_InterpretedFunction(env, ops);
		return result;
	}
	result.methods[bind_nullary_id] = new S_CompiledFunction(&bind_nullary);
	
	return result;
}

bool isNull(S_Function fn) {
	return fn is s_null_constant;
}

bool isInt(num_type n) {
	return n == cast(num_type)cast(int)n;
}

//unittest {
//	import std.stdio;
//	S_Function a = makeNum(1.0);
//	S_Function b = makeNum(10.50001);
//	writeln(b.call(makeId(S_Id("-"))).call(a));
//}
