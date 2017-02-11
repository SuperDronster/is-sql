/* -----------------------------------------------------------------------------
	Resource Item Range Layout
	Constant:
		_record_rel.type = 2 (Parent Resource Layout Node ->
			Resource Layout Node)
----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_tag('rc-layout','node-kind', NULL, 'item-range-root',
	'Standard Resource Layout Node');
SELECT core.new_tag('rc-layout','node-kind', NULL, 'item-range-node',
	'Standard Resource Layout Node');
SELECT core.new_tag('rc-layout','node-kind', NULL, 'item-range-data',
	'Standard Resource Layout Node');

SELECT core.new_tag('rc-layout','use-type', NULL, 'fixed-item-range',
	'Fixed Item Range');
SELECT core.new_tag('rc-layout','use-type', NULL, 'custom-item-range',
	'Object Item Range');

CREATE TABLE rc_layout_item_range(
	item_range_lower_index integer NOT NULL,
	item_range_high_index integer NOT NULL,
	CONSTRAINT rclayoutir_id_pkey PRIMARY KEY (rclayout_id),

	-- Нельзя удалять тег вида раскладки ресурса
	CONSTRAINT rclayoutir_kind_fk FOREIGN KEY (layout_kind)
		REFERENCES core.tag(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,

	-- Нельзя удалять тег имени раскладки ресурса
	CONSTRAINT rclayoutir_name_fk FOREIGN KEY (name)
		REFERENCES core.tag(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION
) INHERITS(rc_layout);

CREATE INDEX rclayoutir_resource_ptr_idx ON rc_layout_item_range(resource_ptr);
CREATE INDEX rclayoutir_parent_ptr_idx ON rc_layout_item_range(parent_ptr);

CREATE OR REPLACE FUNCTION __on_before_insert_rclayoutir_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_insert_rclayoutir(NEW.rclayout_id, NEW.resource_ptr,
		NEW.parent_ptr, 'rc_layout_item_range'::regclass, NEW.layout_kind);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_rclayoutir_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_delete_rclayoutir(OLD.rclayout_id);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER before_delete_rclayoutir_trigger
	BEFORE DELETE ON rc_layout_item_range FOR EACH ROW
	EXECUTE PROCEDURE __on_before_delete_rclayoutir_trigger();

CREATE TRIGGER before_insert_rclayoutir_trigger
	BEFORE INSERT ON rc_layout_item_range FOR EACH ROW
	EXECUTE PROCEDURE __on_before_insert_rclayoutir_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_before_insert_rclayoutir(
	p_rclayout_id bigint,
	p_resource_id bigint,
	p_parent_id bigint,
	p_child_oid oid,
	p_child_kind bigint
) RETURNS void AS $$
DECLARE
BEGIN
	PERFORM spec.__on_before_insert_rclayout(p_rclayout_id, p_resource_id,
		p_parent_id, p_child_oid, p_child_kind);
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_rclayoutir(
	p_rclayout_id bigint
) RETURNS void AS $$
BEGIN
	PERFORM spec.__on_before_delete_rclayout(p_rclayout_id);
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Создание записи раскладки ресурса диапазона кол-ва элементов
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_rc_layout_item_range(
	p_rclayout_id bigint,
	p_resource_id bigint,
	p_parent_id bigint,
	p_use_type_tag_name varchar(128),
	p_name_tag_name varchar(128),
	p_lower_index integer,
	p_high_index integer,
	p_color integer DEFAULT 0
) RETURNS bigint AS $$
DECLARE
	res_id bigint;
	name varchar;
BEGIN
	IF p_rclayout_id IS NULL THEN
		res_id := nextval('spec.rclayout_id_seq');
	ELSE
		res_id := p_rclayout_id;
	END IF;

	INSERT INTO spec.rc_layout_item_range
	(
		rclayout_id, parent_ptr, resource_ptr, layout_kind, name,
		item_range_lower_index, item_range_high_index, color,
		use_type
	)
	VALUES
	(
		res_id, p_parent_id, p_resource_id,
		core.tag_id('rc-layout', 'node-kind', 'item-range-data'),
		core.tag_id('names','rc-layout', p_name_tag_name), p_lower_index,
		p_high_index, p_color,
		core.tag_id('rc-layout','use-type', p_use_type_tag_name)
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;
