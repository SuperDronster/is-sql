/* -----------------------------------------------------------------------------
	System Functions.
----------------------------------------------------------------------------- */

SET search_path TO "core";

/* -----------------------------------------------------------------------------
	Constant.

  'measure'
  'file-kind' 'folder'
  'file-kind' 'resource'
  'file-kind' 'specification'
  'rc-sides'


	Tag Group ID:
		1 - Unit Names
		2 - File Kinds
			'default-resource'
			'default-specification'
			'rc-producer-connector',
			'rc-consumer-connector',
			'rc-connection-connector'
			'rc-assoc-connector'
		3 - Resource Layout Kinds
			'item-range-node'
			'item-range-data'
		4 - Resource Layout Names
		5 - Resource Sides Enum Names
		6 - Resource Sides Enum Values
		7 - Connector Group Types
			'geometry-vertical-view'
			'geometry-horisontal-view'
			'item-range-connection'
			'resource-connection'
		8 - Specification Item Names
		9 - Specification Item Kinds

----------------------------------------------------------------------------- */

CREATE TABLE _record_rel (
  type             INTEGER NOT NULL,
  parent_table_oid OID     NOT NULL,
  parent_rec_kind  BIGINT  NOT NULL,
  child_table_oid  OID     NOT NULL,
  child_rec_kind   BIGINT  NOT NULL,
  child_rec_count  INTEGER NOT NULL DEFAULT (-1),
  visual_name      VARCHAR NOT NULL,
  CONSTRAINT _record_rel_pkey PRIMARY KEY (
    type,
    parent_table_oid, parent_rec_kind,
    child_table_oid, child_rec_kind)
);

--CREATE SEQUENCE _dataref_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

/*CREATE TABLE _data_type_def (
  type_id     INTEGER      NOT NULL,
  type_role   INTEGER      NOT NULL,
  system_name VARCHAR(128) NOT NULL,
  visual_name VARCHAR      NOT NULL,
  CONSTRAINT _type_def_pkey PRIMARY KEY (type_id)
);

CREATE UNIQUE INDEX _datatypedef_systemname_idx
  ON _data_type_def (system_name);

CREATE TABLE _data_table_def (
  type_ptr   INTEGER NOT NULL,
  table_role INTEGER NOT NULL,
  table_oid  OID     NOT NULL,
  CONSTRAINT _datatable_def_datatype_def_fk FOREIGN KEY (type_ptr)
  REFERENCES _data_type_def (type_id) MATCH SIMPLE
  ON UPDATE NO ACTION ON DELETE CASCADE,
  CONSTRAINT _data_def_pkey PRIMARY KEY (type_ptr, table_oid)
);*/

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

/* -----------------------------------------------------------------------------
	Вызывает исключение
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION _error(
  p_code    VARCHAR,
  p_message VARCHAR
)
  RETURNS VOID AS $$
DECLARE
  i_code INTEGER;
BEGIN
  IF p_code IN (
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
CREATE OR REPLACE FUNCTION _notice(
  p_message VARCHAR
)
  RETURNS VOID AS $$
DECLARE
  i_code INTEGER;
BEGIN
  RAISE NOTICE USING MESSAGE = p_message;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Приводит строку символов в канонический вид
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION canonical_string(
  p_string VARCHAR
)
  RETURNS VARCHAR AS $$
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
CREATE OR REPLACE FUNCTION compare_domens(
  p_domen_a VARCHAR,
  p_domen_b VARCHAR
)
  RETURNS INTEGER AS $$
DECLARE
  i_a INTEGER;
  i_b INTEGER;
BEGIN
  i_a := strpos(p_domen_a, p_domen_b);
  i_b := strpos(p_domen_b, p_domen_a);
  RAISE NOTICE '% %', i_a, i_b;
  IF i_a = 1 AND i_b = 1
  THEN
    RETURN 0; -- domen_a = domen_b
  END IF;
  IF
  (i_a <> 1 OR i_a IS NULL) AND
  (i_b <> 1 OR i_b IS NULL)
  THEN
    RETURN NULL; -- domen_a <> domen_b
  END IF;

  IF i_a = 1
  THEN
    RETURN -1; -- domen_a < domen_b
  ELSE
    RETURN +1; -- domen_a > domen_b
  END IF;
END;
$$ LANGUAGE plpgsql
IMMUTABLE;

--------------------------------------------------------------------------------

/* -----------------------------------------------------------------------------
	Создает разрешение на вставку файла в дерево
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION _add_record_rel(
  p_type             INTEGER,
  p_parent_table_oid OID,
  p_parent_rec_kind  BIGINT,
  p_child_table_oid  OID,
  p_child_rec_kind   BIGINT,
  p_child_rec_count  INTEGER,
  p_name             VARCHAR
)
  RETURNS VOID AS $$
BEGIN
  INSERT INTO core._record_rel
  (
    type, parent_table_oid, parent_rec_kind,
    child_table_oid, child_rec_kind, child_rec_count,
    visual_name
  )
  VALUES
    (
      p_type,
      p_parent_table_oid, p_parent_rec_kind,
      p_child_table_oid, p_child_rec_kind,
      p_child_rec_count, p_name
    );
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Проверяет можно ли добавить файла в дерево
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION _check_record_rel(
  p_type             INTEGER,
  p_parent_table_oid OID,
  p_parent_rec_kind  BIGINT,
  p_child_table_oid  OID,
  p_child_rec_kind   BIGINT
)
  RETURNS INTEGER AS $$
DECLARE
  count INTEGER;
BEGIN
  SELECT child_rec_count
  INTO count
  FROM core._record_rel
  WHERE
    type = p_type AND
    parent_table_oid = p_parent_table_oid AND
    parent_rec_kind = p_parent_rec_kind AND
    child_table_oid = p_child_table_oid AND
    child_rec_kind = p_child_rec_kind;

  RETURN count;
END;
$$ LANGUAGE plpgsql;
