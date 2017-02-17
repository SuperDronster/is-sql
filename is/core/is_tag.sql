/* -----------------------------------------------------------------------------
	System Functions.
----------------------------------------------------------------------------- */

SET search_path TO "core";

--------------------------------------------------------------------------------
CREATE SEQUENCE pool_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;
CREATE SEQUENCE tag_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TABLE pool
(
	id integer NOT NULL DEFAULT nextval('pool_id_seq'),
	role_key varchar(32) NOT NULL,
	pool_key varchar(32) NOT NULL,
	visual_name varchar NOT NULL,
	order_index integer NOT NULL DEFAULT 0,
	is_system boolean NOT NULL DEFAULT true,
	CONSTRAINT pool_pkey PRIMARY KEY (id),
	CONSTRAINT pool_unique UNIQUE (role_key, pool_key)
);

CREATE TABLE tag
(
	id bigint NOT NULL DEFAULT nextval('tag_id_seq'),
	pool_ptr integer NOT NULL,
	system_name varchar(128) NOT NULL,
	visual_name varchar NOT NULL,
	order_index integer NOT NULL DEFAULT 0,
	is_system boolean NOT NULL DEFAULT true,

	-- Удаление всех тегов при удалении групы
	CONSTRAINT tag_pool_del_fk FOREIGN KEY (pool_ptr)
		REFERENCES pool(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE CASCADE,

	CONSTRAINT tag_pkey PRIMARY KEY (id),
	CONSTRAINT tag_unique UNIQUE (pool_ptr, system_name)
);

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

/* -----------------------------------------------------------------------------
	Создание тега
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION new_pool
(
	p_id integer,
	p_role_key varchar,
	p_pool_key varchar,
	p_visual_name varchar,
	p_order_index integer DEFAULT 0
) RETURNS bigint AS $$
DECLARE
	res_id bigint;
BEGIN
	IF p_id IS NULL THEN
		res_id := nextval('core.pool_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	INSERT INTO core.pool
	(
		id, role_key, pool_key, visual_name, order_index
	)
	VALUES
	(
		res_id, p_role_key, p_pool_key, p_visual_name,
		p_order_index
	);
	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pool_id
(
	p_role_key varchar(32),
	p_pool_key varchar(32)
)
RETURNS integer AS $$
DECLARE
	res_id bigint;
BEGIN
	SELECT id INTO res_id
	FROM core.pool
	WHERE
		role_key = p_role_key AND
		pool_key = p_pool_key;

	IF res_id IS NULL THEN
		PERFORM core._error('DataIsNotFound', format('Pool (%s)%s is not found.',
			p_role_key, p_pool_key));
	END IF;

	RETURN res_id;
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Создание тега
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION new_tag
(
	p_role_key varchar(32),
	p_pool_key varchar(32),
	p_id bigint,
	p_system_name varchar(128),
	p_visual_name varchar DEFAULT NULL,
	p_order_index integer DEFAULT 0,
	p_is_system boolean DEFAULT true
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
		id, pool_ptr, system_name, visual_name, order_index, is_system
	)
	VALUES
	(
		res_id, core.pool_id(p_role_key, p_pool_key),
		core.canonical_string(p_system_name), visual_name,
		p_order_index, p_is_system
	);
	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Возвращает ид записи тега по ид группы и системному имени
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION tag_id
(
	p_role_key varchar(32),
	p_pool_key varchar(32),
	p_system_name varchar(128)
)
RETURNS bigint AS $$
DECLARE
	res_id bigint;
	name varchar := core.canonical_string(p_system_name);
	pool_id integer := core.pool_id(p_role_key, p_pool_key);
BEGIN
	SELECT id INTO res_id
	FROM core.tag
	WHERE
		pool_ptr = pool_id AND
		system_name = name;

	IF NOT FOUND THEN
		PERFORM core._error('DataIsNotFound', format('Tag "(%s)%s.%s" is not found.',
			p_role_key, p_pool_key, core.canonical_string(name)));
	END IF;

	RETURN res_id;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION tag_id
(
	p_pool_id integer,
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
		pool_ptr = p_pool_id AND
		system_name = name;

	IF NOT FOUND THEN
		PERFORM core._error('DataIsNotFound',
			format('Tag "(pool id=%s).%s" is not found.',
			p_pool_id, core.canonical_string(name)));
	END IF;

	RETURN res_id;
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Возвращает визуальное имя по ид записи тега
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION tag_name
(
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
		PERFORM core._error('DataIsNotFound',
			format('Tag "id=%s" is not found.', p_id));
	END IF;

	RETURN res;
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Возвращает массив ид записей тега по ид группы и массиву системных имен
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION tag_ids
(
	p_role_key varchar(32),
	p_pool_key varchar(32),
	p_system_names varchar,
	p_delimiter char DEFAULT ':'
)
RETURNS SETOF bigint AS $$
DECLARE
	name varchar;
	s_name varchar;
	res_id bigint;
	list varchar[] := regexp_split_to_array(p_system_names, p_delimiter);
	pool_id integer := core.pool_id(p_role_key, p_pool_key);
BEGIN
	FOREACH name IN ARRAY list
	LOOP
		s_name := core.canonical_string(name);
		SELECT id INTO res_id
		FROM core.tag
		WHERE
			pool_ptr = pool_id AND
			system_name = s_name;

		IF NOT FOUND THEN
			PERFORM core._error('DataIsNotFound', format('Tag "(%s)%s.%s" is not found.',
				p_role_key, p_pool_key, core.canonical_string(name)));
		END IF;

		RETURN NEXT res_id;
	END LOOP;
END;
$$ LANGUAGE 'plpgsql';
