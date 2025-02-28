/*************************************************************************;
%** PROGRAM: c5_trigger_anchor_op.sas
%** PURPOSE: To identify OP lines that can potentially trigger BPCI-A episodes 
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro c5_trigger_anchor_op();

   /*TRIGGER OP ANCHORS*/
   
   *find all opl claim lines with a triggering hcpcs code;
   data temp.triggered_op_hcpcs (drop = %do a = 1 %to &nflag_vars.; &&flag_vars&a.._flag %end; missing_provider_flag)
        temp.excluded_non_positive_op
        temp.excluded_miss_rev_dt_op;

      length anchor_type $5. anchor_stay_id anchor_claimno anchor_lineitem transfer_stay 8. anchor_provider $6. anchor_beg_dt anchor_end_dt anchor_lookback_dt post_dsch_beg_dt post_dsch_end_dt post_dsch_end_dt_&post_dschrg_days. post_epi_beg_dt post_epi_end_dt 8.
             anchor_trigger_cd $5. anchor_at_npi anchor_op_npi $10. %do a = 1 %to &nflag_vars.; anchor_&&flag_vars&a.._flag %end; anchor_missing_provider_flag 8. anchor_num_ip_transfers anchor_tran_standard_allowed_amt anchor_tran_allowed_amt anchor_tran_clm_prpay
             anchor_standard_allowed_amt anchor_allowed_amt anchor_clm_prpay anchor_length_of_stay 8. attr_start_dt attr_end_dt 8.;
      format anchor_beg_dt anchor_end_dt anchor_lookback_dt post_dsch_beg_dt post_dsch_end_dt post_dsch_end_dt_&post_dschrg_days. post_epi_beg_dt post_epi_end_dt date9. anchor_claimno comma22. attr_start_dt attr_end_dt date9.;
      if _n_ = 1 then do;

         *list of BPCI episode trigger codes;
         if 0 then set temp.op_anchor_episode_list (keep = episode_group_name episode_group_id hcpcs_cd);
         declare hash trig_hcpcs (dataset: "temp.op_anchor_episode_list (keep = episode_group_name episode_group_id hcpcs_cd");
         trig_hcpcs.definekey("hcpcs_cd");
         trig_hcpcs.definedata("episode_group_name", "episode_group_id");
         trig_hcpcs.definedone();

      end;

      set temp.opl;

      if (missing(rev_dt)) then output temp.excluded_miss_rev_dt_op;

      *only claim lines with a positive standardized allowed amount are allowed to trigger an episode;
      if (line_std_allowed <= 0) then output temp.excluded_non_positive_op;
      else if (line_std_allowed > 0) and (not missing(rev_dt)) then do;

         if (trig_hcpcs.find(key: hcpcs_cd) = 0) then do;

            anchor_type = "op";
            call missing(anchor_stay_id);
            anchor_claimno = claimno;
            anchor_lineitem = lineitem;
            *set all transfer related variable to zero since these variables only apply to ip based anchors;
            transfer_stay = 0;
            anchor_num_ip_transfers = 0;
            anchor_tran_standard_allowed_amt = 0;
            anchor_tran_allowed_amt = 0;
            anchor_tran_clm_prpay = 0;
            anchor_provider = provider;
            *the rev_dt marks the start and end of the anchor period when in outpatient setting since outpatient anchors are always one day long;
            anchor_beg_dt = rev_dt;
            anchor_end_dt = rev_dt;
            anchor_lookback_dt = rev_dt - &lookback_days.;
            post_dsch_beg_dt = anchor_end_dt;
            post_dsch_end_dt = post_dsch_beg_dt + %eval(&post_dschrg_days. - 1);
            post_dsch_end_dt_&post_dschrg_days. = post_dsch_beg_dt + %eval(&post_dschrg_days. - 1);
            post_epi_beg_dt = post_dsch_end_dt + 1;
            post_epi_end_dt = post_epi_beg_dt + %eval(&post_epi_days.  - 1);
            anchor_trigger_cd = hcpcs_cd;
            anchor_at_npi = at_npi;
            anchor_op_npi = op_npi;
            %do a = 1 %to &nflag_vars.;
               anchor_&&flag_vars&a.._flag = &&flag_vars&a.._flag;
            %end;
            anchor_missing_provider_flag = missing_provider_flag;
            anchor_standard_allowed_amt = line_std_allowed;
            anchor_allowed_amt = line_allowed;
            anchor_clm_prpay = sum(rev_msp1, rev_msp2);
            anchor_length_of_stay = max((anchor_beg_dt - anchor_end_dt), 1);
            attr_start_dt = rev_dt - &attr_lookback_days.;
            attr_end_dt = rev_dt;

            output temp.triggered_op_hcpcs;

         end;

      end;

   run;

   *sort claims so that the ones with the highest standardized cost is at the top;
   proc sort data = temp.triggered_op_hcpcs;
      by link_id rev_dt descending line_std_allowed descending daily_dt descending rev_chrg claimno lineitem;
   run;

   *for cases where multiple triggering hcpcs codes are found on the same day for the same beneficiary, break ties by as follows:
      *1/ choose the OP line with the higher standardzied allowed amount;
      *2/ choose the OP line with the later processing date (i.e daily_dt);
      *3/ choose the OP line with the higher revenue charge amount;
      *4/ choose by claimno and lineitem;
   data temp.op_anchors 
        temp.excluded_same_day_op;

      set temp.triggered_op_hcpcs;
      by link_id rev_dt descending line_std_allowed descending daily_dt descending rev_chrg claimno lineitem;
      if first.rev_dt then output temp.op_anchors;
      else output temp.excluded_same_day_op;

   run;


   /*MAP HCPCS TO APC*/

   *create a crosswalk of anchor OP lines to their corresponding secondary/add-on HCPCS;
   data temp.op_anchors_w_sec_hcpcs (keep = link_id anchor_claimno anchor_lineitem anchor_trigger_cd claimno lineitem secondary_hcpcs_code)
        temp.op_anchors_w_sec_hcpcs_perf (keep = link_id anchor_claimno anchor_lineitem anchor_trigger_cd claimno lineitem perf_sec_hcpcs_code)
        temp.op_w_j1_rankings (keep = link_id anchor_claimno anchor_lineitem anchor_trigger_cd anchor_beg_dt anchor_end_dt anchor_provider claimno lineitem prim_assign_rank line_std_allowed hcpcs_cd rev_dt rstusind rev_msp1 rev_msp2 trigger_line c_apc_flag j1_flag from_dt thru_dt);

      if _n_ = 1 then do;

         *list of anchoring OP lines;
         if 0 then set temp.op_anchors (keep = link_id anchor_claimno anchor_lineitem anchor_trigger_cd anchor_beg_dt anchor_end_dt anchor_provider);
         declare hash op_trig_line (dataset: "temp.op_anchors (keep = link_id anchor_claimno anchor_lineitem anchor_trigger_cd anchor_beg_dt anchor_end_dt anchor_provider)", multidata: "y");
         op_trig_line.definekey("link_id", "anchor_claimno");
         op_trig_line.definedata("anchor_claimno", "anchor_lineitem", "anchor_trigger_cd", "anchor_beg_dt", "anchor_end_dt", "anchor_provider");
         op_trig_line.definedone();

         *list of all trigger HCPCS that require a secondary/add-on HCPCS code to map to an complexity adjusted-APC;
         if 0 then set temp.hcpcs_to_apc_xwalk (keep = cy_year hcpcs_code sec_j1_add_on where = (not missing(sec_j1_add_on)));
         declare hash hcpcs_apc (dataset: "temp.hcpcs_to_apc_xwalk (keep = cy_year hcpcs_code sec_j1_add_on where = (not missing(sec_j1_add_on)))");
         hcpcs_apc.definekey("hcpcs_code", "cy_year", "sec_j1_add_on");
         hcpcs_apc.definedone();
         
         *list of all trigger HCPCS that require a secondary/add-on HCPCS code to map to an complexity adjusted-APC for performance year;
         if 0 then set temp.hcpcs_to_apc_xwalk (keep = cy_year hcpcs_code sec_j1_add_on where = ((cy_year = &update_factor_cy.) and (not missing(sec_j1_add_on))));
         declare hash perf_hcpcs_apc (dataset: "temp.hcpcs_to_apc_xwalk (keep = cy_year hcpcs_code sec_j1_add_on where = ((cy_year = &update_factor_cy.) and (not missing(sec_j1_add_on))))");
         perf_hcpcs_apc.definekey("hcpcs_code", "sec_j1_add_on");
         perf_hcpcs_apc.definedone();

         *list showing the years when a certain trigger HCPCS has transition to C-APC;
         if 0 then set temp.hcpcs_to_apc_dedup (keep = cy_year hcpcs_code is_c_apc);
         declare hash apc_years (dataset: "temp.hcpcs_to_apc_dedup (keep = cy_year hcpcs_code is_c_apc)");
         apc_years.definekey("hcpcs_code", "cy_year");
         apc_years.definedata("is_c_apc");
         apc_years.definedone();

         *list showing the ranking of primary assignment J1 HCPCS codes;
         if 0 then set temp.prim_assignment_rankings_&update_factor_cy. (keep = hcpcs_code prim_assign_rank status_ind);
         declare hash j1_ranks (dataset: "temp.prim_assignment_rankings_&update_factor_cy. (keep = hcpcs_code prim_assign_rank status_ind)");
         j1_ranks.definekey("hcpcs_code" );
         j1_ranks.definedata("prim_assign_rank", "status_ind");
         j1_ranks.definedone();

      end;
      call missing(of _all_);

      *NOTE: OP lines with zero line allowed payment are eligible to be a secondary HCPCS for mapping HCPCS-APC purposes;
      set temp.opl (keep = link_id claimno lineitem hcpcs_cd line_std_allowed rev_dt rstusind rev_msp1 rev_msp2 from_dt thru_dt where = ((line_std_allowed >= 0) and (not missing(rev_dt))));

      if (op_trig_line.find(key: link_id, key: claimno) = 0) then do;

         rc_op_trig_line = 0;
         do while (rc_op_trig_line = 0);

            *flag if the current line is the triggering OP line;
            if (lineitem = anchor_lineitem) then trigger_line = 1;
            else trigger_line = 0;

            *look through all the lineitems associated with the claimno of the anchoring OP line to see if any lineitem has a secondary/add-on HCPCS;
            if (trigger_line = 0) then do;
               if (hcpcs_apc.find(key: anchor_trigger_cd, key: year(anchor_end_dt), key: hcpcs_cd) = 0) then do;
                  secondary_hcpcs_code = hcpcs_cd;
                  output temp.op_anchors_w_sec_hcpcs;
               end;
            end;
            
            *look trough all the lineitems associated with the claimno of the anchoring OP line to see if any lineitem has a secondary/add-on HCPCS for performance year;
            if (trigger_line = 0) then do;
               if (perf_hcpcs_apc.find(key: anchor_trigger_cd, key: hcpcs_cd) = 0) then do;
                  perf_sec_hcpcs_code = hcpcs_cd;
                  output temp.op_anchors_w_sec_hcpcs_perf;
               end;
            end;

            *assign primary ranking to each line on the claim. this dataset will be needed later in determining exclusion of non-highest ranking J1 OP episodes;
            j1_flag = 0;
            if (j1_ranks.find(key: hcpcs_cd) = 0) then do;
               if (strip(rstusind) = strip(status_ind)) then j1_flag = 1; 
            end;
            c_apc_flag = 0;
            if (apc_years.find(key: anchor_trigger_cd, key: year(anchor_end_dt)) = 0) then do;
               if (lowcase(is_c_apc) = "y") then c_apc_flag = 1; 
            end;
            output temp.op_w_j1_rankings;

            rc_op_trig_line = op_trig_line.find_next();

         end;

      end;

   run;

   proc sort data = temp.op_anchors_w_sec_hcpcs;
      by link_id anchor_claimno anchor_lineitem;
   run;

   *make the prior crosswalk of secondary HCPCS wide so that the array of all secondary HCPCS found can be merged to the anchoring OP episode later on;
   data temp.sec_hcpcs_wide (keep = link_id anchor_claimno anchor_lineitem secondary_hcpcs_1-secondary_hcpcs_&sec_hcpcs_array_size.);

      set temp.op_anchors_w_sec_hcpcs;
      by link_id anchor_claimno anchor_lineitem;

      array secondary_hcpcs_{&sec_hcpcs_array_size.} $5.;
      retain secondary_hcpcs_1-secondary_hcpcs_&sec_hcpcs_array_size. counter;

      if first.anchor_lineitem then do;
         counter = 0;
         call missing(of secondary_hcpcs_1-secondary_hcpcs_&sec_hcpcs_array_size.);
      end;
      counter = counter + 1;
      secondary_hcpcs_{counter} = secondary_hcpcs_code;
      if last.anchor_lineitem then output temp.sec_hcpcs_wide;

   run;
   
   proc sort data = temp.op_anchors_w_sec_hcpcs_perf;
      by link_id anchor_claimno anchor_lineitem;
   run;
   
   *make the prior crosswalk of secondary HCPCS for performance year wide so that the array of all secondary HCPCS found can be merged to the anchoring OP episode later on;
   data temp.perf_sec_hcpcs_wide (keep = link_id anchor_claimno anchor_lineitem perf_sec_hcpcs_1-perf_sec_hcpcs_&sec_hcpcs_array_size.);

      set temp.op_anchors_w_sec_hcpcs_perf;
      by link_id anchor_claimno anchor_lineitem;

      array perf_sec_hcpcs_{&sec_hcpcs_array_size.} $5.;
      retain perf_sec_hcpcs_1-perf_sec_hcpcs_&sec_hcpcs_array_size. counter;

      if first.anchor_lineitem then do;
         counter = 0;
         call missing(of perf_sec_hcpcs_1-perf_sec_hcpcs_&sec_hcpcs_array_size.);
      end;
      counter = counter + 1;
      perf_sec_hcpcs_{counter} = perf_sec_hcpcs_code;
      if last.anchor_lineitem then output temp.perf_sec_hcpcs_wide;
   
   run;

   data temp.op_anchors (drop = hcpcs_code cy_year apc apc_payment_rate comp_adj_hcpcs comp_adj_apc comp_adj_apc_payment_rate is_c_apc rc_:);

      length anchor_apc $10. anchor_apc_pmt_rate 8. anchor_comp_adj_hcpcs $5. anchor_c_apc_flag 8. perf_apc $10. perf_apc_pmt_rate 8. perf_comp_adj_hcpcs $5. perf_c_apc_flag 8. comp_adj_apc_flag 8. perf_comp_adj_apc_flag 8.;
      if _n_ = 1 then do;

         *crosswalk of APC/APC payment rates by HCPCS and calendar year;
         if 0 then set temp.hcpcs_to_apc_dedup (keep = cy_year hcpcs_code apc apc_payment_rate comp_adj_hcpcs comp_adj_apc comp_adj_apc_payment_rate is_c_apc);
         declare hash hcpcs_apc (dataset: "temp.hcpcs_to_apc_dedup (keep = cy_year hcpcs_code apc apc_payment_rate comp_adj_hcpcs comp_adj_apc comp_adj_apc_payment_rate is_c_apc)");
         hcpcs_apc.definekey("hcpcs_code", "cy_year");
         hcpcs_apc.definedata("apc", "apc_payment_rate", "comp_adj_hcpcs", "comp_adj_apc", "comp_adj_apc_payment_rate", "is_c_apc");
         hcpcs_apc.definedone();

         *list of all secondary/add-on HCPCS associated with a triggering OP line;
         if 0 then set temp.sec_hcpcs_wide (keep = link_id anchor_claimno anchor_lineitem secondary_hcpcs_:);
         declare hash get_sec (dataset: "temp.sec_hcpcs_wide (keep = link_id anchor_claimno anchor_lineitem secondary_hcpcs_:)");
         get_sec.definekey("link_id", "anchor_claimno", "anchor_lineitem");
         get_sec.definedata(%do a = 1 %to &sec_hcpcs_array_size.; "secondary_hcpcs_&a." %if &a. ^= &sec_hcpcs_array_size. %then ,; %end;);
         get_sec.definedone();
         
         *list of all secondary/add-on HCPCS for performance year associated with a triggering OP line;
         if 0 then set temp.perf_sec_hcpcs_wide (keep = link_id anchor_claimno anchor_lineitem perf_sec_hcpcs_:);
         declare hash get_perf_sec (dataset: "temp.perf_sec_hcpcs_wide (keep = link_id anchor_claimno anchor_lineitem perf_sec_hcpcs_:)");
         get_perf_sec.definekey("link_id", "anchor_claimno", "anchor_lineitem");
         get_perf_sec.definedata(%do a = 1 %to &sec_hcpcs_array_size.; "perf_sec_hcpcs_&a." %if &a. ^= &sec_hcpcs_array_size. %then ,; %end;);
         get_perf_sec.definedone();

      end;
      call missing(of _all_);

      set temp.op_anchors;

      rc_hcpcs_apc = hcpcs_apc.find(key: anchor_trigger_cd, key: year(anchor_end_dt));

      *flag if trigger line meets the requirement (i.e. has the needed secondary/add-on HCPCS) for its APC and APC payment rate to be pushed to a complexity adjusted-APC category/complexity adjusted-APC payment rate;
      if (get_sec.find(key: link_id, key: anchor_claimno, key: anchor_lineitem) = 0) then comp_adj_apc_flag = 1;
      else comp_adj_apc_flag = 0;
      
      *flag if trigger line meets the requirement for performance year (i.e. has the needed secondary/add-on HCPCS) so that its APC and APC payment rate can be pushed to a complexity adjusted-APC category/complexity adjusted-APC payment rate;
      if (get_perf_sec.find(key: link_id, key: anchor_claimno, key: anchor_lineitem) = 0) then perf_comp_adj_apc_flag = 1;
      else perf_comp_adj_apc_flag = 0;

      *if the trigger line meets the requirement of a complexity adjusted-APC then assign it the complexity adjusted-APC payment rate and complexity adjusted HCPCS. otherwise, assign it the regular APC payment rate;
      if (comp_adj_apc_flag = 1) then do;
         anchor_apc = comp_adj_apc;
         anchor_apc_pmt_rate = comp_adj_apc_payment_rate;
         anchor_comp_adj_hcpcs = comp_adj_hcpcs;
         *flag if trigger HCPCS is a C-APC in the baseline year;
         if (lowcase(is_c_apc) = "y") then anchor_c_apc_flag = 1; else anchor_c_apc_flag = 0;
      end; %*end of baseline complexity adjusted assignment;
      else do;
         anchor_apc = apc;
         anchor_apc_pmt_rate = apc_payment_rate;
         call missing(anchor_comp_adj_hcpcs);
         *flag if trigger HCPCS is a C-APC in the baseline year;
         if (lowcase(is_c_apc) = "y") then anchor_c_apc_flag = 1; else anchor_c_apc_flag = 0;
      end; %*end of baseline regular assignment;
      
      *if the trigger line meets the requirement of a complexity adjusted-APC for performance year then assign it the complexity adjusted-APC payment rate and complexity adjusted HCPCS. otherwise, assign it the regular APC payment rate;
      if (perf_comp_adj_apc_flag = 1) then do;
         if (hcpcs_apc.find(key: anchor_trigger_cd, key: &update_factor_cy.) = 0) then do;
            perf_apc = comp_adj_apc;
            perf_apc_pmt_rate = comp_adj_apc_payment_rate;
            perf_comp_adj_hcpcs = comp_adj_hcpcs;
            *flag if trigger HCPCS is a C-APC in the performance year;
            if (lowcase(is_c_apc) = "y") then perf_c_apc_flag = 1; else perf_c_apc_flag = 0;
         end;
      end; %*end of performance complexity adjusted assignment;
      else do;
         if (hcpcs_apc.find(key: anchor_trigger_cd, key: &update_factor_cy.) = 0) then do;
            perf_apc = apc;
            perf_apc_pmt_rate = apc_payment_rate;
            call missing(perf_comp_adj_hcpcs);
            *flag if trigger HCPCS is a C-APC in the performance year;
            if (lowcase(is_c_apc) = "y") then perf_c_apc_flag = 1; else perf_c_apc_flag = 0;
         end;
      end; %*end of performance regular assignment;
      
   run;
   
%mend; 