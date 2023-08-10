global.GMLua = {}
with(global.GMLua)
{
	self.logmode = true
	/*self.lexer = undefined;
	self.parser = undefined;
	self.interpreter = undefined;*/
	function lexAndParse(code,logmode = self.logmode,folderPath="",fileName="Misc")
	{
		var lexedTokens = global.lexer.lex(code);
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
	
		var abstractTree = global.parser.parseChunk(lexedTokens,folderPath,fileName);

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
			file_text_write_string(f,global.parser.createChunkBlock(abstractTree));
			file_text_close(f);
		}
		return abstractTree;
	}
	
	function runAST(abstractTree, scope = new Scope(), logFolderPath )
	{
		if(is_undefined(logFolderPath))
		{
			logFolderPath = (abstractTree.sourceFilePath+"InterpreterLog_"+abstractTree.sourceFileName)
		}
		var newScope = global.interpreter.visitChunk(abstractTree,scope);
		if(logmode)
		{
			var f = file_text_open_write(logFolderPath + "InterpreterLog.txt");
			file_text_write_string(f,string(newScope));
			file_text_close(f);
		}
		return newScope;
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
		return lexAndParse(code,logmode,folderPath,fileName);
	}

	function createLuaFromString(str,logmode = noone)
	{
		return lexAndParse(str,logmode);
	}
	
}