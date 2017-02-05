/* -----------------------------------------------------------------------------
	Folder Functions.
	Constant.
----------------------------------------------------------------------------- */

SET search_path TO "core";

--------------------------------------------------------------------------------

SELECT new_pool(NULL, 'file-kind', 'folder', 'Folder Kinds.', 0);

CREATE TABLE folder(
	CONSTRAINT folder_pkey PRIMARY KEY (file_id),

	-- Нельзя удалять тег - вид файла
	CONSTRAINT folder_filekind_fk FOREIGN KEY (file_kind)
		REFERENCES tag(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION
) INHERITS(file);

CREATE OR REPLACE FUNCTION __on_before_insert_folder_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM core.__on_before_insert_file(NEW.file_id);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_folder_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM core.__on_before_delete_file(OLD.file_id, OLD.ref_counter);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER before_delete_folder_trigger
	BEFORE DELETE ON folder FOR EACH ROW
	EXECUTE PROCEDURE __on_before_delete_folder_trigger();

CREATE TRIGGER before_insert_folder_trigger
	BEFORE INSERT ON folder FOR EACH ROW
	EXECUTE PROCEDURE __on_before_insert_folder_trigger();

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
		res_id, p_creator_id, core.tag_id('file-kind','folder', p_kind_tag_name),
		core.canonical_string(p_system_name), name, p_is_packable,
		p_is_readonly, p_color
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------
