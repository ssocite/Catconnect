--- degrees

with d as (select *
 from mv_entity_ksm_degrees
where mv_entity_ksm_degrees.program not like '%STUDENT%'
),

--- Base alumni info

entity as (select *
from mv_entity),

--- Assign

assign as (Select a.household_id,
       a.donor_id,
       a.sort_name,
       a.prospect_manager_name,
       a.lagm_user_id,
       a.lagm_name
From mv_assignments a),

--- Top Prospect

TP as (select C.CONSTITUENT_DONOR_ID,
c.constituent_university_overall_rating,
c.constituent_research_evaluation
from DM_ALUMNI.DIM_CONSTITUENT C ),

--- gab

gab as (select *
from v_committee_gab),

--- Trustee

trustee as (select *
from v_committee_trustee),

--- Exec Board for Asia

asia as (select *
from v_committee_asia),

--- giving

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

--- KSM faculty or staff

f as (SELECT
    CONSTITUENT_DONOR_ID ,'Faculty/Staff' AS SHORT_DESC
  FROM DM_ALUMNI.DIM_CONSTITUENT
  WHERE CONSTITUENT_TYPE LIKE '%Faculty%'),


--- special handloing

SH as (select  s.donor_id,
       s.no_contact,
       s.no_email_ind
from mv_special_handling s),

--- contact

contacts as (select c.donor_id,
       c.linkedin_url,
       c.email_preferred_type,
       c.email_preferred,
       c.email_personal,
       c.email_business,
       c.emails_concat
from mv_entity_contact_info c),

--- student contact

scontacts as (select c.donor_id,
       c.linkedin_url,
       c.email_preferred_type,
       c.email_preferred,
       c.email_personal,
       c.email_business,
       c.emails_concat
from mv_entity_contact_info c),

/* Pulling relationships... KSM alumni with Children as NU Undergrad Students */


student_contact as (select *
from stg_alumni.contact),

--- Northwestern Undergrad Students

student as (select distinct
       con.ucinn_ascendv2__donor_id__c as student_donor_id,
       mv_entity.institutional_suffix,
       mv_entity.primary_record_type,
       c.ap_degree_type_from_degreecode__c
from stg_alumni.ucinn_ascendv2__degree_information__c c
--- to get donor ID
inner join student_contact con on c.ucinn_ascendv2__contact__c = con.id
inner join mv_entity on mv_entity.donor_id = con.ucinn_ascendv2__donor_id__c
--- just undergrads and NU
where ucinn_ascendv2__degree_code__c = 'a0UUz00000Lowj9MAB' -- Undergraduate Student
--- Northwestern is the insitution
and c.ucinn_ascendv2__degree_institution__c = '001Uz00000Jp3SrIAJ'
--- Record Type is Student
and mv_entity.primary_record_type = 'Student'),


r as (select distinct
--- The Parent
r.primary_donor_id,
r.primary_full_name,
r.primary_institutional_suffix,
--- The Child
r.relationship_donor_id,
r.relationship_full_name,
student.primary_record_type,
r.relationship_institutional_suffix,
r.relationship_role
from mv_entity_relationships r
--- Children and NU Undergrad Student:
inner join student on student.student_donor_id = r.relationship_donor_id
--- Children
where r.relationship_role IN ('Child','Grandchild')),



--- Listagg for Multiple Children


lr as (select
--- The Parent's ID
r.primary_donor_id,
--- The Children's Data
Listagg (r.relationship_donor_id, ';  ') Within Group (Order By r.relationship_donor_id) As relationship_donor_id,
Listagg (r.relationship_full_name, ';  ') Within Group (Order By r.relationship_donor_id) As realtionship_full_name,
Listagg (r.primary_record_type, ';  ') Within Group (Order By r.relationship_donor_id) As realtionship_record_type,
Listagg (r.relationship_institutional_suffix, ';  ') Within Group (Order By r.relationship_donor_id) As relationship_institutional_suffix,
Listagg (r.relationship_role, ';  ') Within Group (Order By r.relationship_donor_id) As relationship_role,
Listagg (scontacts.email_preferred, ';  ') Within Group (Order By r.relationship_donor_id) As email_preferred
from r
--- emails for the students
left join scontacts on scontacts.donor_id = r.relationship_donor_id
group by primary_donor_id)

/* Final Query */


select distinct
d.donor_id,
d.sort_name,
entity.is_deceased_indicator,
entity.first_name,
entity.last_name,
entity.institutional_suffix,
d.degrees_verbose,
d.first_ksm_year,
d.program,
d.program_group,
entity.preferred_address_city,
entity.preferred_address_state,
entity.preferred_address_country,
assign.prospect_manager_name,
assign.lagm_name,
give.ngc_lifetime,
tp.constituent_university_overall_rating,
tp.constituent_research_evaluation,
gab.involvement_name as gab_involvement_ind,
trustee.involvement_name as trustee,
asia.involvement_name as asia_exec_board,
f.SHORT_DESC as Faculty_Staff_Ind,
contacts.linkedin_url,
sh.no_contact,
sh.no_email_ind,
contacts.email_preferred_type,
contacts.email_preferred,
---case when sh.no_contact is null
--  and no_email_ind is null then contacts.emails_concat else 'DO NOT EMAIL' end as email_concat,
lr.relationship_donor_id,
lr.relationship_role,
lr.realtionship_full_name,
lr.realtionship_record_type,
lr.relationship_institutional_suffix,
lr.email_preferred as Email_Preferred_Relationship
from d
inner join entity on entity.donor_id = d.donor_id
left join assign on assign.donor_id = d.donor_id
left join TP on TP.CONSTITUENT_DONOR_ID = d.donor_id
left join gab on gab.constituent_donor_id = d.donor_id
left join trustee on trustee.constituent_donor_id = d.donor_id
left join asia on asia.constituent_donor_id = d.donor_id
left join give on give.household_id = d.donor_id
left join f on f.CONSTITUENT_DONOR_ID = d.donor_id
left join SH on SH.donor_id = d.donor_id
left join contacts on contacts.donor_id = d.donor_id
inner join lr on lr.primary_donor_id = d.donor_id
order by entity.last_name asc
