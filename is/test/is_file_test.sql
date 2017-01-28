/*
select core.new_tag(7,NULL,'geometry-vertical-view', 'Geometry Vertical Projection');
select core.new_tag(7,NULL,'geometry-horisontal-view', 'Geometry Horisontal Projection');
select core.new_tag(7,NULL,'item-range-connection', 'Item Range Connection');  
select core.new_tag(7,NULL,'resource-connection', 'Resource Body Connection');

select core.new_tag(5,NULL, 'facility','Facility');
select core.new_tag(4,NULL, 'all','All Items');
select core.new_tag(4,NULL, '9-red','9 Red Group');
select core.new_tag(4,NULL, '9-green','9 Green Group');
select core.new_tag(4,NULL, '9-blue','9 Blue Group');
select core.new_tag(4,NULL, '3-red','3 Red Group');
select core.new_tag(4,NULL, '3-green','3 Green Group');
select core.new_tag(4,NULL, '3-blue','3 Blue Group');
select core.new_tag(4,NULL, '1-red','1 Red');
select core.new_tag(4,NULL, '1-green','1 Green');
select core.new_tag(4,NULL, '1-blue','1 Blue');

select core.new_tag(2,NULL,'cnr-root', 'Root Connector Folder');
select core.new_tag(2,NULL,'spc-root', 'Root Specification Folder');
select core.new_tag(2,NULL,'spc-node', 'Node Specification Folder');
select core.new_tag(2,NULL,'rsc-root', 'Root Resource Folder');
select core.new_tag(2,NULL,'rsc-node', 'Node Resource Folder');


select core._add_file_rel('core.folder'::regclass, 'cnr-root', 'core.folder'::regclass, 'rc-producer-connector', 1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'cnr-root', 'core.folder'::regclass, 'rc-consumer-connector', 1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'cnr-root', 'core.folder'::regclass, 'rc-connection-connector', 1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'cnr-root', 'core.folder'::regclass, 'rc-assoc-connector', 1, 'Добавить папку.');

select core._add_file_rel('core.folder'::regclass, 'spc-root', 'core.folder'::regclass, 'spc-node', -1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'rsc-root', 'core.folder'::regclass, 'rsc-node', -1, 'Добавить папку.');

select core._add_file_rel('core.folder'::regclass, 'rc-producer-connector', 'core.folder'::regclass, 'rc-producer-connector', -1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'rc-producer-connector', 'spec.connector'::regclass, 'rc-producer-connector', -1, 'Добавить файл.');
select core._add_file_rel('core.folder'::regclass, 'rc-consumer-connector', 'core.folder'::regclass, 'rc-consumer-connector', -1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'rc-consumer-connector', 'spec.connector'::regclass, 'rc-consumer-connector', -1, 'Добавить файл.');
select core._add_file_rel('core.folder'::regclass, 'rc-connection-connector', 'core.folder'::regclass, 'rc-connection-connector', -1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'rc-connection-connector', 'spec.connector'::regclass, 'rc-connection-connector', -1, 'Добавить файл.');
select core._add_file_rel('core.folder'::regclass, 'rc-assoc-connector', 'core.folder'::regclass, 'rc-assoc-connector', -1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'rc-assoc-connector', 'spec.connector'::regclass, 'rc-assoc-connector', -1, 'Добавить файл.');

select core._add_file_rel('core.folder'::regclass, 'rsc-node', 'core.folder'::regclass, 'rsc-node', -1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'rsc-node', 'spec.rc_item_count'::regclass, 'default-resource', -1, 'Добавить папку.');

select core._add_file_rel('core.folder'::regclass, 'spc-node', 'core.folder'::regclass, 'spc-node', -1, 'Добавить папку.');
select core._add_file_rel('core.folder'::regclass, 'spc-node', 'spec.specification'::regclass, 'default-specification', -1, 'Добавить папку.');

select core.new_folder(1, 0, 'cnr-root', 'root', 'Root', 0, true, false);
select core.new_folder(10, 0, 'rc-producer-connector', 'producers', 'Producers Connector', 0, true, false);
select core.insert_file(0,1,10); 

select core.new_folder(11, 0, 'rc-consumer-connector', 'consumers', 'Consumers Connector', 0, true, false);
select core.insert_file(0,1,11);
select core.new_folder(12, 0, 'rc-connection-connector', 'connection', 'Connection Connector', 0, true, false);
select core.insert_file(0,1,12); 

select spec.new_connector(101, 0, 'rc-producer-connector', 'poin.place.map', 'geometry-horisontal-view', 'Point Place on Map');
select core.insert_file(0,10,101);
select spec.new_connector(102, 0, 'rc-producer-connector', 'line.place.map', 'geometry-horisontal-view', 'Line Place on Map');
select core.insert_file(0,10,102);

select spec.new_connector(111, 0, 'rc-consumer-connector', 'point.place', 'geometry-horisontal-view', 'Point Place');
select core.insert_file(0,11,111);
select spec.new_connector(112, 0, 'rc-consumer-connector', 'line.place', 'geometry-horisontal-view', 'Line Place');
select core.insert_file(0,11,112);

select spec.new_connector(121, 0, 'rc-connection-connector', 'pairs.copper', 'item-range-connection', 'Copper Pairs Group');
select core.insert_file(0,12,121);
select spec.new_connector(122, 0, 'rc-connection-connector', 'ends.cable', 'resource-connection', 'Cable Ends');
select core.insert_file(0,12,122);
select spec.new_connector(123, 0, 'rc-connection-connector', 'ends.cable.copper', 'resource-connection', 'Copper Cable Ends');
select core.insert_file(0,12,123);
select spec.new_connector(124, 0, 'rc-connection-connector', 'ends.ur', 'resource-connection', 'Ur Ends');
select core.insert_file(0,12,124); 


select core.new_folder(2, 0, 'rsc-root', 'root', 'Root', 0, true, false);
select core.new_folder(20, 0, 'rsc-node', 'std', 'Standard Resource', 0, true, false);
select core.insert_file(0,2,20); 
select core.new_folder(200, 0, 'rsc-node', 'item-count', 'Item Count', 0, true, false);
select core.insert_file(0,20,200);
select spec.new_rc_item_count(2000, 0, NULL,27, 'facility', '27-optical-fibers', '27 Optical Fibers');
select core.insert_file(0,200,2000);

select spec._add_rclayout_rel('spec.rc_layout'::regclass, 'item-range-root', 'spec.rc_layout'::regclass, 'item-range-node', -1, 'Добавить папку.');
select spec._add_rclayout_rel('spec.rc_layout'::regclass, 'item-range-node', 'spec.rc_layout'::regclass, 'item-range-node', -1, 'Добавить папку.');

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
select spec.new_rc_layout_item_range(14,2000,5,'1-red', 1,1, 0);
select spec.new_rc_layout_item_range(15,2000,5,'1-green', 2,2, 0);
select spec.new_rc_layout_item_range(16,2000,5,'1-blue', 3,3, 0);
select spec.new_rc_layout_item_range(17,2000,6,'1-red', 4,4, 0);
select spec.new_rc_layout_item_range(18,2000,6,'1-green', 5,5, 0);
select spec.new_rc_layout_item_range(19,2000,6,'1-blue', 6,6, 0);
select spec.new_rc_layout_item_range(20,2000,7,'1-red', 7,7, 0);
select spec.new_rc_layout_item_range(21,2000,7,'1-green', 8,8, 0);
select spec.new_rc_layout_item_range(22,2000,7,'1-blue', 9,9, 0);*/

--select spec.rc_layout(2000,'all/9-red/3-blue/1-green', 'spec.rc_layout_item_range'::regclass)
--select core.file_id('cnr-root', 'producers/point-place-on-map', 'spec.connector'::regclass);
--select core.file_id('rsc-root', 'std/item-count/27-optical-fibers', 'spec.rc_item_count'::regclass);

--select remove_file(0,1,2);
--select file_pack()
