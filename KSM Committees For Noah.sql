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


--- AMP

amp as (Select *
From v_committee_amp),

--- Tech

tech as (Select *
From v_committee_tech),

--- healthcare at Kellogg

health as (Select *
From v_committee_healthcare),

--- email

email as (select  c.ucinn_ascendv2__donor_id__c,
c.email
from stg_alumni.contact c),

--- Special Handling

SH as (select  s.donor_id,
       s.no_contact,
       s.no_email_ind
from mv_special_handling s),

--- most recent gift

give as (select g.household_id,
g.household_primary_donor_id,
       g.ngc_lifetime,
       g.ngc_cfy,
       g.ngc_pfy1,
       g.ngc_pfy2,
       g.ngc_pfy3,
       g.ngc_pfy4,
       g.ngc_pfy5,
       g.ngc_fy_giving_first_yr,
       g.ngc_fy_giving_last_yr,
       g.last_ngc_tx_id,
       g.last_ngc_date,
       g.last_ngc_opportunity_type,
       g.last_ngc_designation_id,
       g.last_ngc_designation,
       g.last_ngc_recognition_credit
from mv_ksm_giving_summary g)


select distinct
e.donor_id,
dm.salutation,
e.sort_name,
e.institutional_suffix,
gab.involvement_name as gab_ind,
asia.involvement_name as asia_ind,
yab.involvement_name as yab_ind,
kac.involvement_name as kac_ind,
peac.involvement_name as peac_ind,
pasia.involvement_name as pasia_ind,
health.involvement_name as healthcare_ind,
amp.involvement_name as amp_ind,
tech.involvement_name as tech_ind,
give.ngc_fy_giving_first_yr,
give.ngc_fy_giving_last_yr,
give.last_ngc_tx_id,
give.last_ngc_date,
give.last_ngc_designation,
give.last_ngc_recognition_credit,
email.email,
sh.no_contact,
sh.no_email_ind

from e
left join DM_ALUMNI.DIM_CONSTITUENT dm on dm.constituent_donor_id = e.donor_id
left join give on give.household_id = e.household_id
left join gab on gab.constituent_donor_id = e.donor_id
left join asia on asia.constituent_donor_id = e.donor_id
left join yab on asia.constituent_donor_id = e.donor_id
left join kac on kac.constituent_donor_id = e.donor_id
left join peac on peac.constituent_donor_id = e.donor_id
left join pasia on pasia.constituent_donor_id = e.donor_id
left join health on health.constituent_donor_id = e.donor_id
left join amp on amp.constituent_donor_id = e.donor_id
left join tech on tech.constituent_donor_id = e.donor_id
left join email on email.ucinn_ascendv2__donor_id__c = e.donor_id
left join sh on sh.donor_id = e.donor_id

where

(gab.constituent_donor_id is not null or
asia.constituent_donor_id is not null or
kac.constituent_donor_id  is not null or
peac.constituent_donor_id  is not null or
pasia.constituent_donor_id is not null or
health.constituent_donor_id is not null or
amp.constituent_donor_id is not null or
tech.constituent_donor_id is not null)

order by e.sort_name asc
