// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

//This is a singleton as only one Parser is needed at any time
//When another tokenList must be parsed, a function is provided to do so
global.parser = {}
with(global.parser)
{
	operatorPrecedence = [];
	operatorPrecedence[11] = ["^"];
	operatorPrecedence[10] = ["not","#","-","~"];
	operatorPrecedence[9] = ["*","/","//","%"];
	operatorPrecedence[8] = ["+","-"];
	operatorPrecedence[7] = [".."];
	operatorPrecedence[6] = ["<<",">>"];
	operatorPrecedence[5] = ["&"];
	operatorPrecedence[4] = ["~"];
	operatorPrecedence[3] = ["|"];
	operatorPrecedence[2] = ["<",">","<=",">=","~=","=="];
	operatorPrecedence[1] = ["and"];
	operatorPrecedence[0] = ["or"];
	//scopeDepth = 0;
	function parseChunk(tokens,sourceFilePath, sourceFileName)
	{
		self.tokens = new TokenStream(tokens);
		//self.goto = {};
		var chunk = new ASTChunk(parseBlock(),sourceFilePath,sourceFileName);

		//logString = string(chunk)
		return chunk;
	}
	parseBlock = function()
	{
		var statements = [];
		var gotoIndices = {};
		//scopeDepth++;
		while(!peek(["end","until","elseif","else"]) && tokens.has(0))
		{
			var newAST = undefined;
			var curLine = tokens.get(0).line;
			while(match(";"))
			{}
			
			if(peek(Token.IDENTIFIER))
			{
				var curIndex = tokens.index;

				try
				{
					newAST = parseFunctionCall();
				}
				catch(e)
				{
					
					setIndex(curIndex);
					var varList = parseVarList();
					if(!match("="))
					{
						ParserException("Assignment missing \"=\"",tokens.get(-1).line);
					}
					var expList = parseExpressionList();
					
					newAST = new ASTAssignment(varList,expList);
				}

			}
			else if(peek("::"))
			{
				newAST = parseLabel();
			}
			else if(peek("break"))
			{
				newAST = parseBreakStatement();
			}
			else if(peek("goto"))
			{
				newAST = parseGotoStatement();
			}
			else if(peek("do"))
			{
				newAST = parseDoStatement();
			}
			else if(peek("while"))
			{
				newAST = parseWhileStatement();	
			}
			else if(peek("repeat"))
			{
				newAST = parseRepeatStatement();
			}
			else if(peek("if"))
			{
				newAST = parseIfStatement();	
			}
			else if(peek("for"))
			{
				newAST = parseForStatement();
			}
			else if(peek("function"))
			{
				newAST = parseFunctionDeclaration();
			}
			else if(peek("local"))
			{
				newAST = parseLocalDeclaration();
			}
			else if(peek("return"))
			{
				newAST = parseReturnStatement();
			}
			if(is_undefined(newAST))
			{
				//show_debug_message(statements);
				ParserException(string(tokens.get(0)) + "is not a start of a statement",tokens.get(0).line)
			}
			if(newAST.astType == AST.STATEMENT && newAST.statementType == Statement.LABEL)
			{
				var labelName = newAST.name;
				if(!variable_struct_exists(gotoIndices,labelName))
				{
					variable_struct_set(gotoIndices,labelName,array_length(statements));
				}
				else
				{
					ParserException("Duplicate label name in the same block: " + labelName,tokens.get(-1).line)
				}
			}
			else
			{
				newAST.firstLine = curLine;
				array_push(statements,newAST);
			}
			while(match(";"))
			{}
		}
		var newBlock = new ASTBlock(statements,gotoIndices);
		newBlock.firstLine = -1;
		if(array_length(statements) > 0)
		{
			newBlock.firstLine = statements[0].firstLine;
			newBlock.lastLine = statements[array_length(statements) - 1].firstLine;
		}
		return newBlock
	}
	
	parseLabel = function()
	{
		if(!match("::"))
		{
			ParserException("Parser issue, check parseLabel function in Parser",-1);	
		}
		
		if(!peek(Token.IDENTIFIER))
		{
			ParserException("Label missing Identifier",tokens.get(-1).line);
		}
		var labelName = tokens.get(0).literal;
		tokens.advance();
		
		if(!match("::"))
		{
			ParserException("Unterminated Label",tokens.get(-1).line);	
		}
		return new ASTLabel(labelName);
	}
	
	parseBreakStatement = function()
	{
		if(!match("break"))
		{
			ParserException("Parser issue, check parseBreakStatement function in Parser",-1);	
		}
		return new ASTBreak();
	}
	
	parseGotoStatement = function()
	{
		if(!match("goto"))
		{
			ParserException("Parser issue, check parseGotoStatement function in Parser",-1);	
		}
		if(!peek(Token.IDENTIFIER))
		{
			ParserException("Goto statement missing Identifier",tokens.get(-1).line);
		}
		var labelName = tokens.get(0).literal;
		tokens.advance();
		return new ASTGoto(labelName);
	}
	
	parseDoStatement = function()
	{
		var statements = helpParseDoStatement();
		return new ASTDo(statements);
	}
	
	helpParseDoStatement = function()
	{
		if(!match("do"))
		{
			ParserException("Missing \"do\"",tokens.get(-1).line);	
		}
		var statements = parseBlock();
		if(!match("end"))
		{
			ParserException("Missing \"end\"",tokens.get(-1).line);	
		}		
		return statements;
	}
	
	parseWhileStatement = function()
	{
		if(!match("while"))
		{
			ParserException("Parser issue, check parseWhileStatement function in Parser",-1);	
		}
		var condition = parseExpression();
		var statements = helpParseDoStatement();
		return new ASTWhile(condition,statements);
	}
	
	parseRepeatStatement = function()
	{
		if(!match("repeat"))
		{
			ParserException("Parser issue, check parseWhileStatement function in Parser",-1);	
		}
		var statements = parseBlock();
		if(!match("until"))
		{
			ParserException("Missing \"until\" from repeat statement",tokens.get(-1).line);	
		}
		var condition = parseExpression();
		return new ASTRepeat(condition,statements)
	}
	
	parseIfStatement = function()
	{
		var conditions = [];
		var blocks = [];
		if(!match("if"))
		{
			ParserException("Parser issue, check parseIfStatement function in Parser",-1);	
		}
		array_push(conditions,parseExpression());
		if(!match("then"))
		{
			ParserException("Missing \"then\" from if statement",tokens.get(-1).line);	
		}
		array_push(blocks,parseBlock());
		
		while(match("elseif"))
		{
			array_push(conditions,parseExpression());
			if(!match("then"))
			{
				ParserException("Missing \"then\" from if statement",tokens.get(-1).line);	
			}
			array_push(blocks,parseBlock());
		}
		
		if(match("else"))
		{
			array_push(blocks,parseBlock());
		}
		
		if(!match("end"))
		{
			ParserException("Missing \"end\" from if statement",tokens.get(-1).line);	
		}
		return new ASTIf(conditions,blocks);
	}
	
	parseForStatement = function()
	{
		if(!match("for"))
		{
			ParserException("Parser issue, check parseForStatement function in Parser",-1);	
		}
		if(!match(Token.IDENTIFIER))
		{
			ParserException("For statement is missing an identifier",tokens.get(-1).line);	
		}
		if(match("="))
		{
			var initalName = tokens.get(-2).literal;
			var inital = parseExpression();
			if(!match(","))
			{
				ParserException("For statement is missing \",\"",tokens.get(-1).line);	
			}
			var limit = parseExpression();
			var step = new ASTLiteral(1);
			if(match(","))
			{
				step = parseExpression();
			}
			var block = helpParseDoStatement();
			return new ASTNumericFor(initalName,inital,limit,step,block);
		}
		else
		{
			var nameList = [];
			var expList = [];
			tokens.index -= 1;
			if(!peek(Token.IDENTIFIER))
			{
				ParserException("For statement is missing an identifier",tokens.get(-1).line);
			}
			
			array_push(nameList,tokens.get(0).literal);
			tokens.advance();
			while(match(","))
			{
				array_push(nameList,tokens.get(0).literal);
				tokens.advance();
			}
			
			if(!match("in"))
			{
				ParserException("For statement is missing \"in\"",tokens.get(-1).line);	
			}
			
			expList = parseExpressionList();
			
			var statements = helpParseDoStatement();
			
			return new ASTGenericFor(nameList,expList,statements);
		}
		ParserException("Parser issue, check parseForStatement function in Parser",-1);	
	}
	
	parseFunctionDeclaration = function()
	{
		var name = [];
		if(!match("function"))
		{
			ParserException("Parser issue, check parseFunctionDeclaration function in Parser",-1);	
		}
		if(!peek(Token.IDENTIFIER))
		{
			ParserException("Missing identifier for function declaration",tokens.get(-1).line);	
		}
		array_push(name,tokens.get(0).literal);
		tokens.advance();
		while(match("."))
		{
			if(!peek(Token.IDENTIFIER))
			{
				ParserException("Missing identifier for function declaration",tokens.get(-1).line);	
			}
			array_push(name,tokens.get(0).literal);
			tokens.advance();
		}
		var isMethod = false;
		if(match(":"))
		{
			array_push(name,tokens.get(0).literal);
			tokens.advance();
			isMethod = true;
		}
		
		if(array_length(name) == 1)
		{
			name = new ASTAccess(name[0]);
		}
		else
		{
			var cur = new ASTLiteral(name[array_length(name)-1]);
			for(var i = array_length(name)-2; i >= 0 ; --i)
			{
				cur = new ASTAccess(name[i],cur);
			}
			name = cur;
		}
		
		var body = [];
		if(isMethod)
		{
			array_push(body, parseFunctionBody(["self"]));
		}
		else
		{
			array_push(body , parseFunctionBody());	
		}

		return new ASTAssignment([name],body);
	}
	
	parseFunctionBody = function(parameters = [])
	{
		var varargs = false;
		if(!match("("))
		{
			ParserException("Missing \"(\" for function body",tokens.get(-1).line);	
		}
		if(match("..."))
		{
			varargs = true;
		}
		else
		{
			if(!peek(")"))
			{
				if(!peek(Token.IDENTIFIER))
				{
					ParserException("Missing identifier for function body",tokens.get(-1).line);	
				}
				array_push(parameters,tokens.get(0).literal);
				tokens.advance();
				while(match(","))
				{
					if(!peek(Token.IDENTIFIER))
					{
						ParserException("Missing identifier for function body",tokens.get(-1).line);	
					}
					array_push(parameters,tokens.get(0).literal);
					tokens.advance();
				}
				if(match("..."))
				{
					varargs = true;
				}
			}
		}
		
		if(!match(")"))
		{
			ParserException("Missing \")\" for function body",tokens.get(-1).line);	
		}
		var block = parseBlock();
		if(!match("end"))
		{
			ParserException("Missing \"end\" for function body",tokens.get(-1).line);	
		}
		return new ASTFunctionBody(parameters,varargs,block);
	}
	
	parseLocalDeclaration = function()
	{
		match("local");
		if(match("function"))
		{		
			if(!peek(Token.IDENTIFIER))
			{
				ParserException("Missing identifier for local function declaration",tokens.get(-1).line);	
			}
			var name = [];
			array_push(name,new ASTAccess(tokens.get(0).literal));
			tokens.advance();
			var body = [];
			array_push(body,parseFunctionBody());	
			return new ASTDeclaration(name,[noone],body);
		}
		else
		{
			var names = [];
			var attributes = [];
			var expressions = [];
			if(!peek(Token.IDENTIFIER))
			{
				ParserException("Missing identifier for local variable declaration",tokens.get(-1).line);	
			}
			array_push(names, tokens.get(0).literal);
			tokens.advance();
			if(match("<"))
			{
				if(!peek(["const","close"]))
				{
					ParserException("Missing attribute for local variable declaration",tokens.get(-1).line);	
				}
				array_push(attributes,tokens.get(0).literal);
				tokens.advance();
				if(!match(">"))
				{
					ParserException("Missing \">\" for variable attribute declaration",tokens.get(-1).line);	
				}
			}
			else
			{
				array_push(attributes,noone);
			}
			while(match(","))
			{
				var curName = noone;
				var curAttribute = noone;
				if(!peek(Token.IDENTIFIER))
				{
					ParserException("Missing identifier for local variable declaration",tokens.get(-1).line);	
				}
				curName = tokens.get(0).literal;
				tokens.advance();
				if(match("<"))
				{
					if(!peek(["const","close"]))
					{
						ParserException("Missing attribute for local variable declaration",tokens.get(-1).line);	
					}
					curAttribute = tokens.get(0).literal;
					tokens.advance();
					if(!match(">"))
					{
						ParserException("Missing \">\" for variable declaration",tokens.get(-1).line);	
					}
				}
				array_push(names, curName);
				array_push(attributes,curAttribute);
			}
			if(!match("="))
			{
				ParserException("Missing \"=\" for variable declaration",tokens.get(-1).line);	
			}
			expressions = parseExpressionList();
			var ASTnames = [];
			for(var i = 0; i < array_length(names); ++i)
			{
				var curAST = new ASTAccess(names[i]);
				array_push(ASTnames,curAST);
			}
			return new ASTDeclaration(ASTnames,attributes,expressions);
		}		
	}
	
	parseReturnStatement = function()
	{
		if(!match("return"))
		{
			ParserException("Parser issue, check parseReturnStatement function in Parser",-1);	
		}
		var curIndex = tokens.index;
		var expressions = [];
		try
		{
			expressions = parseExpressionList();
		}
		catch(e)
		{
			setIndex(curIndex);
			expressions = [];
		}
		match(";");
		return new ASTReturn(expressions);
	}
	
	parseExpressionList = function(statements = [])
	{
		array_push(statements,parseExpression());
		while(match(","))
		{
			array_push(statements,parseExpression());
		}
		return statements;	
	}
	
	parseExpression = function()
	{
		return parseExpressionTerm(0)
	}
	// Level 0 is lowest priority, 11 is highest
	parseExpressionTerm = function(level)
	{
		if(level > 11)
		{
			return parsePrimaryExpression();	
		}
		if(level == 10)
		{
			var operator = noone;
			if(peek(operatorPrecedence[level])&& peek(Token.OPERATOR))
			{
				operator= tokens.get(0).literal;
				tokens.advance();
			}
			var first = parseExpressionTerm(level+1);
			if(operator == noone)
			{
				return first;	
			}
			return new ASTUniop(operator,first);	
		}
		var first = parseExpressionTerm(level+1);
		if(peek(operatorPrecedence[level])&& peek(Token.OPERATOR))
		{
			var operator = tokens.get(0).literal;
			tokens.advance();
			var second = parseExpressionTerm(level+1);
			var firstSide;

			firstSide = new ASTBinop(operator,first,second);
			
			first = helpParseExpressionTerm(firstSide,level);
		}
		return first;
	}
	//Deals with repeats binary operations
	helpParseExpressionTerm = function(firstSide,level)
	{
		if(level < 0)
		{
			return parsePrimaryExpression();	
		}

		while(peek(operatorPrecedence[level])&& peek(Token.OPERATOR))
		{
			var operator = tokens.get(0).literal;
			tokens.advance();
			// Operators at level 11 and 7 are right-associative.
			// All other operators are left-associative
			var second = parseExpressionTerm(level+1);
			if(level == 11 || level == 7)
			{
				firstSide.second = new ASTBinop(operator,firstSide.second,second);
				//return firstSide
			}
			else
			{
				firstSide = new ASTBinop(operator,firstSide,second);
			}
		}
		return firstSide;
	}
	
	parsePrimaryExpression = function()
	{
		if(match("nil"))
		{
			return new ASTLiteral(undefined);
		}
		else if(match("true"))
		{
			return new ASTLiteral(true);
		}
		else if(match("false"))
		{
			return new ASTLiteral(false);
		}
		else if(match(Token.INTEGER))
		{
			return new ASTLiteral(int64(real(tokens.get(-1).literal)));
		}
		else if(match(Token.FLOAT))
		{
			var strVal = tokens.get(-1).literal;
			var isBaseTen = true;
			var val;
			if(string_pos("0x",strVal) != 0 || string_pos("0X",strVal) != 0)
			{
				isBaseTen = false;
				strVal = string_copy(strVal,3,string_length(strVal)-2);
			}
			if(isBaseTen)
			{
				var ePos = string_pos("e",strVal);
				if(ePos == 0)
				{
					ePos = string_pos("E",strVal);
				}
				
				if(ePos != 0)
				{
					var base = real(string_copy(strVal,1,ePos-1));
					var exponent = int64(string_copy(strVal,ePos+1,(string_length(strVal) - ePos)));
					
					if(exponent < 0)
					{
						exponent *= -1;
						val = base * power(0.1,exponent);
					}
					else
					{
						val = base * power(10,exponent);
					}
					
				}
				else
				{
					val = real(strVal);
				}
			}
			else
			{
				var pPos = string_pos("p",strVal);
				if(pPos == 0)
				{
					pPos = string_pos("P",strVal);
				}
				
				if(pPos != 0)
				{
					var base = real(string_copy(strVal,1,pPos-1));
					var exponent = int64(string_copy(strVal,pPos+1,(string_length(strVal) - pPos)));
					
					if(exponent < 0)
					{
						base = 1/base;	
						exponent *= -1;
					}
					
					if(exponent < 0)
					{
						exponent *= -1;
						val = base * power(0.5,exponent);
					}
					else
					{
						val = base * power(2,exponent);
					}
				}
				else
				{
					val = real("0x" + strVal);	
				}
			}
			return new ASTLiteral(val);
		}
		else if(match(Token.STRING))
		{
			var val = tokens.get(-1).literal;
			
			return new ASTLiteral(val);
		}
		else if(match("function"))
		{
			return parseFunctionBody();
		}
		else if(match("..."))
		{
			return new ASTAccess("...");
		}
		else if(peek("{"))
		{
			return parseTableConstructor();	
		}
		else
		{
			return parsePrefixExpression();
		}
		
	}
	
	parsePrefixExpression = function(prefix = noone)
	{
		if(prefix == noone)
		{
			if(match("("))
			{
				var group = parseExpression();
				if(!match(")"))
				{
					ParserException("Missing \")\" for prefixExpression",tokens.get(-1).line);	
				}
				return parsePrefixExpression(new ASTGroup(group));
			}
			else if(match(Token.IDENTIFIER))
			{
				var name = tokens.get(-1).literal;
				return parsePrefixExpression(new ASTAccess(name));
			}
			
		}
		else
		{
			if(peek(["(","{",":",Token.STRING]))
			{
				return parsePrefixExpression(parseFunctionCall(prefix));
			}
			else if(match("["))
			{
				var expression =  parseExpression();
				if(!match("]"))
				{
					ParserException("Missing \"]\" for prefixExpression",tokens.get(-1).line);	
				}
				return parsePrefixExpression(new ASTAccess(prefix,expression));
			}
			else if(match("."))
			{
				if(!match(Token.IDENTIFIER))
				{
					ParserException("Missing Identifier for prefixExpression",tokens.get(-1).line);
				}
				var name = tokens.get(-1).literal;
				return parsePrefixExpression(new ASTAccess(prefix,new ASTLiteral(name)));
			}
			return prefix;
		}
		ParserException(string(tokens.get(-1)) + " was unexpected",tokens.get(-1).line);
	}
	
	parseFunctionCall = function(prefix = noone)
	{
		//show_debug_message("functioncall");
		var prefixIsCall = false;
		if(prefix == noone)
		{
			prefix = parsePrefixExpression();
		}
		var curIndex = tokens.index;
		if(prefix.expressionType == Expression.FUNCTIONCALL)
		{
			prefixIsCall = true;
		}
		try
		{
			var args = [];
			var finalIndex = noone;
			if(match(":"))
			{
				var name;
				if(match(Token.IDENTIFIER))
				{
					name = tokens.get(-1).literal;
				}
				else
				{
					ParserException("Function call missing Identifier" ,tokens.get(-1).line);
				}
				finalIndex = new ASTLiteral(name);
			}
			if(match("("))
			{
				if(!peek(")"))
				{
					args = parseExpressionList(args);
				}
				if(!match(")"))
				{
					ParserException("Function call missing \")\"",tokens.get(-1).line);
				}
			}
			else if(peek("{"))
			{
				args = [parseTableConstructor()];	
			}
			else if(match(Token.STRING))
			{
				val = tokens.get(-1).literal;
				args = [new ASTLiteral(val)];
			}
			else
			{
				ParserException("Function call missing arguments",tokens.get(-1).line);
			}
			return new ASTFunctionCall(prefix,args,finalIndex);
		}
		catch(e)
		{
			if(!prefixIsCall)
			{
				throw(e);
			}
			setIndex(curIndex);	
			return prefix;
		}
	}
	
	parseVar = function()
	{
		var varRs = parsePrefixExpression();
		if(varRs.expressionType != Expression.ACCESS)
		{
			ParserException(string(varRs)+", This Expression is not a Var",tokens.get(-1).line);
		}
		return varRs;
	}
	
	parseVarList = function()
	{
		var list = [parseVar()];
		while(match(","))
		{
			array_push(list,parseVar());
		}
		return list;
	}
	
	parseTableConstructor = function()
	{
		var keys = [];
		var values = [];
		if(!match("{"))
		{
			ParserException("Parser Issue, please check parseTableConstructor function",tokens.get(-1).line);
		}
		if(!peek("}"))
		{
			var index = 1;
			var exp1;
			var exp2;
			if(match("["))
			{
				exp1 = parseExpression();
				if(!match("]"))
				{
					ParserException("Missing \"]\" for field",tokens.get(-1).line);	
				}
			}
			else if(peek(Token.IDENTIFIER) && peek("=",1))
			{
				exp1 = tokens.get(0).literal;
				tokens.advance();
			}
			else
			{
				exp1 = parseExpression();
			}
			
			if(match("="))
			{
				exp2 = parseExpression();
				array_push(keys, exp1);
				array_push(values, exp2);
			}
			else
			{
				array_push(keys, new ASTLiteral(index));
				array_push(values, exp1);
				index++;
			}
			if(peek([",",";"]) && peek("}",1))
			{
				tokens.advance(2);
				return new ASTTable(keys,values);
			}
			while(match([",",";"]))
			{
				if(match("["))
				{
					exp1 = parseExpression();
					if(!match("]"))
					{
						ParserException("Missing \"]\" for field",tokens.get(-1).line);	
					}
				}
				else if(peek(Token.IDENTIFIER) && peek("=",1))
				{
					exp1 = tokens.get(0).literal;
					tokens.advance();
				}
				else
				{
					exp1 = parseExpression();
				}
			
				if(match("="))
				{
					exp2 = parseExpression();
					array_push(keys, exp1);
					array_push(values, exp2);
				}
				else
				{
					array_push(keys, new ASTLiteral(index));
					array_push(values, exp1);
					index++;
				}
			}
		}
		match([",",";"]);
		
		if(!match("}"))
		{
			//show_debug_message(tokens.get(0))
			ParserException("Missing \"}\" for table constructor",tokens.get(-1).line);	
		}
		return new ASTTable(keys,values);
	}
	
	setIndex = function(index)
	{
		tokens.index = index;	
	}
	peek = function(pattern,offset = 0)
	{
		if(!tokens.has(offset))
		{
			return false;
		}
		var curToken = tokens.get(offset);
		if(typeof(pattern) != "array")
		{
			if(typeof(pattern) == "string")
			{
				return (curToken.literal == pattern)
			}
			else if(typeof(pattern) == "int64")
			{
				return (curToken.type = pattern);
			}
		}
		
		for(var i = 0; i < array_length(pattern); ++i)
		{
			var p = pattern[i];
			if(typeof(p) == "string")
			{
				if(curToken.literal == p)
				{
					return true;	
				}
			}
			else if(typeof(p) == "int64")
			{
				if(curToken.type == p)
				{
					return true;	
				}
			}
		}
		return false;
	}
	match = function(pattern, offset = 0)
	{
		if(peek(pattern,offset))
		{
			tokens.advance();
			return true;
		}
		return false;
	}
	function createChunkBlock(chunk)
	{
		var appendStr = chunk.sourceFilePath+chunk.sourceFileName + "\n";
		appendStr+= createLog(0,chunk.block)
		return appendStr;
	}
	createLog = function(level,block)
	{
		var appendString = "\n";
		var ws = "";
		for(var i = 0; i < level; ++i)
		{
			ws += "    ";
		}
		if(array_length(block.statements) == 0)
		{
			return "";	
		}
		for(var i = 0; i < array_length(block.statements);++i)
		{
			var curStatement = block.statements[i];
			//show_debug_message(curStatement)
			if(curStatement.astType == AST.EXPRESSION &&
			curStatement.expressionType == Expression.FUNCTIONCALL)
			{
				appendString += ws + "function call: " + string(curStatement) + "\n";
				continue;
			}
			switch(curStatement.statementType)
			{
					
				case Statement.ASSIGNMENT:
					appendString += ws + "names: " + string(curStatement.names) + "\n";
					appendString += ws + "assignedExpressions: [";
					for(var j = 0; j < array_length(curStatement.expressions);++j)
					{
						var curExpression = curStatement.expressions[j];
						//show_debug_message(curExpression.expressionType == Expression.FUNCTIONBODY)
						if(curExpression.expressionType == Expression.FUNCTIONBODY)
						{
							appendString += ws + "paramlist: "+ string(curExpression.paramlist) + ", "+
							"isVarArgs: " + string(curExpression.isVarArgs);
							appendString += self.createLog(level+1,curExpression.block)
						}
						else
						{
							appendString += ws + string(curExpression);
						}
							
						if(j != array_length(curStatement.expressions) - 1)
						{
							appendString += ", ";
						}
					}
					appendString += "]\n";
						
				break;
				case Statement.DECLARATION:
					appendString += ws + "names: " + string(curStatement.names) + ", ";
					appendString += "attributes: " + string(curStatement.attributes) + "\n";
					appendString += ws + "assignedExpressions: [";
					for(var j = 0; j < array_length(curStatement.expressions);++j)
					{
						var curExpression = curStatement.expressions[j];
						//show_debug_message(curExpression.expressionType == Expression.FUNCTIONBODY)
						if(curExpression.expressionType == Expression.FUNCTIONBODY)
						{
							appendString += ws + "paramlist: "+ string(curExpression.paramlist) + 
							", isVarArgs: " + string(curExpression.isVarArgs);
							appendString += ws + self.createLog(level+1,curExpression.block)
						}
						else
						{
							appendString += ws + string(curExpression);
						}
							
						if(j != array_length(curStatement.expressions) - 1)
						{
							appendString += ", ";
						}
					}
					appendString += "]\n";
				break;
				case Statement.DO:
					appendString += self.createLog(level +1, curStatement.block)
				break;
				case Statement.GENERICFOR:
					appendString += ws + "namelist :" + string(curStatement.namelist);
					appendString += " ,"
					appendString += ws + "explist :" string(curStatement.explist);
					appendString += self.createLog(level +1, curStatement.block)
				break;
				case Statement.IF:
					var conditions = curStatement.conditions
					var blocks = curStatement.blocks;
					for(var j = 0; j < array_length(conditions); ++j)
					{
						appendString += "\n" + ws + "condition" + string(j) + " :" + string(conditions[j]);
						appendString += self.createLog(level +1, blocks[j])
					}
					if(array_length(blocks) > array_length(conditions))
					{
						appendString += self.createLog(level +1, blocks[array_length(blocks)-1])
					}
				break;
				case Statement.NUMERICFOR:
					appendString += ws + "initalName :" + curStatement.initalName;
					appendString += " ,"
					appendString += "inital :" +string(curStatement.inital);
					appendString += " ,"
					appendString += "limit :" + string(curStatement.limit);
					appendString += " ,"
					appendString += "step :" + string(curStatement.step);
					appendString += self.createLog(level +1, curStatement.block)
				break;
				case Statement.REPEAT:
					appendString += ws + "condition :" + string(curStatement.condition);
					appendString += self.createLog(level +1, curStatement.block)
				break;
				case Statement.WHILE:
					appendString += ws + "condition :" + string(curStatement.condition);
					appendString += self.createLog(level +1, curStatement.block)
				break;
				default:
					appendString += ws + string(curStatement) + "\n"
				break
			}
		}
		return appendString;
	}
	
}

function TokenStream(tokens) constructor
{
	self.input = tokens;
	index = 0;
	has = function(offset)
	{
		return index + offset < array_length(input);
	};
	get = function(offset)
	{
		return array_get(input,index+offset);
	};
	advance = function(num = 1)
	{
		for(var i = 0; i < num; ++i)
		{
			++index;
		}
		if(!has(-1))
		{
			throw("Reached End Of File");	
		}
	};
}