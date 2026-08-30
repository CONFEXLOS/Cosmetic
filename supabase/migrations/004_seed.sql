-- BeautyLink Africa — données de démonstration déterministes
insert into public.currencies(code,name,symbol,decimals,active) values
('XOF','Franc CFA','FCFA',0,true),
('EUR','Euro','€',2,true),
('USD','Dollar américain','$',2,true)
on conflict(code) do update set name=excluded.name,symbol=excluded.symbol,active=excluded.active;

insert into public.countries(code,name,default_currency,default_language,phone_prefix,active) values
('SN','Sénégal','XOF','fr','+221',true),
('CI','Côte d’Ivoire','XOF','fr','+225',false),
('ML','Mali','XOF','fr','+223',false),
('FR','France','EUR','fr','+33',false)
on conflict(code) do update set name=excluded.name,active=excluded.active;

insert into public.profiles(id,display_name,handle,bio,city,country_code,primary_role,verification_status,is_public,is_demo) values
('00000000-0000-0000-0000-000000000001','Mariama Sow','mariama.dkr','Journal de routine et découverte de produits.','Dakar','SN','consumer','verified',true,true),
('00000000-0000-0000-0000-000000000002','Dr Aïssatou Diagne','dr.aissatou','Dermatologue fictive de démonstration.','Dakar','SN','doctor','verified',true,true),
('00000000-0000-0000-0000-000000000003','Fatou Ndiaye','fatou.skincoach','Esthéticienne et skincare coach fictive de démonstration.','Dakar','SN','beauty_professional','verified',true,true),
('00000000-0000-0000-0000-000000000004','Teranga Skin','terangaskin','Marque locale fictive de démonstration.','Dakar','SN','brand_seller','verified',true,true),
('00000000-0000-0000-0000-000000000005','Admin BeautyLink','admin.beautylink','Compte administration fictif de démonstration.','Dakar','SN','super_admin','verified',false,true),
('00000000-0000-0000-0000-000000000006','Dr Marième Faye','dr.marieme.faye','Dermatologue fictive de démonstration.','Dakar','SN','doctor','verified',true,true),
('00000000-0000-0000-0000-000000000007','Cheikh Sarr','cheikh.grooming','Barbier et spécialiste grooming fictif.','Dakar','SN','beauty_professional','verified',true,true),
('00000000-0000-0000-0000-000000000008','Awa Camara','awa.senteurs','Conseillère en parfumerie fictive.','Dakar','SN','beauty_professional','verified',true,true),
('00000000-0000-0000-0000-000000000009','Khady Fall','khady.haircare','Spécialiste cheveux naturels fictive.','Thiès','SN','beauty_professional','verified',true,true)
on conflict(id) do update set display_name=excluded.display_name,handle=excluded.handle,bio=excluded.bio,city=excluded.city,primary_role=excluded.primary_role,verification_status=excluded.verification_status,is_demo=true;

insert into public.user_roles(profile_id,role) values
('00000000-0000-0000-0000-000000000001','consumer'),
('00000000-0000-0000-0000-000000000002','doctor'),
('00000000-0000-0000-0000-000000000003','beauty_professional'),
('00000000-0000-0000-0000-000000000004','brand_seller'),
('00000000-0000-0000-0000-000000000005','super_admin'),
('00000000-0000-0000-0000-000000000006','doctor'),
('00000000-0000-0000-0000-000000000007','beauty_professional'),
('00000000-0000-0000-0000-000000000008','beauty_professional'),
('00000000-0000-0000-0000-000000000009','beauty_professional')
on conflict do nothing;

insert into public.profile_private(profile_id,email,phone,preferred_language) values
('00000000-0000-0000-0000-000000000001','mariama.demo@beautylink.local','+221770000001','fr')
on conflict(profile_id) do update set email=excluded.email,phone=excluded.phone;

insert into public.notification_preferences(profile_id, in_app, email, sms, whatsapp, push) values
('00000000-0000-0000-0000-000000000001',true,true,false,true,true)
on conflict(profile_id) do nothing;

