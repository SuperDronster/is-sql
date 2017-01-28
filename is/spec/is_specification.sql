/* -----------------------------------------------------------------------------
	Resource File and System
	Constant.
		tag.group_id = 2 (File Kind Tags)
		tag.group_id = 7 (specification Data Types)

----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_tag(2,NULL, 'default-specification', 'Default Specification File.');

CREATE TABLE specification(
	dependency_flags integer DEFAULT 0,
	CONSTRAINT specification_filekind_fk FOREIGN KEY (file_kind)
		REFERENCES core.tag(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,
	CONSTRAINT specification_pkey PRIMARY KEY (file_id)
) INHERITS(core.file);

CREATE INDEX specification_systemname_idx ON specification(system_name);

-- Triggers

CREATE OR REPLACE FUNCTION __on_delete_specification_trigger() RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_delete_specification(OLD.file_id,OLD.ref_counter);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER delete_specification_trigger
	BEFORE DELETE ON specification FOR EACH ROW
	EXECUTE PROCEDURE __on_delete_specification_trigger();

CREATE TRIGGER create_specification_trigger
	BEFORE INSERT ON specification FOR EACH ROW
	EXECUTE PROCEDURE core.__on_create_file_trigger();

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_delete_specification(
	p_file_id bigint,
	p_ref_counter bigint
) RETURNS void AS $$
BEGIN
	DELETE FROM spec.spec_item
	WHERE
		specification_ptr = p_file_id AND
		parent_ptr IS NULL;

	PERFORM core.__on_delete_file(p_file_id, p_ref_counter);
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
		res_id, p_creator_id, core.tag_id(2, 'default-specification'),
		0, core.canonical_string(p_system_name), v_name, p_is_packable,
		p_is_readonly, p_color
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;
