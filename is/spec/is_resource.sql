/* -----------------------------------------------------------------------------
	Resource File and System
	Constant.
		tag.group_id = 2 (File Kind Tags)
----------------------------------------------------------------------------- */

SET search_path TO "spec";

--------------------------------------------------------------------------------

SELECT core.new_tag(2,NULL, 'default-resource', 'Default Resource File.');

CREATE TABLE resource(
	rc_data_type integer DEFAULT NULL,
	rc_sides bigint NOT NULL,
	CONSTRAINT resource_pkey PRIMARY KEY (file_id)
) INHERITS(core.file);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION __on_delete_resource_trigger() RETURNS trigger AS $$
BEGIN
	PERFORM spec.__on_delete_resource(OLD.file_id,OLD.ref_counter);
	RETURN OLD;
END;
$$ LANGUAGE 'plpgsql';

/*CREATE OR REPLACE FUNCTION __on_create_resource_trigger() RETURNS trigger AS $$
BEGIN
	PERFORM core.__on_create_file(NEW.file_id);
	RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';*/

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ --

CREATE OR REPLACE FUNCTION __on_delete_resource(
	p_file_id bigint,
	p_ref_counter bigint
) RETURNS void AS $$
BEGIN
	DELETE FROM spec.rc_layout
	WHERE
		resource_ptr = p_file_id AND
		parent_ptr IS NULL;

	PERFORM core.__on_delete_file(p_file_id, p_ref_counter);
END;
$$ LANGUAGE 'plpgsql';
