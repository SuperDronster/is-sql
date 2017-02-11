/* -----------------------------------------------------------------------------
	File Functions.
	Constant:
		_record_rel.type = 1 (Parent File -> Chld File Relation)
----------------------------------------------------------------------------- */

SET search_path TO "core";

--------------------------------------------------------------------------------

SELECT new_pool(NULL, 'file', 'kind', 'File Kinds.', 0);

CREATE SEQUENCE file_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TABLE file(
	file_id bigint NOT NULL,
	file_kind bigint NOT NULL REFERENCES tag(id),
	color integer NOT NULL DEFAULT 0,
	create_time timestamp NOT NULL DEFAULT now(),
	creator_id integer NOT NULL DEFAULT 0,
	ref_counter bigint NOT NULL DEFAULT 0,
	is_packable boolean NOT NULL DEFAULT true,
	is_readonly boolean NOT NULL DEFAULT false,
	system_name varchar(128) NOT NULL,
	visual_name varchar,
	CONSTRAINT file_pkey PRIMARY KEY (file_id)
);
CREATE INDEX file_refcounter_idx ON file(ref_counter);
CREATE INDEX file_system_name_idx ON file(system_name);
CREATE INDEX file_kind_idx ON file(file_kind);

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

-- API core.file----------------------------------------------------------------

CREATE OR REPLACE FUNCTION __on_before_insert_file(
	p_file_id bigint
) RETURNS void AS $$
DECLARE
	count integer;
BEGIN
	SELECT count(*) INTO count
	FROM core.file
	WHERE
		file_id = p_file_id;

	IF count <> 0 THEN
		PERFORM core._error('DuplicateData',
			format('File "id=%s" allready exists.', p_file_id));
	END IF;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_file(
	p_file_id bigint,
	p_ref_counter bigint
) RETURNS void AS $$
BEGIN
	IF p_ref_counter <> 0 THEN
		PERFORM _error('ImpossibleOperation',
			format('Can not Delete File "link counter=%s".',p_ref_counter));
	END IF;
	DELETE FROM core.file_tree
	WHERE
		parent_file_ptr = p_file_id;
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Увеличивает кол-во ссылок на файл на +1
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION __inc_file_ref(
	p_file_id bigint
) RETURNS void AS $$
DECLARE
	count integer;
BEGIN
	UPDATE core.file
	SET ref_counter = ref_counter + 1
	WHERE
		file_id = p_file_id;
	GET DIAGNOSTICS count = ROW_COUNT;

	IF count = 0  THEN
		PERFORM core._error('DataIsNotFound', format('File "id=%s" is not found.',
			p_file_id));
	END IF;
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Уменьшает кол-во ссылок на файл на -1
----------------------------------------------------------------------------- */
CREATE OR REPLACE  FUNCTION __dec_file_ref (
	p_file_id bigint
) RETURNS void AS $$
DECLARE
	count integer;
BEGIN
	UPDATE core.file
	SET ref_counter = ref_counter - 1
	WHERE
		file_id = p_file_id;
	GET DIAGNOSTICS count = ROW_COUNT;

	IF count = 0  THEN
		PERFORM core._error('DataIsNotFound', format('File "id=%s" is not found.',
			p_file_id));
	END IF;
END;
$$ LANGUAGE 'plpgsql';

-- API core.file----------------------------------------------------------------

/* -----------------------------------------------------------------------------
	Удаление записей (c 0 кол-вом ссылок) из всех таблиц наследуемых от file
------------------------------------------------------------------------------*/
CREATE  OR REPLACE FUNCTION file_pack() RETURNS integer AS $$
DECLARE
	res integer = 0;
	count integer = -1;
BEGIN
	WHILE count <> 0
	LOOP
		DELETE FROM core.file
		WHERE
			is_packable AND
			ref_counter = 0;

		GET DIAGNOSTICS count = ROW_COUNT;
		res := res + count;
	END LOOP;

	RETURN res;
END;
$$ LANGUAGE plpgsql;
