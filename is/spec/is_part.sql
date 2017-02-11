﻿/* -----------------------------------------------------------------------------
	Specification Item
	Constant:
		_record_rel.type = 3 (Spec Item -> Spec Item)
----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_pool(NULL, 'names', 'part', 'Part Names.', 0);

SELECT core.new_pool(NULL, 'part', 'node-kind', 'Part Node Kinds.', 0);
SELECT core.new_tag('part','node-kind', NULL, 'item-count', 'Item Count Part');
SELECT core.new_tag('part','node-kind', NULL, 'group', 'Part Group');

CREATE SEQUENCE part_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TABLE part(
	part_id bigint NOT NULL DEFAULT nextval('spec.part_id_seq'),
	part_kind bigint NOT NULL REFERENCES core.tag(id),
	parent_ptr bigint DEFAULT NULL,
	specification_ptr bigint NOT NULL,
	resource_ptr bigint DEFAULT NULL,
	name bigint NOT NULL REFERENCES core.tag(id),
	color integer NOT NULL DEFAULT 0,
	CONSTRAINT part_pkey PRIMARY KEY (part_id)
);

CREATE INDEX part_spec_ptr_idx ON part(specification_ptr);
CREATE INDEX part_parent_ptr_idx ON part(parent_ptr);

CREATE TABLE part_dep(
	specification_ptr bigint NOT NULL,
	consumer_part_ptr bigint NOT NULL,
	producer_part_ptr bigint NOT NULL,

	-- Удалять все ссылки на producer спец. ресурсов при удалении
	-- consumer спец. ресурса
	CONSTRAINT partdep_del_fk FOREIGN KEY (consumer_part_ptr)
		REFERENCES part(part_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE CASCADE,

	-- Нельзя удалять файл спецификации
	CONSTRAINT partdep_spec_fk FOREIGN KEY (specification_ptr)
		REFERENCES specification(file_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,

	-- Нельзя удалять producer спец. ресурс пока его использует consumer
	-- спец. ресурс
	CONSTRAINT partdep_prod_fk FOREIGN KEY (producer_part_ptr)
		REFERENCES part(part_id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,

	CONSTRAINT partdep_pkey PRIMARY KEY
		(consumer_part_ptr, producer_part_ptr)
);

-- Triggers

CREATE OR REPLACE FUNCTION __on_before_insert_part_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_insert_part(NEW.part_id, NEW.part_kind,
		'spec.part'::regclass, NEW.specification_ptr, NEW.parent_ptr,
		NEW.resource_ptr);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_part_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_delete_part(OLD.part_id,
		OLD.resource_ptr);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER before_delete_part_trigger
	BEFORE DELETE ON part FOR EACH ROW
	EXECUTE PROCEDURE __on_before_delete_part_trigger();

CREATE TRIGGER before_insert_part_trigger
	BEFORE INSERT ON part FOR EACH ROW
	EXECUTE PROCEDURE __on_before_insert_part_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_before_insert_part(
	p_part_id bigint,
	p_part_kind bigint,
	p_part_oid oid,
	p_specification_id bigint,
	p_parent_id bigint,
	p_resource_id bigint
) RETURNS void AS $$
DECLARE
	count integer;
	p_kind integer;
	p_oid oid;
	c_kind integer;
	c_oid oid;
BEGIN
	-- Проверяем уникальность ИД
	SELECT count(*) INTO count
	FROM spec.part
	WHERE
		part_id = p_part_id;
	IF count <> 0 THEN
		PERFORM core._error('DuplicateData',
			format('Spec Item "id=%s" allready exists.', p_part_id));
	END IF;

	-- Проверяем есть ли Обьект - спецификация
	SELECT count(*) INTO count
	FROM spec.specification
	WHERE
		file_id = p_specification_id;
	IF count <> 1 THEN
		PERFORM core._error('DataIsNotFound',
			format('Specification File "id=%s" is not found.',
				p_specification_id));
	END IF;


	IF p_resource_id IS NOT NULL
	THEN
		-- Проверяем есть ли Обьект - ресурс
		SELECT count(*) INTO count
		FROM spec.resource
		WHERE
			file_id = p_resource_id;
		IF count <> 1 THEN
			PERFORM core._error('DataIsNotFound',
				format('Resource File "id=%s" is not found.',
					p_resource_id));
		END IF;

		-- увеличиваем кол-во ссылок в объекте - ресурс
		PERFORM core.__inc_file_ref(p_resource_id);
	END IF;

	IF p_parent_id IS NOT NULL
	THEN
		-- Проверяем есть ли родительский объект
		SELECT tableoid,part_kind INTO p_oid, p_kind
		FROM spec.part
		WHERE
			part_id = p_parent_id;
		IF NOT FOUND THEN
			PERFORM core._error('DataIsNotFound',
				format('Parent Spec Item "id=%s" is not found.',
					p_parent_id));
		END IF;

		count := core._check_record_rel(3, p_oid, p_kind,
			p_part_oid, p_part_kind);
		IF count IS NULL THEN
			PERFORM core._error('Forbidden',
				format('Spec Item Relation [(%s)%s->(%s)%s] is forbidden.',
				core.tag_name(p_kind),p_oid::regclass,
				core.tag_name(p_part_kind),p_part_oid::regclass));
		END IF;
	END IF;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_part(
	p_part_id bigint,
	p_resource_id bigint
) RETURNS void AS $$
BEGIN
	DELETE FROM spec.part
	WHERE
		parent_ptr = p_part_id;
	IF p_resource_id IS NOT NULL
	THEN
		-- уменьшаем кол-во ссылок в объекте - ресурс
		PERFORM core.__dec_file_ref(p_resource_id);
	END IF;
END;
$$ LANGUAGE 'plpgsql';

CREATE  OR REPLACE FUNCTION _add_part_rel(
	p_parent_table_oid oid,
	p_parent_rec_kind_tag_name varchar(128),
	p_child_table_oid oid,
	p_child_rec_kind_tag_name varchar(128),
	p_child_rec_count integer,
	p_name varchar
) RETURNS void AS $$
BEGIN
	PERFORM core._add_record_rel(3, p_parent_table_oid,
		core.tag_id('part','node-kind', p_parent_rec_kind_tag_name),
		p_child_table_oid,
		core.tag_id('part','node-kind', p_child_rec_kind_tag_name),
		p_child_rec_count, p_name
	);
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Создание записи раскладки ресурса диапазона кол-ва элементов
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_part(
	p_id bigint,
	p_kind_tag_name varchar(128),
  p_specification_id bigint,
  p_parent_id bigint,
	p_name_tag_name varchar(128),
	p_resource_id bigint DEFAULT NULL,
	p_color integer DEFAULT 0
) RETURNS bigint AS $$
DECLARE
	res_id bigint;
	name varchar;
BEGIN
	IF p_id IS NULL THEN
		res_id := nextval('spec.part_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	INSERT INTO spec.part
	(
		part_id, part_kind, parent_ptr, specification_ptr,
		resource_ptr, name, color
	)
	VALUES
	(
		res_id, core.tag_id('part','node-kind', p_kind_tag_name),
		p_parent_id, p_specification_id,
		p_resource_id, core.tag_id('names','part', p_name_tag_name),
		p_color
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Находит Spec Item для specification по строке пути
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION part(
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
	name_id := core.tag_id('names','part', names[1]);

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
			name_id := core.tag_id('names','part', names[i]);

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
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION new_part_dep(
	p_specifcation_id bigint,
	p_consumer_id bigint,
	p_producer_id bigint
) RETURNS void AS $$
DECLARE
BEGIN
	INSERT INTO spec.part_dep
	(
		specification_ptr,
		consumer_part_ptr,
		producer_part_ptr
	)
	VALUES
	(
		p_specifcation_id,
		p_consumer_id,
		p_producer_id
	);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION del_part_dep(
	p_specifcation_id bigint,
	p_consumer_id bigint,
	p_producer_id bigint
) RETURNS void AS $$
DECLARE
BEGIN
	DELETE FROM spec.part_dep
	WHERE
		specification_ptr = p_specifcation_id AND
		consumer_part_ptr = p_consumer_id AND
		producer_part_ptr = p_producer_id;
END;
$$ LANGUAGE plpgsql;