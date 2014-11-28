module comet.fn;

import comet.id;
import comet.primitive;

import std.conv;
import std.string : format;

import std.stdio;

class S_Expr {
	abstract S_Function interpret(S_Function env);
}

class S_Constant_Expr : S_Expr {
	S_Function val;
	
	this(S_Function val) {
		this.val = val;
	}
	
	override S_Function interpret(S_Function env) {
		return val;
	}
	
	override string toString() {
		return to!string(val);
	}
}

class S_Call_Expr : S_Expr {
	S_Expr receiver;
	S_Expr param;
	
	this(S_Expr receiver, S_Expr param) {
		this.receiver = receiver;
		this.param = param;
	}
	
	override S_Function interpret(S_Function env) {
		return receiver.interpret(env).call(param.interpret(env));
	}
	
	override string toString() {
		return "(%s %s)".format(receiver, param);
	}
}

class S_Env_Expr : S_Expr {
	override S_Function interpret(S_Function env) {
		return env;
	}
	
	override string toString() {
		return "@";
	}
}

class S_Function {
	abstract S_Function call(S_Function param);
	
	override string toString() {
		mixin(useId("to_str"));
		return extract!string(call(to_str_fn).call(s_null_constant));
	}
}

class S_InterpretedFunction : S_Function {
	S_Function env;
	S_Expr[] code;
	
	S_Function paramNameIdFn;
	
	this(S_Function env, S_Expr[] code) {
		this.env = env;
		this.code = code;
	}
	
	override S_Function call(S_Function param) {
		//writeln("Calling interpreted function!");
		//static S_Function instantiateId; //= S_Id.fn("instantiate");
		//static S_Function defId; //= S_Id.fn("def");
		
		mixin(useId("instantiate"));
		mixin(useId("def_shadow"));
		
		S_Function this_env = env.call(instantiate_fn).call(s_null_constant);
		
		//if (paramNameIdFn !is null) this_env.call(defId).call(paramNameIdFn).call(param);
		if (paramNameIdFn !is null) this_env.call(def_shadow_fn).call(paramNameIdFn).call(param);
		
		// call side-effect expressions
		if (!code.length) return null;
		foreach (i; 0 .. code.length - 1) {
			code[i].interpret(this_env);
		}
		// call final return expression
		return code[code.length - 1].interpret(this_env);
		
		//return s_null_constant;
		//assert(0);
	}
}

class S_CompiledFunction : S_Function {
	S_Function delegate(S_Function) dg;
	
	this(S_Function delegate(S_Function) dg) {
		this.dg = dg;
	}
	
	override S_Function call(S_Function param) {
		return dg(param);
	}
}

class S_DataFunction : S_Function {
	override S_Function call(S_Function param) {
		throw new Exception("Data functions are completely opaque; they may not be invoked");
	}
}

S_Function curryHelper(uint count, S_Function delegate(S_Function[]) dg) {
	return partialHelper([], count, dg);
}

S_Function partialHelper(S_Function[] already, uint remainingCount, S_Function delegate(S_Function[]) dg) {
	assert(remainingCount != 0, "partial application glitch cbdhjsalbchdsalbchdljabc");
	if (remainingCount == 1) {
		S_Function finalResult(S_Function lastArg) {
			return dg(already ~ [lastArg]);
		}
		return new S_CompiledFunction(&finalResult);
	}
	else {
		S_Function result(S_Function incrementalArg) {
			//writeln("remaining count ", remainingCount);
			return partialHelper(already ~ [incrementalArg], remainingCount - 1, dg);
		}
		return new S_CompiledFunction(&result);
	}
}
