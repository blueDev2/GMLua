// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function Scope(parent = noone) constructor
{
	//If there is no parent, this scope is the global scope
	//(Function scopes will have a global scope as the parent)
	self.parent = parent;
	variables = {};
	
	//Provides a variable struct reference
	//If the variable does not currently exist,
	//Create one with Nil value in the global scope
	function getVariable(name)
	{
		//If the variable is in the current scope, return it
		if(variable_struct_exists(variables,name))
		{
			return variable_struct_get(variables,name);
		}
		//Otherwise, if the scope has a parent, check if it has the variable
		if(parent != noone)
		{
			return parent.getVariable(name);
		}
		//If the scope does not have a parent, it must be the global scope.
		//As the final fallback, if a variable is not found in global scope, 
		//it will be added as a global.
		else
		{
			var newVariable = new Variable(new simpleValue(undefined));
			variable_struct_set(variables,name,newVariable);
			return newVariable;
		}
		
	}
	
	function getAllLocalVariables(rs = {})
	{
		var names = variable_struct_get_names(variables);
		for(var i = 0; i < array_length(names); ++i)
		{
			//If a variable is found in multiple scopes, the
			//most local scope reference is taken.
			if(!variable_struct_exists(rs,names[i]))
			{
				variable_struct_set(rs,names[i],
				variable_struct_get(variables,names[i]));
			}
		}
		//Allow the array to be garbage collected
		names = -1;
		//Do not take values from global scope
		if(parent != noone && parent.parent != noone)
		{
			parent.getAllLocalVariables(rs);
		}
		return rs;
	}
}

