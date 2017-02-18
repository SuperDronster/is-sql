/* -----------------------------------------------------------------------------
	System Functions.
----------------------------------------------------------------------------- */

SET search_path TO "spec";

/* -----------------------------------------------------------------------------
	Constant.

----------------------------------------------------------------------------- */

CREATE SEQUENCE attr_def_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;
CREATE SEQUENCE interface_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TYPE attribute_data_type AS ENUM
(
	'boolean',
	'integer',
	'bigint',
	'double',
	'string',
	'record',
	'object'
);

CREATE TABLE _attribute_def (
	id integer NOT NULL,
	data_type attribute_data_type NOT NULL,
	data_storage varchar NOT NULL,
	unit_ptr integer DEFAULT NULL REFERENCES core.unit(id),
	is_array boolean NOT NULL DEFAULT false,
	domen_name varchar NOT NULL,
	CONSTRAINT _attributedef_pkey PRIMARY KEY (domen_name)
);

CREATE TABLE _interface_def (
	id INTEGER NOT NULL,
	system_name VARCHAR(128) NOT NULL,
	visual_name VARCHAR NOT NULL,
	json_desc varchar NOT NULL,
	CONSTRAINT _interfacedef_pkey PRIMARY KEY (id)
);
CREATE UNIQUE INDEX _interfacedef_systemname_idx ON _interface_def(system_name);

CREATE TABLE _interface_attr (
	interface_ptr INTEGER NOT NULL,
	attr_def_ptr INTEGER NOT NULL,
	is_nullable boolean NOT NULL DEFAULT false,
	order_index integer NOT NULL DEFAULT 1,

	CONSTRAINT _interfaceattr_interface_fk FOREIGN KEY (interface_ptr)
		REFERENCES _interface_def(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE CASCADE,

	CONSTRAINT _interfaceattr_pkey PRIMARY KEY (interface_ptr, attr_def_ptr)
);

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

/* -----------------------------------------------------------------------------
	Создает описание атрибута данных объекта
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION _add_attribute_def
(
	p_id integer,
	p_data_type attribute_data_type,
	p_data_storage varchar,
	p_unit_name varchar,
	p_domen_name varchar,
	p_is_array boolean DEFAULT false
)
RETURNS integer AS $$
DECLARE
  res_id integer;
BEGIN
  IF p_id IS NULL THEN
    res_id := nextval('spec.attr_def_id_seq');
  ELSE
    res_id := p_id;
  END IF;

  INSERT INTO spec._attribute_def
  (
    id, data_type, data_storage, unit_ptr, domen_name, is_array
  )
  VALUES
  (
    res_id, p_data_type, p_data_storage, core.unit_id(p_unit_name),
		p_domen_name, p_is_array
  );
  RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	ВозвращаетСоздает ИД записи описание атрибута данных объекта
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION _attribute_def_id
(
	p_domen_name varchar
)
RETURNS integer AS $$
BEGIN
  RETURN
    (SELECT id
    FROM spec._attribute_def
    WHERE
      domen_name = p_domen_name);
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Создает описание интерфейса данных объекта
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION _add_interface_def
(
	p_id integer,
	p_class_role integer,
	p_system_name varchar(128),
	p_visual_name varchar,
	p_json_desc varchar
)
RETURNS integer AS $$
DECLARE
  res_id integer;
BEGIN
  IF p_id IS NULL THEN
    res_id := nextval('interface_id_seq');
  ELSE
    res_id := p_id;
  END IF;

  INSERT INTO spec._attribute_def
  (
    id, system_name, visual_name, json_desc
  )
  VALUES
  (
    res_id, core.canonical(p_system_name),
		p_visual_name, p_json_desc
  );
  RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	ВозвращаетСоздает ИД записи описание интерфейса данных объекта
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION _interface_def_id
(
	p_system_name varchar
)
RETURNS integer AS $$
BEGIN
  RETURN
    (SELECT id
    FROM spec._interface_def
    WHERE
      system_name = p_system_name);
END;
$$ LANGUAGE plpgsql;


/* -----------------------------------------------------------------------------
  Установка атрибута частью интерыейса данных объекта
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION _set_interface_attr
(
	p_interface_name varchar,
	p_attr_def_name varchar,
	p_order_index integer DEFAULT 1,
	p_is_nullable boolean DEFAULT false
)
RETURNS void AS $$
DECLARE
  i_name varchar := core.canonical(p_interface_name);
BEGIN
  INSERT INTO spec._interface_attr
  (
    interface_ptr, attr_def_ptr, is_nullable, order_index
  )
  VALUES
  (
    spec.interface_def_id(core.canonical(i_name)),
		spec.attribute_def_id(p_attr_def_name),
		p_is_nullable, p_order_index
  );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _interface_storage_names
(
	p_spec_id bigint,
	p_interface_id integer
)
RETURNS SETOF varchar AS $$
DECLARE
  t_name varchar;
BEGIN
	RETURN QUERY
	  SELECT attrdef.data_storage
	  FROM spec._interface_attr iattr
			JOIN spec._attribute_def attrdef 
				ON (iattr.attr_def_ptr = attrdef.id)
	  WHERE
	    iattr.interface_ptr = p_interface_id;
END;
$$ LANGUAGE plpgsql;

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
