/* -----------------------------------------------------------------------------
	Resource File and System
	Constant.

----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_tag('file','kind', NULL, 'connector-folder-root',
	'Connector Folder Root');
SELECT core.new_tag('file','kind', NULL, 'connector-folder-node',
	'Connector Folder Node');

SELECT core.new_tag('file','kind', NULL, 'resource-producer-connector-folder', 'Producer');
SELECT core.new_tag('file','kind', NULL, 'resource-consumer-connector-folder', 'Consumer');
SELECT core.new_tag('file','kind', NULL, 'node-connection-connector-folder', 'Connection');
SELECT core.new_tag('file','kind', NULL, 'edge-connection-connector-folder', 'Connection');
SELECT core.new_tag('file','kind', NULL, 'network-connection-connector-folder', 'Connection');
SELECT core.new_tag('file','kind', NULL, 'association-connector-folder', 'Association');

SELECT core.new_tag('file','kind', NULL, 'resource-producer-connector', 'Producer');
SELECT core.new_tag('file','kind', NULL, 'resource-consumer-connector', 'Consumer');
SELECT core.new_tag('file','kind', NULL, 'node-connection-connector', 'Connection');
SELECT core.new_tag('file','kind', NULL, 'edge-connection-connector', 'Connection');
SELECT core.new_tag('file','kind', NULL, 'network-connection-connector', 'Connection');
SELECT core.new_tag('file','kind', NULL, 'association-connector', 'Association');

SELECT core.new_pool(NULL, 'connector','group-type', 'Connector Group Types.',0);
SELECT core.new_tag('connector','group-type', NULL, 'geometry-vertical-view',
	'Geometry Vertical View');
SELECT core.new_tag('connector','group-type', NULL, 'geometry-horisontal-view',
	'Geometry Horisontal View');
SELECT core.new_tag('connector','group-type', NULL, 'item-range-connection',
	'Item Range Connection');
SELECT core.new_tag('connector','group-type', NULL, 'resource-connection',
	'Resource Connection');

SELECT core.new_pool(NULL, 'connector','rc-rel-type', 'Resource Relation Types.',0);
SELECT core.new_tag('connector','rc-rel-type', NULL, '>=', 'Bigger and Equals');
SELECT core.new_tag('connector','rc-rel-type', NULL, '<=', 'Litlle and Equals');
SELECT core.new_tag('connector','rc-rel-type', NULL, '==', 'Equals');
SELECT core.new_tag('connector','rc-rel-type', NULL, 'any', 'Any');

CREATE TABLE connector(
	group_type bigint NOT NULL REFERENCES core.tag(id),
	rc_rel_type bigint NOT NULL REFERENCES core.tag(id),
	domen_name varchar NOT NULL,

	-- Нельзя удалять тег - вид файла
	CONSTRAINT connector_filekind_fk FOREIGN KEY (file_kind)
		REFERENCES core.tag(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,
	CONSTRAINT connector_pkey PRIMARY KEY (file_id)
) INHERITS(core.file);

CREATE INDEX connector_systemname_idx ON connector(system_name);

-- Triggers

CREATE OR REPLACE FUNCTION __on_before_insert_connector_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_insert_connector(NEW.file_id);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_connector_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_delete_connector(OLD.file_id,OLD.ref_counter);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER before_delete_connector_trigger
	BEFORE DELETE ON connector FOR EACH ROW
	EXECUTE PROCEDURE __on_before_delete_connector_trigger();

CREATE TRIGGER before_insert_connector_trigger
	BEFORE INSERT ON connector FOR EACH ROW
	EXECUTE PROCEDURE __on_before_insert_connector_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_before_insert_connector(
	p_file_id bigint
) RETURNS void AS $$
DECLARE
	count integer;
BEGIN
	PERFORM core.__on_before_insert_file(p_file_id);
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_connector(
	p_file_id bigint,
	p_ref_counter bigint
) RETURNS void AS $$
BEGIN
	PERFORM core.__on_before_delete_file(p_file_id, p_ref_counter);
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Создание файла - кол-ва ресурса
---------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_connector(
	p_id bigint,
	p_creator_id integer,
	p_kind_tag_name varchar(128),
	p_rcreltype_tag_name varchar(128),
	p_domen_name varchar,
	p_group_type_tag_name varchar(128),
	p_system_name varchar(128) DEFAULT NULL,
	p_visual_name varchar DEFAULT NULL,
	p_color integer DEFAULT 0,
	p_is_readonly boolean DEFAULT true,
	p_is_packable boolean DEFAULT true
) RETURNS bigint AS $$
DECLARE
	res_id bigint;
	v_name varchar;
	s_name varchar;
BEGIN
	IF p_id IS NULL THEN
		res_id := nextval('core.file_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	IF p_system_name IS NULL THEN
		s_name := p_domen_name;
	ELSE
		s_name := p_system_name;
	END IF;
	IF p_visual_name IS NULL THEN
		v_name := s_name;
	ELSE
		v_name := p_visual_name;
	END IF;

	INSERT INTO spec.connector
	(
		file_id, creator_id, file_kind, domen_name, group_type, rc_rel_type,
		system_name, visual_name, is_packable, is_readonly, color
	)
	VALUES
	(
		res_id, p_creator_id, core.tag_id('file','kind', p_kind_tag_name),
		p_domen_name, core.tag_id('connector','group-type', p_group_type_tag_name),
		core.tag_id('connector','rc-rel-type', p_rcreltype_tag_name),
		core.canonical_string(s_name), v_name, p_is_packable, p_is_readonly, p_color
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;
