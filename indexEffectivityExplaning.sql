set enable_hashjoin = off;
set enable_mergejoin = off;

/*Uneffective*/
/*6-7ms -> 9-10ms*/
EXPLAIN (ANALYZE) SELECT sin_type._name, _event._text FROM sin_type JOIN sin_type_distribution_list ON sin_type_distribution_list.sin_type_id=sin_type.id JOIN _event ON sin_type_distribution_list.event_id=_event.id;
/*9-10ms -> 15-16ms*/
EXPLAIN (ANALYZE) SELECT work._name, person._name FROM work JOIN work_list ON work.id=work_list.work_id JOIN soul ON soul.person_id=work_list.soul_id JOIN person ON person.id=soul.person_id; 

/*Effective*/
/*20-22ms -> 15-16ms*/
EXPLAIN (ANALYZE) SELECT torture._name, person._name FROM torture JOIN soul ON soul.torture_id=torture.id JOIN person ON soul.person_id=person.id; 
/*21-22ms -> 4-5ms*/
EXPLAIN (ANALYZE) SELECT * FROM souls_handled_by_users;
/*12-13ms -> 1-2ms*/
EXPLAIN (ANALYZE) SELECT * FROM events_handled_by_users;
/*1.0-1.3ms -> 0.1-0.2ms*/
EXPLAIN (ANALYZE) SELECT * FROM complaints_handled_by_users;

/*Uneffective*/
CREATE INDEX work_list_work_id_idx_hash ON work_list USING hash(work_id);
CREATE INDEX work_list_soul_id_idx_hash ON work_list USING hash(soul_id);
CREATE INDEX sin_type_distribution_list_sin_type_id_idx_hash ON sin_type_distribution_list USING hash(sin_type_id);
CREATE INDEX sin_type_distribution_list_event_id_idx_hash ON sin_type_distribution_list USING hash(event_id);

/*Effective*/
CREATE INDEX soul_torture_id_idx_hash ON soul USING hash(torture_id);
CREATE INDEX soul_handler_id_idx_hash ON soul USING hash(handler_id);
CREATE INDEX event_handler_id_idx_hash ON _event USING hash(handler_id);
CREATE INDEX complaint_handler_id_idx_hash ON complaint USING hash(handler_id);

/*Uneffective*/
/*6-7ms -> 9-10ms*/
EXPLAIN (ANALYZE) SELECT sin_type._name, _event._text FROM sin_type JOIN sin_type_distribution_list ON sin_type_distribution_list.sin_type_id=sin_type.id JOIN _event ON sin_type_distribution_list.event_id=_event.id;
/*9-10ms -> 15-16ms*/
EXPLAIN (ANALYZE) SELECT work._name, person._name FROM work JOIN work_list ON work.id=work_list.work_id JOIN soul ON soul.person_id=work_list.soul_id JOIN person ON person.id=soul.person_id; 

/*Effective*/
/*20-22ms -> 15-16ms*/
EXPLAIN (ANALYZE) SELECT torture._name, person._name FROM torture JOIN soul ON soul.torture_id=torture.id JOIN person ON soul.person_id=person.id; 
/*21-22ms -> 4-5ms*/
EXPLAIN (ANALYZE) SELECT * FROM souls_handled_by_users;
/*12-13ms -> 1-2ms*/
EXPLAIN (ANALYZE) SELECT * FROM events_handled_by_users;
/*1.0-1.3ms -> 0.1-0.2ms*/
EXPLAIN (ANALYZE) SELECT * FROM complaints_handled_by_users;

set enable_hashjoin = on;
set enable_mergejoin = on;
