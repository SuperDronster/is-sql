/* -----------------------------------------------------------------------------
	System Functions.
----------------------------------------------------------------------------- */

SET search_path TO "core";

/* -----------------------------------------------------------------------------
	Constant.

	Tag Group ID:
		1 - Unit Names
		2 - Global Enum Names
		3 - Global Enum Values
		4 - Folder Types
		5 - File Types
			'rc-item-count-file'
		6 - Resource Layout Names
		10 - RC Sides Enum Names
		11 - RC Sides Enum Values

----------------------------------------------------------------------------- */

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

/* -----------------------------------------------------------------------------
	Вызывает исключение
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION _error(
	p_code varchar,
	p_message varchar
)
RETURNS void AS $$
DECLARE
	i_code integer;
BEGIN
	IF p_code In (
		'DeveloperError',
		'NotRealized',
		'DataIsNotFound',
		'WrongData',
		'ImpossibleOperation',
		'DuplicateData',
		'Forbidden')
	THEN
		RAISE EXCEPTION USING MESSAGE = p_code || ' :: ' || p_message;
	ELSE
		RAISE EXCEPTION 'Wrong Error Code Name "%"', p_code;
	END IF;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Выводит в консоль инф. сообщение
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION _notice(
	p_message varchar
)
RETURNS void AS $$
DECLARE
	i_code integer;
BEGIN
		RAISE NOTICE USING MESSAGE = p_message;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Приводит строку символов в канонический вид
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION canonical_string(
	p_string varchar
)
RETURNS varchar AS $$
DECLARE
BEGIN
	RETURN lower(trim(p_string));
END;
$$ LANGUAGE plpgsql
IMMUTABLE;

/* -----------------------------------------------------------------------------
	Сравнивает два доменных имени A и B:
		NULL - (A <> B) 'common/red' <> 'common/green'
		0 - (A = B) 'common/red' = 'common/red'
		+1 - (A > B) 'common/' = 'common/red'
		-1 - (A < B) 'common/red' = 'common/'
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION compare_domens(
	p_domen_a varchar,
	p_domen_b varchar
)
RETURNS integer AS $$
DECLARE
	i_a integer;
	i_b integer;
BEGIN
	i_a := strpos(p_domen_a, p_domen_b);
	i_b := strpos(p_domen_b, p_domen_a);
	raise notice '% %', i_a,i_b;
	IF i_a = 1 AND i_b = 1 THEN
		RETURN 0; -- domen_a = domen_b
	END IF;
	IF
		(i_a <> 1 OR i_a IS NULL) AND
		(i_b <> 1 OR i_b IS NULL) THEN
		RETURN NULL; -- domen_a <> domen_b
	END IF;

	IF i_a = 1 THEN
		RETURN -1; -- domen_a < domen_b
	ELSE
		RETURN +1; -- domen_a > domen_b
	END IF;
END;
$$ LANGUAGE plpgsql
IMMUTABLE;

----------------------------------------------------------------------------- */
