// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function Scope(parent) constructor
{
	self.parent = parent;
	variables = {};
	getVariable = function(name)
	{
		if(variable_struct_exists(variables,name))
		{
			return variable_struct_get(variables,name);
		}
		else if(parent != noone)
		{
			return parent.getVariable(name);
		}
		else
		{
			return undefined;	
		}
	}
}

