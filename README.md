# GMLua

A Lua interpreter using GML

# Important Objects

## Lua Object (Internally a struct)
Holds the instructions that are ran

Example: 
```
local a = 3
>local b = 7 + a
```
The selected statement instructs that the value of 7 plus the value within a is placed within a new variable, b


## Scope
Holds the context (variables) that are used in instructions

Example: 

```
local a = 3
>local b = 7 + a
```

The selected statement must use Scope to find the value of a, which was declared via the previous statement

NOTICE: Only global scopes can be manipulated with the interface. 

# Interface

## Lua Object Creation Functions

Makes the Lua Object from a string, directly or from a Lua file.

### function createLuaFromFile(filePath, logmode=false)

### function createLuaFromString(str,logmode=false)

## Lua Object Running Function

### function runLua(luaObj, scope = new Scope(), logFolderPath)
Runs the functions using the provided scope, if a scope is not provided, a default empty scope is made.

## Scope Manipulation Functions

Expressions are changed to GML or Lua values as needed, automatically

### function setGMLVariable(scope,name, newExp)

Within the global scope, "scope", create a variable with identfier: name, and value: newExp

newExp can be any GML value that can be converted to a Lua value except for GML functions

### function setGMLFunction(scope,name, func, isGMLtoGML = true)

Within the global scope, "scope", create a variable with identfier: name, and value: func

Lua GMFunctions have 2 different types, GMLtoGML and LuatoLua.

Most GMFunctions are GMLtoGML, the Lua values are converted into GML values and then sent to the associated GML function

LuatoLua functions provide the Lua values directly and expect a return Lua value.

### function getLuaVariable(scope,name)

# GMLua specific functions

### function getgmlfunction(functionName)
Takes a string which is the name of a GML built in function and returns a GMFunction of said GML built in function

### function callwithcontext(context,func,[args...])
Certain built in functions, such as the ones used in collisions, must have context of an instance to work properly. Take context, a function, using the remaining expressions as arguments, return the func's return.

# Data Types and Conversions

NOTICE (Functions): Lua has 2 data types for functions: Function and GMFunction. The former is for functions defined in Lua, the latter is for functiond defined in GML. Both may be used interchangeably in the Lua code.  

NOTICE (Tables): If a struct or instance is provided to a scope to create a Table, changes to the inital data structure causes immediate changes to the Table and vice versa.

## GML to Lua

String -> String

Int32,Int64 -> Int

Number -> Float

Bool -> Boolean

Struct, Instance -> Table

Undefined -> Nil

Method -> GMFunction (Since non-method functions are indistinguishable from integers, if you wish to provide a non-method function to a Lua scope, first turn it into a method via method(undefined,func))


## Lua to GML

String -> String

Int -> Int64 

Float -> Number

Boolean -> Bool

Table->Struct, Instance (default is struct)

Nil -> Undefined

GMFunction -> Method

Function -> Method 

# Departures from Lua 5.4

- Table string keys cannot start with: ["Table_","Function_", "GMFunction_","Number_"]
- Table string keys cannot be: ["Nil","Boolean_True", "Boolean_False"]
- There is no intent to add Userdata and any C related APIs
- The library has 3 basic functions: print, select, setmetatable
- The library function getgmlfunction allows Lua code to request a built-in function by name.
- Goto statements are NOT prohibited from jumping into the scope of a local variable

# Demo

A test.zip file is provided in this project. If you would like to see a demo of this in action, place the test.zip file in the appropriate location depending on device and unzip it. Refer to [this](https://manual.yoyogames.com/Additional_Information/The_File_System.htm) part of the manual.

Run the project and you should see 2 red circles with grey centers that follow the mouse at differing speeds. Please then check on the "Lua_test_object" to see an example on how to make the GML and Lua interact seamlessly.
