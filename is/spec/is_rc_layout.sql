/* -----------------------------------------------------------------------------
	Resource File and System
	Constant:
		_record_rel.type = 2 (Parent Resource Layout Node ->
													Child Resource Layout Node)
		tag.group_id = 3 (Resource Layout Kinds)
		tag.group_id = 4 (Resource Layout Names)
----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

CREATE SEQUENCE rclayout_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TABLE rc_layout(
	layout_id bigint NOT NULL DEFAULT nextval('spec.rclayout_id_seq'),
	parent_ptr bigint DEFAULT NULL,
	resource_ptr bigint DEFAULT NULL,
	layout_kind bigint NOT NULL REFERENCES core.tag(id),
	is_virtual boolean DEFAULT true,
	name bigint NOT NULL REFERENCES core.tag(id),
	color integer NOT NULL DEFAULT 0,
	CONSTRAINT rc_layout_pkey PRIMARY KEY (layout_id)
);

CREATE INDEX rc_layout_rc_file_ptr_idx ON rc_layout(rc_file_ptr);

-- Triggers

CREATE OR REPLACE FUNCTION __on_create_rclayout_trigger() RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_create_rclayout(NEW.layout_id, NEW.resource_ptr, NEW.parent_ptr);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_delete_rclayout_trigger() RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_delete_rclayout(OLD.layout_id);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER create_rclayout_trigger
	BEFORE INSERT ON rc_layout FOR EACH ROW
	EXECUTE PROCEDURE __on_create_rclayout_trigger();

CREATE TRIGGER delete_rclayout_trigger
	BEFORE DELETE ON rc_layout FOR EACH ROW
	EXECUTE PROCEDURE __on_delete_rclayout_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_create_rclayout(
	p_layout_id bigint,
	p_resource_ptr bigint,
	p_parent_ptr bigint
) RETURNS void AS $$
DECLARE
	count integer;
BEGIN
	SELECT count(*) INTO count
	FROM spec.rc_layout
	WHERE
		layout_id = p_layout_id;

	IF count <> 0 THEN
		PERFORM core._error('DuplicateData',
			format('RC Layout "id=%s" allready exists.', p_layout_id));
	END IF;

	SELECT count(*) INTO count
	FROM spec.resource
	WHERE
		file_id = p_resource_ptr;

	IF count <> 1 THEN
		PERFORM core._error('DataIsNotFound',
			format('Resource File "id=%s" is not found.', p_resource_ptr));
	END IF;

	IF p_parent_ptr IS NOT NULL
	THEN
		SELECT count(*) INTO count
		FROM spec.rc_layout
		WHERE
			layout_id = p_parent_ptr;

		IF count <> 1 THEN
			PERFORM core._error('DataIsNotFound',
				format('Parent Rc Layout "id=%s" is not found.', p_parent_ptr));
		END IF;
	END IF;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_delete_rclayout(
	p_layout_id bigint
) RETURNS void AS $$
BEGIN
	DELETE FROM spec.rc_layout
	WHERE
		parent_ptr = p_layout_id;
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Создание записи раскладки ресурса диапазона кол-ва элементов
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_rc_layout_node(
	p_layout_id bigint,
  p_resource_ptr bigint,
  p_parent_ptr bigint,
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
		res_id, p_parent_ptr, p_resource_ptr, core.tag_id(3, p_kind_tag_name),
		core.tag_id(4, p_name_tag_name), p_color, true
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Находит Rc Layout для Resource по строке пути
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION rc_layout(
	p_resource_ptr bigint,
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
			resource_ptr = p_resource_ptr AND
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
					resource_ptr = p_resource_ptr AND
			  	parent_ptr = prev_id;

			IF curr_id IS NULL
			THEN
				PERFORM core._error('DataIsNotFound',
					format('RC Layout "%s" For Resource "id=%s" is not found.',
					curr_path, p_resource_ptr));
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
			curr_path, p_resource_ptr));
	END IF;

	RETURN prev_id;
END;
$$ LANGUAGE 'plpgsql';
