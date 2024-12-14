/*************************************************************************;
%** PROGRAM: g10_apply_final_update_factor.sas
%** PURPOSE: To calculate and applie final update factors to episode cost. 
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

%macro g10_apply_final_update_factor();

   proc sql;
      create table temp.baseline_episode_cost_ccn as
      select distinct 
         anchor_provider,
         episode_group_name,
         epi_fy_year,
         division_code,
         division_name,
         count(*) as epi_count,
         sum(tot_std_allowed) as epi_std_sum,
         sum(tot_post_epi_std_allowed) as post_epi_std_sum,
         sum(anchor_standard_allowed_amt) as anchor_pmt_sum,
         (calculated epi_std_sum - calculated anchor_pmt_sum) as epi_std_pmt_sum,
         %do a = 1 %to &nupdate_settings.;
            sum(epi_std_pmt_&&update_settings&a..) as epi_std_pmt_&&update_settings&a.._sum,
            calculated epi_std_pmt_&&update_settings&a.._sum/calculated epi_std_pmt_sum as epi_std_pmt_&&update_settings&a.._perc
            %if &a. ^= &nupdate_settings. %then ,;
         %end;
      from temp.tot_epi_std_pmt
      group by anchor_provider, episode_group_name, epi_fy_year, division_code, division_name
      ;
   quit;  

   *calculate anchor provider level update factors;
   data temp.baseline_update_factor_ccn (drop = rc_:);
      
      if _n_ = 1 then do;
         
         *irf update factors;
         if 0 then set temp.irf_post_anchor_update_factor (keep = irf_year irf_update_factor rename = (irf_year = ccn_year irf_update_factor = irf_update_factor_ccn));
         declare hash irf_factors (dataset: "temp.irf_post_anchor_update_factor (keep = irf_year irf_update_factor rename = (irf_year = ccn_year irf_update_factor = irf_update_factor_ccn))");
         irf_factors.definekey("ccn_year");
         irf_factors.definedata("irf_update_factor_ccn");
         irf_factors.definedone();

         *other update factors;
         if 0 then set temp.other_post_anchor_update_factor (keep = other_year other_update_factor rename = (other_year = ccn_year other_update_factor = other_update_factor_ccn));
         declare hash other_factors (dataset: "temp.other_post_anchor_update_factor (keep = other_year other_update_factor rename = (other_year = ccn_year other_update_factor = other_update_factor_ccn))");
         other_factors.definekey("ccn_year");
         other_factors.definedata("other_update_factor_ccn");
         other_factors.definedone();

      end;
      call missing(of _all_);

      merge temp.baseline_episode_cost_ccn (rename = (epi_fy_year = ccn_year) in = in_baseline)
            temp.ipps_post_anchor_update_factor (keep = anchor_provider episode_group_name ip_year post_dsch_ipps_update_factor rename = (ip_year = ccn_year post_dsch_ipps_update_factor = post_dsch_ipps_update_factor_ccn) in = in_ip)
            temp.pb_post_anchor_update_factor (keep = anchor_provider episode_group_name anes_update total_anes_pay anes_perc total_phy_pay phys_update phys_perc pb_year pfs_update_factor rename = (pb_year = ccn_year pfs_update_factor = pfs_update_factor_ccn) in = in_phy)
            temp.hh_post_anchor_update_factor (keep = anchor_provider episode_group_name hh_year hh_update_factor rename = (hh_year = ccn_year hh_update_factor = hh_update_factor_ccn) in = in_hh)            
            temp.sn_post_anchor_update_factor (keep = anchor_provider episode_group_name snf_year snf_update_factor rename = (snf_year = ccn_year snf_update_factor = snf_update_factor_ccn) in = in_snf);
      by anchor_provider episode_group_name ccn_year;

      rc_irf_factors = irf_factors.find(key: ccn_year);
      rc_other_factors = other_factors.find(key: ccn_year);

      if (missing(post_dsch_ipps_update_factor_ccn)) then post_dsch_ipps_update_factor_ccn = 0;
      if (missing(pfs_update_factor_ccn)) then pfs_update_factor_ccn = 0;
      if (missing(phys_update)) then phys_update = 0;
      if (missing(phys_perc)) then phys_perc = 0;
      if (missing(total_phy_pay)) then total_phy_pay = 0;
      if (missing(anes_update)) then anes_update = 0;
      if (missing(anes_perc)) then anes_perc = 0;
      if (missing(total_anes_pay)) then total_anes_pay = 0;
      if (missing(hh_update_factor_ccn)) then hh_update_factor_ccn = 0;
      if (missing(snf_update_factor_ccn)) then snf_update_factor_ccn = 0;
      if (missing(irf_update_factor_ccn)) then irf_update_factor_ccn = 0;
      if (missing(other_update_factor_ccn)) then other_update_factor_ccn = 0;

      *calculate overall update factors;
      update_factor_ccn = sum(post_dsch_ipps_update_factor_ccn*epi_std_pmt_ip_perc,
                              pfs_update_factor_ccn*epi_std_pmt_pb_perc,
                              hh_update_factor_ccn*epi_std_pmt_hh_perc,
                              snf_update_factor_ccn*epi_std_pmt_sn_perc,
                              irf_update_factor_ccn*epi_std_pmt_irf_perc,
                              other_update_factor_ccn*epi_std_pmt_other_perc);
                              
      if (in_baseline = 1) then output temp.baseline_update_factor_ccn;

   run;

   data temp.episodes_w_updt_factors (drop = rc_: ccn_year rename = (op_anchor_pmt = anchor_op_pmt_w_elgb_services));

      length epi_std_pmt_fctr post_epi_std_pmt_fctr price_updated_flag 8.;
      if _n_ = 1 then do;

         *update factors at the CCN level;
         if 0 then set temp.baseline_update_factor_ccn (keep = anchor_provider episode_group_name ccn_year post_dsch_ipps_update_factor_ccn pfs_update_factor_ccn hh_update_factor_ccn snf_update_factor_ccn irf_update_factor_ccn other_update_factor_ccn update_factor_ccn);
         declare hash ccn_update (dataset: "temp.baseline_update_factor_ccn (keep = anchor_provider episode_group_name ccn_year post_dsch_ipps_update_factor_ccn pfs_update_factor_ccn hh_update_factor_ccn snf_update_factor_ccn irf_update_factor_ccn other_update_factor_ccn update_factor_ccn)");
         ccn_update.definekey("anchor_provider", "episode_group_name", "ccn_year");
         ccn_update.definedata("post_dsch_ipps_update_factor_ccn", "pfs_update_factor_ccn", "hh_update_factor_ccn", "snf_update_factor_ccn", "irf_update_factor_ccn", "other_update_factor_ccn", "update_factor_ccn");
         ccn_update.definedone();

         *update factors for the IPPS anchor period;
         if 0 then set temp.ipps_anchor_update_factor (keep = episode_id anchor_ipps_update_factor);
         declare hash anchor_ip_fctr (dataset: "temp.ipps_anchor_update_factor (keep = episode_id anchor_ipps_update_factor)");
         anchor_ip_fctr.definekey("episode_id");
         anchor_ip_fctr.definedata("anchor_ipps_update_factor");
         anchor_ip_fctr.definedone();
         
         *update factors for the OPPS anchor period;
         if 0 then set temp.opps_anchor_update_factor (keep = episode_id anchor_opps_update_factor);
         declare hash anchor_op_fctr (dataset: "temp.opps_anchor_update_factor (keep = episode_id anchor_opps_update_factor)");
         anchor_op_fctr.definekey("episode_id");
         anchor_op_fctr.definedata("anchor_opps_update_factor");
         anchor_op_fctr.definedone();

         *OPPS anchor payment costs by episode;
         if 0 then set temp.op_anchor_pmt_by_epis (keep = episode_id op_anchor_pmt);
         declare hash op_cost_by_epi (dataset: "temp.op_anchor_pmt_by_epis (keep = episode_id op_anchor_pmt)");
         op_cost_by_epi.definekey("episode_id");
         op_cost_by_epi.definedata("op_anchor_pmt");
         op_cost_by_epi.definedone();

      end;
      call missing(of _all_);

      set temp.episodes_w_safety_net;
      
      *initialize flags;
      price_updated_flag = 0;

      epi_year = year(anchor_end_dt);
      epi_quarter = qtr(anchor_end_dt);
      
      %do year = &query_start_year. %to %eval(&query_end_year.+1);
         %let prev_year = %eval(&year.-1);
         if ("01OCT&prev_year."D <= anchor_end_dt <= "30SEP&year."D) then epi_fy_year = &year.;
         %if &year. ^= %eval(&query_end_year.+1) %then else;
      %end;

      *since update factors were generated using only final episodes, only providers associated wth a final episode should have the updated factor costs merged to it;
      *non-final episodes will have missing for the updated factor costs;
      if (final_episode = 1) then do;

         rc_anchor_ip_fctr = anchor_ip_fctr.find(key: episode_id);
         rc_anchor_op_fctr = anchor_op_fctr.find(key: episode_id);
         rc_op_cost_by_epi = op_cost_by_epi.find(key: episode_id);

         if (lowcase(anchor_type) = "ip") then anchor_pmt_amt = anchor_standard_allowed_amt;
         else if (lowcase(anchor_type) = "op") then do;
            *if OP episode is a C-APC in both baseline and performance, then just update the trigger line cost. if episode is not a C-APC in baseline then update the trigger line cost plus eligible service costs that would have been bundled to the trigger line if it did exist in a C-APC world;
            if (anchor_c_apc_flag = 1) and (perf_c_apc_flag = 1) then anchor_pmt_amt = anchor_standard_allowed_amt;
            else if (anchor_c_apc_flag = 0) and (perf_c_apc_flag = 1) then anchor_pmt_amt = anchor_standard_allowed_amt;
         end;

         if (ccn_update.find(key: anchor_provider, key: episode_group_name, key: epi_fy_year) = 0) then do;
            price_updated_flag = 1;
            *must update the anchoring trigger cost separately from the non-triggering costs;
            *for episode period costs;
            if (lowcase(anchor_type) = "ip") then epi_std_pmt_fctr = sum(update_factor_ccn*sum(tot_std_allowed, -anchor_pmt_amt), (anchor_ipps_update_factor*anchor_pmt_amt));
            else if (lowcase(anchor_type) = "op") then epi_std_pmt_fctr = sum(update_factor_ccn*sum(tot_std_allowed, -anchor_pmt_amt), (anchor_opps_update_factor*anchor_pmt_amt));
            *for post-episode period costs;
            post_epi_std_pmt_fctr = update_factor_ccn*tot_post_epi_std_allowed;
         end;

      end;

      *set missings to zeros;
      *for anchor period of episodes;
      if (missing(anchor_pmt_amt)) then anchor_pmt_amt = 0;
      if (missing(op_anchor_pmt)) then op_anchor_pmt = 0;
      if (missing(anchor_ipps_update_factor)) then anchor_ipps_update_factor = 0;
      if (missing(anchor_opps_update_factor)) then anchor_opps_update_factor = 0;

      *for CCNs;
      if (missing(post_dsch_ipps_update_factor_ccn)) then post_dsch_ipps_update_factor_ccn = 0;
      if (missing(pfs_update_factor_ccn)) then pfs_update_factor_ccn = 0;
      if (missing(hh_update_factor_ccn)) then hh_update_factor_ccn = 0;
      if (missing(snf_update_factor_ccn)) then snf_update_factor_ccn = 0;
      if (missing(irf_update_factor_ccn)) then irf_update_factor_ccn = 0;
      if (missing(other_update_factor_ccn)) then other_update_factor_ccn = 0;
      if (missing(update_factor_ccn)) then update_factor_ccn = 0;

   run;   
%mend; 
