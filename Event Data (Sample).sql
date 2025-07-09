--- Pulling KSM Event Data 

Select 
e.id,
e.conference360__category__c,
e.conference360__organizer_account__c, 
e.conference360__organizer_contact__c,
e.name,
e.organizer_entity_id__c,
e.nu_blackthorn_event__c,
e.conference360__category__c,
e.conference360__event_end_date_time_gmt__c,
e.conference360__event_end_date_time__c,
e.conference360__event_end_date__c,
e.conference360__event_start_date_time_gmt__c,
e.conference360__event_start_date_time__c,
e.conference360__event_start_date__c,
e.conference360__status__c, e.conference360__venue_name__c
From stg_alumni.conference360__event__c e
where e.name like '%Kellogg Alumni Club of Chicago Networking Breakfast%'