insert into public.beauty_profiles(profile_id,skin_type,scalp_type,hair_type,concerns,sensitivities,fragrance_families,fragrance_intensity,monthly_budget_min,monthly_budget_max,habits) values
('00000000-0000-0000-0000-000000000001','mixte','normal','crépu',array['taches','imperfections','hydratation'],array['parfums forts'],array['floral','boisé'],'modérée',20000,45000,'{"routine_morning":true,"routine_evening":true}'::jsonb)
on conflict(profile_id) do update set skin_type=excluded.skin_type,concerns=excluded.concerns,monthly_budget_min=excluded.monthly_budget_min,monthly_budget_max=excluded.monthly_budget_max;

insert into public.goals(id,profile_id,domain,label,status) values
('01000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','beauty','Uniformiser l’apparence du teint','active'),
('01000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000001','beauty','Maintenir une routine régulière','active')
on conflict(id) do update set label=excluded.label,status=excluded.status;

insert into public.allergy_declarations(id,profile_id,substance,reaction_description,severity) values
('01100000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','Parfum synthétique fort','Irritation déclarée par l’utilisatrice','mild')
on conflict(id) do update set reaction_description=excluded.reaction_description;

insert into public.brands(id,owner_profile_id,name,slug,description,country_code,verification_status) values
('30000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000004','Teranga Skin','teranga-skin','Skincare pensé pour les climats africains.','SN','verified'),
('30000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000004','Baobab Care','baobab-care','Soins hydratants et corporels.','SN','verified'),
('30000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000004','Maison Ndar','maison-ndar','Parfumerie inspirée de Saint-Louis.','SN','verified'),
('30000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000004','Sahel Grooming','sahel-grooming','Grooming homme et barbe.','SN','verified')
on conflict(id) do update set name=excluded.name,description=excluded.description,verification_status='verified';

