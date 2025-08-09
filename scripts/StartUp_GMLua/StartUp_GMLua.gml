// This script is for ensuring GMLua scripts start up in the correct order. 
// It must be called before using GMLua functions, and only once at the start of the game.
// For the purposes of the demo, this is called when the room is created
function StartUp_GMLua(){
	static hasStartedGMLua = false;
	if (hasStartedGMLua)
	{
		return;
	}
	startUpGMLua_Interpreter();
	startUpGMLua_Lexer();
	startUpGMLua_Library();
	startUpGMLua_Parser();
	startUpGMLua_Control();
	hasStartedGMLua = true;
	// This is just for the "Circles chase mouse" demo, remove the "Lua_Action_Object" and comment this out
	// at the same time. Secure management of moding structure is the end-developer's responsibilty
	setFunctionNameList([],false)
}