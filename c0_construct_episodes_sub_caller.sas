/*************************************************************************;
%** PROGRAM: c0_construct_episodes_sub_caller.sas
%** PURPOSE: To select and execute sub-macros in c series
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/
%macro c0_construct_episodes_sub_caller();

   *print log;
   %create_log_file(log_file_name = c0_construct_episodes_sub_caller);
  
   *map MS-DRGs to represent the performing FYs;
   %c1_remap_ms_drg();

   *create provider type indicators for IP stays and OP claim-lines;
   %c2_flag_provider_types();

   *resolve acute to acute transfer stays;
   %c3_resolve_transfer_stays();

   *identify IP stays that can potentially trigger BPCI-A episodes;
   %c4_trigger_anchor_ip();

   *identify OP lines that can potentially trigger BPCI-A episodes;
   %c5_trigger_anchor_op();

   *create flags to indicate the reasons for excluding episodes;
   %c6_create_exclusion_flags();
  
%mend;