insert into public.products(id,brand_id,seller_profile_id,sku,name,slug,category,audience,description,ingredients,usage_instructions,precautions,origin_country,base_price,currency_code,stock_quantity,status,average_rating,review_count,metadata) values
('40000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000004','TS-SER-001','Sérum Éclat Karité & Niacinamide','serum-eclat-karite-niacinamide','visage','unisex','Sérum léger pour améliorer l’apparence de l’uniformité du teint.',array['niacinamide','glycérine','dérivés de karité'],'Quelques gouttes le soir.','Test local recommandé.','SN',18500,'XOF',42,'active',4.70,128,'{"volume":"30 ml","skin_types":["mixte","grasse"],"goals":["éclat","taches"]}'::jsonb),
('40000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000004','BC-SPF-001','Crème Hydratante Baobab SPF30','creme-hydratante-baobab-spf30','visage','unisex','Hydratation quotidienne et protection solaire.',array['baobab','humectants','filtres UV'],'Dernière étape du matin.','Renouveler selon l’exposition.','SN',14900,'XOF',15,'active',4.50,96,'{"volume":"50 ml","goals":["hydratation","protection"]}'::jsonb),
('40000000-0000-0000-0000-000000000003','30000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000004','TS-CLE-001','Nettoyant Doux Sans Savon','nettoyant-doux-sans-savon','visage','unisex','Nettoyant visage quotidien.',array['base lavante douce','glycérine'],'Matin et soir.','Éviter les yeux.','SN',8500,'XOF',96,'active',4.80,211,'{"volume":"200 ml","skin_types":["sensible","sèche","mixte"]}'::jsonb),
('40000000-0000-0000-0000-000000000004','30000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000004','MN-PAR-001','Eau de Parfum Dakar Nuit','eau-de-parfum-dakar-nuit','parfums','unisex','Parfum ambré et boisé.',array['composition parfumante'],'Points de pulsation.','Inflammable.','SN',39000,'XOF',9,'active',4.90,88,'{"volume":"75 ml","fragrance_families":["ambré","boisé"]}'::jsonb),
('40000000-0000-0000-0000-000000000005','30000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000004','SG-BRD-001','Huile Barbe Oud & Vétiver','huile-barbe-oud-vetiver','barbe','homme','Huile nourrissante pour barbe.',array['huiles végétales','oud','vétiver'],'Quelques gouttes sur barbe propre.','Usage externe.','SN',11500,'XOF',38,'active',4.60,74,'{"volume":"30 ml"}'::jsonb),
('40000000-0000-0000-0000-000000000006','30000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000004','BC-HAI-001','Masque Capillaire Protéiné','masque-capillaire-proteine','cheveux','unisex','Masque pour cheveux crépus et bouclés.',array['protéines hydrolysées','huiles végétales'],'Une fois par semaine.','Espacer si rigidité.','SN',12500,'XOF',29,'active',4.40,61,'{"volume":"250 ml"}'::jsonb),
('40000000-0000-0000-0000-000000000007','30000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000004','BC-BOD-001','Lait Corps Beurre de Karité','lait-corps-beurre-karite','corps','unisex','Lait corps hydratant.',array['karité','glycérine'],'Après la douche.','Usage externe.','SN',9900,'XOF',67,'active',4.30,107,'{"volume":"400 ml"}'::jsonb),
('40000000-0000-0000-0000-000000000008','30000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000004','TS-KIT-001','Coffret Routine Débutant Peau Grasse','coffret-routine-debutant-peau-grasse','coffrets','unisex','Routine de base en trois étapes.',array['voir chaque produit'],'Suivre la fiche routine.','Introduire progressivement.','SN',34500,'XOF',18,'active',4.80,54,'{"compare_at_price":41000}'::jsonb),
('40000000-0000-0000-0000-000000000009','30000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000004','TS-SPF-002','Fluide Solaire Invisible SPF50','fluide-solaire-invisible-spf50','visage','unisex','Fluide solaire sans effet blanc visible.',array['filtres UV','humectants'],'Appliquer généreusement.','Renouveler.','SN',16900,'XOF',52,'active',4.70,166,'{"volume":"50 ml"}'::jsonb),
('40000000-0000-0000-0000-000000000010','30000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000004','TS-MSK-001','Masque Argile Douce','masque-argile-douce','visage','unisex','Masque hebdomadaire doux.',array['argiles','glycérine'],'Une fois par semaine.','Ne pas laisser sécher complètement.','SN',7900,'XOF',41,'active',4.20,44,'{"volume":"100 ml"}'::jsonb),
('40000000-0000-0000-0000-000000000011','30000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000004','MN-PAR-002','Brume Ndar Fraîche','brume-ndar-fraiche','parfums','femme','Brume fraîche et légère.',array['composition parfumante'],'Vaporiser à distance.','Inflammable.','SN',14500,'XOF',25,'active',4.30,39,'{"volume":"100 ml"}'::jsonb),
('40000000-0000-0000-0000-000000000012','30000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000004','MN-PAR-003','Vanille de Gorée','vanille-de-goree','parfums','unisex','Parfum gourmand vanillé.',array['composition parfumante'],'Points de pulsation.','Inflammable.','SN',32000,'XOF',16,'active',4.60,71,'{"volume":"50 ml"}'::jsonb)
on conflict(id) do update set name=excluded.name,slug=excluded.slug,category=excluded.category,base_price=excluded.base_price,stock_quantity=excluded.stock_quantity,status='active',metadata=excluded.metadata,updated_at=now();

insert into public.specialties(id,code,name,medical,active) values
('10000000-0000-0000-0000-000000000001','dermatology','Dermatologie',true,true),
('10000000-0000-0000-0000-000000000002','skincare','Soins visage & skincare',false,true),
('10000000-0000-0000-0000-000000000003','perfumery','Conseil en parfumerie',false,true),
('10000000-0000-0000-0000-000000000004','grooming','Grooming homme & barbe',false,true),
('10000000-0000-0000-0000-000000000005','haircare','Soins capillaires non médicaux',false,true)
on conflict(id) do update set name=excluded.name,medical=excluded.medical,active=true;

