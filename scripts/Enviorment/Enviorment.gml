// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
enum LuaTypes
{
	NIL,
	BOOLEAN,	
	INTEGER,
	FLOAT,
	STRING,
	FUNCTION,
	THREAD,
	TABLE,
	GMFUNCTION,
	VARIABLE,
	REFERENCE,
	EXPLIST
}

//All IDs are unique and positive
function createUniqueRefID()
{
	static idCounter = int64(0);
	idCounter++;
	return idCounter;
}

function valueParent() constructor
{
	getValue = function()
	{
		throw("getValue was not overloaded by child value constructor")
	}
	setValue = function(newVal)
	{
		throw("setValue was not overloaded by child value constructor")
	}
}

function simpleValue(val): valueParent() constructor
{
	if(typeof(val) == "int32")
	{
		val = int64(val);	
	}
	self.val = val;
	switch(typeof(val))
	{
		case "number":
			type = LuaTypes.FLOAT;
		break;
		case "string":
			type = LuaTypes.STRING;
		break;
		case "bool":
			type = LuaTypes.BOOLEAN;
		break;
		case "int64":
			type = LuaTypes.INTEGER;
		break;
		case "undefined":
			type = LuaTypes.NIL;
		break;
		default:
			InterpreterException("Issue with Interpreter: \""+string(val)+"\" is not a simple value")
		break;
	}
	toString = function()
	{
		return "{" + "type: " + string(type) + ", val: " + string(val) + "}"
	}
}

function luaFunction(ASTFunc,scope) : valueParent() constructor
{
	self.val = ASTFunc;
	self.persistentScope = scope;
	self.UID = createUniqueRefID();
	self.analogousItem = function()
	{
		global.interpreter.globalScope = persistentScope.parent;
		var expArgs = array_create(15,new simpleValue(undefined));
		for(var i = 0; i < argument_count; ++i)
		{
			expArgs[i] = GMLToLua(argument[i]);
		}
		//var prevScope = global.interpreter.currentScope;
		var funcBodyExp = self;
		var funcBodyAST = funcBodyExp.val;
		global.interpreter.currentScope = funcBodyExp.persistentScope;
			
		global.interpreter.currentScope = new Scope(global.interpreter.currentScope);
			
		var isVarArgs = funcBodyAST.isVarArgs;
		var paramNames = [];
		var block = funcBodyAST.block
		for(var i = 0; i < array_length(funcBodyAST.paramlist); ++i)
		{
			array_push(paramNames,funcBodyAST.paramlist[i])
		}

		for(var i = 0;i < array_length(paramNames); ++i)
		{
			var curExpression = new simpleValue(undefined);
			if(i < array_length(expArgs))
			{
				curExpression = expArgs[i];
			}
			global.interpreter.currentScope.setLocalVariable(paramNames[i],curExpression);
		}
		if(isVarArgs)
		{
			var varArgs = []
			for(var i = array_length(paramNames); i < array_length(expArgs); ++i)
			{
				array_push(varArgs,new Reference(expArgs[i]));
			}
			global.interpreter.currentScope.getVariable("...").setValue(new ExpressionList(varArgs,true));
		}
		try
		{
			global.interpreter.helpVisitBlock(block);
			return new Reference(new simpleValue(undefined));
		}
		catch(e)
		{
			if(!variable_struct_exists(e,"type"))
			{
				throw(e);
			}
			if(e.type == ExceptionType.BREAK || e.type == ExceptionType.JUMP)
			{
				e.type = ExceptionType.UNCATCHABLE;
			}
			if(e.type == ExceptionType.RETURN)
			{
				var retValue = (e.value);
				if(typeof(retValue) == "array")
				{
					var retArray = [];
					for(var i = 0; i < array_length(retValue); ++i)
					{
						array_push(retArray,LuaToGML(retValue[i].getValue()));
					}
					return retArray;
				}
				return LuaToGML(retValue.getValue())
			}
			if(e.lineNumber == -1)
			{
				e.lineNumber = funcBodyAST.firstLine;
			}
			global.HandleGMLuaExceptions(e,persistentScope.parent.associatedFilePath)
		}
		finally
		{
			currentScope = noone;
			globalScope = noone;
		}
	}
	type = LuaTypes.FUNCTION;
	getValue = function()
	{
		return val;
	}
	setValue = function(newVal)
	{
		val = newVal;
	}
	toString = function()
	{
		return "{" + "type: " + string(type) +", UID: "+ string(UID) + "}"
	}
}

