CREATE TABLE IF NOT EXISTS person (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(50) NOT NULL);

CREATE TABLE IF NOT EXISTS _user (person_id INTEGER PRIMARY KEY NOT NULL,
                                is_active BOOLEAN DEFAULT FALSE,
                                FOREIGN KEY(person_id) REFERENCES person (id) ON DELETE CASCADE);

CREATE TABLE IF NOT EXISTS _level (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(30) NOT NULL UNIQUE);

CREATE TABLE IF NOT EXISTS _location (id SERIAL PRIMARY KEY NOT NULL,
                                level_id INTEGER NOT NULL,
                                _name VARCHAR(50) NOT NULL UNIQUE,
                                FOREIGN KEY(level_id) REFERENCES _level (id) ON DELETE CASCADE);

CREATE TABLE IF NOT EXISTS monster (person_id INTEGER PRIMARY KEY NOT NULL,
                                location_id INTEGER NOT NULL,
                                motherland_id INTEGER NOT NULL,
                                FOREIGN KEY(person_id) REFERENCES person (id) ON DELETE CASCADE,
                                FOREIGN KEY(motherland_id) REFERENCES _location (id) ON DELETE RESTRICT,
                                FOREIGN KEY(location_id) REFERENCES _location (id) ON DELETE RESTRICT);

CREATE TABLE IF NOT EXISTS torture (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(50) NOT NULL UNIQUE,
                                monster_id INTEGER,
                                creator_id INTEGER NOT NULL,
                                handler_id INTEGER,
                                FOREIGN KEY(monster_id) REFERENCES monster (person_id) ON DELETE SET NULL,
                                FOREIGN KEY(creator_id) REFERENCES _user (person_id) ON DELETE NO ACTION,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE NO ACTION);

CREATE TABLE IF NOT EXISTS soul (person_id INTEGER PRIMARY KEY NOT NULL,
                                birth_date DATE NOT NULL CHECK (birth_date < '2003-01-01'),
                                date_of_death DATE NOT NULL CHECK (date_of_death < '2022-01-01' AND birth_date < date_of_death),
                                is_working BOOLEAN DEFAULT false,
                                is_distributed BOOLEAN DEFAULT false,
                                handler_id INTEGER,
                                torture_id INTEGER,
                                FOREIGN KEY(person_id) REFERENCES person (id) ON DELETE CASCADE,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE NO ACTION,
                                FOREIGN KEY(torture_id) REFERENCES torture (id) ON DELETE SET NULL);

CREATE TABLE IF NOT EXISTS sin_type (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(50) NOT NULL UNIQUE,
                                _weight REAL NOT NULL CHECK (_weight > 0 AND _weight > 0),
                                handler_id INTEGER,
                                creator_id INTEGER,
                                torture_id INTEGER,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE NO ACTION,
                                FOREIGN KEY(creator_id) REFERENCES _user (person_id) ON DELETE NO ACTION,
                                FOREIGN KEY(torture_id) REFERENCES torture (id) ON DELETE SET NULL);

CREATE TABLE IF NOT EXISTS _status (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(30) NOT NULL UNIQUE);

CREATE TABLE IF NOT EXISTS complaint (id SERIAL PRIMARY KEY NOT NULL,
                                title VARCHAR(50) NOT NULL,
                                body VARCHAR(1000) NOT NULL,
                                soul_id INTEGER,
                                status_id INTEGER DEFAULT 1,
                                handler_id INTEGER,
                                FOREIGN KEY(soul_id) REFERENCES soul (person_id) ON DELETE CASCADE,
                                FOREIGN KEY(status_id) REFERENCES _status (id) ON DELETE SET DEFAULT,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE NO ACTION);

CREATE TABLE IF NOT EXISTS _event (id SERIAL PRIMARY KEY NOT NULL,
                                _text VARCHAR(500) NOT NULL,
                                soul_id INTEGER,
                                _date DATE NOT NULL,
                                status_id INTEGER DEFAULT 1,
                                handler_id INTEGER,
                                FOREIGN KEY(soul_id) REFERENCES soul (person_id) ON DELETE CASCADE,
                                FOREIGN KEY(status_id) REFERENCES _status (id) ON DELETE SET DEFAULT,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE NO ACTION);

