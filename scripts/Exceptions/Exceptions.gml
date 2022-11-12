// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function ParserException(msg,line)
{
	throw("ParserException: "+ msg + " at line " + string(line));
}
 
enum ExceptionType
{
	RETURN,
	BREAK,
	UNCATCHABLE
}

function InterpreterException(msg)
{
	throw({type: ExceptionType.UNCATCHABLE,value: "RuntimeException: "+ msg});
}

function ReturnException(value)
{
	throw({type: ExceptionType.RETURN, value: value});
}

function BreakException()
{
	throw({type: ExceptionType.BREAK,value: "Break statement outside of a loop"});
}
