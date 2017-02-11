/* -----------------------------------------------------------------------------
	Resource File and System
	Constant.
		tag.group_id = 2 (File Kind Tags)
----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_tag('file','kind', NULL, 'resource-folder-root',
	'Resource Folder Root');
SELECT core.new_tag('file','kind', NULL, 'resource-folder-node',
	'Resource Folder Node');

SELECT core.new_tag('file','kind', NULL, 'std-resource', 'Standard Resource');

CREATE SEQUENCE rcdatatype_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TABLE rc_data_type(
	id integer NOT NULL DEFAULT nextval('rcdatatype_id_seq'),
	static_table varchar(48),
	object_table varchar(48),
	visual_name varchar NOT NULL,
	CONSTRAINT rcdatatype_pkey PRIMARY KEY (id)
);

CREATE TABLE resource(
	data_type_ptr integer DEFAULT NULL,
	rc_sides integer NOT NULL,
	CONSTRAINT resource_pkey PRIMARY KEY (file_id)
) INHERITS(core.file);

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION _add_rc_data_type(
	p_id bigint,
	p_static_table varchar(48),
	p_object_table varchar(48),
	p_visual_name varchar DEFAULT NULL
) RETURNS bigint AS $$
DECLARE
	res_id bigint;
BEGIN
	IF p_id IS NULL THEN
		res_id := nextval('core.rcdatatype_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	INSERT INTO spec.rc_data_type
	(
		id, static_table, object_table, visual_name
	)
	VALUES
	(
		res_id, p_static_table, p_object_table,
		p_visual_name
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION __on_before_insert_resource(
	p_file_id bigint
) RETURNS void AS $$
DECLARE
	count integer;
BEGIN
	PERFORM core.__on_before_insert_file(p_file_id);
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_resource(
	p_file_id bigint,
	p_ref_counter bigint
) RETURNS void AS $$
BEGIN
	DELETE FROM spec.rc_layout
	WHERE
		resource_ptr = p_file_id AND
		parent_ptr IS NULL;

	PERFORM core.__on_before_delete_file(p_file_id, p_ref_counter);
END;
$$ LANGUAGE 'plpgsql';
