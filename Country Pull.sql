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

intr as (select distinct
 c.ucinn_ascendv2__donor_id__c,
Listagg (c.ap_industry_sectors__c, ';  ') Within Group (Order By c.ap_industry_sectors__c) As ap_industry_sectors__c,
Listagg (c.ap_industry_subsectors__c, ';  ') Within Group (Order By c.ap_industry_subsectors__c) As ap_industry_subsectors__c
from stg_alumni.contact c
group by c.ucinn_ascendv2__donor_id__c
),

--- Employment or Interest in 'Media'

interest as (
 select distinct
 c.ucinn_ascendv2__donor_id__c,
Listagg (c.ap_industry_subsectors__c, ';  ') Within Group (Order By c.ap_industry_subsectors__c) As ap_industry_subsectors__c

from stg_alumni.contact c
--- Employed in The industry sectors
where
---- Industry sub sectors - This is bascially ""interest""
 (c.ap_industry_subsectors__c like '%Advertising%'
or c.ap_industry_subsectors__c like '%Broadcasting (except Internet)%'
or c.ap_industry_subsectors__c like '%Media and Telecommunications%'
or c.ap_industry_subsectors__c like '%Mobile Gaming Apps%'
or c.ap_industry_subsectors__c like '%Motion Picture and Sound Recording Industries%'
or c.ap_industry_subsectors__c like '%Motion Picture and Video Industries%'
or c.ap_industry_subsectors__c like '%Motion Picture and Video Production%'
or c.ap_industry_subsectors__c like '%Newspaper Publishers%'
or c.ap_industry_subsectors__c like '%Online Audio and Video Media%'
or c.ap_industry_subsectors__c like '%Performing Arts Companies%'
or c.ap_industry_subsectors__c like '%Performing Arts%'
or c.ap_industry_subsectors__c like '%Publishing Industries (except Internet)%'
or c.ap_industry_subsectors__c like '%Radio and Television Broadcasting%'
or c.ap_industry_subsectors__c like '%Telecommunications%')
group by c.ucinn_ascendv2__donor_id__c

),






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
       e.sort_name,
       e.primary_record_type,
       e.institutional_suffix,
       --e.spouse_donor_id,
       --e.spouse_name,
       e.preferred_address_city,
       e.preferred_address_country,
       d.first_ksm_year,
       d.program,
       d.program_group,
      /* tp.constituent_university_overall_rating,
       tp.constituent_research_evaluation,
       give.ngc_lifetime,
       give.ngc_cfy,
       give.ngc_pfy1,
       give.ngc_pfy2,
       give.ngc_pfy3,
       give.ngc_pfy4,
       give.ngc_pfy5, */
       employ.primary_employer,
       employ.primary_job_title,
       intr.ap_industry_sectors__c,
       intr.ap_industry_subsectors__c,
       interest.ap_industry_subsectors__c as industry_subsectors_media_flag,
       l.linkedin_address,
       sh.no_contact,
       sh.no_email_ind
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
left join give on give.household_id = e.donor_id
--- intr as
left join intr on intr.ucinn_ascendv2__donor_id__c = e.donor_id
--- interest media
left join interest on interest.ucinn_ascendv2__donor_id__c = e.donor_id
where
--- Remove deceased records
 e.is_deceased_indicator = 'N'
--- Alum
and e.primary_record_type = 'Alum'
--- Chile
and e.preferred_address_country = 'Chile'
---- Take out No Contacts
and (sh.no_contact is null)
order by e.sort_name asc
