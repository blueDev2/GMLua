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
		return "{" + "type: " + string(type) +", val: "+ string(val) + "}"
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
			var needsUpdate = false;
			if(gmlType == "struct" || gmlType == "ref")
			{
				if(is_undefined(expression))
				{
					needsUpdate = true;
				}
				else if(expression.type != LuaTypes.TABLE)
				{
					needsUpdate = true;
				}
				else
				{
					if(expression.analogousObject != analogousItem)
					{
						needsUpdate = true;
					}
				}
			}
			else if(is_method(analogousItem))
			{
				if(is_undefined(expression))
				{
					needsUpdate = true;
				}
				else if(expression.type != LuaTypes.GMFUNCTION)
				{
					needsUpdate = true;
				}
				else
				{
					if(expression.val != analogousItem)
					{
						needsUpdate = true;
					}
				}
			}
			else
			{
				
				if(expression == undefined)
				{
					val[$key] = luaReference(analogousObject,key);
					expression = val[$key];	
				}
				else if(expression.type != LuaTypes.REFERENCE)
				{
					val[$key] = luaReference(analogousObject,key);
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
		throw("Error found, expression type within table is unexpected")
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
				case LuaTypes.TABLE:
				refToValue.setValue(newVal.analogousObject);
				default:
				refToValue.setValue(undefined);
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
		var str =  "{analogousObject: " +string(analogousObject)+", UID: "
		+string(UID);
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
	self.ReferenceObject = new Reference(container,key);
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
	if(luaItem.type == LuaTypes.FUNCTION 
	|| luaItem.type == LuaTypes.THREAD|| luaItem.type == LuaTypes.GMFUNCTION)
	{
		return luaItem;
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
			return "String_"+luaItem.val;	
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
			throw("Attempted to change a constant variable");	
		}
		self.value = value;
	}
	type = LuaTypes.VARIABLE;
	toString = function()
	{
		return "{" + "type: " + string(type) + ", value: " + string(value) + "}";
	}
}
