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

-- Folder Kinds
SELECT core.new_tag('file','kind', NULL, 'resource-producer-connector-folder', 'Producer');
SELECT core.new_tag('file','kind', NULL, 'resource-consumer-connector-folder', 'Consumer');
SELECT core.new_tag('file','kind', NULL, 'node-connection-connector-folder', 'Connection');
SELECT core.new_tag('file','kind', NULL, 'edge-connection-connector-folder', 'Connection');
SELECT core.new_tag('file','kind', NULL, 'network-connection-connector-folder', 'Connection');
SELECT core.new_tag('file','kind', NULL, 'association-connector-folder', 'Association');

select core._add_file_rel('core.folder'::regclass, 'connector-folder-root', 'core.folder'::regclass, 'resource-producer-connector-folder', 1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'connector-folder-root', 'core.folder'::regclass, 'resource-consumer-connector-folder', 1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'connector-folder-root', 'core.folder'::regclass, 'node-connection-connector-folder', 1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'connector-folder-root', 'core.folder'::regclass, 'edge-connection-connector-folder', 1, 'Добавить папку.');

select core._add_file_rel('core.folder'::regclass, 'specification-folder-root', 'core.folder'::regclass, 'specification-folder-node', -1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'resource-folder-root', 'core.folder'::regclass, 'resource-folder-node', -1, 'Добавить папку.');

select core._add_file_rel('core.folder'::regclass, 'resource-producer-connector-folder', 'core.folder'::regclass, 'resource-producer-connector-folder', -1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'resource-producer-connector-folder', 'spec.connector'::regclass, 'resource-producer-connector', -1, 'Добавить файл.');
select core._add_file_rel('core.folder'::regclass, 'resource-consumer-connector-folder', 'core.folder'::regclass, 'resource-consumer-connector-folder', -1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'resource-consumer-connector-folder', 'spec.connector'::regclass, 'resource-consumer-connector', -1, 'Добавить файл.');
select core._add_file_rel('core.folder'::regclass, 'node-connection-connector-folder', 'core.folder'::regclass, 'node-connection-connector-folder', -1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'node-connection-connector-folder', 'spec.connector'::regclass, 'node-connection-connector', -1, 'Добавить файл.');
select core._add_file_rel('core.folder'::regclass, 'edge-connection-connector-folder', 'core.folder'::regclass, 'edge-connection-connector-folder', -1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'edge-connection-connector-folder', 'spec.connector'::regclass, 'edge-connection-connector', -1, 'Добавить файл.');


select core._add_file_rel('core.folder'::regclass, 'resource-folder-node', 'core.folder'::regclass, 'resource-folder-node', -1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'resource-folder-node', 'spec.rc_item_count'::regclass, 'item-count-resource', -1, 'Добавить папку.');

select core._add_file_rel('core.folder'::regclass, 'specification-folder-node', 'core.folder'::regclass, 'specification-folder-node', -1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'specification-folder-node', 'spec.specification'::regclass, 'std-specification', -1, 'Добавить папку.');

*/

/*

select core.new_folder(1, 0, 'connector-folder-root', 'root', 'Root', 0, true, false);
select core.new_folder(10, 0, 'resource-producer-connector-folder', 'producers', 'Producers Connector', 0, true, false);
select core.insert_file(0,1,10);

select core.new_folder(11, 0, 'resource-consumer-connector-folder', 'consumers', 'Consumers Connector', 0, true, false);
select core.insert_file(0,1,11);
select core.new_folder(12, 0, 'node-connection-connector-folder', 'connection', 'Connection Connector', 0, true, false);
select core.insert_file(0,1,12);

select spec.new_connector(101, 0, 'resource-producer-connector', '==', 'poin.place.map', 'geometry-horisontal-view', 'Point Place on Map');
select core.insert_file(0,10,101);
select spec.new_connector(102, 0, 'resource-producer-connector', '==', 'line.place.map', 'geometry-horisontal-view', 'Line Place on Map');
select core.insert_file(0,10,102);

select spec.new_connector(111, 0, 'resource-consumer-connector', '==', 'point.place', 'geometry-horisontal-view', 'Point Place');
select core.insert_file(0,11,111);
select spec.new_connector(112, 0, 'resource-consumer-connector', '==', 'line.place', 'geometry-horisontal-view', 'Line Place');
select core.insert_file(0,11,112);

select spec.new_connector(121, 0, 'node-connection-connector', '==', 'pairs.copper', 'item-range-connection', 'Copper Pairs Group');
select core.insert_file(0,12,121);
select spec.new_connector(122, 0, 'node-connection-connector', '==', 'ends.cable', 'resource-connection', 'Cable Ends');
select core.insert_file(0,12,122);
select spec.new_connector(123, 0, 'node-connection-connector', '==', 'ends.cable.copper', 'resource-connection', 'Copper Cable Ends');
select core.insert_file(0,12,123);
select spec.new_connector(124, 0, 'node-connection-connector', '==', 'ends.ur', 'resource-connection', 'Ur Ends');
select core.insert_file(0,12,124);


select core.new_folder(2, 0, 'resource-folder-root', 'root', 'Root', 0, true, false);
select core.new_folder(20, 0, 'resource-folder-node', 'std', 'Standard Resource', 0, true, false);
select core.insert_file(0,2,20);
select core.new_folder(200, 0, 'resource-folder-node', 'item-count', 'Item Count', 0, true, false);
select core.insert_file(0,20,200);
select spec.new_rc_item_count(2000, 0, NULL,27, 'facility', '27-optical-fibers', '27 Optical Fibers');
select core.insert_file(0,200,2000);

*/


