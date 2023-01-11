// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information

function Lexer() constructor
{
	keywords = ds_map_create();
	//keywords[?"and"] = true;
	keywords[?"break"] = true;
	keywords[?"do"] = true;
	keywords[?"else"] = true;
	keywords[?"elseif"] = true;
	keywords[?"false"] = true;
	keywords[?"end"] = true;
	keywords[?"for"] = true;
	keywords[?"function"] = true;
	keywords[?"goto"] = true;
	keywords[?"if"] = true;
	keywords[?"in"] = true;
	keywords[?"local"] = true;
	keywords[?"nil"] = true;
	//keywords[?"not"] = true;
	//keywords[?"or"] = true;
	keywords[?"repeat"] = true;
	keywords[?"return"] = true;
	keywords[?"then"] = true;
	keywords[?"true"] = true;
	keywords[?"until"] = true;
	keywords[?"while"] = true;
		
	lex = function(code)
	{
		self.chars = new charStream(code);
		var tokens = [];
		
		var isShortComment = false;
		var isLongComment = false;
		
		while(chars.has(0))
		{
			if(isShortComment)
			{
				while(chars.has(0) && !peek(["\r","\n"]))
				{
					chars.advance();
				}
				chars.advance();
				chars.skip();
				isShortComment = false;
				continue;
			}
			if(isLongComment)
			{
				while(chars.has(0) && !peek(["]"]))
				{
					chars.advance();
				}
				chars.advance();
				chars.skip();
				isLongComment = false;
				continue;
			}
			// Whitespace is always ignored
			while(match(["\t-\r"," "]))
			{
				chars.skip();
			}
			if(!chars.has(0))
			{
				break;	
			}
			// Check if comment
			if(peek(["-"]) && peek(["-"],1))
			{
				chars.advance(2);
				if(match(["["]))
				{
					isLongComment = true;
				}
				else
				{
					isShortComment = true;
				}
				continue;
			}
			//break;
			array_push(tokens,lexToken());
		}
		return tokens;
	}
	
	
	lexToken = function ()
	{
		if(peek(["A-Z","a-z","_"]))
		{
			return lexIdentfier();
		}
		if(peek(["0-9"])) 
		{
			return lexNumber();
		}
		if(peek(["\"","'"]))
		{
			return lexString();
		}
		if(peek(["["]))
		{
			var i = 1;
			while(peek(["="],i))
			{
				++i;	
			}
			if(peek(["["],i))
			{
				return lexString();
			}
			else
			{
				return lexOperator();
			}
		}
		return lexOperator();
		ParserException("Parser cannot tell what kind of token is",chars.line);
	}
	
	lexIdentfier = function()
	{
		if(!match(["A-Z","a-z","_"]))
		{
			ParserException("Please check lexer function \"lexIdentifier\"",-1);
		}
		while(match(["A-Z","a-z","_","0-9"]))
		{
		}
		
		var token = chars.emit(Token.IDENTIFIER);
		if(keywords[? token.literal])
		{
			token.type = Token.KEYWORD;
		}
		if(token.literal == "and" || token.literal == "or" || token.literal == "not")
		{
			token.type = Token.OPERATOR;
		}
		return token;
	}
	lexNumber = function()
	{
		var isBaseTen = true;
		var hasExponent = false;
		if(peek(["0"]) && peek(["x","X"],1))
		{
			chars.advance(2);
			isBaseTen = false;	
		}
		//Match digits pre-point
		while(match(["0-9"]))
		{}
		
		//Optional point
		var hasPoint = match(["."]);
		
		//Match digits post-point, if no decimal this will fail immeditely
		while(match(["0-9"]))
		{}
		
		//Check Exponent
		if(isBaseTen)
		{
			hasExponent = match(["e","E"]);
		}
		else
		{
			hasExponent = match(["p","P"]);
		}
		
		//Match digits post-exponent, if no exponent this will fail immeditely
		while(match(["0-9"]))
		{}
		var token;
		if(hasPoint || hasExponent)
		{
			token = chars.emit(Token.FLOAT);
		}
		else
		{
			token = chars.emit(Token.INTEGER);
		}
		return token;
	}
	
	lexString = function()
	{
		var endingVal = "";
		var level = 0;
		if(match(["\""]))
		{
			endingVal = "\"";
		}
		else if(match(["'"]))
		{
			endingVal = "'";
		}
		else if(match(["["]))
		{
			while(match(["="]))
			{
				++level;
			}
			if(!match(["["]))
			{
				ParserException("Long string is not properly initalized",chars.line)	
			}
			endingVal = "]";
		}
		
		if(endingVal == "]")
		{
				
			while(true)
			{
				if(match(["\\"]))
				{
					if(!match(["a","b","f","n","r","t","v","\\","\"","'","z"]))
					{
						ParserException("Escape character does not have a following character",chars.line);
					}
				}
				else
				{
					chars.advance();	
				}
				if(peek(["]"]))
				{
					var leave = true;
					for(var i = 1; i <= level; ++i)
					{
						if(!peek(["="],i))
						{
							leave = false;
							break;
						}
					}
					if(leave && peek(["]"],level+1))
					{
						chars.advance(level+2);
						break;	
					}
				}
				if(!chars.has(0))
				{
					ParserException("Unterminated long string",chars.line);
				}

			}
		}
		else
		{
			while(!peek([endingVal]))
			{
				if(match(["\\"]))
				{
					if(!match(["a","b","f","n","r","t","v","\\","\"","'","z"]))
					{
						ParserException("Escape character does not have a following character",chars.line);
					}
				}
				else
				{
					if(chars.has(0))
					{
						chars.advance();	
					}
					else
					{
						ParserException("Unterminated short string",chars.line)	
					}
				}
			}
			if(!match([endingVal]))
			{
				ParserException("Unterminated short string",chars.line)	
			}
		}
		
		var token = chars.emit(Token.STRING);
		return token;
	}
	
	lexOperator = function()
	{
		if(match(["+","-","*","^","%","&","|","[","]","{","}","(",")",",",";","#"]))
		{
			
		}
		else if(match(["/"]))
		{
			match(["/"]);	
		}
		else if(match(["~"]))
		{
			match(["="]);	
		}
		else if(match(["<"]))
		{
			if(match(["="]))
			{}
			else if(match(["<"]))
			{}			
		}
		else if(match([">"]))
		{
			if(match(["="]))
			{}
			else if(match([">"]))
			{}	
		}
		else if(match(["="]))
		{
			match(["="]);
		}
		else if(match([":"]))
		{
			match([":"]);
		}
		else if(match(["."]))
		{
			match(["."]);
			match(["."]);
		}
		else
		{
			ParserException("Parser cannot tell what kind of operation is",chars.line);	
		}
		return chars.emit(Token.OPERATOR);
	}
	
	peek = function (patterns,offset = 0)
	{
		
		if(!chars.has(offset))
		{
			return false;	
		}
		var curChar = chars.get(offset);
		//show_debug_message(curChar);
		var curCharCode = string_ord_at(curChar,1);
		for(var i = 0; i < array_length(patterns); ++i)
		{
			var patternLen = string_length(patterns[i]);
			if(patternLen == 1)
			{
				if(patterns[i] == curChar)
				{
					return true;	
				}
			}
			// Assuming it is a interval
			else if(patternLen == 3)
			{
				var start = string_ord_at(patterns[i],1);
				var ending = string_ord_at(patterns[i],3);
				if(curCharCode >= start && curCharCode <= ending)
				{
					return true;
				}
			}
		}
		return false;
	}
	match = function(patterns,offset)
	{
		if(peek(patterns,offset))
		{
			chars.advance();
			return true;
		}
		return false;
	}
}

function charStream(input) constructor
{
	self.input = input;
	index = 1;
	length = 0;
	line = 1;
	has = function(offset)
	{
		return index + offset <= string_length(input);
	};
	get = function(offset)
	{
		return string_char_at(input,index+offset);
	};
	advance = function(num = 1)
	{
		for(var i = 0; i < num; ++i)
		{
			var cur = get(0);
			if(cur == "\n")
			{
				++line;	
			}
			++index;
			++length;
		}
	};
	skip = function()
	{
		length = 0;
	}
	emit = function(tokenType)
	{
		var start = index - length;
		//show_debug_message(string(start)+","+string(length));
		var token = new Token(tokenType,string_copy(input,start,length),start,line);
		skip();
		return token;
	}
}

global.lexer = new Lexer();