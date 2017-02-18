/* -----------------------------------------------------------------------------
	resources File and System
	Constant.
		tag.group_id = 2 (File Kind Tags)
----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_tag('file','kind', NULL, 'r', 'Resources Folder Root');
SELECT core.new_tag('file','kind', NULL, 'resources-group',
	'Resources Group');
SELECT core.new_tag('file','kind', NULL, 'unvalued-items-resources-group',
	'Unvalued Items Reources Object');
SELECT core.new_tag('file','kind', NULL, 'unvalued-items-resources-object',
	'Unvalued Items Reources Object');

CREATE SEQUENCE rcdatatype_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TABLE rc_data_type(
	id integer NOT NULL DEFAULT nextval('rcdatatype_id_seq'),
	static_table varchar(48),
	object_table varchar(48),
	visual_name varchar NOT NULL,
	CONSTRAINT rcdatatype_pkey PRIMARY KEY (id)
);

CREATE SEQUENCE rcside_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TABLE rc_side
(
	id integer NOT NULL DEFAULT nextval('rcside_id_seq'),
	pool_ptr integer NOT NULL,
	connection_channel integer DEFAULT NULL,
	system_name varchar(128) NOT NULL,
	visual_name varchar NOT NULL,

	-- Удалять все ключи при удалении пула - перечисления
	CONSTRAINT rcside_del_fk FOREIGN KEY (pool_ptr)
		REFERENCES core.pool(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE CASCADE,

	CONSTRAINT rcside_pkey PRIMARY KEY (id)
);

CREATE TABLE resources(
	data_type_ptr integer DEFAULT NULL REFERENCES spec.rc_data_type(id),
	rc_sides integer NOT NULL REFERENCES core.pool(id),
	rc_count integer NOT NULL DEFAULT 1,
	CONSTRAINT resources_pkey PRIMARY KEY (file_id)
) INHERITS(core.file);


CREATE OR REPLACE FUNCTION __on_before_insert_resources_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_insert_resources(NEW.file_id);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_resources_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_delete_resources(OLD.file_id,OLD.ref_counter);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER before_insert_resources_trigger
	BEFORE INSERT ON resources FOR EACH ROW
	EXECUTE PROCEDURE __on_before_insert_resources_trigger();
CREATE TRIGGER before_delete_resources_trigger
	BEFORE DELETE ON resources FOR EACH ROW
	EXECUTE PROCEDURE __on_before_delete_resources_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_before_insert_resources(
	p_file_id bigint
) RETURNS void AS $$
DECLARE
	count integer;
BEGIN
	PERFORM core.__on_before_insert_file(p_file_id);
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_resources(
	p_file_id bigint,
	p_ref_counter bigint
) RETURNS void AS $$
BEGIN
	DELETE FROM spec.rc_layout
	WHERE
		resources_ptr = p_file_id AND
		parent_ptr IS NULL;

	PERFORM core.__on_before_delete_file(p_file_id, p_ref_counter);
END;
$$ LANGUAGE 'plpgsql';

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

CREATE  OR REPLACE FUNCTION new_rc_side
(
	p_id integer,
	p_role_key varchar(32),
	p_pool_key varchar(32),
	p_system_name varchar(128),
	p_visual_name varchar,
	p_connection_channel integer DEFAULT NULL
) RETURNS integer AS $$
DECLARE
	res_id integer;
BEGIN
	IF p_id IS NULL THEN
		res_id := nextval('core.rcside_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	INSERT INTO core.rc_side
	(
		id,
		pool_ptr, connection_channel, system_name,
		visual_name
	)
	VALUES
	(
		p_id,
		core.pool_id(p_role_key, p_pool_key),
		p_connection_channel, p_system_name,
		p_visual_name
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

CREATE  OR REPLACE FUNCTION new_rc_side
(
	p_id integer,
	p_pool_id integer,
	p_system_name varchar(128),
	p_visual_name varchar,
	p_connection_channel integer DEFAULT NULL
) RETURNS integer AS $$
DECLARE
	res_id integer;
BEGIN
	IF p_id IS NULL THEN
		res_id := nextval('core.rcside_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	INSERT INTO core.rc_side
	(
		id,
		pool_ptr, connection_channel, system_name,
		visual_name
	)
	VALUES
	(
		p_id, p_pool_id,
		p_connection_channel, p_system_name,
		p_visual_name
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

CREATE  OR REPLACE FUNCTION rc_side_id(
	p_role_key varchar(32),
	p_pool_key varchar(32),
	p_system_name varchar(128)
) RETURNS integer AS $$
DECLARE
	pool_id integer := core.pool_id(p_role_key, p_pool_key);
BEGIN
	RETURN
		(SELECT id
		FROM core.rc_side
		WHERE
		 	pool_ptr = pool_id AND
			system_name = p_system_name);
END;
$$ LANGUAGE plpgsql;

CREATE  OR REPLACE FUNCTION rc_side_id(
	p_pool_id integer,
	p_system_name varchar(128)
) RETURNS integer AS $$
BEGIN
	RETURN
		(SELECT id
		FROM core.rc_side
		WHERE
		 	pool_ptr = p_pool_id AND
			system_name = p_system_name);
END;
$$ LANGUAGE plpgsql;

CREATE  OR REPLACE FUNCTION rc_side_name(
	p_id integer
) RETURNS varchar AS $$
BEGIN
	RETURN
		(SELECT visual_name
		FROM core.rc_side
		WHERE
		 	id = p_id);
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Создание файла - кол-ва ресурса
---------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_resources(
	p_id bigint,
	p_creator_id integer,
	p_data_type_id integer,
	p_count integer,
	p_sides_pool_name varchar(128),
	p_system_name varchar(128),
	p_visual_name varchar DEFAULT NULL,
	p_color integer DEFAULT 0,
	p_is_readonly boolean DEFAULT true,
	p_is_packable boolean DEFAULT true
) RETURNS bigint AS $$
DECLARE
	res_id bigint;
	name varchar;
BEGIN
	IF p_id IS NULL THEN
		res_id := nextval('core.file_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	IF p_visual_name IS NULL THEN
		name := p_system_name;
	ELSE
		name := p_visual_name;
	END IF;

	INSERT INTO spec.resources
	(
		file_id, creator_id, data_type_ptr, file_kind, system_name, visual_name,
		is_packable, is_readonly, color, rc_sides, rc_count
	)
	VALUES
	(
		res_id, p_creator_id, p_data_type_id,
		core.tag_id('file','kind', 'unvalued-items-resources-object'),
    core.canonical_string(p_system_name), name, p_is_packable,
		p_is_readonly, p_color, core.pool_id('rc-sides', p_sides_pool_name),
		p_count
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Initial Data
---------------------------------------------------------------------------- */

SELECT core._add_file_rel
(
	'core.folder'::regclass, 'r',
	'core.folder'::regclass, 'resources-group',
	-1, 'Add Resources Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'resources-group',
	'core.folder'::regclass, 'resources-group',
	-1, 'Add Resources Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'resources-group',
	'spec.resources'::regclass, 'unvalued-items-resources-object',
	-1, 'Add Anvalued Item resources Object.'
);
