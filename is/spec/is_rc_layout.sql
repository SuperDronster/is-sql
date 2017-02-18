/* -----------------------------------------------------------------------------
	resources Layout
	Constant:
		_record_rel.type = 2 (Parent Rc Layout Node -> Child Rc Layout Node)
----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_pool(NULL, 'names', 'rc-layout', 'Resources Layout Names.', 0);

--SELECT core.new_pool(NULL, 'rc-layout', 'node-kind', 'resources Layout Nodes.', 0);
--SELECT core.new_tag('rc-layout','node-kind', NULL, 'range-root',
--	'Standard resources Layout Node');
--SELECT core.new_tag('rc-layout','node-kind', NULL, 'range-node',
--	'Standard resources Layout Node');

/*SELECT core.new_pool(NULL, 'rc-layout', 'use-type', 'Rc Layout Types.', 0);
SELECT core.new_tag('rc-layout','use-type', NULL, 'virtual-node', 'Virtual Node');
SELECT core.new_tag('rc-layout','use-type', NULL, 'fixed-range', 'Fixed Range');
SELECT core.new_tag('rc-layout','use-type', NULL, 'custom-range', 'Object Range');*/

CREATE TYPE rclayout_use_type AS ENUM
(
	'virtual-node',
	'fixed-range',
	'custom-range'
);

CREATE SEQUENCE rclayout_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TABLE rc_layout(
	id bigint NOT NULL DEFAULT nextval('spec.rclayout_id_seq'),
	parent_ptr bigint DEFAULT NULL,
	resources_ptr bigint NOT NULL,
	rc_lower_index integer DEFAULT NULL,
	rc_high_index integer DEFAULT NULL,
	use_type rclayout_use_type NOT NULL,
	name bigint NOT NULL REFERENCES core.tag(id),
	color integer NOT NULL DEFAULT 0,
	CONSTRAINT rc_layout_pkey PRIMARY KEY (id)
);

CREATE INDEX rc_layout_resources_ptr_idx ON rc_layout(resources_ptr);
CREATE INDEX rc_layout_parent_ptr_idx ON rc_layout(parent_ptr);

-- Triggers

CREATE OR REPLACE FUNCTION __on_before_insert_rclayout_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_insert_rclayout(NEW.id, NEW.parent_ptr,
		NEW.resources_ptr);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_rclayout_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_delete_rclayout(OLD.id);
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

CREATE OR REPLACE FUNCTION __on_before_insert_rclayout
(
	p_id bigint,
	p_parent_id bigint,
	p_resources_id bigint
)
RETURNS void AS $$
DECLARE
	count integer;
BEGIN
	-- Проверяем уникальность ИД
	SELECT count(*) INTO count
	FROM spec.rc_layout
	WHERE
		id = p_id;
	IF count <> 0 THEN
		PERFORM core._error('DuplicateData',
			format('resources Layout "id=%s" allready exists.', p_id));
	END IF;

	-- Проверяем есть ли Обьект - ресурс
	SELECT count(*) INTO count
	FROM spec.resources
	WHERE
		file_id = p_resources_id;
	IF count <> 1 THEN
		PERFORM core._error('DataIsNotFound',
			format('resources File "id=%s" is not found.', p_resources_id));
	END IF;

	IF p_parent_id IS NOT NULL
	THEN
		-- Проверяем есть ли родительский объект
		SELECT count(*) INTO count
		FROM spec.rc_layout
		WHERE
			id = p_parent_id;
		IF NOT FOUND THEN
			PERFORM core._error('DataIsNotFound',
				format('Parent Rc Layout "id=%s" is not found.',
				p_parent_id));
		END IF;
	END IF;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_rclayout
(
	p_id bigint
)
RETURNS void AS $$
BEGIN
	DELETE FROM spec.rc_layout
	WHERE
		parent_ptr = p_id;
END;
$$ LANGUAGE 'plpgsql';

/*CREATE  OR REPLACE FUNCTION _add_rclayout_rel(
	p_parent_table_oid oid,
	p_parent_rec_kind_tag_name varchar(128),
	p_child_table_oid oid,
	p_child_rec_kind_tag_name varchar(128),
	p_child_rec_count integer,
	p_name varchar
) RETURNS void AS $$
BEGIN
	PERFORM core._add_record_rel(2, p_parent_table_oid,
		core.tag_id('rc-layout','node-kind', p_parent_rec_kind_tag_name),
		p_child_table_oid,
		core.tag_id('rc-layout','node-kind', p_child_rec_kind_tag_name),
		p_child_rec_count, p_name
	);
END;
$$ LANGUAGE plpgsql;*/

/* -----------------------------------------------------------------------------
	Создание записи раскладки ресурса диапазона кол-ва элементов
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_rc_layout
(
	p_id bigint,
	p_parent_id bigint,
	p_resources_id bigint,
	p_use_type rclayout_use_type,
	p_name_tag_name varchar(128),
	p_lower_index integer,
	p_high_index integer,
	p_color integer DEFAULT 0
)
RETURNS bigint AS $$
DECLARE
	res_id bigint;
	name varchar;
BEGIN
	IF p_id IS NULL THEN
		res_id := nextval('spec.rclayout_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	INSERT INTO spec.rc_layout
	(
		id, parent_ptr, resources_ptr, name,
		rc_lower_index, rc_high_index, color,
		use_type
	)
	VALUES
	(
		res_id, p_parent_id, p_resources_id,
		core.tag_id('names','rc-layout', p_name_tag_name), p_lower_index,
		p_high_index, p_color, p_use_type
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Находит Rc Layout для resources по строке пути
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION rc_layout_id
(
	p_resources_id bigint,
	p_path varchar,
	p_use_type rclayout_use_type DEFAULT NULL
)
RETURNS bigint AS $$
DECLARE
	res_id bigint;
	names varchar[] := regexp_split_to_array(p_path, '/');
	prev_id bigint;
	curr_id bigint;
	name_id bigint;
	count integer;
	a_use_type rclayout_use_type;
	i integer;
	curr_path varchar;
BEGIN
	count := array_length(names,1);

	curr_path := names[1];
	name_id := core.tag_id('names','rc-layout', names[1]);

	SELECT id, use_type
	INTO prev_id, a_use_type
	FROM spec.rc_layout
	WHERE
			name = name_id AND
			resources_ptr = p_resources_id AND
	  	parent_ptr IS NULL;

	IF count > 1 THEN
		FOR i IN 2..count
		LOOP
			curr_path := curr_path || '/' || names[i];
			name_id := core.tag_id('names','rc-layout', names[i]);

			SELECT id, use_type
			INTO curr_id, a_use_type
			FROM spec.rc_layout
			WHERE
					name = name_id AND
					resources_ptr = p_resources_id AND
			  	parent_ptr = prev_id;

			IF curr_id IS NULL
			THEN
				PERFORM core._error('DataIsNotFound',
					format('RC Layout "%s" For resources "id=%s" is not found.',
					curr_path, p_resources_id));
			END IF;
			prev_id := curr_id;
		END LOOP;
	END IF;

	IF prev_id IS NULL OR
		(p_use_type IS NOT NULL AND
		a_use_type <> p_use_type)
	THEN
		PERFORM core._error('DataIsNotFound',
			format('RC Layout "%s" For resources "id=%s" is not found.',
			curr_path, p_resources_id));
	END IF;

	RETURN prev_id;
END;
$$ LANGUAGE 'plpgsql';
