/* -----------------------------------------------------------------------------
	Specification Item
	Constant:
----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_pool(NULL, 'names', 'pin', 'Spec Pin Names.', 0);
SELECT core.new_pool(NULL, 'pin', 'group', 'Spec Pin Groups.', 0);

SELECT core.new_tag('pin','group', NULL, 'provide', 'Spec Pin Provide Group');
SELECT core.new_tag('pin','group', NULL, 'connect', 'Spec Pin Connect Group');
SELECT core.new_tag('pin','group', NULL, 'placing', 'Spec Pin Placing Group');
SELECT core.new_tag('pin','group', NULL, 'node', 'Spec Pin Node Group');

CREATE SEQUENCE pin_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TABLE pin(
	pin_id bigint NOT NULL DEFAULT nextval('spec.pin_id_seq'),
	connector_ptr bigint NOT NULL REFERENCES spec.connector(file_id),
	part_ptr bigint NOT NULL REFERENCES spec.part(part_id),
	rclayout_ptr bigint REFERENCES spec.rc_layout(rclayout_id),
	resource_side bigint NOT NULL REFERENCES core.tag(id),
	name bigint NOT NULL REFERENCES core.tag(id),
	group_name bigint NOT NULL REFERENCES core.tag(id),
	group_index integer DEFAULT 1,
	order_index integer DEFAULT 1,
	is_unique_rc boolean NOT NULL DEFAULT false,
	use_count integer NOT NULL DEFAULT -1,
	CONSTRAINT pin_pkey PRIMARY KEY (pin_id)
);

-- Triggers

CREATE OR REPLACE FUNCTION __on_before_insert_pin_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_insert_pin(NEW.pin_id, NEW.connector_ptr,
		NEW.part_ptr, NEW.rclayout_ptr, NEW.resource_side);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_pin_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_delete_pin(OLD.pin_id, OLD.connector_ptr,
		OLD.part_ptr, OLD.rclayout_ptr, NEW.resource_side);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER before_delete_pin_trigger
	BEFORE DELETE ON pin FOR EACH ROW
	EXECUTE PROCEDURE __on_before_delete_pin_trigger();

CREATE TRIGGER before_insert_pin_trigger
	BEFORE INSERT ON pin FOR EACH ROW
	EXECUTE PROCEDURE __on_before_insert_pin_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_before_insert_pin(
	p_pin_id bigint,
	p_connector_ptr bigint,
	p_part_ptr bigint,
	p_rclayout_ptr bigint,
	p_resource_side bigint
) RETURNS void AS $$
BEGIN
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_pin(
	p_pin_id bigint,
	p_connector_ptr bigint,
	p_part_ptr bigint,
	p_rclayout_ptr bigint,
	p_resource_side bigint
) RETURNS void AS $$
BEGIN
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Создание записи раскладки ресурса диапазона кол-ва элементов
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_pin(
	p_id bigint,
	p_connector_id bigint,
	p_part_id bigint,
	p_rclayout_id bigint,
	p_resource_side_tag_name varchar(128),
	p_name_tag_name varchar(128),
	p_group_name_tag_name varchar(128),
	p_is_unique_rc boolean DEFAULT true,
	p_use_count integer DEFAULT -1,
	p_group_index integer DEFAULT 1,
	p_order_index integer DEFAULT 1
) RETURNS bigint AS $$
DECLARE
	res_id bigint;
	sides_pool integer;
BEGIN
	IF p_id IS NULL THEN
		res_id := nextval('spec.pin_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	SELECT r.rc_sides INTO sides_pool
	FROM part p
		JOIN resource r ON (p.resource_ptr = r.file_id)
	WHERE
		p.part_id = p_part_id;

	INSERT INTO spec.part
	(
		pin_id,
		connector_ptr,
		part_ptr,
		rclayout_ptr,
		resource_side,
		name,
		group_name,
		group_index,
		order_index,
		is_unique_rc,
		use_count
	)
	VALUES
	(
		res_id,
		p_connector_id,
		p_part_id,
		p_rclayout_id,
		core.tag_id(sides_pool, p_resource_side_tag_name),
		core.tag_id('names','pin', p_name_tag_name),
		core.tag_id('pin','group', p_group_name_tag_name),
		p_group_index,
		p_order_index,
		p_is_unique_rc,
		p_use_count
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Находит Spec Item для specification по строке пути
----------------------------------------------------------------------------- */
/*CREATE OR REPLACE FUNCTION part(
	p_specification_id bigint,
	p_path varchar,
	p_is_resource boolean DEFAULT NULL
) RETURNS bigint AS $$
DECLARE
	res_id bigint;
	names varchar[] := regexp_split_to_array(p_path, '/');
	prev_id bigint;
	curr_id bigint;
	name_id bigint;
	count integer;
	is_resource boolean;
	i integer;
	curr_path varchar;
BEGIN
	count := array_length(names,1);

	curr_path := names[1];
	name_id := core.tag_id('names','spec-rc', names[1]);

	SELECT part_id, resource_ptr IS NOT NULL
	INTO prev_id, is_resource
	FROM spec.part
	WHERE
			name = name_id AND
			specification_ptr = p_specification_id AND
	  	parent_ptr IS NULL;

	IF count > 1 THEN
		FOR i IN 2..count
		LOOP
			curr_path := curr_path || '/' || names[i];
			name_id := core.tag_id('names','spec-rc', names[i]);

			SELECT part_id, resource_ptr IS NOT NULL
			INTO curr_id, is_resource
			FROM spec.part
			WHERE
					name = name_id AND
					specification_ptr = p_specification_id AND
			  	parent_ptr = prev_id;

			IF curr_id IS NULL
			THEN
				PERFORM core._error('DataIsNotFound',
					format('Spec Item "%s" For Specification "id=%s" is not found.',
					curr_path, p_specification_id));
			END IF;
			prev_id := curr_id;
		END LOOP;
	END IF;

	IF prev_id IS NULL OR
		(p_is_resource IS NOT NULL AND
		is_resource <> p_is_resource)
	THEN
		PERFORM core._error('DataIsNotFound',
			format('Spec Item "%s" For Specification "id=%s" is not found.',
			curr_path, p_specification_id));
	END IF;

	RETURN prev_id;
END;
$$ LANGUAGE 'plpgsql';*/
