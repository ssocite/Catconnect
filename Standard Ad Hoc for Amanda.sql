"--- Current Linkedin Addresses
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


B as (select distinct
 co.constituent_donor_id,
 co.industry_subsectors,
 co.industries
from DM_ALUMNI.Dim_Constituent co),



--- Special Handling

SH as (select  s.donor_id,
       s.no_contact,
       s.no_email_ind
from mv_special_handling s),

--- Top Prospect

TP as (select C.CONSTITUENT_DONOR_ID,
c.constituent_university_overall_rating,
c.constituent_research_evaluation
from DM_ALUMNI.DIM_CONSTITUENT C ),

--- Giving Summary

give as (select g.household_id,
g.household_primary_donor_id,
       g.ngc_lifetime,
       g.ngc_cfy,
       g.ngc_pfy1,
       g.ngc_pfy2,
       g.ngc_pfy3,
       g.ngc_pfy4,
       g.ngc_pfy5
from mv_ksm_giving_summary g),

--- Assignment

assign as (Select a.household_id,
       a.donor_id,
       a.sort_name,
       a.prospect_manager_name,
       a.lagm_user_id,
       a.lagm_name
From mv_assignments a),

--- model score

m as (select k.donor_id,
       k.alumni_engagement_code,
       k.alumni_engagement_description,
       k.alumni_engagement_score,
       k.student_supporter_code,
       k.student_supporter_description,
       k.student_supporter_score
from mv_ksm_models k)

select distinct
       e.donor_id,
       e.gender_identity,
       e.gender_code,
       e.sort_name,
       e.first_name,
       e.primary_record_type,
       e.institutional_suffix,
       d.program,
       d.program_group,
       d.first_ksm_year,
       employ.primary_employer,
       employ.primary_job_title,
       case when final_employment.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C is not null then 'C-Suite' End as C_suite_flag,
       b.industry_subsectors,
       b.industries,
       assign.prospect_manager_name,
       assign.lagm_name,
       e.preferred_address_city,
       e.preferred_address_country,
       give.ngc_lifetime,
       tp.constituent_university_overall_rating,
       tp.constituent_research_evaluation,
       l.linkedin_address,
       sh.no_contact,
       sh.no_email_ind,
       m.alumni_engagement_code,
       m.alumni_engagement_description,
       m.alumni_engagement_score,
       m.student_supporter_code,
       m.student_supporter_description,
       m.student_supporter_score
from mv_entity e
--- ksm degree information
inner join mv_entity_ksm_degrees d on d.donor_id = e.donor_id
--- empoloyment
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
--- linkedin
left join l on l.ucinn_ascendv2__donor_id__c = e.donor_id
--- special handling
left join sh on sh.donor_id = e.donor_id
--- Eval Rating
left join tp on tp.CONSTITUENT_DONOR_ID = e.donor_id
--- give
left join give on give.household_primary_donor_id = e.donor_id
--- assign
left join assign on assign.donor_id = e.donor_id
--- industries
left join b on b.constituent_donor_id = e.donor_id
--- model score
left join m on m.donor_id = e.donor_id
--- C-sutie Flag
left join final_employment on final_employment.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
where
--- Remove deceased records
e.is_deceased_indicator = 'N'
--- Alumni
and e.primary_record_type = 'Alum'
---- Take out No Contacts
and (sh.no_contact is null)
--- First KSM Year
and d.first_ksm_year IN ('2024','2020','2015')
--- filter for IDs
order by  employ.primary_job_title asc
