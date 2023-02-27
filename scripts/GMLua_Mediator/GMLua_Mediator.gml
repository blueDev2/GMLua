global.GMLua = {}
with(global.GMLua)
{
	self.logmode = true
	self.lexer = undefined;
	self.parser = undefined;
	self.interpreter = undefined;
	function lexAndParse(code,logmode = self.logmode,folderPath="",fileName="Misc")
	{
		var lexedTokens = lexer.lex(code);
		if(logmode)
		{
			var f;
			if(fileName == "Misc")
			{
				f = file_text_open_append(folderPath+"LexerLog_"+ fileName+".txt");	
				file_text_write_string(f,"-----------------------\n");
			}
			else
			{
				f = file_text_open_write(folderPath+"LexerLog_"+ fileName+".txt");	
			}
			file_text_write_string(f,string_replace_all(string(lexedTokens),"},","}\n"));
			file_text_close(f);
		}
	
		var abstractTree = parser.parseChunk(lexedTokens);

		if(logmode)
		{
			var f;
			if(fileName == "Misc")
			{
				f = file_text_open_append(folderPath+"ParserLog_"+ fileName+".txt");
				file_text_write_string(f,"-----------------------\n");
			}
			else
			{
				f = file_text_open_write(folderPath+"ParserLog_"+ fileName+".txt");	
			}
			file_text_write_string(f,parser.createLog(0,abstractTree));
			file_text_close(f);
		}
	}
	function runFunction(abstractTree, scope = new Scope())
	{
		interpreter = Interpreter(abstractTree);
		if(logmode)
		{
			var f = file_text_open_write(folderPath + "InterpreterLog.txt");
			file_text_write_string(f,string_replace_all(string(interpreter.globalScope),"},","}\n\n"));
			file_text_close(f);
		}
	}

	function createLuaFromFile(filePath,logmode)
	{
		var file = file_text_open_read(filePath);
		var code = "";
		var folderPath = filename_path(filePath);
		var fileName = filename_name(filePath);
		while(!file_text_eof(file))
		{
			code += file_text_readln(file);
		}
		file_text_close(file);
		lexAndParse(code,logmode,folderPath,fileName);
	}

	function createLuaFromString(str,logmode = noone)
	{
		lexAndParse(str,logmode);
	}
}