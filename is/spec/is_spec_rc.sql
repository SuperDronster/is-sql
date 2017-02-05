/* -----------------------------------------------------------------------------
	Specification Item
	Constant:
		_record_rel.type = 3 (Spec Item -> Spec Item)
----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_pool(NULL, 'names', 'spec-rc', 'Spec Resource Names.', 0);
SELECT core.new_pool(NULL, 'node-kind', 'spec-rc', 'Spec Resource Nodes.', 0);

SELECT core.new_tag('node-kind','spec-rc', NULL, 'item-count', 'Item Count Spec Resource');
SELECT core.new_tag('node-kind','spec-rc', NULL, 'group', 'Spec Resource Group');

CREATE SEQUENCE specrc_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TABLE spec_rc(
	specrc_id bigint NOT NULL DEFAULT nextval('spec.specrc_id_seq'),
	specrc_kind bigint NOT NULL REFERENCES core.tag(id),
	parent_ptr bigint DEFAULT NULL,
	specification_ptr bigint NOT NULL,
	resource_ptr bigint DEFAULT NULL,
	name bigint NOT NULL REFERENCES core.tag(id),
	color integer NOT NULL DEFAULT 0,
	CONSTRAINT spec_rc_pkey PRIMARY KEY (specrc_id)
);

CREATE INDEX spec_rc_spec_ptr_idx ON spec_rc(specification_ptr);
CREATE INDEX spec_rc_parent_ptr_idx ON spec_rc(parent_ptr);

-- Triggers

CREATE OR REPLACE FUNCTION __on_before_insert_specrc_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_insert_specrc(NEW.specrc_id, NEW.specrc_kind,
		'spec.spec_rc'::regclass, NEW.specification_ptr, NEW.parent_ptr,
		NEW.resource_ptr);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_specrc_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_delete_specrc(OLD.specrc_id,
		OLD.resource_ptr);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER before_delete_specrc_trigger
	BEFORE DELETE ON spec_rc FOR EACH ROW
	EXECUTE PROCEDURE __on_before_delete_specrc_trigger();

CREATE TRIGGER before_insert_specrc_trigger
	BEFORE INSERT ON spec_rc FOR EACH ROW
	EXECUTE PROCEDURE __on_before_insert_specrc_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_before_insert_specrc(
	p_specrc_id bigint,
	p_specrc_kind bigint,
	p_specrc_oid oid,
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
	FROM spec.spec_rc
	WHERE
		specrc_id = p_specrc_id;
	IF count <> 0 THEN
		PERFORM core._error('DuplicateData',
			format('Spec Item "id=%s" allready exists.', p_specrc_id));
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
		SELECT tableoid,specrc_kind INTO p_oid, p_kind
		FROM spec.spec_rc
		WHERE
			specrc_id = p_parent_id;
		IF NOT FOUND THEN
			PERFORM core._error('DataIsNotFound',
				format('Parent Spec Item "id=%s" is not found.',
					p_parent_id));
		END IF;

		count := core._check_record_rel(3, p_oid, p_kind,
			p_specrc_oid, p_specrc_kind);
		IF count IS NULL THEN
			PERFORM core._error('Forbidden',
				format('Spec Item Relation [(%s)%s->(%s)%s] is forbidden.',
				core.tag_name(p_kind),p_oid::regclass,
				core.tag_name(p_specrc_kind),p_specrc_oid::regclass));
		END IF;
	END IF;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_specrc(
	p_specrc_id bigint,
	p_resource_id bigint
) RETURNS void AS $$
BEGIN
	DELETE FROM spec.spec_rc
	WHERE
		parent_ptr = p_specrc_id;
	IF p_resource_id IS NOT NULL
	THEN
		-- уменьшаем кол-во ссылок в объекте - ресурс
		PERFORM core.__dec_file_ref(p_resource_id);
	END IF;
END;
$$ LANGUAGE 'plpgsql';

CREATE  OR REPLACE FUNCTION _add_specrc_rel(
	p_parent_table_oid oid,
	p_parent_rec_kind_tag_name varchar(128),
	p_child_table_oid oid,
	p_child_rec_kind_tag_name varchar(128),
	p_child_rec_count integer,
	p_name varchar
) RETURNS void AS $$
BEGIN
	PERFORM core._add_record_rel(3, p_parent_table_oid,
		core.tag_id('node-kind','spec-rc', p_parent_rec_kind_tag_name),
		p_child_table_oid,
		core.tag_id('node-kind','spec-rc', p_child_rec_kind_tag_name),
		p_child_rec_count, p_name
	);
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Создание записи раскладки ресурса диапазона кол-ва элементов
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_spec_rc(
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
		res_id := nextval('spec.specrc_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	INSERT INTO spec.spec_rc
	(
		specrc_id, specrc_kind, parent_ptr, specification_ptr,
		resource_ptr, name, color
	)
	VALUES
	(
		res_id, core.tag_id('node-kind','spec-rc', p_kind_tag_name),
		p_parent_id, p_specification_id,
		p_resource_id, core.tag_id('names','spec-rc', p_name_tag_name),
		p_color
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Находит Spec Item для specification по строке пути
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION spec_rc(
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

	SELECT specrc_id, resource_ptr IS NOT NULL
	INTO prev_id, is_resource
	FROM spec.spec_rc
	WHERE
			name = name_id AND
			specification_ptr = p_specification_id AND
	  	parent_ptr IS NULL;

	IF count > 1 THEN
		FOR i IN 2..count
		LOOP
			curr_path := curr_path || '/' || names[i];
			name_id := core.tag_id('names','spec-rc', names[i]);

			SELECT specrc_id, resource_ptr IS NOT NULL
			INTO curr_id, is_resource
			FROM spec.spec_rc
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
