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
 mathematics uuid; web_creator uuid; algebra uuid;
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
 insert into courses(scope,title,slug,description,content_family,difficulty,status,created_by,approved_by,approved_at)
 values('global','Web Creator','demo-web-creator','DEMO: project-based web pathway.','skills','beginner','published',platform_author,platform_author,now()) returning id into web_creator;
 insert into content_nodes(course_id,content_type,title,body,status,scope,created_by,approved_by,approved_at,sort_order) values
 (web_creator,'topic','How the Web Works','DEMO topic.','published','global',platform_author,platform_author,now(),1),
 (web_creator,'module','HTML Foundations','DEMO module.','published','global',platform_author,platform_author,now(),2),
 (web_creator,'module','CSS Foundations','DEMO module.','published','global',platform_author,platform_author,now(),3);
 if school_author is not null then
  insert into school_course_adoptions(school_id,course_id,adopted_by) values(greenfield,mathematics,school_author);
 end if;
 insert into tags(name,slug) values('algebra','algebra'),('problem-solving','problem-solving'),('beginner','beginner'),('web','web'),('coding','coding'),('entrepreneurship','entrepreneurship'),('project-based','project-based') on conflict do nothing;
end $$;

-- OPTIONAL STAGE 6 LEARNING DATA. This block stays development-only with this file.
-- Provision Amani Njoroge through Supabase Auth first; if that profile exists, attach
-- it to Greenfield's Grade 8 before running this seed.
do $$ declare sid uuid; grade8 uuid; author uuid; math uuid; web uuid; algebra uuid; amani_profile uuid; amani_class uuid;
begin
 select id into sid from schools where slug='greenfield-academy';
 select id into grade8 from grades where school_id=sid and level_number=8;
 select id into author from profiles where role='platform_admin' limit 1;
 select id into math from courses where slug='demo-mathematics';
 select id into web from courses where slug='demo-web-creator';
 select id into algebra from content_nodes where course_id=math and title='Algebra' limit 1;
 if sid is null or author is null or math is null then raise notice 'Skipping Stage 6 learning seed until Stage 4 demo prerequisites exist.'; return; end if;
 update courses set grade_id=grade8,learning_objectives='["Build confidence solving linear equations","Use equations to represent word problems"]' where id=math;
 update content_nodes set structured_content=jsonb_build_object('components',jsonb_build_array(
   jsonb_build_object('id','concept','type','heading','text','Learn the concept'),
   jsonb_build_object('id','explanation','type','text','text',body),
   jsonb_build_object('id','worked-example','type','worked_example','title','Worked example','text','Solve x + 3 = 8 by subtracting 3 from both sides. x = 5.'),
   jsonb_build_object('id','quick-activity','type','activity','prompt','Which operation keeps both sides balanced?','items',jsonb_build_array('Apply the same operation to both sides','Change only one side'),'answer','Apply the same operation to both sides.'),
   jsonb_build_object('id','summary','type','summary','text','An equation stays balanced when the same operation is applied to both sides.'))),
   learning_objectives='["Isolate a variable in a simple equation"]'
 where course_id=math and content_type='lesson';
 if not exists(select 1 from content_nodes where course_id=math and title='Word Problems') then
  insert into content_nodes(course_id,parent_id,content_type,title,body,structured_content,learning_objectives,status,scope,created_by,approved_by,approved_at,sort_order)
  values(math,algebra,'lesson','Word Problems','Translate a word problem into an equation.','{"components":[{"id":"concept","type":"text","text":"Identify the unknown, name it with a variable, then write the relationship as an equation."},{"id":"reflection","type":"reflection","prompt":"What is the unknown in your example?"},{"id":"summary","type":"summary","text":"Define the unknown before forming an equation."}]}','["Represent a word problem with a linear equation"]','published','global',author,author,now(),4);
 end if;
 if web is not null then
  insert into school_course_adoptions(school_id,course_id,adopted_by) values(sid,web,coalesce((select id from profiles where role='school_admin' and school_id=sid limit 1),author)) on conflict(school_id,course_id) do update set active=true;
  update courses set grade_id=grade8,learning_objectives='["Understand how webpages are structured","Style a webpage with CSS"]',difficulty='Beginner' where id=web;
  update content_nodes set content_type='lesson',structured_content=jsonb_build_object('components',jsonb_build_array(jsonb_build_object('id','concept','type','text','text',body),jsonb_build_object('id','try-it','type','project_instruction','title','Try it','text','Create a small example and observe what changes.'),jsonb_build_object('id','reflection','type','reflection','prompt','What did you change and what happened?'))),learning_objectives='["Create and explain a small web example"]' where course_id=web;
 end if;
 insert into school_course_assignments(school_id,course_id,grade_id,is_active) values(sid,math,grade8,true) on conflict nulls not distinct (school_id,course_id,grade_id,class_id) do update set is_active=true;
 select id into amani_profile from profiles where school_id=sid and lower(first_name)='amani' and lower(last_name)='njoroge' limit 1;
 select id into amani_class from classes where school_id=sid and grade_id=grade8 order by name limit 1;
 if amani_profile is not null and not exists(select 1 from student_profiles where profile_id=amani_profile) then insert into student_profiles(school_id,profile_id,student_number,grade_id,class_id) values(sid,amani_profile,'DEV-AMANI',grade8,amani_class); end if;
end $$;
