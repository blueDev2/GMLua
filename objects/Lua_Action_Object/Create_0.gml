/// @description Insert description here
// You can write your code in this editor

//Create new scope
scope = new Scope();
//Attach this instance to the scope
setGMLVariable(scope,"obj",self);
//Create an AST object from the lua file
var ast = createLuaFromFile("test/test_object/test.lua",false)
//Run said AST object
runLua(ast,scope);
//Pull the functions for onCreate, onStep, and onDraw from the scope
onCreate = getLuaVariable(scope,"onCreate")
onStep = getLuaVariable(scope,"onStep")
onDraw = getLuaVariable(scope,"onDraw")

//Run the lua function "onCreate"
onCreate();