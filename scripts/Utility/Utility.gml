// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

//I cannot find a way to call a function with an unknown number of 
//parameters.
function callFunction(functionRef, arguments)
{
	switch(array_length(arguments))
	{
		case 0:
		return functionRef();
		break;
		case 1:
		return functionRef(arguments[0]);
		break;
		case 2:
		return functionRef(arguments[0],arguments[1]);
		break;
		case 3:
		return functionRef(arguments[0],arguments[1],arguments[2]);
		break;
		case 4:
		return functionRef(arguments[0],arguments[1],arguments[2],arguments[3]);
		break;
		case 5:
		return functionRef(arguments[0],arguments[1],arguments[2],arguments[3],arguments[4]);
		break;
		case 6:
		return functionRef(arguments[0],arguments[1],arguments[2],arguments[3],arguments[4]
		,arguments[5]);
		break;
		case 7:
		return functionRef(arguments[0],arguments[1],arguments[2],arguments[3],arguments[4]
		,arguments[5],arguments[6]);
		break;
		case 8:
		return functionRef(arguments[0],arguments[1],arguments[2],arguments[3],arguments[4]
		,arguments[5],arguments[6],arguments[7]);
		break;
		case 9:
		return functionRef(arguments[0],arguments[1],arguments[2],arguments[3],arguments[4]
		,arguments[5],arguments[6],arguments[7],arguments[8]);
		break;
		case 10:
		return functionRef(arguments[0],arguments[1],arguments[2],arguments[3],arguments[4]
		,arguments[5],arguments[6],arguments[7],arguments[8],arguments[9]);
		break;
		case 11:
		return functionRef(arguments[0],arguments[1],arguments[2],arguments[3],arguments[4]
		,arguments[5],arguments[6],arguments[7],arguments[8],arguments[9],arguments[10]);
		break;
		case 12:
		return functionRef(arguments[0],arguments[1],arguments[2],arguments[3],arguments[4]
		,arguments[5],arguments[6],arguments[7],arguments[8],arguments[9],arguments[10],
		arguments[11]);
		break;
		case 13:
		return functionRef(arguments[0],arguments[1],arguments[2],arguments[3],arguments[4]
		,arguments[5],arguments[6],arguments[7],arguments[8],arguments[9],arguments[10],
		arguments[11],arguments[12]);
		break;
		case 14:
		return functionRef(arguments[0],arguments[1],arguments[2],arguments[3],arguments[4]
		,arguments[5],arguments[6],arguments[7],arguments[8],arguments[9],arguments[10],
		arguments[11],arguments[12],arguments[13]);
		break;
		case 15:
		return functionRef(arguments[0],arguments[1],arguments[2],arguments[3],arguments[4]
		,arguments[5],arguments[6],arguments[7],arguments[8],arguments[9],arguments[10],
		arguments[11],arguments[12],arguments[13],arguments[14]);
		break;
		default:
		InterpreterException("function call has too many arguments (This interpreter accepts 15)")
	}
}

function Pointer() constructor
{
	
}

