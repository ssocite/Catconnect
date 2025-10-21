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

--- Banking, but pulling on industry and industry subsectors

B as (select distinct
 co.constituent_donor_id,
 co.industry_subsectors,
 co.industries
from DM_ALUMNI.Dim_Constituent co
where co.industries like '%Finance and Insurance%'
or co.industry_subsectors like '%Funds, Trusts, and Other Financial Vehicles%'
or co.industry_subsectors like '%Investment Advice%'
or co.industry_subsectors like '%Investment Banking and Securities Dealing%'),

--- Banking - Final Employment

Bank as (select employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C,
employ.primary_job_title,
employ.primary_employer,
B.industry_subsectors,
b.industries
from employ
inner join B on
B.constituent_donor_id = UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C),


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
from stg_alumni.contact c),

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
--- Louisville Geocode
and g.ap_geocode_value_description__c like '%Chicago%'),

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
       Bank.industry_subsectors,
       bank.industries,
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
--- Bank (""Investment/Wealth Management"")
inner join bank on bank.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
--- Chicago
inner join fa on fa.ucinn_ascendv2__donor_id__c = e.donor_id
 --- ksm degree information
inner join mv_entity_ksm_degrees d on d.donor_id = e.donor_id
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
where sh.no_contact is null
and d.program not like '%Student%'
order by e.sort_name asc
