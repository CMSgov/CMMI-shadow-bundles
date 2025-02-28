/*************************************************************************;
%** PROGRAM: f0_create_ra_variables_sub_caller.sas
%** PURPOSE: To select and execute sub-callers/macros in f series
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/
%macro f0_create_ra_vars_sub_caller();

   *print log;
   %create_log_file(log_file_name = f0_create_ra_variables_sub_caller);

   *add beneficiary level variables;
   %f1_add_bene_ra_vars();

   *add provider level variables and time trend variables;
   %f2_add_prov_ra_vars();
   
   *add HCC flags;
   %f3_add_hccs();

   *add covid infection rates;   
   %f4_add_covid_inf_rates();
   
   *add indicator for beneficiary that utilized any post-acute care services prior to the episodes;  
   %f5_add_prior_hosp_flags();
   
   *add dual eligibility flag for beneficiaries that are eligible for both Medicare and Medicaid; 
   %f6_add_dual_elig_flags();
   
   *add flag to indicate safety net hospitals; 
   %f7_add_safety_net_flags();
   
  
%mend;
