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
	REFERENCE
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

//Input expressions, output expressions. Treated as a reference in the
//Interpreter. Point at non-table values
//SHOULD ALWAYS BE ASSOCIATED WITH A TABLE
function ReferenceType(container, key) : valueParent() constructor
{
	type = LuaTypes.REFERENCE;
	self.ReferenceObject = new Reference(container,key);
	getValue = function()
	{
		return GMLToLua(ReferenceObject.getValue());
	}
	setValue = function(newValue)
	{
		ReferenceObject.setValue(LuaToGML(newValue));
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
}

function Function(ASTFunc) : valueParent() constructor
{
	self.val = ASTFunc;
	self.persistentScope = new Scope();
	type = LuaTypes.FUNCTION;
	getValue = function()
	{
		return val;
	}
	setValue = function(newVal)
	{
		val = newVal;
	}
}

function GMFunction(funcRef) :  valueParent() constructor
{
	self.val = funcRef;
	type = LuaTypes.GMFUNCTION
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
//newAnalogousObject must be a struct or instance
//getValue and setValue expect and return expression, 
//so a table may act as a reference in the interpreter.
function Table(newVal = {}, newAnalogousObject = {}) constructor
{
	val = newVal;
	type = LuaTypes.TABLE;
	analogousObject = newAnalogousObject;
	metaTable = noone;
	
	getValue = function(key)
	{
		key = LuaToGML(key);
		var expression = val[$key];	
		if(expression.type == LuaTypes.TABLE)
		{
			return expression;
		}
		// Must be a "ReferenceType" expression
		else if(expression.type = LuaTypes.REFERENCE)
		{
			return expression.getValue();
		}
		else
		{
			return new simpleValue(undefined);	
		}
	}
	setValue = function(key,newVal)
	{
		key = LuaToGML(key);
		//The reference struct is used because references can handle both
		//structs and instances
		var refToValue = (new Reference(analogousObject,key,false));
		refToValue.setValue(LuaToGML(newVal));
		if(newVal.type == LuaTypes.TABLE)
		{
			val[$key] = newVal;
		}
		//newVal is a non-table expression, which will be saved using reference expression that
		//points to the analagous object.
		else
		{
			val[$key] = new ReferenceType(analogousObject,key);
		}
	}
}
function LuaToGML(luaItem)
{
	if(luaItem.type == LuaTypes.TABLE)
	{
		return luaItem.analogousObject;	
	}
	if(luaItem.type == LuaTypes.FUNCTION || luaItem.type == LuaTypes.THREAD)
	{
		return luaItem;
	}
	return luaItem.val;
}

//There is no difference between a number and a script function in GML
//If trying to use a script function(func), pass it through 
//method(undefined, func) first
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
		return new Table({},gmlItem);
	}
	InterpreterException("Failed to change a GML value to lua");
}

function Variable(value = new simpleValue(undefined),attribute = noone): valueParent() constructor
{
	self.attribute = attribute;
	self.value = value;
	function getValue()
	{
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
}
