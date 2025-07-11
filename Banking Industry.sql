--- Current Linkedin Addresses
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
group by c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C
),

--- Banking, but pulling on industry and industry subsectors

B as (select distinct
 co.constituent_donor_id,
 co.industry_subsectors,
 co.industries
from DM_ALUMNI.Dim_Constituent co
where co.industry_subsectors like '%Banking%'),

--- Banking - Final Employment 

Bank as (select employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C,
employ.primary_job_title,
employ.primary_employer,
B.industry_subsectors,
b.industries
from employ
inner join B on
B.constituent_donor_id = UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C),

--- Special Handling --- Remove No Contacts

SH as (select  s.donor_id,
       s.no_contact
from mv_special_handling s),


--- Top Prospect

TP as (select C.CONSTITUENT_DONOR_ID,
c.constituent_university_overall_rating,
c.constituent_research_evaluation
from DM_ALUMNI.DIM_CONSTITUENT C ),

--- Assignment

assign as (Select a.donor_id,
       a.prospect_manager_name,
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
       g.ngc_pfy5
from mv_ksm_giving_summary g)

select distinct
       e.donor_id,
       e.household_id,
       e.sort_name,
       e.primary_record_type,
       e.institutional_suffix,
       d.first_ksm_year,
       d.program,
       d.program_group,
       bank.primary_job_title,
       bank.primary_employer,
       bank.industries,
       bank.industry_subsectors, 
       give.ngc_lifetime,
       give.ngc_cfy,
       give.ngc_pfy1,
       give.ngc_pfy2,
       give.ngc_pfy3,
       give.ngc_pfy4,
       give.ngc_pfy5,     
       e.preferred_address_city,
       e.preferred_address_state,
       e.preferred_address_country,
       tp.constituent_university_overall_rating,
       tp.constituent_research_evaluation,
       assign.prospect_manager_name,
       assign.lagm_name,
       l.linkedin_address,      
       sh.no_contact
from mv_entity e
--- ksm degree information - KSM alumni
inner join mv_entity_ksm_degrees d on d.donor_id = e.donor_id
--- industry in Banking 
inner join Bank on Bank.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
--- linkedin
left join l on l.ucinn_ascendv2__donor_id__c = e.donor_id
--- special handling
left join sh on sh.donor_id = e.donor_id
--- Eval Rating
left join tp on tp.CONSTITUENT_DONOR_ID = e.donor_id
--- assign
left join assign on assign.donor_id = e.donor_id
--- Giving 
left join give on give.household_id = e.household_id 
where 
--- Remove deceased records
e.is_deceased_indicator = 'N'
---- Take out No Contacts
and (sh.no_contact is null)
--- FT, EMBA, E&W
and d.program IN ('TMP','EMP','FT')
order by bank.primary_job_title asc
