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

--- Employment with Senior Titles

final_employment as (select
employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C,
employ.primary_job_title,
employ.primary_employer
from employ
where   (primary_job_title like '%Vice President%'
or primary_job_title like '%VP%'
or primary_job_title like '%Managing Director%'
or primary_job_title like '%Partner%'
or primary_job_title like '%Senior Asset Manager%'
or primary_job_title like '%Chief%')),

--- Trying to find folks working in real estate
RE as (select distinct
c.constituent_donor_id,
c.INDUSTRIES
from DM_ALUMNI.Dim_Constituent c
where c.industries like '%Real Estate%'),

---- Folks Employed in Real Estate

Ree as (select employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C,
employ.primary_employ_ind,
employ.primary_job_title,
employ.primary_employer
from employ
inner join re on
re.constituent_donor_id = UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C),

--- Special Handling --- Remove No Contacts

SH as (select  s.donor_id,
       s.no_contact
from mv_special_handling s),

--- Email

email as (select  c.ucinn_ascendv2__donor_id__c,
c.email
from stg_alumni.contact c),

--- Top Prospect

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

--- Pull folks from Kellogg Real Estate Network

KREAN as (select *
from mv_involvement
where mv_involvement.involvement_name = 'Kellogg Real Estate Alumni Network'),

--- Kellogg Advisory Board

rc as (Select *
From v_committee_realestcouncil),


i as (select distinct c.constituent_donor_id,
c.industries
from DM_ALUMNI.Dim_Constituent c)

select distinct
       e.donor_id,
       e.sort_name,
       e.primary_record_type,
       e.institutional_suffix,
       d.first_ksm_year,
       d.program,
       d.program_group,
       final_employment.primary_employer,
       final_employment.primary_job_title,
       case when Ree.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C is not null then 'Employed in Real Estate' end as RE_Employed,
       i.industries,
       KREAN.involvement_name as KREAN_IND,
       case when rc.constituent_donor_id is not null then rc.involvement_name end as real_estate_advisory_council, 
       e.preferred_address_city,
       e.preferred_address_state,
       e.preferred_address_country,
       d.first_ksm_year,
       tp.constituent_university_overall_rating,
       tp.constituent_research_evaluation,
       l.linkedin_address,
       assign.prospect_manager_name,
       assign.lagm_name,
       sh.no_contact
from mv_entity e
--- Working in Real Estate (We will create a flag)
left join re on re.CONSTITUENT_DONOR_ID = e.donor_id
--- ksm degree information - KSM alumni
inner join mv_entity_ksm_degrees d on d.donor_id = e.donor_id
--- empoloyment
left join final_employment on final_employment.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
--- linkedin
left join l on l.ucinn_ascendv2__donor_id__c = e.donor_id
--- email
left join email on email.ucinn_ascendv2__donor_id__c = e.donor_id
--- special handling
left join sh on sh.donor_id = e.donor_id
--- Eval Rating
left join tp on tp.CONSTITUENT_DONOR_ID = e.donor_id
--- assign
left join assign on assign.donor_id = e.donor_id
--- industry
left join i on i.constituent_donor_id = e.donor_id
--- Involvement
left join KREAN on KREAN.constituent_donor_id = e.donor_id
--- industry in real estate
left join Ree on Ree.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
---- real estate advisory board
left join rc on rc.constituent_donor_id = e.donor_id



where --- Remove deceased records
e.is_deceased_indicator = 'N'
--- Alumni
and e.primary_record_type = 'Alum'
---- Take out No Contacts
and (sh.no_contact is null)

and final_employment.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C is not null

and
(Ree.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C is not null

or KREAN.constituent_donor_id is not null

or rc.constituent_donor_id is not null 
)

and d.program_group IN ('FT','TMP','EMP')

order by e.sort_name asc
