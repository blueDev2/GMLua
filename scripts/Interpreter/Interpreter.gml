// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function Interpreter(chunk) constructor
{
	globalScope = new Scope(noone);
	currentScope = globalScope;
	for(var i = 0; i < array_length(chunk.globals); ++i)
	{
		visit(chunk.globals[i]);
	}
	
	visit = function(visitor)
	{
		if(visitor.astType == AST.STATEMENT)
		{
			return visitStatement(visitor);
		}
		else
		{
			return visitExpression(visitor);
		}
	}
	
	visitStatement = function(visitor)
	{
		switch(visitor.statementType)
		{
			case Statement.ASSIGNMENT:
				return visitAssignment(visitor);
			break;
			case Statement.BREAK:
				return visitBreak(visitor);
			break;
			case Statement.DECLARATION:
				return visitDeclaration(visitor);
			break;
			case Statement.DO:
				return visitDo(visitor);
			break;
			case Statement.GENERICFOR:
				return visitGenericFor(visitor);
			break;
			case Statement.NUMERICFOR:
				return visitNumericFor(visitor);
			break
			case Statement.GOTO:
				return visitGoto(visitor);
			break;
			case Statement.IF:
				return visitIf(visitor);
			break;
			case Statement.LABEL:
				return visitLabel(visitor);
			break;
			case Statement.REPEAT:
				return visitRepeat(visitor);
			break;
			case Statement.RETURN:
				return visitReturn(visitor);
			break;
			case Statement.WHILE:
				return visitWhile(visitor);
			break;
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
				return visitorLiteral(visitor);
			break;
			case Expression.TABLE:
				return visitorTable(visitor);
			break;
			case Expression.UNIOP:
				return visitorUniop(visitor);
			break;
		}
	}
	
	visitAccess = function(visitor)
	{
		var curName;
		var curExpression;
		if(typeof(visitor.name) == "string")
		{
			curName = currentScope.getVariable(vistor.name);	
		}
		else
		{
			curName = visit(visitor.name);
		}
		
		if(visitor.expression != noone) // checl that curName is a table
		{
			curExpression = visit(expression);
		}
		
	}
	
}