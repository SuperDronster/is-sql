/* -----------------------------------------------------------------------------
	Resource Item Range Layout
	Constant:
		_record_rel.type = 2 (Parent Resource Layout Node ->
													Child Resource Layout Node)
		tag.group_id = 3 (Resource Layout Kinds)
		tag.group_id = 4 (Resource Layout Names)
----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_tag(3,NULL, 'item-range-root', 'Item Range Root Rc Layout.');
SELECT core.new_tag(3,NULL, 'item-range-node', 'Item Range Node Rc Layout.');
SELECT core.new_tag(3,NULL, 'item-range-data', 'Item Range Data Rc Layout.');

CREATE TABLE rc_layout_item_range(
	item_range_lower_index integer NOT NULL,
	item_range_high_index integer NOT NULL,
	CONSTRAINT rclayoutir_id_pkey PRIMARY KEY (layout_id),
	--CONSTRAINT rclayoutir_unique UNIQUE (resource_ptr, name),
	CONSTRAINT rclayoutir_kind_fk FOREIGN KEY (layout_kind)
		REFERENCES core.tag(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,
	CONSTRAINT rclayoutir_name_fk FOREIGN KEY (name)
		REFERENCES core.tag(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION
) INHERITS(rc_layout);

CREATE INDEX rclayoutir_resource_ptr_idx ON rc_layout_item_range(resource_ptr);
CREATE INDEX rclayoutir_parent_ptr_idx ON rc_layout_item_range(parent_ptr);

CREATE OR REPLACE FUNCTION __on_create_rclayoutir_trigger() RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_create_rclayout(NEW.layout_id, NEW.resource_ptr,
		NEW.parent_ptr, 'rc_layout_item_range'::regclass, NEW.layout_kind);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER delete_rclayoutir_trigger
	BEFORE DELETE ON rc_layout_item_range FOR EACH ROW
	EXECUTE PROCEDURE spec.__on_delete_rclayout_trigger();

CREATE TRIGGER create_rclayoutir_trigger
	BEFORE INSERT ON rc_layout_item_range FOR EACH ROW
	EXECUTE PROCEDURE spec.__on_create_rclayoutir_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

/* -----------------------------------------------------------------------------
	Создание записи раскладки ресурса диапазона кол-ва элементов
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_rc_layout_item_range(
	p_layout_id bigint,
	p_resource_id bigint,
	p_parent_id bigint,
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
		layout_id, parent_ptr, resource_ptr, layout_kind, name,
		item_range_lower_index, item_range_high_index, color,
		is_virtual
	)
	VALUES
	(
		res_id, p_parent_id, p_resource_id,
		core.tag_id(3, 'item-range-data'),
		core.tag_id(4, p_name_tag_name), p_lower_index,
		p_high_index, p_color, false
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;
