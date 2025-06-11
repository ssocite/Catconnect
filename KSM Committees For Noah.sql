with e as (select *
from  mv_entity),

-- GAB


GAB as (Select *
From v_committee_gab),

--- EBfa

asia as (select *
from v_committee_asia),

--- YAB

yab as (select *
from v_committee_yab),

--- KAC

kac as (select *
from v_committee_kac),

--- PEAC

peac as (select *
from v_committee_privateequity),

--- PEAC Asia

pasia as (Select *
From v_committee_pe_asia),

mbai as (

-- MBAi
Select *
From v_committee_mbai),

--- AMP

amp as (Select *
From v_committee_amp),

--- Tech

tech as (Select *
From v_committee_tech),

--- Volunteer Form - Confidentialty Agreement

v as (Select c.ucinn_ascendv2__donor_id__c,
c.ap_is_volunteer__c
From stg_alumni.contact c
where c.ap_is_volunteer__c = 'true')

select distinct
e.donor_id,
e.sort_name,
e.institutional_suffix,
gab.involvement_name as gab_ind,
asia.involvement_name as asia_ind,
yab.involvement_name as yab_ind,
kac.involvement_name as kac_ind,
peac.involvement_name as peac_ind,
pasia.involvement_name as pasia_ind,
mbai.involvement_name as mbai_ind,
amp.involvement_name as amp_ind,
tech.involvement_name as tech_ind,
v.ap_is_volunteer__c

from e
left join v on v.ucinn_ascendv2__donor_id__c = e.donor_id
left join gab on gab.constituent_donor_id = e.donor_id
left join asia on asia.constituent_donor_id = e.donor_id
left join yab on asia.constituent_donor_id = e.donor_id
left join kac on kac.constituent_donor_id = e.donor_id
left join peac on peac.constituent_donor_id = e.donor_id
left join pasia on pasia.constituent_donor_id = e.donor_id
left join mbai on mbai.constituent_donor_id = e.donor_id
left join amp on amp.constituent_donor_id = e.donor_id
left join tech on tech.constituent_donor_id = e.donor_id

where

(gab.constituent_donor_id is not null or
asia.constituent_donor_id is not null or
kac.constituent_donor_id  is not null or
peac.constituent_donor_id  is not null or
pasia.constituent_donor_id is not null or
mbai.constituent_donor_id is not null or
amp.constituent_donor_id is not null or
tech.constituent_donor_id is not null)

order by e.sort_name asc
