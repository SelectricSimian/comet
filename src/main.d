module main;

import std.stdio;
import spring.exec;
import spring.primitive;
import spring.fn;
import spring.id;

// this creates an environment whose "instantiate" always returns the same result, so that variables can be used across commands in the interactive interpreter
S_Function makeInteractiveEnv() {
	S_DirectDefObj result = makeObj();
	S_Function topEnv = makeTopEnv();
	
	mixin(useId("instantiate", true));
	S_Function instantiate(S_Function param) {
		assert(isNull(param), "Instantiate takes no parameters!");
		return topEnv;
	}
	result.methods[instantiate_id] = new S_CompiledFunction(&instantiate);
	
	return result;
}

void main(string[] args) {
	if (args.length == 1) {
		S_Function env = makeInteractiveEnv;
		writeln("Comet version √-1");
		writeln("By William Brandon");
		writeln("enter a blank line to begin a multi-line command (terminated with [esc])\n");
		for (;;) {
			write(">>> ");
			//string cmnd = readln(27)[0..$-1];
			string singleLineCommand = readln('\n');
			string cmnd;
			if (singleLineCommand.length == 1) {
				cmnd = readln(27)[0..$-1];
			} else {
				cmnd = singleLineCommand;
			}
			//write(cast(string)[27, '[', '7', 'm']);
			S_Function result = execString(cmnd, env);
			if (!isNull(result)) {
				writeln("==> ", result);
			}
			//write(cast(string)[27, '[', '0', 'm']);
		}
	}
	else
	if (args.length == 2) {
		execFile(args[1]);
	}
	else {
		writeln("Usage: comet [filename]\nCall with no arguments for an interactive-interpreter");
	}
}
