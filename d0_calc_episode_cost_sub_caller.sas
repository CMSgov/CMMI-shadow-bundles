/*************************************************************************;
%** PROGRAM: d0_calculate_episode_cost_sub_caller.sas
%** PURPOSE: To select and execute sub-callers/macros in d series
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
