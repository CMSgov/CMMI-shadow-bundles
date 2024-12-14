/*************************************************************************;
%** PROGRAM: c6_create_exclusion_flags.sas
%** PURPOSE: To create flags to indicate the reasons for excluding episodes 
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

%macro c6_create_exclusion_flags();

   /*GATHER ALL CANDIDATE EPISODES*/

   *stack together the list of possible ip and op anchors;
   data temp.all_anchors;

      if _n_ = 1 then do;
         
         *unique list of beneficiary with an ip or op anchor;
         declare hash benes (ordered: "a");
         benes.definekey("link_id");
         benes.definedata("link_id");
         benes.definedone();

      end;

      set temp.ip_anchors 
          temp.op_anchors
          end = last;

      if (benes.find(key: link_id) ^= 0) then benes.add();
      if last then benes.output(dataset: "temp.bene_finder");

   run;
   
   /*PREPARE DATASETS TO CREATE EXCLUSION FLAGS*/
   
   *get enrollment information for beneficiaries with triggered episodes;
   data temp.bene_finder
        temp.benes_not_in_uber (keep = link_id);
      
      set temp.bene_finder (keep = link_id);
      by link_id;

      set enrll.uber_enr_%sysfunc(compress(%str(&edb_version.), %str(_))) (keep = link_id bene_sex_race_cd bene_birth_dt bene_death_dt curhic_uneq enr_%eval(&query_start_year.-1)-enr_&query_end_year. orig_mscd) 
      key = link_id/unique;

      select(_iorc_);
         when (%sysrc(_sok)) do;
            output temp.bene_finder;
         end;
         when (%sysrc(_dsenom)) do;
             output temp.benes_not_in_uber;
            _error_ = 0;
         end;
         otherwise do;
            put "UNEXPECTED PROBLEM: _IORC_ = " _iorc_;
            stop;
         end;
      end;

   run;

   *get ESRD and primary payer information from RIC tables;
   *esrd coverage (RIC S), esrd dialysis (RIC T), esrd transplant (RIC U), primary payer (RIC F);
   data temp.esrd (keep = link_id esrd_start_dt esrd_end_dt ric_table)
        temp.primary_payer (keep = link_id other_pp_start_dt other_pp_end_dt);

      if _n_ = 1 then do;
         
         *list of beneficiaries with an IP or OP anchor;
         if 0 then set temp.bene_finder (keep = link_id);
         declare hash getbene (dataset: "temp.bene_finder (keep = link_id)");
         getbene.definekey("link_id");
         getbene.definedone();

      end;
      call missing(of _all_);

      set oth_inp.esrd (keep = link_id esrd_start_dt esrd_end_dt ric_table in = in_esrd)
          oth_inp.primary_payer (keep = link_id other_pp_start_dt other_pp_end_dt in = in_prim_payer);

      *for transplant ESRD, the coverage period should be set to 36 months from the starting date;
      *for regular ESRD coverage (RIC S) and dialysis (RIC T), continue to use the defined esrd start and end date;
      if (in_esrd = 1) and (lowcase(ric_table) = "u") then esrd_end_dt = sum(esrd_start_dt, &num_transplnt_days.);

      if (getbene.find(key: link_id) = 0) then do;
         if (in_esrd = 1) then output temp.esrd;
         if (in_prim_payer = 1) then output temp.primary_payer;
      end;

   run;

   *sort all ip and op anchor stays so that a specific episode identifier can be created according to this sorted order;
   proc sort data = temp.all_anchors;
      by link_id anchor_beg_dt anchor_provider anchor_type;
   run;

   *sort so that within each claim, the line with the higher primary ranking (smaller rank value) is first;
   *NOTE: make sure to sort so that the trigger line precedes the non-trigger line to deal with cases when ties in ranking occur and we still keep the trigger line as the highest ranked line;
   proc sort data = temp.op_w_j1_rankings (where = ((line_std_allowed > 0) and (not missing(prim_assign_rank))))
             out = temp.high_rank_j1_by_claim;
        by link_id anchor_claimno anchor_lineitem descending j1_flag prim_assign_rank descending trigger_line;
   run;

   *create a finder showing the highest ranking line for each claim;
   data temp.high_rank_j1_dedup;
      set temp.high_rank_j1_by_claim;
      by link_id anchor_claimno anchor_lineitem descending j1_flag prim_assign_rank descending trigger_line;
      if first.anchor_lineitem then output temp.high_rank_j1_dedup;
   run;

   *output a list of all IP transfer legs where a CAH or cancer hospital was involved in the transfer at some point; 
   data temp.transfers_w_cah_cancer (drop = cah_flag cancer_hosp_flag excl_mdc excl_readmsn trans_w_excl_mdc trans_w_excl_readmsn)
        temp.transfers_w_excl_drg_mdc (drop = cah_flag cancer_hosp_flag excl_mdc excl_readmsn trans_w_cah trans_w_cancer);

      if _n_ = 1 then do;
      
         *list of MDC to be excluded;
         if 0 then set temp.excluded_mdc (keep = mdc);
         declare hash h_mdc (dataset: "temp.excluded_mdc (keep = mdc)");
         h_mdc.definekey("mdc");
         h_mdc.definedone();
         
         *list of readmission exclusion drg codes;
         if 0 then set temp.excluded_readmissions (keep = ms_drg);
         declare hash h_excl_readmsn (dataset: "temp.excluded_readmissions (keep = ms_drg)");
         h_excl_readmsn.definekey("ms_drg");
         h_excl_readmsn.definedata("ms_drg");
         h_excl_readmsn.definedone();
         
      end;
      call missing(of _all_);
      
      set temp.transfers_prov_crosswalk;
      
      excl_mdc = 0;
      excl_readmsn = 0;
      if (h_mdc.find(key: mdc) = 0) then excl_mdc = 1;
      if (h_excl_readmsn.find(key: drg_&update_factor_fy.) = 0) then excl_readmsn = 1;

      by transfer_id;
      retain trans_w_cah trans_w_cancer trans_w_excl_mdc trans_w_excl_readmsn;
      
      if first.transfer_id then do;
         trans_w_cah = 0;
         trans_w_cancer = 0;
         trans_w_excl_mdc = 0;
         trans_w_excl_readmsn = 0;
      end;
      if (cah_flag = 1) then trans_w_cah = 1;
      if (cancer_hosp_flag = 1) then trans_w_cancer = 1;
      if (excl_mdc = 1) then trans_w_excl_mdc = 1;
      if (excl_readmsn = 1) then trans_w_excl_readmsn = 1;
      
      if last.transfer_id then do;
         if (trans_w_cah = 1) or (trans_w_cancer = 1) then output temp.transfers_w_cah_cancer;
         if (trans_w_excl_mdc = 1) or (trans_w_excl_readmsn = 1) then output temp.transfers_w_excl_drg_mdc;
      end;

   run;

   /*CREATE EXCLUSION FLAGS FOR CANDIDATE EPISODES*/
   
   *create flags incdicating exclusion reasons for an episode;
   data temp.episodes_w_dropflags (drop = rc_: %do year = %eval(&query_start_year.-1) %to &query_end_year.; enr_&year. %end; esrd_start_dt esrd_end_dt other_pp_start_dt other_pp_end_dt claimno_j1 lineitem_j1 excl_trans_stay excl_drg_trans_stay
                                                          CCN demo_start_date demo_end_date model_start_date);

      length dropflag_not_cont_enr_ab_no_c dropflag_no_bene_enr_info dropflag_death_dur_anchor death_dur_postdschrg death_dur_postepi dropflag_esrd dropflag_other_primary_payer dropflag_los_gt_%eval(&max_stay_length.-1)
             dropflag_non_ach dropflag_excluded_state dropflag_lvad dropflag_remap_drg dropflag_non_highest_j1 dropflag_trans_w_cah_cancer drop_episode episode_in_study_period dropflag_rch_demo dropflag_rural_pa dropflag_mdc dropflag_trans_w_exc_drg_mdc final_episode 8.;
      if _n_ = 1 then do;

         *uber information dataset;
         if 0 then set temp.bene_finder (keep = link_id bene_sex_race_cd bene_birth_dt bene_death_dt enr_: orig_mscd curhic_uneq);
         declare hash getbene (dataset: "temp.bene_finder (keep = link_id bene_sex_race_cd bene_birth_dt bene_death_dt enr_: orig_mscd curhic_uneq)");
         getbene.definekey("link_id");
         getbene.definedata("bene_sex_race_cd", "bene_birth_dt", "bene_death_dt", %do year = %eval(&query_start_year.-1) %to &query_end_year.; "enr_&year.", %end; "orig_mscd", "curhic_uneq");
         getbene.definedone();

         *esrd dataset;
         if 0 then set temp.esrd (keep = link_id esrd_start_dt esrd_end_dt);
         declare hash getesrd (dataset: "temp.esrd (keep = link_id esrd_start_dt esrd_end_dt)", multidata: "y");
         getesrd.definekey("link_id");
         getesrd.definedata("esrd_start_dt", "esrd_end_dt");
         getesrd.definedone();

         *primary payer dataset;
         if 0 then set temp.primary_payer (keep = link_id other_pp_start_dt other_pp_end_dt);
         declare hash getprim (dataset: "temp.primary_payer (keep = link_id other_pp_start_dt other_pp_end_dt)", multidata: "y");
         getprim.definekey("link_id");
         getprim.definedata("other_pp_start_dt", "other_pp_end_dt");
         getprim.definedone();

         *list of status codes to exclude;
         if 0 then set temp.excluded_status_codes (keep = stus_cd);
         declare hash excl_stus (dataset: "temp.excluded_status_codes (keep = stus_cd)");
         excl_stus.definekey("stus_cd");
         excl_stus.definedone();

         *list of highest primary ranking J1 line for each claim;
         if 0 then set temp.high_rank_j1_dedup (keep = link_id anchor_claimno anchor_lineitem claimno lineitem c_apc_flag j1_flag rename = (claimno = claimno_j1 lineitem = lineitem_j1));
         declare hash prim_rank (dataset: "temp.high_rank_j1_dedup (keep = link_id anchor_claimno anchor_lineitem claimno lineitem c_apc_flag j1_flag rename = (claimno = claimno_j1 lineitem = lineitem_j1))");
         prim_rank.definekey("link_id", "anchor_claimno", "anchor_lineitem");
         prim_rank.definedata("claimno_j1", "lineitem_j1", "c_apc_flag", "j1_flag");
         prim_rank.definedone();

         *list of all final leg IP stays where a CAH/cancer hospital was involved in the transfer at some point;
         if 0 then set temp.transfers_w_cah_cancer (keep = ip_stay_id rename = (ip_stay_id = excl_trans_stay));
         declare hash excl_trans (dataset: "temp.transfers_w_cah_cancer (keep = ip_stay_id rename = (ip_stay_id = excl_trans_stay))");
         excl_trans.definekey("excl_trans_stay");
         excl_trans.definedone();
        
         *list of overlap rural community hospitals;
         if 0 then set temp.overlap_rural_ccn (keep = CCN demo_start_date demo_end_date);
         declare hash rch_hos (dataset: "temp.overlap_rural_ccn (keep = CCN demo_start_date demo_end_date)");
         rch_hos.definekey("CCN");
         rch_hos.definedata("demo_start_date", "demo_end_date");
         rch_hos.definedone();

         *list of PA rural health hospitals;
         if 0 then set temp.pa_rural_health_hospital (keep = CCN model_start_date);
         declare hash pa_hos (dataset: "temp.pa_rural_health_hospital (keep = CCN model_start_date)");
         pa_hos.definekey("CCN");
         pa_hos.definedata("model_start_date");
         pa_hos.definedone();
         
         *list of MDC to be excluded;
         if 0 then set temp.excluded_mdc (keep = mdc);
         declare hash h_mdc (dataset: "temp.excluded_mdc (keep = mdc)");
         h_mdc.definekey("mdc");
         h_mdc.definedone();

         *list of all final leg IP stays where any transfer leg was an excluded MDC or DRG;
         if 0 then set temp.transfers_w_excl_drg_mdc (keep = ip_stay_id rename = (ip_stay_id = excl_drg_trans_stay));
         declare hash excl_trans_drg (dataset: "temp.transfers_w_excl_drg_mdc (keep = ip_stay_id rename = (ip_stay_id = excl_drg_trans_stay))");
         excl_trans_drg.definekey("excl_drg_trans_stay");
         excl_trans_drg.definedone();
         
         *add service line group;
         if 0 then set temp.service_line (keep = service_line_group episode_group_name episode_group_id);
         declare hash srvc_line (dataset: "temp.service_line (keep = service_line_group episode_group_name episode_group_id)");
         srvc_line.definekey("episode_group_name", "episode_group_id");
         srvc_line.definedata("service_line_group");
         srvc_line.definedone();

      end;
      call missing(of _all_);

      set temp.all_anchors;

      *create a unique episode identifier;
      retain episode_id;
      if _n_ = 1 then episode_id = 1;
      else episode_id = episode_id + 1;

      *initialize flags;
      dropflag_not_cont_enr_ab_no_c = 0;
      dropflag_no_bene_enr_info = 0;
      dropflag_death_dur_anchor = 0; 
      death_dur_postdschrg = 0;
      death_dur_postepi = 0;
      dropflag_esrd = 0;
      dropflag_other_primary_payer = 0;
      dropflag_los_gt_%eval(&max_stay_length.-1) = 0;
      dropflag_non_ach = 0;
      dropflag_excluded_state = 0;
      dropflag_non_highest_j1 = 0;
      dropflag_trans_w_cah_cancer = 0;
      drop_episode = 0;
      episode_in_study_period = 0;
      dropflag_rch_demo = 0;
      dropflag_rural_pa = 0;
      dropflag_mdc = 0;
      dropflag_trans_w_exc_drg_mdc = 0;
      
      if getbene.find(key: link_id) = 0 then do;

         if (not missing(bene_death_dt)) then do;
            *flag if beneficiary died during the anchor hospitalization;
            if (anchor_beg_dt <= bene_death_dt <= anchor_end_dt) then dropflag_death_dur_anchor = 1;
            *flag if beneficiary died during the post-discharge period;
            *set the end of the post-discharge period to the date of death for exclusion purpose and this will be changed back in last step;
            else if (post_dsch_beg_dt <= bene_death_dt <= post_dsch_end_dt) then do;
               death_dur_postdschrg = 1;
               post_dsch_end_dt = bene_death_dt;
               call missing(post_epi_beg_dt, post_epi_end_dt);
            end;
            *flag if beneficiary died during the post-episode period;
            else if (post_epi_beg_dt <= bene_death_dt <= post_epi_end_dt) then do;
               death_dur_postepi = 1;
               post_epi_end_dt = bene_death_dt;
            end;
         end;

         *flag if beneficiary is not continuously enrolled in Medicare Part A and B for entire episode period;
         enr_string_%eval(&query_start_year.-1)_&query_end_year. = catt(of enr_%eval(&query_start_year.-1)-enr_&query_end_year.);
         enr_start = (year(anchor_lookback_dt) - %eval(&query_start_year.-1))*12 + month(anchor_lookback_dt);
         enr_end = (year(post_dsch_end_dt) - %eval(&query_start_year.-1))*12 + month(post_dsch_end_dt);
         if (enr_start >= 1) then do;
            if lengthn(compress(substr(enr_string_%eval(&query_start_year.-1)_&query_end_year., enr_start, (enr_end - enr_start) + 1), "&part_a_b_codes.")) ^= 0 then dropflag_not_cont_enr_ab_no_c = 1;
         end;

      end;
      else dropflag_no_bene_enr_info = 1;

      *flag if contains a listed exclusion status code;
      if (excl_stus.find(key: stus_cd) = 0) then dropflag_death_dur_anchor = 1;

      *flag if beneficiary is enrolled in Medicare on the basis of ESRD;
      if getesrd.find(key: link_id) = 0 then do;
         rc_getesrd = 0;
         do while (rc_getesrd = 0);
            if not missing(esrd_start_dt) and missing(esrd_end_dt) then esrd_end_dt = "&sysdate."D;
            if (anchor_lookback_dt <= esrd_start_dt <= post_dsch_end_dt) or
               (anchor_lookback_dt <= esrd_end_dt <= post_dsch_end_dt) or
               (esrd_start_dt <= anchor_lookback_dt <= esrd_end_dt) or
               (esrd_start_dt <= post_dsch_end_dt <= esrd_end_dt)
            then dropflag_esrd = 1;
            if (dropflag_esrd = 1) then rc_getesrd = 1;
            else rc_getesrd = getesrd.find_next();
         end;
      end;

      *flag if Medicare is not the primary payer;
      if (anchor_clm_prpay > 0) then dropflag_other_primary_payer = 1;
      else if getprim.find(key: link_id) = 0 then do;
         rc_getprim = 0;
         do while (rc_getprim = 0);
            if not missing(other_pp_start_dt) and missing(other_pp_end_dt) then other_pp_end_dt = "&sysdate."D;
            if (anchor_lookback_dt <= other_pp_start_dt <= post_dsch_end_dt) or
               (anchor_lookback_dt <= other_pp_end_dt <= post_dsch_end_dt) or
               (other_pp_start_dt <= anchor_lookback_dt <= other_pp_end_dt) or
               (other_pp_start_dt <= post_dsch_end_dt <= other_pp_end_dt)
            then dropflag_other_primary_payer = 1;
            if (dropflag_other_primary_payer = 1) then rc_getprim = 1;
            else rc_getprim = getprim.find_next();
         end;
      end;

      *flag if provider of episode is from an excluded state (e.g. Maryland);
      if (anchor_state_flag = 1) then dropflag_excluded_state = 1;

      *flag as non-acute care hospital if provider is not an IPPs hospital;
      *NOTE: definition of ACH should be apply to both IP and OP based episodes;
      if (anchor_ipps_flag ^= 1) or 
         (anchor_cancer_hosp_flag = 1) or
         (anchor_cah_flag = 1) or
         (anchor_emerg_hosp_flag = 1) or
         (anchor_veteran_hosp_flag = 1) 
      then dropflag_non_ach = 1;

      if (lowcase(anchor_type) = "ip") then do;

         *flag if length of ip stay is greater than the maximum allowable stay length;
         if (anchor_length_of_stay > %eval(&max_stay_length.-1)) then dropflag_los_gt_%eval(&max_stay_length.-1) = 1;

         *flag if an IP episode was involved in a transfer where a CAH or cancer hospital was a part of that transfer at some point;
         if (excl_trans.find(key: anchor_stay_id) = 0) then dropflag_trans_w_cah_cancer = 1;

         *flag if an IP episode had any transfer leg asssociated with an excluded DRG or MDC;
         if (excl_trans_drg.find(key: anchor_stay_id) = 0) then dropflag_trans_w_exc_drg_mdc = 1;

      end;

      *flag if OP trigger line is not the highest ranking J1 line in its respective claim;
      *NOTE: if there are multiple OP lines that tie for the highest J1 ranking, then still keep the triggering OP line;
      if (lowcase(anchor_type) = "op") then do;
         if (prim_rank.find(key: link_id, key: anchor_claimno, key: anchor_lineitem) = 0) then do;
            *if the OP episode exists in a C-APC world then it must have a J1 status indicator and a the highest J1 ranking;
            *if the OP episode exists in a non-C-APC world then it does not need to have a J1 status indicator, just the highest ranking;
            if ((anchor_claimno = claimno_j1) and (anchor_lineitem = lineitem_j1)) and
               (((c_apc_flag = 1) and (j1_flag = 1)) or (c_apc_flag = 0))
            then dropflag_non_highest_j1 = 0;
            else dropflag_non_highest_j1 = 1;
         end;
      end;
      
      *flag if provider is overlap rural community hospital;
      if (not missing(anchor_provider)) then do;
         if (rch_hos.find(key: anchor_provider) = 0) then do;
            if (anchor_beg_dt <= demo_start_date <= post_dsch_end_dt) or
               (anchor_beg_dt <= demo_end_date <= post_dsch_end_dt) or
               (demo_start_date <= anchor_beg_dt <= demo_end_date) or
               (demo_start_date <= post_dsch_end_dt <= demo_end_date)
            then dropflag_rch_demo = 1;
         end;
      end;

      *flag if provider is PA rural health hospital;
      if (not missing(anchor_provider)) then do;
         if (pa_hos.find(key: anchor_provider) = 0) and (missing(model_start_date) or anchor_beg_dt >= model_start_date) then dropflag_rural_pa = 1;
      end;
      
      *exclude IP stays with an excluded MDC;
      if (h_mdc.find(key: mdc) = 0) then dropflag_mdc = 1;
      
      *add service line group;
      if srvc_line.find(key: upcase(strip(episode_group_name)), key: episode_group_id) ^= 0 then call missing(service_line_group);

      *create overall drop flag to indicate if any dropflag reasons apply;
      if (dropflag_not_cont_enr_ab_no_c = 1) or
         (dropflag_no_bene_enr_info = 1) or
         (dropflag_death_dur_anchor = 1) or
         (dropflag_esrd = 1) or
         (dropflag_other_primary_payer = 1) or
         (dropflag_los_gt_%eval(&max_stay_length.-1) = 1) or
         (dropflag_non_ach = 1) or
         (dropflag_excluded_state = 1) or
         (dropflag_non_highest_j1 = 1) or
         (dropflag_trans_w_cah_cancer = 1) or
         (dropflag_rch_demo = 1) or
         (dropflag_rural_pa = 1) or
         (dropflag_mdc = 1) or 
         (dropflag_trans_w_exc_drg_mdc = 1)
      then drop_episode = 1;

      *determine if episode is within the study period;
      if ("&baseline_start_dt."D <= anchor_end_dt <= "&baseline_end_dt."D) then episode_in_study_period = 1;

      if (drop_episode = 0) and (episode_in_study_period = 1) then final_episode = 1;
      else final_episode = 0;
      

      output temp.episodes_w_dropflags;

   run;

%mend; 