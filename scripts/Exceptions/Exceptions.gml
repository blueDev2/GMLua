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
	UNCATCHABLE,
	JUMP
}

//Return or Break exceptions should be converted to Uncatchable
//Exceptions when applicaple.

function InterpreterException(msg)
{
	throw({type: ExceptionType.UNCATCHABLE,
		originalType: ExceptionType.UNCATCHABLE,
		lineNumber: -1,
		value: "RuntimeException: "+ msg});
}

function ReturnException(expression)
{
	var excpt = {type: ExceptionType.RETURN,
				originalType: ExceptionType.RETURN,
				value: expression,
				lineNumber: -1}
	throw(excpt);
}

function BreakException()
{
	throw({type: ExceptionType.BREAK,
		originalType: ExceptionType.BREAK,
		lineNumber: -1,
		});
}

function JumpException(ASTgoto)
{
	throw({type: ExceptionType.JUMP,
		originalType: ExceptionType.JUMP,
		value: ASTgoto.labelName ,
		lineNumber: -1,
		});
}

function HandleGMLuaExceptions(error, fullFilePath)
{
	if(!variable_struct_exists(error,"type"))
	{
		throw(error);
	}
	var lineNumber = string(error.lineNumber);
	var thrownString = "";

	switch(error.originalType)
	{
		case ExceptionType.RETURN:
			thrownString = "Return statement at line "+lineNumber +
			" is not in a function body."
		break;
		case ExceptionType.BREAK:
			thrownString = "Break statement at line "+lineNumber +
			" is not in a loop body."
		break;
		case ExceptionType.UNCATCHABLE:
			thrownString = error.value + "\nThis is at line "+lineNumber +".";
		break;
		case ExceptionType.JUMP:
			thrownString = "Goto " + error.labelName + " at line " +lineNumber+
			" has no visable labels"; 
		break;
	}
	if(!is_undefined(fullFilePath))
	{
		thrownString += "\nThis exception is from the source code at " +fullFilePath;
	}
	throw(thrownString)
}
