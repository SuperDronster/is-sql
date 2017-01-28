/* -----------------------------------------------------------------------------
	Folder Functions.
	Constant.
		tag.group_id = 2 (File Kind Tags)
----------------------------------------------------------------------------- */

SET search_path TO "core";

--------------------------------------------------------------------------------

CREATE TABLE folder(
	CONSTRAINT folder_pkey PRIMARY KEY (file_id),
	CONSTRAINT folder_filekind_fk FOREIGN KEY (file_kind)
       REFERENCES tag(id) MATCH SIMPLE
       ON UPDATE NO ACTION ON DELETE NO ACTION
) INHERITS(file);

CREATE TRIGGER delete_folder_trigger
	BEFORE DELETE ON folder FOR EACH ROW
	EXECUTE PROCEDURE __on_delete_file_trigger();

CREATE TRIGGER create_folder_trigger
	BEFORE INSERT ON folder FOR EACH ROW
	EXECUTE PROCEDURE __on_create_file_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

/* -----------------------------------------------------------------------------
	Создание файла - папки
---------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_folder(
	p_id bigint,
	p_creator_id integer,
	p_kind_tag_name varchar(128),
	p_system_name varchar(128),
	p_visual_name varchar DEFAULT NULL,
	p_color integer DEFAULT 0,
	p_is_readonly boolean DEFAULT false,
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

	INSERT INTO core.folder
	(
		file_id, creator_id, file_kind, system_name, visual_name,
		is_packable, is_readonly, color
	)
	VALUES
	(
		res_id, p_creator_id, core.tag_id(2, p_kind_tag_name),
		core.canonical_string(p_system_name), name, p_is_packable,
		p_is_readonly, p_color
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------
