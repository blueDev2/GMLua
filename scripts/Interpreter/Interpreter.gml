// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function Interpreter(chunk) constructor
{
	globalScope = new Scope(noone);
	currentScope = new Scope(globalScope);
	//globalScope.getVariable("_ENV")
	gc = instance_create_depth(0,0,0,GarbageCollector);
	visitChunk = function()
	{
		for(var i = 0; i < array_length(chunk.globals); ++i)
		{
			visitStatement(chunk.globals[i]);
		}
	}
	
	/*
	visit = function(visitor)
	{
		if(visitor.astType == AST.STATEMENT || 
		visitor.expressionType == Expression.FUNCTIONCALL)
		{
			visitStatement(visitor);
		}
		else
		{
			return visitExpression(visitor);
		}
	}*/
	helpVisitBlock = function(block)
	{
		for(var i = 0; i < array_length(block); ++i)
		{
			visitStatement(block[i]);	
		}
	}
	visitStatement = function(visitor)
	{
		if(variable_struct_get(visitor,"expressionType") == Expression.FUNCTIONCALL)
		{
			visitFunctionCall(visitor);	
		}
		switch(visitor.statementType)
		{
			case Statement.ASSIGNMENT:
				visitAssignment(visitor);
			break;
			case Statement.BREAK:
				visitBreak(visitor);
			break;
			case Statement.DECLARATION:
				visitDeclaration(visitor);
			break;
			case Statement.DO:
				visitDo(visitor);
			break;
			case Statement.GENERICFOR:
				visitGenericFor(visitor);
			break;
			case Statement.NUMERICFOR:
				visitNumericFor(visitor);
			break
			case Statement.GOTO:
				visitGoto(visitor);
			break;
			case Statement.IF:
				visitIf(visitor);
			break;
			case Statement.LABEL:
				visitLabel(visitor);
			break;
			case Statement.REPEAT:
				visitRepeat(visitor);
			break;
			case Statement.RETURN:
				visitReturn(visitor);
			break;
			case Statement.WHILE:
				visitWhile(visitor);
			break;
			default:
				InterpreterException("Attempted to visit a statement, but visitor is not a statement");
			break;
		}
	}
	visitAssignment = function(visitor)
	{
		expressionValues = [];
		nameList = [];
		for(var i = 0; i < array_length(visitor.expressions); ++i)
		{
			var curExpression = visitAsValue(visitor.expressions[i]);
			//If return is array (can only happen with function calls),
			//if the current expression is the last value, append all values
			//to the end of the expressionValues, otherwise, only add
			//the first return value.
			if(typeof(curExpression) == "array")
			{
				if(i == array_length(visitor.expressions) -1)
				{
					for(var j = 0; j < array_length(curExpression); ++j)
					{
						array_push(expressionValues,curExpression[j]);
					}					
				}
				else
				{
					array_push(expressionValues,curExpression[0]);
				}
			}
			else
			{
				array_push(expressionValues,curExpression);
			}
		}
		
		for(var i = 0; i < array_length(visitor.names); ++i)
		{
			//These should all return a Variable value
			var curName = visitAccess(visitor.names[i]);
			if(curName.attribute == "const")
			{
				InterpreterException("Attempted to modify a const variable");	
			}
			array_push(nameList,curName);
		}
		//If expressionValues has less elements than names, fill the 
		//expressionValues with Nil Values until expressionValues has
		//the same number of elements as names.
		while(array_length(expressionValues) < array_length(nameList))
		{
			array_push(expressionValues,new simpleValue(undefined));
		}
		
		for(var i = 0; i < array_length(curName); ++i)
		{
			nameList[i].setValue(expressionValues[i]);
		}
	}
	visitBreak = function(visitor)
	{
		BreakException();
	}
	visitDeclaration = function(visitor)
	{
		//If expression is an array, it's a "regular" declaration
		//else, it must be a function declaration.
		if(typeof(visitor.expression) == "array")
		{
			//This is nearly identical to an assignemnt, except for
			// access visit is local based and an attributeList must be dealt with.
			expressionValues = [];
			nameList = [];
			arrtributeList = visitor.attribute;
			for(var i = 0; i < array_length(visitor.expressions); ++i)
			{
				var curExpression = visitAsValue(visitor.expressions[i]);
				//If return is array (can only happen with function calls),
				//if the current expression is the last value, append all values
				//to the end of the expressionValues, otherwise, only add
				//the first return value.
				if(typeof(curExpression) == "array")
				{
					if(i == array_length(visitor.expressions) -1)
					{
						for(var j = 0; j < array_length(curExpression); ++j)
						{
							array_push(expressionValues,curExpression[j]);
						}					
					}
					else
					{
						array_push(expressionValues,curExpression[0]);
					}
				}
				else
				{
					array_push(expressionValues,curExpression);
				}
			}
		
			for(var i = 0; i < array_length(visitor.names); ++i)
			{
				//These should all return a Variable value
				//Also, must be local
				var curName = visitAccess(visitor.names[i],true);
				curName.attribute = attributeList[i];
				array_push(nameList,curName);
			}
			//If expressionValues has less elements than names, fill the 
			//expressionValues with Nil Values until expressionValues has
			//the same number of elements as names.
			while(array_length(expressionValues) < array_length(nameList))
			{
				array_push(expressionValues,new simpleValue(undefined));
			}
		
			for(var i = 0; i < array_length(curName); ++i)
			{
				nameList[i].setValue(expressionValues[i]);
			}
		}
		else
		{
			var curName = visitAccess(visitor.name,visitor.isLocal);
			var funcBody = visitFunctionBody(visitor.expression);
			curName.value = funcBody;
		}
	}
	visitDo = function(visitor)
	{
		currentScope = new Scope(currentScope)
		try
		{
			helpVisitBlock(visitor.block);
		}
		finally
		{
			currentScope = currentScope.parent;
		}
	}
	visitGenericFor = function(visitor)
	{
		try
		{
			
		}
		catch(e)
		{
			if(e.type != ExceptionType.BREAK)
			{
				throw(e);
			}
		}
	}
	visitNumericFor = function(visitor)
	{
		
		var controlVariable = new Variable();
		var inital = visitAsValue(visitor.inital);
		var limit = (visitAsValue(visitor.limit)).val;
		var step = (visitAsValue(visitor.step)).val;
		controlVariable.value = inital;
		
		

		while((step > 0 && controlVariable.value.val <= limit.val)
		|| (step < 0 && controlVariable.value.val >= limit.val))
		{
			currentScope = new Scope(currentScope);
				
			variable_struct_set(currentScope.variables,
			visitor.initalName,controlVariable);
			
			try
			{
				helpVisitBlock(visitor.block);
				currentScope = currentScope.parent;
			}
			catch(e)
			{
				currentScope = currentScope.parent;
				if(e.type != ExceptionType.BREAK)
				{
					throw(e);	
				}
				else
				{
					break;	
				}
			}
		}

		
	}
	//Disabled until I can figure out how to deal with scope
	visitGoto = function(visitor)
	{
		
	}
	visitIf = function(visitor)
	{

		var blockExecuted = false;
		for(var i = 0; i < array_length(visitor.conditions) && !blockExecuted;++i)
		{
			var conditionValue = (visitAsValue(visitor.conditions[i])).value;
			currentScope = new Scope(currentScope);
			try
			{
				if(conditionValue != false && conditionValue != undefined)
				{
					blockExecuted = true;
					helpVisitBlock(visitor.blocks[i]);
				}
			}
			finally
			{
				currentScope = currentScope.parent;
			}
		}
		if(!blockExecuted && 
		(array_length(visitor.conditions) < array_length(visitor.blocks)))
		{
			currentScope = new Scope(currentScope);
			try
			{
				helpVisitBlock(visitor.blocks[array_length(visitor.blocks)-1]);
			}
			finally
			{
				currentScope = currentScope.parent;	
			}
		}
	}
	//Just do nothing
	visitLabel = function(visitor)
	{
		
	}
	visitRepeat = function(visitor)
	{
		var condition = new simpleValue(true);
		var hasBreak = false;
		while(!hasBreak && condition.val != undefined && condition.val != false)
		{
			currentScope = new Scope(currentScope);
			try
			{
				array_length(visitor.block)
			}
			catch(e)
			{
				if(e.type != ExceptionType.BREAK)
				{
					currentScope = currentScope.parent;
					throw(e);
				}
				else
				{
					hasBreak = true;
				}
			}
			condition = visitAsValue(visitor.condition);
			currentScope = currentScope.parent;
		}
		
	}
	visitReturn = function(visitor)
	{
		var expressionValues = [];
		for(var i = 0; i < visitor.expressions;++i)
		{
			array_push(expressionValues,visitAsValue(visitor.expressions[i]));
		}
		ReturnException(expressionValues);
	}
	visitWhile = function(visitor)
	{
		var condition =  visitAsValue(visitor.condition);
		var hasBreak = false;
		while(!hasBreak && condition.val != undefined && condition.val != false)
		{
			currentScope = new Scope(currentScope);
			try
			{
				array_length(visitor.block);
			}
			catch(e)
			{
				if(e.type != ExceptionType.BREAK)
				{
					currentScope = currentScope.parent;
					throw(e);
				}
				else
				{
					hasBreak = true;
				}
			}
			currentScope = currentScope.parent;
			condition = visitAsValue(visitor.condition);
		}
	}
	
	visitAsValue = function(visitor,canReturnMultiple = false)
	{
		var rs = visitExpression(visitor);
		if(typeof(rs) == "array")
		{
			if(!canReturnMultiple)
			{
				if(rs[0].type == LuaTypes.VARIABLE)
				{
					rs[0] = (rs[0]).getValue();
				}
				return rs[0]
			}
			for(var i = 0; i < array_length(rs); ++i)
			{
				if(rs[i].type == LuaTypes.VARIABLE)
				{
					rs[i] = (rs[i]).getValue();
				}
			}
		}
		else if(rs.type == LuaTypes.VARIABLE)
		{
			rs = rs.getValue();
		}
		return rs;
	}
	visitExpression = function(visitor)
	{
		switch(visitor.expressionType)
		{
			case Expression.ACCESS:
				return visitAccess(visitor);
			break;
			case Expression.BINOP:
				return visitBinop(visitor);
			break;
			case Expression.FUNCTIONBODY:
				return visitFunctionBody(visitor);
			break;
			case Expression.FUNCTIONCALL:
				return visitFunctionCall(visitor);
			break;
			case Expression.GROUP:
				return visitGroup(visitor);
			break;
			case Expression.LITERAL:
				return visitLiteral(visitor);
			break;
			case Expression.TABLE:
				return visitTable(visitor);
			break;
			case Expression.UNIOP:
				return visitUniop(visitor);
			break;
			default:
				InterpreterException("Attempted to visit a expression, but visitor is not a expression");
			break
		}
	}
	
	// Must return a Variable Reference
	visitAccess = function(visitor,localOnly = false)
	{
		var curName;
		var curExpression;
		if(typeof(visitor.name) == "string")
		{
			curName = currentScope.getVariable(visitor.name,localOnly);	
			if(visitor.expression == noone)
			{
				return curName;
			}
			curName = curName.getValue();
		}
		else
		{
			curName = visitAsValue(visitor.name);
		}
		if(curName.type != LuaTypes.TABLE || curName.type != LuaTypes.GMOBJECT)
		{
			InterpreterException("Attempted to index a non-indexable value: " + string(curName));	
		}
		curExpression = visitAsValue(visitor.expression);
		return curName.getValue(curExpression.val);
	}
	
	visitBinop = function(visitor)
	{
		var curFirst = visitor.first;
		var curSecond = visitor.second;
		var operator = visitor.operator;
		//switch(operator)
		{
			//case	
		}
	}
	
	visitFunctionBody = function(visitor)
	{	
		var newFunc = new Function(visitor);

		/*Create a new scope
		Set the new scope's variables to current scope's variables
		Get references to all variables available to the current scope
		Set new Func's persistentScope to the new scope
		*/
		
		var newPersistentScope = new Scope(globalScope);
		newPersistentScope.variables = currentScope.getAllLocalVariables();
		
		newFunc.persistentScope = newPersistentScope;
		
		return newFunc;
	}
	
	visitFunctionCall = function(visitor)
	{
		var func = visitAsValue(visitor.name);
		var args = visitor.args;
		
		if(func.type == LuaTypes.FUNCTION)
		{
			var previousScope = currentScope;
			currentScope = func.persistentScope;
			var paramList = func.ASTFunc.paramlist;
		
			var argsList = [];
			for(var i = 0; i < array_length(args);++i)
			{
				if(i != array_length(args)-1)
				{
					var curExpression = visitAsValue(args[i],true);
					if(typeof(curExpression) == "array")
					{
						for(var j = 0; j < array_length(curExpression); ++j)
						{
							array_push(argsList,curExpression[i]);
						}
					}
					else
					{
						array_push(argsList,curExpression);
					}
				}
				else
				{
					array_push(argsList,visitAsValue(args[i]));
				}
			}
		
			for(var i = 0;i < array_length(paramList); ++i)
			{
				if(i < array_length(argsList))
				{
					variable_struct_set(currentScope.variables,paramList[i],
					new Variable(argsList[i]));
				}
				else
				{
					variable_struct_set(currentScope.variables,paramList[i],
					new Variable());
				}
			}
		
			if(func.isVarArgs)
			{
				var newTable = new Table(gc);
				for(var j = array_length(paramList); 
				j < array_length(args); ++j)
				{
					newTable.vars[? j - array_length(visitor.paramList)+1] =
					visitAsValue(visitor.args[i]);
				}
				variable_struct_set(currentScope,"args",new Variable(newTable));
			}
			var rs = new simpleValue(undefined);		
			try
			{
				for(var i = 0; i < array_length(func.block); ++i)
				{
					visitStatement(func.block[i]);
				}
				currentScope = previousScope;
			}
			catch(e)
			{
				currentScope = previousScope;
				if(e.type == ExceptionType.RETURN)
				{
					rs = e.value;
				}
				else if(e.type == ExceptionType.BREAK)
				{
					e.type = ExceptionType.UNCATCHABLE;
					throw(e);
				}
			}
			return rs;
		}
		else if(func.type == LuaTypes.GMFUNCTION)
		{
			for(var i = 0; i < array_length(args); ++i)
			{
				args[i] = visitAsValue(args[i]);	
			}
			return GMLToLua(callFunction(func.val,args));
		}
		InterpreterException("Attempted to call a non-function");	
		
	}
	
	visitGroup = function(visitor)
	{
		return visitAsValue(visitor.group);
	}
	
	visitLiteral = function(visitor)
	{
		return new simpleValue(visitor.value);
	}
	
	visitTable = function(visitor)
	{
		var newTable = new Table(gc);
		for(var i = 0; i < array_length(visitor.keys); ++i)
		{
			var curValue = visitAsValue(visitor.value[i]);
			var curKey = visitAsValue(visitor.keys[i]);
			newTable.setValue(curKey.val, new Variable(curValue));
		}
		return newTable;
	}
	
	visitUniop = function(visitor)
	{
		var firstValue = visitAsValue(visitor.first);
		var curOperator = visitor.operator;
		switch(curOperator)
		{
			case "not":
				if(firstValue.type = LuaTypes.BOOLEAN)
				{
					firstValue.val = !firstValue.val; 
					return firstValue;
				}
			break;
			case "#":
				if(firstValue.type = LuaTypes.TABLE)
				{
					return new simpleValue(ds_map_size(firstValue.val));
				}
			break;
			case "-":
				if(firstValue.type == LuaTypes.INTEGER ||
				firstValue.type == LuaTypes.FLOAT)
				{
					firstValue.val = -firstValue.val; 
					return firstValue
				}
			break;
			case "~":
				if(firstValue.type == LuaTypes.INTEGER)
				{
					firstValue.val = ~firstValue.val; 
					return firstValue;
				}			
			break;
		}
		InterpreterException("Uni-operator has problems");
	}
}