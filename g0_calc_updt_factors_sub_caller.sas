/*************************************************************************;
%** PROGRAM: g0_calc_updt_factors_sub_caller.sas
%** PURPOSE: To select and execute sub-callers/macros in g series
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/
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
