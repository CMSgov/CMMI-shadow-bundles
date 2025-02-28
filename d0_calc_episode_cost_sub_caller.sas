/*************************************************************************;
%** PROGRAM: d0_calculate_episode_cost_sub_caller.sas
%** PURPOSE: To select and execute sub-callers/macros in d series
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/
%macro d0_calc_episode_cost_sub_caller();

   *print log;
   %create_log_file(log_file_name = d0_calc_episode_cost_sub_caller);

   *gather all claims starting during an episode window or post-episode period;
   %d1_group_clms_to_epi();

   *identify qualifying OP claim-lines to be grouped to episodes;
   %d2_process_op_clms();

   *identify qualifying IP stays to be grouped to episodes;
   %d3_process_ip_clms();

   *identify qualifying DM claim-lines to be grouped to episodes;
   %d4_process_dm_clms();

   *identify qualifying PB claim-lines to be grouped to episodes;
   %d5_process_pb_clms();

   *identify qualifying SN claim-lines to be grouped to episodes;
   %d6_process_hs_clms();

   *identify qualifying HS claim to be grouped to episodes;
   %d7_process_sn_clms();

   *identify qualifying HH claim to be grouped to episodes;
   %d8_process_hh_clms();

   *calculate total cost of all qualifying claims grouped to episodes;
   %d9_calculate_grouped_costs();
  
%mend;
