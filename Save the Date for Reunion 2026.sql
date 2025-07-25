With manual_dates As (
Select
  2025 AS pfy
  ,2026 AS cfy
  From DUAL
),

-- Base of Degrees

KSM_Degrees as (Select d.donor_id,
case when d.program = 'FT-MS' and d.first_ksm_year IN ('2024','2025')
  then 'MiM' else d.program end as program, 
d.program_group,
d.first_ksm_year,
d.first_masters_year,
d.last_masters_year,
d.degrees_verbose,
d.last_noncert_year,
d.class_section
From mv_entity_ksm_degrees d
),

--- Pull Kellogg Reunion Year - Exclude Certificates AND Doctorates 

d as (select c.id,
       c.ucinn_ascendv2__contact__c,
       c.ucinn_ascendv2__reunion_year__c,
       c.ap_school_reunion_year__c
from stg_alumni.ucinn_ascendv2__degree_information__c c
where c.ap_school_reunion_year__c like '%Kellogg%'
and c.ap_degree_type_from_degreecode__c Not In ('Certificate', 'Doctorate Degree')
),

--- Reunion Year
--- This is to get donor IDs that tie to the degree table

reunion_year as (select a.ucinn_ascendv2__donor_id__c,
a.firstname,
a.lastname,
d.ucinn_ascendv2__reunion_year__c,
KD.program,
KD.program_group,
KD.first_ksm_year,
KD.first_masters_year,
KD.last_masters_year,
KD.degrees_verbose,
KD.last_noncert_year,
KD.class_section
from stg_alumni.contact a
CROSS JOIN manual_dates MD
inner join d on d.ucinn_ascendv2__contact__c = a.id
inner join KSM_Degrees KD on KD.donor_id = a.ucinn_ascendv2__donor_id__c

--- Years adjusted to first query
--- This project just wants 5th - 50th Milestones

where (TO_NUMBER(NVL(TRIM(d.ucinn_ascendv2__reunion_year__c),'1'))) IN (--- Just 5th - 50th
MD.CFY-5, MD.CFY-10, MD.CFY-15, MD.CFY-20,
MD.CFY-25, MD.CFY-30, MD.CFY-35, MD.CFY-40,
MD.CFY-45, MD.CFY-50)

/* We will invite Full time, E&W, TMP (Part time),PHDs
JDMBA, MMM, MBAi, Business Undergrad (old program)*/

AND KD.PROGRAM IN (
--- All EMBA
 'EMP', 'EMP-FL', 'EMP-IL', 'EMP-CAN', 'EMP-GER', 'EMP-HK', 'EMP-ISR', 'EMP-JAN', 'EMP-CHI',
--- No PHDs for the Save the Date Project
--- Full Time
 'FT', 'FT-1Y', 'FT-2Y', 'FT-JDMBA', 'FT-MMGT', 'FT-MMM',
--- Include MSMS (AKA MiM) and MBAi
 'FT-MS', 'FT-MBAi',
---- The old Undergrad programs - should be 50+ milestone Now
 'FT-CB', 'FT-EB',
 --- Evening and Weekend
 'TMP', 'TMP-SAT','TMP-SATXCEL', 'TMP-XCEL')),

--- listag reunion
-- Some have more than 2 preferred KSM Reunions

l as (select reunion_year.ucinn_ascendv2__donor_id__c,
Listagg (distinct reunion_year.ucinn_ascendv2__reunion_year__c, ';  ')
Within Group (Order By reunion_year.ucinn_ascendv2__reunion_year__c) As reunion_year_concat
from reunion_year
group by reunion_year.ucinn_ascendv2__donor_id__c
),

--- Final Reunion Subquery

k as (select l.ucinn_ascendv2__donor_id__c,
l.reunion_year_concat,
reunion_year.first_ksm_year,
reunion_year.program,
reunion_year.program_group,
reunion_year.class_section,
reunion_year.first_masters_year,
reunion_year.last_masters_year,
reunion_year.last_noncert_year,
reunion_year.degrees_verbose
from l
inner join KSM_Degrees on KSM_Degrees.donor_id = l.ucinn_ascendv2__donor_id__c
inner join reunion_year on reunion_year.ucinn_ascendv2__donor_id__c = l.ucinn_ascendv2__donor_id__c),

--- Spouse Reunion Year  - KELLOGG ONLY!

spr as (select en.spouse_donor_id,
en.spouse_name,
en.spouse_institutional_suffix,
--- This should be Reunion for Spouses 
k.reunion_year_concat
from mv_entity en
inner join k on k.ucinn_ascendv2__donor_id__c = en.spouse_donor_id
inner join KSM_Degrees on KSM_Degrees.donor_id = en.spouse_donor_id

),

-- GAB

