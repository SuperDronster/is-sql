﻿/* -----------------------------------------------------------------------------
	Resource Item Range Layout
----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

CREATE TABLE rc_layout_item_range(
	item_range_lower_index integer NOT NULL,
	item_range_high_index integer NOT NULL,
	CONSTRAINT rclayoutir_id_pkey PRIMARY KEY (layout_id),
	--CONSTRAINT rclayoutir_unique UNIQUE (resource_ptr, name),
	CONSTRAINT rclayoutir_name_fk FOREIGN KEY (name)
		REFERENCES core.tag(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION
) INHERITS(rc_layout);

CREATE TRIGGER delete_rclayoutir_trigger
	BEFORE DELETE ON rc_layout_item_range FOR EACH ROW
	EXECUTE PROCEDURE __on_delete_rclayout_trigger();

CREATE TRIGGER create_rclayoutir_trigger
	BEFORE INSERT ON rc_layout_item_range FOR EACH ROW
	EXECUTE PROCEDURE __on_create_rclayout_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

/* -----------------------------------------------------------------------------
	Создание записи раскладки ресурса диапазона кол-ва элементов
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_rc_layout_item_range(
	p_layout_id bigint,
	p_resource_ptr bigint,
	p_parent_ptr bigint,
	p_name_tag_name varchar(128),
	p_lower_index integer,
	p_high_index integer,
	p_color integer DEFAULT 0
) RETURNS bigint AS $$
DECLARE
	res_id bigint;
	name varchar;
BEGIN
	IF p_layout_id IS NULL THEN
		res_id := nextval('spec.rclayout_id_seq');
	ELSE
		res_id := p_layout_id;
	END IF;

	INSERT INTO spec.rc_layout_item_range
	(
		layout_id, parent_ptr, resource_ptr, name,
		item_range_lower_index, item_range_high_index, color,
		is_virtual
	)
	VALUES
	(
		res_id, p_parent_ptr, p_resource_ptr,
		core.tag_id(6, p_name_tag_name), p_lower_index,
		p_high_index, p_color, false
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;