// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
global.interpreter = {};
function startUpGMLua_Interpreter()
{
	with(global.interpreter)
{
	//Variables that are always available
	globalScope = new Scope(noone);
	//Variables that are currently available
	currentScope = new Scope(globalScope);

	

	function visitChunk(chunk, scope = new Scope(noone))
	{
		// Interpreter is global, so changes to global scope cannot be done until the interpreter
		// is fully done with it.
		static interpreterBusy = false
		if(interpreterBusy)
		{
			InterpreterException("Attempted to execute a chunk while already executing a chunk")
		}
		interpreterBusy = true
		scope.associatedFilePath = chunk.sourceFilePath+chunk.sourceFileName
		globalScope = scope;
		
		setGMLVariable(scope,"self",self,true);
		setGMLVariable(scope,"other",other,true);
		setGMLVariable(scope,"all",all,true);
		setGMLVariable(scope,"noone",noone,true);
		

		
		addBasicLibraries(scope)
		
		currentScope = new Scope(scope);
		try
		{
			helpVisitBlock(chunk.block);
		}
		catch(e)
		{
			HandleGMLuaExceptions(e,scope.associatedFilePath);
		}
		finally
		{
			interpreterBusy = false;
		}
		scope  = currentScope.parent;
		globalScope = noone;
		currentScope = noone;
		return scope;
	}

	helpVisitBlock = function(block,threadTrace = undefined)
	{
		var i = 0;
		if(!is_undefined(threadTrace)&& array_length(threadTrace) != 0)
		{
			var trace = array_pop(threadTrace)
			i = trace.index;
		}
		while(i < array_length(block.statements))
		{
			try
			{
				for(; i < array_length(block.statements); ++i)
				{
					if(!is_undefined(threadTrace)&& array_length(threadTrace) == 0)
					{
						threadTrace = undefined
					}
					visitStatement(block.statements[i],threadTrace);
				}
			}
			catch(e)
			{
				if(is_instanceof(e,Scope))
				{
					throw(e)
				}
				if(!variable_struct_exists(e,"type"))
				{
					throw(e);
				}
				if(e.type == ExceptionType.JUMP)
				{
					if(variable_struct_exists(block.gotoIndices,e.value))
					{
						i = block.gotoIndices[$e.value];
					}
					else
					{
						throw(e)
					}
				}
				else if(e.type == ExceptionType.YIELD)
				{
					var trace = new Thread_Trace((-1),,i)
					array_push(e.threadTraces,trace)
					throw(e)	
				}
				else
				{
					throw(e)	
				}
			}
		}
	}
	
	visit = function(visitor,threadTrace = undefined)
	{
		if(visitor.astType == AST.STATEMENT)
		{
			visitStatement(visitor,threadTrace);
		}
		else if(visitor.astType == AST.EXPRESSION)
		{
			return visitExpression(visitor,threadTrace);
		}
	}

	visitExpression = function(visitor,threadTrace = undefined)
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
				return visitFunctionCall(visitor,threadTrace);
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
	visitStatement = function(visitor,threadTrace = undefined)
	{
		try
		{
			if(variable_struct_get(visitor,"expressionType") == Expression.FUNCTIONCALL)
			{
				visitFunctionCall(visitor,threadTrace);	
				return;
			}
			switch(visitor.statementType)
			{
				case Statement.ASSIGNMENT:
					visitAssignment(visitor,threadTrace);
				break;
				case Statement.BREAK:
					visitBreak(visitor);
				break;
				case Statement.DECLARATION:
					visitDeclaration(visitor,threadTrace);
				break;
				case Statement.DO:
					visitDo(visitor,threadTrace);
				break;
				case Statement.GENERICFOR:
					visitGenericFor(visitor,threadTrace);
				break;
				case Statement.NUMERICFOR:
					visitNumericFor(visitor,threadTrace);
				break
				case Statement.GOTO:
					visitGoto(visitor);
				break;
				case Statement.IF:
					visitIf(visitor,threadTrace);
				break;
				case Statement.LABEL:
					visitLabel(visitor);
				break;
				case Statement.REPEAT:
					visitRepeat(visitor,threadTrace);
				break;
				case Statement.RETURN:
					visitReturn(visitor,threadTrace);
				break;
				case Statement.WHILE:
					visitWhile(visitor,threadTrace);
				break;
				default:
					InterpreterException("Attempted to visit a statement, but visitor is not a statement");
				break;
			}
		}
		catch(e)
		{
			if(is_instanceof(e,Scope))
			{
				throw(e);
			}
			if(!variable_struct_exists(e,"type"))
			{
				throw(e);
			}
			if(variable_struct_get(visitor,"expressionType") != Expression.FUNCTIONCALL)
			array_push(e.lineNumbers, visitor.firstLine);
			throw(e)
		}
	}
	//Statements
	visitAssignment = function(visitor,threadTrace = undefined)
	{
		var lAstExps = visitor.names;
		var rAstExps = visitor.expressions;
		var lExpRefs = [];
		var rExpRefs = [];
		
		var i = 0
		var trace = noone;
		if(!is_undefined(threadTrace) && array_length(threadTrace) != 0)
		{
			trace = array_pop(threadTrace);
			i = trace.index;
			rExpRefs = trace.rExpRefs;
		}
		
		try
		{
			for(i = 0; i < array_length(rAstExps); ++i)
			{
				array_push(rExpRefs,visitExpression(rAstExps[i],threadTrace));
			}
		}
		catch(e)
		{
			if(!variable_struct_exists(e,"type"))
			{
				throw(e);
			}
			if(e.type == ExceptionType.YIELD)
			{
				var trace = new Thread_Trace(Statement.ASSIGNMENT,,i)
				trace.rExpRefs = rExpRefs;
				array_push(e.threadTraces,trace);
			}
			throw(e)
		}
		
		for(var i = 0; i < array_length(lAstExps); ++i)
		{
			array_push(lExpRefs,visitExpression(lAstExps[i]));
		}
		
		rExpRefs = helpPruneExpList(rExpRefs,array_length(lExpRefs));
		if(typeof(rExpRefs) != "array")
		{
			rExpRefs = [rExpRefs]
		}
		var rExps = [];
		for(var i = 0; i < array_length(rExpRefs); ++i)
		{
			var curRExp = rExpRefs[i].getValue();
			array_push(rExps,curRExp);
		}
		
		for(var i = 0; i < array_length(rExpRefs); ++i)
		{
			var curLRef = lExpRefs[i];
			var curRExp = rExps[i];
			curLRef.setValue(curRExp);
		}
	}
	visitBreak = function(visitor)
	{
		BreakException();
	}
	visitDeclaration = function(visitor,threadTrace = undefined)
	{
		var lAstExps = visitor.names;
		var rAstExps = visitor.expressions;

		var rExpRefs = [];
		
		var i = 0
		var trace = noone;
		if(!is_undefined(threadTrace) && array_length(threadTrace) != 0)
		{
			trace = array_pop(threadTrace);
			i = trace.index;
			rExpRefs = trace.rExpRefs;
		}
		
		try
		{
			for(i = 0; i < array_length(rAstExps); ++i)
			{
				array_push(rExpRefs,visitExpression(rAstExps[i],threadTrace));
			}
		}
		catch(e)
		{
			if(!variable_struct_exists(e,"type"))
			{
				throw(e);
			}
			if(e.type == ExceptionType.YIELD)
			{
				var trace = new Thread_Trace(Statement.DECLARATION,,i)
				trace.rExpRefs = rExpRefs;
				array_push(e.threadTraces,trace);
			}
			throw(e)
		}
		
		rExpRefs = helpPruneExpList(rExpRefs,array_length(lAstExps));
		if(typeof(rExpRefs) != "array")
		{
			rExpRefs = [rExpRefs]
		}
		
		for(var i = 0; i < array_length(rExpRefs); ++i)
		{
			var curLAST = lAstExps[i];
			var curRExp = rExpRefs[i].getValue();
			currentScope.setLocalVariable(curLAST.name,curRExp,visitor.attributes[i]);
		}
		
	}
	visitDo = function(visitor,threadTrace = undefined)
	{
		if(!is_undefined(threadTrace)&& array_length(threadTrace) != 0)
		{
			var trace = array_pop(threadTrace);
			currentScope = trace.scope;
		}
		else
		{
			currentScope = new Scope(currentScope);
		}
		try
		{	
			helpVisitBlock(visitor.block,threadTrace);
		}
		catch(e)
		{
			if(!variable_struct_exists(e,"type"))
			{
				throw(e);
			}
			if(e.type == ExceptionType.YIELD)
			{
				array_push(e.threadTraces,new Thread_Trace(Statement.DO,currentScope));
			}
		}
		finally
		{
			currentScope = currentScope.parent;
		}
	}
	
	visitGenericFor = function(visitor,threadTrace = undefined)
	{
		var namelist = visitor.namelist;
		var explist = visitor.explist;
		var block = visitor.block;
		
		var iterCall = new ASTFunctionCall(new ASTAccess("0_f"),
		[new ASTAccess("0_s"), new ASTAccess("0_var")]);;
		var controlVariable = noone;
		
		var hasThreadTrace = !is_undefined(threadTrace) && array_length(threadTrace) != 0
		var trace = noone
		
		if(hasThreadTrace)
		{
			trace = array_pop(threadTrace);
			currentScope = trace.scope
			controlVariable = trace.controlVariable
		}
		
		if(!hasThreadTrace)
		{
			var rExpRefs = [];
			for(var i = 0; i < array_length(explist); ++i)
			{
				array_push(rExpRefs, visitExpression(explist[i]));
			}
			rExpRefs = helpPruneExpList(rExpRefs,3);
			currentScope = new Scope(currentScope);
		
			var iterExp = rExpRefs[0].getValue();
			var invariantExp = rExpRefs[1].getValue();
			var controlExp =  rExpRefs[2].getValue();
		
			currentScope.setLocalVariable("0_f",iterExp)
			currentScope.setLocalVariable("0_s",invariantExp)
			currentScope.setLocalVariable("0_var",controlExp)
		
			controlVariable = currentScope.getVariable("0_var");
		}
		
		var caughtBreak = false;
		while(!caughtBreak)
		{
			if(!hasThreadTrace)
			{
				var varValueRefs = noone;
				varValueRefs = visitExpression(iterCall);
				varValueRefs = helpPruneExpList(varValueRefs,array_length(namelist));
				if(typeof(varValueRefs) != "array")
				{
					varValueRefs = [varValueRefs]
				}
				currentScope = new Scope(currentScope);
				for(var i = 0; i < array_length(namelist); ++i)
				{
					currentScope.setLocalVariable(namelist[i],varValueRefs[i].getValue());
				}
				controlVariable.setValue(currentScope.getVariable(namelist[0]).getValue())
				if(controlVariable.getValue().type = LuaTypes.NIL)
				{
					currentScope = currentScope.parent.parent;
					return;
				}
			}
			else
			{
				hasThreadTrace = false;
			}
			try
			{
				helpVisitBlock(block,threadTrace);
			}
			catch(e)
			{
				var tempCurScope = currentScope
				currentScope = currentScope.parent;
				if(!variable_struct_exists(e,"type"))
				{
					throw(e);
				}
				if(e.type ==  ExceptionType.BREAK)
				{
					caughtBreak = true;					
				}
				else if(e.type == ExceptionType.YIELD)
				{
					var trace = new Thread_Trace(Statement.GENERICFOR,
					tempCurScope)
					trace.controlVariable = controlVariable;
					array_push(e.threadTraces,trace);
					throw(e);
				}
				else
				{
					throw(e);
				}
			}
			finally
			{
				//descope to remove the scope that contains the control 
				//variable
				currentScope = currentScope.parent;	
			}
		}
	}
	visitNumericFor = function(visitor,threadTrace = undefined)
	{
		var limitVal;
		var stepVal;
		var controlVariable;
		var isUpperBound;
		var caughtBreak = false;
		var hasThreadTrace = !is_undefined(threadTrace) && array_length(threadTrace) != 0
		var trace = noone;
		
		if(!hasThreadTrace)
		{
			var initalName = visitor.initalName;
			var initalExpression = visitExpression(visitor.inital).getValue();
			var limitExpression = visitExpression(visitor.limit).getValue();
			var stepExpression = visitExpression(visitor.step).getValue();
		
			currentScope = new Scope(currentScope);
			currentScope.setLocalVariable(initalName,initalExpression)
		
			if(initalExpression.type != LuaTypes.INTEGER ||
			stepExpression.type != LuaTypes.INTEGER)
			{
				initalExpression = GMLToLua(real(initalExpression.val));
				limitExpression = GMLToLua(real(limitExpression.val));
				stepExpression = GMLToLua(real(stepExpression.val));
			}
			limitVal = limitExpression.val;
			stepVal = stepExpression.val;
			if(stepVal == 0)
			{
				InterpreterException("Step cannot be 0");	
			}
			controlVariable = currentScope.getVariable(initalName)
			isUpperBound = (stepVal > 0);
		}
		else
		{
			trace = array_pop(threadTrace)
			limitVal = trace.limitVal;
			stepVal = trace.stepVal;
			controlVariable = trace.controlVariable;
			isUpperBound = trace.isUpperBound;
		}
		
		var controlVal = controlVariable.getValue().val;
		try
		{
			while((isUpperBound && controlVal <= limitVal) || 
			(!isUpperBound && controlVal >= limitVal))
			{
				if(hasThreadTrace)
				{
					currentScope = trace.scope;
					hasThreadTrace = false;
				}
				else
				{
					currentScope = new Scope(currentScope);
				}
				helpVisitBlock(visitor.block,threadTrace);
				//If an error occurs, descoping is missed
				currentScope = currentScope.parent;
				
				controlVal += stepVal;
				controlVariable.setValue(GMLToLua(controlVal));
			}
		}
		catch(e)
		{
			//descope to account for the inner block descoping missed
			//due to the exception
			if(!variable_struct_exists(e,"type"))
			{
				throw(e);
			}
			if(e.type ==  ExceptionType.BREAK)
			{
				caughtBreak = true;					
			}
			if(e.type == ExceptionType.YIELD)
			{
				var trace = new Thread_Trace(Statement.NUMERICFOR,currentScope);
				trace.controlVariable = controlVariable;
				trace.isUpperBound = isUpperBound;
				trace.limitVal = limitVal;
				trace.stepVal = stepVal;
				array_push(e.threadTraces,trace);
				throw(e);
			}
			currentScope = currentScope.parent;
		}
		finally
		{
			//descope to remove the scope that contains the control 
			//vaeiable
			currentScope = currentScope.parent;	
		}
	}
	visitGoto = function(visitor)
	{
		JumpException(visitor)
	}
	visitIf = function(visitor,threadTrace = undefined)
	{
		var conditions = visitor.conditions;
		var blocks = visitor.blocks;
		var i = 0;
		//Find the first condition that returns a non-false and non-nil
		//expression
		var hasThreadTrace = !is_undefined(threadTrace) && array_length(threadTrace) != 0;
		var trace = noone;
		if(hasThreadTrace)
		{
			trace = array_pop(threadTrace)
			i = trace.index
		}
		
		while(!hasThreadTrace && i < array_length(conditions))
		{
			var conditionExpression = visitExpression(conditions[i]).getValue();
			if(isExpressionFalsy(conditionExpression))
			{
				++i;
			}
			else
			{
				break;
			}
		}
		if(i < array_length(blocks))
		{
			if(hasThreadTrace)
			{
				currentScope = trace.scope
			}
			else
			{
				currentScope = new Scope(currentScope);
			}
			try
			{
				helpVisitBlock(blocks[i],threadTrace)
			}
			catch(e)
			{
				if(!variable_struct_exists(e,"type"))
				{
					throw(e);
				}
				if(e.type == ExceptionType.YIELD)
				{
					var trace = new Thread_Trace(Statement.IF,currentScope,i)
					array_push(e.threadTraces,trace);
				}
				throw(e)
			}
			finally
			{
				currentScope = currentScope.parent;
			}
		}
	}
	visitRepeat = function(visitor,threadTrace = undefined)
	{			
		var condition =  visitor.condition;
		var block = visitor.block;
		var caughtBreak = false;
		var hasThreadTrace = !is_undefined(threadTrace) && array_length(threadTrace) != 0;
		var trace = noone;
		if(hasThreadTrace)
		{
			trace = array_pop(threadTrace)
		}
			
		do
		{
			if(hasThreadTrace)
			{
				currentScope = trace.scope;
			}
			else
			{
				currentScope = new Scope(currentScope);
			}
			hasThreadTrace = false;
			try
			{	
				helpVisitBlock(block,threadTrace);
			}
			catch(e)
			{
				if(!variable_struct_exists(e,"type"))
				{
					throw(e);
				}
				if(e.type ==  ExceptionType.BREAK)
				{
					caughtBreak = true;					
				}
				else if(e.type == ExceptionType.YIELD)
				{
					var trace = new Thread_Trace(Statement.REPEAT,currentScope)
					array_push(e.threadTraces,trace);
					throw(e)
				}
				else
				{
					throw(e);
				}
			}
			finally
			{
				//Visit the condition within the inner scope
				if(!caughtBreak)
				{
					conditionExpression = visitExpression(condition).getValue();
				}
				currentScope = currentScope.parent;
			}		

		}
		until(caughtBreak || !isExpressionFalsy(conditionExpression))
		
	}
	visitReturn = function(visitor,threadTrace = undefined)
	{
		var expressions = visitor.expressions;
		var retExps = [];
		var trace = noone
		if(!is_undefined(threadTrace) && array_length(threadTrace) != 0)
		{
			trace = array_pop(threadTrace);
		}
		var i = 0
		if(trace != noone)
		{
			i = trace.index;
		}
		for(; i < array_length(expressions); ++i)
		{
			
			try
			{
				array_push(retExps,visitExpression(expressions[i],threadTrace));
			}
			catch(e)
			{
				if(!variable_struct_exists(e,"type"))
				{
					throw(e);
				}
				if(e.type == ExceptionType.YIELD)
				{
					var trace = new Thread_Trace(Statement.RETURN,,i)
					array_push(e.threadTraces,trace)
				}
				throw(e)
			}
		}
		retExps = helpPruneExpList(retExps,-1);
		ReturnException(retExps);
	}
	visitWhile = function(visitor,threadTrace = undefined)
	{
		var condition =  visitor.condition;
		var block = visitor.block;
		var conditionExpression = noone;
		
		var caughtBreak = false;
		
		var hasThreadTrace = !is_undefined(threadTrace) && array_length(threadTrace) != 0;
		var trace = noone;
		if(hasThreadTrace)
		{
			trace = array_pop(threadTrace)
		}
		else
		{
			conditionExpression = visitExpression(condition).getValue();
		}
		
		while(hasThreadTrace || (!caughtBreak && !isExpressionFalsy(conditionExpression)))
		{
			if(hasThreadTrace)
			{
				currentScope = trace.scope
				hasThreadTrace = false;
			}
			else
			{
				currentScope = new Scope(currentScope);
			}
			try
			{	
				helpVisitBlock(block,threadTrace);
			}
			//Break exceptions are allowed
			//All other exceptions are rethrown
			catch(e)
			{
				if(!variable_struct_exists(e,"type"))
				{
					throw(e);
				}
				if(e.type ==  ExceptionType.BREAK)
				{
					caughtBreak = true;					
				}
				else if(e.type == ExceptionType.YIELD)
				{
					var trace = new Thread_Trace(Statement.WHILE,currentScope)
					array_push(e.threadTraces,trace);
					throw(e);
				}
				else
				{
					throw(e);
				}
			}
			finally
			{
				currentScope = currentScope.parent;
			}		
			if(!caughtBreak)
			{
				conditionExpression = visitExpression(condition).getValue();
			}
		}
	}
	
	//Should be impossible, labels are discarded by parser.
	visitLabel = function(visitor)
	{
		InterpreterException("A label has been visted, there is an issue with the interpreter or parser");
	}


	//Expressions
	//All expression visitors must return a reference that gets and
	//sets Enviorment expressions.
	visitAccess = function(visitor)
	{
		if(visitor.expression == noone)
		{

			var retExp = currentScope.getVariable(visitor.name);
			
			try
			{
				if(retExp.getValue().type == LuaTypes.EXPLIST)
				{
					retExp = retExp.getValue().getValue();
				}
			}
			catch(e)
			{
				show_debug_message("ONCE AGAIN A FUCKUP")	
			}
			
			return retExp;
		}
		var curName = visitExpression(visitor.name);
		var curExp = visitExpression(visitor.expression);
		
		var curNameExpression = curName.getValue();
		var curExpExpression = curExp.getValue();
		if(curExpExpression.val == undefined)
		{
			InterpreterException("Undefined indexing");
		}
		//Table references needs additional context to work properly
		//However, visit functions must return a reference that has
		//2 functions, getValue() and setValue(newVal)
		if(curNameExpression.type != LuaTypes.TABLE)
		{
			InterpreterException("Non-table value attempted to be indexed");
		}
		var customReference = {};
		with(customReference)
		{
			key = curExpExpression;
			tableRef = curNameExpression;
			//This is here so the customReference will use
			//callMetamethod in the right (GML) scope
			interpreter = other;
			getValue = function()
			{
				var rawValExpression = tableRef.getValue(key);
				if(rawValExpression.type == LuaTypes.NIL &&
				tableRef.metatable != noone && 
				!is_undefined(tableRef.metatable.getValue(new simpleValue("__index"))))
				{
					rawValExpression = interpreter.callMetamethod("[]",tableRef,key);
				}
				return rawValExpression;
			}
			setValue = function(newVal)
			{
				var rawValExpression = tableRef.getValue(key);
				if(tableRef.metatable != noone && 
				!is_undefined(tableRef.metatable.getValue(new simpleValue("__newindex"))) && 
				rawValExpression.type == LuaTypes.NIL)
				{
					rawValExpression = interpreter.callMetamethod("=[]",tableRef,key,newVal);
				}
				else
				{
					tableRef.setValue(key,newVal);
				}
			}
		}
		return customReference;
	}
	
	visitBinop = function(visitor)
	{
		var curOperator = visitor.operator;
		var opIsAnd = (curOperator == "and");
		var opIsOr = (curOperator == "or");
		var firstExp = (helpPruneExpList(visitExpression(visitor.first))).getValue();
		var firstFalsy = (firstExp.val == false || firstExp.val == undefined);
		//Short circut eval
		if(opIsAnd && firstFalsy)
		{
			return new Reference(firstExp);
		}
		if(opIsOr && !firstFalsy)
		{
			return new Reference(firstExp);
		}
		var secondExp = (helpPruneExpList(visitExpression(visitor.second))).getValue();
		if(opIsAnd || opIsOr)
		{
			return new Reference(secondExp);
		}
		var newExp = helpVisitOp(curOperator,firstExp,secondExp);
		return new Reference(newExp);
	}
	
	visitFunctionBody = function(visitor)
	{	
		var pScope = currentScope.copyLocalScope();
		if(visitor.isVarArgs)
		{
			pScope.setLocalVariable("...");
		}
		pScope.parent = globalScope;
		return new Reference(new luaFunction(visitor,pScope));	
	}
	
	visitFunctionCall = function(visitor,threadTrace = undefined)
	{
		var trace = noone;
		if(!is_undefined(threadTrace) && array_length(threadTrace) != 0)
		{
			trace = array_pop(threadTrace);
		}
		
		if(trace != noone && trace.statementType == Statement.RETURN)
		{
			return trace.value
		}
		var funcBodyExp = noone;
		var expArgsRefs = [];
		var expArgs = [];
		
		if(trace == noone)
		{
			var funcBody = visitExpression(visitor.name)
			var isMethod = (visitor.finalIndex != noone)
			if(isMethod)
			{
				array_push(expArgs,funcBody);
				var finalIndexExp = visitExpression(finalIndex).getValue();
				funcBodyExp = funcBody.getValue().getValue(finalIndexExp);
			}
			else
			{
				funcBodyExp = funcBody.getValue();
			}
			var ASTArgs = visitor.args;
			for(var i = 0; i < array_length(ASTArgs); ++i)
			{
				array_push(expArgsRefs,visitExpression(ASTArgs[i]));
			}
		
			expArgsRefs = helpPruneExpList(expArgsRefs,-1);
			if(typeof(expArgsRefs) != "array")
			{
				expArgsRefs = [expArgsRefs];
			}
		
			for(var i = 0; i < array_length(expArgsRefs); ++i)
			{
				array_push(expArgs,expArgsRefs[i].getValue());
			}
		}
		if(trace != noone || funcBodyExp.type == LuaTypes.FUNCTION)
		{
			var prevScope = noone
			var block = noone
			if(trace == noone)
			{
				prevScope = currentScope;
				var funcBodyAST = funcBodyExp.val;
				currentScope = funcBodyExp.persistentScope;
			
				currentScope = new Scope(currentScope);
			
				var isVarArgs = funcBodyAST.isVarArgs;
				var paramNames = [];
				block = funcBodyAST.block
				for(var i = 0; i < array_length(funcBodyAST.paramlist); ++i)
				{
					array_push(paramNames,funcBodyAST.paramlist[i])
				}

				for(var i = 0;i < array_length(paramNames); ++i)
				{
					var curExpression = new simpleValue(undefined);
					if(i < array_length(expArgs))
					{
						curExpression = expArgs[i];
					}
					currentScope.setLocalVariable(paramNames[i],curExpression);
				}
				if(isVarArgs)
				{
					var varArgs = []
					for(var i = array_length(paramNames); i < array_length(expArgs); ++i)
					{
						array_push(varArgs,new Reference(expArgs[i]));
					}
					currentScope.getVariable("...").setValue(new ExpressionList(varArgs,true));
				}
			}
			else
			{
				currentScope = trace.scope;
				prevScope = trace.prevScope;
				block = trace.block
			}
			try
			{
				helpVisitBlock(block,threadTrace);
				return new Reference(new simpleValue(undefined));
			}
			catch(e)
			{
				if(is_instanceof(e,Scope))
				{
					throw(e);
				}
				if(!variable_struct_exists(e,"type"))
				{
					throw(e);
				}
				if(e.type == ExceptionType.BREAK || e.type == ExceptionType.JUMP)
				{
					e.type = ExceptionType.UNCATCHABLE;
				}
				if(e.type == ExceptionType.RETURN)
				{
					return (e.value);
				}
				if(e.type == ExceptionType.YIELD)
				{
					var trace = new Thread_Trace(Expression.FUNCTIONCALL,currentScope);
					trace.prevScope = prevScope;
					trace.block = block
					array_push(e.threadTraces,trace)
				}
				//array_push(e.lineNumbers, visitor.firstLine);
				throw(e);
			}
			finally
			{
				currentScope = prevScope;
			}
		}
		else if(funcBodyExp.type == LuaTypes.GMFUNCTION)
		{
			var GMLfunc = funcBodyExp.val;
			
			{
				//Expects either an array of Luaitems or a Luaitem, no references
				if(!funcBodyExp.isGMLtoGML)
				{
					var retVal =  (callFunction(GMLfunc,expArgs));
					if(typeof(retVal) == "array")
					{
						for(var i = 0; i < array_length(retVal);++i)
						{
							retVal[i] = new Reference((retVal[i]));
						}
						return retVal;
					}
					else
					{
						return new Reference(retVal);
					}
				}
				var GMLParameters = [];
				for(var i = 0; i < array_length(expArgs); ++i)
				{
					array_push(GMLParameters,LuaToGML(expArgs[i]));
				}
				var retVal = callFunction(GMLfunc,GMLParameters);
				if(typeof(retVal) == "array")
				{
					for(var i = 0; i < array_length(retVal);++i)
					{
						retVal[i] = new Reference(GMLToLua(retVal[i]));
					}
					return retVal;
				}
				else
				{
					return new Reference(GMLToLua(retVal));
				}
			}
		}
		else if(funcBodyExp.type == LuaTypes.TABLE)
		{
			return callMetamethod("()",funcBodyExp,expArgs);
		}
		else
		{
			InterpreterException("Cannot peform a function call on "
			+ string(visitor.name));
		}
	}
	
	visitGroup = function(visitor)
	{
		//Groups are defined to return 1 expression at all times
		return helpPruneExpList(visitExpression(visitor.group));
	}
	
	visitLiteral = function(visitor)
	{
		return new Reference(new simpleValue(visitor.value));
	}
	
	visitTable = function(visitor)
	{
		var keyASTs = visitor.keys;
		var valueASTs = visitor.values;
		var keyExpRefs = [];
		var valueExpRefs = [];
		
		//var internalData = {};
		//var analagousData = {};
		
		var table = new Table();
		if(array_length(keyASTs) == 0)
		{
			return new Reference(table);
		}
		
		for(var i = 0; i < array_length(keyASTs)-1; ++i)
		{
			keyExpRefs[i] = helpPruneExpList(visitExpression(keyASTs[i]));
			valueExpRefs[i] = helpPruneExpList(visitExpression(valueASTs[i]));
		}
		var lastIndex = array_length(keyASTs)-1;
		if(lastIndex == visitor.lastAutoIndex)
		{
			var lastKey = keyASTs[lastIndex].value;
			var lastValueExps = visitExpression(valueASTs[lastIndex])	
			if(typeof(lastValueExps) != "array")
			{
				lastValueExps = [lastValueExps];
			}
			for(var i = 0; i < array_length(lastValueExps); ++i)
			{
				var keyExpression = new simpleValue(lastKey+i);
				var valueExpression = lastValueExps[i].getValue();
				table.setValue(keyExpression,valueExpression);
			}
		}
		else
		{
			var lastKeyRef = helpPruneExpList(visitExpression(keyASTs[lastIndex]))
			var lastValueRef = helpPruneExpList(visitExpression(valueASTs[lastIndex]))
			table.setValue(lastKeyRef.getValue(), lastValueRef.getValue())
		}
		
		for(var i = 0; i < array_length(keyExpRefs); ++i)
		{
			var key = keyExpRefs[i].getValue();
			var valueExp = valueExpRefs[i].getValue();
			table.setValue(key,valueExp);
		}
		return new Reference(table);

	}
	
	visitUniop = function(visitor)
	{
		var firstValue = visitExpression(visitor.first);
		var firstValueExp = (helpPruneExpList(firstValue)).getValue();
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
					/*if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}*/
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
					/*if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}*/
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
					/*if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}*/
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
					/*if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}*/
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
					/*if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}*/
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
					/*if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}*/
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
					retExp = new simpleValue(power(real(exp1Val), real(exp2Val)));
				}
				if(retExp == noone)
				{
					retExp = callMetamethod(op, exp1, exp2);
					/*if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}*/
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
					/*if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}*/
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
					/*if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}*/
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
					/*if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}*/
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
					/*if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}*/
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
					/*if(retExp == noone)
					{
						MetamethodFailureException(op, exp1, exp2);
					}*/
				}
				return retExp;
			}
			break;
			//Relational Operators
			case "==":
			{
				var retExp = noone;

				var isExp1Num = (exp1.type == LuaTypes.INTEGER) || (exp1.type == LuaTypes.FLOAT);
				var isExp2Num = (exp2.type == LuaTypes.INTEGER) || (exp2.type == LuaTypes.FLOAT);
				if((exp1.type != exp2.type) && (!isExp1Num || !isExp2Num))
				{
					retExp = new simpleValue(false);	
				}
				else
				{
					if(exp1.type == LuaTypes.TABLE && exp2.type == LuaTypes.TABLE)
					{
						retExp = new simpleValue(exp1 == exp2);
						if(!retExp.val)
						{
							retExp = callMetamethod(op, exp1,exp2);
						}
						if(retExp.val == undefined)
						{
							retExp = new simpleValue(false);
						}
					}
					else if(exp1.type == LuaTypes.FUNCTION)
					{
						retExp = new simpleValue(exp1 == exp2);
					}
					else
					{
						retExp = new simpleValue(exp1.val == exp2.val);
					}
				}
				/*if(retExp == noone)
				{
					MetamethodFailureException(op, exp1, exp2);
				}*/
				if(negateFinal)
				{
					retExp.val = !retExp.val;
				}
				return retExp;
			}
			break;
			case "<":
			{
				var retExp = noone;
				var isExp1Num = (exp1.type == LuaTypes.INTEGER) || (exp1.type == LuaTypes.FLOAT);
				var isExp2Num = (exp2.type == LuaTypes.INTEGER) || (exp2.type == LuaTypes.FLOAT);
				if(isExp1Num && isExp1Num)
				{
					return new simpleValue(exp1Val < exp2Val);
				}
				retExp = callMetamethod(op,exp1,exp2);
				/*if(retExp == noone)
				{
					MetamethodFailureException(op, exp1, exp2);
				}*/
				return retExp;
			}
			break;
			case "<=":
			{
				var retExp = noone;
				var isExp1Num = (exp1.type == LuaTypes.INTEGER) || (exp1.type == LuaTypes.FLOAT);
				var isExp2Num = (exp2.type == LuaTypes.INTEGER) || (exp2.type == LuaTypes.FLOAT);
				if(isExp1Num && isExp1Num)
				{
					return new simpleValue(exp1Val <= exp2Val);
				}
				retExp = callMetamethod(op,exp1,exp2);
				/*if(retExp == noone)
				{
					MetamethodFailureException(op, exp1, exp2);
				}*/
				return retExp;
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
				var retExp = noone;
				var isExp1Stringable = (exp1.type == LuaTypes.INTEGER) || (exp1.type == LuaTypes.FLOAT) || (exp1.type == LuaTypes.STRING);
				var isExp2Stringable = (exp2.type == LuaTypes.INTEGER) || (exp2.type == LuaTypes.FLOAT) || (exp2.type == LuaTypes.STRING);
				if(isExp1Stringable && isExp2Stringable)
				{
					exp1Val = string(exp1Val);
					exp2Val = string(exp2Val);
					return new simpleValue(exp1Val + exp2Val)
				}
				else
				{
					retExp = callMetamethod(op,exp1,exp2);
				}
				/*if(retExp == noone)
				{
					MetamethodFailureException(op, exp1, exp2);
				}*/
				return retExp;
			}
			break;
			//Length
			case "#":
			{
				var retExp = noone;
				if(exp1.type == LuaTypes.STRING)
				{
					return new simpleValue(string_length(exp1Val))
				}
				else if (exp1.type == LuaTypes.TABLE)
				{
					if(exp1.metatable != noone)
					{
						retExp = callMetamethod(op,exp1,exp2);
					}
					retExp = new simpleValue(variable_struct_names_count(exp1Val))	
				}

				
				/*if(retExp == noone)
				{
					MetamethodFailureException(op, exp1, exp2);
				}*/
				return retExp;
			}
			break;
		}
		InterpreterException("This statement should be impossible to reach, check the preceding switch statement");
	}
	
	//This must return an expression
	callMetamethod = function(op, exp1, exp2 = noone, exp3 = noone)
	{
		static opToMetaIndexFactory = function()
		{
			var opToMetaValue = {}
			opToMetaValue[$"+"] = "__add";
			opToMetaValue[$"-"] = ["__sub","__unm"];
			opToMetaValue[$"*"] = "__mul";
			opToMetaValue[$"/"] = "__div";
			opToMetaValue[$"%"] = "__mod";
			opToMetaValue[$"^"] = "__pow";
			opToMetaValue[$"//"] = "__idiv";
			opToMetaValue[$"&"] = "__band";
			opToMetaValue[$"|"] = "__bor";
			opToMetaValue[$"~"] = ["__bxor","__bnot"];
			opToMetaValue[$"<<"] = "__shl";
			opToMetaValue[$">>"] = "__shr";
			opToMetaValue[$".."] = "__concat";
			opToMetaValue[$"#"] = "__len";
			opToMetaValue[$"=="] = "__eq";
			opToMetaValue[$"<"] = "__lt";
			opToMetaValue[$"<="] = "__le";
			opToMetaValue[$"[]"] = "__index";
			opToMetaValue[$"=[]"] = "__newindex";
			opToMetaValue[$"()"] = "__call";
			return opToMetaValue;
		};
		static opToMetaIndex = opToMetaIndexFactory();
		static MetamethodFailureException = function(op,exp1,exp2)
		{
			InterpreterException("Failed to find an appropriate metamethod for " + string(exp1) + " and " + string(exp2) +"\nUnder the operator: " + op);
		}
		//throw("Incomplete feature, the use of metamethods (currently) is disallowed")
		switch(op)
		{
			case "[]":
			{
				if(exp1.metatable == noone)
				{
					MetamethodFailureException(op,exp1,exp2)
				}
				var metaIndexExp = new simpleValue(opToMetaIndex[$op]);
				var metaValue = exp1.metatable.getValue(metaIndexExp);
				
				var retExpRef = noone;
				
				currentScope = new Scope(currentScope)
				currentScope.setLocalVariable("0_table",metaValue);
				currentScope.setLocalVariable("0_originalTable",exp1);
				currentScope.setLocalVariable("0_key",exp2);
				if(metaValue.type == LuaTypes.TABLE)
				{
					var ASTtable = new ASTAccess("0_table");
					var ASTkey = new ASTAccess("0_key")
					
					retExpRef = visitAccess(new ASTAccess(ASTtable,ASTkey));
				}
				else if(metaValue.type == LuaTypes.FUNCTION ||
				metaValue.type == LuaTypes.GMFUNCTION)
				{
					var ASTtable = new ASTAccess("0_table");
					var ASToriginalTable = new ASTAccess("0_originalTable");
					var ASTkey = new ASTAccess("0_key");
					
					retExpRef = visitFunctionCall(
					new ASTFunctionCall(ASTtable,[ASToriginalTable,ASTkey]))
				}
				else
				{
					MetamethodFailureException(op,exp1,exp2)
				}
				currentScope = currentScope.parent
				return retExpRef.getValue();
			}
			break;
			case "=[]":
			{
				if(exp1.metatable == noone)
				{
					MetamethodFailureException(op,exp1,exp2)
				}
				var metaIndexExp = new simpleValue(opToMetaIndex[$op]);
				var metaValue = exp1.metatable.getValue(metaIndexExp);
				
				var retExpRef = noone;
				currentScope = new Scope(currentScope)
				currentScope.setLocalVariable("0_table",metaValue);
				currentScope.setLocalVariable("0_originalTable",exp1);
				currentScope.setLocalVariable("0_key",exp2);
				currentScope.setLocalVariable("0_newVal",exp3);
				if(metaValue.type == LuaTypes.TABLE)
				{
					var ASTtable = new ASTAccess("0_table");
					var ASTKey = new ASTAccess("0_key");
					
					var ASTLeftSide = new ASTAccess(ASTtable, ASTKey)
					var ASTRightSide = new ASTAccess("0_newVal");
					
					visitStatement(new ASTAssignment([ASTLeftSide],[ASTRightSide]))
				}
				else if(metaValue.type == LuaTypes.FUNCTION ||
				metaValue.type == LuaTypes.GMFUNCTION)
				{
					var ASTarg1 = new ASTAccess("0_originalTable");
					var ASTarg2 = new ASTAccess("0_key");
					var ASTarg3 = new ASTAccess("0_newVal");
					
					var ASTfunc = new ASTAccess("0_table");
					visitStatement(new ASTFunctionCall(ASTfunc,
					[ASTarg1,ASTarg2,ASTarg3]));
				}
				else
				{
					MetamethodFailureException(op,exp1,exp2)
				}
				currentScope = currentScope.parent;
				return noone;
			}
			break;
			case "()":
			{
				if(exp1.metatable == noone)
				{
					MetamethodFailureException(op,exp1,exp2)
				}
				var metaIndexExp = new simpleValue(opToMetaIndex[$op]);
				var metaValue = exp1.metatable.getValue(metaIndexExp);
				
				currentScope = new Scope(currentScope)
				var allArgExps =  helpPruneExpList([exp1,exp2],-1);
				currentScope.setLocalVariable("0_func",metaValue);
				//currentScope.setLocalVariable("0_originalTable",exp1);
				currentScope.setLocalVariable("0_argExps",new ExpressionList(allArgExps,false));
				var retVal = new simpleValue(undefined);
				if(metaValue.type == LuaTypes.FUNCTION ||
				metaValue.type == LuaTypes.GMFUNCTION)
				{
					var ASTfunc = new ASTAccess("0_func");
					var ASTArgs = new ASTAccess("0_argExps");
					//TODO: Args need to be spread out as individual vals
					retVal = visitExpression(new ASTFunctionCall(ASTfunc,[ASTArgs]));
				}
				else
				{
					MetamethodFailureException(op,exp1,exp2)
				}
				currentScope = currentScope.parent;
				return retVal
			}
			break;

			default:
			{
				var metaIndex = opToMetaIndex[$op];
				var isBinary = (exp2 != noone);
				if(op == "-")
				{
					if(isBinary)
					{
						metaIndex = metaIndex[0]
					}
					else
					{
						metaIndex = metaIndex[1]
					}
				}
				else if(op == "~")
				{
					if(isBinary)
					{
						metaIndex = metaIndex[0]
					}
					else
					{
						metaIndex = metaIndex[1]
					}
				}
				var metaIndexExp = new simpleValue(metaIndex);
				var metaValue = noone;
				var tableWithMetatable = noone;
				if(isBinary)
				{
					if(exp1.type == LuaTypes.TABLE && exp1.metatable != noone)
					{
						tableWithMetatable = exp1;
					}
					else if(exp2.type == LuaTypes.TABLE && exp2.metatable != noone)
					{
						tableWithMetatable = exp2;
					}
				}
				else
				{
					if(exp1.type == LuaTypes.TABLE && exp1.metatable != noone)
					{
						tableWithMetatable = exp1;
					}
				}
				if(tableWithMetatable == noone)
				{
					MetamethodFailureException(op,exp1,exp2);
				}
				metaValue = tableWithMetatable.metatable.getValue(metaIndexExp);
				if(metaValue.type != LuaTypes.FUNCTION &&
				metaValue.type != LuaTypes.GMFUNCTION && metaValue.type != LuaTypes.TABLE)
				{
					MetamethodFailureException(op,exp1,exp2);
				}
				currentScope = new Scope(currentScope);
				currentScope.setLocalVariable("0_exp1",exp1);
				currentScope.setLocalVariable("0_exp2",exp2);
				currentScope.setLocalVariable("0_func", metaValue);
				var ASTArgs = [new ASTAccess("0_exp1")];
				if(isBinary)
				{
					array_push(ASTArgs,new ASTAccess("0_exp2"));
				}
				var ASTfuncExp = new ASTFunctionCall(new ASTAccess("0_func"),
				ASTArgs);
				var result = helpPruneExpList(visitExpression(ASTfuncExp));
				currentScope = currentScope.parent;
				if(op == "==" || op == "<" || op == "<=")
				{
					if(isExpressionFalsy(result))
					{
						return new simpleValue(false)
					}
					return new simpleValue(true)
				}
				return result.getValue();
			}
			break;
		}
		InterpreterException("This statement should be impossible to reach, check the preceding switch statement");
	}
	
}
}