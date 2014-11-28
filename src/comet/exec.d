module comet.exec;

import comet.primitive;
import comet.fn;
import comet.parse;
import comet.id;

import std.stdio;

S_Function makeWrite() {
	S_Function result(S_Function toWrite) {
		writeln(toWrite);
		return s_null_constant;
	}
	return new S_CompiledFunction(&result);
}

S_Function makeRead() {
	S_Function result(S_Function param) {
		assert(isNull(param), "read takes no arguments!");
		return makeStr(readln());
	}
	return new S_CompiledFunction(&result);
}

S_Function makeObjCtr() {
	S_Function result(S_Function param) {
		assert(isNull(param), "obj takes no arguments!");
		return makeObj();
	}
	return new S_CompiledFunction(&result);
}

S_Function makeLstCtr() {
	S_Function result(S_Function param) {
		//assert(isNull(param), "lst takes no arguments!");
		mixin(useId("give", true));
		S_DirectDefObj result = makeLst();
		param.call(result.methods[give_id]);
		return result;
	}
	return new S_CompiledFunction(&result);
}

S_Function makeWhile() {
	S_Function result(S_Function[] params) {
		S_Function condition = params[0];
		S_Function bodyFn = params[1];
		while (extract!bool(condition.call(s_null_constant))) {
			bodyFn.call(s_null_constant);
		}
		return s_null_constant;
	}
	return curryHelper(2, &result);
}

S_Function makeLoop() {
	S_Function result(S_Function[] params) {
		num_type times = extract!num_type(params[0]);
		for (int i = 0; i < times; i++) {
			params[1].call(makeNum(i));
		}
		return s_null_constant;
	}
	return curryHelper(2, &result);
}

S_Function makeImport() {
	static S_Function[string] cache;
	
	S_Function result(S_Function pathFn) {
		string path = extract!string(pathFn);
		S_Function* cacheMatch = path in cache;
		if (cacheMatch !is null) return *cacheMatch;
		S_Function output;
		cache[path] = output = execFile(path);
		return output;
	}
	return new S_CompiledFunction(&result);
}

S_Function makeExit() {
	import core.stdc.stdlib : exit;
	S_Function result(S_Function param) {
		exit(0);
		assert(0);
	}
	return new S_CompiledFunction(&result);
}

import std.math : floor, ceil;

S_Function makeFloor() {
	S_Function result(S_Function param) {
		num_type num = extract!num_type(param);
		return makeNum(floor(num));
	}
	return new S_CompiledFunction(&result);
}

S_Function makeCeil() {
	S_Function result(S_Function param) {
		num_type num = extract!num_type(param);
		return makeNum(ceil(num));
	}
	return new S_CompiledFunction(&result);
}

S_Function makeTopEnv() {
	S_DirectDefObj top = makeObj();
	mixin(useId("write", true));
	mixin(useId("read", true));
	mixin(useId("obj", true));
	mixin(useId("lst", true));
	mixin(useId("true", true));
	mixin(useId("false", true));
	mixin(useId("while", true));
	mixin(useId("loop", true));
	mixin(useId("import", true));
	mixin(useId("exit", true));
	mixin(useId("floor", true));
	mixin(useId("ceil", true));
	
	top.methods[write_id] = makeWrite;
	top.methods[read_id] = makeRead;
	top.methods[obj_id] = makeObjCtr;
	top.methods[lst_id] = makeLstCtr;
	top.methods[true_id] = makeBool(true);
	top.methods[false_id] = makeBool(false);
	top.methods[while_id] = makeWhile;
	top.methods[loop_id] = makeLoop;
	top.methods[import_id] = makeImport;
	top.methods[exit_id] = makeExit;
	top.methods[floor_id] = makeFloor;
	top.methods[ceil_id] = makeCeil;
	
	mixin(useId("instantiate", true));
	S_Function instantiate(S_Function param) {
		//writeln("parameter given: ", param);
		assert(isNull(param), "instantiate takes no parameters!");
		return makeEnv(top);
	}
	top.methods[instantiate_id] = new S_CompiledFunction(&instantiate);
	
	return top;
}

//unittest {
//	string contents = import("experiment1.comet");
//	S_Expr[] testBody = parseBody(contents);
//	//writeln("Testing execution of: ", testBody);
//	S_Function loaded = new S_InterpretedFunction(makeTopEnv, testBody);
//	loaded.call(s_null_constant);
//}

S_Function execFile(in char[] fileName) {
	import std.file;
	return execString(readText(fileName));
}

S_Function execString(string source, S_Function env) {
	 S_Expr[] bodyExprs = parseBody(source);
	 assert(source.length == 0, "Syntax error; could not parse the following section of code:\n" ~ source);
	 S_Function loaded = new S_InterpretedFunction(env, bodyExprs);
	 return loaded.call(s_null_constant);
}

S_Function execString(string source) {
	return execString(source, makeTopEnv);
}
