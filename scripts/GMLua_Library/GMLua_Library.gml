// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
global.LuaLibrary = {}
with(global.LuaLibrary)
{
	basicFunctionLibrary = {};
	with(basicFunctionLibrary)
	{
		GMLtoGMLfunctions = {};
		LuaToLuaFunctions = {};
		//add built-in functions as needed in builtInFuncs
		GMLtoGMLfunctions.getgmlfunction = function(functionName)
		{
			static findBuiltInFuncs = function()
			{
				var res = {};
				var i = 0;

				//By guessing and checking every index from 0 to 10000
				//(Probably) all Built-In functions are provided for use.
				for(; i < 10000; ++i)
				{
					var funcName = script_get_name(i);
					//Strings that start with "@@" are internal to GML	
					//and cannot be used
					if(string_char_at(funcName,1) == "@" && 
					string_char_at(funcName,2) == "@")
					{
						continue;
					}
					if(!is_undefined(funcName))	
					{
						res[$funcName] = i;
					}
				}


				return res;
			}
			static builtInFuncs = findBuiltInFuncs()
			var curFuncIndex = builtInFuncs[$functionName];
			if(is_undefined(curFuncIndex))
			{
				return undefined;
			}
			return method(undefined,curFuncIndex)
		}
		
		GMLtoGMLfunctions.print = function()
		{
			var printStr = "";
			var args = argument[15];
			for(var i = 0; i < array_length(args); ++i)
			{
				if(args[i] == undefined)
				{
					continue;
				}
				printStr += (string(args[i]) + "    ")
			};
			show_debug_message(printStr)
		}
		GMLtoGMLfunctions.select = function()
		{
			var args = argument[15];
			var index = args[0];
			if(index == "#")
			{
				return (array_length(args)-1)
			}
			if(index == 0)
			{
				InterpreterException("Bad first argument in the function \"select\"");
			}
			if(index < 0)
			{
				index += array_length(args);
				if(index <= 0)
				{
					InterpreterException("Bad first argument in the function \"select\"");
				}
			}
			var retList = [];
			for(var i = index; i < array_length(args); ++i)
			{
				array_push(retList,args[i]);
			}
			return retList;
		}
		
		LuaToLuaFunctions.setmetatable = function(table,metatable)
		{
			table.metatable = metatable;
			return table;
		}
	}
	function addBasicLibraryFunctions(scope)
	{
		var GMLtoGMLfunctions = basicFunctionLibrary.GMLtoGMLfunctions;
		var LuaToLuaFunctions = basicFunctionLibrary.LuaToLuaFunctions;
	
	
		var funcNames = variable_struct_get_names(GMLtoGMLfunctions)
		for(var i = 0; i < array_length(funcNames); ++i)
		{
			var curName = funcNames[i];
			setGMLFunction(scope,curName,GMLtoGMLfunctions[$curName],true);
		}
	
		funcNames = variable_struct_get_names(LuaToLuaFunctions);
		for(var i = 0; i < array_length(funcNames); ++i)
		{
			var curName = funcNames[i];
			setGMLFunction(scope,curName,LuaToLuaFunctions[$curName],false);		
		}
	}
}