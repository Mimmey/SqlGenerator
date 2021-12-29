CREATE TABLE IF NOT EXISTS person (id SERIAL PRIMARY KEY NOT NULL UNIQUE,
                                _name VARCHAR(50) NOT NULL);

CREATE TABLE IF NOT EXISTS _user (person_id INTEGER PRIMARY KEY NOT NULL UNIQUE,
                                FOREIGN KEY(person_id) REFERENCES person (id) ON DELETE CASCADE);

CREATE TABLE IF NOT EXISTS _level (id SERIAL PRIMARY KEY NOT NULL UNIQUE,
                                _name VARCHAR(30) NOT NULL UNIQUE);

CREATE TABLE IF NOT EXISTS _location (id SERIAL PRIMARY KEY NOT NULL UNIQUE,
                                level_id INTEGER NOT NULL,
                                _name VARCHAR(50) NOT NULL UNIQUE,
                                FOREIGN KEY(level_id) REFERENCES _level (id) ON DELETE CASCADE);

CREATE TABLE IF NOT EXISTS monster (person_id INTEGER PRIMARY KEY NOT NULL UNIQUE,
                                location_id INTEGER NOT NULL,
                                motherland_id INTEGER NOT NULL,
                                FOREIGN KEY(person_id) REFERENCES person (id) ON DELETE CASCADE,
                                FOREIGN KEY(motherland_id) REFERENCES _location (id) ON DELETE RESTRICT,
                                FOREIGN KEY(location_id) REFERENCES _location (id) ON DELETE RESTRICT);

CREATE TABLE IF NOT EXISTS torture (id SERIAL PRIMARY KEY NOT NULL UNIQUE,
                                _name VARCHAR(50) NOT NULL UNIQUE,
                                monster_id INTEGER,
                                creator_id INTEGER NOT NULL,
                                handler_id INTEGER,
                                FOREIGN KEY(monster_id) REFERENCES monster (person_id) ON DELETE SET NULL,
                                FOREIGN KEY(creator_id) REFERENCES _user (person_id) ON DELETE RESTRICT,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE RESTRICT);

CREATE TABLE IF NOT EXISTS soul (person_id INTEGER PRIMARY KEY NOT NULL UNIQUE,
                                birth_date DATE NOT NULL CHECK (birth_date < '2003-01-01'),
                                date_of_death DATE NOT NULL CHECK (date_of_death < '2022-01-01' AND birth_date < date_of_death),
                                is_working BOOLEAN DEFAULT false,
                                is_distributed BOOLEAN DEFAULT false,
                                handler_id INTEGER,
                                torture_id INTEGER,
                                FOREIGN KEY(person_id) REFERENCES person (id) ON DELETE CASCADE,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE RESTRICT,
                                FOREIGN KEY(torture_id) REFERENCES torture (id) ON DELETE SET NULL);

CREATE TABLE IF NOT EXISTS sin_type (id SERIAL PRIMARY KEY NOT NULL UNIQUE,
                                _name VARCHAR(50) NOT NULL UNIQUE,
                                _weight REAL NOT NULL CHECK (_weight > 0 AND _weight > 0),
                                handler_id INTEGER,
                                creator_id INTEGER,
                                torture_id INTEGER,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE RESTRICT,
                                FOREIGN KEY(creator_id) REFERENCES _user (person_id) ON DELETE RESTRICT,
                                FOREIGN KEY(torture_id) REFERENCES torture (id) ON DELETE SET NULL);

CREATE TABLE IF NOT EXISTS _status (id SERIAL PRIMARY KEY NOT NULL UNIQUE,
                                _name VARCHAR(30) NOT NULL UNIQUE);

CREATE TABLE IF NOT EXISTS complaint (id SERIAL PRIMARY KEY NOT NULL UNIQUE,
                                title VARCHAR(50) NOT NULL,
                                body VARCHAR(1000) NOT NULL,
                                soul_id INTEGER,
                                status_id INTEGER DEFAULT 1,
                                handler_id INTEGER,
                                FOREIGN KEY(soul_id) REFERENCES soul (person_id) ON DELETE CASCADE,
                                FOREIGN KEY(status_id) REFERENCES _status (id) ON DELETE SET DEFAULT,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE RESTRICT);

CREATE TABLE IF NOT EXISTS _event (id SERIAL PRIMARY KEY NOT NULL UNIQUE,
                                _text VARCHAR(500) NOT NULL,
                                soul_id INTEGER,
                                _date DATE NOT NULL,
                                status_id INTEGER DEFAULT 1,
                                handler_id INTEGER,
                                FOREIGN KEY(soul_id) REFERENCES soul (person_id) ON DELETE CASCADE,
                                FOREIGN KEY(status_id) REFERENCES _status (id) ON DELETE SET DEFAULT,
                                FOREIGN KEY(handler_id) REFERENCES _user (person_id) ON DELETE RESTRICT);

CREATE TABLE IF NOT EXISTS work (id SERIAL PRIMARY KEY NOT NULL UNIQUE,
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