insert into public.professionals(profile_id,professional_type,title,establishment_name,license_number,years_experience,languages,specialties_summary,verification_status,verified_at,consultation_enabled,teleconsultation_enabled,average_rating,review_count,metadata) values
('00000000-0000-0000-0000-000000000002','doctor','Dermatologue','Cabinet fictif Point E','DEMO-MED-SN-001',12,array['fr','wo'],'Hyperpigmentation, acné et peaux noires','verified',now(),true,true,4.90,184,'{"demo_only":true,"no_product_commission":true}'::jsonb),
('00000000-0000-0000-0000-000000000006','doctor','Dermatologue','Clinique fictive Almadies','DEMO-MED-SN-002',9,array['fr','wo','en'],'Dermatologie clinique et cuir chevelu','verified',now(),true,true,4.80,96,'{"demo_only":true,"no_product_commission":true}'::jsonb),
('00000000-0000-0000-0000-000000000003','beauty_professional','Esthéticienne & Skincare coach','Studio fictif Fatou Beauty',null,7,array['fr','wo'],'Routines et soins visage non médicaux','verified',now(),true,true,4.80,233,'{"demo_only":true}'::jsonb),
('00000000-0000-0000-0000-000000000007','beauty_professional','Barbier & spécialiste grooming','Sahel Grooming Studio',null,10,array['fr','wo'],'Barbe et grooming','verified',now(),true,false,4.60,141,'{"demo_only":true}'::jsonb),
('00000000-0000-0000-0000-000000000008','beauty_professional','Conseillère en parfumerie','Maison des Senteurs',null,5,array['fr','en'],'Profil olfactif','verified',now(),true,true,4.50,58,'{"demo_only":true}'::jsonb),
('00000000-0000-0000-0000-000000000009','beauty_professional','Spécialiste cheveux naturels','Nappy Thiès',null,8,array['fr','wo'],'Routines capillaires non médicales','verified',now(),true,true,4.70,119,'{"demo_only":true}'::jsonb)
on conflict(profile_id) do update set title=excluded.title,verification_status='verified',average_rating=excluded.average_rating,review_count=excluded.review_count,metadata=excluded.metadata;

insert into public.professional_specialties(professional_profile_id,specialty_id) values
('00000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000006','10000000-0000-0000-0000-000000000001'),
('00000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000002'),
('00000000-0000-0000-0000-000000000007','10000000-0000-0000-0000-000000000004'),
('00000000-0000-0000-0000-000000000008','10000000-0000-0000-0000-000000000003'),
('00000000-0000-0000-0000-000000000009','10000000-0000-0000-0000-000000000005')
on conflict do nothing;

insert into public.professional_services(id,professional_profile_id,name,description,duration_minutes,price,currency_code,delivery_mode,active,is_medical) values
('20000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','Téléconsultation dermatologique','Consultation vidéo dans un cadre médical.',25,25000,'XOF','online',true,true),
('20000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000003','Coaching routine en ligne','Conseil esthétique non médical.',30,12000,'XOF','online',true,false),
('20000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000007','Taille de barbe + soin','Prestation grooming.',45,8000,'XOF','in_person',true,false),
('20000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000008','Consultation olfactive','Profil parfum et sélection.',40,10000,'XOF','online',true,false)
on conflict(id) do update set price=excluded.price,active=true;

insert into public.posts(id,author_profile_id,kind,visibility,body,tags,published_at,moderation_status) values
('80000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','medical','public','L’éclaircissement volontaire de la peau peut entraîner des complications. Privilégiez une information médicale fiable et une photoprotection adaptée.',array['peaunoire','photoprotection'],now()-interval '2 hours','approved'),
('80000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000003','educational','public','Ordre simple : nettoyant, sérum, hydratant, protection solaire. Introduisez un actif à la fois.',array['routine','debutant'],now()-interval '5 hours','approved'),
('80000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000004','sponsored','public','Le coffret routine peau grasse est de retour en stock. Contenu sponsorisé de démonstration.',array['coffret','sponsorise'],now()-interval '12 hours','approved'),
('80000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000001','testimonial','public','Mon journal m’aide à suivre la régularité de ma routine sans confondre ce suivi avec un diagnostic.',array['journal','progression'],now()-interval '1 day','approved')
on conflict(id) do update set body=excluded.body,published_at=excluded.published_at,moderation_status='approved';

