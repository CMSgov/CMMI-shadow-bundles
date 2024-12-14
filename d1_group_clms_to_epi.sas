/*************************************************************************;
%** PROGRAM: d1_group_clms_to_epi.sas
%** PURPOSE: To gather all claims starting within the episode and post-episode window 
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

%macro d1_group_clms_to_epi();

   *define the variables to keep from each claim setting;
   %let opl_keep_vars = link_id claimno lineitem provider hcpcs_cd from_dt thru_dt rev_cntr dgnscd: rev_msp1 rev_msp2 rev_dt line_std_allowed line_allowed rstusind link_num daily_dt pvisit:;
   %let ip_keep_vars = link_id ip_stay_id provider admsn_dt dschrgdt from_dt thru_dt drg_cd mdc standard_allowed_amt_w_o_outlier standard_allowed_amt outlier_pmt clm_prpay allowed_amt allowed_amt_w_o_outlier stay_outlier ipps_provider missing_provider_flag drg_:
                       overlap_keep_acute overlap_keep_inner overlap_keep_outer overlap_keep_inner_outer prcdrcd: dgnscd: ad_dgns;
   %do a = 1 %to &nflag_vars.;
      %let ip_keep_vars = &ip_keep_vars. &&flag_vars&a.._flag;
   %end;
   %let dm_keep_vars = link_id claimno lineitem expnsdt1 hcpcs_cd linedgns line_std_allowed lprpdamt from_dt thru_dt line_allowed link_num daily_dt dgnscd:;
   %let pb_keep_vars = link_id claimno lineitem expnsdt1 hcpcs_cd linedgns lprpdamt plcsrvc line_std_allowed from_dt thru_dt mdfr_cd: line_allowed betos carr_num lclty_cd prfnpi tax_num link_num daily_dt dgnscd:;
   %let sn_keep_vars = link_id claimno provider from_dt admsn_dt dschrgdt thru_dt std_allowed prpayamt clm_allowed sgmt_num rvcntr: rvunt: hcpscd: link_num daily_dt dgnscd: ad_dgns;
   %let hs_keep_vars = link_id claimno provider from_dt dschrgdt thru_dt std_allowed prpayamt clm_allowed demonum: fac_type typesrvc freq_cd link_num daily_dt dgnscd:;
   %let hh_keep_vars = link_id claimno from_dt thru_dt sgmt_num apcpps: rvcntr: rvunt: rev_dt: visitcnt rvchrg: rvncvr: hcpscd: prcrrtrn std_allowed prpayamt clm_allowed lupa_flag link_num daily_dt dgnscd:;

   *define variables to keep from episode-level dataset;
   %let anchor_keep_vars = link_id episode_id episode_group_id episode_group_name anchor_stay_id anchor_claimno anchor_lineitem anchor_type anchor_trigger_cd anchor_provider anchor_lookback_dt anchor_beg_dt anchor_end_dt post_dsch_beg_dt post_dsch_end_dt post_dsch_end_dt_&post_dschrg_days.
                           post_epi_beg_dt post_epi_end_dt anchor_at_npi anchor_op_npi anchor_length_of_stay anchor_standard_allowed_amt anchor_allowed_amt anchor_clm_prpay transfer_stay trans_ip_stay_: anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag;

   *define variables to keep in clms_to_epi_ dataset for each setting;
   %let opl_clm_vars = link_id claimno lineitem provider hcpcs_cd rev_cntr dgnscd: rev_msp1 rev_msp2 rev_dt standard_allowed_amt raw_allowed_amt clm_prpay rstusind episode_id anchor_: post_: anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag anchor_drg_&update_factor_fy. link_num daily_dt pvisit:;
   %let ip_clm_vars = link_id ip_stay_id provider from_dt thru_dt drg_cd mdc standard_allowed_amt_w_o_outlier standard_allowed_amt outlier_pmt clm_prpay raw_allowed_amt raw_allowed_amt_w_o_outlier raw_outlier_pmt episode_id anchor_: post_: ipps_provider missing_provider_flag drg_:
                      overlap_keep_acute overlap_keep_inner overlap_keep_outer overlap_keep_inner_outer transfer_stay trans_ip_stay_: anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag prcdrcd: anchor_drg_&update_factor_fy. episode_group_name dgnscd: ad_dgns;
   %do a = 1 %to &nflag_vars.;
      %let ip_clm_vars = &ip_clm_vars. &&flag_vars&a.._flag;
   %end;
   %let dm_clm_vars = link_id claimno lineitem hcpcs_cd linedgns from_dt thru_dt standard_allowed_amt clm_prpay raw_allowed_amt episode_id anchor_: post_: anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag anchor_drg_&update_factor_fy. link_num daily_dt dgnscd: episode_group_name;
   %let pb_clm_vars = link_id claimno lineitem hcpcs_cd linedgns from_dt thru_dt plcsrvc mdfr_cd: standard_allowed_amt clm_prpay raw_allowed_amt episode_id anchor_: post_: betos carr_num lclty_cd prfnpi tax_num anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag anchor_drg_&update_factor_fy. episode_group_name link_num daily_dt dgnscd:;
   %let sn_clm_vars = link_id claimno sgmt_num provider admsn_dt dschrgdt standard_allowed_amt clm_prpay raw_allowed_amt episode_id anchor_: post_: rvcntr: rvunt: hcpscd: anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag episode_group_name link_num daily_dt dgnscd: ad_dgns;
   %let hs_clm_vars = link_id claimno provider dschrgdt standard_allowed_amt clm_prpay raw_allowed_amt demonum: fac_type typesrvc freq_cd episode_id anchor_: post_: anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag link_num daily_dt dgnscd: episode_group_name;
   %let hh_clm_vars = link_id claimno sgmt_num from_dt thru_dt apcpps: rvcntr: rvunt: rev_dt: visitcnt rvchrg: rvncvr: hcpscd: prcrrtrn standard_allowed_amt clm_prpay raw_allowed_amt episode_id anchor_: post_: lupa_flag anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag episode_group_name link_num daily_dt dgnscd:;   

   *grab all claims occurring within the episode and post-episode period;
   data %do a = 1 %to &nsettings.; 
            temp.&&settings&a.._clms_to_epi (keep = &&&&&&settings&a.._clm_vars. file_type service_start_dt service_start_dt_type service_end_dt service_end_dt_type non_positive_payment non_medicare_prpayer 
                                                                 ed_flag gsc_flag gsc_num gsc_exclude covid_19_clm hemophilia_flag part_b_dropflag excluded_cardiac_rehab opps_pass_thru_flag excluded_readmission excluded_mdc excluded_pci_tavr excluded_ibd_partb
                                                                 overlap_w_excluded_readmsn overlap_w_excluded_mdc overlap_w_excluded_pci_tavr ocm_pbpm_flag eom_pbpm_flag mccm_pbpm_flag part_of_transfer_flag anchor_visit_count post_dschrg_visit_count post_epi_visit_count
                                                                 tot_visit_count prorated anchor_overlap_days post_dschrg_overlap_days tot_overlap_days grouped tot_claim_length catgry_num cost_category)
        %end;;

      length file_type $10. service_start_dt_type service_end_dt_type $20. service_start_dt service_end_dt non_positive_payment non_medicare_prpayer ed_flag gsc_flag gsc_num gsc_exclude covid_19_clm hemophilia_flag part_b_dropflag excluded_cardiac_rehab 
             opps_pass_thru_flag excluded_readmission excluded_mdc excluded_pci_tavr excluded_ibd_partb overlap_w_excluded_readmsn overlap_w_excluded_mdc overlap_w_excluded_pci_tavr part_of_transfer_flag ocm_pbpm_flag eom_pbpm_flag mccm_pbpm_flag 8. 
             anchor_visit_count post_dschrg_visit_count post_epi_visit_count tot_visit_count prorated anchor_overlap_days post_dschrg_overlap_days post_epi_overlap_days tot_overlap_days grouped tot_claim_length
             catgry_num 8. cost_category $100.;
      format service_start_dt service_end_dt date9.;
      if _n_ = 1 then do;

         *list of all candidate episodes;
         if 0 then set temp.episodes_w_dropflags (keep = &anchor_keep_vars. drg_&update_factor_fy. rename = (drg_&update_factor_fy. = anchor_drg_&update_factor_fy.));
         declare hash anchors (dataset: "temp.episodes_w_dropflags (keep = &anchor_keep_vars. drg_&update_factor_fy. rename = (drg_&update_factor_fy. = anchor_drg_&update_factor_fy.))", multidata: "y");
         anchors.definekey("link_id");
         anchors.definedata(all: "y");
         anchors.definedone();

      end;
      call missing(of _all_);

      *NOTE: set overlap ip stay flag so that when an overlap between an outer LTCH/IRF/IPF stay occur with an inner acute stay, only the inner is kept. this is to prevent the accidental inclusion of the outer LTCH stay in the post-discharge period cost during IP cost aggregation later on;
      set clm_inp.opl (obs = max keep = &opl_keep_vars. in = in_opl rename = (line_std_allowed = standard_allowed_amt line_allowed = raw_allowed_amt) where = (not missing(rev_dt)))
          temp.cleaned_ip_stays_w_remap (obs = max keep = &ip_keep_vars. in = in_ip rename = (allowed_amt = raw_allowed_amt allowed_amt_w_o_outlier = raw_allowed_amt_w_o_outlier stay_outlier = raw_outlier_pmt) where = (overlap_keep_inner_outer = 1))
          clm_inp.dm (obs = max keep = &dm_keep_vars. in = in_dm rename = (line_std_allowed = standard_allowed_amt lprpdamt = clm_prpay line_allowed = raw_allowed_amt))
          clm_inp.pb (obs = max keep = &pb_keep_vars. in = in_pb rename = (line_std_allowed = standard_allowed_amt lprpdamt = clm_prpay line_allowed = raw_allowed_amt))
          clm_inp.sn (obs = max keep = &sn_keep_vars. in = in_sn rename = (std_allowed = standard_allowed_amt prpayamt = clm_prpay clm_allowed = raw_allowed_amt))
          clm_inp.hs (obs = max keep = &hs_keep_vars. in = in_hs rename = (std_allowed = standard_allowed_amt prpayamt = clm_prpay clm_allowed = raw_allowed_amt))
          clm_inp.hh (obs = max keep = &hh_keep_vars. in = in_hh rename = (std_allowed = standard_allowed_amt prpayamt = clm_prpay clm_allowed = raw_allowed_amt))
          ;
      
      %do a = 1 %to &nsettings.;
         if (in_&&settings&a.. = 1) then file_type = "&&settings&a..";
      %end;

      if (in_opl = 1) then clm_prpay = sum(rev_msp1, rev_msp2); 

      *define the service start and end dates for each setting;
      if (in_opl = 1) then do;
         service_start_dt = rev_dt;
         service_start_dt_type = "rev_dt";
         service_end_dt = rev_dt;
         service_end_dt_type = "rev_dt";
      end;
      else if (in_ip = 1) then do;
         service_start_dt = admsn_dt;
         service_start_dt_type = "admsn_dt";
         service_end_dt = dschrgdt;
         service_end_dt_type = "dschrgdt";
      end;
      else if (in_pb = 1) or (in_dm = 1) then do;
         service_start_dt = expnsdt1;
         service_start_dt_type = "expnsdt1";
         service_end_dt = expnsdt1;
         service_end_dt_type = "expnsdt1";
      end;
      else if (in_sn = 1) or (in_hs = 1) or (in_hh = 1) then do;
         service_start_dt = from_dt;
         service_start_dt_type = "from_dt";
         service_end_dt = thru_dt;
         service_end_dt_type = "thru_dt";
      end;

      *determine if claim has positive payment;
      if (standard_allowed_amt <= 0) then non_positive_payment = 1;
      else non_positive_payment = 0;
      
      *determine if claim is from a non-medicare primary payer;
      if (clm_prpay > 0) then non_medicare_prpayer = 1;
      else non_medicare_prpayer = 0;

      *initialize flags;
      *NOTE: certain flags are only applicable to some settings, however, all flags will still be initialized in this location rather than in the setting-specific macros;
      ed_flag = 0;
      gsc_flag = 0;
      gsc_num = 0;
      gsc_exclude = 0;
      covid_19_clm = 0;
      hemophilia_flag = 0;
      part_b_dropflag = 0;
      excluded_cardiac_rehab = 0;
      opps_pass_thru_flag = 0;
      excluded_readmission = 0;
      excluded_mdc = 0;
      excluded_pci_tavr = 0;
      excluded_ibd_partb = 0;
      overlap_w_excluded_readmsn = 0;
      overlap_w_excluded_mdc = 0;
      overlap_w_excluded_pci_tavr = 0;
      part_of_transfer_flag = 0;
      ocm_pbpm_flag = 0;
      eom_pbpm_flag = 0;
      mccm_pbpm_flag = 0;
      anchor_visit_count = 0;
      post_dschrg_visit_count = 0;
      post_epi_visit_count = 0;
      tot_visit_count = 0;
      prorated = 0;
      anchor_overlap_days = 0;
      post_dschrg_overlap_days = 0;
      post_epi_overlap_days = 0;
      tot_overlap_days = 0;
      grouped = 0;
      tot_claim_length = (service_end_dt - service_start_dt) + 1;
      catgry_num = 0;
      cost_category = "unattributed";

      *group all claims that start within the episode and post-episode window;
      if (anchors.find(key: link_id) = 0) then do;
         rc_anchors = 0;
         do while (rc_anchors = 0);
            *NOTE: include one day lookback for PB and OP claims to account for ED/GSC claims;
            if ((anchor_beg_dt - &gsc_ed_lookback_days. <= service_start_dt <= max(post_dsch_end_dt, post_epi_end_dt)) and ((in_pb = 1) or (in_opl = 1))) or
               ((anchor_beg_dt <= service_start_dt <= max(post_dsch_end_dt, post_epi_end_dt)) and ((in_ip = 1) or (in_dm = 1) or (in_sn = 1) or (in_hs = 1) or (in_hh = 1)))
            then do;
               %do a = 1 %to &nsettings.;
                  if (in_&&settings&a.. = 1) then output temp.&&settings&a.._clms_to_epi;
                  %if &a. ^= &nsettings. %then else;
               %end;
            end;
            rc_anchors = anchors.find_next();
         end;
      end;

   run;

   %do a = 1 %to &nsettings.;
      proc sort data = temp.&&settings&a.._clms_to_epi;
         by episode_id;
      run;
   %end;
   
%mend; 