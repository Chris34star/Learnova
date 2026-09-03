-- OPTIONAL DEVELOPMENT/DEMO DATA. Run manually after all migrations; never use in production.
do $$ declare sid uuid; g7 uuid; g8 uuid; g9 uuid; begin
 insert into schools(name,slug,country,status) values ('Greenfield Academy','greenfield-academy','Kenya','trial') returning id into sid;
 insert into school_settings(school_id) values (sid);
 insert into grades(school_id,name,level_number,display_order) values (sid,'Grade 7',7,1) returning id into g7;
 insert into grades(school_id,name,level_number,display_order) values (sid,'Grade 8',8,2) returning id into g8;
 insert into grades(school_id,name,level_number,display_order) values (sid,'Grade 9',9,3) returning id into g9;
 insert into classes(school_id,grade_id,name) values (sid,g7,'Grade 7A'),(sid,g8,'Grade 8A'),(sid,g9,'Grade 9A');
 insert into subjects(name,slug,is_global,status) values ('Mathematics','mathematics',true,'active'),('English','english',true,'active'),('Science','science',true,'active') on conflict do nothing;
end $$;

-- Stage 4 demo rows need provisioned admin profiles because governance records always
-- retain an accountable author. This block safely skips content when demo users are absent.
do $$ declare platform_author uuid; school_author uuid; greenfield uuid; grade8 uuid; math_subject uuid;
 mathematics uuid; web_creator uuid; algebra uuid; word_problems uuid;
begin
 select id into platform_author from profiles where role='platform_admin' limit 1;
 select id into school_author from profiles where role='school_admin' and school_id=(select id from schools where slug='greenfield-academy') limit 1;
 select id into greenfield from schools where slug='greenfield-academy';
 select id into grade8 from grades where school_id=greenfield and level_number=8 limit 1;
 select id into math_subject from subjects where slug='mathematics' and is_global limit 1;
 if platform_author is null then raise notice 'Skipping Stage 4 demo content: provision a platform_admin profile first.'; return; end if;

 insert into courses(scope,title,slug,description,content_family,subject_id,status,created_by,approved_by,approved_at)
 values('global','Mathematics','demo-mathematics','DEMO: Grade 8 mathematics pathway.','academic',math_subject,'published',platform_author,platform_author,now()) returning id into mathematics;
 insert into content_nodes(course_id,content_type,title,body,status,scope,created_by,approved_by,approved_at,sort_order)
 values(mathematics,'module','Algebra','DEMO: Algebra module.','published','global',platform_author,platform_author,now(),1) returning id into algebra;
 insert into content_nodes(course_id,parent_id,content_type,title,body,status,scope,created_by,approved_by,approved_at,sort_order)
 values
 (mathematics,algebra,'lesson','Introduction','DEMO lesson.','published','global',platform_author,platform_author,now(),1),
 (mathematics,algebra,'lesson','Basic Equations','DEMO lesson.','published','global',platform_author,platform_author,now(),2),
 (mathematics,algebra,'lesson','Two-Step Equations','DEMO lesson.','published','global',platform_author,platform_author,now(),3);
 insert into content_nodes(course_id,parent_id,content_type,title,body,status,scope,created_by,approved_by,approved_at,sort_order)
 values(mathematics,algebra,'lesson','Algebraic Word Problems','DEMO lesson.','published','global',platform_author,platform_author,now(),4) returning id into word_problems;
 insert into courses(scope,title,slug,description,content_family,difficulty,status,created_by,approved_by,approved_at)
 values('global','Web Creator','demo-web-creator','DEMO: project-based web pathway.','skills','beginner','published',platform_author,platform_author,now()) returning id into web_creator;
 insert into content_nodes(course_id,content_type,title,body,status,scope,created_by,approved_by,approved_at,sort_order) values
 (web_creator,'topic','How the Web Works','DEMO topic.','published','global',platform_author,platform_author,now(),1),
 (web_creator,'module','HTML Foundations','DEMO module.','published','global',platform_author,platform_author,now(),2),
 (web_creator,'module','CSS Foundations','DEMO module.','published','global',platform_author,platform_author,now(),3);
 if school_author is not null then
  insert into school_course_adoptions(school_id,course_id,adopted_by) values(greenfield,mathematics,school_author);
  insert into content_nodes(course_id,content_type,title,body,status,scope,school_id,source_content_id,is_override,created_by,approved_by,approved_at,sort_order)
  values(mathematics,'lesson','Algebraic Word Problems','DEMO: Greenfield-localized examples.','published','school',greenfield,word_problems,true,school_author,school_author,now(),4);
 end if;
 insert into tags(name,slug) values('algebra','algebra'),('problem-solving','problem-solving'),('beginner','beginner'),('web','web'),('coding','coding'),('entrepreneurship','entrepreneurship'),('project-based','project-based') on conflict do nothing;
end $$;
