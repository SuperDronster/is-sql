/* -----------------------------------------------------------------------------
	Enum Value Functions.
----------------------------------------------------------------------------- */

SET search_path TO "core";

/*DROP TABLE IF EXISTS
	enum_value
CASCADE;*/

--------------------------------------------------------------------------------

CREATE TABLE enum_value
(
	enum_id bigint NOT NULL REFERENCES Tag(id),
	value_id bigint NOT NULL REFERENCES Tag(id),
	CONSTRAINT enum_value_pkey PRIMARY KEY (enum_id, value_id)
);

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

/* -----------------------------------------------------------------------------
	Создает значение перечисления
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION new_enum_value(
	p_enum_tag_name varchar(128),
	p_value_tag_name varchar(128),
	p_enum_type integer DEFAULT 2,
	p_value_type integer DEFAULT 3
) RETURNS void AS $$
DECLARE
BEGIN
	INSERT INTO core.enum_value
	(
		enum_id, value_id
	)
	VALUES
	(
		core.tag_id(p_enum_type, p_enum_tag_name),
		core.tag_id(p_value_type, p_value_tag_name)
	);
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Удаляет значение перечисления
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION del_enum_value(
	p_enum_tag_name varchar(128),
	p_value_tag_name varchar(128),
	p_enum_type integer DEFAULT 2,
	p_value_type integer DEFAULT 3
) RETURNS boolean AS $$
DECLARE
 count integer;
BEGIN
	DELETE FROM enum_value
	WHERE
		enum_id = core.tag_id(p_enum_type, p_enum_tag_name) AND
		value_id = core.tag_id(p_value_type, p_value_tag_name);
	GET DIAGNOSTICS count = ROW_COUNT;

	RETURN count <> 0;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Возвращает ид записи тега, соответствующего значению перечисления
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION enum_value_id(
	p_enum_id bigint,
	p_value_tag_name varchar(128),
	p_value_type integer DEFAULT 3
) RETURNS bigint AS $$
DECLARE
	p_value_id bigint := core.tag_id(p_value_type, p_value_tag_name);
	res integer;
BEGIN
	SELECT count(*) INTO res
	FROM enum_value
	WHERE
	 	enum_id = p_enum_id AND
		value_id = p_value_id;

	IF res = 0 THEN
		PERFORM core._error('DataIsNotFound', format('Enum Value "%s.%s" is not defined.',
			p_enum_id, p_value_tag_name));
	END IF;
	RETURN p_value_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Возвращает ид записи тега, соответствующего значению перечисления
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION enum_value_id(
	p_enum_tag_name varchar(128),
	p_value_tag_name varchar(128),
	p_enum_type integer DEFAULT 2,
	p_value_type integer DEFAULT 3
) RETURNS bigint AS $$
DECLARE
BEGIN
	RETURN core.enum_value_id(core.tag_id(p_enum_type, p_enum_tag_name),
		p_value_tag_name, p_value_type);
END;
$$ LANGUAGE plpgsql;
