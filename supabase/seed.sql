-- OPTIONAL development seed. Run manually only after the Stage 3 migration.
do $$ declare sid uuid; g7 uuid; g8 uuid; g9 uuid; begin
 insert into schools(name,slug,country,status) values ('Greenfield Academy','greenfield-academy','Kenya','trial') returning id into sid;
 insert into school_settings(school_id) values (sid);
 insert into grades(school_id,name,level_number,display_order) values (sid,'Grade 7',7,1) returning id into g7;
 insert into grades(school_id,name,level_number,display_order) values (sid,'Grade 8',8,2) returning id into g8;
 insert into grades(school_id,name,level_number,display_order) values (sid,'Grade 9',9,3) returning id into g9;
 insert into classes(school_id,grade_id,name) values (sid,g7,'Grade 7A'),(sid,g8,'Grade 8A'),(sid,g9,'Grade 9A');
 insert into subjects(name,slug,is_global,status) values ('Mathematics','mathematics',true,'active'),('English','english',true,'active'),('Science','science',true,'active') on conflict do nothing;
end $$;
