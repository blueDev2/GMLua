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
		GMLtoGMLfunctions.print = function()
		{
			for(var i = 0; i < argument_count; ++i)
			{
				if(argument[i] == undefined)
				{
					continue;
				}
				show_debug_message(argument[i]);
			};
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
			scope.setGMLFunction(curName,GMLtoGMLfunctions[$curName],true);
		}
	
		funcNames = variable_struct_get_names(LuaToLuaFunctions);
		for(var i = 0; i < array_length(funcNames); ++i)
		{
			var curName = funcNames[i];
			scope.setGMLFunction(curName,LuaToLuaFunctions[$curName],false);		
		}
	}
}