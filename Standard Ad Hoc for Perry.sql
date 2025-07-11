--- Created a temp table from student group data

with golf as (select *
from KSM_Golf),

--- pulling linkedin

a as (select
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

--- email

email as (select  c.ucinn_ascendv2__donor_id__c,
c.email
from stg_alumni.contact c)

--- Final Query 

select distinct
       e.donor_id,
       case when golf.id_number is not null then 'Golf List' end as Golf,
       e.sort_name,
       e.primary_record_type,
       e.institutional_suffix,
       e.preferred_address_city,
       e.preferred_address_state,
       e.preferred_address_country,
       d.first_ksm_year,
       d.program,
       d.program_group,
       employ.primary_employer,
       employ.primary_job_title,
       l.linkedin_address,
       email.email,
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
inner join golf on golf.id_number = e.donor_id
--- ksm degree information
left join mv_entity_ksm_degrees d on d.donor_id = e.donor_id
--- empoloyment
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
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
--- email
left join email on email.ucinn_ascendv2__donor_id__c = e.donor_id
--- Remove No Contacts 
order by e.sort_name asc
