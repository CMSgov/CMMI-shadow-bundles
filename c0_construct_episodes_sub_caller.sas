/*************************************************************************;
%** PROGRAM: c0_construct_episodes_sub_caller.sas
%** PURPOSE: To select and execute sub-macros in c series
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
RESTRICTED RIGHTS NOTICE (SEPT 2014)

(a) This computer software is submitted with restricted rights under Government Agreement No._ Contract_Number_ . It may not be used, reproduced, or disclosed by the Government except as provided in paragraph (b) of this Notice or as otherwise expressly stated in the agreement. 
(b) This computer software may be�
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
