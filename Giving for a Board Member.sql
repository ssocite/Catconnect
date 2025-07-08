/*Select *
From mv_ksm_designation mvd
Where mvd.designation_name Like '%AMP%'
  Or mvd.designation_name Like '%Asset%'
;
*/

Select
  kt.credited_donor_id
  , kt.credited_donor_sort_name
  , kt.tx_id
  , kt.opportunity_record_id
  , kt.legacy_receipt_number
  , kt.source_type_detail
  , kt.gypm_ind
  , kt.designation_record_id
  , kt.designation_name
  , kt.cash_category
  , kt.credit_date
  , kt.fiscal_year
  , kt.credit_type
  , kt.credit_amount
  , kt.hard_credit_amount
From mv_ksm_transactions kt
Where kt.designation_record_id In ('N4005431', 'N3038605', 'N3032892')
---And kt.credited_donor_id In (Enter ID Here)
