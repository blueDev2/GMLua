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
	GMOBJECT,
	VARIABLE
}

function simpleValue(val) constructor
{
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
		case "int64" || "int32":
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

function Function(ASTFunc) constructor
{
	self.val = ASTFunc;
	self.persistentScope = new Scope();
	type = LuaTypes.FUNCTION;
}

function GMFunction(funcRef) constructor
{
	self.val = funcRef;
	type = LuaTypes.GMFUNCTION
}

function GMObject(obj) constructor
{
	self.val = obj;
	type = LuaTypes.GMOBJECT;
	getValue = function(name)
	{
		name = name.val;
		var checkedValue;
		switch(typeof(val))
		{
			case "struct":
				checkedValue = variable_struct_get(val,name);
			break;
			case "ref":
				checkedValue = variable_instance_get(val,name);
			break;
		}
		return GMLToLua(checkedValue);
	}
	setValue = function(name,newVal)
	{
		name = name.val;
		newVal = newVal.val;
		switch(typeof(val))
		{
			case "struct":
				variable_struct_set(val,name,newVal);
			break;
			case "ref":
				variable_instance_set(val,name,newVal);
			break;
		}
	}
}

function Thread(func) constructor
{
	tempScope = new Scope();
	self.val = func;
	type = LuaTypes.THREAD;
}

function Table(gc) constructor
{
	val = ds_map_create();
	type = LuaTypes.TABLE;
	getValue = function(key)
	{
		if(variable_struct_exists(key,"val"))
		{
			key = key.val;
		}
		return val[?key];	
	}
	setValue = function(key,newVal)
	{
		if(variable_struct_exists(key,"val"))
		{
			key = key.val;
		}
		val[?key] = newVal;
	}
	//ds maps are collected via an instance of an object 
	//that checks if the LuaObject is collected or not and
	//if it is collected, destroy the ds_map
	gc.addTable(self);
}
//Using this on a Lua Object is not recommended
function GMLToLua(gmlItem)
{
	var type = typeof(gmlItem);
	if(type == "number" || type == "string" || type == "bool"
	|| type == "int32" || type == "int64" || type == "undefined")
	{
		return new simpleValue(gmlItem);	
	}
	else if(is_method(gmlItem) || script_exists(gmlItem))
	{
		return new GMFunction(gmlItem);
	}
	else if(type == "struct" || type == "ref")
	{
		return new GMObject(gmlItem);
	}
	InterpreterException("Failed to change a GML value to lua");
}

function Variable(value = new simpleValue(undefined),attribute = noone) constructor
{
	self.attribute = attribute;
	self.value = value;
	function getValue()
	{
		return self.value;	
	}
	function setValue(value)
	{
		self.value = value;
	}
	type = LuaTypes.VARIABLE;
}
