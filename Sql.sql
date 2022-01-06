CREATE TABLE IF NOT EXISTS person (id SERIAL PRIMARY KEY NOT NULL,
                                _name VARCHAR(50) NOT NULL);

CREATE TABLE IF NOT EXISTS _user (person_id INTEGER PRIMARY KEY NOT NULL,
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

CREATE OR REPLACE FUNCTION make_soul_working() RETURNS TRIGGER 
    AS $$
        BEGIN
            UPDATE soul SET is_working=true WHERE person_id=NEW.soul_id;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_make_soul_working AFTER INSERT ON work_list
FOR EACH ROW EXECUTE PROCEDURE make_soul_working();

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

            DELETE FROM TABLE person WHERE person.id=OLD.person_id;
            return OLD;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_delete_user AFTER DELETE ON _user
FOR EACH ROW EXECUTE PROCEDURE delete_user();

CREATE OR REPLACE FUNCTION delete_soul() RETURNS TRIGGER 
    AS $$
        BEGIN
            DELETE FROM TABLE person WHERE person.id=OLD.person_id;
            return OLD;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_delete_soul AFTER DELETE ON soul
FOR EACH ROW EXECUTE PROCEDURE delete_soul();

CREATE OR REPLACE FUNCTION delete_torture() RETURNS TRIGGER 
    AS $$
        BEGIN
            UPDATE soul SET torture_id=NULL, handler_id=NULL WHERE(
                SELECT torture_id FROM torture JOIN soul ON torture.id=soul.torture_id WHERE torture_id = OLD.torture_id
            ) = OLD.torture_id;
            return OLD;
        END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER tr_delete_torture AFTER DELETE ON torture
FOR EACH ROW EXECUTE PROCEDURE delete_torture();

//todo
CREATE OR REPLACE FUNCTION delete_monster() RETURNS TRIGGER 
    AS $$
        BEGIN
            UPDATE 
            DELETE FROM TABLE person WHERE person.id=OLD.person_id;
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

