/* -----------------------------------------------------------------------------
	Enum Value Functions.
----------------------------------------------------------------------------- */

SET search_path TO "core";

--------------------------------------------------------------------------------

CREATE TABLE enum_value
(
	pool_ptr integer NOT NULL,
	value_key integer NOT NULL,
	system_name varchar(24) DEFAULT NULL,
	visual_name varchar NOT NULL,

	-- Удалять все ключи при удалении пула - перечисления
	CONSTRAINT enumvalue_del_fk FOREIGN KEY (pool_ptr)
		REFERENCES pool(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE CASCADE,

	CONSTRAINT enumvalue_pkey PRIMARY KEY (pool_ptr, value_key)
);

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

/* -----------------------------------------------------------------------------
	Создает значение перечисления
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION new_enum_value
(
	p_role_key varchar(32),
	p_pool_key varchar(32),
	p_value_key integer,
	p_visual_name varchar,
	p_system_name varchar(24) DEFAULT NULL
) RETURNS void AS $$
BEGIN
	INSERT INTO core.enum_value
	(
		pool_ptr, value_key, system_name, visual_name
	)
	VALUES
	(
		core.pool_id(p_role_key, p_pool_key),
		p_value_key, core.canonical_string(p_system_name),
		p_visual_name
	);
END;
$$ LANGUAGE plpgsql;

CREATE  OR REPLACE FUNCTION new_enum_value
(
	p_pool_id integer,
	p_value_key integer,
	p_visual_name varchar,
	p_system_name varchar(24) DEFAULT NULL
) RETURNS void AS $$
BEGIN
	INSERT INTO core.enum_value
	(
		pool_ptr, value_key, system_name, visual_name
	)
	VALUES
	(
		p_pool_id, p_value_key, core.canonical_string(p_system_name),
		p_visual_name
	);
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Возвращает визуальное наименование ключа перечисления
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION enum_value_name(
	p_pool_id integer,
	p_value_key integer
) RETURNS varchar AS $$
DECLARE
	res integer;
BEGIN
	RETURN
		(SELECT visual_name
		FROM core.enum_value
		WHERE
		 	pool_ptr = p_pool_id AND
			value_key = p_value_key);
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Возвращает числовой ключ перечисления
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION enum_value_key(
	p_pool_id integer,
	p_name varchar
) RETURNS varchar AS $$
DECLARE
	res integer;
BEGIN
	RETURN
		(SELECT value_key
		FROM core.enum_value
		WHERE
		 	pool_ptr = p_pool_id AND
			system_name = p_name);
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Возвращает битовую маску по именам ключей (значения бита) перечисления
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION enum_flags
(
	p_role_key varchar(32),
	p_pool_key varchar(32),
	p_system_names varchar,
	p_delimiter char DEFAULT ':'
)
RETURNS SETOF integer AS $$
DECLARE
	name varchar;
	res_id integer;
	list varchar[] := regexp_split_to_array(p_system_names, p_delimiter);
	pool_id integer := core.pool_id(p_role_key, p_pool_key);
BEGIN
	res_id := 0;
	FOREACH name IN ARRAY list
	LOOP
		res_id := res_id | enum_value_key(pool_id, name);
	END LOOP;
	RETURN res_id;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION enum_flags
(
	p_pool_id integer,
	p_system_names varchar,
	p_delimiter char DEFAULT ':'
)
RETURNS SETOF integer AS $$
DECLARE
	name varchar;
	res_id integer;
	list varchar[] := regexp_split_to_array(p_system_names, p_delimiter);
BEGIN
	res_id := 0;
	FOREACH name IN ARRAY list
	LOOP
		res_id := res_id | enum_value_key(p_pool_id, name);
	END LOOP;
	RETURN res_id;
END;
$$ LANGUAGE 'plpgsql';
