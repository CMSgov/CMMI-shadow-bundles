/*************************************************************************;
%** PROGRAM: c1_clean_ip_stays.sas
%** PURPOSE: Applies preliminary restrictions and create additional variables for IP stays
%** AUTHOR: Acumen
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

%macro c1_clean_ip_stays();

   *define list of variables to keep in processed ip stays dataset;
   %let ip_keep_vars = link_id ip_stay_id stay_drg_cd provider stay_admsn_dt stay_dschrgdt stay_daily_dt stay_from_dt stay_thru_dt stus_cd at_npi op_npi stay_cr_day stay_prpayamt stay_allowed stay_std_outlier_wo_nta stay_std_deductible stay_std_coinsurance 
                       stay_std_allowed_wo_hemo_nta stay_std_allwd_wo_outlier_wo_nta dgnscd: ad_dgns prcdrcd: pdgns_cd stay_outlier stay_new_tech_pmt stay_clotting_pmt overlap_keep_acute overlap_keep_inner overlap_keep_outer overlap_keep_inner_outer ltch_stay irf_stay;

   *define the variables to be renamed in the ip stays dataset;
   %macarray(orig_vars,    stay_drg_cd    stay_admsn_dt     stay_dschrgdt     stay_daily_dt     stay_from_dt      stay_thru_dt      stay_cr_day    stay_prpayamt     stay_allowed      stay_std_deductible     stay_std_coinsurance
                           stay_std_allowed_wo_hemo_nta     stay_std_allwd_wo_outlier_wo_nta    stay_std_outlier_wo_nta);
   *define the new names to rename the variables to;
   %macarray(rename_vars,  drg_cd         admsn_dt          dschrgdt          daily_dt          from_dt           thru_dt           sum_util       clm_prpay         clm_allowed       deductible              coinsurance
                           standard_allowed_amt             standard_allowed_amt_w_o_outlier    outlier_pmt);

   *sort processed ip stays;
   proc sort data = ab_clm.ip_stays (keep = &ip_keep_vars. rename = (%do a = 1 %to &norig_vars.; &&orig_vars&a.. = &&rename_vars&a.. %end;))
             out = temp.ip_stays;
        by link_id admsn_dt dschrgdt daily_dt provider;
   run;

   *restrict to IP stays with positive standard allowed amount and create additional payment variables;
   data temp.cleaned_ip_stays;   
      length allowed_amt allowed_amt_w_o_outlier 8.;      
      set temp.ip_stays (where = (standard_allowed_amt > 0));
      
      *calculate standardized allowed amounts without technology, clotting factors, and outlier add-on payments;
      allowed_amt = clm_allowed - sum(stay_new_tech_pmt, stay_clotting_pmt);
      allowed_amt_w_o_outlier = clm_allowed - sum(stay_new_tech_pmt, stay_clotting_pmt, stay_outlier);
   run;

%mend;
