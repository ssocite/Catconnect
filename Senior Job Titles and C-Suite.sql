with a as (select
stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__contact__c,
max (stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__url__c) keep (dense_rank first order by stg_alumni.ucinn_ascendv2__social_media__c.lastmodifieddate) as Linkedin_address
from stg_alumni.ucinn_ascendv2__social_media__c
where stg_alumni.ucinn_ascendv2__social_media__c.ap_status__c like '%Current%'
and stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__platform__c = 'LinkedIn'
group BY stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__contact__c
),

-- max(linkedin_url) keep dense_rank first ...
--- Using Keep Dense Rank

l as (select distinct c.ucinn_ascendv2__donor_id__c,
c.ucinn_ascendv2__first_and_last_name_formula__c,
a.linkedin_address
from stg_alumni.contact c
inner join a on c.id = a.ucinn_ascendv2__contact__c),

--- Employment - primary
--- Also use keep dense rank function to pull most recent employee start date

employ as (select distinct
c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C,
max (c.ap_is_primary_employment__c) keep (dense_rank First Order by c.ucinn_ascendv2__start_date__c desc) as primary_employ_ind,
max (c.ucinn_ascendv2__job_title__c) keep (dense_rank first order by c.ucinn_ascendv2__start_date__c desc) as primary_job_title,
max (c.UCINN_ASCENDV2__RELATED_ACCOUNT_NAME_FORMULA__C) keep (dense_rank first order by c.ucinn_ascendv2__start_date__c desc) as primary_employer
from stg_alumni.ucinn_ascendv2__Affiliation__c c
where c.ap_is_primary_employment__c = 'true'
group by c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C),

--- Employment with Senior Titles

final_employment as (select
employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C,
employ.primary_job_title,
employ.primary_employer
from employ
where   ((primary_job_title like '%Vice President%'
or primary_job_title like '%VP%'
or primary_job_title like '%Owner%'
or primary_job_title like '%Founder%'
or primary_job_title like '%Managing Director%'
or primary_job_title like '%Executive%'
or primary_job_title like '%Partner%'
or primary_job_title like '%Principal%'
or primary_job_title like '%Head%'
or primary_job_title like '%Senior%'
or primary_job_title like '%Chief%'
or primary_job_title like '%Board%'
---- Check Abbreviations too 
or primary_job_title like '%CEO%'
--- Chief Finance Officer
or primary_job_title like '%CFO%'
--- Chief Marketing Officer
or primary_job_title like '%CMO%'
--- Chief Information Officer
or primary_job_title like '%CIO%'
--- Chiefer Operating Office
or primary_job_title like '%COO%'
--- Chief Tech Officer
or primary_job_title like '%CTO%'
--- Chief Compliance officer
or primary_job_title like '%CCO%')

--- take out assistants/associates/advisors, not actual senior titles

and (primary_job_title not like '%Assistant%'
and primary_job_title not like '%Asst%'
and primary_job_title not like '%Associate%'
and primary_job_title not like '%Assoc%'
and primary_job_title not like '%Advisor%'
and primary_job_title not like '%Workspace Product Partnerships%'))),

--- Special Handling

SH as (select  s.donor_id,
       s.no_contact,
       s.no_email_ind
from mv_special_handling s),

--- TP
TP as (select C.CONSTITUENT_DONOR_ID,
c.constituent_university_overall_rating,
c.constituent_research_evaluation
from DM_ALUMNI.DIM_CONSTITUENT C ),

--- Assignment

assign as (Select a.household_id,
       a.donor_id,
       a.sort_name,
       a.prospect_manager_name,
       a.lagm_user_id,
       a.lagm_name
From mv_assignments a),

--- Giving Summary

give as (select g.household_id,
g.household_primary_donor_id,
       g.ngc_lifetime,
       g.ngc_cfy,
       g.ngc_pfy1,
       g.ngc_pfy2,
       g.ngc_pfy3,
       g.ngc_pfy4,
       g.ngc_pfy5,
       g.last_ngc_tx_id,
       g.last_ngc_date,
       g.last_ngc_opportunity_type,
       g.last_ngc_designation_id,
       g.last_ngc_designation,
       g.last_ngc_recognition_credit
from mv_ksm_giving_summary g),

--- Geocodes

geocode as (select distinct g.ap_address_relation_record_type__c,
                        g.ap_address_relation__c,
                        g.ap_constituent__c,
                        g.ap_geocode_value__c,
                        g.ap_geocode_value_description__c,
                        g.ap_is_active__c,
                        g.ap_is_constituent_address_relation__c,
                        g.geocode_value_type_description__c,
                        g.id
from stg_alumni.ap_geocode__c g
--- Active Geocode
where g.ap_is_active__c = 'true'
--- San Fran Geocode
and g.ap_geocode_value_description__c like '%San Francisco%'),

--- Join Geocode on Address

fa as (select geocode.id,
s.ucinn_ascendv2__donor_id__c,
geocode.ap_geocode_value_description__c,
a.ucinn_ascendv2__address__c,
a.ucinn_ascendv2__contact__c,
a.ucinn_ascendv2__is_preferred__c
from stg_alumni.ucinn_ascendv2__address_relation__c a
--- we want just those in the geocode
inner join geocode on geocode.ap_address_relation__c = a.id
left join stg_alumni.contact s on s.id = a.ucinn_ascendv2__contact__c
--- Preferred address
where a.ucinn_ascendv2__is_preferred__c = 'true')

--- Final Query

select distinct
       e.donor_id,
       e.sort_name,
       e.gender_identity,
       e.is_deceased_indicator,
       e.lost_indicator,
       e.primary_record_type,
       e.institutional_suffix,
       e.preferred_address_city,
       e.preferred_address_state,
       e.preferred_address_country,
       d.first_ksm_year,
       d.program,
       d.program_group,
       final_employment.primary_employer,
       final_employment.primary_job_title,
       l.linkedin_address,
       sh.no_contact,
       sh.no_email_ind,
       TP.constituent_university_overall_rating,
       TP.constituent_research_evaluation,
       a.prospect_manager_name,
       a.lagm_name,
       give.ngc_lifetime,
       give.ngc_cfy,
       give.ngc_pfy1,
       give.ngc_pfy2,
       give.ngc_pfy3,
       give.ngc_pfy4,
       give.ngc_pfy5,
       give.last_ngc_tx_id,
       give.last_ngc_date,
       give.last_ngc_opportunity_type,
       give.last_ngc_designation_id,
       give.last_ngc_designation,
       give.last_ngc_recognition_credit
from mv_entity e
--- San Francisco
inner join fa on fa.ucinn_ascendv2__donor_id__c = e.donor_id
--- ksm degree information
inner join mv_entity_ksm_degrees d on d.donor_id = e.donor_id
--- empoloyment
inner join final_employment on final_employment.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
--- linkedin
left join l on l.ucinn_ascendv2__donor_id__c = e.donor_id
--- special handling
left join sh on sh.donor_id = e.donor_id
--- Top Prospect
left join TP on TP.CONSTITUENT_DONOR_ID = e.donor_id
--- assignment
left join assign a on a.donor_id = e.donor_id
--- Give
left join give on give.household_primary_donor_id = e.donor_id
--- Remove No Contacts
where sh.no_contact is null
--- Remove Students
and d.program != 'STUDENT'
--- Alive
and e.is_deceased_indicator = 'N'
--- alumnae 
and e.gender_identity like '%Woman%'
order by  final_employment.primary_job_title asc
