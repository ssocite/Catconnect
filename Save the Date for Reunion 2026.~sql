--- KSM Degree and Reunion Year

with d as (select c.id,
       c.ucinn_ascendv2__contact__c,
       c.ucinn_ascendv2__reunion_year__c,
       c.ap_school_reunion_year__c
from stg_alumni.ucinn_ascendv2__degree_information__c c
where c.ap_school_reunion_year__c like '%Kellogg%'
),

--- Reunion Year

reunion as (select a.ucinn_ascendv2__donor_id__c,
a.firstname,
a.lastname,
d.ucinn_ascendv2__reunion_year__c
---d.ucinn_ascendv2__reunion_year__c
from stg_alumni.contact a
inner join d on d.ucinn_ascendv2__contact__c =
a.id),

--- listag reunion

l as (select reunion.ucinn_ascendv2__donor_id__c,
Listagg (reunion.ucinn_ascendv2__reunion_year__c, ';  ') Within Group (Order By reunion.ucinn_ascendv2__reunion_year__c)
As reunion_year_concat
from reunion
group by reunion.ucinn_ascendv2__donor_id__c
),

--- Just Full Time, EMBA and Evening and Weekend

k as (Select d.donor_id,
d.program,
d.program_group,
d.first_ksm_year
From mv_entity_ksm_degrees d
where d.program_GROUP IN ('FT','EMP','TMP')

),

-- GAB

GAB as (Select *
From v_committee_gab),

--- KAC

kac as (select *
from v_committee_kac),

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
entity.preferred_address_city,
entity.preferred_address_state,
entity.preferred_address_postal_code,
entity.preferred_address_country
from mv_entity entity
inner join l on l.ucinn_ascendv2__donor_id__c = entity.donor_id
inner join k on k.donor_id = entity.donor_id
where
--- don't want 2025, but do want 1's and 6's
(l.reunion_year_concat like '%2021%'
or l.reunion_year_concat like '%2016%'
or l.reunion_year_concat like '%2011%'
or l.reunion_year_concat like '%2006%'
or l.reunion_year_concat like '%2001%'
or l.reunion_year_concat like '%1996%'
or l.reunion_year_concat like '%1991%'
or l.reunion_year_concat like '%1986%'
or l.reunion_year_concat like '%1981%'
or l.reunion_year_concat like '%1976%')
and (entity.preferred_address_country like '%United States%')),

--- employment
employ as (select distinct
c.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C,
max (c.ap_is_primary_employment__c) keep (dense_rank First Order by c.ucinn_ascendv2__start_date__c desc) as primary_employ_ind,
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

--- Salutation 

salutation as (
select co.ucinn_ascendv2__donor_id__c,
co.salutation
from stg_alumni.contact co)

--- Query

select FR.donor_id,
en.household_primary,
--- Salutation 
salutation.salutation,
FR.first_name,
FR.last_name,
FR.institutional_suffix,
FR.reunion_year_concat as reunion_year_concat,
k.first_ksm_year,
case when FR.reunion_year_concat = '2021' then '5th Milestone'
  when FR.reunion_year_concat = '2016' then '10th Milestone'
  when FR.reunion_year_concat = '2011' then '15th Milestone'
  when FR.reunion_year_concat = '2006' then '20th Milestone'
  when FR.reunion_year_concat = '2001' then '25th Milestone'
  when FR.reunion_year_concat = '1996' then '25th Milestone'
  when FR.reunion_year_concat = '1991' then '30th Milestone'
  when FR.reunion_year_concat = '1986' then '35th Milestone'
  when FR.reunion_year_concat = '1981' then '40th Milestone'
  when FR.reunion_year_concat = '1976' then '45th Milestone'
  when FR.reunion_year_concat = '1971' then '50th Milestone'
    end as reunion_milestone,
k.program,
k.program_group,
employ.primary_employer,
employ.primary_job_title,

case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_status end as preferred_address_status,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_type end as preferred_address_type,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_line_1 end as preferred_address_line1,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_line_2 end as preferred_address_line2,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_city end as preferred_address_city,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_state end as preferred_address_state,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_postal_code end as preferred_postal_code,
case when sh.no_contact is null
and       sh.no_mail_ind is null then FR.preferred_address_country end as preferred_country,
case when sh.no_contact is null
and sh.no_email_ind is null
then email.email end as email_address,
phone.phone,
sh.no_contact,
sh.no_mail_ind,
sh.no_email_ind
from FR
--- entity
inner join mv_entity en on en.donor_id = fr.donor_id
--- degrees
inner join k on k.donor_id = FR.donor_id
--- Salutation 
inner join salutation on salutation.ucinn_ascendv2__donor_id__c = FR.donor_id
--- employment
left join employ on employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C = FR.donor_id
--- linkedin
left join linked on linked.ucinn_ascendv2__donor_id__c = employ.UCINN_ASCENDV2__RELATED_CONTACT_DONOR_ID_FORMULA__C
--- Special handling
left join SH on SH.donor_id = FR.donor_id
--- email
left join email on email.ucinn_ascendv2__donor_id__c = FR.donor_id
--- phone
left join phone on phone.ucinn_ascendv2__donor_id__c = FR.donor_id
--- KAC
left join kac on kac.constituent_donor_id = fr.donor_id
--- GAB
left join gab on gab.constituent_donor_id = fr.donor_id
--- trustee
left join trustee on trustee.constituent_donor_id = fr.donor_id
where (kac.constituent_donor_id is null
and gab.constituent_donor_id is null
and trustee.constituent_donor_id is null)
--- exclude no contact, never engaged forever, never engaged reunion, no mail
and  (sh.no_contact is null
and  sh.never_engaged_forever is null
and sh.never_engaged_reunion is null
and sh.no_mail_ind is null)
--- Primary Household!
and en.household_primary = 'Y'
and FR.reunion_year_concat is not null
order by reunion_year_concat ASC 
