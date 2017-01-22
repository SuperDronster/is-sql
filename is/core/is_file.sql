/* -----------------------------------------------------------------------------
	File Functions.
----------------------------------------------------------------------------- */

SET search_path TO "core";

--------------------------------------------------------------------------------

CREATE SEQUENCE file_id_seq INCREMENT BY 1 MINVALUE 1000 START WITH 1000;

CREATE TABLE file(
	file_id bigint NOT NULL,
	file_kind bigint NOT NULL REFERENCES Tag(id),
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

CREATE TABLE file_tree(
	color integer NOT NULL DEFAULT 0,
	creator_id integer NOT NULL DEFAULT 0,
	create_time timestamp NOT NULL DEFAULT now(),
	parent_file_ptr bigint NOT NULL,
	child_file_ptr bigint NOT NULL,
	CONSTRAINT file_tree_pk PRIMARY KEY (parent_file_ptr,child_file_ptr)
);
CREATE INDEX file_tree_parent_idx ON file_tree(parent_file_ptr);
CREATE INDEX file_tree_child_idx ON file_tree(child_file_ptr);

CREATE TABLE file_relation(
	parent_table_oid oid NOT NULL,
	parent_file_kind bigint NOT NULL,
	child_table_oid oid NOT NULL,
	child_file_kind bigint NOT NULL,
	child_file_count integer NOT NULL DEFAULT (-1),
	visual_name varchar DEFAULT NULL,
	CONSTRAINT file_relation_pk PRIMARY KEY (
		parent_table_oid,parent_file_kind,
		child_table_oid,child_file_kind)
);

-- Triggers

CREATE OR REPLACE FUNCTION __on_create_file_trigger() RETURNS trigger AS $$
BEGIN
	PERFORM __on_create_file(NEW.file_id);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_delete_file_trigger() RETURNS trigger AS $$
BEGIN
	PERFORM __on_delete_file_(OLD.file_id, OLD.ref_counter);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_insert_file_trigger() RETURNS trigger AS $$
DECLARE
	count integer;
BEGIN
	SELECT count(*) INTO count
	FROM core.file
	WHERE
		file_id = NEW.parent_file_ptr;

	IF NOT FOUND THEN
		PERFORM core._error('DataIsNotFound', format('Parent File "id=%s" is not found.',
			p_file_id));
	END IF;

	PERFORM core.__inc_file_ref(NEW.child_file_ptr);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_remove_file_trigger() RETURNS trigger AS $$
BEGIN
	PERFORM core.__dec_file_ref(OLD.child_file_ptr);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER remove_file_trigger
	AFTER DELETE ON file_tree FOR EACH ROW
	EXECUTE PROCEDURE __on_remove_file_trigger();

CREATE TRIGGER insert_file_trigger
	AFTER INSERT ON file_tree FOR EACH ROW
	EXECUTE PROCEDURE __on_insert_file_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_create_file(
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

CREATE OR REPLACE FUNCTION __on_delete_file(
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

/* -----------------------------------------------------------------------------
	Создает разрешение на вставку файла в дерево
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION _new_file_relation(
	p_parent_table_oid oid,
	p_parent_file_kind_tag_name varchar(128),
	p_child_table_oid oid,
	p_child_file_kind_tag_name varchar(128),
	p_child_file_count integer,
	p_name varchar
) RETURNS void AS $$
BEGIN
	INSERT INTO core.file_relation
	(
		parent_table_oid, parent_file_kind,
		child_table_oid, child_file_kind, child_file_count,
		visual_name
	)
	VALUES
	(
		p_parent_table_oid, core.tag_id(4,p_parent_file_kind_tag_name),
		p_child_table_oid, core.tag_id(4,p_child_file_kind_tag_name),
		p_child_file_count, p_name
	);
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Удаляет разрешение на вставку файла в дерево
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION _del_file_relation(
	p_parent_table_oid oid,
	p_parent_file_kind_tag_name varchar(128),
	p_child_table_oid oid,
	p_child_file_kind_tag_name varchar(128)
) RETURNS void AS $$
BEGIN
	DELETE FROM core.file_relation
	WHERE
		parent_table_oid=p_parent_table_oid AND
		parent_file_kind=core.tag_id(4,p_parent_file_kind) AND
		child_table_oid=p_child_table_oid AND
		child_file_kind=core.tag_id(4,p_child_file_kind);
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Проверяет можно ли добавить файла в дерево
----------------------------------------------------------------------------- */
CREATE  OR REPLACE FUNCTION _check_file_relation(
	p_parent_table_oid oid,
	p_parent_file_kind bigint,
	p_child_table_oid oid,
	p_child_file_kind bigint
) RETURNS integer AS $$
DECLARE
	count integer;
BEGIN
	SELECT child_file_count INTO count
	FROM core.file_relation
	WHERE
		parent_table_oid=p_parent_table_oid AND
		parent_file_kind=p_parent_file_kind AND
		child_table_oid=p_child_table_oid AND
		child_file_kind=p_child_file_kind;

	RETURN count;
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Создание дочерний ссылки на файл (через триггер у файла увеличивается счетчик
	ref_counter на 1)
------------------------------------------------------------------------------*/
CREATE OR REPLACE FUNCTION insert_file(
	p_creator_id integer,
	p_parent_file_id bigint,
	p_child_file_id bigint,
	p_color integer DEFAULT 0
) RETURNS void AS $$
DECLARE
	p_kind integer;
	p_oid oid;
	c_kind integer;
	c_oid oid;
	count integer;
	count_rel integer;
	s_name varchar;
BEGIN
	SELECT tableoid, file_kind INTO p_oid, p_kind
	FROM core.file
	WHERE
		file_id = p_parent_file_id;
	IF NOT FOUND THEN
		PERFORM core._error('DataIsNotFound', format('Parent File "id=%s" is not found.',
			p_parent_file_id));
	END IF;

	SELECT tableoid, file_kind, system_name INTO c_oid, c_kind, s_name
	FROM core.file
	WHERE
		file_id = p_child_file_id;
	IF NOT FOUND THEN
		PERFORM core._error('DataIsNotFound', format('Child File "id=%s" is not found.',
			p_child_file_id));
	END IF;

	count_rel := core._check_file_relation(p_oid, p_kind, c_oid, c_kind);
	IF count_rel IS NULL THEN
		PERFORM _error('Forbidden', format('File Relation [(%s)%s->(%s)%s] is forbidden.',
			tag_name(p_kind),p_oid::regclass, tag_name(c_kind),c_oid::regclass));
	END IF;

	IF count_rel <> -1 THEN
		SELECT count(*) INTO count
		FROM core.file_tree ft
			JOIN file fl ON (ft.child_file_ptr=fl.file_id)
		WHERE
			ft.parent_file_ptr = p_parent_file_id AND
			fl.file_kind = c_kind;

		IF count >= count_rel THEN
			PERFORM core._error('Forbidden', format('Wron Count of Child Files. Current count = %s.',
				count));
		END IF;
	END IF;

	SELECT count(*) INTO count
	FROM core.file_tree ft
		JOIN file fl ON (ft.child_file_ptr=fl.file_id)
	WHERE
		ft.parent_file_ptr = p_parent_file_id AND
		fl.system_name = s_name;

	IF count<>0 THEN
		PERFORM core._error('DuplicateData', format('Child File with name "%s" allredy exists!',
			s_name));
	END IF;

	INSERT INTO core.file_tree
	(
		color, creator_id, parent_file_ptr, child_file_ptr
	)
	VALUES
	(
		p_color, p_creator_id, p_parent_file_id, p_child_file_id
	);
END;
$$ LANGUAGE plpgsql;

/* -----------------------------------------------------------------------------
	Удаление дочерней ссылки на файл (через триггер у файла уменьшается
	ref_counter счетчик на 1)
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION remove_file(
	p_user_id integer,
	p_parent_file_id bigint,
	p_child_file_id bigint
) RETURNS boolean AS $$
DECLARE
	count integer;
BEGIN
	SELECT count(*) INTO count
	FROM core.file
	WHERE
		file_id = p_parent_file_id;
	IF count = 0 THEN
		PERFORM core._error('DataIsNotFound', format('Parent File "id=%s" is not found.',
			p_parent_file_id));
	END IF;

	SELECT count(*) INTO count
	FROM file
	WHERE
		file_id = p_child_file_id;
	IF count = 0 THEN
		PERFORM core._error('DataIsNotFound', format('Child File "id=%s" is not found.',
			p_child_file_id));
	END IF;

	DELETE FROM file_tree
	WHERE
		parent_file_ptr = p_parent_file_id AND
		child_file_ptr = p_child_file_id;
	GET DIAGNOSTICS count = ROW_COUNT;

	RETURN count <> 0;
END;
$$ LANGUAGE plpgsql;


/* -----------------------------------------------------------------------------
	Поиск корневой папки
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION root_file_id(
	p_kind_tag_name varchar(128)
) RETURNS bigint AS $$
DECLARE
	res_id bigint;
	kind_id bigint = core.tag_id(4, p_kind_tag_name);
BEGIN
	SELECT file_id INTO res_id
	FROM file
	WHERE
		file_kind = kind_id
	LIMIT 1;
	RETURN res_id;
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Поиск дочернего файла
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION child_file_id(
	p_file_id bigint,
	p_system_name varchar(128),
	p_type oid DEFAULT NULL
)
RETURNS bigint AS $$
DECLARE
	name varchar = canonical_string(p_system_name);
	res_id bigint;
	t_oid oid;
BEGIN
	SELECT fl.file_id, fl.tableoid
	INTO res_id, t_oid
	FROM core.file_tree tr
		INNER JOIN core.file fl ON(fl.file_id = tr.child_file_ptr)
	WHERE
		tr.parent_file_ptr = p_file_id AND
		fl.system_name = name
	LIMIT 1;

	IF t_oid IS NOT NULL AND t_oid <> p_type
	THEN
		PERFORM core._error('WrongData', format('Found Incompatible File ("%s"<>"%s")',
			t_oid::regclass, p_type::regclass));
	END IF;
	RETURN res_id;
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Поиск дочернего файла
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION child_files(
	p_file_id bigint
)
RETURNS TABLE(table_oid oid, file_id bigint, kind bigint,
	system_name varchar, visual_name varchar, color integer,
	is_readonly boolean, creator_id integer, create_time timestamp) AS $$
BEGIN
	RETURN QUERY
	SELECT fl.tableoid,fl.file_id, fl.file_kind, fl.system_name, fl.visual_name,
		fl.color, fl.is_readonly, fl.creator_id, fl.create_time
	FROM core.file_tree tr
		INNER JOIN core.file fl ON(fl.file_id = tr.child_file_ptr)
	WHERE
		tr.parent_file_ptr = p_file_id;
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Поиск папки начиная от корневой по иерархическому пути из системных имен
----------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION file_id(
	p_root_file_id bigint,
	p_path varchar,
	p_type oid DEFAULT NULL
) RETURNS bigint AS $$
DECLARE
	res_id bigint;
	next_name varchar;
	last_path varchar;
	pos integer;
BEGIN
	pos := strpos(p_path, '/');
	IF pos = 0 THEN
		RETURN core.child_file_id(p_root_file_id, p_path, p_type);
	ELSE
		next_name := substr(p_path, 1, pos-1);
		last_path := right(p_path, length(p_path)-pos);
		res_id := core.child_file_id(p_root_file_id, next_name, p_type);
		IF res_id IS NOT NULL THEN
			RETURN core.file_id(res_id, last_path, p_type);
		ELSE
			RETURN NULL;
		END IF;
	END IF;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION file_id(
	p_root_kind_tag_name varchar(128),
	p_path varchar,
	p_type oid DEFAULT NULL
) RETURNS bigint AS $$
BEGIN
	RETURN core.file_id(core.root_file_id(p_root_kind_tag_name), p_path, p_type);
END;
$$ LANGUAGE 'plpgsql';

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
