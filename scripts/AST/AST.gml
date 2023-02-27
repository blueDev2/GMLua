// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
enum AST
{
	CHUNK,
	BLOCK,
	STATEMENT,
	EXPRESSION
}

enum Statement
{
	ASSIGNMENT,
	DECLARATION,
	LABEL,
	BREAK,
	GOTO,
	DO,
	WHILE,
	REPEAT,
	IF,
	GENERICFOR,
	NUMERICFOR,
	RETURN
}

enum Expression
{
	FUNCTIONCALL,
	FUNCTIONBODY,
	LITERAL,
	BINOP,
	UNIOP,
	GROUP,
	ACCESS,
	TABLE
}
function ASTStatement() constructor
{
	firstLine = -1;
	astType = AST.STATEMENT;
}
function ASTExpression() constructor
{
	astType = AST.EXPRESSION;
}
function ASTChunk(globals) constructor
{
	self.globals = globals;
	astType = AST.CHUNK;
}
function ASTBlock(block) constructor
{
	self.statements = block;
	astType = AST.BLOCK
}

function ASTLabel(name) : ASTStatement() constructor
{
	self.name = name;
	statementType = Statement.LABEL;
}

function ASTBreak(): ASTStatement() constructor
{
	//astType = AST.STATEMENT;
	statementType = Statement.BREAK;
}

function ASTGoto(labelName) : ASTStatement() constructor
{
	self.labelName 	= labelName;
	//astType = AST.STATEMENT;
	statementType = Statement.GOTO;
}

function ASTDo(block): ASTStatement() constructor
{
	self.block = block;
	//astType = AST.STATEMENT;
	statementType = Statement.DO;
}

function ASTWhile(condition,block): ASTStatement() constructor
{
	self.condition = condition;
	self.block = block;
	//astType = AST.STATEMENT;
	statementType = Statement.WHILE;
}

function ASTRepeat(condition,block): ASTStatement() constructor
{
	self.condition = condition;
	self.block = block;
	//astType = AST.STATEMENT;
	statementType = Statement.REPEAT;
}

function ASTIf(conditions, blocks): ASTStatement() constructor
{
	self.conditions = conditions;
	self.blocks = blocks;
	//astType = AST.STATEMENT;
	statementType = Statement.IF;
}

function ASTNumericFor(initalName,inital,limit,step,block): ASTStatement() constructor
{
	self.initalName = initalName;
	self.inital = inital;
	self.limit = limit;
	self.step = step;
	self.block = block;
	//astType = AST.STATEMENT;
	statementType = Statement.NUMERICFOR;
}

function ASTGenericFor(namelist,explist,block): ASTStatement() constructor
{
	self.namelist = namelist;
	self.explist = explist;
	self.block = block;
	//astType = AST.STATEMENT;
	statementType = Statement.GENERICFOR;
}

function ASTReturn(expressions): ASTStatement() constructor
{
	self.expressions = expressions;	
	//astType = AST.STATEMENT;
	statementType = Statement.RETURN;
}

function ASTDeclaration(names,attributes, expressions, isLocal): ASTStatement() constructor
{
	self.names = names;
	self.attributes = attributes;
	self.expressions = expressions;
	self.isLocal = isLocal;
	//astType = AST.STATEMENT;
	statementType = Statement.DECLARATION;
}

function ASTAssignment(names,expressions): ASTStatement() constructor
{
	self.names = names;	
	self.expressions = expressions;
	
	statementType = Statement.ASSIGNMENT;

}


function ASTFunctionBody(paramlist, isVarArgs, block): ASTExpression() constructor
{
	self.paramlist = paramlist;
	self.isVarArgs = isVarArgs;
	self.block = block;
	
	expressionType = Expression.FUNCTIONBODY;
}

// value is in GML type
function ASTLiteral(value): ASTExpression() constructor
{
	self.value = value;
	
	expressionType = Expression.LITERAL;
}

function ASTBinop(operator,first,second): ASTExpression()  constructor
{
	self.first = first;
	self.second = second;
	self.operator = operator;
	
	expressionType = Expression.BINOP;
}

function ASTUniop(operator,first): ASTExpression()  constructor
{
	self.first = first;
	self.operator = operator;
	
	expressionType = Expression.UNIOP;
}

function ASTGroup(group): ASTExpression()  constructor
{
	self.group = group;
	
	expressionType = Expression.GROUP;
}

function ASTAccess(name,expression = noone): ASTExpression()  constructor
{
	self.name = name;
	self.expression = expression;
	expressionType = Expression.ACCESS;
}

function ASTFunctionCall(name,args,isMethod = false): ASTExpression()  constructor
{
	self.name = name;	
	self.args = args;
	self.isMethod =isMethod;
	expressionType = Expression.FUNCTIONCALL;
}

function ASTTable(keys,values): ASTExpression()  constructor
{
	self.keys = keys;
	self.value = values;
	
	expressionType = Expression.TABLE;	
}