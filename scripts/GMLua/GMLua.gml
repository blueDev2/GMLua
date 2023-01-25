global.GMLua_Logmode = true;

function GMLua(logmode = global.GMLua_Logmode,filepath = "") constructor
{
	self.logmode = logmode;
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
			file_text_write_string(f,global.parser.createLog(0,abstractTree));
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

function createLuaFromFile(filePath,logmode)
{
	var file = file_text_open_read(filePath);
	var code = "";
	while(!file_text_eof(file))
	{
		code += file_text_readln(file);
	}
	file_text_close(file);
	var gmlua =  new GMLua(logmode,filePath);
	gmlua.lexAndParse(code);
	return gmlua;
}

function createLuaFromString(str,logmode = noone)
{
	return new GMLua(str,logmode);
}
