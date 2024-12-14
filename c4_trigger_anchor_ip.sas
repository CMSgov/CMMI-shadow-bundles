/*************************************************************************;
%** PROGRAM: c4_trigger_anchor_ip.sas
%** PURPOSE: To identify IP stays that can potentially trigger BPCI-A episodes 
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

%macro c4_trigger_anchor_ip();

   data temp.ip_anchors (drop = first_: last_: fin_: %do a = 1 %to &nflag_vars.; &&flag_vars&a.._flag %end; missing_provider_flag tavr_flag icd9_icd10 procedure_cd mjrue_trigger_flag mjrue_drop_flag)
        temp.mjrue_drop_epis (drop = first_: last_: fin_: %do a = 1 %to &nflag_vars.; &&flag_vars&a.._flag %end; missing_provider_flag tavr_flag icd9_icd10 procedure_cd);

      length anchor_type $5. anchor_stay_id anchor_claimno anchor_lineitem 8. anchor_provider $6. anchor_beg_dt anchor_end_dt anchor_lookback_dt post_dsch_beg_dt post_dsch_end_dt post_dsch_end_dt_&post_dschrg_days. post_epi_beg_dt post_epi_end_dt 8. 
             anchor_trigger_cd $5. anchor_at_npi anchor_op_npi $10. %do a = 1 %to &nflag_vars.; anchor_&&flag_vars&a.._flag %end; anchor_missing_provider_flag 8. anchor_num_ip_transfers anchor_tran_standard_allowed_amt anchor_tran_allowed_amt
             anchor_tran_clm_prpay anchor_standard_allowed_amt anchor_allowed_amt anchor_clm_prpay anchor_length_of_stay 8. anchor_apc $10. anchor_apc_pmt_rate 8. anchor_comp_adj_hcpcs $5. anchor_c_apc_flag 8.
             perf_apc $10. perf_apc_pmt_rate 8. perf_comp_adj_hcpcs $5. perf_c_apc_flag 8. comp_adj_apc_flag 8. perf_comp_adj_apc_flag 8.;
      format anchor_beg_dt anchor_end_dt anchor_lookback_dt post_dsch_beg_dt post_dsch_end_dt post_dsch_end_dt_&post_dschrg_days. post_epi_beg_dt post_epi_end_dt date9.;
      if _n_ = 1 then do;

         *list of BPCI episode trigger codes;
         if 0 then set temp.ip_anchor_episode_list (keep = episode_group_name episode_group_id drg_cd);
         declare hash epi_list (dataset: "temp.ip_anchor_episode_list (keep = episode_group_name episode_group_id drg_cd)");
         epi_list.definekey("drg_cd");
         epi_list.definedata("episode_group_name", "episode_group_id");
         epi_list.definedone();
         
         *list of TAVR episode trigger codes;
         if 0 then set temp.ip_anchor_episode_list (keep = drg_cd);
         declare hash tavr_cds (dataset: "temp.ip_anchor_episode_list (keep = episode_group_name drg_cd where = (upcase(strip(episode_group_name)) = 'IP-TRANSCATHETER AORTIC VALVE REPLACEMENT'))");
         tavr_cds.definekey("drg_cd");
         tavr_cds.definedone();
         
         *list of TAVR procedure codes ICD9;
         if 0 then set temp.tavr_procedure_codes (keep = procedure_cd icd9_icd10 where = (upcase(icd9_icd10) = 'ICD-9'));
         declare hash tavr_icd9 (dataset: "temp.tavr_procedure_codes (keep = procedure_cd icd9_icd10 where = (upcase(icd9_icd10) = 'ICD-9'))");
         tavr_icd9.definekey("procedure_cd");
         tavr_icd9.definedata("icd9_icd10");
         tavr_icd9.definedone();
         
         *list of TAVR procedure codes ICD10;
         if 0 then set temp.tavr_procedure_codes (keep = procedure_cd icd9_icd10 where = (upcase(icd9_icd10) = 'ICD-10'));
         declare hash tavr_icd10 (dataset: "temp.tavr_procedure_codes (keep = procedure_cd icd9_icd10 where = (upcase(icd9_icd10) = 'ICD-10'))");
         tavr_icd10.definekey("procedure_cd");
         tavr_icd10.definedata("icd9_icd10");
         tavr_icd10.definedone();
         
         *list of MJRUE episode trigger codes;
         if 0 then set temp.ip_anchor_episode_list (keep = drg_cd);
         declare hash mjrue_cds (dataset: "temp.ip_anchor_episode_list (keep = episode_group_name drg_cd where = (upcase(strip(episode_group_name)) = 'MS-MAJOR JOINT REPLACEMENT OF THE UPPER EXTREMITY'))");
         mjrue_cds.definekey("drg_cd");
         mjrue_cds.definedone();
         
         *list of MJRUE trigger procedure codes;
         if 0 then set temp.mjrue_trigger_procedure_codes (keep = procedure_cd);
         declare hash mjrue_tr (dataset: "temp.mjrue_trigger_procedure_codes (keep = procedure_cd)");
         mjrue_tr.definekey("procedure_cd");
         mjrue_tr.definedone();
         
         *list of MJRUE dropped procedure codes;
         if 0 then set temp.mjrue_dropped_procedure_codes (keep = procedure_cd);
         declare hash mjrue_dr (dataset: "temp.mjrue_dropped_procedure_codes (keep = procedure_cd)");
         mjrue_dr.definekey("procedure_cd");
         mjrue_dr.definedone();

      end;
      call missing(of _all_);

      set temp.ip_stays_w_transfers;

      *define episode window;
      anchor_type = "ip";
      anchor_stay_id = ip_stay_id;
      call missing(anchor_claimno, anchor_lineitem);
      anchor_provider = first_provider;
      anchor_beg_dt = first_admsn_dt;
      anchor_end_dt = last_dschrgdt;
      anchor_lookback_dt = first_admsn_dt - &lookback_days.;
      post_dsch_beg_dt = anchor_end_dt;
      post_dsch_end_dt = post_dsch_beg_dt + %eval(&post_dschrg_days. - 1);
      post_dsch_end_dt_&post_dschrg_days. = post_dsch_beg_dt + %eval(&post_dschrg_days. - 1);
      post_epi_beg_dt = post_dsch_end_dt + 1;
      post_epi_end_dt = post_epi_beg_dt + %eval(&post_epi_days.  - 1);
      anchor_trigger_cd = last_drg_cd;
      anchor_at_npi = first_at_npi;
      anchor_op_npi = first_op_npi;
      %do a = 1 %to &nflag_vars.;
         anchor_&&flag_vars&a.._flag = first_&&flag_vars&a.._flag;
      %end;
      anchor_missing_provider_flag = first_missing_provider_flag;
      anchor_num_ip_transfers = fin_num_transfers_ip;

      *NOTE: the anchor_tran_ cost variables only include the costs of the prior transfer stays and do not include the cost of the last stay in the transfer;
      if (transfer_stay = 1) then do;
         anchor_standard_allowed_amt = fin_standard_allowed_amt;
         anchor_allowed_amt = fin_allowed_amt;
         anchor_clm_prpay = fin_clm_prpay;
         anchor_tran_standard_allowed_amt = fin_standard_allowed_amt - standard_allowed_amt;
         anchor_tran_allowed_amt = fin_allowed_amt - allowed_amt;
         anchor_tran_clm_prpay = fin_clm_prpay - clm_prpay;
      end;
      else if (transfer_stay = 0) then do;
         anchor_num_ip_transfers = 0;
         anchor_tran_standard_allowed_amt = 0;
         anchor_tran_allowed_amt = 0;
         anchor_tran_clm_prpay = 0;
         anchor_standard_allowed_amt = fin_standard_allowed_amt;
         anchor_allowed_amt = fin_allowed_amt;
         anchor_clm_prpay = fin_clm_prpay;
      end;

      *calculate the length of stay for the total inpatient hospitalization (from admission to the first leg of an ip stay to discharge from the last stay in a transfer process);
      anchor_length_of_stay = max((anchor_end_dt - anchor_beg_dt), 1);

      *set to zero and missing since these variables only apply to OP anchors;
      anchor_c_apc_flag = 0;
      perf_c_apc_flag = 0;
      comp_adj_apc_flag = 0;
      perf_comp_adj_apc_flag = 0;
      call missing(anchor_apc, anchor_apc_pmt_rate, anchor_comp_adj_hcpcs, perf_apc, perf_apc_pmt_rate, perf_comp_adj_hcpcs);

      tavr_flag = 0;
      mjrue_trigger_flag = 0;
      mjrue_drop_flag = 0;
      if (epi_list.find(key: drg_&update_factor_fy.) = 0) then do;
         if (tavr_cds.find(key: drg_&update_factor_fy.) = 0) then do;
            if (anchor_end_dt < "&icd9_icd10_date."D) then do;
               %do a = 1 %to &diag_proc_length.;
                  %let b = %sysfunc(putn(&a., z2.));
                  if (tavr_icd9.find(key: prcdrcd&b.) = 0) then tavr_flag = 1;
                  %if &a. ^= &diag_proc_length. %then else;
               %end;
            end;
            else do;
               %do a = 1 %to &diag_proc_length.;
                  %let b = %sysfunc(putn(&a., z2.));
                  if (tavr_icd10.find(key: prcdrcd&b.) = 0) then tavr_flag = 1;
                  %if &a. ^= &diag_proc_length. %then else;
               %end;
            end;
            if tavr_flag = 1 then output temp.ip_anchors;
         end; %*end of trigger TAVR epis;
         else if (mjrue_cds.find(key: drg_&update_factor_fy.) = 0) then do;
            %do a = 1 %to &diag_proc_length.;
               %let b = %sysfunc(putn(&a., z2.));
               if (mjrue_tr.find(key: prcdrcd&b.) = 0) then mjrue_trigger_flag = 1;
               if (mjrue_dr.find(key: prcdrcd&b.) = 0) then mjrue_drop_flag = 1;
            %end;
            if mjrue_trigger_flag = 1 then output temp.ip_anchors;
            else output temp.mjrue_drop_epis;
         end; %*end of trigger MJRUE epis;
         else do;
            output temp.ip_anchors;
         end; %*end of trigger other epis;
      end; %*end of trigger epis;

   run;
   
%mend; 