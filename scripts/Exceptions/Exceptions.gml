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

//Return or Break exceptions should be converted to Uncatchable
//Exceptions when applicaple.
function InterpreterException(msg)
{
	throw({type: ExceptionType.UNCATCHABLE,value: "RuntimeException: "+ msg});
}

function ReturnException(expression)
{
	var excpt = {type: ExceptionType.RETURN, value: expression}
	throw(excpt);
}

function BreakException()
{
	throw({type: ExceptionType.BREAK,value: "Break statement outside of a loop"});
}
