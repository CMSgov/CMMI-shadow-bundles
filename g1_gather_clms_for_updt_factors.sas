/*************************************************************************;
%** PROGRAM: g1_gather_clms_for_updt_factors.sas
%** PURPOSE: To gather claims to be used for calculating the update factors 
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro g1_gather_clms_for_updt_factors();

   *create a finder file containing all grouped claims to episode window;
   data temp.hh_group_clms_finder
        temp.sn_group_clms_finder
        temp.ip_group_clms_finder
        temp.pb_group_clms_finder;

      set temp.all_grp_clms_to_epi (keep = episode_id link_id anchor_beg_dt anchor_end_dt anchor_provider anchor_trigger_cd anchor_type claimno lineitem ip_stay_id std_cost_: file_type cost_category
                                     where = (((lowcase(file_type) in ("ip" "sn" "pb") and "&baseline_start_dt."D <= anchor_end_dt <= "&baseline_end_dt."D) or 
                                               (lowcase(file_type) in ("hh") and "&baseline_start_dt."D <= anchor_end_dt <= "&baseline_end_dt."D)) and 
                                               (lowcase(cost_category) not in ("post-episode period" "prorated - post-episode period only")))
                                               );

      if (lowcase(file_type) in ("hh")) then output temp.hh_group_clms_finder;
      else if (lowcase(file_type)  = "sn") then output temp.sn_group_clms_finder;
      else if (lowcase(file_type) = "ip") and (lowcase(cost_category) ^= "anchor period") then output temp.ip_group_clms_finder; %*NOTE: only grab the non-anchor claims (i.e. the post-discharge or post-episode claims) for IP here. the anchor IP cost will be grabbed in the next step;
      else if (lowcase(file_type) = "pb") then output temp.pb_group_clms_finder;

   run;

   data temp.grp_hh_for_updates (keep = link_id episode_id episode_group_name anchor_beg_dt anchor_end_dt anchor_provider anchor_trigger_cd anchor_type anchor_standard_allowed_amt claimno sgmt_num hh_from_dt hh_thru_dt std_cost_: apcpps: rvcntr: rvunt: hcpscd: visitcnt division_name state_abbr state_name
                                                     division_code division_name payment_amt lupa_flag anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag tot_std_allowed tot_post_epi_std_allowed)
        temp.grp_ip_for_updates (keep = link_id episode_id episode_group_name anchor_beg_dt anchor_end_dt anchor_provider anchor_trigger_cd anchor_type anchor_standard_allowed_amt drg_cd std_cost_: ipps_flag state_flag cancer_hosp_flag irf_flag anchor_ipps_flag anchor_state_flag anchor_c_apc_flag 
                                                     perf_c_apc_flag comp_adj_apc_flag anchor_cancer_hosp_flag anchor_irf_flag provider service_start_dt service_end_dt std_cost_: drg_: division_name state_abbr state_name division_code division_name drg_code discharge_dt irf_claim payment_amt trigger_ip
                                                     tot_std_allowed tot_post_epi_std_allowed)
        temp.grp_op_for_updates (keep = link_id episode_id episode_group_name anchor_beg_dt anchor_end_dt anchor_provider anchor_trigger_cd anchor_claimno anchor_lineitem anchor_type anchor_standard_allowed_amt tot_std_allowed comp_adj_apc_flag anchor_apc anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag
                                                     tot_std_allowed tot_post_epi_std_allowed)
        temp.grp_sn_for_updates (keep = link_id episode_id episode_group_name anchor_beg_dt anchor_end_dt anchor_provider anchor_trigger_cd anchor_type anchor_standard_allowed_amt claimno sgmt_num provider std_cost_: rvcntr: rvunt: hcpscd: division_name state_abbr state_name division_code division_name payment_amt
                                                     anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag tot_std_allowed tot_post_epi_std_allowed)
        temp.grp_pb_for_updates (keep = link_id episode_id episode_group_name anchor_beg_dt anchor_end_dt anchor_provider anchor_trigger_cd anchor_type anchor_standard_allowed_amt claimno lineitem standard_allowed_amt hcpcs_cd std_cost_: betos carr_num lclty_cd plcsrvc mdfr_cd: anchor_c_apc_flag 
                                                     perf_c_apc_flag comp_adj_apc_flag division_name state_abbr state_name division_code division_name payment_amt tot_std_allowed tot_post_epi_std_allowed)
        temp.all_anchors_for_updates (keep = episode_id link_id episode_group_name anchor_beg_dt anchor_end_dt anchor_type anchor_provider anchor_trigger_cd anchor_standard_allowed_amt anchor_ipps_flag anchor_state_flag anchor_cancer_hosp_flag anchor_irf_flag tot_std_allowed tot_post_epi_std_allowed
                                                          drg_: tot_std_allowed division_name state_abbr state_name division_code division_name anchor_c_apc_flag perf_c_apc_flag);
      
      length drg_code $3. discharge_dt irf_claim payment_amt 8.;
      format discharge_dt date9.;
      if _n_ = 1 then do;

         *final set of episodes in the baseline period;
         if 0 then set temp.episodes_w_costs (keep = episode_id anchor_end_dt final_episode tot_std_allowed tot_post_epi_std_allowed drop_episode where = ((drop_episode = 0) and ("&baseline_start_dt."D <= anchor_end_dt <= "&baseline_end_dt."D)));
         declare hash epis (dataset: "temp.episodes_w_costs (keep = episode_id anchor_end_dt final_episode tot_std_allowed tot_post_epi_std_allowed drop_episode where = ((drop_episode = 0) and ('&baseline_start_dt.'D <= anchor_end_dt <= '&baseline_end_dt.'D)))");
         epis.definekey("episode_id");
         epis.definedata("tot_std_allowed", "tot_post_epi_std_allowed");
         epis.definedone();

         *list of all hh claims grouped to episodes occuring in the baseline period;
         if 0 then set temp.hh_group_clms_finder (keep = episode_id link_id claimno std_cost_anchor std_cost_post_dsch std_cost_post_epi);
         declare hash hh_finder (dataset: "temp.hh_group_clms_finder (keep = episode_id link_id claimno std_cost_anchor std_cost_post_dsch std_cost_post_epi)");
         hh_finder.definekey("episode_id", "link_id", "claimno");
         hh_finder.definedata("std_cost_anchor", "std_cost_post_dsch", "std_cost_post_epi");
         hh_finder.definedone();

         *list of all sn claims grouped to episodes occuring in the baseline period;
         if 0 then set temp.sn_group_clms_finder (keep = episode_id link_id claimno std_cost_anchor std_cost_post_dsch std_cost_post_epi);
         declare hash sn_finder (dataset: "temp.sn_group_clms_finder (keep = episode_id link_id claimno std_cost_anchor std_cost_post_dsch std_cost_post_epi)");
         sn_finder.definekey("episode_id", "link_id", "claimno");
         sn_finder.definedata("std_cost_anchor", "std_cost_post_dsch", "std_cost_post_epi");
         sn_finder.definedone();

         *list of all ip claims grouped to episodes occuring in the baseline period;
         if 0 then set temp.ip_group_clms_finder (keep = episode_id link_id ip_stay_id std_cost_anchor std_cost_post_dsch std_cost_post_epi);
         declare hash ip_finder (dataset: "temp.ip_group_clms_finder (keep = episode_id link_id ip_stay_id std_cost_anchor std_cost_post_dsch std_cost_post_epi)");
         ip_finder.definekey("episode_id", "link_id", "ip_stay_id");
         ip_finder.definedata("std_cost_anchor", "std_cost_post_dsch", "std_cost_post_epi");
         ip_finder.definedone();

         *list of all pb claims grouped to episodes occuring in the baseline period;
         if 0 then set temp.pb_group_clms_finder (keep = episode_id link_id claimno lineitem std_cost_anchor std_cost_post_dsch std_cost_post_epi);
         declare hash pb_finder (dataset: "temp.pb_group_clms_finder (keep = episode_id link_id claimno lineitem std_cost_anchor std_cost_post_dsch std_cost_post_epi)");
         pb_finder.definekey("episode_id", "link_id", "claimno", "lineitem");
         pb_finder.definedata("std_cost_anchor", "std_cost_post_dsch", "std_cost_post_epi");
         pb_finder.definedone();

         *crosswalk of CCN codes to state;
         if 0 then set temp.ccn_state_codes (keep = ccn_code state_abbr state_name);
         declare hash ccn_state_cd (dataset: "temp.ccn_state_codes (keep = ccn_code state_abbr state_name)");
         ccn_state_cd.definekey("ccn_code");
         ccn_state_cd.definedata("state_abbr", "state_name");
         ccn_state_cd.definedone();

         *crosswalk of state abbreviation to census region;
         if 0 then set temp.state_to_census_reg (keep = state_abbr division_code division_name);
         declare hash cens_region (dataset: "temp.state_to_census_reg (keep = state_abbr division_code division_name)");
         cens_region.definekey("state_abbr");
         cens_region.definedata("division_code", "division_name");
         cens_region.definedone();

      end;
      call missing(of _all_);

      *all HH, IP, SN, PB claims occuring in the baseline period;
      set temp.hh_clms_to_epi (keep = episode_id link_id episode_group_name anchor_beg_dt anchor_end_dt anchor_provider anchor_trigger_cd anchor_type anchor_standard_allowed_amt claimno sgmt_num from_dt thru_dt apcpps: rvcntr: rvunt: hcpscd: visitcnt service_start_dt service_end_dt standard_allowed_amt lupa_flag 
                                             anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag  rename=(from_dt=hh_from_dt thru_dt=hh_thru_dt)
                                      where = ("&baseline_start_dt."D <= anchor_end_dt <= "&baseline_end_dt."D)
                                      in = in_hh)
          temp.ip_clms_to_epi (keep = episode_id link_id episode_group_name anchor_beg_dt anchor_end_dt anchor_provider anchor_trigger_cd anchor_type anchor_standard_allowed_amt ip_stay_id drg_: ipps_flag state_flag cancer_hosp_flag irf_flag provider service_start_dt service_end_dt 
                                      standard_allowed_amt anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag
                               where = ("&baseline_start_dt."D <= anchor_end_dt <= "&baseline_end_dt."D)
                               in = in_ip)
          temp.sn_clms_to_epi (keep = episode_id link_id episode_group_name anchor_beg_dt anchor_end_dt anchor_provider anchor_trigger_cd anchor_type anchor_standard_allowed_amt claimno sgmt_num provider rvcntr: rvunt: hcpscd: service_start_dt service_end_dt standard_allowed_amt 
                                      anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag
                               where = ("&baseline_start_dt."D <= anchor_end_dt <= "&baseline_end_dt."D)
                               in = in_sn)
          temp.pb_clms_to_epi (keep = episode_id link_id episode_group_name anchor_beg_dt anchor_end_dt anchor_provider anchor_trigger_cd anchor_type anchor_standard_allowed_amt claimno lineitem service_start_dt service_end_dt standard_allowed_amt hcpcs_cd betos carr_num lclty_cd plcsrvc mdfr_cd:
                                      anchor_c_apc_flag perf_c_apc_flag comp_adj_apc_flag
                               where = ("&baseline_start_dt."D <= anchor_end_dt <= "&baseline_end_dt."D)
                               in = in_pb)
          temp.episodes_w_costs (keep = episode_id link_id episode_group_name anchor_beg_dt anchor_end_dt anchor_type anchor_provider anchor_trigger_cd anchor_standard_allowed_amt final_episode anchor_ipps_flag anchor_state_flag anchor_cancer_hosp_flag anchor_irf_flag drg_:
                                        tot_std_allowed tot_post_epi_std_allowed anchor_stay_id anchor_claimno anchor_lineitem comp_adj_apc_flag anchor_apc anchor_c_apc_flag perf_c_apc_flag
                                 where = ((final_episode = 1) and ("&baseline_start_dt."D <= anchor_end_dt <= "&baseline_end_dt."D))
                                 in = in_all_anchor);

      *crosswalk division and states;
      if (ccn_state_cd.find(key: substr(anchor_provider, 1, 2)) = 0) then do;
         rc_cens_region = cens_region.find(key: state_abbr);
      end;

      *filter to grouped claims belonging to the final set of episodes;
      *NOTE: the reason we need to go to the dataset containing all possible claims to episode and then filter down to grouped claims belonging to final episodes rather than use the all_grp_clms_to_epi_: dataset to begin with is because information on claims with segment number;
      *      greater than 1 are necessary but not kept in the construction of the all_grp_clms_to_epi dataset;
       if ((in_hh = 1) or (in_ip = 1) or (in_sn = 1) or (in_pb = 1)) and (epis.find(key: episode_id) = 0) then do;
          if ((in_hh = 1) and (hh_finder.find(key: episode_id, key: link_id, key: claimno) = 0)) or
             ((in_sn = 1) and (sn_finder.find(key: episode_id, key: link_id, key: claimno) = 0)) or
             ((in_ip = 1) and (ip_finder.find(key: episode_id, key: link_id, key: ip_stay_id) = 0)) or
             ((in_pb = 1) and (pb_finder.find(key: episode_id, key: link_id, key: claimno, key: lineitem) = 0)) 
          then do;
            payment_amt = sum(std_cost_anchor, std_cost_post_dsch);
            if (in_hh = 1) then output temp.grp_hh_for_updates;
            else if (in_ip = 1) then do;
               trigger_ip = 0;
               drg_code = drg_cd;
               discharge_dt = service_end_dt;
               if (irf_flag = 1) then irf_claim = 1;
               else irf_claim = 0;
               output temp.grp_ip_for_updates;
            end;
            else if (in_sn = 1) then output temp.grp_sn_for_updates;
            else if (in_pb = 1) then output temp.grp_pb_for_updates;
          end;
       end;
       else if (in_all_anchor = 1) then do;
          output temp.all_anchors_for_updates;
          if (lowcase(anchor_type) = "ip") then do;
             trigger_ip = 1;
             drg_code = anchor_trigger_cd;
             discharge_dt = anchor_end_dt;
             irf_claim = 0;
             payment_amt = anchor_standard_allowed_amt;
             output temp.grp_ip_for_updates;
          end;
          else if (lowcase(anchor_type) = "op") then output temp.grp_op_for_updates;
       end;

   run;
   
%mend; 
