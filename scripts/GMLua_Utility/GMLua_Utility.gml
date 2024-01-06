// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

//This is to allow an inderect call to a function using an array of arguments
//and a reference to the function

//This is really ugly and there may be a better way, but I have not found it
//15 normal arguments allowed. The 16th argument is an array of all arguments.
function callFunction(functionRef, arguments)
{

	arr = array_create(15,undefined);
	for(var i = 0; i < array_length(arguments); ++i)
	{
		arr[i] = arguments[i];
	}

	return functionRef(arr[0],arr[1],arr[2],arr[3],arr[4],
	arr[5],arr[6],arr[7],arr[8],arr[9],arr[10],arr[11],arr[12],arr[13],
	arr[14],arguments);
}

// Helper struct that acts like a pointer. An enviorment (container)
// and key are stored in this so that an expression and a variable have
// the same interface. getValue() must always suceed, but setValue()
// may fail.
// NOT AN ENVIORMENT TYPE. Just a useful struct of interpreter's interal
// logic when peforming visit calls. 
function Reference(container,key = undefined, checkExistance = true) constructor
{
	self.container = container;
	self.key = key;
	if(key == undefined)
	{
		getValue = function()
		{
			return container;
		}
		setValue = function(newVal)
		{
			InterpreterException("Attempted to set the value of a reference that does not have a key.");	
		}
	}
	else
	{
		if(checkExistance)
		{
			var errMsg = "Reference attempts to index a non-existant key";
			switch(typeof(container))
			{
				case "struct":
					if(!variable_struct_exists(container,key))
					{
						InterpreterException(errMsg)
					}
				break
				case "ref":
					if(!variable_instance_exists(container,key))
					{
						InterpreterException(errMsg)
					}
				break
			}
		}
		getValue = function()
		{
			switch(typeof(container))
			{
				case "struct":
					return variable_struct_get(container,key);
				break
				case "ref":
					return variable_instance_get(container,key);
				break
			}
		}
		setValue = function(newVal)
		{
			switch(typeof(container))
			{
				case "struct":
					variable_struct_set(container,key,newVal);
				break
				case "ref":
					variable_instance_set(container,key,newVal);
				break
			}
		}	
	}
	toString = function()
	{
		return "{key: " + string(key)+"}";
	}
}

