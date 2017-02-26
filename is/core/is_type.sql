/* -----------------------------------------------------------------------------
	System Functions.
----------------------------------------------------------------------------- */

SET search_path TO "core";

/* -----------------------------------------------------------------------------
	Constant.

----------------------------------------------------------------------------- */

CREATE SEQUENCE attr_def_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;
CREATE SEQUENCE type_def_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TYPE attr_data_type AS ENUM
(
	'boolean',
	'integer',
	'bigint',
	'double',
	'string',
	'record',
	'object'
);

CREATE TABLE _attr_def (
	id integer NOT NULL,
	data_type attr_data_type NOT NULL,
	data_storage varchar NOT NULL,
	unit_ptr integer DEFAULT NULL REFERENCES core.unit(id),
	is_array boolean NOT NULL DEFAULT false,
	domen_name varchar NOT NULL,
	CONSTRAINT _attrdef_pkey PRIMARY KEY (domen_name)
);

CREATE TABLE _type_def (
	id INTEGER NOT NULL,
	system_name VARCHAR(128) NOT NULL,
	visual_name VARCHAR NOT NULL,
	json_desc varchar NOT NULL,
	CONSTRAINT _typedef_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX _typedef_systemname_idx ON _type_def(system_name);

CREATE TABLE _type_attr (
	type_def_ptr INTEGER NOT NULL,
	attr_def_ptr INTEGER NOT NULL,
	system_name VARCHAR(128) NOT NULL,
	visual_name VARCHAR NOT NULL,
	is_nullable boolean NOT NULL DEFAULT false,
	order_index integer NOT NULL DEFAULT 1,

	CONSTRAINT _typeattr_del_fk FOREIGN KEY (type_def_ptr)
		REFERENCES _type_def(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE CASCADE,

	CONSTRAINT _typeattr_pkey PRIMARY KEY (type_def_ptr, attr_def_ptr)
);

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

/* -----------------------------------------------------------------------------
	Создает описание атрибута данных объекта
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION _add_attr_def
(
	p_id integer,
	p_data_type attr_data_type,
	p_unit_name varchar,
	p_data_storage varchar,
	p_domen_name varchar,
	p_is_array boolean DEFAULT false
)
RETURNS integer AS $$
DECLARE
	res_id integer;
	u_id integer;
BEGIN
	IF p_unit_name IS NOT NULL THEN
		u_id := core.unit_id(p_unit_name);
	ELSE
		u_id := NULL;
	END IF;
  IF p_id IS NULL THEN
    res_id := nextval('core.attr_def_id_seq');
  ELSE
    res_id := p_id;
  END IF;

  INSERT INTO core._attr_def
  (
    id, data_type, data_storage, unit_ptr, domen_name, is_array
  )
  VALUES
  (
    res_id, p_data_type, p_data_storage, u_id, p_domen_name,
    p_is_array
  );
  RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	ВозвращаетСоздает ИД записи описание атрибута данных объекта
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION _attr_def_id
(
	p_domen_name varchar
)
RETURNS integer AS $$
BEGIN
  RETURN
    (SELECT id
    FROM core._attr_def
    WHERE
      domen_name = p_domen_name);
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Создает описание интерфейса данных объекта
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION _add_type_def
(
	p_id integer,
	p_system_name varchar(128),
	p_visual_name varchar,
	p_json_desc varchar
)
RETURNS integer AS $$
DECLARE
  res_id integer;
BEGIN
  IF p_id IS NULL THEN
    res_id := nextval('core.type_def_id_seq');
  ELSE
    res_id := p_id;
  END IF;

  INSERT INTO core._type_def
  (
    id, system_name, visual_name, json_desc
  )
  VALUES
  (
    res_id, core.canonical_string(p_system_name),
		p_visual_name, p_json_desc
  );
  RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	ВозвращаетСоздает ИД записи описание интерфейса данных объекта
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION _type_def_id
(
	p_system_name varchar
)
RETURNS integer AS $$
BEGIN
  RETURN
    (SELECT id
    FROM core._type_def
    WHERE
      system_name = p_system_name);
END;
$$ LANGUAGE plpgsql;


/* -----------------------------------------------------------------------------
  Установка атрибута частью интерыейса данных объекта
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION _set_type_attr
(
	p_type_name varchar,
	p_attr_name varchar,
	p_system_name varchar(128),
	p_visual_name varchar,
	p_order_index integer DEFAULT 1,
	p_is_nullable boolean DEFAULT false
)
RETURNS void AS $$
DECLARE
	type_def_id integer := core._type_def_id(core.canonical_string(p_type_name));
	attr_def_id integer := core._attr_def_id(core.canonical_string(p_attr_name));
BEGIN
	IF type_def_id IS NULL THEN
		PERFORM core._error('DeveloperError',
			format('Type %s is not found.',p_type_name));
	END IF;
	IF attr_def_id IS NULL THEN
		PERFORM core._error('DeveloperError',
			format('Attribute %s is not found.',p_attr_name));
	END IF;

	INSERT INTO core._type_attr
	(
		type_def_ptr, attr_def_ptr,
		system_name, visual_name,
		is_nullable, order_index
	)
	VALUES
	(
		type_def_id, attr_def_id,
		p_system_name, p_visual_name,
		p_is_nullable, p_order_index
	);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _type_attr_storage
(
	p_type_name varchar,
	p_attr_name varchar
)
RETURNS varchar AS $$
DECLARE
  t_name varchar;
BEGIN
	RETURN
	(SELECT ad.data_storage
	FROM core._type_attr ta
		JOIN core._type_def td ON (ta.type_def_ptr = td.id)
		JOIN core._attr_def ad ON (ta.attr_def_ptr = ad.id)
	WHERE
		td.system_name = p_type_name AND
		ta.system_name = p_attr_name );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _is_interface_property
(
	p_name name
)
RETURNS boolean AS $$
DECLARE
BEGIN
	IF p_name in ('tableoid', 'cmax', 'xmax', 'cmin', 'xmin', 'ctid') THEN
		RETURN false;
	END IF;
	RETURN SUBSTR(p_name, 1, 1) <> '_';
	RETURN 0;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION core._interface_property_type
(
	p_name name
)
RETURNS varchar AS $$
DECLARE
BEGIN
	CASE p_name
	WHEN 'bool' THEN RETURN 'boolean';
	WHEN 'int8' THEN RETURN 'bigint';
	WHEN 'int4' THEN RETURN 'integer';
	WHEN 'int2' THEN RETURN 'smallint';
	WHEN 'float4' THEN RETURN 'float';
	WHEN 'float8' THEN RETURN 'double';
	WHEN 'numeric' THEN RETURN 'numeric';
	WHEN 'money' THEN RETURN 'money';
	WHEN 'date' THEN RETURN 'date';
	WHEN 'time' THEN RETURN 'time';
	WHEN 'interval' THEN RETURN 'interval';
	WHEN 'varchar' THEN RETURN 'string';
	WHEN 'timestamp' THEN RETURN 'timestamp';
	ELSE
		PERFORM core._error('DeveloperError',
			format('Unsupported interface property type : %s".',p_name));
	END CASE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _public_table_properties
(
	p_toid oid
)
RETURNS
	TABLE(data_type varchar, data_size integer, name varchar,
		is_nullable boolean, is_default boolean) AS $$
SELECT
	core._interface_property_type(t.typname) as data_type,
	t.typlen::integer as data_size,
	a.attname::varchar as name,
	NOT(a.attnotnull) as is_nullable,
	false as is_default
FROM pg_attribute a
	JOIN pg_type t ON (t.oid = a.atttypid)
WHERE
	attrelid = p_toid AND
	core._is_interface_property(a.attname)
ORDER BY
	a.attnum;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION _insert_interface_record
(
	p_type_name varchar,
	p_attr_name varchar,
	p_properties JSON
)
RETURNS bigint AS $$
DECLARE
	s_name varchar = core._type_attr_storage(p_type_name, p_attr_name);
BEGIN
	RETURN 0;
END;
$$ LANGUAGE plpgsql;

/*CREATE OR REPLACE FUNCTION _type_data_storages
(
	p_type_id integer
)
RETURNS SETOF varchar AS $$
DECLARE
  t_name varchar;
BEGIN
	RETURN QUERY
	  SELECT DISTINCT ad.data_storage
	  FROM core._type_attr ta
			JOIN core._attr_def ad
				ON (ta.attr_def_ptr = ad.id)
	  WHERE
	    ia.type_ptr = p_type_id;
END;
$$ LANGUAGE plpgsql;*/

/*CREATE OR REPLACE FUNCTION __delete_static_specrc_interface_data
(
  p_spec_item_id bigint,
  p_resource_id bigint,
  p_interface_id integer
)
RETURNS void AS $$
DECLARE
  t_name varchar;
BEGIN
  SELECT table_name INTO t_name
  FROM _custom_data_interface
  WHERE
    id = p_interface_id;

  EXECUTE
      'DELETE FROM ' || t_name || ' WHERE ' ||
      '_specitem_ptr = ' || p_specitem_id || ' AND ' ||
      '_resource_ptr = ' || p_resource_id;
END;
$$ LANGUAGE plpgsql;*/

/*CREATE OR REPLACE FUNCTION __delete_object_specrc_interface_data
(
  p_object_id bigint,
  p_spec_item_id bigint,
  p_resource_id bigint,
  p_interface_id integer
)
RETURNS void AS $$
DECLARE
  t_name varchar;
BEGIN
  SELECT table_name INTO t_name
  FROM _custom_data_interface
  WHERE
    id = p_interface_id;

  EXECUTE
      'DELETE FROM ' || t_name || ' WHERE ' ||
      '_specitem_ptr = ' || p_specitem_id || ' AND ' ||
      '_resource_ptr = ' || p_resource_id;
END;
$$ LANGUAGE plpgsql;*/