CREATE TABLE IF NOT EXISTS work (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(50) NOT NULL UNIQUE,
                                location_id INTEGER NOT NULL,
                                creator_id INTEGER NOT NULL,
                                FOREIGN KEY(location_id) REFERENCES _location (id) ON DELETE RESTRICT,
                                FOREIGN KEY(creator_id) REFERENCES _user (person_id) ON DELETE NO ACTION);

CREATE TABLE IF NOT EXISTS sin_type_distribution_list (
                                event_id INTEGER NOT NULL,
                                sin_type_id INTEGER NOT NULL,
                                FOREIGN KEY(event_id) REFERENCES _event (id) ON DELETE CASCADE,
                                FOREIGN KEY(sin_type_id) REFERENCES sin_type (id) ON DELETE CASCADE);

CREATE TABLE IF NOT EXISTS work_list (
                                soul_id INTEGER NOT NULL,
                                work_id INTEGER NOT NULL,
                                FOREIGN KEY(soul_id) REFERENCES soul (person_id) ON DELETE CASCADE,
                                FOREIGN KEY(work_id) REFERENCES work (id) ON DELETE CASCADE);


CREATE MATERIALIZED VIEW active_user
    AS SELECT person_id FROM _user WHERE _user.is_active=true;


CREATE OR REPLACE FUNCTION authorize_after_creating() RETURNS TRIGGER
    AS $$
        BEGIN
            IF EXISTS (SELECT person_id FROM _user JOIN person on _user.person_id = person.id  WHERE person._name='UNAUTHORIZED') AND NEW.person_id IN (SELECT person_id FROM _user JOIN person on _user.person_id = person.id  WHERE person._name='UNAUTHORIZED') THEN
                UPDATE _user SET is_active=true WHERE _user.person_id=NEW.person_id;
            END IF;

            REFRESH MATERIALIZED VIEW active_user;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql;


CREATE TRIGGER tr_authorize_after_creating AFTER INSERT ON _user
    FOR EACH ROW WHEN (pg_trigger_depth() = 0) EXECUTE PROCEDURE authorize_after_creating();


CREATE OR REPLACE FUNCTION authorize_for_trigger() RETURNS TRIGGER
    AS $$
        BEGIN
            IF NEW.is_active=true AND (NEW.person_id NOT IN (SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE (person._name='DELETED')))
                                  AND (NEW.person_id NOT IN (SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE (person._name='AUTO')))
                                  AND (NEW.person_id NOT IN (SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE (person._name='UNAUTHORIZED'))) THEN
                UPDATE _user SET is_active=false WHERE (NEW.person_id != _user.person_id);
            ELSE
                UPDATE _user SET is_active=false;
                UPDATE _user SET is_active=true WHERE _user.person_id IN (SELECT _user.person_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='UNAUTHORIZED');
            END IF;

            REFRESH MATERIALIZED VIEW active_user;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql;


CREATE TRIGGER tr_authorize AFTER UPDATE OF is_active ON _user
FOR EACH ROW WHEN (pg_trigger_depth() = 0) EXECUTE PROCEDURE authorize_for_trigger();


CREATE OR REPLACE FUNCTION make_soul_working() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            DELETE FROM work_list WHERE soul_id = NEW.soul_id;
            UPDATE soul SET is_working=true WHERE person_id=NEW.soul_id;
            UPDATE soul SET handler_id=active_user_id WHERE soul.person_id=NEW.soul_id;
            UPDATE soul SET is_distributed=true WHERE soul.person_id=NEW.soul_id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_make_soul_working BEFORE INSERT ON work_list
FOR EACH ROW EXECUTE PROCEDURE make_soul_working();


CREATE OR REPLACE FUNCTION update_work_list() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            UPDATE soul SET is_distributed=false WHERE soul.person_id=OLD.soul_id;
            UPDATE soul SET is_working=true WHERE soul.person_id=OLD.soul_id;
            UPDATE soul SET handler_id=active_user_id WHERE soul.person_id=OLD.soul_id;
            DELETE FROM work_list WHERE soul_id=NEW.soul_id;
            UPDATE soul SET is_working=true WHERE person_id=NEW.soul_id;
            UPDATE soul SET handler_id=active_user_id WHERE soul.person_id=NEW.soul_id;
            UPDATE soul SET is_distributed=true WHERE soul.person_id=NEW.soul_id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_work_list BEFORE UPDATE OF soul_id ON work_list
    FOR EACH ROW EXECUTE PROCEDURE update_work_list();


