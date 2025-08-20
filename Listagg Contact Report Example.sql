with a as (select
co.ucinn_ascendv2__donor_id__c,
co.firstname,
co.lastname,
c.ap_contact_report_author_name_formula__c,
c.ucinn_ascendv2__contact_method__c,
c.ucinn_ascendv2__date__c,
c.ucinn_ascendv2__description__c,
c.ucinn_ascendv2__contact_report_body__c
from stg_alumni.ucinn_ascendv2__contact_report__c c
left join stg_alumni.contact co on co.id = c.ucinn_ascendv2__contact__c
where c.ap_contact_report_author_name_formula__c = 'Francesca Cornelli'
and (c.ucinn_ascendv2__contact_method__c = 'Event'
and c.ucinn_ascendv2__date__c >= to_date ('09/01/2024', 'mm/dd/yyyy'))
or c.ucinn_ascendv2__contact_report_name_auto_number__c IN ('CR-1100531','CR-1687627','CR-1044927')
order by c.ucinn_ascendv2__date__c ASC),

--- Listagg this 

l as (select a.ucinn_ascendv2__donor_id__c,
Listagg (a.ap_contact_report_author_name_formula__c, ';  ') Within Group (Order By a.ucinn_ascendv2__date__c) As author_name,
Listagg (a.ucinn_ascendv2__contact_method__c, ';  ') Within Group (Order By a.ucinn_ascendv2__date__c) As contact_type,

Listagg (a.ucinn_ascendv2__date__c, ';  ') Within Group (Order By a.ucinn_ascendv2__date__c) As cr_date, 
Listagg (a.ucinn_ascendv2__description__c, ';  ') Within Group (Order By a.ucinn_ascendv2__date__c) As cr_description
from a
group by a.ucinn_ascendv2__donor_id__c)

select e.donor_id,
       e.full_name,
       e.first_name,
       e.last_name,
       l.author_name,
       l.contact_type,
       l.cr_date, 
       l.cr_description
from mv_entity e
inner join l on l.ucinn_ascendv2__donor_id__c = e.donor_id
order by l.cr_description ASC  
