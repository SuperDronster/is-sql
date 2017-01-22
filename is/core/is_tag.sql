/* -----------------------------------------------------------------------------
	System Functions.
----------------------------------------------------------------------------- */

SET search_path TO "core";

/*DROP TABLE IF EXISTS
	Tag
CASCADE;*/

--------------------------------------------------------------------------------

CREATE SEQUENCE tag_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TABLE Tag
(
	id bigint NOT NULL DEFAULT nextval('tag_id_seq'),
	group_id integer NOT NULL,
	system_name varchar(128) NOT NULL,
	visual_name varchar NOT NULL,
	order_index integer NOT NULL DEFAULT 0,
	CONSTRAINT tag_pkey PRIMARY KEY (id),
	CONSTRAINT tag_unique UNIQUE (group_id, system_name)
);

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

/* -----------------------------------------------------------------------------
	Создание тега
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION new_tag(
	p_group_id integer,
	p_id bigint,
	p_system_name varchar(128),
	p_visual_name varchar DEFAULT NULL,
	p_order_index integer DEFAULT 0
) RETURNS bigint AS $$
DECLARE
	visual_name varchar;
	res_id bigint;
BEGIN
	IF p_id IS NULL THEN
		res_id := nextval('core.tag_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	IF p_visual_name IS NULL THEN
		visual_name := p_system_name;
	ELSE
		visual_name := p_visual_name;
	END IF;
	INSERT INTO core.tag
	(
		id, group_id, system_name, visual_name, order_index
	)
	VALUES
	(
		res_id, p_group_id, core.canonical_string(p_system_name),
		visual_name, p_order_index
	);
	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Возвращает ид записи тега по ид группы и системному имени
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION tag_id(
	p_group_id integer,
	p_system_name varchar(128)
)
RETURNS bigint AS $$
DECLARE
	res_id bigint;
	name varchar := core.canonical_string(p_system_name);
BEGIN
	SELECT id INTO res_id
	FROM core.tag
	WHERE
		group_id = p_group_id AND
		system_name = name;

	IF NOT FOUND THEN
		PERFORM core._error('DataIsNotFound', format('Tag "%s.%s" is not found.',
			p_group_id, name));
	END IF;

	RETURN res_id;
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Возвращает визуальное имя по ид записи тега
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION tag_name(
	p_id bigint
)
RETURNS varchar AS $$
DECLARE
	res varchar;
BEGIN
	SELECT visual_name INTO res
	FROM core.tag
	WHERE
		id = p_id;

	IF NOT FOUND THEN
		PERFORM _error('DataIsNotFound', format('Tag "id=%s" is not found.', p_id));
	END IF;

	RETURN res;
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Возвращает массив ид записей тега по ид группы и массиву системных имен
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION tag_ids(
	p_group_id integer,
	p_system_names varchar,
	p_delimiter char DEFAULT ':'
) RETURNS SETOF bigint AS $$
DECLARE
	name varchar;
	res_id bigint;
	list varchar[] := regexp_split_to_array(p_system_names, p_delimiter);
BEGIN
	FOREACH name IN ARRAY list
	LOOP
		SELECT id INTO res_id
		FROM core.tag
		WHERE
			group_id = p_group_id AND
			system_name = core.canonical_string(name);

		IF NOT FOUND THEN
			PERFORM core._error('DataIsNotFound', format('Tag "%s.%s" is not found.',
				p_group_id, core.canonical_string(name)));
		END IF;

		RETURN NEXT res_id;
	END LOOP;
END;
$$ LANGUAGE 'plpgsql';
