// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function Scope(parent = noone) constructor
{
	//If there is no parent, this scope is the global scope
	self.parent = parent;
	variables = {};
	
	//Provides a variable struct reference
	//If the variable does not currently exist,
	//Create one with Nil value in the proper scope
	function getVariable(name,onlyLocal = false)
	{
		if(variable_struct_exists(variables,name))
		{
			return variable_struct_get(variables,name);
		}
		
		if(onlyLocal)
		{
			var newVariable = new Variable();
			variable_struct_set(variables,name,newVariable);
		}
		else
		{
			if(parent != noone)
			{
				return parent.getVariable(name);
			}
			else
			{
				var newVariable = new Variable();
				variable_struct_set(variables,name,newVariable);
			}
		}
	}
	
	function getAllLocalVariables(rs = {})
	{
		var names = variable_struct_get_names(variables);
		for(var i = 0; i < array_length(names); ++i)
		{
			if(!variable_struct_exists(rs,names[i]))
			{
				variable_struct_set(rs,names[i],
				variable_struct_get(variables,names[i]));
			}
		}
		names = -1;
		//Do not take values from global scope
		if(parent != noone && parent.parent != noone)
		{
			parent.getAllLocalVariables(rs);
		}
		return rs;
	}
}

