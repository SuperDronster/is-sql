/* -----------------------------------------------------------------------------
	resources File and System
	Constant.

----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_tag('file','kind', NULL, 'c', 'Connector Folder Root');
SELECT core.new_tag('file','kind', NULL, 'connector-group',
	'Connector Group');

SELECT core.new_tag('file','kind', NULL, 'resource-produce-connector-group',
	'Resource Produce Connector Group');
SELECT core.new_tag('file','kind', NULL, 'resource-consume-connector-group',
	'Resource Consume Connector Group');
SELECT core.new_tag('file','kind', NULL, 'node-connection-connector-group',
	'Node Connection Connector Group');
SELECT core.new_tag('file','kind', NULL, 'edge-connection-connector-group',
	'Edge Connection Connector Group');
SELECT core.new_tag('file','kind', NULL, 'network-connection-connector-group',
	'Network Connection Connector Group');
SELECT core.new_tag('file','kind', NULL, 'resource-assoc-connector-group',
	'Resource Association Connector Group');

SELECT core.new_tag('file','kind', NULL, 'resource-produce-connector-object',
	'Resource Produce Connector Object');
SELECT core.new_tag('file','kind', NULL, 'resource-consume-connector-object',
	'Resource Consume Connector Object');
SELECT core.new_tag('file','kind', NULL, 'node-connection-connector-object',
	'Node Connection Connector Object');
SELECT core.new_tag('file','kind', NULL, 'edge-connection-connector-object',
	'Edge Connection Connector Object');
SELECT core.new_tag('file','kind', NULL, 'network-connection-connector-object',
	'Network Connection Connector Object');
SELECT core.new_tag('file','kind', NULL, 'resource-assoc-connector-object',
	'Resource Association Connector Object');

CREATE TYPE connector_kind AS ENUM
(
	'resource-assoc',
	'resource-produce',
	'resource-consume',
	'node-connection',
	'edge-connection',
	'network-connection'
);

CREATE TYPE connector_group_type AS ENUM
(
	'information-capacity',
	'vertical-view',
	'horisontal-view',
	'section-view',
	'resource-connection',
	'range-connection'
);
CREATE TYPE connector_rc_rel_type AS ENUM
(
	'>=',
	'<=',
	'==',
	'any'
);

/*SELECT core.new_pool(NULL, 'connector','group-type', 'Connector Group Types.',0);
SELECT core.new_tag('connector','group-type', NULL, 'geometry-vertical-view',
	'Geometry Vertical View');
SELECT core.new_tag('connector','group-type', NULL, 'geometry-horisontal-view',
	'Geometry Horisontal View');
SELECT core.new_tag('connector','group-type', NULL, 'item-range-connection',
	'Item Range Connection');
SELECT core.new_tag('connector','group-type', NULL, 'resources-connection',
	'resources Connection');

SELECT core.new_pool(NULL, 'connector','rc-rel-type', 'resources Relation Types.',0);
SELECT core.new_tag('connector','rc-rel-type', NULL, '>=', 'Bigger and Equals');
SELECT core.new_tag('connector','rc-rel-type', NULL, '<=', 'Litlle and Equals');
SELECT core.new_tag('connector','rc-rel-type', NULL, '==', 'Equals');
SELECT core.new_tag('connector','rc-rel-type', NULL, 'any', 'Any');*/