//GMLtoGML functions take GML and return GML values
//LuaToLua will return expression structs
function GMFunction(funcRef,isGMLtoGML = true) :  valueParent() constructor
{
	self.val = funcRef;
	type = LuaTypes.GMFUNCTION
	self.UID = createUniqueRefID();
	self.isGMLtoGML = isGMLtoGML;
	getValue = function()
	{
		return val;
	}
	setValue = function(newVal)
	{
		val = newVal;
	}
	toString = function()
	{
		return "{" + "type: " + string(type) +", UID: "+ string(UID) +
		", isGMLtoGML: "+string(isGMLtoGML)+"}"
	}
}

function Thread(func) :  valueParent() constructor
{
	tempScope = new Scope();
	self.val = func;
	type = LuaTypes.THREAD;
	getValue = function()
	{
		return val;
	}
	setValue = function(newVal)
	{
		val = newVal;
	}
}

function ExpressionList(arrOfLuaitems,areRefs = false) :  valueParent() constructor
{
	type = LuaTypes.EXPLIST;
	if(!areRefs)
	{
		for(var i = 0; i < array_length(arrOfLuaitems); ++i)
		{
			arrOfLuaitems[i] = new Reference(arrOfLuaitems[i]);
		}
	}
	val = arrOfLuaitems;
	getValue = function()
	{
		return val;
	}
	setValue = function(newVal)
	{
		val = newVal;
	}/*
	toString = function()
	{
		return "{ type: " + type + ", val: "+string(val) + "}"
	}*/
}

//newAnalogousObject must be a struct or instance
//getValue and setValue expect and return expression, 
//so a table may act as a reference in the interpreter.

