/* -----------------------------------------------------------------------------
	resources File and System
	Constant.

----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_tag('file','kind', NULL, 'c', 'Class Folder Root');
SELECT core.new_tag('file','kind', NULL, 'class-group',
	'Class Group');

SELECT core.new_tag('file','kind', NULL, 'standard-class-object',
	'Standard Class Object');

CREATE TYPE class_object_kind AS ENUM
(
	'information',
	'node',
	'facility',
	'network'
);

CREATE TABLE class(
	interface_ptr integer DEFAULT NULL REFERENCES spec._interface_def(id),
	spec_folder_ptr bigint DEFAULT NULL,
	object_kind class_object_kind NOT NULL,
	object_role integer DEFAULT NULL REFERENCES core.pool(id),
	object_state integer DEFAULT NULL REFERENCES core.pool(id),

	-- Нельзя удалять тег - вид файла
	CONSTRAINT class_filekind_fk FOREIGN KEY (file_kind)
		REFERENCES core.tag(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,

	CONSTRAINT class_pkey PRIMARY KEY (file_id)
) INHERITS(core.file);

CREATE INDEX class_systemname_idx ON class(system_name);

-- Triggers

CREATE OR REPLACE FUNCTION __on_before_insert_class_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_insert_class(NEW.file_id, NEW.spec_folder_ptr);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_class_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_delete_class(OLD.file_id,OLD.ref_counter,
		NEW.spec_folder_ptr);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER before_delete_class_trigger
	BEFORE DELETE ON class FOR EACH ROW
	EXECUTE PROCEDURE __on_before_delete_class_trigger();

CREATE TRIGGER before_insert_class_trigger
	BEFORE INSERT ON class FOR EACH ROW
	EXECUTE PROCEDURE __on_before_insert_class_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_before_insert_class
(
	p_file_id bigint,
	p_spec_folder_id bigint
) RETURNS void AS $$
DECLARE
	count integer;
BEGIN
	PERFORM core.__on_before_insert_file(p_file_id);
	IF p_spec_folder_id IS NOT NULL THEN
		PERFORM core.__inc_file_ref(p_spec_folder_id);
	END IF;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_class
(
	p_file_id bigint,
	p_ref_counter bigint,
	p_spec_folder_id bigint
) RETURNS void AS $$
BEGIN
	PERFORM core.__on_before_delete_file(p_file_id, p_ref_counter);
	IF p_spec_folder_id IS NOT NULL THEN
		PERFORM core.__dec_file_ref(p_spec_folder_id);
	END IF;
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Создание файла - класс объекта
---------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_class(
	p_id bigint,
	p_creator_id integer,
	p_interface_id integer,
	p_spec_folder_id bigint,
	p_object_kind class_object_kind,
	p_object_role integer,
	p_object_state integer,
	p_system_name varchar(128) DEFAULT NULL,
	p_visual_name varchar DEFAULT NULL,
	p_color integer DEFAULT 0,
	p_is_readonly boolean DEFAULT true,
	p_is_packable boolean DEFAULT true
) RETURNS bigint AS $$
DECLARE
	res_id bigint;
	v_name varchar;
BEGIN
	IF p_id IS NULL THEN
		res_id := nextval('core.file_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	IF p_visual_name IS NULL THEN
		v_name := p_system_name;
	ELSE
		v_name := p_visual_name;
	END IF;

	INSERT INTO spec.connector
	(
		file_id, creator_id, file_kind, interface_ptr, spec_folder_ptr,
		object_kind, object_role, object_state,
		system_name, visual_name, is_packable, is_readonly, color
	)
	VALUES
	(
		res_id, p_creator_id, core.tag_id('file','kind', 'standard-class-object'),
		p_interface_id, spec_folder_id, p_object_kind, p_object_role, p_object_state,
		core.canonical_string(p_system_name), v_name, p_is_packable, p_is_readonly,
		p_color
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Initial Data
---------------------------------------------------------------------------- */

SELECT core.new_folder(NULL, 0, 'c', 'root', 'Class Catalog', 0, true, false);

SELECT core._add_file_rel
(
	'core.folder'::regclass, 'c',
	'core.folder'::regclass, 'class-group',
	-1, 'Add Class Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'class-group',
	'core.folder'::regclass, 'class-group',
	-1, 'Add Class Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'class-group',
	'spec.connector'::regclass, 'standard-class-object',
	-1, 'Add Standard Class Object.'
);
