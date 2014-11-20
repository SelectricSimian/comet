module comet.parse;

import comet.fn;
import comet.primitive;
import comet.id;

import std.conv;

import std.stdio;

private T[] consume(T)(ref T[] lst, size_t count) {
	auto result = lst[0..count];
	lst = lst[count .. $];
	return result;
}

string consumeWhile(ref string str, bool function(char) predicate) {
	size_t i = 0;
	while (i < str.length && predicate(str[i])) i++;
	return consume(str, i);
}

bool isNumeric(char c) {
	return c >= '0' && c <= '9';
}

S_Expr parseNumber(ref string str) {
	num_type sign = 1;
	if (str.length >= 2 && str[0] == '-' && isNumeric(str[1])) {
		consume(str, 1);
		sign = -1;
	}
	string integerPart = consumeWhile(str, &isNumeric);
	if (!integerPart.length) return null;
	if (str.length > 0 && str[0] == '.') {
		consume(str, 1);
		string fractionalPart = consumeWhile(str, &isNumeric);
		//if (!(integerPart.length || fractionalPart.length)) return null;
		//writeln("Converting ", integerPart, ".", fractionalPart);
		return new S_Constant_Expr(makeNum(sign * to!num_type(integerPart ~ "." ~ fractionalPart)));
	}
	if (!integerPart.length) return null;
	//writeln("Converting ", integerPart);
	return new S_Constant_Expr(makeNum(sign * to!num_type(integerPart)));
}

bool isAlphabetic(char c) {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c == '_') || (c == '?');
}

bool isIdentifierBodyChar(char c) {
	return isAlphabetic(c) || isNumeric(c);
}

string consumeIdentifier(ref string str) {
	string result = "";
	if (str.length > 0 && isAlphabetic(str[0])) {
		result ~= consume(str, 1);
		result ~= consumeWhile(str, &isIdentifierBodyChar);
	}
	return result;
}

S_Expr parseIdentifier(ref string str) {
	string identifierStr = consumeIdentifier(str);
	if (!identifierStr.length) return null;
	return new S_Call_Expr(new S_Env_Expr, new S_Constant_Expr(makeId(S_Id(identifierStr))));
}

S_Expr parseSymbol(ref string str) {
	if (str.length > 0 && str[0] == ':') {
		consume(str, 1);
		string identifierStr = consumeIdentifier(str);
		if (!identifierStr.length) return null;
		return new S_Constant_Expr(makeId(S_Id(identifierStr)));
	}
	return null;
}

bool isOperatorChar(char c) {
	return
		c == '.' ||
		c == '+' ||
		c == '-' ||
		c == '*' ||
		c == '/' ||
		c == '=' ||
		c == '>' ||
		c == '<' ||
		c == '&' ||
		c == '|' ||
		c == '#' ||
		c == '%' ||
		c == '^';
}

S_Expr parseOperator(ref string str) {
	string operatorStr = consumeWhile(str, &isOperatorChar);
	//writeln("operator '", operatorStr, "'");
	if (!operatorStr.length) return null;
	//writeln("length: ", operatorStr.length);
	//writeln(cast(ubyte[])operatorStr);
	return new S_Constant_Expr(makeId(S_Id(operatorStr)));
}

char escape(char c) {
	switch (c) {
		case '"': return '"';
		case '\\': return '\\';
		case 'n': return '\n';
		case 't': return '\t';
		case 'r': return '\r';
		default: throw new Exception("Unexpected escape sequence \\" ~ [c] ~ " in string!");
	}
}

bool isNotSpecialStringChar(char c) {
	return (c != '"') && (c != '\\');
}

S_Expr parseString(ref string str) {
	if (str.length > 0 && str[0] == '"') {
		consume(str, 1);
		string result = "";
		for (;;) {
			string matched = consumeWhile(str, &isNotSpecialStringChar);
			result ~= matched;
			if (str.length) {
				char unmatched = consume(str, 1)[0];
				if (unmatched == '"') {
					return new S_Constant_Expr(makeStr(result));
				} else if (unmatched == '\\') {
					char escapedChar = consume(str, 1)[0];
					result ~= [escape(escapedChar)];
				} else {
					assert(0); // can't be reached unless isNotSpecialStringChar is modified to have incorrect behavior
				}
			} else {
				throw new Exception("Unterminated string!");				
			}
		}
	}
	return null;
}

S_Expr parseParenthesized(ref string str) {
	if (str.length > 0 && str[0] == '(') {
		consume(str, 1);
		S_Expr result = parseExpr(str);
		assert(consume(str, 1)[0] == ')', "Unmatched left parenthesis!");
		return result;
	}
	return null;
}

S_Expr parseGroupingArrow(ref string str) {
	if (str.length >= 2 && str[0..2] == "<-") {
		consume(str, 2);
		S_Expr result = parseExpr(str);
		return result;
	}
	return null;
}

S_Expr parseNullSymbol(ref string str) {
	if (str.length > 0 && str[0] == '!') {
		consume(str, 1);
		return new S_Constant_Expr(s_null_constant);
	}
	return null;
}

S_Expr parseEnvSymbol(ref string str) {
	if (str.length > 0 && str[0] == '@') {
		consume(str, 1);
		return new S_Env_Expr;
	}
	return null;
}

S_Id[] parseParamList(ref string str) {
	S_Id[] results = [];
	for (;;) {
		consumeWhitespace(str);
		if (str.length > 0 && str[0] == '\\') {
			consume(str, 1);
			string idStr = consumeIdentifier(str);
			if (!idStr.length) throw new Exception("Expected identifier after \\"); //return null;
			results.length++;
			results[results.length - 1] = S_Id(idStr);
		} else {
			return results;
		}
	}
}