CREATE TABLE connector(
	kind connector_kind NOT NULL,
	group_type connector_group_type NOT NULL,
	rc_rel_type connector_rc_rel_type,
	domen_name varchar NOT NULL NOT NULL,

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
	p_kind connector_kind,
	p_group_type connector_group_type,
	p_rc_rel_type connector_rc_rel_type,
	p_domen_name varchar,
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
	tag_id bigint;
BEGIN
	IF p_id IS NULL THEN
		res_id := nextval('core.file_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	CASE p_kind
	WHEN 'resource-assoc' THEN
		tag_id := core.tag_id('file','kind', 'resource-assoc-connector-object');
	WHEN 'resource-produce' THEN
		tag_id := core.tag_id('file','kind', 'resource-produce-connector-object');
	WHEN 'resource-consume' THEN
		tag_id := core.tag_id('file','kind', 'resource-consume-connector-object');
	WHEN 'node-connection' THEN
		tag_id := core.tag_id('file','kind', 'node-connection-connector-object');
	WHEN 'edge-connection' THEN
		tag_id := core.tag_id('file','kind', 'edge-connection-connector-object');
	WHEN 'network-connection' THEN
		tag_id := core.tag_id('file','kind', 'network-connection-connector-object');
	ELSE
		PERFORM _error('DeveloperError', 'Wrong Connector Kind value!');
	END CASE;

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
		file_id, creator_id, file_kind, domen_name, kind,
		group_type, rc_rel_type,
		system_name, visual_name, is_packable, is_readonly,
		color
	)
	VALUES
	(
		res_id, p_creator_id, tag_id,
		p_domen_name, p_kind, p_group_type,p_rc_rel_type,
		core.canonical_string(s_name),
		v_name, p_is_packable, p_is_readonly, p_color
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Initial Data
---------------------------------------------------------------------------- */

SELECT core._add_file_rel
(
	'core.folder'::regclass, 'c',
	'core.folder'::regclass, 'connector-group',
	-1, 'Add Connector Group.'
);

SELECT core._add_file_rel
(
	'core.folder'::regclass, 'connector-group',
	'core.folder'::regclass, 'connector-group',
	-1, 'Add Connector Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'connector-group',
	'spec.connector'::regclass, 'resource-produce-connector-object',
	-1, 'Add Resource Produce Connector Object.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'connector-group',
	'spec.connector'::regclass, 'resource-consume-connector-object',
	-1, 'Add Resource Consume Connector Object.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'connector-group',
	'spec.connector'::regclass, 'node-connection-connector-object',
	-1, 'Add Node Connection Connector Object.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'connector-group',
	'spec.connector'::regclass, 'edge-connection-connector-object',
	-1, 'Add Edge Connection Connector Object.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'connector-group',
	'spec.connector'::regclass, 'network-connection-connector-object',
	-1, 'Add Network Connection Connector Object.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'connector-group',
	'spec.connector'::regclass, 'resource-assoc-connector-object',
	-1, 'Add Resource Association Connector Object.'
);

SELECT core._add_file_rel
(
	'core.folder'::regclass, 'c',
	'core.folder'::regclass, 'resource-produce-connector-group',
	-1, 'Add Resource Produce Connector Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'c',
	'core.folder'::regclass, 'resource-consume-connector-group',
	-1, 'Add Resource Consume Connector Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'c',
	'core.folder'::regclass, 'node-connection-connector-group',
	-1, 'Add Node Connection Connector Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'c',
	'core.folder'::regclass, 'edge-connection-connector-group',
	-1, 'Add Edge Connection Connector Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'c',
	'core.folder'::regclass, 'network-connection-connector-group',
	-1, 'Add Network Connection Connector Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'c',
	'core.folder'::regclass, 'resource-assoc-connector-group',
	-1, 'Add Resource Assoc Connector Group.'
);

SELECT core._add_file_rel
(
	'core.folder'::regclass, 'connector-group',
	'core.folder'::regclass, 'resource-produce-connector-group',
	-1, 'Add Resource Produce Connector Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'connector-group',
	'core.folder'::regclass, 'resource-consume-connector-group',
	-1, 'Add Resource Consume Connector Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'connector-group',
	'core.folder'::regclass, 'node-connection-connector-group',
	-1, 'Add Node Connection Connector Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'connector-group',
	'core.folder'::regclass, 'edge-connection-connector-group',
	-1, 'Add Edge Connection Connector Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'connector-group',
	'core.folder'::regclass, 'network-connection-connector-group',
	-1, 'Add Network Connection Connector Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'connector-group',
	'core.folder'::regclass, 'resource-assoc-connector-group',
	-1, 'Add Resource Assoc Connector Group.'
);


SELECT core._add_file_rel
(
	'core.folder'::regclass, 'resource-produce-connector-group',
	'spec.connector'::regclass, 'resource-produce-connector-object',
	-1, 'Add Resource Produce Connector Object.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'resource-consume-connector-group',
	'spec.connector'::regclass, 'resource-consume-connector-object',
	-1, 'Add Resource Consume Connector Object.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'node-connection-connector-group',
	'spec.connector'::regclass, 'node-connection-connector-object',
	-1, 'Add Node Connection Connector Object.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'edge-connection-connector-group',
	'spec.connector'::regclass, 'edge-connection-connector-object',
	-1, 'Add Edge Connection Connector Object.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'network-connection-connector-group',
	'spec.connector'::regclass, 'network-connection-connector-object',
	-1, 'Add Network Connection Connector Object.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'resource-assoc-connector-group',
	'spec.connector'::regclass, 'resource-assoc-connector-object',
	-1, 'Add Resource Association Connector Object.'
);
