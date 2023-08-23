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
			if(functionName == "ds_map_create")
			{
				show_debug_message("sad")
			}
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
				var str = noone;
				if(typeof(args[i]) == "bool")
				{
					if(args[i])
					{
						str = "true"
					}
					else
					{
						str = "false";
					}
				}
				else
				{
					str = string(args[i])
				}
				printStr += (str + "    ")
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
		GMLtoGMLfunctions.callwithcontext = function(context,func)
		{
			var args = array_create(15,undefined)
			for(var i = 2; i < array_length(argument[15]); ++i)
			{
				args[i-2] = argument[15][i]
			}


			with(context)
			{
				var retVal = func(args[0],args[1],args[2],args[3],args[4],
	args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13],
	args[14],args)
				//show_debug_message(typeof(retVal))
				return retVal;
			}
		}
		
		LuaToLuaFunctions.setmetatable = function(table,metatable)
		{
			table.metatable = metatable;
			return table;
		}
		LuaToLuaFunctions.type = function(luaItem)
		{
			var typeName = "";
			switch(luaItem.type)
			{
				case LuaTypes.NIL: 
					typeName = "Nil"
				break
				case LuaTypes.BOOLEAN:	
					typeName = "Boolean"
				break
				case LuaTypes.INTEGER:
					typeName = "Integer"
				break;	
				case LuaTypes.FLOAT:
					typeName = "Float"
				break;
				case LuaTypes.STRING:
					typeName = "String"
				break
				case LuaTypes.FUNCTION:
					typeName = "Function"
				break
				case LuaTypes.THREAD:
					typeName = "Thread"
				break
				case LuaTypes.TABLE:
					typeName = "Table"
				break
				case LuaTypes.GMFUNCTION:
					typeName = "GMFunction"
				break
			}
			return new Reference(new simpleValue(typeName));
		}
	}
	coroutineLibrary ={}
	with(coroutineLibrary)
	{
		GMLtoGMLfunctions = {};
		LuaToLuaFunctions = {};
		
		LuaToLuaFunctions.yield = function()
		{
			var expressions = argument[15]
			var retExps = [];
			for(var i = 0; i < array_length(expressions); ++i)
			{
				array_push(retExps,new Reference(expressions[i]));
			}
			retExps = helpPruneExpList(retExps,-1);
			YieldException(retExps)
		}
		
		LuaToLuaFunctions.create = function(luaFunc)
		{
			if(luaFunc.type != LuaTypes.FUNCTION)
			{
				InterpreterException("Attempted to use a non-function when creating a thread")
			}
			return new Reference(new Thread(luaFunc));
		}
		LuaToLuaFunctions.resume = function(thread)
		{
			//thread.val.threadTrace = thread.threadTrace;
			/*var GMLArgs = [];
			for(var i = 0; i < array_length(argument[15]); ++i)
			{
				array_push(GMLArgs,LuaToGML(argument[15][i]))
			}*/
			var args = argument[15];
			array_shift(args);
			
			for(var i = 0; i < array_length(args);++i)
			{
				args[i] = new Reference(args[i])
			}
			
			var retVal =  callFunction(thread.luaInternalItem,args)
			return retVal;
		}
	}
	
	libraries = {};
	libraries[$"basic"] = basicFunctionLibrary
	libraries[$"coroutine"] = coroutineLibrary
	function addLibraryFunctions(scope,libraryName = "basic")
	{
		var GMLtoGMLfunctions = libraries[$libraryName].GMLtoGMLfunctions;
		var LuaToLuaFunctions = libraries[$libraryName].LuaToLuaFunctions;
		var libraryTable = new Table();
		var isBasic = (libraryName == "basic");
	
		var funcNames = variable_struct_get_names(GMLtoGMLfunctions)
		for(var i = 0; i < array_length(funcNames); ++i)
		{
			var curName = funcNames[i];
			if(isBasic)
			{
				setGMLFunction(scope,curName,GMLtoGMLfunctions[$curName],true);
			}
			else
			{
				setGMLFunctionTableValue(libraryTable,curName,GMLtoGMLfunctions[$curName],true)
			}
		}
	
		funcNames = variable_struct_get_names(LuaToLuaFunctions);
		for(var i = 0; i < array_length(funcNames); ++i)
		{
			var curName = funcNames[i];
			if(isBasic)
			{
				setGMLFunction(scope,curName,LuaToLuaFunctions[$curName],false);
			}
			else
			{
				setGMLFunctionTableValue(libraryTable,curName,LuaToLuaFunctions[$curName],false)
			}
		}
		
		if(!isBasic)
		{
			scope.setLocalVariable(libraryName,libraryTable);
		}
	}
}