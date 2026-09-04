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

-- OPTIONAL STAGE 10 SKILLS LAB DATA. Two focused pathways, not a mass-generated catalog.
do $$ declare author uuid;sid uuid;admin uuid;web uuid;entrepreneur uuid;web_path uuid;business_path uuid;personal uuid;pitch uuid;n uuid;html_skill uuid;css_skill uuid;
begin
 select id into author from profiles where role='platform_admin' limit 1;select id into sid from schools where slug='greenfield-academy';select id into admin from profiles where school_id=sid and role='school_admin' limit 1;select id into web from courses where slug='demo-web-creator';
 if author is null or web is null then raise notice 'Skipping Stage 10 seed until governed Web Creator content exists.';return;end if;
 -- Complete the shared Web Creator content sequence with lessons, challenge and project bridge.
 insert into content_nodes(course_id,content_type,title,body,structured_content,learning_objectives,status,scope,created_by,approved_by,approved_at,sort_order) values
 (web,'lesson','Responsive Design','Use flexible layouts and media queries so pages work across screen sizes.','{"components":[{"type":"demonstration","text":"Resize a flexible card layout."},{"type":"activity","prompt":"Adapt one section for a narrow screen."},{"type":"reflection","prompt":"What changed at the breakpoint?"}]}','["Build a responsive layout"]','published','global',author,author,now(),4),
 (web,'lesson','JavaScript Basics','Add a small interaction while keeping structure, style, and behavior separate.','{"components":[{"type":"demonstration","text":"Connect a button click to a visible change."},{"type":"activity","prompt":"Add one useful interaction."}]}','["Add a basic webpage interaction"]','published','global',author,author,now(),5),
 (web,'challenge','CSS Card Challenge','Create three cards with consistent spacing and distinct background styles.','{"submissionType":"reflection","prompt":"What CSS rule created consistency?"}','["Apply consistent CSS styling"]','published','global',author,author,now(),6),
 (web,'activity','Build Your Website','Combine page structure, content, styling and responsive behavior.','{"components":[{"type":"project_instruction","text":"Build, test, improve, then explain your choices."}]}','["Plan and build a webpage"]','published','global',author,author,now(),7)
 on conflict do nothing;
 insert into skills(scope,course_id,name,description) values('global',web,'HTML Structure','Use semantic elements to organize a page') returning id into html_skill;
 insert into skills(scope,course_id,name,description) values('global',web,'CSS Styling','Apply clear, consistent visual styles') returning id into css_skill;
 insert into learning_pathways(scope,title,description,category,difficulty,status,created_by,approved_by,approved_at) values('global','Web Creator','Learn how websites work and build your own responsive website.','skill','Beginner','published',author,author,now()) returning id into web_path;
 for n in select id from content_nodes where course_id=web and title in('How the Web Works','HTML Foundations','CSS Foundations','Responsive Design','JavaScript Basics','CSS Card Challenge','Build Your Website') order by sort_order loop insert into pathway_items(pathway_id,content_node_id,level,sort_order,is_required) values(web_path,n,(select sort_order from content_nodes where id=n),(select sort_order from content_nodes where id=n),true);end loop;
 insert into projects(scope,course_id,pathway_id,title,description,difficulty,estimated_minutes,instructions,success_criteria_json,status,created_by) values('global',web,web_path,'Personal Website','Create and present a working responsive website.','Beginner',240,'Build a personal website, test it at several widths, publish it safely, then explain what you learned.','[{"key":"structure","label":"Valid page structure with a heading, paragraph and links"},{"key":"style","label":"Clear basic styling and consistent spacing"},{"key":"responsive","label":"Usable responsive behavior"},{"key":"reflection","label":"Thoughtful reflection completed"}]','published',author) returning id into personal;
 insert into project_milestones(project_id,title,description,instructions,sort_order,required,related_skill_id,estimated_minutes) values
 (personal,'Create page structure','Start with meaningful HTML.','Add the main page regions, heading, paragraph and navigation links.',1,true,html_skill,45),(personal,'Add your content','Make the site yours.','Write concise content and add safe links.',2,true,html_skill,35),(personal,'Style with CSS','Create a consistent visual system.','Choose spacing, color and typography rules and apply them consistently.',3,true,css_skill,55),(personal,'Make it responsive','Support small and large screens.','Test at multiple widths and fix overflow or cramped layouts.',4,true,css_skill,55),(personal,'Final review','Check and explain the outcome.','Use every success criterion, correct issues, and prepare your reflection.',5,true,null,50);
 insert into courses(scope,title,slug,description,content_family,difficulty,status,created_by,approved_by,approved_at) values('global','Young Entrepreneur','demo-young-entrepreneur','Turn a real problem into a tested idea and simple pitch.','skills','Beginner','published',author,author,now()) returning id into entrepreneur;
 insert into content_nodes(course_id,content_type,title,body,status,scope,created_by,approved_by,approved_at,sort_order) values
 (entrepreneur,'lesson','Finding Problems','Notice useful problems without judging people.','published','global',author,author,now(),1),(entrepreneur,'activity','Understanding Customers','Ask respectful questions and record needs, not assumptions.','published','global',author,author,now(),2),(entrepreneur,'challenge','Idea Generation','Generate three alternatives before choosing one.','published','global',author,author,now(),3),(entrepreneur,'lesson','Testing an Idea','Run a small, ethical validation test.','published','global',author,author,now(),4),(entrepreneur,'activity','Simple Business Model','Describe value, costs and a fair way to sustain the idea.','published','global',author,author,now(),5),(entrepreneur,'challenge','Pitching','Explain problem, audience, idea and evidence in two minutes.','published','global',author,author,now(),6);
 insert into learning_pathways(scope,title,description,category,difficulty,status,created_by,approved_by,approved_at) values('global','Young Entrepreneur','Find a useful problem, test an idea, and communicate a simple business model.','skill','Beginner','published',author,author,now()) returning id into business_path;
 for n in select id from content_nodes where course_id=entrepreneur order by sort_order loop insert into pathway_items(pathway_id,content_node_id,level,sort_order,is_required) values(business_path,n,(select sort_order from content_nodes where id=n),(select sort_order from content_nodes where id=n),true);end loop;
 insert into projects(scope,course_id,pathway_id,title,description,difficulty,estimated_minutes,instructions,success_criteria_json,status,created_by) values('global',entrepreneur,business_path,'Mini Business Pitch','A validated idea and concise, evidence-aware pitch.','Beginner',180,'Choose a problem, learn from potential customers, test one assumption, and present what the evidence says.','[{"key":"problem","label":"Specific problem and audience"},{"key":"evidence","label":"Evidence from a small validation activity"},{"key":"model","label":"Simple and realistic business model"},{"key":"pitch","label":"Clear short pitch and reflection"}]','published',author) returning id into pitch;
 insert into project_milestones(project_id,title,description,instructions,sort_order,required,estimated_minutes) values(pitch,'Define the problem','Choose one useful problem.','Describe who experiences it and why it matters.',1,true,30),(pitch,'Learn from customers','Replace assumptions with respectful evidence.','Ask at least three people neutral questions and summarize themes.',2,true,45),(pitch,'Test one assumption','Run a small test.','Choose the riskiest assumption and test it safely.',3,true,40),(pitch,'Build the pitch','Tell a concise, honest story.','Present the problem, audience, solution, evidence and simple model.',4,true,45),(pitch,'Reflect','Decide what to improve.','Explain what changed and what you would test next.',5,true,20);
 if sid is not null then insert into school_pathway_settings(school_id,pathway_id,enabled,requirement) values(sid,web_path,true,'optional'),(sid,business_path,true,'optional') on conflict(school_id,pathway_id)do update set enabled=true;insert into school_course_adoptions(school_id,course_id,adopted_by)values(sid,entrepreneur,coalesce(admin,author))on conflict(school_id,course_id)do update set active=true;end if;
 insert into learning_graph_relationships(scope,source_type,source_id,target_type,target_id,relationship_type,is_required,weight,created_by) values('global','skill',css_skill,'skill',html_skill,'recommended_after',false,2,author),('global','pathway',business_path,'pathway',web_path,'related',false,1,author);
end $$;
