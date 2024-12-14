/*************************************************************************;
%** PROGRAM: g9_aggregate_clms_for_uf_weights.sas
%** PURPOSE: To gather all claims/episodes to calculate the weights for update factors 
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

%macro g9_aggregate_clms_for_uf_weights();

   /*GET ANCHOR COST FROM TRIGGERING IP STAYS AND OP LINES*/

   proc sql;
      create table temp.op_anchor_pmt_by_epis as
      select distinct 
         episode_id, 
         sum(line_std_allowed) as op_anchor_pmt
      from temp.services_for_op_anchor_pmt
      group by episode_id
      ;
   quit;
   
   data temp.all_anchors_for_updt_costs (drop = rc_:);

      if _n_ = 1 then do;

         *OPPS anchor payment costs by episode;
         if 0 then set temp.op_anchor_pmt_by_epis (keep = episode_id op_anchor_pmt);
         declare hash op_cost_by_epi (dataset: "temp.op_anchor_pmt_by_epis (keep = episode_id op_anchor_pmt)");
         op_cost_by_epi.definekey("episode_id");
         op_cost_by_epi.definedata("op_anchor_pmt");
         op_cost_by_epi.definedone();

      end;
      call missing(of _all_);

      set temp.all_anchors_for_updates;

      rc_op_cost_by_epi = op_cost_by_epi.find(key: episode_id);
      if (missing(op_anchor_pmt)) then op_anchor_pmt = 0;
      if (lowcase(anchor_type) = "ip") then anchor_pmt_amt = anchor_standard_allowed_amt;
      else if (lowcase(anchor_type) = "op") then do;
         if (anchor_c_apc_flag = 1) and (perf_c_apc_flag = 1) then anchor_pmt_amt = anchor_standard_allowed_amt;
         else if (anchor_c_apc_flag = 0) and (perf_c_apc_flag = 1) then anchor_pmt_amt = anchor_standard_allowed_amt;
      end;
   run;

   proc sort data = temp.all_anchors_for_updt_costs;
      by episode_id;
   run;


   /*GET ELIGIBLE CLAIMS WITH POST-ANCHOR COST*/
   
   *for IP;
   *get dataset containing all IP and IRF claims used to generate weights;
   proc sort data = temp.irf_ip_for_post_anchor_uf;
      by episode_id;
   run; 
   
   *for PB;
   *get dataset containing all physician PB claims used to produce weights;
   proc sort data = temp.pb_rvu_w_gpci;
      by episode_id;
   run;   
   *for anesthesia;
   *get dataset containing all anesthesia PB claims used to produce weights;
   proc sort data = temp.anes_w_cf;             
      by episode_id;
   run; 
   
   *for HH;
   *get dataset containing all HH claims used to generate weights;
   proc sort nodupkey data = temp.hh_lines_w_weights;                      
      by episode_id claimno;
   run;

   *for SN;
   *get datasets containing SN claims used to produce weights;   
   proc sort nodupkey data = temp.grp_sn_w_pdpm_rate;
      by episode_id claimno;
   run;


   *stack IP, IRF, SN, HH, PB, and anesthesia claims used for setting specific updates;
   data temp.aggregated_clm_costs (keep = episode_id link_id anchor_beg_dt anchor_end_dt anchor_provider epi_std_pmt_: tot_std_allowed tot_post_epi_std_allowed division_code division_name anchor_pmt_amt anchor_type anchor_standard_allowed_amt op_anchor_pmt);

      length setting_type $10.;
      if _n_ = 1 then do;
         
         *OPPS anchor payment costs by episode;
         if 0 then set temp.op_anchor_pmt_by_epis (keep = episode_id op_anchor_pmt);
         declare hash op_cost_by_epi (dataset: "temp.op_anchor_pmt_by_epis (keep = episode_id op_anchor_pmt)");
         op_cost_by_epi.definekey("episode_id");
         op_cost_by_epi.definedata("op_anchor_pmt");
         op_cost_by_epi.definedone();

      end;
      call missing(of _all_);

      set 
          temp.irf_ip_for_post_anchor_uf (in = in_irf where = (irf_claim = 1)) %*this only includes IRF claims in post-discharge period;
          temp.irf_ip_for_post_anchor_uf (in = in_ip where = (irf_claim = 0)) %*this only includes IP claims in the post-discharge period;
          temp.pb_rvu_w_gpci (in = in_pb_rvu)
          temp.anes_w_cf (in = in_anes)
          temp.hh_lines_w_weights (in = in_hh)
          temp.grp_sn_w_pdpm_rate (in = in_sn)
          ;
      by episode_id;

      retain %do a = 1 %to &nupdate_settings.; epi_std_pmt_&&update_settings&a.. %end;;

      *merge on the OPPS payment amount for the episode;
      rc_op_cost_by_epi = op_cost_by_epi.find(key: episode_id);
      if (missing(op_anchor_pmt)) then op_anchor_pmt = 0;

      if (in_ip = 1) then setting_type = "ip";
      else if (in_irf = 1) then setting_type = "irf";
      else if (in_hh = 1) then setting_type = "hh";
      else if (in_sn = 1) then setting_type = "sn";
      else if (in_pb_rvu = 1) or (in_anes = 1) then setting_type = "pb";

      *calculate the total payment amount associated with each price-update setting;
      if first.episode_id then do;
         %do a = 1 %to &nupdate_settings.;
            epi_std_pmt_&&update_settings&a.. = 0;
         %end;
      end;
      %do a = 1 %to &nupdate_settings.;
         %if "&&update_settings&a.." ^= "other" %then %do;
            if (lowcase(setting_type) = "&&update_settings&a..") then epi_std_pmt_&&update_settings&a.. = sum(epi_std_pmt_&&update_settings&a.., payment_amt);
         %end;
      %end;
      if last.episode_id then do;
         if (lowcase(anchor_type) = "ip") then anchor_pmt_amt = anchor_standard_allowed_amt;
         else if (lowcase(anchor_type) = "op") then do;
            if (anchor_c_apc_flag = 1) and (perf_c_apc_flag = 1) then anchor_pmt_amt = anchor_standard_allowed_amt;
            else if (anchor_c_apc_flag = 0) and (perf_c_apc_flag = 1) then anchor_pmt_amt = anchor_standard_allowed_amt;
         end;
         %do a = 1 %to &nupdate_settings.;
            *NOTE: remember to substract out the anchor period cost since for both IP and OP based episodes, the anchor period cost is updated separately from the post-discharge period costs;
            %if "&&update_settings&a.." = "other" %then %do;
                epi_std_pmt_&&update_settings&a.. = max(0, sum(tot_std_allowed, -epi_std_pmt_ip, -epi_std_pmt_irf, -epi_std_pmt_pb, -epi_std_pmt_sn, -epi_std_pmt_hh, -anchor_pmt_amt));
            %end;
            %else %do;
               epi_std_pmt_&&update_settings&a.. = epi_std_pmt_&&update_settings&a..;
            %end;
         %end;
         output temp.aggregated_clm_costs;
      end;

   run;

   *NOTE: make sure to grab any remaining episodes occurring in the baseline period that may not have been accounted for in the aggregrated_clm_costs dataset by merging back to main episode-level dataset;
   data temp.tot_epi_std_pmt;

      length epi_year epi_fy_year 8.;
      merge temp.all_anchors_for_updt_costs (keep = episode_id link_id episode_group_name anchor_beg_dt anchor_end_dt anchor_provider anchor_type tot_std_allowed tot_post_epi_std_allowed anchor_standard_allowed_amt division_code division_name anchor_pmt_amt op_anchor_pmt in = in_all)
            temp.aggregated_clm_costs (in = in_agg);
      by episode_id;

      epi_year = year(anchor_end_dt);
      
      %do year = &baseline_start_year. %to &baseline_end_year.;
         %let prev_year = %eval(&year.-1);
         if ("01OCT&prev_year."D <= anchor_end_dt <= "30SEP&year."D) then epi_fy_year = &year.;
         %if &year. ^= &baseline_end_year. %then else;
      %end;

      *for episodes not already accounted for in the aggregated_clm_costs datasets, need to calcalate the epi_std_pmt_: cost variables;
      %do a = 1 %to &nupdate_settings.;
         *NOTE: remember to substract out the anchor period cost since for both IP and OP based episodes, the anchor period cost is updated separately from the post-discharge period costs;
         %if "&&update_settings&a.." = "other" %then %do;
            epi_std_pmt_&&update_settings&a.. = max(0, sum(tot_std_allowed, -epi_std_pmt_ip, -epi_std_pmt_irf, -epi_std_pmt_pb, -epi_std_pmt_sn, -epi_std_pmt_hh, -anchor_pmt_amt));
         %end;
         %else %do;
            if (missing(epi_std_pmt_&&update_settings&a..)) then epi_std_pmt_&&update_settings&a.. = 0;
         %end;
      %end;

      output temp.tot_epi_std_pmt;

   run;
   
%mend; 
