/*************************************************************************;
%** PROGRAM: g3_calculate_opps_update_factor.sas
%** PURPOSE: To calculate OPPS update factor for anchor period cost
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

%macro g3_calculate_opps_update_factor();
   
   /*PROCESS OP LINES TO INCLUDE IN OPPS ANCHOR UPDATE FACTOR CALCULATION*/
   data temp.services_for_op_anchor_pmt (drop = status_ind_code included_in_opps cy_year cy_quarter)
        temp.all_lines_for_opps (drop = status_ind_code included_in_opps cy_year cy_quarter);

      if _n_ = 1 then do;

         *list of status indicators identifying which OP services to include in OP anchor payments;
         if 0 then set temp.opps_status_indicators (keep = status_ind_code included_in_opps where = (lowcase(included_in_opps) = "y"));
         declare hash incl_opps_si (dataset: "temp.opps_status_indicators (keep = status_ind_code included_in_opps where = (lowcase(included_in_opps) = 'y'))");
         incl_opps_si.definekey("status_ind_code");
         incl_opps_si.definedone();

         *list of status indicators identifying which OP services to exclude in OP anchor payments;
         if 0 then set temp.opps_status_indicators (keep = status_ind_code included_in_opps where = (lowcase(included_in_opps) = "n"));
         declare hash excl_opps_si (dataset: "temp.opps_status_indicators (keep = status_ind_code included_in_opps where = (lowcase(included_in_opps) = 'n'))");
         excl_opps_si.definekey("status_ind_code");
         excl_opps_si.definedone();

         *list of hemophilia/clotting factor drugs by year and quarter;
         %* _2 is the most updated version that is available at the time of running the program;         
         %do year = &query_start_year. %to &query_end_year.;
            %if &year. ^= &query_end_year. %then %do;
               %do quart = 1 %to 4;
                  %if &year. = 2019 and &quart. = 3 %then %do;
                     if 0 then set hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1));
                     declare hash drug&year.q&quart. (dataset: "hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1))");
                  %end;
                  %else %if &year. = 2019 and &quart. = 4 %then %do;
                     if 0 then set hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1));
                     declare hash drug&year.q&quart. (dataset: "hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1))");
                  %end;
                  %else %if &year. = 2020 and &quart. = 1 %then %do;
                     if 0 then set hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1));
                     declare hash drug&year.q&quart. (dataset: "hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1))");
                  %end;
                  %else %if &year. = 2020 and &quart. = 2 %then %do;
                     if 0 then set hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1));
                     declare hash drug&year.q&quart. (dataset: "hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1))");
                  %end;
                  %else %do;
                     if 0 then set hemos.part_b_drug_asp_&year.q&quart. (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1));
                     declare hash drug&year.q&quart. (dataset: "hemos.part_b_drug_asp_&year.q&quart. (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1))");
                  %end;
                  drug&year.q&quart..definekey("hcpcs_cd");
                  drug&year.q&quart..definedone();
               %end;
            %end;
            %else %do;
               %do quart = 1 %to &hemo_quart_end.;
                  if 0 then set hemos.part_b_drug_asp_&year.q&quart. (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1));
                  declare hash drug&year.q&quart. (dataset: "hemos.part_b_drug_asp_&year.q&quart. (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1))");
                  drug&year.q&quart..definekey("hcpcs_cd");
                  drug&year.q&quart..definedone();
               %end;
            %end;
         %end;

         *list of additional hemophilia codes to check for;
         if 0 then set temp.hemophilia_codes (keep = hcpcs_cd);
         declare hash hemo (dataset: "temp.hemophilia_codes (keep = hcpcs_cd)");
         hemo.definekey("hcpcs_cd");
         hemo.definedone();
         
         *list of part B drugs to be excluded;
         if 0 then set temp.excluded_part_b_drugs (keep = hcpcs_cd);
         declare hash partb (dataset: "temp.excluded_part_b_drugs (keep = hcpcs_cd)");
         partb.definekey("hcpcs_cd");
         partb.definedone();
         
         *list of cardiac rehab HCPCS for exclusion;
         if 0 then set temp.excluded_hcpcs_cr (keep = hcpcs_cd);
         declare hash hcpcs_cr (dataset: "temp.excluded_hcpcs_cr (keep = hcpcs_cd)");
         hcpcs_cr.definekey("hcpcs_cd");
         hcpcs_cr.definedone();

         *list of all OP lines that trigger final OP episodes;
         if 0 then set temp.grp_op_for_updates (keep = link_id episode_id anchor_claimno anchor_lineitem comp_adj_apc_flag anchor_apc);
         declare hash op_epis (dataset: "temp.grp_op_for_updates (keep = link_id episode_id anchor_claimno anchor_lineitem comp_adj_apc_flag anchor_apc)");
         op_epis.definekey("link_id", "anchor_claimno", "anchor_lineitem");
         op_epis.definedata("episode_id", "comp_adj_apc_flag", "anchor_apc");
         op_epis.definedone();

      end;
      call missing(of _all_);

      set temp.op_w_j1_rankings (keep = link_id anchor_claimno anchor_lineitem anchor_trigger_cd anchor_beg_dt anchor_end_dt anchor_provider claimno lineitem prim_assign_rank line_std_allowed hcpcs_cd rev_dt rstusind rev_msp1 rev_msp2 from_dt thru_dt trigger_line
                                 where = ((line_std_allowed > 0) and (not missing(rev_dt))));

      op_year = year(anchor_end_dt);

      clm_prpay = sum(rev_msp1, rev_msp2); 
      if (clm_prpay > 0) then non_medicare_prpayer = 1;
      else non_medicare_prpayer = 0;

      *if the trigger OP line cannot be found then it means the episode did not pass an exclusion criteria and should not be used in determine the average OPPS anchor payment;
      if (op_epis.find(key: link_id, key: anchor_claimno, key: anchor_lineitem) ^= 0) then excl_epi = 1;
      else excl_epi = 0;

      *flag to include cost of line in OPPS anchor payment amount if OP line is not hemophilia and contains a status indicator identifying an included service;
      hemophilia_flag = 0;
      cy_year = year(rev_dt);
      cy_quarter = qtr(rev_dt);
      if (hemo.find(key: hcpcs_cd) = 0) then hemophilia_flag = 1;
      else do;
         %do year = &query_start_year. %to &query_end_year.;
            %if &year. ^= &query_end_year. %then %do;
               %do quart = 1 %to 4;
                  if (cy_year = &year.) and (cy_quarter = &quart.) then do;
                     if (drug&year.q&quart..find(key: hcpcs_cd) = 0) then hemophilia_flag = 1;
                  end;
               %end;
            %end;
            %else %do;
               %do quart = 1 %to &hemo_quart_end.;
                  if (cy_year = &year.) and (cy_quarter = &quart.) then do;
                     if (drug&year.q&quart..find(key: hcpcs_cd) = 0) then hemophilia_flag = 1;
                  end;
               %end;
            %end;
         %end;
      end;
      
      *determine if claim has excluded part B drugs;
      part_b_dropflag = 0;
      if (partb.find(key: hcpcs_cd) = 0) then part_b_dropflag = 1;
      
      *determine if claim has excluded cardiac rehab HCPCS;
      excluded_cardiac_rehab = 0;
      if (hcpcs_cr.find(key: hcpcs_cd) = 0) then excluded_cardiac_rehab = 1;

      *flag if OP line contains an excluded status indicator;
      if (excl_opps_si.find(key: strip(rstusind)) = 0) then excl_status_ind = 1;
      else excl_status_ind = 0;

      *flag if OP line contains an incuded status indicator;
      if (incl_opps_si.find(key: strip(rstusind)) = 0) then incl_status_ind = 1;
      else incl_status_ind = 0;

      if (hemophilia_flag = 0) and (part_b_dropflag = 0) and (excluded_cardiac_rehab = 0) and (non_medicare_prpayer = 0) and (excl_status_ind = 0) and (incl_status_ind = 1) then incl_serv_in_op_anchor_pmt = 1;
      else incl_serv_in_op_anchor_pmt = 0;

      output temp.all_lines_for_opps;
      
      *if the anchoring trigger line is the highest ranking J1 on that claim and the claim is either the trigger line or an included service then output;
      if (excl_epi = 0) and ((incl_serv_in_op_anchor_pmt = 1) or (trigger_line = 1)) then output temp.services_for_op_anchor_pmt;
   run;

   *calculate the average OPPS anchor payment costs across episodes for each triggering HCPCS code and baseline year where the anchor payment cost should include the cost of the triggering OP line and all eligible services;
   proc sql;
      create table temp.avg_op_anchor_pmt_costs as
      select anchor_trigger_cd,
             op_year,
             anchor_apc,
             comp_adj_apc_flag,
             count(distinct episode_id) as num_episodes, 
             sum(line_std_allowed) as op_anchor_pmt,
             calculated op_anchor_pmt/calculated num_episodes as avg_op_anchor_pmt                
      from temp.services_for_op_anchor_pmt
      group by anchor_trigger_cd, op_year, anchor_apc, comp_adj_apc_flag
      ;
   quit;
   
   
   /*CALCULATE OPPS ANCHOR UPDATE FACTORS*/
   
   data temp.opps_anchor_update_factor;

      length anchor_opps_update_factor 8.;
      if _n_ = 1 then do;

         *list of all average OP anchor payment amount by trigger code, baseline year, and complexity-adjustment;
         if 0 then set temp.avg_op_anchor_pmt_costs (keep = anchor_trigger_cd op_year anchor_apc comp_adj_apc_flag avg_op_anchor_pmt);
         declare hash avg_op_pmt (dataset: "temp.avg_op_anchor_pmt_costs (keep = anchor_trigger_cd op_year anchor_apc comp_adj_apc_flag avg_op_anchor_pmt)");
         avg_op_pmt.definekey("anchor_trigger_cd", "op_year", "anchor_apc", "comp_adj_apc_flag");
         avg_op_pmt.definedata("avg_op_anchor_pmt");
         avg_op_pmt.definedone();

      end;
      call missing(of _all_);

      set temp.episodes_w_costs (keep = episode_id anchor_trigger_cd anchor_type final_episode anchor_end_dt anchor_apc perf_apc anchor_c_apc_flag perf_c_apc_flag anchor_apc_pmt_rate perf_apc_pmt_rate comp_adj_apc_flag
                                 where = ((lowcase(anchor_type) = "op") and (final_episode = 1) and ("&baseline_start_dt."D <= anchor_end_dt <= "&baseline_end_dt."D))); 

      op_year = year(anchor_end_dt);

      *for when the anchor HCPCS is both a C-APC in the baseline and the performance then the OPPS update factor is simply the ratio of performance period APC payment to the baseline period APC payment;
      if (anchor_c_apc_flag = 1) and (perf_c_apc_flag = 1) then anchor_opps_update_factor = perf_apc_pmt_rate/anchor_apc_pmt_rate;
      *for when the anchor HCPCS is not a C-APC in both the baseline and performance then the OPPS update factor is the ratio of the performance period APC payment to the calculated average OPPS anchor payment for that HCPCS, baseline year, and complexity-adjustment;
      else do;
         if (avg_op_pmt.find(key: anchor_trigger_cd, key: op_year, key: anchor_apc, key: comp_adj_apc_flag) = 0) then anchor_opps_update_factor = perf_apc_pmt_rate/avg_op_anchor_pmt;
      end;

   run;
%mend; 
