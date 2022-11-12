// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
enum AST
{
	CHUNK,
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

function ASTChunk(globals) constructor
{
	self.globals = globals;
	astType = AST.CHUNK;
}

function ASTLabel(name) constructor
{
	self.name = name;
	astType = AST.STATEMENT;
	statementType = Statement.LABEL;
}

function ASTBreak() constructor
{
	astType = AST.STATEMENT;
	statementType = Statement.BREAK;
}

function ASTGoto(labelName) constructor
{
	self.labelName 	= labelName;
	astType = AST.STATEMENT;
	statementType = Statement.GOTO;
}

function ASTDo(block) constructor
{
	self.block = block;
	astType = AST.STATEMENT;
	statementType = Statement.DO;
}

function ASTWhile(condition,block) constructor
{
	self.condition = condition;
	self.block = block;
	astType = AST.STATEMENT;
	statementType = Statement.WHILE;
}

function ASTRepeat(condition,block) constructor
{
	self.condition = condition;
	self.block = block;
	astType = AST.STATEMENT;
	statementType = Statement.REPEAT;
}

function ASTIf(conditions, blocks) constructor
{
	self.conditions = conditions;
	self.blocks = blocks;
	astType = AST.STATEMENT;
	statementType = Statement.IF;
}

function ASTNumericFor(initalName,inital,limit,step,block) constructor
{
	self.initalName = initalName;
	self.inital = inital;
	self.limit = limit;
	self.step = step;
	self.block = block;
	astType = AST.STATEMENT;
	statementType = Statement.NUMERICFOR;
}

function ASTGenericFor(namelist,explist,block) constructor
{
	self.namelist = namelist;
	self.explist = explist;
	self.block = block;
	astType = AST.STATEMENT;
	statementType = Statement.GENERICFOR;
}

function ASTReturn(expressions) constructor
{
	self.expressions = expressions;	
	astType = AST.STATEMENT;
	statementType = Statement.RETURN;
}

function ASTDeclaration(name,attribute, expression, isLocal) constructor
{
	self.name = name;
	self.attribute = attribute;
	self.expression = expression;
	self.isLocal = isLocal;
	astType = AST.STATEMENT;
	statementType = Statement.DECLARATION;
}

function ASTAssignment(names,expressions) constructor
{
	self.names = names;	
	self.expressions = expressions;
	astType = AST.STATEMENT;
	statementType = Statement.ASSIGNMENT;
}


function ASTFunctionBody(paramlist, isVarArgs, block) constructor
{
	self.paramlist = paramlist;
	self.isVarArgs = isVarArgs;
	self.block = block;
	astType = AST.EXPRESSION;
	expressionType = Expression.FUNCTIONBODY;
}

// value is in GML type
function ASTLiteral(value) constructor
{
	self.value = value;
	astType = AST.EXPRESSION;
	expressionType = Expression.LITERAL;
}

function ASTBinop(operator,first,second) constructor
{
	self.first = first;
	self.second = second;
	self.operator = operator;
	astType = AST.EXPRESSION;
	expressionType = Expression.BINOP;
}

function ASTUniop(operator,first) constructor
{
	self.first = first;
	self.operator = operator;
	astType = AST.EXPRESSION;
	expressionType = Expression.UNIOP;
}

function ASTGroup(group) constructor
{
	self.group = group;
	astType = AST.EXPRESSION;
	expressionType = Expression.GROUP;
}

function ASTAccess(name,expression = noone) constructor
{
	self.name = name;
	self.expression = expression;
	astType = AST.EXPRESSION;
	expressionType = Expression.ACCESS;
}

function ASTFunctionCall(name,args) constructor
{
	self.name = name;	
	self.args = args;
	astType = AST.EXPRESSION;
	expressionType = Expression.FUNCTIONCALL;
}

function ASTTable(keys,values) constructor
{
	self.keys = keys;
	self.value = values;
	astType = AST.EXPRESSION;
	expressionType = Expression.TABLE;	
}