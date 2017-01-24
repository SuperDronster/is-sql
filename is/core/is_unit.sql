/* -----------------------------------------------------------------------------
	Unit Value Functions.
	_record_rel.type = 1 (Parent File -> Chld File Relation)
	tag.group_id = 1 (Unit Name Tags)
----------------------------------------------------------------------------- */

SET search_path TO "core";

/*DROP TABLE IF EXISTS
	Unit
CASCADE;
DROP SEQUENCE IF EXISTS
	unit_id_seq
CASCADE;
DROP TYPE IF EXISTS
	unit_info,
	unit_value
CASCADE;
DROP CAST IF EXISTS
	(unit_value AS varchar)
CASCADE;*/

--------------------------------------------------------------------------------

CREATE TYPE unit_info AS
(
	id integer,
	kind bigint,
	visual_name text,
	basa_unit_ptr integer,
	to_Kf double precision,
	fr_Kf double precision
);
CREATE TYPE unit_value AS
(
	unit_id integer,
	value double precision
);

CREATE SEQUENCE unit_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TABLE Unit
(
	id integer NOT NULL DEFAULT nextval('unit_id_seq'),
	kind bigint NOT NULL REFERENCES Tag(id),
	order_index integer DEFAULT 0,
	basa_unit_ptr integer DEFAULT NULL REFERENCES Unit(id),
	system_name varchar(24) NOT NULL,
	visual_name varchar NOT NULL,
	format_number_string varchar NOT NULL,
	format_result_string varchar NOT NULL,
	to_kf float NOT NULL DEFAULT 1.0,
	fr_kf float NOT NULL DEFAULT 1.0,
	CONSTRAINT unit_pkey PRIMARY KEY (id),
	CONSTRAINT unit_unique UNIQUE (system_name)
);

-- Cast

CREATE OR REPLACE FUNCTION string(
	p_unit_value unit_value
	--p_is_ext boolean DEFAULT false
) RETURNS varchar AS $$
DECLARE
	f_number_str varchar;
	f_result_str varchar;
	u_kind integer;
BEGIN
	SELECT format_number_string, format_result_string, kind
	INTO f_number_str, f_result_str, u_kind
	FROM core.unit
	WHERE
		id = p_unit_value.unit_id;

	IF NOT FOUND THEN
		PERFORM core._error('DataIsNotFound', format('Unit "id=%s" is not found.',
			p_id));
	END IF;

	--IF p_is_ext THEN
	--	RETURN '(' || tag_name(1,u_kind) || ') ' ||
	--		format(f_result_str, to_char(p_unit_value.value,f_number_str));
	--ELSE
		RETURN format(f_result_str, to_char(p_unit_value.value,f_number_str));
	--END IF;
END;
$$ LANGUAGE 'plpgsql';

CREATE CAST (unit_value AS varchar)
	WITH FUNCTION core.string(unit_value) AS ASSIGNMENT;

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

