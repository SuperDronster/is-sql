--select new_tag(NULL,1,'DISTANCE');
--select new_unit(1,'DISTANCE','m', 'Metre', 1.0,1.0, 'F99999999.000', '%s м.', 1, 1);
--select new_unit(2,'DISTANCE','mm', 'Millimeter', 1.0/1000.0,1.0*1000.0, 'F99999999.000', '"%s" мм.', 1, 1);

--select unit_value(1, 'mm')::varchar;

--select * from unit_info('m') 
--select * from unit_id('kg') 
--select * from unit_value(1, 'mm');
--select convert_unit_value(unit_value(1, 'mm'), 'm') 
--select * from unit_value(1, 'kg', true);
--select string(unit_value(1, 'mm', true));
