// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
global.LuaLibrary = {}
with(global.LuaLibrary)
{
	gmlFunctionNameList = [];
	nameListIsWhitelist = true;
	libraries = {};
	
	basicFunctionLibrary = new Library("basic");
	with(basicFunctionLibrary)
	{
		with(globalVals)
		{
			with(GMLToGMLFunctions)
			{
				getgmlfunction = function(functionName)
				{
					var inNameList = false;
					if(array_get_index(global.LuaLibrary.gmlFunctionNameList,functionName) != -1)
					{
						inNameList = true;
					}
					if(inNameList && !global.LuaLibrary.nameListIsWhitelist)
					{
						InterpreterException("Attempted to use a gml built-in function that is on the blacklist")
					}
					if(!inNameList && global.LuaLibrary.nameListIsWhitelist)
					{
						InterpreterException("Attempted to use a gml built-in function that is not on the whitelist")
					}
				
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
				ExplistToTable = function()
				{
					var arr = argument[15];
			
					var retStruct = {}
					for(var i = 0; i < array_length(arr); ++i)
					{
						retStruct[$string(i+1)] = arr[i];
					}
					return retStruct;
				}
				print = function()
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
				select = function()
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
				callwithcontext = function(context,func)
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
			}
			with(LuaToLuaFunctions)
			{
				setmetatable = function(table,metatable)
				{
					table.metatable = metatable;
					return table;
				}
				type = function(luaItem)
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
			with(nonFunctions)
			{
				
			}
		}
		onLoad = function(scope)
		{
			var globalTable = new Table()
			var globalMetatable = new Table(,
			{
				__index : function(t,k)
				{
					return getLuaVariable(global.interpreter.globalScope,k)
				},
			
				__newindex : function(t,k,v)
				{
					setGMLVariable(global.interpreter.globalScope,k,v)
				}
			})
			globalTable.metatable = globalMetatable
			scope.setLocalVariable("_G",globalTable)
		}
	}
	
	coroutineLibrary = new Library("coroutine");
	with(coroutineLibrary)
	{
		with(tableVals)
		{
			with(LuaToLuaFunctions)
			{
				yield = function()
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
				create = function(luaFunc)
				{
					if(luaFunc.type != LuaTypes.FUNCTION)
					{
						InterpreterException("Attempted to use a non-function when creating a thread")
					}
					return (new Thread(luaFunc));
				}
				resume = function(thread)
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
					if(typeof(retVal) = "array")
					{
						for(var i = 0; i < array_length(retVal); ++i)
						{
								retVal[i] = retVal[i].getValue()
						}
					}
					else
					{
						retVal = retVal.getValue()
					}
					return retVal;
				}
			}
		}
	}
	
	packageLibrary = new Library("package");
	with(packageLibrary)
	{
		with(globalVals)
		{
			with(LuaToLuaFunctions)
			{
				// Will always return 2 values 
				require = function(moduleName)
				{
					moduleName = LuaToGML(moduleName)
					var currentGlobalScope = global.interpreter.globalScope
					// First check if the a GMLua_Library with [moduleName] exists
					if(struct_exists(global.LuaLibrary.libraries,moduleName))
					{
						return global.LuaLibrary.addLibraryFunctions(currentGlobalScope,moduleName)
					}
					
					// If no GMLua_Library exist, then check if a lua library exists using pattern matching
					var currentPackageLibrary =  getLuaVariable(currentGlobalScope,"package")
					var searchpath = currentPackageLibrary.searchpath
					var filePath = searchpath(moduleName,currentPackageLibrary.path)
					
					var chunk =  createLuaFromFile(filePath)
					with(global.interpreter)
					{
						try
						{
							helpVisitBlock(chunk.block)
						}
						catch(e)
						{
							if(e.type == ExceptionType.RETURN)
							{
								var expVals = [];
								for(var i = 0; i < array_length(e.value); ++i)
								{
									array_push(expVals,e.value[i].getValue())
								}
								return expVals
							}
							else
							{
								e.type = ExceptionType.UNCATCHABLE
								throw(e)
							}
						}
						
					}
				}
			}
		}
		with(tableVals)
		{
			with(GMLToGMLFunctions)
			{
				searchpath = function(name,path,sep = ".",rep = "/")
				{
					name = string_replace_all(name,sep,rep)
					path = string_replace_all(path,"?",name)
					var curPath = ""
					for(var i = 1; i < string_length(path); ++i)
					{
						var curChar = string_char_at(path,i)
						if(curChar == ";")
						{
							var file = file_text_open_read(curPath)
							if(file != -1)
							{
								file_text_close(file)
								return curPath
							}
							else
							{
								curPath = ""
							}
						}
						else
						{
							curPath += curChar;
						}
					}
					if(string_length(curPath) > 0)
					{
						var file = file_text_open_read(curPath)
						if(file != -1)
						{
							file_text_close(file)
							return curPath
						}
						else
						{
							curPath = ""
						}
					}
				}
			}
			with(nonFunctions)
			{
				path = ""
			}
		}	

	}
	
	stringLibrary = new Library("string")
	with(stringLibrary)
	{
		with(tableVals)
		{
			with(GMLToGMLFunctions)
			{
				byte = function(s,i = 1,j = i)
				{
					var bytes = [];
					for(;i<=j;++i)
					{
						array_push(bytes,string_byte_at(s,i))
					}
					return bytes
				}
				char = function()
				{
					var str = ""
					var args = argument[15];
					for(var i = 0; i < array_length(args); ++i)
					{
						str += chr(args[i])
					}
					return str;
				}
				len = function(s)
				{
					return string_length(s)
				}
				lower = function(s)
				{
					return string_lower(s)	
				}
				rep = function(s,n,sep ="")
				{
					var res = ""
					for(var i = 0; i < n; ++i)
					{
						res += n
						if(i == n-1)
						{
							res += sep	
						}
					}
				}
				reverse = function(s)
				{
					var res = ""
					for(var i = string_length(s); i <= 1; --i)
					{
						res += string_char_at(s,i)	
					}
					return rs
				}
				upper = function(s)
				{
					return string_upper(s)	
				}
			}
			
		}
	}
	
	function addLibraryFunctions(scope,libraryName = "basic")
	{
		var library = libraries[$libraryName]
		library.addLibraryToScope(scope,libraryName)
	}
	
}
	
function addBasicLibraries(scope)
{
	global.LuaLibrary.addLibraryFunctions(globalScope, "basic")
	global.LuaLibrary.addLibraryFunctions(globalScope,"coroutine");
	global.LuaLibrary.addLibraryFunctions(globalScope,"package");
	global.LuaLibrary.addLibraryFunctions(globalScope,"string");
}
	
function Library(name) constructor
{
	globalVals = {};
	tableVals = {};
	
	globalVals.nonFunctions = {};
	globalVals.LuaToLuaFunctions = {};
	globalVals.GMLToGMLFunctions = {};
	
	tableVals.nonFunctions = {};
	tableVals.LuaToLuaFunctions = {};
	tableVals.GMLToGMLFunctions = {};
	
	onLoad = noone
	
	global.LuaLibrary.libraries[$name] = self
	
	function addLibraryToScope(scope,libraryName)
	{
		var libraryTable = new Table()
		

		
		var curStruct = globalVals.nonFunctions
		var curNames = struct_get_names(curStruct)
		
		for(var i = 0; i < array_length(curNames); ++i)
		{
			var curName = curNames[i]
			setGMLVariable(scope,curName,curStruct[$curName])
		}
		
		curStruct = globalVals.GMLToGMLFunctions
		curNames = struct_get_names(curStruct)
		for(var i = 0; i < array_length(curNames); ++i)
		{
			var curName = curNames[i]
			setGMLFunction(scope,curName,curStruct[$curName],true)
		}
		
		curStruct = globalVals.LuaToLuaFunctions
		curNames = struct_get_names(curStruct)
		for(var i = 0; i < array_length(curNames); ++i)
		{
			var curName = curNames[i]
			setGMLFunction(scope,curName,curStruct[$curName],false)
		}
		
		
		curStruct = tableVals.nonFunctions
		curNames = struct_get_names(curStruct)
		
		for(var i = 0; i < array_length(curNames); ++i)
		{
			var curName = curNames[i]
			setGMLValueTableValue(libraryTable,curName,curStruct[$curName])
		}
		
		curStruct = tableVals.GMLToGMLFunctions
		curNames = struct_get_names(curStruct)
		for(var i = 0; i < array_length(curNames); ++i)
		{
			var curName = curNames[i]
			setGMLFunctionTableValue(libraryTable,curName,curStruct[$curName],true)
		}
		
		curStruct = tableVals.LuaToLuaFunctions
		curNames = struct_get_names(curStruct)
		for(var i = 0; i < array_length(curNames); ++i)
		{
			var curName = curNames[i]
			setGMLFunctionTableValue(libraryTable,curName,curStruct[$curName],false)
		}
		
		if(onLoad != noone) 
		{
			onLoad(scope)
		}
		
		if(struct_names_count(libraryTable.analogousObject) > 0)
		{
			scope.setLocalVariable(libraryName,libraryTable)
			return libraryTable;
		}
	}
}