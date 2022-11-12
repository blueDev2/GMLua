/// @description Insert description here
// You can write your code in this editor
if(ds_map_size(weakTableList) == 0)
{
	return;	
}
var numCheck = int64(proportionCheck * ds_map_size(weakTableList));
if(numCheck < 1)
{
	numCheck = 1;	
}
if(is_undefined(index))
{
	index = ds_map_find_first(weakTableList);	
}
for(var i = 0; i < numCheck; ++i)
{
	if(!weak_ref_alive(index))
	{
		var curMap = weakTableList[? index];
		var curRef = index;
		index = ds_map_find_next(weakTableList,index);
		ds_map_delete(weakTableList,curRef);
		ds_map_destroy(curMap);
		if(!is_undefined(index))
		{
			continue;	
		}
	}
	if(is_undefined(index))
	{
		index = ds_map_find_first(weakTableList);
	}
}