CREATE OR REPLACE FUNCTION delete_from_work_list() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            UPDATE soul SET is_distributed=false WHERE soul.person_id=OLD.soul_id;
            UPDATE soul SET is_working=true WHERE soul.person_id=OLD.soul_id;
            UPDATE soul SET handler_id=active_user_id WHERE soul.person_id=OLD.soul_id;
            return OLD;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_delete_from_work_list AFTER DELETE ON work_list
    FOR EACH ROW EXECUTE PROCEDURE delete_from_work_list();


CREATE OR REPLACE FUNCTION create_work() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            UPDATE work SET creator_id=active_user_id WHERE NEW.id=work.id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_create_work AFTER INSERT ON work
    FOR EACH ROW EXECUTE PROCEDURE create_work();


CREATE OR REPLACE FUNCTION distribute_soul_by_hand() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            UPDATE soul SET is_working=false WHERE soul.person_id = OLD.person_id;
            UPDATE soul SET handler_id=active_user_id WHERE soul.person_id = OLD.person_id;
            UPDATE soul SET is_distributed=true WHERE soul.person_id = OLD.person_id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_distribute_soul_by_hand AFTER UPDATE OF torture_id ON soul
    FOR EACH ROW EXECUTE PROCEDURE distribute_soul_by_hand();


CREATE OR REPLACE FUNCTION create_event() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
            date_of_birth DATE;
            death_date DATE;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            SELECT birth_date INTO date_of_birth FROM soul WHERE soul.person_id = NEW.soul_id;
            SELECT date_of_death INTO death_date FROM soul WHERE soul.person_id = NEW.soul_id;

            IF NEW._date < date_of_birth OR DATE_PART('year', NEW._date) - DATE_PART('year', date_of_birth) < 18
                OR NEW._date > death_date THEN
                RAISE EXCEPTION 'INVALID DATE';
            ELSE
                UPDATE _event SET handler_id=active_user_id WHERE _event.id=NEW.id;
                return NEW;
            END IF;
        END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_event AFTER INSERT ON _event
    FOR EACH ROW EXECUTE PROCEDURE create_event();


CREATE OR REPLACE FUNCTION handle_event_through_list() RETURNS TRIGGER
AS $$
DECLARE
    active_user_id INTEGER;
    approved_status_id INTEGER;
BEGIN
    SELECT person_id INTO active_user_id FROM active_user;
    SELECT id INTO approved_status_id FROM _status WHERE _status._name='Одобрено';
    UPDATE _event SET handler_id=active_user_id WHERE _event.id=NEW.event_id;
    UPDATE _event SET status_id=approved_status_id WHERE _event.id=NEW.event_id;
    return NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_handle_event_through_list BEFORE INSERT ON sin_type_distribution_list
    FOR EACH ROW EXECUTE PROCEDURE handle_event_through_list();


CREATE OR REPLACE FUNCTION handle_event() RETURNS TRIGGER
AS $$
DECLARE
    active_user_id INTEGER;
    non_handled_status_id INTEGER;
    denied_status_id INTEGER;
BEGIN
    SELECT person_id INTO active_user_id FROM active_user;
    SELECT id INTO non_handled_status_id FROM _status WHERE _status._name='Не обработано';
    SELECT id INTO denied_status_id FROM _status WHERE _status._name='Отказано';
    IF NEW.status_id=non_handled_status_id OR NEW.status_id=denied_status_id THEN
        DELETE FROM sin_type_distribution_list WHERE event_id=NEW.id;
    END IF;
    UPDATE _event SET handler_id=active_user_id WHERE _event.id=NEW.id;
    return NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_handle_event AFTER UPDATE OF status_id ON _event
    FOR EACH ROW EXECUTE PROCEDURE handle_event();


CREATE OR REPLACE FUNCTION update_event_list() RETURNS TRIGGER
AS $$
DECLARE
    active_user_id INTEGER;
    approved_status_id INTEGER;
    non_handled_status_id INTEGER;
