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
                                FOREIGN KEY(creator_id) REFERENCES _user (person_id) ON DELETE RESTRICT,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE RESTRICT);

CREATE TABLE IF NOT EXISTS soul (person_id INTEGER PRIMARY KEY NOT NULL,
                                birth_date DATE NOT NULL CHECK (birth_date < '2003-01-01'),
                                date_of_death DATE NOT NULL CHECK (date_of_death < '2022-01-01' AND birth_date < date_of_death),
                                is_working BOOLEAN DEFAULT false,
                                is_distributed BOOLEAN DEFAULT false,
                                handler_id INTEGER,
                                torture_id INTEGER,
                                FOREIGN KEY(person_id) REFERENCES person (id) ON DELETE CASCADE,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE RESTRICT,
                                FOREIGN KEY(torture_id) REFERENCES torture (id) ON DELETE SET NULL);

CREATE TABLE IF NOT EXISTS sin_type (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(50) NOT NULL UNIQUE,
                                _weight REAL NOT NULL CHECK (_weight > 0 AND _weight > 0),
                                handler_id INTEGER,
                                creator_id INTEGER,
                                torture_id INTEGER,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE RESTRICT,
                                FOREIGN KEY(creator_id) REFERENCES _user (person_id) ON DELETE RESTRICT,
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
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE RESTRICT);

CREATE TABLE IF NOT EXISTS _event (id SERIAL PRIMARY KEY NOT NULL,
                                _text VARCHAR(500) NOT NULL,
                                soul_id INTEGER,
                                _date DATE NOT NULL,
                                status_id INTEGER DEFAULT 1,
                                handler_id INTEGER,
                                FOREIGN KEY(soul_id) REFERENCES soul (person_id) ON DELETE CASCADE,
                                FOREIGN KEY(status_id) REFERENCES _status (id) ON DELETE SET DEFAULT,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE RESTRICT);

CREATE TABLE IF NOT EXISTS work (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(50) NOT NULL UNIQUE,
                                location_id INTEGER NOT NULL,
                                creator_id INTEGER NOT NULL,
                                FOREIGN KEY(location_id) REFERENCES _location (id) ON DELETE RESTRICT,
                                FOREIGN KEY(creator_id) REFERENCES _user (person_id) ON DELETE RESTRICT);

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


CREATE OR REPLACE PROCEDURE authorize(id integer)
    AS $$
        BEGIN
            IF (id!=SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='DELETED')
                                  AND (id!=SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='AUTO') THEN
                UPDATE _user SET is_active=false WHERE _user.person_id = id;
                UPDATE _user SET is_active=true WHERE _user.person_id = id;
            END IF;
    END;
    $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION authorize_for_trigger() RETURNS TRIGGER
    AS $$
        BEGIN
            IF NEW.is_active=true AND OLD.is_active=false
                                  AND (NEW.person_id!=SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='DELETED')
                                  AND (NEW.person_id!=SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='AUTO') THEN
                UPDATE _user SET is_active=false WHERE (SELECT person_id FROM _user WHERE _user.person_id!=NEW.person_id);
                return NEW;
            END IF;

            IF (NEW.person_id=SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='DELETED')
                                  OR (NEW.person_id=SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='AUTO') THEN
                UPDATE _user SET is_active=false WHERE (SELECT person_id FROM _user WHERE _user.person_id=NEW.person_id);
                return NEW;
            END IF;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_authorize AFTER UPDATE OF is_active ON _user
FOR EACH ROW EXECUTE PROCEDURE authorize_for_trigger();


CREATE OR REPLACE FUNCTION make_soul_working() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER := SELECT person_id FROM _user WHERE _user.is_active=true;
        BEGIN
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
            active_user_id INTEGER := SELECT person_id FROM _user WHERE _user.is_active=true;
        BEGIN
            UPDATE soul SET is_distributed=false WHERE soul.person_id=OLD.soul_id;
            UPDATE soul SET is_working=true WHERE soul.person_id=OLD.soul_id;
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
        BEGIN
            UPDATE soul SET is_distributed=false WHERE soul.person_id=OLD.soul_id;
            UPDATE soul SET is_working=true WHERE soul.person_id=OLD.soul_id;
            return OLD;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_delete_from_work_list AFTER DELETE ON work_list
    FOR EACH ROW EXECUTE PROCEDURE delete_from_work_list();


CREATE OR REPLACE FUNCTION create_work() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER := SELECT person_id FROM _user WHERE _user.is_active=true;
        BEGIN
            UPDATE work SET creator_id=active_user_id WHERE NEW.id=work.id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_create_work AFTER INSERT ON work
    FOR EACH ROW EXECUTE PROCEDURE create_work();

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

CREATE OR REPLACE FUNCTION distribute_soul_by_hand() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER := SELECT person_id FROM _user WHERE _user.is_active=true;
        BEGIN
            UPDATE soul SET is_working=false WHERE soul.person_id = OLD.person_id;
            UPDATE soul SET handler_id=active_user_id WHERE soul.person_id = OLD.person_id;
            UPDATE soul SET is_distributed=true WHERE soul.person_id = OLD.person_id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_distribute_soul_by_hand AFTER UPDATE OF torture_id ON soul
    FOR EACH ROW EXECUTE PROCEDURE distribute_soul_by_hand();