GAB as (Select *
From v_committee_gab),

--- KAC

kac as (select *
from v_committee_kac),

--- PHS

phs as (select *
from v_committee_phs),

--- Trustee

trustee as (Select *
From v_committee_trustee),

--- Final Reunion

FR AS (
select entity.donor_id,
entity.first_name,
entity.last_name,
entity.institutional_suffix,
l.reunion_year_concat,
entity.preferred_address_status,
entity.preferred_address_type,
entity.preferred_address_line_1,
entity.preferred_address_line_2,
entity.preferred_address_line_3,
entity.preferred_address_city,
entity.preferred_address_state,
entity.preferred_address_postal_code,
entity.preferred_address_country
from mv_entity entity
inner join l on l.ucinn_ascendv2__donor_id__c = entity.donor_id
--- Pulling JUST on the Programs for Reunion
inner join k on k.ucinn_ascendv2__donor_id__c = entity.donor_id
--- Projects just wants domestic alumni
where entity.preferred_address_country like '%United States%'
or entity.preferred_address_country In ('USA', 'UNITED STATES', 'US')

),

--- employment
employ as (select distinct
c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C,
max (c.ap_is_primary_employment__c) keep (dense_rank First Order by c.ucinn_ascendv2__start_date__c desc) as primary_employ_ind,
max (c.ucinn_ascendv2__is_retiree__c) keep (dense_rank First Order by c.ucinn_ascendv2__start_date__c desc) as retiree,
max (c.ucinn_ascendv2__status__c) keep (dense_rank First Order by c.ucinn_ascendv2__start_date__c desc) as job_status,
max (c.ucinn_ascendv2__job_title__c) keep (dense_rank first order by c.ucinn_ascendv2__start_date__c desc) as primary_job_title,
max (c.UCINN_ASCENDV2__RELATED_ACCOUNT_NAME_FORMULA__C) keep (dense_rank first order by c.ucinn_ascendv2__start_date__c desc) as primary_employer
from stg_alumni.ucinn_ascendv2__Affiliation__c c
where c.ap_is_primary_employment__c = 'true'
group by c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C),

--- Current Linkedin Addresses
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

linked as (select distinct c.ucinn_ascendv2__donor_id__c,
c.ucinn_ascendv2__first_and_last_name_formula__c,
a.linkedin_address
from stg_alumni.contact c
inner join a on c.id = a.ucinn_ascendv2__contact__c),

SH as (select  s.donor_id,
       s.no_contact,
       s.no_phone_ind,
       s.no_mail_ind,
       s.no_email_ind,
       s.never_engaged_forever,
       s.never_engaged_reunion
from mv_special_handling s),

--- email

email as (select  c.ucinn_ascendv2__donor_id__c,
c.email
from stg_alumni.contact c),

--- contact

phone as (select c.ucinn_ascendv2__donor_id__c,
c.phone
from stg_alumni.contact c),


--- 2016 Reunion Attendees

r16 as (SELECT r16.id_number
FROM ksm_2016_reunion r16),

--- 2022 Reunion Attendees

r22 as (SELECT r22.id_number
FROM ksm_2022_weekend1_reunion r22),

--- Preferred Mail Name - From Amy
MN as (SELECT ME.DONOR_ID,
INDNAMESAL.UCINN_ASCENDV2__CONSTRUCTED_NAME_FORMULA__C as preferred_mail_name
FROM stg_alumni.ucinn_ascendv2__contact_name__c  INDNAMESAL
Inner Join mv_entity ME
ON ME.SALESFORCE_ID = INDNAMESAL.UCINN_ASCENDV2__CONTACT__C
AND INDNAMESAL.ucinn_ascendv2__type__c = 'Full Name'),


Salutation as (Select
        mv_entity.donor_id
      , stgc.UCINN_ASCENDV2__SALUTATION_TYPE__c As Salutation_Type
      , stgc.ucinn_ascendv2__salutation_record_type_formula__c As Ind_or_Joint
      , stgc.ucinn_ascendv2__inside_salutation__c As Salutation
      , stgc.lastmodifieddate
      , stgc.ucinn_ascendv2__author_title__c As Sal_Author
      , stgc.isdeleted
From stg_alumni.ucinn_ascendv2__salutation__c stgc
Left Join mv_entity
     On mv_entity.salesforce_id = stgc.ucinn_ascendv2__contact__c
Where  stgc.isdeleted = 'false'
And stgc.ucinn_ascendv2__salutation_record_type_formula__c = 'Joint'
--- formal 
and stgc.UCINN_ASCENDV2__SALUTATION_TYPE__c = 'Formal'
)


