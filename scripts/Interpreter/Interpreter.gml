// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
global.interpreter = {};
with(global.interpreter)
{
	//Variables that are always available
	globalScope = new Scope(noone);
	//Variables that are currently available
	currentScope = new Scope(globalScope);
	//globalScope.getVariable("_ENV")
	visitChunk = function(chunk,scopes)
	{
		for(var i = 0; i < array_length(chunk.globals); ++i)
		{
			visitStatement(chunk.globals[i]);
		}
	}
	
	visit = function(visitor)
	{
		if(visitor.astType == AST.STATEMENT)
		{
			visitStatement(visitor);
		}
		else if(visitor.astType == AST.EXPRESSION)
		{
			return visitExpression(visitor);
		}
	}
	helpVisitBlock = function(block)
	{
		var statements = block.statements;
		for(var i = 0; i < array_length(statements); ++i)
		{
			visitStatement(statements[i]);	
		}
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
	//Statements
	visitAssignment = function(visitor)
	{
		
	}
	visitBreak = function(visitor)
	{
		BreakException();
	}
	visitDeclaration = function(visitor)
	{
		
	}
	visitGenericFor = function(visitor)
	{
		
	}
	visitNumericFor = function(visitor)
	{
		
	}
	//Disabled until I can figure out how to deal with scope
	visitGoto = function(visitor)
	{
		
	}
	visitIf = function(visitor)
	{

	}
	//Just do nothing
	visitLabel = function(visitor)
	{
		
	}
	visitRepeat = function(visitor)
	{
		
	}
	visitReturn = function(visitor)
	{
		
	}
	visitWhile = function(visitor)
	{
		
	}


	//Expressions
	//All expression visitors must return a reference that gets and
	//sets Enviorment expressions.
	visitAccess = function(visitor)
	{
		if(visitor.expression == noone)
		{
			return currentScope.getVariable(visitor.name);
		}
		var curName = visitExpression(visitor.name);
		var curExp = visitExpression(visitor.expression);
		
		var curNameExpression = curName.getValue();
		if(curNameExpression.type != LuaTypes.TABLE)
		{
			throw("Attempted to index a non-table");	
		}
		var curExpExpression = curExp.getValue();
		//Table references needs additional context to work properly
		//However, visit functions must return a reference that has
		//2 functions, getValue() and setValue(newVal)
		var customReference = {};
		with(customReference)
		{
			key = curExpExpression;
			tableRef = curNameExpression;
			getValue = function()
			{
				tableRef.getValue(key);
			}
			setValue = function(newVal)
			{
				tableRef.setValue(key,newVal);
			}
		}
		//If indexing the table at a particuar key returns NIL,
		//Peform a metamethod call for __index.
		if(customReference.getValue().val == undefined)
		{
			var newExp = callMetamethod("[]",curNameExpression,curExpExpression);
			//This new expression can be Nil
			customReference = new Reference(newExp);
		}
		return customReference;
	}
	
	visitBinop = function(visitor)
	{
		var curOperator = visitor.operator;
		var opIsAnd = (curOperator == "and");
		var opIsOr = (curOperator == "or");
		var firstExp = visitExpression(visitor.first);
		var firstFalsy = (firstExp.val == false || firstExp.val == undefined);
		//Short circut eval
		if(opIsAnd && firstFalsy)
		{
			return new Reference(firstExp.getValue());
		}
		if(opIsOr && !firstFalsy)
		{
			return new Reference(firstExp.getValue());
		}
		var secondExp = visitExpression(visitor.second);
		if(opIsAnd || opIsOr)
		{
			return new Reference(secondExp.getValue());
		}
		var newExp = helpVisitOp(curOperator,firstExp,secondExp);
		return new Reference(newExp);
	}
	
	visitFunctionBody = function(visitor)
	{	
		var envFunction = new Function(visitor);
		
	}
	
	visitFunctionCall = function(visitor)
	{
		var ref = visitExpression(visitor.name)
		var argExpressions = [];
		var object = ref.container;
		if(visitor.isMethod)
		{
			array_push(argExpressions,object)
		}
		for(var i = 0; i < array_length(visitor.args);++i)
		{
			array_push(argExpressions,visitExpression(visitor.args[i]));
		}
	}
	
	visitGroup = function(visitor)
	{
		return visitExpression(visitor.group);
	}
	
	visitLiteral = function(visitor)
	{
		return new Reference(new simpleValue(visitor.value));
	}
	
	visitTable = function(visitor)
	{
		
	}
	
	visitUniop = function(visitor)
	{
		var firstValue = visitExpression(visitor.first);
		var firstValueExp = firstValue.getValue();
		var curOperator = visitor.operator;
		var newExp = helpVisitOp(curOperator,firstValueExp);
		return new Reference(newExp);
	}
	
	//Any expression with an operator will call this
	//Must return an expression
	//May call a metamethod (which also must return an expression)
	helpVisitOp = function(op, exp1, exp2 = noone)
	{
		//For certain relational operatorions 
		var negateFinal = false;
		switch(op)
		{
			case "~=":
				op = "==";
				negateFinal = true;
				break;
			case ">":
				op = "<";
				temp = exp1;
				exp1 = exp2;
				exp2 = temp;
				break;
			case ">=":
				op = "<=";
				temp = exp1;
				exp1 = exp2;
				exp2 = temp;
				break;
		}
		var isBinary = (exp2 != noone);
		if(exp2 == noone)
		{
			exp2 = exp1;	
		}
		var exp1Val = exp1.val;
		var exp2Val = exp2.val;
		

		static MetamethodFailureException = function(exp1,exp2,op)
		{
			InterpreterException("Failed to find an appropriate metamethod for " + string(exp1) + " and " + string(exp2) +"\nUnder the operator: " + op);
		}
		static ArithmetricExecute = function(exp1, exp2, case1Function, case2Function = noone)
		{
			if(case2Function == noone)
			{
				case2Function = case1Function;	
			}
			var exp1Val = exp1.val;
			var exp2Val = exp2.val;
			var isExp1Int = (exp1.type == LuaTypes.INTEGER);
			var isExp2Int = (exp2.type == LuaTypes.INTEGER);
			if(isExp1Int && isExp2Int)
			{
				return new simpleValue(case1Function(exp1Val, exp2Val));
			}
			var isExp1Num = isExp1Int || (exp1.type == LuaTypes.FLOAT);
			var isExp2Num = isExp2Int || (exp2.type == LuaTypes.FLOAT);
			if(isExp1Num && isExp2Num)
			{
				return new simpleValue(case2Function(exp1Val, exp2Val));
			}	
			return noone;
		}
		static BitwiseExecute = function(exp1, exp2, func)
		{
			var exp1Val = exp1.val;
			var exp2Val = exp2.val;
			if(exp1.type == LuaTypes.INTEGER)
			{}
			else if(exp1.type == LuaTypes.FLOAT)
			{
				if(frac(exp1Val) == 0)
				{
					exp1Val = int64(exp1Val);
				}
				else
				{
					return noone;
				}
			}
			else
			{
				return noone
			}
			
			if(exp2.type == LuaTypes.INTEGER)
			{}
			else if(exp2.type == LuaTypes.FLOAT)
			{
				if(frac(exp2Val) == 0)
				{
					exp2Val = int64(exp2Val);
				}
				else
				{
					return noone;
				}
			}
			else
			{
				return noone
			}
			return new simpleValue(func(exp1Val, exp2Val));
		}
		switch(op)
		{
			//Arithmetic Operators
			case "+":
			{
				var addIntegers = function(val1, val2)
				{
					return val1+val2;
				}
				var addNumbers = function(val1, val2)
				{
					return real(val1)+real(val2);
				}
				var retExp = ArithmetricExecute(exp1, exp2, addIntegers, addNumbers);
				if(retExp == noone)
				{
					retExp = callMetamethod(op, exp1, exp2);
					if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}
				}
				return retExp;
			}
			break;
			case "-":
			{
				var retExp = noone;
				//Can be uniary or binary
				if(isBinary)
				{
					var subtractIntegers = function(val1, val2)
					{
						return val1-val2;
					}
					var subtractNumbers = function(val1, val2)
					{
						return real(val1) - real(val2);
					}
					retExp = ArithmetricExecute(exp1, exp2,subtractIntegers,subtractNumbers);
				}
				else
				{
					var negateNumber = function(val1, val2)
					{
						return -1 * val1;
					}
					retExp = ArithmetricExecute( exp1, exp2, negateNumber);
				}
				if(retExp == noone)
				{
					if(isBinary)
					{
						retExp = callMetamethod(op, exp1, exp2);
					}
					else
					{
						retExp = callMetamethod(op, exp1);
					}
					if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}
				}
				return retExp;
			}
			break;
			case "*":
			{
				var multiplyIntegers = function(val1, val2)
				{
					return val1*val2;
				}
				var multiplyNumbers = function(val1,val2)
				{
					return real(val1)*real(val2)
				}
				var retExp = ArithmetricExecute(exp1, exp2,multiplyIntegers, multiplyNumbers);
				if(retExp == noone)
				{
					retExp = callMetamethod(op, exp1, exp2);
					if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}
				}
				return retExp;
			}
			break;
			case "/":
			{
				var retExp = noone;
				if((exp1.type == LuaTypes.INTEGER || exp1.type == LuaTypes.FLOAT) &&
				(exp2.type == LuaTypes.INTEGER || exp2.type == LuaTypes.FLOAT))
				{
					retExp = new simpleValue(real(exp1Val) / real(exp2Val));
				}
				if(retExp == noone)
				{
					retExp = callMetamethod(op, exp1, exp2);
					if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}
				}
				return retExp;
			}
			break;
			case "//":
			{
				var divideIntegers = function(val1, val2)
				{
					return floor(val1/val2);
				}
				var divideNumbers = function(val1, val2)
				{
					return floor(real(val1)/real(val2));
				}
				var retExp = ArithmetricExecute(exp1,exp2,divideIntegers,divideNumbers);
				if(retExp == noone)
				{
					retExp = callMetamethod(op, exp1, exp2);
					if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}
				}
				return retExp;
			}
			break;
			case "%":
			{
				//This may cause floating point percision issues, a better solution should be found
				var integralModulo = function(val1, val2)
				{
					return (val1 - (int64(val1/val2))*val2);
				}
				var numberModulo = function(val1, val2)
				{
					return (val1-(int64(real(val1)/real(val2)))*val2)
				}
				var retExp = ArithmetricExecute(exp1, exp2,integralModulo,numberModulo);
				if(retExp == noone)
				{
					retExp = callMetamethod(op, exp1, exp2);
					if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}
				}
				return retExp;
			}
			break;
			case "^":
			{
				var retExp = noone;
				if((exp1.type == LuaTypes.INTEGER || exp1.type == LuaTypes.FLOAT) &&
				(exp2.type == LuaTypes.INTEGER || exp2.type == LuaTypes.FLOAT))
				{
					retExp = new simpleValue(power(real(val1), real(val2)));
				}
				if(retExp == noone)
				{
					retExp = callMetamethod(op, exp1, exp2);
					if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}
				}
				return retExp;
			}
			break;
			//Bitwise Operators
			case "&":
			{
				var bitwiseAND = function(val1, val2)
				{
					return val1 & val2;
				}
				var retExp = BitwiseExecute(exp1,exp2,bitwiseAND);
				if(retExp == noone)
				{
					retExp = callMetamethod(op, exp1, exp2);
					if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}
				}
				return retExp;
			}
			break;
			case "|":
			{
				var bitwiseOR = function(val1, val2)
				{
					return val1 | val2;
				}
				var retExp = BitwiseExecute(exp1,exp2,bitwiseOR);
				if(retExp == noone)
				{
					retExp = callMetamethod(op, exp1, exp2);
					if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}
				}
				return retExp;
			}
			break;
			case "~":
			{
				//Can be uniary or binary
				var retExp = noone;
				if(isBinary)
				{
					var bitwiseXOR = function(val1, val2)
					{
						return val1 ^ val2;
					}
					retExp = BitwiseExecute(exp1,exp2,bitwiseXOR);
				}
				else
				{
					var bitwiseNOT = function(val1, val2)
					{
						return ~val1
					}
					retExp = BitwiseExecute(exp1,exp2,bitwiseNOT);
				}
				if(retExp == noone)
				{
					if(isBinary)
					{
						retExp = callMetamethod(op, exp1, exp2);
					}
					else
					{
						retExp = callMetamethod(op, exp1);	
					}
					if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}
				}
				return retExp;
			}
			break;
			case ">>":
			{
				var bitwiseRS = function(val1, val2)
				{
					return val1 >> val2;
				}
				var retExp = BitwiseExecute(exp1,exp2,bitwiseRS);
				if(retExp == noone)
				{
					retExp = callMetamethod(op, exp1, exp2);
					if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}
				}
				return retExp;
			}
			break;
			case "<<":
			{
				var bitwiseLS = function(val1, val2)
				{
					return val1 << val2;
				}
				var retExp = BitwiseExecute(exp1,exp2,bitwiseLS);
				if(retExp == noone)
				{
					retExp = callMetamethod(op, exp1, exp2);
					if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}
				}
				return retExp;
			}
			break;
			//Relational Operators
			case "==":
			{
				var retExp = noone;
				if(exp1.type != exp2.type)
				{
					retExp = false;	
				}
				else
				{
					if(exp1.type == LuaTypes.TABLE && exp2.type == LuaTypes.TABLE)
					{
						retExp = (exp1 == exp2);
						if(!retExp)
						{
							retExp = callMetamethod(op, exp1,exp2);
						}
						if(retExp == noone)
						{
							retExp = false;
						}
					}
					else if(exp1.type == LuaTypes.FUNCTION)
					{
						retExp = (exp1 == exp2);
					}
					else
					{
						retExp = (exp1.val == exp2.val);
					}
				}
				if(retExp == noone)
				{
					MetamethodFailureException(op, exp1, exp2);
				}
				if(negateFinal)
				{
					retExp = !retExp;
				}
				return retExp;
			}
			break;
			case "<":
			{
				
			}
			break;
			case "<=":
			{
				
			}
			break;
			//Logical Operators
			//To allow for short-circut evaluation, visitBinop will deal
			//with "and" and "or" operators
			case "not":
			{
				if(exp1Val == false || exp1Val == undefined)
				{
					return new simpleValue(true);
				}
				return new simpleValue(false);
			}
			break;
			//Concatenation
			case "..":
			{
				
			}
			break;
			//Length
			case "#":
			{
				
			}
			break;
		}

	}
	//This may return "noone", helpVisitOp must deal with that value
	//Otherwise, this must return an expression
	callMetamethod = function(op, exp1, exp2 = noone)
	{
		if(exp1.type = LuaTypes.TABLE)
		{
			switch(op)
			{
				//Index
				case "[]":
			
				break;
				//New Index
				case "=[]":
				
				break;
				//Call
				case "()":
			
				break;	
			}
		}
		else if(exp2 != noone && exp2.type = LuaTypes.TABLE)
		{
			
		}
		else
		{
			InterpreterException("No metamethod is provided for " + op);	
		}
	}
	
}