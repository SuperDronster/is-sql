/* -----------------------------------------------------------------------------
	Resource Count File
	Constant:
		tag.group_id = 2 (File Type Tags)
---------------------------------------------------------------------------- */

SET search_path TO "spec";

-------------------------------------------------------------------------------

SELECT core.new_tag(2,NULL, 'resource-item-count', 'Resource Item-Count File.');

CREATE TABLE rc_item_count(
	rc_value_count integer,
	CONSTRAINT rc_item_count_pkey PRIMARY KEY (file_id),
	CONSTRAINT rc_item_count_rc_sides_fk FOREIGN KEY (rc_sides)
       REFERENCES core.tag(id) MATCH SIMPLE
       ON UPDATE NO ACTION ON DELETE NO ACTION
) INHERITS(resource);

CREATE TRIGGER delete_rcitemcount_trigger
	BEFORE DELETE ON rc_item_count FOR EACH ROW
	EXECUTE PROCEDURE __on_delete_resource_trigger();

CREATE TRIGGER create_rcitemcount_trigger
	BEFORE INSERT ON rc_item_count FOR EACH ROW
	EXECUTE PROCEDURE core.__on_create_file_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

/* -----------------------------------------------------------------------------
	Создание файла - кол-ва ресурса
---------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_rc_item_count(
	p_id bigint,
	p_creator_id integer,
	p_value_count integer,
	p_sides_tag_name varchar(128),
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

	INSERT INTO spec.rc_item_count
	(
		file_id, creator_id, file_kind, system_name, visual_name,
		is_packable, is_readonly, color, rc_sides, rc_value_count
	)
	VALUES
	(
		res_id, p_creator_id, core.tag_id(2, 'rc-item-count-file'),
    core.canonical_string(p_system_name), name, p_is_packable, p_is_readonly,
    p_color, core.tag_id(10, p_sides_tag_name), p_value_count
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------