S_Expr parseFnLiteral(ref string str) {
	mixin(useId("this"));
	
	S_Id[] paramList = parseParamList(str);
	//writeln(paramList);
	//if (paramList is null) assert(0); //return null;
	//if (!paramList.length) writeln("empty param list");
	S_Expr defaultReceiver = null;
	char closeChar = '}';
	if (!(str.length > 0 && str[0] == '{'))
	{
		if (str.length > 0 && str[0] == '[') {
			defaultReceiver = new S_Call_Expr(new S_Env_Expr, new S_Constant_Expr(this_fn));
			paramList = [this_id] ~ paramList;
			closeChar = ']';
		}
		else
		if (paramList.length) {
			throw new Exception("Curly or square block expected after parameter list!");
		}
		else {
			return null;
		}
	}
	consume(str, 1);
	
	S_Expr[] bodyExprs = parseBody(str, defaultReceiver);
	if(!(str.length > 0 && str[0] == closeChar)) {
		throw new Exception("Expected '%c' to close block".format(closeChar));
	}
	consume(str, 1);
	
	mixin(useId("bind_nullary"));
	if (paramList.length > 0) {
		return curryExpr(paramList, bodyExprs);
	} else {
		S_Function nullaryBinder = makeSyntax(bodyExprs).call(bind_nullary_fn);
		return new S_Call_Expr(new S_Constant_Expr(nullaryBinder), new S_Env_Expr);
	}
}

S_Expr curryExpr(S_Id[] paramIds, S_Expr[] bodyExprs) {
	mixin(useId("bind"));
	if (paramIds.length == 1) {
		S_Function binder = makeSyntax(bodyExprs).call(bind_fn).call(makeId(paramIds[0]));
		return new S_Call_Expr(new S_Constant_Expr(binder), new S_Env_Expr);
	}
	else {
		S_Id outermost = paramIds[0];
		S_Function binder = makeSyntax([curryExpr(paramIds[1..$], bodyExprs)]).call(bind_fn).call(makeId(outermost));
		return new S_Call_Expr(new S_Constant_Expr(binder), new S_Env_Expr);
	}
}

//auto firstNonNull(T...)(lazy T vals) {
//	foreach (i; 0 .. vals.length) {
//		T val = vals[i];
//		if (val !is null) return val;
//	}
//	return null;
//}
//unittest {
//	assert(firstNonNull(null, null, "hello", null, "world") == "hello");
//	assert(firstNonNull("test", null) == "test");
//	assert(firstNonNull(null, null) is null);
	
//	string thisShouldRun() {
//		return "a";
//	}
	
//	string thisShouldNeverRun() {
//		assert(0);
//	}
	
//	assert(firstNonNull(null, thisShouldRun, null, thisShouldNeverRun) == "a");
//}

S_Expr parseAtom(ref string str) {
	//return firstNonNull(
	//	parseNumber(str),
	//	parseIdentifier(str),
	//	parseSymbol(str),
	//	parseGroupingArrow(str),
	//	parseParenthesized(str),
	//	parseOperator(str),
	//	parseString(str),
	//);

	S_Expr result;
	result = parseNumber(str);
	if (result !is null) return result;
	
	result = parseIdentifier(str);
	if (result !is null) return result;
	
	result = parseSymbol(str);
	if (result !is null) return result;
	
	result = parseGroupingArrow(str);
	if (result !is null) return result;
	
	result = parseParenthesized(str);
	if (result !is null) return result;
	
	result = parseOperator(str);
	if (result !is null) return result;
	
	result = parseString(str);
	if (result !is null) return result;
	
	result = parseNullSymbol(str);
	if (result !is null) return result;
	
	result = parseEnvSymbol(str);
	if (result !is null) return result;
	
	result = parseFnLiteral(str);
	if (result !is null) return result;
	
	return null;
}

bool isNonTerminatingWhitespace(char c) {
	return c == ' ' || c == '\t' || c == '\r';
}

void consumeWhitespace(ref string str) {
	consumeWhile(str, &isNonTerminatingWhitespace);
}

bool isTerminating(char c) {
	return c == '\n' || c == ',';
}

bool isTerminatorOrWhitespace(char c) {
	return isTerminating(c) || isNonTerminatingWhitespace(c);
}

bool isNotNewline(char c) {
	return c != '\n';
}

void consumeTerminatorsAndWhitespace(ref string str) {
	for (;;) {
		consumeWhile(str, &isTerminatorOrWhitespace);
		if (str.length > 0 && str[0] == '~') 
			consumeWhile(str, &isNotNewline);
		else
			return;
	}
}

S_Expr parseExpr(ref string str, S_Expr receiver = null) {
	bool foundOne = false;
	for (;;) {
		consumeWhitespace(str);
		S_Expr atom = parseAtom(str);
		if (atom !is null) {
			foundOne = true;
			if (receiver !is null)
				receiver = new S_Call_Expr(receiver, atom);
			else
				receiver = atom;
		} else if (foundOne) {
			return receiver;
		} else {
			return null;
		}
	}
}

S_Expr[] parseBody(ref string str, S_Expr implicitReceiver = null) {
	S_Expr[] result = [];
	for (;;) {
		consumeTerminatorsAndWhitespace(str);
		//consumeWhitespace(str);
		S_Expr expr = parseExpr(str, implicitReceiver);
		if (expr !is null) {
			result.length++;
			result[result.length - 1] = expr;
		} else {
			return result;
		}
	}
}

//unittest {
//	import std.stdio;
//	string myStr = import("test1.comet");
//	writeln(parseBody(myStr));
//	writeln(myStr);
//}
