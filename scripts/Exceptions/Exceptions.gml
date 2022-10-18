// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function ParserException(msg,line)
{
	throw("ParserException: "+ msg + " at line " + string(line));
}
 
function ReturnException(value)
{
	throw(
		{type: "return", value: value}
		);
}

function BreakException()
{
	throw(
		{type: "break"}
	);
}