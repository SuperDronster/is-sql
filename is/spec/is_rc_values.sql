/* -----------------------------------------------------------------------------
	resources Count File
	Constant:
---------------------------------------------------------------------------- */

SET search_path TO "spec";

-------------------------------------------------------------------------------

SELECT core.new_tag('file','kind', NULL, 'valued-items-resources-group',
	'Valued Items Reources Group');
SELECT core.new_tag('file','kind', NULL, 'valued-items-resources-object',
	'Valued Items Reources Object');

CREATE TABLE rc_values(
	rc_value core.unit_value,
	CONSTRAINT rcvalues_pkey PRIMARY KEY (file_id),

	-- Нельзя удалять тип данных ресурса
	CONSTRAINT rcvalues_rcdatatype_fk FOREIGN KEY (data_type_ptr)
		REFERENCES rc_data_type(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,

	-- Нельзя удалять пул тегов - сторон ресурса
	CONSTRAINT rcvalues_rcsides_fk FOREIGN KEY (rc_sides)
		REFERENCES core.pool(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION,

	-- Нельзя удалять вид файла - ресурса
	CONSTRAINT rcvalues_filekind_fk FOREIGN KEY (file_kind)
		REFERENCES core.tag(id) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE NO ACTION
) INHERITS(resources);

-- Triggers

CREATE OR REPLACE FUNCTION __on_before_insert_rcvalues_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_insert_rcvalues(NEW.file_id);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_rcvalues_trigger()
RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_before_delete_rcvalues(OLD.file_id,OLD.ref_counter);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER before_insert_rcvalues_trigger
	BEFORE INSERT ON rc_values FOR EACH ROW
	EXECUTE PROCEDURE __on_before_insert_rcvalues_trigger();
CREATE TRIGGER before_delete_rcvalues_trigger
	BEFORE DELETE ON rc_values FOR EACH ROW
	EXECUTE PROCEDURE __on_before_delete_rcvalues_trigger();

--------------------------------------------------------------------------------

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_before_insert_rcvalues(
	p_file_id bigint
) RETURNS void AS $$
DECLARE
	count integer;
BEGIN
	PERFORM spec.__on_before_insert_resources(p_file_id);
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION __on_before_delete_rcvalues(
	p_file_id bigint,
	p_ref_counter bigint
) RETURNS void AS $$
BEGIN
	PERFORM spec.__on_before_delete_resources(p_file_id,p_ref_counter);
END;
$$ LANGUAGE 'plpgsql';

/* -----------------------------------------------------------------------------
	Создание файла - кол-ва ресурса
---------------------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION new_rc_values(
	p_id bigint,
	p_creator_id integer,
	p_data_type_id integer,
	p_count integer,
	p_value core.unit_value,
	p_sides_pool_name varchar(128),
	p_system_name varchar(128),
	p_visual_name varchar DEFAULT NULL,
	p_color integer DEFAULT 0,
	p_is_readonly boolean DEFAULT true,
	p_is_packable boolean DEFAULT true
) RETURNS bigint AS $$
DECLARE
	res_id bigint;
	name varchar;
BEGIN
	IF p_id IS NULL THEN
		res_id := nextval('core.file_id_seq');
	ELSE
		res_id := p_id;
	END IF;

	IF p_visual_name IS NULL THEN
		name := p_system_name;
	ELSE
		name := p_visual_name;
	END IF;

	INSERT INTO spec.rc_values
	(
		file_id, creator_id, data_type_ptr, file_kind, system_name, visual_name,
		is_packable, is_readonly, color, rc_sides, rc_count, rc_value
	)
	VALUES
	(
		res_id, p_creator_id, p_data_type_id,
		core.tag_id('file','kind', 'valued-items-resources-object'),
    core.canonical_string(p_system_name), name, p_is_packable,
		p_is_readonly, p_color, core.pool_id('rc-sides', p_sides_pool_name),
		p_count, p_value
	);

	RETURN res_id;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------------------------------------
