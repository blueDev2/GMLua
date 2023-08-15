// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function collision(a,runIndirect)
{
	with(a)
	{
		runIndirect()
	}
}
function runIndirect()
{
	if(place_meeting(x,y,object_index))
	{
		show_debug_message("Touching");
	}	
}