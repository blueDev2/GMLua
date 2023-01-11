// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function Interpreter(chunk) constructor
{
	//Variables that are always available
	globalScope = new Scope(noone);
	//Variables that are currently available
	currentScope = new Scope(globalScope);
	//globalScope.getVariable("_ENV")
	visitChunk = function()
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
		for(var i = 0; i < array_length(block); ++i)
		{
			visitStatement(block[i]);	
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
		return;
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
		return customReference;
	}
	
	visitBinop = function(visitor)
	{
		var firstExp = visitExpression(visitor.first);
		var secondExp = visitExpression(visitor.second);
		var curOperator = visitor.operator;
		var newExp = helpVisitOp(curOperator,firstExp,secondExp);
		return new Reference(newExp);
	}
	
	visitFunctionBody = function(visitor)
	{	
		var envFunction = new Function(visitor);
		
	}
	
	visitFunctionCall = function(visitor)
	{
		
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
	helpVisitOp = function(op, exp1, exp2 = noone)
	{
		if(exp1.type == LuaTypes.TABLE || 
		(exp2 != noone && exp2.type == LuaTypes.TABLE))
		{
			return callMetamethod(op,exp1,exp2);
		}
		switch(op)
		{
			//Arithmetic Operators
			case "+":
			
			break;
			case "-":
				//Can be uniary or binary
			break;
			case "*":
			
			break;
			case "/":
			
			break;
			case "//":
			
			break;
			case "%":
			
			break;
			case "^":
			
			break;
			//Bitwise Operators
			case "&":
			
			break;
			case "|":
			
			break;
			case "~":
				//Can be uniary or binary
			break;
			case ">>":
			
			break;
			case "<<":
			
			break;
			//Relational Operators
			case "==":
			
			break;
			case "~=":
			
			break;
			case "<":
			
			break;
			case ">":
			
			break;
			case "<=":
			
			break;
			case ">=":
			
			break;
			//Logical Operators
			case "and":
			
			break;
			case "or":
			
			break;
			case "not":
			
			break;
			//Concatenation
			case "..":
			
			break;
			//Length
			case "#":
			
			break;
		}
	}
	callMetamethod = function(op, exp1, exp2 = noone)
	{
		if(exp1.type = LuaTypes.TABLE)
		{
			
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