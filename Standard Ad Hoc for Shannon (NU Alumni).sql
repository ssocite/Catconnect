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
group by c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C),

--- Geocodes

geocode as (select distinct g.ap_address_relation_record_type__c,
                        g.ap_address_relation__c,
                        g.ap_constituent__c,
                        g.ap_geocode_value_description__c,
                        g.ap_is_active__c,
                        g.ap_is_constituent_address_relation__c,
                        g.geocode_value_type_description__c,
                        g.id
from stg_alumni.ap_geocode__c g
--- Active Geocode
where g.ap_is_active__c = 'true'
--- Louisville Geocode
and g.ap_geocode_value_description__c like '%Louisville%'
--- Club Geocode
and g.ap_geocode_value__c like '%aAMUz000000Dkc7OAC%'
),

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
where a.ucinn_ascendv2__is_preferred__c = 'true'),

--- Special Handling

SH as (select  s.donor_id,
       s.no_contact,
       s.no_email_ind
from mv_special_handling s)

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
       fa.ap_geocode_value_description__c,
       sh.no_contact,
       sh.no_email_ind
from mv_entity e
--- address (current address in given club geocode)
inner join fa on fa.ucinn_ascendv2__donor_id__c = e.donor_id
--- ksm degree information
left join mv_entity_ksm_degrees d on d.donor_id = e.donor_id
--- empoloyment
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = e.donor_id
--- linkedin
left join l on l.ucinn_ascendv2__donor_id__c = e.donor_id
--- special handling
left join sh on sh.donor_id = e.donor_id
where
--- We want NU Alumni
e.primary_record_type = 'Alum'
--- Remove deceased records
and e.is_deceased_indicator = 'N'
---- Take out No Contacts and No Email
and (sh.no_contact is null
and sh.no_email_ind is null)
order by e.sort_name asc