BEGIN
    SELECT person_id INTO active_user_id FROM _user WHERE _user.is_active=true;
    SELECT id INTO approved_status_id FROM _status WHERE _status._name='Одобрено';
    SELECT id INTO non_handled_status_id FROM _status WHERE _status._name='Не обработано';
    UPDATE _event SET handler_id=active_user_id WHERE _event.id=NEW.event_id;
    UPDATE _event SET status_id=approved_status_id WHERE _event.id=NEW.event_id;
    IF NOT EXISTS (SELECT * FROM sin_type_distribution_list WHERE event_id = OLD.event_id) THEN
        UPDATE _event SET status_id=non_handled_status_id WHERE _event.id=OLD.event_id;
    END IF;
    return NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_event_list AFTER UPDATE OF event_id ON sin_type_distribution_list
    FOR EACH ROW EXECUTE PROCEDURE update_event_list();


CREATE OR REPLACE FUNCTION delete_from_event_list() RETURNS TRIGGER
AS $$
DECLARE
    non_handled_status_id INTEGER;
BEGIN
    SELECT id INTO non_handled_status_id FROM _status WHERE _status._name='Не обработано';
    IF NOT EXISTS (SELECT * FROM sin_type_distribution_list WHERE event_id = OLD.event_id) THEN
        UPDATE _event SET status_id=non_handled_status_id WHERE _event.id=OLD.event_id;
    END IF;
    return NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_delete_from_event_list AFTER DELETE ON sin_type_distribution_list
    FOR EACH ROW EXECUTE PROCEDURE delete_from_event_list();


/*
CREATE OR REPLACE FUNCTION authorize(id integer) RETURNS void
    AS $$
        BEGIN
            IF (id NOT IN (SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='DELETED'))
                                  AND (id NOT IN (SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='AUTO'))
                                  AND (id NOT IN (SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='UNAUTHORIZED')) THEN
                UPDATE _user SET is_active=false WHERE _user.person_id != id;
                UPDATE _user SET is_active=true WHERE _user.person_id = id;
            END IF;

            IF ((id IN (SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE (person._name='DELETED')))
                OR (id IN (SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE (person._name='AUTO')))
                OR (id IN (SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='UNAUTHORIZED'))) THEN
                UPDATE _user SET is_active=false;
            END IF;

            IF NOT EXISTS (SELECT * FROM _user WHERE is_active=true) THEN
                UPDATE _user SET is_active=true WHERE id IN (SELECT _user.person_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='UNAUTHORIZED');
            END IF;

            REFRESH MATERIALIZED VIEW active_user;
        END;
    $$ LANGUAGE plpgsql;
*/

/*
CREATE OR REPLACE FUNCTION delete_work() RETURNS TRIGGER
    AS $$
        BEGIN
            UPDATE soul SET is_distributed=false WHERE soul.person_id = (SELECT soul_id FROM work_list WHERE work_list.work_id = OLD.id);
            UPDATE soul SET is_working=true WHERE soul.person_id = (SELECT soul_id FROM work_list WHERE work_list.work_id = OLD.id);
            return OLD;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_delete_work BEFORE DELETE ON work
    FOR EACH ROW EXECUTE PROCEDURE delete_work();
*/

/*
//todo
CREATE OR REPLACE PROCEDURE distribute_soul_by_algo(id integer)
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            UPDATE soul SET is_working=false WHERE soul.person_id = id;
            UPDATE soul SET handler_id=auto_id WHERE soul.person_id = id;
            UPDATE soul SET is_distributed=true WHERE soul.person_id = id;
    END;
    $$ LANGUAGE plpgsql;
*/



CREATE OR REPLACE FUNCTION handle_complaint() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            UPDATE complaint SET handler_id=active_user_id WHERE complaint.id=NEW.id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_handle_complaint AFTER UPDATE OF status_id ON complaint
    FOR EACH ROW EXECUTE PROCEDURE handle_complaint();


CREATE OR REPLACE FUNCTION create_sin_type() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            UPDATE sin_type SET creator_id=active_user_id WHERE NEW.id=sin_type.id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_create_sin_type AFTER INSERT ON sin_type
    FOR EACH ROW EXECUTE PROCEDURE create_sin_type();


CREATE OR REPLACE FUNCTION handle_sin_type() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            UPDATE sin_type SET handler_id=active_user_id WHERE NEW.id=sin_type.id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_handle_sin_type AFTER UPDATE OF torture_id ON sin_type
    FOR EACH ROW EXECUTE PROCEDURE handle_sin_type();


