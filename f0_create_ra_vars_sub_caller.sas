/*************************************************************************;
%** PROGRAM: f0_create_ra_variables_sub_caller.sas
%** PURPOSE: To select and execute sub-callers/macros in f series
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
RESTRICTED RIGHTS NOTICE (SEPT 2014)

(a) This computer software is submitted with restricted rights under Government Agreement No._ Contract_Number_ . It may not be used, reproduced, or disclosed by the Government except as provided in paragraph (b) of this Notice or as otherwise expressly stated in the agreement. 
(b) This computer software may be—
   (1) Used or copied for use in or with the computer or computers for which it was acquired, including use at any Government installation to which such computer or computers may be transferred; 
   (2) Used or copied for use in a backup computer if any computer for which it was acquired is inoperative; 
   (3) Reproduced for safekeeping (archives) or backup purposes; 
   (4) Modified, adapted, or combined with other computer software, provided that the modified, combined, or adapted portions of the derivative software are made subject to the same restricted rights; 
   (5) Disclosed to and reproduced for use by support service Recipients in accordance with subparagraphs (b)(1) through (4) of this clause, provided the Government makes such disclosure or reproduction subject to these restricted rights; and
   (6) Used or copied for use in or transferred to a replacement computer. 
(c) Notwithstanding the foregoing, if this computer software is published copyrighted computer software, it is licensed to the Government, without disclosure prohibitions, with the minimum rights set forth in paragraph (b) of this clause. 
(d) Any other rights or limitations regarding the use, duplication, or disclosure of this computer software are to be expressly stated in, or incorporated in, the agreement. 
(e) This Notice shall be marked on any reproduction of this computer software, in whole or in part. 

(End of notice)
*************************************************************************/
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
