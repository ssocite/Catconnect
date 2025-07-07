--- Current Linkedin Addresses
with a as (select
stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__contact__c,
max (stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__url__c) keep (dense_rank first order by stg_alumni.ucinn_ascendv2__social_media__c.lastmodifieddate) as Linkedin_address
from stg_alumni.ucinn_ascendv2__social_media__c
where stg_alumni.ucinn_ascendv2__social_media__c.ap_status__c like '%Current%'
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
       s.no_email_ind,
       s.no_mail_ind
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
       g.ngc_fy_giving_first_yr,
       g.ngc_fy_giving_last_yr,
       g.cash_fy_giving_first_yr,
       g.cash_fy_giving_last_yr,
       g.last_cash_tx_id,
       g.last_cash_date,
       g.last_cash_opportunity_type,
       g.last_cash_designation_id,
       g.last_cash_designation,
       g.last_cash_recognition_credit,
       g.cash_giving_first_credit_dt
from mv_ksm_giving_summary g
),

--- Assignment

assign as (Select a.household_id,
       a.donor_id,
       a.sort_name,
       a.prospect_manager_name,
       a.lagm_user_id,
       a.lagm_name
From mv_assignments a)

select distinct
       e.donor_id,
       e.sort_name,
       e.institutional_suffix,
       d.first_ksm_year,
       d.program,
       d.program_group,
       ---e.primary_record_type,
       --e.spouse_donor_id,
       --e.spouse_name,
       e.preferred_address_status,
       e.preferred_address_type,
       e.preferred_address_line_1,
       ---e.preferred_address_line_2,
       e.preferred_address_city,
       e.preferred_address_state,
       e.preferred_address_postal_code,
       e.preferred_address_country,
       ---d.first_ksm_year,
       ---give.ngc_fy_giving_first_yr,
       give.cash_fy_giving_first_yr,
       give.cash_giving_first_credit_dt,
       ---give.ngc_lifetime,
       /*give.ngc_cfy,
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
       give.last_ngc_recognition_credit,*/
       give.last_cash_tx_id,
       give.last_cash_date,
       give.last_cash_opportunity_type,
       give.last_cash_designation,
       give.last_cash_recognition_credit,
       employ.primary_employer,
       employ.primary_job_title,
       l.linkedin_address,
       assign.prospect_manager_name,
       assign.lagm_name,
       tp.constituent_university_overall_rating,
       tp.constituent_research_evaluation,
       sh.no_contact,
       sh.no_mail_ind
from mv_entity e
--- ksm degree information
inner join mv_entity_ksm_degrees d on d.donor_id = e.donor_id
--- give
inner join give on give.household_primary_donor_id = e.donor_id
--- empoloyment
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
--- linkedin
left join l on l.ucinn_ascendv2__donor_id__c = e.donor_id
--- special handling
left join sh on sh.donor_id = e.donor_id
--- Eval Rating
left join tp on tp.CONSTITUENT_DONOR_ID = e.donor_id
--- assign
left join assign on assign.donor_id = e.donor_id

where e.is_deceased_indicator = 'N'

--- class year
and (d.first_ksm_year IN ('2008','2009','2010','2011','2012','2013','2014',
'2015','2016','2017','2018','2019','2020','2021','2022','2023','2024','2025')

--- No EMBA International, Only Domestic Alumni too

and (d.program NOT IN ('EMP-CAN','EMP-CHI','EMP-GER','EMP-HK','EMP-ISR')
and e.preferred_address_country = 'United States'))

---- Take out No Contacts
and (sh.no_contact is null)

--- they want gifts march 1st until now
and give.cash_giving_first_credit_dt >= to_date ('03/01/2025', 'mm/dd/yyyy')

order by  give.last_cash_date desc
