// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function Thread_Trace(statementType, scope = noone, index = -1) constructor
{
	self.statementType = statementType
	self.scope = scope;
	self.index = index;
}