//todo
CREATE OR REPLACE PROCEDURE distribute_soul_by_algo(id integer)
    AS $$
        DECLARE
            auto_id INTEGER := SELECT person_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='AUTO';
        BEGIN
            UPDATE soul SET is_working=false WHERE soul.person_id = id;
            UPDATE soul SET handler_id=auto_id WHERE soul.person_id = id;
            UPDATE soul SET is_distributed=true WHERE soul.person_id = id;
    END;
    $$ LANGUAGE plpgsql;


//todo
CREATE OR REPLACE FUNCTION create_event() RETURNS TRIGGER
AS $$
DECLARE
    active_user_id INTEGER := SELECT person_id FROM _user WHERE _user.is_active=true;
BEGIN
    UPDATE _event SET handler_id=active_user_id WHERE _event.id=NEW.id;
    return NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_event AFTER INSERT ON _event
    FOR EACH ROW EXECUTE PROCEDURE create_event();



CREATE OR REPLACE FUNCTION handle_event_for_trigger() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER := SELECT person_id FROM _user WHERE _user.is_active=true;
            approved_status_id INTEGER := SELECT id FROM _status WHERE _status._name='Одобрено';
        BEGIN
            UPDATE _event SET handler_id=active_user_id WHERE _event.id=NEW.event_id;
            UPDATE _event SET status_id=approved_status_id WHERE _event.id=NEW.event_id;
        return NEW;
    END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_handle_event_through_list BEFORE INSERT ON sin_type_distribution_list
    FOR EACH ROW EXECUTE PROCEDURE handle_event_for_trigger();


CREATE OR REPLACE FUNCTION handle_event() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER := SELECT person_id FROM _user WHERE _user.is_active=true;
        BEGIN
            UPDATE _event SET handler_id=active_user_id WHERE _event.id=NEW.id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_handle_event AFTER UPDATE OF status_id ON _event
    FOR EACH ROW EXECUTE PROCEDURE handle_event();


CREATE OR REPLACE FUNCTION update_event_list_for_trigger() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER := SELECT person_id FROM _user WHERE _user.is_active=true;
            approved_status_id INTEGER := SELECT id FROM _status WHERE _status._name='Одобрено';
            non_handled_status_id INTEGER := SELECT id FROM _status WHERE _status._name='Не обработано';
        BEGIN
            UPDATE _event SET handler_id=active_user_id WHERE _event.id=NEW.event_id;
            UPDATE _event SET status_id=approved_status_id WHERE _event.id=NEW.event_id;
            IF (SELECT * FROM sin_type_distribution_list WHERE event_id = OLD.event_id) IS NULL THEN
                UPDATE _event SET status_id=non_handled_status_id WHERE _event.id=OLD.event_id;
            END IF;
        return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_event_list AFTER UPDATE OF event_id ON sin_type_distribution_list
    FOR EACH ROW EXECUTE PROCEDURE update_event_list_for_trigger();


CREATE OR REPLACE FUNCTION delete_from_event_list() RETURNS TRIGGER
    AS $$
        DECLARE
            non_handled_status_id INTEGER := SELECT id FROM _status WHERE _status._name='Не обработано';
        BEGIN
            IF (SELECT * FROM sin_type_distribution_list WHERE event_id = OLD.event_id) IS NULL THEN
                UPDATE _event SET status_id=non_handled_status_id WHERE _event.id=OLD.event_id;
            END IF;
        return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_delete_from_event_list AFTER DELETE ON sin_type_distribution_list
    FOR EACH ROW EXECUTE PROCEDURE delete_from_event_list();


CREATE OR REPLACE FUNCTION change_status_of_event() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER := SELECT person_id FROM _user WHERE _user.is_active=true;
        BEGIN
            UPDATE _event SET handler_id=active_user_id WHERE _event.id=NEW.event_id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_change_status_of_event AFTER UPDATE OF status_id ON _event
    FOR EACH ROW EXECUTE PROCEDURE handle_event();


CREATE OR REPLACE FUNCTION handle_complaint() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER := SELECT person_id FROM _user WHERE _user.is_active=true;
        BEGIN
            UPDATE complaint SET handler_id=active_user_id WHERE complaint.id=NEW.id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_handle_event AFTER UPDATE OF status_id ON complaint
    FOR EACH ROW EXECUTE PROCEDURE handle_complaint();


CREATE OR REPLACE FUNCTION create_sin_type() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER := SELECT person_id FROM _user WHERE _user.is_active=true;
        BEGIN
            UPDATE sin_type SET creator_id=active_user_id WHERE NEW.id=sin_type.id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_create_sin_type AFTER INSERT ON sin_type
    FOR EACH ROW EXECUTE PROCEDURE create_sin_type();


CREATE OR REPLACE FUNCTION handle_sin_type() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER := SELECT person_id FROM _user WHERE _user.is_active=true;
        BEGIN
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