CREATE OR REPLACE FUNCTION delete_user() RETURNS TRIGGER 
    AS $$
        BEGIN
            UPDATE complaint SET handler_id = (
                SELECT person_id FROM _user JOIN person ON _user.person_id = person.id WHERE person.name = 'DELETED'
                ) WHERE complaint.handler_id=OLD.person_id;

            UPDATE soul SET handler_id = (
                SELECT person_id FROM _user JOIN person ON _user.person_id = person.id WHERE person.name = 'DELETED'
                ) WHERE soul.handler_id=OLD.person_id;

            UPDATE sin_type SET handler_id = (
                SELECT person_id FROM _user JOIN person ON _user.person_id = person.id WHERE person.name = 'DELETED'
                ) WHERE sin_type.handler_id=OLD.person_id;

            UPDATE sin_type SET creator_id = (
                SELECT person_id FROM _user JOIN person ON _user.person_id = person.id WHERE person.name = 'DELETED'
                ) WHERE sin_type.creator_id=OLD.person_id;

            UPDATE torture SET handler_id = (
                SELECT person_id FROM _user JOIN person ON _user.person_id = person.id WHERE person.name = 'DELETED'
                ) WHERE torture.handler_id=OLD.person_id;

            UPDATE _event SET handler_id = (
                SELECT person_id FROM _user JOIN person ON _user.person_id = person.id WHERE person.name = 'DELETED'
                ) WHERE _event.handler_id=OLD.person_id;

            DELETE FROM person WHERE person.id=OLD.person_id;
            return OLD;
        END;
    $$ LANGUAGE plpgsql;


CREATE TRIGGER tr_delete_user AFTER DELETE ON _user
FOR EACH ROW EXECUTE PROCEDURE delete_user();


CREATE OR REPLACE FUNCTION delete_soul() RETURNS TRIGGER 
    AS $$
        BEGIN
            DELETE FROM person WHERE person.id=OLD.person_id;
            return OLD;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_delete_soul AFTER DELETE ON soul
FOR EACH ROW EXECUTE PROCEDURE delete_soul();


CREATE OR REPLACE FUNCTION delete_torture() RETURNS TRIGGER 
    AS $$
        BEGIN
            UPDATE soul SET torture_id=NULL, handler_id=NULL WHERE(
                OLD.id = SELECT torture_id FROM soul ON soul.torture_id = torture.id
            );
            return OLD;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_delete_torture AFTER DELETE ON torture
FOR EACH ROW EXECUTE PROCEDURE delete_torture();


CREATE OR REPLACE FUNCTION delete_monster() RETURNS TRIGGER
    AS $$
        BEGIN
            UPDATE soul SET torture_id=NULL, handler_id=NULL WHERE(
                OLD.id = SELECT monster_id FROM soul JOIN torture ON soul.torture_id = torture.id
            );
            return OLD;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_delete_monster AFTER DELETE ON monster
FOR EACH ROW EXECUTE PROCEDURE delete_monster();

DROP MATERIALIZED VIEW active_user;
DROP TABLE work_list;
DROP TABLE sin_type_distribution_list;
DROP TABLE work;
DROP TABLE _event;
DROP TABLE complaint;
DROP TABLE _status;
DROP TABLE sin_type;
DROP TABLE soul;
DROP TABLE torture;
DROP TABLE monster;
DROP TABLE _location;
DROP TABLE _level;
DROP TABLE _user;
DROP TABLE person;

DROP TRIGGER tr_authorize_after_creating ON _user;
DROP TRIGGER tr_authorize ON _user;
DROP TRIGGER tr_create_sin_type ON sin_type;
DROP TRIGGER tr_create_work ON work;
DROP TRIGGER tr_delete_from_event_list ON sin_type_distribution_list;
DROP TRIGGER tr_delete_from_work_list ON work_list;
DROP TRIGGER tr_delete_monster ON monster;
DROP TRIGGER tr_delete_soul ON soul;
DROP TRIGGER tr_delete_torture ON torture;
DROP TRIGGER tr_delete_user ON _user;
DROP TRIGGER tr_distribute_soul_by_hand ON soul;
DROP TRIGGER tr_handle_complaint ON complaint;
DROP TRIGGER tr_handle_event ON _event;
DROP TRIGGER tr_handle_event_through_list ON sin_type_distribution_list;
DROP TRIGGER tr_handle_sin_type ON sin_type;
DROP TRIGGER tr_make_soul_working ON work_list;
DROP TRIGGER tr_update_event_list ON sin_type_distribution_list;
DROP TRIGGER tr_update_work_list ON work_list;