insert into public.routines(id,profile_id,name,status,created_by_profile_id,is_clinical) values
('70000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','Routine matin et soir','active','00000000-0000-0000-0000-000000000003',false)
on conflict(id) do update set status='active';

insert into public.routine_items(id,routine_id,product_id,label,moment,sort_order,instructions,frequency,status) values
('71000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000003','Nettoyant doux','morning',1,'Nettoyer délicatement.','{"days":[1,2,3,4,5,6,7]}'::jsonb,'active'),
('71000000-0000-0000-0000-000000000002','70000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','Sérum niacinamide','evening',2,'Introduire progressivement.','{"days":[1,3,5]}'::jsonb,'active'),
('71000000-0000-0000-0000-000000000003','70000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000002','Hydratant SPF','morning',3,'Dernière étape du matin.','{"days":[1,2,3,4,5,6,7]}'::jsonb,'active')
on conflict(id) do update set instructions=excluded.instructions,status='active';

insert into public.care_carts(id,profile_id,name,status) values
('90000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','Routine éclat','active')
on conflict(id) do update set status='active';

insert into public.care_cart_items(id,care_cart_id,product_id,quantity,status,selected_for_checkout,recommended_by_profile_id,note) values
('91000000-0000-0000-0000-000000000001','90000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001',1,'to_buy',true,'00000000-0000-0000-0000-000000000003','À introduire progressivement'),
('91000000-0000-0000-0000-000000000002','90000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000002',1,'recommended',true,'00000000-0000-0000-0000-000000000003','Routine du matin'),
('91000000-0000-0000-0000-000000000003','90000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000003',2,'started',false,null,'Utilisé depuis 12 jours')
on conflict(id) do update set status=excluded.status,selected_for_checkout=excluded.selected_for_checkout,note=excluded.note;

insert into public.reminders(id,profile_id,title,reminder_type,channel,schedule,next_run_at,active) values
('92000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','Routine du matin','routine','in_app','{"time":"07:00","timezone":"Africa/Dakar"}'::jsonb,now()+interval '1 day',true),
('92000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000001','Feedback sérum J+14','feedback','whatsapp','{"offset_days":14}'::jsonb,now()+interval '7 days',true),
('92000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000001','Nettoyant bientôt terminé','refill','email','{"estimated_days":12}'::jsonb,now()+interval '12 days',true)
on conflict(id) do update set active=excluded.active,next_run_at=excluded.next_run_at;

insert into public.payment_providers(id,country_code,code,display_name,provider_type,enabled,sandbox_enabled,public_config) values
('93000000-0000-0000-0000-000000000001','SN','wave','Wave Sénégal','mobile_money',false,true,'{"configuration_required":true}'::jsonb),
('93000000-0000-0000-0000-000000000002','SN','orange_money','Orange Money Sénégal','mobile_money',false,true,'{"configuration_required":true}'::jsonb),
('93000000-0000-0000-0000-000000000003','SN','card','Carte bancaire','card',false,true,'{"configuration_required":true}'::jsonb),
('93000000-0000-0000-0000-000000000004','SN','cash_on_delivery','Paiement à la livraison','cash_on_delivery',true,true,'{"confirmation_required":true}'::jsonb)
on conflict(country_code,code) do update set display_name=excluded.display_name,sandbox_enabled=true;

insert into public.shipping_zones(id,country_code,name,cities,base_fee,eta_min_hours,eta_max_hours,active) values
('94000000-0000-0000-0000-000000000001','SN','Dakar centre',array['Dakar','Plateau','Mermoz','Ouakam','Almadies'],2000,12,48,true),
('94000000-0000-0000-0000-000000000002','SN','Grande banlieue Dakar',array['Pikine','Guédiawaye','Rufisque','Keur Massar'],3000,24,72,true),
('94000000-0000-0000-0000-000000000003','SN','Régions pilotes',array['Thiès','Saint-Louis'],4500,48,120,true)
on conflict(id) do update set base_fee=excluded.base_fee,active=true;
