/*select new_tag(4,NULL,'root-folder', 'Root Folder');
select new_tag(4,NULL,'std-folder', 'Standard Folder');
select new_tag(4,NULL,'port-folder', 'Port Folder');


select _add_file_rel('folder'::regclass, 'root-folder', 'folder'::regclass, 'std-folder', -1, 'Добавить папку.');
select _add_file_rel('folder'::regclass, 'std-folder', 'folder'::regclass, 'std-folder', -1, 'Добавить папку.');
select _add_file_rel('folder'::regclass, 'std-folder', 'folder'::regclass, 'port-folder', -1, 'Добавить папку.');*/

--select core.new_folder(1, 0, 'root-folder', 'root', 'Root', 0, true, false);

/*select new_folder(2, 0, 'std-folder', 'Level1', 'Level 1', 0);
select new_folder(3, 0, 'std-folder', 'Level2', 'Level 2', 0);
select new_folder(4, 0, 'port-folder', 'PortA ', 'Port A', 0);
select new_folder(5, 0, 'port-folder', 'PortB', 'Port B', 0);

--select insert_file(0,1,4); -- ! error !

select insert_file(0,1,2);
select insert_file(0,2,3);
select insert_file(0,3,4);
select insert_file(0,2,5);*/

--select root_file_id('root-folder')
--select file_id('root-folder', 'Level1 / Level2 / PortA', 'folder'::regclass::oid);
--select file_id('root-folder', 'Level1 / PortB');
--select * from child_files(file_id('root-folder', 'Level1'));

--select remove_file(0,1,2);
--select file_pack()