select distinct FR.donor_id,
en.household_primary,
FR.first_name,
FR.last_name,
en.spouse_donor_id,
en.spouse_name,
en.spouse_institutional_suffix,
--- Salutation
case when spr.reunion_year_concat is not null then salutation.salutation end as joint_salutation,
case when spr.reunion_year_concat is not null then salutation.Salutation_Type end as joint_salutation_type,
case when spr.reunion_year_concat is not null then salutation.Ind_or_Joint end as ind_joint,  
spr.reunion_year_concat as spouse_ksm_reunion_year,
MN.preferred_mail_name,
FR.institutional_suffix,
FR.reunion_year_concat as reunion_year_concat,
k.first_masters_year,
k.last_masters_year,
---k.last_noncert_year,
--- There are a very small handful of folks with 2 Reunions
--- I ordered this by most recent. Assuming their most recent is their highest level of education
case
when FR.reunion_year_concat like '%2021%' then '5th'
when FR.reunion_year_concat like '%2016%' then '10th'
when FR.reunion_year_concat like '%2011%' then '15th'
when FR.reunion_year_concat like '%2006%' then '20th'
when FR.reunion_year_concat like '%2001%' then '25th'
when FR.reunion_year_concat like '%1996%' then '30th'
when FR.reunion_year_concat like '%1991%' then '35th'
when FR.reunion_year_concat like '%1986%' then '40th'
when FR.reunion_year_concat like '%1981%' then '45th'
when FR.reunion_year_concat like '%1976%' then '50th'
end as reunion_milestone_celebrating,
-- Past Reunion Flags
case when r16.id_number is not null then 'Reunion 2016 Attendee' end as Reunion_16_Attendee,
case when r22.id_number is not null then 'Reunion 2022 Attendee' end as Reunion_22_Attendee,
k.program,
k.program_group,
employ.job_status,
case when employ.primary_employer like '%Retired%'
  or employ.primary_job_title like '%Retired%'
  or employ.retiree like '%True%'
  then 'Retired' end as retired,
employ.primary_employer,
employ.primary_job_title,

--- Contact Information

--- Use Special handling of No Contact/No email or phone to mask anyone with those flags
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_status end as preferred_address_status,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_type end as preferred_address_type,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_line_1 end as preferred_address_line1,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_line_2 end as preferred_address_line2,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_line_3 end as preferred_address_line3,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_city end as preferred_address_city,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_state end as preferred_address_state,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_postal_code end as preferred_postal_code,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_country end as preferred_country,
--- Email Address
case when sh.no_contact is null and sh.no_email_ind is null
then email.email end as preferred_email_address,
--- Phone
case when sh.no_phone_ind is null and  sh.no_contact is null then
phone.phone end as preferred_phone,
--- Special Handling Flags
sh.no_contact,
sh.no_mail_ind,
sh.no_email_ind
from FR
--- entity
inner join mv_entity en on en.donor_id = fr.donor_id
--- degrees
inner join k on k.ucinn_ascendv2__donor_id__c = fr.donor_id
--- Salutation 
left join Salutation on Salutation.donor_id = fr.donor_id
--- employment
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = fr.donor_id
--- linkedin
left join linked on linked.ucinn_ascendv2__donor_id__c = employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C
--- Special handling
left join SH on SH.donor_id = fr.donor_id
--- email
left join email on email.ucinn_ascendv2__donor_id__c = fr.donor_id
--- phone
left join phone on phone.ucinn_ascendv2__donor_id__c = fr.donor_id
--- KAC
left join kac on kac.constituent_donor_id = fr.donor_id
--- GAB
left join gab on gab.constituent_donor_id = fr.donor_id
--- trustee
left join trustee on trustee.constituent_donor_id = fr.donor_id
--- PHS
left join phs on phs.constituent_donor_id = fr.donor_id
--- 2016 Reunion Attendees
left join r16 on r16.id_number = fr.donor_id
--- 2022 Reunion Attendees
left join r22 on r22.id_number = fr.donor_id
--- Preferred Mail Name
left join MN on MN.DONOR_ID = fr.donor_id 
--- spouse reunion year 
left join spr on spr.spouse_donor_id = en.spouse_donor_id 
where
--- Primary Household!
en.household_primary = 'Y'
--- Alumni are living
and en.is_deceased_indicator = 'N'
--- exclude kac, gab, trustees, phs
and (kac.constituent_donor_id is null
and gab.constituent_donor_id is null
and trustee.constituent_donor_id is null
and phs.constituent_donor_id is null)
--- AND exclude no contact, never engaged forever, never engaged reunion, no mail
and  (sh.no_contact is null
and  sh.never_engaged_forever is null
and sh.never_engaged_reunion is null
and sh.no_mail_ind is null)
--- No Faculty or Staff
and FR.institutional_suffix not like '%Faculty/Staff%'
order by reunion_year_concat ASC