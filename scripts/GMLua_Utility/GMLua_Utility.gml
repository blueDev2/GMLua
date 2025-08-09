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


//expectedArity must be more than 0 or the value -1
//expList must be a reference or an array of references
//An array of references is always returned
function  helpPruneExpList(expList,expectedArity = 1)
{

	if(expectedArity == 1)
	{
		if(typeof(expList) != "array")
		{
			return expList;
		}
		else if(array_length(expList) > 0)
		{
			return helpPruneExpList(expList[0]);
		}
		else
		{
			return new Reference(new simpleValue(undefined));
		}
	}
		
	if(typeof(expList) != "array")
	{
		var retExpList = [];
		array_push(retExpList,expList);
		while(array_length(retExpList) < expectedArity)
		{
			array_push(retExpList,new Reference(new simpleValue(undefined)));
		}
		return retExpList;
	}
		
	if(array_length(expList) == 0)
	{
		return expList;
	}
		
	if(expectedArity == -1)
	{
		var retExpList = [];
		for(var i = 0; i < array_length(expList) - 1;++i)
		{
			array_push(retExpList, helpPruneExpList(expList[i]));
		}
		var lastRef = array_last(expList);
		if(typeof(lastRef) != "array")
		{
			array_push(retExpList,lastRef)
		}
		else
		{
			var lastList = helpPruneExpList(lastRef,array_length(lastRef));
			if(typeof(lastList) == "array")
			{
				for(var i = 0; i < array_length(lastList); ++i)
				{
					array_push(retExpList,lastList[i]);
				}
			}
			else
			{
				array_push(retExpList,lastList);
			}
		}
		return retExpList;
	}
		
	var retExpList = [];
	//Deal with all expressions except for the last one. Stop a
	//sufficient number of expressions is found.
	//All elements here must return 1 reference
	for(var i = 0; i < array_length(expList) - 1 && array_length(retExpList) < expectedArity;++i)
	{
		array_push(retExpList, helpPruneExpList(expList[i]));
	}
	//For the last element, prune the last value to extend the list
	//to fit the arity
	var remainingRequiredElements = expectedArity - array_length(retExpList);
	var finalReferences = helpPruneExpList(array_last(expList),remainingRequiredElements);
	if(remainingRequiredElements == 0)
	{}
	else if(remainingRequiredElements == 1)
	{
		array_push(retExpList,finalReferences);
	}
	else
	{
		for(var i = 0; i < array_length(finalReferences); ++i)
		{
			array_push(retExpList,finalReferences[i]);
		}
	}
	//Add undefined values to fill the expression list when needed
	//This may not be needed since finalReferences should add undefined 
	//Values as needed
	while(array_length(retExpList) < expectedArity)
	{
		array_push(retExpList,new Reference(new simpleValue(undefined)));
	}
	return retExpList;
}