//Tables are not required to be "consistent" at all times
//When a expression is requested, inconsistenies between
//val and analogousObject are fixed in favor of the latter
function Table(newVal = {}, newAnalogousObject = {}) constructor
{
	//Must be a struct
	val = newVal;
	type = LuaTypes.TABLE;
	//Must be a struct or instance
	analogousObject = newAnalogousObject;
	self.UID = createUniqueRefID();
	metatable = noone;
	
	getValue = function(key)
	{
		key = LuaToHash(key);
		if(key == "undefined")
		{
			InterpreterException("Attempted to index a table with nil")
		}
		var expression = val[$key];	
		
		//Peform checks in case the analogousObject was changed in GML
		var refToValue = (new Reference(analogousObject,key,false));
		var analogousItem = refToValue.getValue();
		if(analogousItem != undefined)
		{
			var gmlType = typeof(analogousItem);
			var needsUpdate = true;
			//Table
			if(gmlType == "struct" || gmlType == "ref")
			{
				if((!is_undefined(expression)) && (expression.type == LuaTypes.TABLE)
				&& (expression.analogousObject == analogousItem))
				{
					needsUpdate = false;
				}
			}
			//Function or GMFunction
			else if(is_method(analogousItem))
			{
				if((!is_undefined(expression))&&(expression.type == LuaTypes.GMFUNCTION)
				&& expression.val == analogousItem)
				{
					needsUpdate = false;
				}
				else if((!is_undefined(expression)) && (expression.type == LuaTypes.FUNCTION) &&
				(expression.analogousItem == analogousItem))
				{
					needsUpdate = false;
				}

			}
			//Non-reference expression
			else
			{	
				var needsUpdate = false;
				if(expression == undefined)
				{
					val[$key] = new luaReference(analogousObject,key);
					expression = val[$key];	
				}
				else if(expression.type != LuaTypes.REFERENCE)
				{
					val[$key] = new luaReference(analogousObject,key);
					expression = val[$key];	
				}
			}
			//Peforms updates if the analogousItem indicates it contains
			//a by-reference expression 
			if(needsUpdate)
			{
				val[$key] = GMLToLua(analogousItem)
				expression = val[$key];	
			}
		}
		/*else if(expression == undefined)
		{
			val[$key] = new luaReference(analogousObject,key);
			expression = val[$key];	
		}
		*/
		if(is_undefined(expression))
		{
			return new simpleValue(undefined);	
		}
		else if(isExpressionByReference(expression))
		{
			return expression;
		}
		// Must be a "ReferenceType" expression
		else if(expression.type = LuaTypes.REFERENCE)
		{
			return expression.getValue();
		}
		InterpreterException("Error found, expression type within table is unexpected")
	}
	getValueFromVal = function(GMLkey)
	{
		GMLkey = LuaToHash(new simpleValue(GMLkey))
		return val[$GMLkey];
	}
	
	setValue = function(key,newVal)
	{
		key = LuaToHash(key);
		var refToValue = (new Reference(analogousObject,key,false));
		if(key == "undefined")
		{
			InterpreterException("Attempted to index a table with nil")
		}
		if(isExpressionByReference(newVal))
		{
			val[$key] = newVal;
			switch(newVal.type)
			{
				case LuaTypes.GMFUNCTION:
					refToValue.setValue(newVal.val);
				break;
				case LuaTypes.TABLE:
					refToValue.setValue(newVal.analogousObject);
				break;
				case LuaTypes.FUNCTION:
					refToValue.setValue(newVal.analogousItem);
				break
				default:
					refToValue.setValue(undefined);
				break;
			}
		}
		//newVal is a non-reference expression, which will be saved using reference expression that
		//points to the analagous object.
		else
		{
			refToValue.setValue(LuaToGML(newVal));
			val[$key] = new luaReference(analogousObject,key);
		}
	}

	toString = function()
	{
		var str = "{";
		if(true)
		{
		    str +=  "analogousObject: {"; 
			var names = noone
			switch(typeof(analogousObject))
			{
				case "struct":
					names = variable_struct_get_names(analogousObject)
					for(var i = 0; i < array_length(names);++i)
					{
						var val = variable_struct_get(analogousObject,names[i])
						if(is_instanceof(val,Scope))
						{
							continue;
						}
						str += " "+ names[i] + ": ";
						str += string(val)
						if(i != array_length(names) - 1)
						{
							str += ", "
						}
					}
				break;
				case "ref":
					names = variable_instance_get_names(analogousObject)
					for(var i = 0; i < array_length(names);++i)
					{
						var val = variable_instance_get(analogousObject,names[i])
						if(is_instanceof(val,Scope))
						{
							continue;
						}
						str += " "+ names[i] + ": ";
						str += string(val)
						if(i != array_length(names) - 1)
						{
							str += ", "
						}
					}
				break;
			}
			str += "} ,"
		}
		str += "UID: " +string(UID);
		if(metatable != noone)
		{
			str += ", metatable.UID: " +string(metatable.UID);
		}
		str += "}";
		return str;
	}
}

