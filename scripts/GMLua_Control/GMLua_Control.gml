global.GMLua = {}
with(global.GMLua)
{
	self.logmode = true
	self.defaultFolderPath = ""
	function lexAndParse(code,logmode = self.logmode,folderPath=defaultFolderPath,fileName="Misc")
	{
		var lexedTokens = global.lexer.lex(code);
		if(filename_ext(fileName) != "")
		{
			fileName = filename_change_ext(fileName,".txt")
		}
		if(fileName != "Misc")
		{
			var a = file_delete(folderPath+"LexerLog_"+ fileName)
		}
		if(logmode)
		{
			var f;
			if(fileName == "Misc")
			{
				f = file_text_open_append(folderPath+"LexerLog_"+ fileName);	
				file_text_write_string(f,"-----------------------\n");
			}
			else
			{
				f = file_text_open_write(folderPath+"LexerLog_"+ fileName);	
			}
			file_text_write_string(f,string_replace_all(string(lexedTokens),"},","}\n"));
			file_text_close(f);
		}
	
		var abstractTree = global.parser.parseChunk(lexedTokens,folderPath,fileName);

		if(fileName != "Misc")
		{
			file_delete(folderPath+"ParserLog_"+ fileName)
		}
		if(logmode)
		{
			var f;
			if(fileName == "Misc")
			{
				f = file_text_open_append(folderPath+"ParserLog_"+ fileName);
				file_text_write_string(f,"-----------------------\n");
			}
			else
			{
				f = file_text_open_write(folderPath+"ParserLog_"+ fileName);	
			}
			file_text_write_string(f,global.parser.createChunkBlock(abstractTree));
			file_text_close(f);
		}
		return abstractTree;
	}
	
	runAST = function(abstractTree, scope = new Scope(), logmode = self.logmode, logFolderPath = undefined)
	{
		if(is_undefined(logFolderPath))
		{
			logFolderPath = (abstractTree.sourceFilePath+"InterpreterLog_");
			var beforeDotStr = string_split((abstractTree.sourceFileName),".")[0];
			logFolderPath += beforeDotStr + ".txt";
		}
		var newScope = global.interpreter.visitChunk(abstractTree,scope);
		file_delete(logFolderPath)
		if(logmode)
		{
			var f = file_text_open_write(logFolderPath);
			file_text_write_string(f,string(newScope));
			file_text_close(f);
		}
		return newScope;
	}

	createLuaFromFile = function(filePath,logmode)
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

	createLuaFromString = function(str,logmode)
	{
		return lexAndParse(str,logmode);
	}
	
}

function createLuaFromFile(filePath, logmode)
{
	return global.GMLua.createLuaFromFile(filePath, logmode)
}
function createLuaFromString(str,logmode)
{
	return global.GMLua.createLuaFromString(str,logmode)
}

function runLua(luaObj, scope = new Scope(), logmode = undefined, logFolderPath = undefined )
{
	return global.GMLua.runAST(luaObj, scope, logmode, logFolderPath)
}

function setGMLVariable(scope,name, newExp, isConst = false)
{
	var attribute = noone;
	if(isConst)
	{
		attribute = "const"
	}
	scope.setLocalVariable(name,GMLToLua(newExp),attribute);
}
function setGMLFunction(scope,name, func, isGMLtoGML = true)
{
	scope.setLocalVariable(name, new GMFunction(func,isGMLtoGML))
}

function setGMLValueTableValue(table,keyName,newExp)
{
	table.setValue(new simpleValue(keyName),GMLToLua(newExp))
}
function setGMLFunctionTableValue(table,keyName,func, isGMLtoGML = true)
{
	table.setValue(new simpleValue(keyName),new GMFunction(func,isGMLtoGML))
}

function getLuaVariable(scope,name)
{
	return LuaToGML(scope.getVariable(name).getValue());
}

// By default, the function list is an empty whitelist
function setFunctionNameList(functionNameList, isWhiteList = true)
{
	global.LuaLibrary.gmlFunctionNameList = functionNameList;
	global.LuaLibrary.nameListIsWhitelist = isWhiteList
}

// This is just for the "Circles chase mouse" demo, remove the "Lua_Action_Object" and comment this out
// at the same time. Secure management of moding structure is the end-developer's responsibilty
setFunctionNameList([],false)