
/*CREATE TABLE book_table (
	_object_ptr bigint PRIMARY KEY,
	boolean_value BOOLEAN, 
	smallint_value SMALLINT,
	integer_value INTEGER,
	float_value REAL,
	double_value DOUBLE PRECISION,
	string_value VARCHAR(44),
	money_value MONEY,
	numeric_value NUMERIC,
	timestamp_value TIMESTAMP,
	date_value DATE,
	time_value TIME,
	interval_value INTERVAL
);*/

/*CREATE TABLE resource_table (
	_object_ptr bigint PRIMARY KEY,
	_part_ptr bigint,
	_rc_index integer,
	boolean_value BOOLEAN, 
	smallint_value SMALLINT,
	integer_value INTEGER,
	float_value REAL,
	double_value DOUBLE PRECISION,
	string_value VARCHAR(44),
	money_value MONEY,
	numeric_value NUMERIC,
	timestamp_value TIMESTAMP,
	date_value DATE,
	time_value TIME,
	interval_value INTERVAL
);*/

--select core._add_attr_def (1, 'record', 'book_table', NULL, 'interface/book_table');
--select core._add_type_def (1, 'book', 'Book', '');
--select core._set_type_attr('book', 'interface/book_table', 'basic-properties', 'Basic Properties');

select core._insert_object_interface_record('book', 'basic-properties', 
E'
{
"boolean_value": true, 
"smallint_value": 1,
"integer_value": 2,
"float_value": 1.5,
"double_value": 2.2,
"string_value": "s\'tring",
"money_value": 12.34,
"numeric_value": 1002346238767865.34583793478937689768,
"timestamp_value": 12323467,
"interval_value": "1 day",
"date_value": "2017.02.27",
"time_value": "12:45:01"
}'::json,
1
);


--select core._type_attr_storage('public_table', 'common_props');
--select * from core._public_table_properties('core.file'::regclass)
