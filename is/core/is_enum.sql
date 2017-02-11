/* -----------------------------------------------------------------------------
	Enum Value Functions.
----------------------------------------------------------------------------- */

SET search_path TO "core";

--------------------------------------------------------------------------------

CREATE TABLE enum_value
(
	pool_ptr integer NOT NULL,
	value_key integer NOT NULL,
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
	p_visual_name varchar
) RETURNS void AS $$
BEGIN
	INSERT INTO core.enum_value
	(
		pool_ptr, value_key, visual_name
	)
	VALUES
	(
		core.pool_id(p_role_key, p_pool_key),
		p_value_key, p_visual_name
	);
END;
$$ LANGUAGE plpgsql;

CREATE  OR REPLACE FUNCTION new_enum_value
(
	p_pool_id integer,
	p_value_key integer,
	p_visual_name varchar
) RETURNS void AS $$
BEGIN
	INSERT INTO core.enum_value
	(
		pool_ptr, value_key, visual_name
	)
	VALUES
	(
		p_pool_id, p_value_key, p_visual_name
	);
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Возвращает наименование ключа перечисления
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
