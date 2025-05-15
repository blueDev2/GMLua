/// @description Insert description here
// You can write your code in this editor

var LAOs = []

//Create new scope
scope = new Scope();
//Attach this instance to the scope
//setGMLVariable(scope,"obj",self);
//Create an AST object from the lua file
var ast = createLuaFromFile("test/test_object/test.lua",true)
//Run said AST object
runLua(ast,scope,true);
//Pull the functions for onCreate, onStep, and onDraw from the scope
onCreate = getLuaVariable(scope,"onCreate")
onStep = getLuaVariable(scope,"onStep")
onDraw = getLuaVariable(scope,"onDraw")

var lua_functions = 
{
	onCreate : onCreate,
	onStep : onStep,
	onDraw : onDraw
}
array_push(LAOs,instance_create_layer(0,0,"Instances_1",Lua_Action_Object,lua_functions))
array_push(LAOs,instance_create_layer(0,0,"Instances_1",Lua_Action_Object,lua_functions))
array_push(LAOs,instance_create_layer(0,0,"Instances_1",Lua_Action_Object,lua_functions))
array_push(LAOs,instance_create_layer(0,0,"Instances_1",Lua_Action_Object,lua_functions))


