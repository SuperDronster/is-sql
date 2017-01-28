/* -----------------------------------------------------------------------------
	Resource Count File
	Constant:
		tag.group_id = 2 (File Type Tags)
		tag.group_id = 5 (Resource Sides Enum Names)
---------------------------------------------------------------------------- */

SET search_path TO "spec";

-------------------------------------------------------------------------------

CREATE TABLE rc_item_count(
	rc_value_count integer,
	CONSTRAINT rcitemcount_pkey PRIMARY KEY (file_id),
	CONSTRAINT rcitemcount_rcdatatype_fk FOREIGN KEY (rc_data_type)
		REFERENCES core._data_type_def(type_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,
	CONSTRAINT rcitemcount_rcsides_fk FOREIGN KEY (rc_sides)
		REFERENCES core.tag(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,
	CONSTRAINT rcitemcount_filekind_fk FOREIGN KEY (file_kind)
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
	p_rc_data_type integer,
	p_value_count integer,
	p_sides_tag_name varchar(128),
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

	INSERT INTO spec.rc_item_count
	(
		file_id, creator_id, rc_data_type, file_kind, system_name, visual_name,
		is_packable, is_readonly, color, rc_sides, rc_value_count
	)
	VALUES
	(
		res_id, p_creator_id, p_rc_data_type, core.tag_id(2, 'default-resource'),
    core.canonical_string(p_system_name), name, p_is_packable, p_is_readonly,
    p_color, core.tag_id(5, p_sides_tag_name), p_value_count
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------
