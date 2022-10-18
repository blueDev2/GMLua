global.GMLua_Logmode = false;
global.GMLua_AllowGmlScope = false;

function GMLua(code, logmode = noone, allowGmlScope = noone) constructor
{
	if(logmode == noone)
	{
		logmode = global.GMLua_Logmode;	
	}
	if(allowGmlScope == noone)
	{
		allowGmlScope = global.GMLua_AllowGmlScope;
	}
	self.allowGmlScope = allowGmlScope;
	
	var lexer = new Lexer(code);
	var lexedTokens = lexer.lex();
	delete lexer;
	if(logmode)
	{
		var f = file_text_open_write("LexerLog.txt");
		file_text_write_string(f,string_replace_all(string(lexedTokens),"},","}\n"));
		file_text_close(f);
	}
	
	var parser = new Parser(lexedTokens);
	lexedTokens = 0;
	var abstractTree = parser.parseChunk();
	delete parser;
	if(logmode)
	{
		var f = file_text_open_write("ParserLog.txt");
		file_text_write_string(f,string_replace_all(string(abstractTree),"},","}\n\n"));
		file_text_close(f);
	}
	
	
	
	
}

function createLuaFromFile(filePath,logmode = noone, allowGmlScope = noone)
{
	var file = file_text_open_read(filePath);
	var code = "";
	while(!file_text_eof(file))
	{
		code += file_text_readln(file);
	}
	file_text_close(file);
	return new GMLua(code,logmode,allowGmlScope);
}

function createLuaFromString(str,logmode = noone, allowGmlScope = noone)
{
	return new GMLua(str,logmode,allowGmlScope);
}
