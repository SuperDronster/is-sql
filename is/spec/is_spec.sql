/* -----------------------------------------------------------------------------
	resources File and System
	Constant.

----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_tag('file','kind', NULL, 's', 'Spec Folder Root');
SELECT core.new_tag('file','kind', NULL, 'spec-group', 'Spec Group');

SELECT core.new_tag('file','kind', NULL, 'standard-spec-group',
	'Standard Spec Group');
SELECT core.new_tag('file','kind', NULL, 'standard-spec-object',
	'Standard Spec Object');

CREATE TABLE spec(
	dependency_flags integer DEFAULT 0,

	-- Нельзя удалять тег - вид файла
	CONSTRAINT spec_filekind_fk FOREIGN KEY (file_kind)
		REFERENCES core.tag(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,

	CONSTRAINT spec_pkey PRIMARY KEY (file_id)
) INHERITS(core.file);

CREATE INDEX spec_systemname_idx ON spec(system_name);

-- Triggers

CREATE OR REPLACE FUNCTION __on_before_insert_spec_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_insert_spec(NEW.file_id);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_spec_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_delete_spec(OLD.file_id,OLD.ref_counter);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER before_insert_spec_trigger
	BEFORE INSERT ON spec FOR EACH ROW
	EXECUTE PROCEDURE __on_before_insert_spec_trigger();

CREATE TRIGGER before_delete_spec_trigger
	BEFORE DELETE ON spec FOR EACH ROW
	EXECUTE PROCEDURE __on_before_delete_spec_trigger();

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_before_insert_spec(
	p_file_id bigint
) RETURNS void AS $$
DECLARE
	count integer;
BEGIN
	PERFORM core.__on_before_insert_file(p_file_id);
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_spec(
	p_file_id bigint,
	p_ref_counter bigint
) RETURNS void AS $$
BEGIN
	DELETE FROM spec.part_dep
	WHERE
		spec_ptr = p_file_id;

	DELETE FROM spec.part
	WHERE
		spec_ptr = p_file_id AND
		parent_ptr IS NULL;

	PERFORM core.__on_before_delete_file(p_file_id, p_ref_counter);
END;
$$ LANGUAGE 'plpgsql';


/* -----------------------------------------------------------------------------
	Создание файла - кол-ва ресурса
---------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_spec(
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

	INSERT INTO spec.spec
	(
		file_id, creator_id, file_kind, dependency_flags, system_name,
		visual_name, is_packable, is_readonly, color
	)
	VALUES
	(
		res_id, p_creator_id, core.tag_id('file','kind', 'standard-spec-object'),
		0, core.canonical_string(p_system_name), v_name, p_is_packable,
		p_is_readonly, p_color
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Initial Data
---------------------------------------------------------------------------- */

SELECT core._add_file_rel
(
	'core.folder'::regclass, 's',
	'core.folder'::regclass, 'spec-group',
	-1, 'Add Specification Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'spec-group',
	'core.folder'::regclass, 'spec-group',
	-1, 'Add Specification Group.'
);
SELECT core._add_file_rel
(
	'core.folder'::regclass, 'spec-group',
	'spec.spec'::regclass, 'standard-spec-object',
	-1, 'Add Standard Specificaion Object.'
);
