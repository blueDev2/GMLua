// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
enum TokenType
{
	IDENTIFIER,
	KEYWORD,
	STRING,
	INTEGER,
	FLOAT,
	OPERATOR
}

function Token(type,literal,index,line) constructor
{
	self.type = type;
	self.literal = literal;
	self.index = index;
	self.line = line;
}