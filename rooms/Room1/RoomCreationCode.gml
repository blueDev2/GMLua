
var testFileLocations = [];
array_push(testFileLocations,"test/test_metamethods2/test.lua");
array_push(testFileLocations,"test/test_operators/test.lua");
array_push(testFileLocations,"test/test_goto/test.lua");
//var thing = method(undefined, array_push)
//var a = variable_global_get("array_push")

for(var i = 0; i < array_length(testFileLocations); ++i)
{
	var curFile = (testFileLocations[i]);
	var chunk = global.GMLua.createLuaFromFile(curFile);
	show_debug_message("Current test file: "+(testFileLocations[i]));
	global.GMLua.runAST(chunk,,);
}



//show_debug_message(scope)
game_end();


