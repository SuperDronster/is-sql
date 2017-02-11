/* -----------------------------------------------------------------------------
	Resource File and System
	Constant.

----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_tag('file','kind', NULL, 'specification-folder-root',
	'Specification Folder Root');
SELECT core.new_tag('file','kind', NULL, 'specification-folder-node',
	'Specification Folder Node');

SELECT core.new_tag('file','kind', NULL, 'std-specification',
	'Standard Specification');

CREATE TABLE specification(
	dependency_flags integer DEFAULT 0,

	-- Нельзя удалять тег - вид файла
	CONSTRAINT specification_filekind_fk FOREIGN KEY (file_kind)
		REFERENCES core.tag(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,
	CONSTRAINT specification_pkey PRIMARY KEY (file_id)
) INHERITS(core.file);

CREATE INDEX specification_systemname_idx ON specification(system_name);

-- Triggers

CREATE OR REPLACE FUNCTION __on_before_insert_specification_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_insert_specification(NEW.file_id);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_specification_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_delete_specification(OLD.file_id,OLD.ref_counter);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER before_insert_specification_trigger
	BEFORE INSERT ON specification FOR EACH ROW
	EXECUTE PROCEDURE __on_before_insert_specification_trigger();

CREATE TRIGGER before_delete_specification_trigger
	BEFORE DELETE ON specification FOR EACH ROW
	EXECUTE PROCEDURE __on_before_delete_specification_trigger();

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_before_insert_specification(
	p_file_id bigint
) RETURNS void AS $$
DECLARE
	count integer;
BEGIN
	PERFORM core.__on_before_insert_file(p_file_id);
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_specification(
	p_file_id bigint,
	p_ref_counter bigint
) RETURNS void AS $$
BEGIN
	DELETE FROM spec.part_dep
	WHERE
		specification_ptr = p_file_id;

	DELETE FROM spec.part
	WHERE
		specification_ptr = p_file_id AND
		parent_ptr IS NULL;

	PERFORM core.__on_before_delete_file(p_file_id, p_ref_counter);
END;
$$ LANGUAGE 'plpgsql';


/* -----------------------------------------------------------------------------
	Создание файла - кол-ва ресурса
---------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_specification(
	p_id bigint,
	p_creator_id integer,
	--p_kind_tag_name varchar(128),
	p_obj_dep_flag_tag_names varchar,
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

	INSERT INTO spec.specification
	(
		file_id, creator_id, file_kind, dependency_flags, system_name,
		visual_name, is_packable, is_readonly, color
	)
	VALUES
	(
		res_id, p_creator_id, core.tag_id('file','kind', 'std-specification'),
		0, core.canonical_string(p_system_name), v_name, p_is_packable,
		p_is_readonly, p_color
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;