/*
select spec._add_rclayout_rel('spec.rc_layout'::regclass, 'item-range-root', 'spec.rc_layout'::regclass, 'item-range-node', -1, 'Добавить папку.');
select spec._add_rclayout_rel('spec.rc_layout'::regclass, 'item-range-node', 'spec.rc_layout'::regclass, 'item-range-node', -1, 'Добавить папку.');
select spec._add_rclayout_rel('spec.rc_layout'::regclass, 'item-range-node', 'spec.rc_layout_item_range'::regclass, 'item-range-data', -1, 'Добавить папку.');

select spec.new_rc_layout_node(1,2000,NULL,'item-range-root','all', 0);
select spec.new_rc_layout_node(2,2000,1,'item-range-node','9-red', 0);
select spec.new_rc_layout_node(3,2000,1,'item-range-node','9-green', 0);
select spec.new_rc_layout_node(4,2000,1,'item-range-node','9-blue', 0);
select spec.new_rc_layout_node(5,2000,2,'item-range-node','3-red', 0);
select spec.new_rc_layout_node(6,2000,2,'item-range-node','3-green', 0);
select spec.new_rc_layout_node(7,2000,2,'item-range-node','3-blue', 0);
select spec.new_rc_layout_node(8,2000,3,'item-range-node','3-red', 0);
select spec.new_rc_layout_node(9,2000,3,'item-range-node','3-green', 0);
select spec.new_rc_layout_node(10,2000,3,'item-range-node','3-blue', 0);
select spec.new_rc_layout_node(11,2000,4,'item-range-node','3-red', 0);
select spec.new_rc_layout_node(12,2000,4,'item-range-node','3-green', 0);
select spec.new_rc_layout_node(13,2000,4,'item-range-node','3-blue', 0);
select spec.new_rc_layout_item_range(14,2000,5,'fixed-item-range', '1-red', 1,1, 0);
select spec.new_rc_layout_item_range(15,2000,5,'fixed-item-range','1-green', 2,2, 0);
select spec.new_rc_layout_item_range(16,2000,5,'fixed-item-range','1-blue', 3,3, 0);
select spec.new_rc_layout_item_range(17,2000,6,'fixed-item-range','1-red', 4,4, 0);
select spec.new_rc_layout_item_range(18,2000,6,'fixed-item-range','1-green', 5,5, 0);
select spec.new_rc_layout_item_range(19,2000,6,'fixed-item-range','1-blue', 6,6, 0);
select spec.new_rc_layout_item_range(20,2000,7,'fixed-item-range','1-red', 7,7, 0);
select spec.new_rc_layout_item_range(21,2000,7,'fixed-item-range','1-green', 8,8, 0);
select spec.new_rc_layout_item_range(22,2000,7,'fixed-item-range','1-blue', 9,9, 0);
*/

/*
select core.new_folder(3, 0, 'specification-folder-root', 'root', 'Root', 0, true, false);
select core.new_folder(30, 0, 'specification-folder-node', 'cables', 'Cables', 0, true, false);
select core.insert_file(0,3,30);
select core.new_folder(300, 0, 'specification-folder-node', 'optical', 'Optical', 0, true, false);
select core.insert_file(0,30,300);
select spec.new_specification(3000, 0, 'FLAGS', '27fibers-12mm', '27 Fibers Optical Cable. 12mm.');
select core.insert_file(0,300,3000);

select spec._add_part_rel('spec.part'::regclass, 'group', 'spec.part'::regclass, 'item-count', -1, 'Добавить папку.');
select spec.new_part(1,'group', 3000, NULL, 'shell', NULL);
select spec.new_part(2,'item-count', 3000, 1, 'fiber-count', 2000);

*/


--select spec.part(3000,'shell/fiber-count');
--select spec.rc_layout(2000,'all/9-red/3-blue/1-green', 'spec.rc_layout_item_range'::regclass)
--select core.file_id('connector-folder-root', 'producers/Point Place on Map', 'spec.connector'::regclass);
--select core.file_id('resource-folder-root', 'std/item-count/27-optical-fibers', 'spec.rc_item_count'::regclass);
--select core.file_id('specification-folder-root', 'cables/optical/27fibers-12mm', 'spec.specification'::regclass);

--select core.remove_file(0,300,3000);
--select core.file_pack()
