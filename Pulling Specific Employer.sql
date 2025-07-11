--- linkedin ((No Idea how to Join))

with a as (select
stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__contact__c,
max (stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__url__c) keep (dense_rank first order by stg_alumni.ucinn_ascendv2__social_media__c.lastmodifieddate) as Linkedin_address
from stg_alumni.ucinn_ascendv2__social_media__c
where stg_alumni.ucinn_ascendv2__social_media__c.ap_status__c like '%Current%'
and stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__platform__c = 'LinkedIn'
group BY stg_alumni.ucinn_ascendv2__social_media__c.ucinn_ascendv2__contact__c
),

-- max(linkedin_url) keep dense_rank first ...

l as (select distinct c.ucinn_ascendv2__donor_id__c,
c.ucinn_ascendv2__first_and_last_name_formula__c,
a.linkedin_address
from stg_alumni.contact c
inner join a on c.id = a.ucinn_ascendv2__contact__c),

--- employment - primary

employ as (select distinct
c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C,

max (c.ap_is_primary_employment__c) keep (dense_rank First Order by c.ucinn_ascendv2__start_date__c desc) as primary_employ_ind,

max (c.ucinn_ascendv2__job_title__c) keep (dense_rank first order by c.ucinn_ascendv2__start_date__c desc) as primary_job_title,

max (c.UCINN_ASCENDV2__RELATED_ACCOUNT_NAME_FORMULA__C) keep (dense_rank first order by c.ucinn_ascendv2__start_date__c desc) as primary_employer

from stg_alumni.ucinn_ascendv2__Affiliation__c c

where c.ap_is_primary_employment__c = 'true'

group by c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C)


select distinct
       e.donor_id,
       e.sort_name,
       e.primary_record_type,
       e.institutional_suffix,
       d.first_ksm_year,
       d.program,
       d.program_group,
       employ.primary_employer,
       employ.primary_job_title,
       l.linkedin_address,
       e.preferred_address_type,
       e.preferred_address_city,
       e.preferred_address_state
       from mv_entity e
--- kellogg alumni
left join mv_entity_ksm_degrees d on d.donor_id = e.donor_id
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
left join l on l.ucinn_ascendv2__donor_id__c = e.donor_id
where (e.primary_record_type = 'Alum'
--- Enter Employer Below: 
--- and employ.primary_employer like '%%')
order by e.sort_name asc