//Input expressions, output expressions. Treated as a reference in the
//Interpreter. Point at non-reference values
//SHOULD ALWAYS BE ASSOCIATED WITH A TABLE
function luaReference(container, key) : valueParent() constructor
{
	type = LuaTypes.REFERENCE;
	self.ReferenceObject = new Reference(container,key,false);
	//Returns a GML value
	getValue = function()
	{
		return GMLToLua(ReferenceObject.getValue());
	}
	//Takes Expressions, saves GML
	setValue = function(newValue)
	{
		ReferenceObject.setValue(LuaToGML(newValue));
	}
	toString = function()
	{
		return string(ReferenceObject)
	}
}
function LuaToGML(luaItem)
{
	if(luaItem.type == LuaTypes.TABLE)
	{
		return luaItem.analogousObject;	
	}
	else if(luaItem.type == LuaTypes.GMFUNCTION)
	{
		return luaItem.val;
	}
	else if(luaItem.type == LuaTypes.FUNCTION)
	{
		return luaItem.analogousItem;
	}
	return luaItem.val;
}
function LuaToHash(luaItem)
{
	switch(luaItem.type)
	{
		case (LuaTypes.TABLE):
		{
			return "Table_"+string(luaItem.UID);		
		}
		case (LuaTypes.FUNCTION):
		{
			return "Function_"+string(luaItem.UID);	
		}
		case (LuaTypes.GMFUNCTION): 
		{
			return "GMFunction_"+string(luaItem.UID);		
		}
		case (LuaTypes.STRING):
		{
			static hash_prefixes = 
			["Table_","Function_", "GMFunction_","Number_"];
			static direct_hashes =
			["Nil","Boolean_True", "Boolean_False"];
			var str = luaItem.val
			for(var i = 0 ; i < array_length(hash_prefixes); ++i)
			{
				if(string_starts_with(str,hash_prefixes[i]))
				{
					InterpreterException("A string used as an index in a table cannot be prefixed with \""+hash_prefixes[i]+"\"")
				}
			}
			for(var i = 0 ; i < array_length(direct_hashes); ++i)
			{
				if(string_starts_with(str,direct_hashes[i]))
				{
					InterpreterException("A string used as an index in a table cannot be \""+direct_hashes[i]+"\"")
				}
			}
			return luaItem.val;	
		}
		case (LuaTypes.NIL):
		{
			return "Nil"
		}
		case (LuaTypes.BOOLEAN):
		{
			if(luaItem.val)
			{
				return "Boolean_True";
			}
			return "Boolean_False"
		}
		case (LuaTypes.INTEGER):
		{
			return "Number_" + string(luaItem.val);
		}
		case (LuaTypes.FLOAT):
		{
			return "Number_" + string(luaItem.val);
		}

		InterpreterException("LuaItem is non-hashable (Likely an issue with Table)")
	}
}

//There is no difference between a number and a script function in GML
//If trying to use a script function(func), pass it through 
//method(undefined, func) first
//Arrays are not allowed, use a struct with numeric keys instead
function GMLToLua(gmlItem)
{
	var type = typeof(gmlItem);
	if(type == "number" || type == "string" || type == "bool"
	|| type == "int32" || type == "int64" || type == "undefined")
	{
		return new simpleValue(gmlItem);	
	}
	else if(is_method(gmlItem))
	{
		return new GMFunction(gmlItem);
	}
	//Do not call instance_destroy on an object used in a Lua Table
	//Unless you know you will not use that table after destroying the instance
	else if(type == "struct" || type == "ref")
	{
		var newTable = new Table({},gmlItem);
		return newTable;
	}
	InterpreterException("Failed to change a GML value to lua");
}

function isExpressionFalsy(expression)
{
	return (expression.type == LuaTypes.NIL || (
			expression.type == LuaTypes.BOOLEAN &&
			expression.val == false));
}

function isExpressionByReference(expression)
{
	return(expression.type == LuaTypes.TABLE ||
	expression.type == LuaTypes.FUNCTION ||
	expression.type == LuaTypes.GMFUNCTION ||
	expression.type == LuaTypes.THREAD)
}

function Variable(value = new simpleValue(undefined),attribute = noone): valueParent() constructor
{
	//Always either "const"(as a string) or noone
	self.attribute = attribute;
	//Always an expression
	self.value = value;
	function getValue()
	{
		var curType = value.type;
		if(curType == LuaTypes.BOOLEAN ||
		curType == LuaTypes.FLOAT ||
		curType == LuaTypes.INTEGER ||
		curType == LuaTypes.NIL ||
		curType == LuaTypes.STRING)
		{
			return new simpleValue(value.val);
		}
		return self.value;	
	}
	function setValue(value)
	{
		if(attribute == "const")
		{
			InterpreterException("Attempted to change a constant variable");	
		}
		self.value = value;
	}
	type = LuaTypes.VARIABLE;
	toString = function()
	{
		return "{" + "type: " + string(type) + ", value: " + string(value) + "}";
	}
}
