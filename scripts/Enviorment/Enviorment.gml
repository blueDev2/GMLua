// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
enum LuaTypes
{
	/*
	NIL = undefined,
	BOOLEAN = boolean,		
	INTEGER = int64,
	FLOAT = real,
	STRING = string,*/
	FUNCTION,
	THREAD,
	TABLE
}


function Function(block) constructor
{
	pointerCount = 1;
	
}

function Thread(func) constructor
{
	pointerCount = 1;
	
}

function Table() constructor
{
	pointerCount = 1;
	vars = ds_map_create();
	type = LuaTypes.TABLE
}