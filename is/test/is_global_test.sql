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

select core.new_folder(1, 0, 'c', 'root', 'Root', 0, true, false);
select core.new_folder(10, 0, 'resource-produce-connector-group', 'producers', 'Producers Connector', 0, true, false);
select core.insert_file(0,1,10);

select core.new_folder(11, 0, 'resource-consume-connector-group', 'consumers', 'Consumers Connector', 0, true, false);
select core.insert_file(0,1,11);
select core.new_folder(12, 0, 'node-connection-connector-group', 'connection', 'Connection Connector', 0, true, false);
select core.insert_file(0,1,12);

select spec.new_connector(101, 0, 'resource-produce', 'horisontal-view', '==', 'poin.place.map', 'Point Place on Map');
select core.insert_file(0,10,101);
select spec.new_connector(102, 0, 'resource-produce', 'horisontal-view', '==', 'line.place.map', 'Line Place on Map');
select core.insert_file(0,10,102);

select spec.new_connector(111, 0, 'resource-consume', 'horisontal-view', '==', 'point.place', 'Point Place');
select core.insert_file(0,11,111);
select spec.new_connector(112, 0, 'resource-consume', 'horisontal-view', '==', 'line.place', 'Line Place');
select core.insert_file(0,11,112);

select spec.new_connector(121, 0, 'node-connection', 'range-connection', '==', 'pairs.copper', 'Copper Pairs Group');
select core.insert_file(0,12,121);
select spec.new_connector(122, 0, 'node-connection', 'resource-connection', '==', 'ends.cable', 'Cable Ends');
select core.insert_file(0,12,122);
select spec.new_connector(123, 0, 'node-connection', 'resource-connection', '==', 'ends.cable.copper', 'Copper Cable Ends');
select core.insert_file(0,12,123);
select spec.new_connector(124, 0, 'node-connection', 'resource-connection', '==', 'ends.ur', 'Ur Ends');
select core.insert_file(0,12,124);


select core.new_folder(2, 0, 'r', 'root', 'Root', 0, true, false);
select core.new_folder(20, 0, 'resources-group', 'std', 'Standard Resource', 0, true, false);
select core.insert_file(0,2,20);
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
select core.new_folder(3, 0, 's', 'root', 'Root', 0, true, false);
select core.new_folder(30, 0, 'spec-group', 'cables', 'Cables', 0, true, false);
select core.insert_file(0,3,30);
select core.new_folder(300, 0, 'spec-group', 'optical', 'Optical', 0, true, false);
select core.insert_file(0,30,300);
select spec.new_spec(3000, 0, 'FLAGS', '27fibers-12mm', '27 Fibers Optical Cable. 12mm.');
select core.insert_file(0,300,3000);

select spec.new_part(1,NULL,	'group', 	3000, 'shell', 		NULL);
select spec.new_part(2,1,	'resources', 	3000, 'fiber-count', 	2000);

*/


--select spec.part_id(3000,'shell/fiber-count');
--select spec.rc_layout_id(2000,'all/9-red/3-blue/1-green', 'fixed_range');
--select core.file_id('c', 'producers/Point Place on Map', 'spec.connector'::regclass);
--select core.file_id('r', 'std/item-count/27-optical-fibers', 'spec.resources'::regclass);
--select core.file_id('s', 'cables/optical/27fibers-12mm', 'spec.spec'::regclass);

--select core.remove_file(0,300,3000);
--select core.file_pack()
