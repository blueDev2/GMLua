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
	JUMP,
	YIELD
}

//Return or Break exceptions should be converted to Uncatchable
//Exceptions when applicaple.

function InterpreterException(msg)
{
	throw({type: ExceptionType.UNCATCHABLE,
		originalType: ExceptionType.UNCATCHABLE,
		scopeAtThrow: global.interpreter.currentScope,
		lineNumbers:[],
		value: "RuntimeException: "+ msg});
}

function ReturnException(expression = simpleValue(undefined))
{
	var excpt = {type: ExceptionType.RETURN,
				originalType: ExceptionType.RETURN,
				scopeAtThrow: global.interpreter.currentScope,
				value: expression,
				lineNumbers:[]}
	throw(excpt);
}

function BreakException()
{
	throw({type: ExceptionType.BREAK,
		originalType: ExceptionType.BREAK,
		scopeAtThrow: global.interpreter.currentScope,
		lineNumbers:[],
		});
}

function JumpException(ASTgoto)
{
	throw({type: ExceptionType.JUMP,
		originalType: ExceptionType.JUMP,
		scopeAtThrow: global.interpreter.currentScope,
		value: ASTgoto.labelName ,
		lineNumbers:[],
		});
}

function YieldException(expRef = new Reference(simpleValue(undefined)))
{
	var resumeTrace = new Thread_Trace(Statement.RETURN,global.interpreter.currentScope)
	resumeTrace.value = new Reference(new simpleValue(undefined));
	
	var fullVal = [new Reference(new simpleValue(true))];
	if(typeof(expRef) == "array")
	{
		for(var i = 0; i < array_length(expRef);++i)
		{
			array_push(fullVal,expRef[i]);
		}
	}
	else
	{
		array_push(fullVal,expRef)
	}
	var excpt = {type: ExceptionType.YIELD,
			originalType: ExceptionType.YIELD,
			scopeAtThrow: global.interpreter.currentScope,
			value: fullVal,
			threadTraces: [resumeTrace],
			lineNumbers:[]}
	throw(excpt);
}
function HandleGMLuaExceptions(error, fullFilePath)
{
	if(!variable_struct_exists(error,"type"))
	{
		throw(error);
	}
	if(global.GMLua.logmode)
	{
		var logFolderPath = (filename_path(fullFilePath)+"InterpreterCrashLog_");
		var beforeDotStr = string_split(filename_name(fullFilePath),".")[0];
		var logFolderPath = logFolderPath + beforeDotStr + ".txt";
		var f = file_text_open_write(logFolderPath);
		file_text_write_string(f,string(error.scopeAtThrow));
		file_text_close(f);
	}
	var lineNumber = string(error.lineNumbers);
	var thrownString = "";

	switch(error.originalType)
	{
		case ExceptionType.RETURN:
			thrownString = "Return statement at lines "+lineNumber +
			" is not in a function body."
		break;
		case ExceptionType.BREAK:
			thrownString = "Break statement at lines "+lineNumber +
			" is not in a loop body."
		break;
		case ExceptionType.UNCATCHABLE:
			thrownString = error.value + "\nThis is at lines "+lineNumber +".";
		break;
		case ExceptionType.JUMP:
			thrownString = "Goto " + error.labelName + " at lines " +lineNumber+
			" has no visable labels"; 
		break;
	}
	if(!is_undefined(fullFilePath))
	{
		thrownString += "\nThis exception is from the source code at " +fullFilePath;
	}
	throw(thrownString)
}
