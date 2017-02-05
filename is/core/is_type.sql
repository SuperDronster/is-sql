/* -----------------------------------------------------------------------------
	System Functions.
----------------------------------------------------------------------------- */

SET search_path TO "core";

/* -----------------------------------------------------------------------------
	Constant.

----------------------------------------------------------------------------- */

CREATE SEQUENCE attr_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;
CREATE SEQUENCE class_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TYPE custom_attribute_type AS ENUM
(
	'boolean_field',
	'integer_field',
	'bigint_field',
	'float_field',
	'string_field'
);

CREATE TYPE custom_interface_type AS ENUM
(
  'specification',
  'static_spec_resource',
  'object_spec_resource',
  'object'
);

CREATE TABLE _custom_data_interface (
  id integer NOT NULL,
  interface_type custom_interface_type,
  table_name VARCHAR(128) NOT NULL,
  visual_name VARCHAR      NOT NULL,
  CONSTRAINT _class_def_pkey PRIMARY KEY (class_id)
);

CREATE TABLE _attribute_def (
  attr_id integer NOT NULL,
  data_type custom_data_type NOT NULL,
  domen_name varchar NOT NULL,
  CONSTRAINT _attribute_def_pkey PRIMARY KEY (domen_name)
);

CREATE TABLE _class_def (
  class_id     INTEGER      NOT NULL,
  class_role   INTEGER      NOT NULL,
  system_name VARCHAR(128) NOT NULL,
  visual_name VARCHAR      NOT NULL,
  CONSTRAINT _class_def_pkey PRIMARY KEY (class_id)
);
CREATE UNIQUE INDEX _classdef_systemname_idx
  ON _class_def (system_name);

CREATE TABLE _class_attribute (
  class_ptr   INTEGER NOT NULL,
  attr_ptr    INTEGER NOT NULL,
  table_name  varchar(48) NOT NULL,
  delete_func varchar(48) NOT NULL,
  CONSTRAINT _classattribute_classdef_fk FOREIGN KEY (class_ptr)
  REFERENCES _class_def (class_id) MATCH SIMPLE
  ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT _classattribute_pkey PRIMARY KEY (class_ptr, attr_ptr)
);

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

/* -----------------------------------------------------------------------------
	Создает разрешение на вставку файла в дерево
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION _add_attr_def
(
  p_id integer,
  p_data_type custom_data_type,
  p_domen_name varchar
)
RETURNS integer AS $$
DECLARE
  res_id integer;
BEGIN
  IF p_id IS NULL THEN
    res_id := nextval('core.attr_id_seq');
  ELSE
    res_id := p_id;
  END IF;

  INSERT INTO core._attribute_def
  (
    attr_id, data_type, domen_name
  )
  VALUES
  (
    res_id, p_data_type, p_domen_name
  );
  RETURN res_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _attr_def(
(
  p_domen_name varchar
)
RETURNS integer AS $$
BEGIN
  RETURN
    (SELECT attr_id
    FROM core._attribute_def
    WHERE
      domen_name = p_domen_name);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _add_class_def
(
  p_id integer,
  p_class_role integer,
  p_system_name varchar(128),
  p_visual_name varchar(128)
)
RETURNS integer AS $$
DECLARE
  res_id integer;
BEGIN
  IF p_id IS NULL THEN
    res_id := nextval('core.class_id_seq');
  ELSE
    res_id := p_id;
  END IF;

  INSERT INTO core._attribute_def
  (
    class_id, class_role, system_name, visual_name
  )
  VALUES
  (
    res_id, p_class_role, p_system_name, p_visual_name
  );
  RETURN res_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _class_def(
(
  p_system_name varchar
)
RETURNS integer AS $$
BEGIN
  RETURN
    (SELECT class_id
    FROM core._class_def
    WHERE
      system_name = p_system_name);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _add_class_attr
(
  p_class_id integer,
  p_attr_id integer,
  p_table_name varchar(48)
)
RETURNS void AS $$
DECLARE
  d_type custom_data_type;
  f_name varchar;
BEGIN
  SELECT data_type INTO d_type
  FROM _attribute_def
  WHERE
    p_attr_id = attr_id;

  CASE d_type
  WHEN 'object_boolean_field' THEN
    f_name := '_on_delete_object_attribute';
  WHEN 'object_integer_field' THEN
    f_name := '_on_delete_object_attribute';
  WHEN 'object_bigint_field' THEN
    f_name := '_on_delete_object_attribute';
  WHEN 'object_float_field' THEN
    f_name := '_on_delete_object_attribute';
  WHEN 'object_string_field' THEN
    f_name := '_on_delete_object_attribute';
  WHEN 'objspecrc_interface' THEN
    f_name := '_on_delete_object_spec_resource_interface';
  WHEN 'spec_interface' THEN
    f_name := '_on_delete_spec_interface';
  WHEN 'oject_interface' THEN
    f_name := '_on_delete_object_interface';
  ELSE
  END CASE;

  INSERT INTO core._class_attribute
  (
    class_ptr, attr_ptr, table_name, delete_func
  )
  VALUES
  (
    p_class_id, p_attr_id, p_table_name,
  );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION __delete_specification_interface_data
(
  p_spec_id bigint
  p_interface_id integer,
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
      '_spec_ptr = ' || p_spec_id;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION __delete_static_specrc_interface_data
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION __delete_object_specrc_interface_data
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
$$ LANGUAGE plpgsql;

  /*SELECT data_type INTO d_type
  FROM _attribute_def
  WHERE
    p_attr_id = attr_id;

  CASE d_type
  WHEN 'object_boolean_field' THEN
    f_name := '_on_delete_object_attribute';
  WHEN 'object_integer_field' THEN
    f_name := '_on_delete_object_attribute';
  WHEN 'object_bigint_field' THEN
    f_name := '_on_delete_object_attribute';
  WHEN 'object_float_field' THEN
    f_name := '_on_delete_object_attribute';
  WHEN 'object_string_field' THEN
    f_name := '_on_delete_object_attribute';
  WHEN 'objspecrc_interface' THEN
    f_name := '_on_delete_object_spec_resource_interface';
  WHEN 'spec_interface' THEN
    f_name := '_on_delete_spec_interface';
  WHEN 'oject_interface' THEN
    f_name := '_on_delete_object_interface';
  ELSE
  END CASE;

  INSERT INTO core._class_attribute
  (
    class_ptr, attr_ptr, table_name, delete_func
  )
  VALUES
  (
    p_class_id, p_attr_id, p_table_name,
  );*/
END;
$$ LANGUAGE plpgsql;
