/*
select core.new_pool(NULL, 'rc-sides','facility', 'Resource Facility Sides.', 0);

-- Rc Layout Names
select core.new_tag('names','rc-layout', NULL, 'all','All Items');
select core.new_tag('names','rc-layout', NULL, '9-red','9 Red Group');
select core.new_tag('names','rc-layout', NULL, '9-green','9 Green Group');
select core.new_tag('names','rc-layout', NULL, '9-blue','9 Blue Group');
select core.new_tag('names','rc-layout', NULL, '3-red','3 Red Group');
select core.new_tag('names','rc-layout', NULL, '3-green','3 Green Group');
select core.new_tag('names','rc-layout', NULL, '3-blue','3 Blue Group');
select core.new_tag('names','rc-layout', NULL, '1-red','1 Red');
select core.new_tag('names','rc-layout', NULL, '1-green','1 Green');
select core.new_tag('names','rc-layout', NULL, '1-blue','1 Blue');

-- Item Names
select core.new_tag('names','part', NULL, 'shell','Shell');
select core.new_tag('names','part', NULL, 'fiber-count','Fiber Count');

*/

/*

select spec.new_connector(NULL, 'resource-produce', 'horisontal-view', '==', 'poin.place.map', 'Point Place on Map');
select spec.new_connector(NULL, 'resource-produce', 'horisontal-view', '==', 'line.place.map', 'Line Place on Map');
select spec.new_connector(NULL, 'resource-consume', 'horisontal-view', '==', 'point.place', 'Point Place');
select spec.new_connector(NULL, 'resource-consume', 'horisontal-view', '==', 'line.place', 'Line Place');
select spec.new_connector(NULL, 'node-connection', 'range-connection', '==', 'pairs.copper', 'Copper Pairs Group');
select spec.new_connector(NULL, 'node-connection', 'resource-connection', '==', 'ends.cable', 'Cable Ends');
select spec.new_connector(NULL, 'node-connection', 'resource-connection', '==', 'ends.cable.copper', 'Copper Cable Ends');
select spec.new_connector(NULL, 'node-connection', 'resource-connection', '==', 'ends.ur', 'Ur Ends');


--select core.new_folder(2, 0, 'r', 'root', 'Root', 0, true, false);


select core.new_folder(20, 0, 'resources-group', 'std', 'Standard Resource', 0, true, false);
select core.insert_file(0,root_file_id('r'),20);
select core.new_folder(200, 0, 'resources-group', 'item-count', 'Item Count', 0, true, false);
select core.insert_file(0,20,200);
select spec.new_resources(2000, 0, NULL,27, 'facility', '27-optical-fibers', '27 Optical Fibers');
select core.insert_file(0,200,2000);

*/

/*

select spec.new_rc_layout(1,NULL,2000,'virtual_node','all', NULL,NULL);
select spec.new_rc_layout(2,1,2000,'virtual_node','9-red', NULL,NULL);
select spec.new_rc_layout(3,1,2000,'virtual_node','9-green', NULL,NULL);
select spec.new_rc_layout(4,1,2000,'virtual_node','9-blue', NULL,NULL);
select spec.new_rc_layout(5,2,2000,'virtual_node','3-red', NULL,NULL);
select spec.new_rc_layout(6,2,2000,'virtual_node','3-green', NULL,NULL);
select spec.new_rc_layout(7,2,2000,'virtual_node','3-blue', NULL,NULL);
select spec.new_rc_layout(8,3,2000,'virtual_node','3-red', NULL,NULL);
select spec.new_rc_layout(9,3,2000,'virtual_node','3-green', NULL,NULL);
select spec.new_rc_layout(10,3,2000,'virtual_node','3-blue', NULL,NULL);
select spec.new_rc_layout(11,4,2000,'virtual_node','3-red', NULL,NULL);
select spec.new_rc_layout(12,4,2000,'virtual_node','3-green', NULL,NULL);
select spec.new_rc_layout(13,4,2000,'virtual_node','3-blue', NULL,NULL);
select spec.new_rc_layout(14,5,2000,'fixed_range', '1-red', 1,1);
select spec.new_rc_layout(15,5,2000,'fixed_range','1-green', 2,2);
select spec.new_rc_layout(16,5,2000,'fixed_range','1-blue', 3,3);
select spec.new_rc_layout(17,6,2000,'fixed_range','1-red', 4,4);
select spec.new_rc_layout(18,6,2000,'fixed_range','1-green', 5,5);
select spec.new_rc_layout(19,6,2000,'fixed_range','1-blue', 6,6);
select spec.new_rc_layout(20,7,2000,'fixed_range','1-red', 7,7);
select spec.new_rc_layout(21,7,2000,'fixed_range','1-green', 8,8);
select spec.new_rc_layout(22,7,2000,'fixed_range','1-blue', 9,9);

*/

/*
select core.new_folder(30, 0, 'spec-group', 'cables', 'Cables', 0, true, false);
select core.insert_file(0,root_file_id('s'),30);
select core.new_folder(300, 0, 'spec-group', 'optical', 'Optical', 0, true, false);
select core.insert_file(0,30,300);
select spec.new_spec(3000, 0, 'facility', '27fibers-12mm', '27 Fibers Optical Cable. 12mm.');
select core.insert_file(0,300,3000);

select spec.new_part_group(1,NULL, 3000, 'shell');
select spec.new_part_resources(2,1, 3000, 'fiber-count', 
	core.file_id('r', 'std/item-count/27-optical-fibers', 'spec.resources'::regclass));

*/


--select spec.part_id(3000,'shell/fiber-count');
--select spec.rc_layout_id(2000,'all/9-red/3-blue/1-green', 'fixed_range');
--select core.file_id('c', 'producers/Point Place on Map', 'spec.connector'::regclass);
--select core.file_id('r', 'std/item-count/27-optical-fibers', 'spec.resources'::regclass);
--select core.file_id('s', 'cables/optical/27fibers-12mm', 'spec.spec'::regclass);

--select core.remove_file(0,300,3000);
--select core.file_pack()