/* -----------------------------------------------------------------------------
	Создание ЕИ (описанние единицы измерения)
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION new_unit(
	p_id integer,
	p_kind_tag_name varchar(128),
	p_system_name varchar(24),
	p_visual_name varchar,
	p_to_kf double precision,
	p_fr_kf double precision,
	p_format_number_string varchar,
	p_format_result_string varchar,
	p_order_index integer DEFAULT 0,
	p_basa_unit_ptr integer DEFAULT NULL
) RETURNS integer AS $$
DECLARE
	res_id integer;
BEGIN
	IF p_id is NULL THEN
		res_id := nextval('core.unit_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	INSERT INTO core.unit
	(
		id, kind, order_index, basa_unit_ptr, system_name, visual_name,
		to_kf, fr_kf, format_number_string, format_result_string
	)
	VALUES
	(
		res_id, core.tag_id(1,p_kind_tag_name), p_order_index, p_basa_unit_ptr,
		core.canonical_string(p_system_name), p_visual_name, p_to_kf, p_fr_kf,
		p_format_number_string, p_format_result_string
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Возвращает ID ЕИ по имени
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION unit_id(
	p_system_name varchar(24)
) RETURNS integer AS $$
DECLARE
	name varchar := canonical_string(p_system_name);
	res_id integer;
BEGIN
	SELECT id INTO res_id
	FROM core.unit
	WHERE
		system_name = name;

	IF NOT FOUND THEN
		PERFORM core._error('DataIsNotFound', format('Unit "%s" is not found.', name));
	END IF;

	RETURN res_id;
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Создает структуру значение + ЕИ
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION unit_value(
	p_value double precision,
	p_system_name varchar(24),
	p_is_to_basa_unit boolean DEFAULT false
) RETURNS core.unit_value AS $$
DECLARE
	name varchar := core.canonical_string(p_system_name);
	res_id integer;
	s_info unit_info;
	t_info unit_info;
BEGIN
	IF p_is_to_basa_unit THEN
		s_info := core.unit_info(canonical_string(name));
		IF s_info.id = s_info.basa_unit_ptr THEN
			RETURN (s_info.id, p_value)::unit_value;
		ELSE
			t_info := core.unit_info(s_info.basa_unit_ptr);
			RETURN (t_info.id, p_value * s_info.to_Kf * t_info.fr_Kf)::unit_value;
		END IF;
	ELSE
		SELECT id INTO res_id
		FROM core.unit
		WHERE
			system_name = name;

		IF NOT FOUND THEN
			PERFORM _error('DataIsNotFound', format('Unit "%s" is not found.', name));
		END IF;
		RETURN (res_id, p_value)::core.unit_value;
	END IF;

END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Возращает имя базовой единиы (БЕ) и коэффициент для преобразования в БЕ
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION unit_info(
	p_system_name varchar
) RETURNS core.unit_info AS $$
DECLARE
	res core.unit_info;
	name varchar := core.canonical_string(p_system_name);
BEGIN
	SELECT u1.id, u1.kind, u1.visual_name, u1.to_kf, u1.fr_kf, u2.id
	INTO res.id, res.kind, res.visual_name, res.to_Kf, res.fr_Kf, res.basa_unit_ptr
	FROM core.unit u1 LEFT JOIN Unit u2 ON(u1.basa_unit_ptr=u2.id)
	WHERE
		u1.system_name = name;

	IF NOT FOUND THEN
		PERFORM core._error('DataIsNotFound', format('Source Unit "%s" is not found.',
			name));
	END IF;

	IF res.basa_unit_ptr IS NULL THEN
		res.basa_unit_ptr := res.id;
	END IF;

	RETURN res;
END;
$$ LANGUAGE 'plpgsql';
CREATE OR REPLACE FUNCTION unit_info(
	p_unit_id integer
) RETURNS core.unit_info AS $$
DECLARE
	res core.unit_info;
	name varchar;
BEGIN
	SELECT u1.id, u1.kind, u1.visual_name, u1.to_kf, u1.fr_kf, u2.id
	INTO res.id, res.kind, res.visual_name, res.to_Kf, res.fr_Kf, res.basa_unit_ptr
	FROM core.unit u1 LEFT JOIN Unit u2 ON(u1.basa_unit_ptr=u2.id)
	WHERE
		u1.id = p_unit_id;

	IF NOT FOUND THEN
		PERFORM core._error('DataIsNotFound', format('Source Unit "id=%s" is not found.',
			p_unit_id));
	END IF;

	IF res.basa_unit_ptr IS NULL THEN
		res.basa_unit_ptr := res.id;
	END IF;

	RETURN res;
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Конвертирует численное значение из одной ЕИ в другую
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION convert_unit_value(
	p_source_unit_value core.unit_value,
	p_target_system_name varchar(24)
) RETURNS double precision AS $$
DECLARE
	s_info core.unit_info;
	t_info core.unit_info;
BEGIN
	s_info := unit_info(p_source_unit_value.unit_id);
	t_info := unit_info(canonical_string(p_target_system_name));

	IF s_info.basa_unit_ptr <> t_info.basa_unit_ptr THEN
		PERFORM core._error('ImpossibleOperation',
			format('Can not convert Unit %s to Unit %s.',
			p_source_system_name,p_target_system_name));
	END IF;

	RETURN p_source_unit_value.value * s_info.to_Kf * t_info.fr_Kf;
END;
$$ LANGUAGE 'plpgsql';
