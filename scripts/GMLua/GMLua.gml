global.GMLua_Logmode = true;
global.GMLua_AllowGmlScope = false;

function GMLua(logmode = global.GMLua_Logmode, allowGmlScope = global.GMLua_AllowGmlScope,filepath = "") constructor
{
	self.logmode = logmode;
	self.allowGmlScope = allowGmlScope;
	self.filepath = filepath;
	
	lexAndParse = function(code)
	{
		var folderPath = filename_path(filepath);
		var fileName = filename_name(filepath);
	
		var lexedTokens = global.lexer.lex(code);
		if(logmode)
		{
			var f = file_text_open_write(folderPath+"LexerLog_"+ fileName+".txt");
			file_text_write_string(f,string_replace_all(string(lexedTokens),"},","}\n"));
			file_text_close(f);
		}
	
		var abstractTree = global.parser.parseChunk(lexedTokens);

		if(logmode)
		{
			var f = file_text_open_write(folderPath+"ParserLog_"+ fileName+".txt");
			file_text_write_string(f,string_replace_all(string(abstractTree),"},","}\n\n"));
			file_text_close(f);
		}
	}
	/*
	interpreter = Interpreter(abstractTree);
	if(logmode)
	{
		var f = file_text_open_write(folderPath + "InterpreterLog.txt");
		file_text_write_string(f,string_replace_all(string(interpreter.globalScope),"},","}\n\n"));
		file_text_close(f);
	}*/
	
}

function createLuaFromFile(filePath,logmode, allowGmlScope)
{
	var file = file_text_open_read(filePath);
	var code = "";
	while(!file_text_eof(file))
	{
		code += file_text_readln(file);
	}
	file_text_close(file);
	var gmlua =  new GMLua(logmode,allowGmlScope,filePath);
	gmlua.lexAndParse(code);
	return gmlua;
}

function createLuaFromString(str,logmode = noone, allowGmlScope = noone)
{
	return new GMLua(str,logmode,allowGmlScope);
}
