/*************************************************************************;
%** PROGRAM: g0_calc_updt_factors_sub_caller.sas
%** PURPOSE: To select and execute sub-callers/macros in g series
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
%macro g0_calc_updt_factors_sub_caller();

   *print log;
   %create_log_file(log_file_name = g0_calc_updt_factors_sub_caller);

   *gather claims to be used for calculating the update factors;
   %g1_gather_clms_for_updt_factors();

   *calculate IPPS update factor for anchor and post-anchor period cost;
   %g2_calculate_ipps_update_factor();

   *calculate OPPS update factor for anchor period cost;
   %g3_calculate_opps_update_factor();

   *calculate PB update factor for post-anchor period cost;
   %g4_calculate_pb_update_factor();

   *calculate HH update factor for post-anchor period cost;
   %g5_calculate_hh_update_factor();

   *calculate SN update factor for post-anchor period cost;
   %g6_calculate_sn_update_factor();

   *calculate IRF update factor for post-anchor period cost;
   %g7_calculate_irf_update_factor();

   *calculate other update factor (MEI);
   %g8_calculate_other_update_factor();

   *gather all claims/episodes to calculate the weights for update factors;
   %g9_aggregate_clms_for_uf_weights();

   *calculate and apply final update factors to episode cost;   
   %g10_apply_final_update_factor(); 
   
   *cap episode updated cost at 1st and 99th percentile;
   %g11_winsorize_episode_cost();
   
%mend;
