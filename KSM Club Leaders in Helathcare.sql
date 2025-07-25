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

--- Healthcare, but pulling on industry and industry subsectors

B as (select distinct
 co.constituent_donor_id,
 co.industry_subsectors,
 co.industries
from DM_ALUMNI.Dim_Constituent co
where co.industry_subsectors IN ('Administration of Public Health Programs',
'Hospitals',
'Medical and Diagnostic Laboratories',
'Offices of All Other Miscellaneous Health Practitioners',
'Offices of Mental Health Practitioners (except Physicians)',
'Pharmacies and Drug Stores',
'Medical Equipment and Supplies Manufacturing',
'Pharmaceutical and Medicine Manufacturing')
or co.industries like '%Health Care and Social Assistance%'
),

--- Healthcare - Final Employment 

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
from mv_ksm_giving_summary g),

i as (select i.constituent_donor_id,
       i.constituent_name,
       i.involvement_record_id,
       i.involvement_code,
       i.involvement_name,
       i.involvement_status,
       i.involvement_type,
       i.involvement_role,
       i.involvement_business_unit,
       i.involvement_start_date,
       i.involvement_end_date,
       i.involvement_comment,
       i.etl_update_date,
       i.mv_last_refresh
from mv_involvement i),

--- clubs

club as (select i.constituent_donor_id,
       i.constituent_name,
       i.involvement_name,
       i.involvement_status,
       i.involvement_type,
       i.involvement_role,
       i.involvement_business_unit,
       i.involvement_start_date
from i
where (i.involvement_role IN ('Club Leader',
'President','President-Elect','Director',
'Secretary','Treasurer','Executive')
--- Current will suffice for the date
and i.involvement_status = 'Current'
and (i.involvement_name  like '%Kellogg%'
or i.involvement_name  like '%KSM%'))),

--- Listagging because someone could be multiple club leader

cl as (select club.constituent_donor_id,
        Listagg (club.involvement_name, ';  ') Within Group (Order By club.involvement_name) As involvement_name,
        Listagg (club.involvement_status, ';  ') Within Group (Order By club.involvement_status) As involvement_status,
        Listagg (club.involvement_type, ';  ') Within Group (Order By club.involvement_type) As involvement_type,
        Listagg (club.involvement_role, ';  ') Within Group (Order By club.involvement_role) As involvement_role
 from club
 group by club.constituent_donor_id)

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
       cl.involvement_name,
       cl.involvement_status,
       cl.involvement_type,
       cl.involvement_role,
       assign.prospect_manager_name,
       assign.lagm_name,
       l.linkedin_address,      
       sh.no_contact
from mv_entity e
--- ksm degree information - KSM alumni
inner join mv_entity_ksm_degrees d on d.donor_id = e.donor_id
--- industry in Healthcare 
inner join Bank on Bank.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
--- Needs to be a club leader
inner join cl on cl.constituent_donor_id = e.donor_id 
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
and d.program_Group IN ('TMP','EMP','FT')
order by bank.primary_job_title asc
