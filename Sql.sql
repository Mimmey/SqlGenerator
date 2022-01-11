CREATE TABLE IF NOT EXISTS person (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(50) NOT NULL);

CREATE TABLE IF NOT EXISTS _user (person_id INTEGER PRIMARY KEY NOT NULL,
                                is_active BOOLEAN DEFAULT FALSE,
                                FOREIGN KEY(person_id) REFERENCES person (id) ON DELETE CASCADE ON UPDATE RESTRICT);

CREATE TABLE IF NOT EXISTS _level (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(30) NOT NULL UNIQUE);

CREATE TABLE IF NOT EXISTS _location (id SERIAL PRIMARY KEY NOT NULL,
                                level_id INTEGER NOT NULL,
                                _name VARCHAR(50) NOT NULL UNIQUE,
                                FOREIGN KEY(level_id) REFERENCES _level (id) ON DELETE CASCADE ON UPDATE RESTRICT);

CREATE TABLE IF NOT EXISTS monster (person_id INTEGER PRIMARY KEY NOT NULL,
                                location_id INTEGER NOT NULL,
                                motherland_id INTEGER NOT NULL,
                                FOREIGN KEY(person_id) REFERENCES person (id) ON DELETE CASCADE ON UPDATE RESTRICT,
                                FOREIGN KEY(motherland_id) REFERENCES _location (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
                                FOREIGN KEY(location_id) REFERENCES _location (id) ON DELETE RESTRICT);

CREATE TABLE IF NOT EXISTS torture (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(50) NOT NULL UNIQUE,
                                monster_id INTEGER,
                                creator_id INTEGER NOT NULL DEFAULT 4,
                                handler_id INTEGER DEFAULT 4,
                                FOREIGN KEY(monster_id) REFERENCES monster (person_id) ON DELETE RESTRICT,
                                FOREIGN KEY(creator_id) REFERENCES _user (person_id) ON DELETE SET DEFAULT ON UPDATE RESTRICT,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE SET DEFAULT);

CREATE TABLE IF NOT EXISTS soul (person_id INTEGER PRIMARY KEY NOT NULL,
                                birth_date DATE NOT NULL CHECK (birth_date < '2003-01-01'),
                                date_of_death DATE NOT NULL CHECK (date_of_death < '2022-01-01' AND birth_date < date_of_death),
                                is_working BOOLEAN DEFAULT false,
                                is_distributed BOOLEAN DEFAULT false,
                                handler_id INTEGER DEFAULT 4,
                                torture_id INTEGER,
                                FOREIGN KEY(person_id) REFERENCES person (id) ON DELETE CASCADE ON UPDATE RESTRICT,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE SET DEFAULT,
                                FOREIGN KEY(torture_id) REFERENCES torture (id) ON DELETE RESTRICT);

CREATE TABLE IF NOT EXISTS sin_type (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(50) NOT NULL UNIQUE,
                                _weight REAL NOT NULL CHECK (_weight > 0 AND _weight > 0),
                                handler_id INTEGER DEFAULT 4,
                                creator_id INTEGER DEFAULT 4,
                                torture_id INTEGER,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE SET DEFAULT,
                                FOREIGN KEY(creator_id) REFERENCES _user (person_id) ON DELETE SET DEFAULT ON UPDATE RESTRICT,
                                FOREIGN KEY(torture_id) REFERENCES torture (id) ON DELETE SET NULL);

CREATE TABLE IF NOT EXISTS _status (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(30) NOT NULL UNIQUE);

CREATE TABLE IF NOT EXISTS complaint (id SERIAL PRIMARY KEY NOT NULL,
                                title VARCHAR(50) NOT NULL,
                                body VARCHAR(1000) NOT NULL,
                                soul_id INTEGER,
                                status_id INTEGER DEFAULT 1,
                                handler_id INTEGER DEFAULT 4,
                                FOREIGN KEY(soul_id) REFERENCES soul (person_id) ON DELETE CASCADE ON UPDATE RESTRICT,
                                FOREIGN KEY(status_id) REFERENCES _status (id) ON DELETE SET DEFAULT,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE SET DEFAULT);

CREATE TABLE IF NOT EXISTS _event (id SERIAL PRIMARY KEY NOT NULL,
                                _text VARCHAR(500) NOT NULL,
                                soul_id INTEGER,
                                _date DATE NOT NULL,
                                status_id INTEGER DEFAULT 1,
                                handler_id INTEGER DEFAULT 4,
                                FOREIGN KEY(soul_id) REFERENCES soul (person_id) ON DELETE CASCADE ON UPDATE RESTRICT,
                                FOREIGN KEY(status_id) REFERENCES _status (id) ON DELETE SET DEFAULT,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE SET DEFAULT);

CREATE TABLE IF NOT EXISTS work (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(50) NOT NULL UNIQUE,
                                location_id INTEGER NOT NULL,
                                creator_id INTEGER NOT NULL DEFAULT 4,
                                FOREIGN KEY(location_id) REFERENCES _location (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
                                FOREIGN KEY(creator_id) REFERENCES _user (person_id) ON DELETE SET DEFAULT ON UPDATE RESTRICT);

CREATE TABLE IF NOT EXISTS sin_type_distribution_list (
                                event_id INTEGER NOT NULL,
                                sin_type_id INTEGER NOT NULL,
                                FOREIGN KEY(event_id) REFERENCES _event (id) ON DELETE CASCADE,
                                FOREIGN KEY(sin_type_id) REFERENCES sin_type (id) ON DELETE CASCADE);

CREATE TABLE IF NOT EXISTS work_list (
                                soul_id INTEGER NOT NULL,
                                work_id INTEGER NOT NULL,
                                FOREIGN KEY(soul_id) REFERENCES soul (person_id) ON DELETE CASCADE,
                                FOREIGN KEY(work_id) REFERENCES work (id) ON DELETE RESTRICT);

CREATE MATERIALIZED VIEW active_user
    AS SELECT person_id FROM _user WHERE is_active=true;

CREATE VIEW unhandled_souls
    AS SELECT person_id FROM soul WHERE is_distributed=false;

CREATE VIEW unhandled_tortures
    AS SELECT id FROM torture WHERE monster_id IS NULL;

CREATE VIEW unhandled_sin_types
    AS SELECT id FROM sin_type WHERE torture_id IS NULL;

CREATE VIEW unhandled_complaints
    AS SELECT id FROM complaint WHERE status_id IN (SELECT id FROM _status WHERE _status._name='Не обработано');

CREATE VIEW unhandled_events
    AS SELECT id FROM _event WHERE status_id IN (SELECT id FROM _status WHERE _status._name='Не обработано');

CREATE VIEW tartar_locations
    AS SELECT _location.id FROM _location JOIN _level ON _location.level_id = _level.id WHERE _level._name='Тартар';

CREATE OR REPLACE FUNCTION get_auto_torture(soul_id_param integer) RETURNS INTEGER
    AS $$
        DECLARE
            result INTEGER;
        BEGIN
            SELECT torture.id INTO result FROM sin_type_distribution_list JOIN _event ON sin_type_distribution_list.event_id = _event.id
                                                                  JOIN sin_type ON sin_type_distribution_list.sin_type_id = sin_type.id
                                                                  JOIN torture ON sin_type.torture_id = torture.id
                                                                  JOIN monster ON torture.monster_id = monster.person_id
            WHERE _event.soul_id=soul_id_param AND sin_type.torture_id IS NOT NULL AND torture.monster_id IS NOT NULL
            AND _weight = (SELECT MAX(_weight) FROM sin_type_distribution_list
                                                  JOIN _event ON sin_type_distribution_list.event_id = _event.id
                                                  JOIN sin_type ON sin_type_distribution_list.sin_type_id = sin_type.id
                                                  JOIN torture ON sin_type.torture_id = torture.id
                                                  JOIN monster ON torture.monster_id = monster.person_id
                                                  WHERE _event.soul_id=soul_id_param AND sin_type.torture_id IS NOT NULL AND torture.monster_id IS NOT NULL) LIMIT 1;
            return result;
        END;
    $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION distribute_soul_by_algo(soul_id_param integer) RETURNS VOID
    AS $$
        DECLARE
            generated_torture INTEGER;
            auto_id INTEGER;
        BEGIN
            generated_torture=get_auto_torture(soul_id_param);

            IF generated_torture IS NULL THEN
                RAISE EXCEPTION 'NOT FOUND TORTURE FOR THIS SOUL';
            END IF;

            SELECT person_id INTO auto_id FROM _user JOIN person ON _user.person_id = person.id WHERE person._name='AUTO';
            UPDATE soul SET is_working=false WHERE soul.person_id = soul_id_param;
            UPDATE soul SET torture_id=generated_torture WHERE soul.person_id = soul_id_param;
            UPDATE soul SET handler_id=auto_id WHERE soul.person_id = soul_id_param;
            UPDATE soul SET is_distributed=true WHERE soul.person_id = soul_id_param;
        END;
    $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION check_if_torture_has_monster(id_param integer) RETURNS BOOLEAN
    AS $$
        DECLARE
            monster INTEGER;
        BEGIN
            SELECT monster_id INTO monster FROM torture WHERE torture.id=id_param;
            RETURN monster IS NOT NULL;
        END;
    $$ LANGUAGE plpgsql;

/*tested*/;
CREATE OR REPLACE FUNCTION authorize_after_creating() RETURNS TRIGGER
    AS $$
        BEGIN
            IF EXISTS (SELECT person_id FROM _user JOIN person on _user.person_id = person.id  WHERE person._name='UNAUTHORIZED') 
                        AND NEW.person_id IN (SELECT person_id FROM _user JOIN person on _user.person_id = person.id  WHERE person._name='UNAUTHORIZED') THEN
                UPDATE _user SET is_active=true WHERE _user.person_id=NEW.person_id;
            END IF;

            REFRESH MATERIALIZED VIEW active_user;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql;


CREATE TRIGGER tr_authorize_after_creating AFTER INSERT ON _user
    FOR EACH ROW WHEN (pg_trigger_depth() = 0) EXECUTE PROCEDURE authorize_after_creating();

/*tested*/;
CREATE OR REPLACE FUNCTION authorize_for_trigger() RETURNS TRIGGER
    AS $$
        BEGIN
            IF NEW.is_active=true AND (NEW.person_id NOT IN (SELECT person_id FROM _user JOIN person ON _user.person_id=person.id 
                        WHERE (person._name IN ('DELETED', 'AUTO', 'UNAUTHORIZED', 'NON-HANDLED')))) THEN
                UPDATE _user SET is_active=false WHERE (NEW.person_id != _user.person_id);
            ELSE
                UPDATE _user SET is_active=false;
                UPDATE _user SET is_active=true WHERE _user.person_id IN (SELECT _user.person_id FROM _user JOIN person ON _user.person_id=person.id 
                        WHERE person._name='UNAUTHORIZED');
            END IF;

            REFRESH MATERIALIZED VIEW active_user;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_authorize AFTER UPDATE OF is_active ON _user
    FOR EACH ROW WHEN (pg_trigger_depth() = 0) EXECUTE PROCEDURE authorize_for_trigger();

CREATE OR REPLACE FUNCTION interface_authorize(id_param integer) RETURNS VOID
    AS $$
        BEGIN
            UPDATE _user SET is_active=true WHERE _user.person_id=id_param;
        END;
    $$ LANGUAGE plpgsql;

/*tested*/;
CREATE OR REPLACE FUNCTION create_monster() RETURNS TRIGGER
    AS $$
        BEGIN
            IF NEW.location_id NOT IN (SELECT * FROM tartar_locations) THEN
                RAISE EXCEPTION 'MONSTER MUST BE IN TARTAR';
            END IF;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_create_monster AFTER INSERT ON monster
    FOR EACH ROW EXECUTE PROCEDURE create_monster();

/*tested*/;
CREATE OR REPLACE FUNCTION update_monster() RETURNS TRIGGER
    AS $$
        BEGIN
            IF NEW.location_id NOT IN (SELECT * FROM tartar_locations) THEN
                RAISE EXCEPTION 'MONSTER MUST BE IN TARTAR';
            END IF;
            return NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_monster AFTER UPDATE OF location_id ON monster
    FOR EACH ROW EXECUTE PROCEDURE update_monster();

/*tested*/;
CREATE OR REPLACE FUNCTION create_work() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            IF NEW.location_id IN (SELECT * FROM tartar_locations) THEN
                RAISE EXCEPTION 'WORK MUST NOT BE IN TARTAR';
            END IF;
            SELECT person_id INTO active_user_id FROM active_user;
            UPDATE work SET creator_id=active_user_id WHERE NEW.id=work.id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_create_work AFTER INSERT ON work
    FOR EACH ROW EXECUTE PROCEDURE create_work();

/*tested*/;
CREATE OR REPLACE FUNCTION update_work() RETURNS TRIGGER
    AS $$
        BEGIN
            IF NEW.location_id IN (SELECT * FROM tartar_locations) THEN
                RAISE EXCEPTION 'WORK MUST NOT BE IN TARTAR';
            END IF;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_work AFTER UPDATE OF location_id ON work
    FOR EACH ROW EXECUTE PROCEDURE update_work();

/*tested*/;
CREATE OR REPLACE FUNCTION create_soul() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            IF NEW.torture_id IS NOT NULL AND NOT check_if_torture_has_monster(NEW.torture_id) THEN
                RAISE EXCEPTION 'TORTURE DOESNT HAVE ANY PERFORMING MONSTER';
            END IF;

            IF DATE_PART('year', NEW.date_of_death) - DATE_PART('year', NEW.birth_date) > 100 THEN
                RAISE EXCEPTION 'TOO OLD SOUL';
            END IF;

            IF NEW.torture_id IS NOT NULL THEN
                UPDATE soul SET handler_id=active_user_id WHERE soul.person_id=NEW.person_id;
            ELSE
                UPDATE soul SET handler_id=NULL WHERE soul.person_id=NEW.person_id;
            END IF;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_create_soul AFTER INSERT ON soul
    FOR EACH ROW EXECUTE PROCEDURE create_soul();

/*tested*/;
CREATE OR REPLACE FUNCTION distribute_soul_by_hand() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            IF NEW.torture_id IS NOT NULL AND NOT check_if_torture_has_monster(NEW.torture_id)THEN
                RAISE EXCEPTION 'TORTURE DOESNT HAVE ANY MONSTER PERFORMER';
            END IF;
            SELECT person_id INTO active_user_id FROM active_user;
            UPDATE soul SET is_working=false WHERE soul.person_id = NEW.person_id;
            UPDATE soul SET handler_id=active_user_id WHERE soul.person_id = NEW.person_id;
            UPDATE soul SET is_distributed=true WHERE soul.person_id = NEW.person_id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_distribute_soul_by_hand AFTER UPDATE OF torture_id ON soul
    FOR EACH ROW EXECUTE PROCEDURE distribute_soul_by_hand();

/*tested*/;
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

/*tested*/;
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

/*tested*/;
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

/*tested*/;
CREATE OR REPLACE FUNCTION create_torture() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            UPDATE torture SET creator_id=active_user_id WHERE torture.id=NEW.id;
            UPDATE torture SET handler_id=NULL WHERE torture.id=NEW.id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_create_torture AFTER INSERT ON torture
    FOR EACH ROW EXECUTE PROCEDURE create_torture();

/*tested*/;
CREATE OR REPLACE FUNCTION create_event() RETURNS TRIGGER
    AS $$
        DECLARE
            date_of_birth DATE;
            death_date DATE;
        BEGIN
            SELECT birth_date INTO date_of_birth FROM soul WHERE soul.person_id = NEW.soul_id;
            SELECT date_of_death INTO death_date FROM soul WHERE soul.person_id = NEW.soul_id;

            IF NEW._date < date_of_birth OR DATE_PART('year', NEW._date) - DATE_PART('year', date_of_birth) < 18
                OR NEW._date > death_date THEN
                RAISE EXCEPTION 'INVALID DATE';
            ELSE
                UPDATE _event SET handler_id=NULL WHERE _event.id=NEW.id;
                return NEW;
            END IF;
        END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_event AFTER INSERT ON _event
    FOR EACH ROW EXECUTE PROCEDURE create_event();

/*tested*/;
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

/*tested*/;
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


/*tested*/;
CREATE OR REPLACE FUNCTION create_complaint() RETURNS TRIGGER
    AS $$
        BEGIN
            UPDATE complaint SET handler_id=NULL WHERE complaint.id=NEW.id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_create_complaint AFTER INSERT ON complaint
    FOR EACH ROW EXECUTE PROCEDURE create_complaint();

/*tested*/;
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

/*tested*/;
CREATE OR REPLACE FUNCTION create_sin_type() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            UPDATE sin_type SET creator_id=active_user_id WHERE NEW.id=sin_type.id;
            UPDATE sin_type SET handler_id=NULL WHERE NEW.id=sin_type.id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_create_sin_type AFTER INSERT ON sin_type
    FOR EACH ROW EXECUTE PROCEDURE create_sin_type();

/*tested*/;
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

/*tested*/;
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

/*tested*/;
CREATE OR REPLACE FUNCTION delete_from_sin_type_distribution_list() RETURNS TRIGGER
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

CREATE TRIGGER tr_delete_from_sin_type_distribution_list AFTER DELETE ON sin_type_distribution_list
    FOR EACH ROW EXECUTE PROCEDURE delete_from_sin_type_distribution_list();

/*tested*/;
CREATE OR REPLACE FUNCTION delete_user() RETURNS TRIGGER
    AS $$
        DECLARE
            active_user_id INTEGER;
            deleted_user_id INTEGER;
            auto_user_id INTEGER;
            unauthorized_user_id INTEGER;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            SELECT person_id INTO deleted_user_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='DELETED';
            SELECT person_id INTO auto_user_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='AUTO';
            SELECT person_id INTO unauthorized_user_id FROM _user JOIN person ON _user.person_id=person.id WHERE person._name='UNAUTHORIZED';

            IF OLD.person_id!=active_user_id THEN
                RAISE EXCEPTION 'CANNOT DELETE USER BC HE/SHE IS NOT AUTHORIZED';
            END IF;

            IF OLD.person_id=deleted_user_id OR OlD.person_id=auto_user_id
                OR OLD.person_id=unauthorized_user_id THEN
                RAISE EXCEPTION 'CANNOT DELETE THIS USER';
            END IF;

            UPDATE complaint SET handler_id = (
                SELECT person_id FROM _user JOIN person ON _user.person_id = person.id WHERE person._name = 'DELETED'
            ) WHERE 'NON-HANDLED' IN (SELECT _name FROM person JOIN _user ON _user.person_id=person.id WHERE person_id=complaint.handler_id);

            UPDATE soul SET handler_id = (
                SELECT person_id FROM _user JOIN person ON _user.person_id = person.id WHERE person._name = 'DELETED'
            ) WHERE 'NON-HANDLED' IN (SELECT _name FROM person JOIN _user ON _user.person_id=person.id WHERE person_id=soul.handler_id);

            UPDATE sin_type SET handler_id = (
                SELECT person_id FROM _user JOIN person ON _user.person_id = person.id WHERE person._name = 'DELETED'
            ) WHERE 'NON-HANDLED' IN (SELECT _name FROM person JOIN _user ON _user.person_id=person.id WHERE person_id=sin_type.handler_id);

            UPDATE sin_type SET creator_id = (
                SELECT person_id FROM _user JOIN person ON _user.person_id = person.id WHERE person._name = 'DELETED'
            ) WHERE 'NON-HANDLED' IN (SELECT _name FROM person JOIN _user ON _user.person_id=person.id WHERE person_id=sin_type.creator_id);

            UPDATE torture SET handler_id = (
                SELECT person_id FROM _user JOIN person ON _user.person_id = person.id WHERE person._name = 'DELETED'
            ) WHERE 'NON-HANDLED' IN (SELECT _name FROM person JOIN _user ON _user.person_id=person.id WHERE person_id=torture.handler_id);

            UPDATE _event SET handler_id = (
                SELECT person_id FROM _user JOIN person ON _user.person_id = person.id WHERE person._name = 'DELETED'
            ) WHERE 'NON-HANDLED' IN (SELECT _name FROM person JOIN _user ON _user.person_id=person.id WHERE person_id=_event.handler_id);

            DELETE FROM person WHERE person.id=OLD.person_id;
            UPDATE _user SET is_active=true WHERE _user.person_id IN (SELECT _user.person_id FROM _user JOIN person ON _user.person_id=person.id 
                    WHERE person._name='UNAUTHORIZED');
            REFRESH MATERIALIZED VIEW active_user;
            return OLD;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_delete_user AFTER DELETE ON _user
    FOR EACH ROW EXECUTE PROCEDURE delete_user();

CREATE OR REPLACE FUNCTION interface_delete_authorized_user() RETURNS VOID
    AS $$
        DECLARE
            active_user_id INTEGER;
        BEGIN
            SELECT person_id INTO active_user_id FROM active_user;
            DELETE FROM _user WHERE person_id=active_user_id;
        END;
$$ LANGUAGE plpgsql;

/*tested*/;
CREATE OR REPLACE FUNCTION delete_soul() RETURNS TRIGGER
    AS $$
        BEGIN
            DELETE FROM person WHERE person.id=OLD.person_id;
            return OLD;
            END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_delete_soul AFTER DELETE ON soul
    FOR EACH ROW EXECUTE PROCEDURE delete_soul();


DROP TRIGGER tr_authorize_after_creating ON _user;
DROP TRIGGER tr_authorize ON _user;
DROP TRIGGER tr_create_sin_type ON sin_type;
DROP TRIGGER tr_create_work ON work;
DROP TRIGGER tr_update_work ON work;
DROP TRIGGER tr_delete_from_sin_type_distribution_list ON sin_type_distribution_list;
DROP TRIGGER tr_delete_from_work_list ON work_list;
DROP TRIGGER tr_delete_soul ON soul;
DROP TRIGGER tr_delete_user ON _user;
DROP TRIGGER tr_distribute_soul_by_hand ON soul;
DROP TRIGGER tr_handle_complaint ON complaint;
DROP TRIGGER tr_handle_event ON _event;
DROP TRIGGER tr_handle_event_through_list ON sin_type_distribution_list;
DROP TRIGGER tr_handle_sin_type ON sin_type;
DROP TRIGGER tr_make_soul_working ON work_list;
DROP TRIGGER tr_update_event_list ON sin_type_distribution_list;
DROP TRIGGER tr_update_work_list ON work_list;
DROP TRIGGER tr_create_monster ON monster;
DROP TRIGGER tr_update_monster ON monster;
DROP TRIGGER tr_create_complaint ON complaint;
DROP TRIGGER tr_create_soul ON soul;
DROP TRIGGER tr_create_torture ON torture;

DROP MATERIALIZED VIEW active_user;
DROP VIEW unhandled_souls;
DROP VIEW unhandled_tortures;
DROP VIEW unhandled_sin_types;
DROP VIEW unhandled_complaints;
DROP VIEW unhandled_events;
DROP VIEW tartar_locations;

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