/* -----------------------------------------------------------------------------
	Resource Layout
	Constant:
		_record_rel.type = 2 (Parent Rc Layout Node -> Child Rc Layout Node)
		tag.group_id = 3 (Resource Layout Kinds)
		tag.group_id = 4 (Resource Layout Names)
----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

CREATE SEQUENCE rclayout_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TABLE rc_layout(
	layout_id bigint NOT NULL DEFAULT nextval('spec.rclayout_id_seq'),
	parent_ptr bigint DEFAULT NULL,
	resource_ptr bigint NOT NULL,
	layout_kind bigint NOT NULL REFERENCES core.tag(id),
	is_virtual boolean DEFAULT true,
	name bigint NOT NULL REFERENCES core.tag(id),
	color integer NOT NULL DEFAULT 0,
	CONSTRAINT rc_layout_pkey PRIMARY KEY (layout_id)
);

CREATE INDEX rc_layout_resource_ptr_idx ON rc_layout(resource_ptr);
CREATE INDEX rc_layout_parent_ptr_idx ON rc_layout(parent_ptr);

-- Triggers

CREATE OR REPLACE FUNCTION __on_before_insert_rclayout_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_insert_rclayout(NEW.layout_id, NEW.resource_ptr,
		NEW.parent_ptr, 'spec.rc_layout'::regclass, NEW.layout_kind);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_rclayout_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_delete_rclayout(OLD.layout_id);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER before_insert_rclayout_trigger
	BEFORE INSERT ON rc_layout FOR EACH ROW
	EXECUTE PROCEDURE __on_before_insert_rclayout_trigger();

CREATE TRIGGER before_delete_rclayout_trigger
	BEFORE DELETE ON rc_layout FOR EACH ROW
	EXECUTE PROCEDURE __on_before_delete_rclayout_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_before_insert_rclayout(
	p_layout_id bigint,
	p_resource_id bigint,
	p_parent_id bigint,
	p_child_oid oid,
	p_child_kind bigint
) RETURNS void AS $$
DECLARE
	p_kind integer;
	p_oid oid;
	c_kind integer;
	c_oid oid;
	count integer;
	count_rel integer;
BEGIN
	-- Проверяем уникальность ИД
	SELECT count(*) INTO count
	FROM spec.rc_layout
	WHERE
		layout_id = p_layout_id;
	IF count <> 0 THEN
		PERFORM core._error('DuplicateData',
			format('Resource Layout "id=%s" allready exists.', p_layout_id));
	END IF;

	-- Проверяем есть ли Обьект - ресурс
	SELECT count(*) INTO count
	FROM spec.resource
	WHERE
		file_id = p_resource_id;
	IF count <> 1 THEN
		PERFORM core._error('DataIsNotFound',
			format('Resource File "id=%s" is not found.', p_resource_id));
	END IF;

	IF p_parent_id IS NOT NULL
	THEN
		-- Проверяем есть ли родительский объект
		SELECT tableoid, layout_kind INTO p_oid, p_kind
		FROM spec.rc_layout
		WHERE
			layout_id = p_parent_id;
		IF NOT FOUND THEN
			PERFORM core._error('DataIsNotFound',
				format('Parent Rc Layout "id=%s" is not found.',
				p_parent_id));
		END IF;

		count_rel := core._check_record_rel(2, p_oid, p_kind, p_child_oid,
			p_child_kind);
		IF count_rel IS NULL THEN
			PERFORM core._error('Forbidden',
				format('Rc Layout Relation [(%s)%s->(%s)%s] is forbidden.',
				core.tag_name(p_kind),p_oid::regclass,
				core.tag_name(p_child_kind),p_child_oid::regclass));
		END IF;
	END IF;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_rclayout(
	p_layout_id bigint
) RETURNS void AS $$
BEGIN
	DELETE FROM spec.rc_layout
	WHERE
		parent_ptr = p_layout_id;
END;
$$ LANGUAGE 'plpgsql';

CREATE  OR REPLACE FUNCTION _add_rclayout_rel(
	p_parent_table_oid oid,
	p_parent_rec_kind_tag_name varchar(128),
	p_child_table_oid oid,
	p_child_rec_kind_tag_name varchar(128),
	p_child_rec_count integer,
	p_name varchar
) RETURNS void AS $$
BEGIN
	PERFORM core._add_record_rel(2, p_parent_table_oid,
		core.tag_id(3,p_parent_rec_kind_tag_name),
		p_child_table_oid,
		core.tag_id(3,p_child_rec_kind_tag_name),
		p_child_rec_count, p_name
	);
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Создание записи раскладки ресурса диапазона кол-ва элементов
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_rc_layout_node(
	p_layout_id bigint,
  p_resource_id bigint,
  p_parent_id bigint,
	p_kind_tag_name varchar(128),
	p_name_tag_name varchar(128),
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

	INSERT INTO spec.rc_layout
	(
		layout_id, parent_ptr, resource_ptr, layout_kind, name,
		color, is_virtual
	)
	VALUES
	(
		res_id, p_parent_id, p_resource_id, core.tag_id(3, p_kind_tag_name),
		core.tag_id(4, p_name_tag_name), p_color, true
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Находит Rc Layout для Resource по строке пути
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION rc_layout(
	p_resource_id bigint,
	p_path varchar,
	p_type oid DEFAULT NULL
) RETURNS bigint AS $$
DECLARE
	res_id bigint;
	names varchar[] := regexp_split_to_array(p_path, '/');
	prev_id bigint;
	curr_id bigint;
	name_id bigint;
	count integer;
	a_type oid;
	i integer;
	curr_path varchar;
BEGIN
	count := array_length(names,1);

	curr_path := names[1];
	name_id := core.tag_id(4,names[1]);

	SELECT layout_id, tableoid
	INTO prev_id, a_type
	FROM spec.rc_layout
	WHERE
			name = name_id AND
			resource_ptr = p_resource_id AND
	  	parent_ptr IS NULL;

	IF count > 1 THEN
		FOR i IN 2..count
		LOOP
			curr_path := curr_path || '/' || names[i];
			name_id := core.tag_id(4,names[i]);

			SELECT layout_id, tableoid
			INTO curr_id, a_type
			FROM spec.rc_layout
			WHERE
					name = name_id AND
					resource_ptr = p_resource_id AND
			  	parent_ptr = prev_id;

			IF curr_id IS NULL
			THEN
				PERFORM core._error('DataIsNotFound',
					format('RC Layout "%s" For Resource "id=%s" is not found.',
					curr_path, p_resource_id));
			END IF;
			prev_id := curr_id;
		END LOOP;
	END IF;

	IF prev_id IS NULL OR
		(p_type IS NOT NULL AND
		a_type <> p_type)
	THEN
		PERFORM core._error('DataIsNotFound',
			format('RC Layout "%s" For Resource "id=%s" is not found.',
			curr_path, p_resource_id));
	END IF;

	RETURN prev_id;
END;
$$ LANGUAGE 'plpgsql';
