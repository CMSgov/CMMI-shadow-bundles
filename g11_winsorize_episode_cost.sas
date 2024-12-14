/*************************************************************************;
%** PROGRAM: g11_winsorize_episode_cost.sas
%** PURPOSE: To cap episode updated cost at 1st and 99th percentile of the episode spending of each FY-DRG/APC. 
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

%macro g11_winsorize_episode_cost();

   *for multisetting MJRLE assign OP episodes with DRG of update year;
   data temp.episodes_w_updt_factors;
      set temp.episodes_w_updt_factors;
      if (lowcase(anchor_type) = "op") and (upcase(strip(episode_group_name)) = 'MS-MAJOR JOINT REPLACEMENT OF THE LOWER EXTREMITY') then drg_&update_factor_fy. = "470";
      if (lowcase(anchor_type) = "op") and (upcase(strip(episode_group_name)) = 'MS-MAJOR JOINT REPLACEMENT OF THE UPPER EXTREMITY') then drg_&update_factor_fy. = "483";
   run;
   
   proc sort data = temp.episodes_w_updt_factors (keep = drg_&update_factor_fy. epi_fy_year episode_group_name epi_std_pmt_fctr post_epi_std_pmt_fctr final_episode 
                                                  where = ((final_episode = 1) and (upcase(substr(episode_group_name, 1, 2)) in ("IP", "MS")))) 
      out = temp.episodes_w_updt_factors_ip;
      by drg_&update_factor_fy. epi_fy_year episode_group_name;
   run;

   proc sort data = temp.episodes_w_updt_factors (keep = perf_apc epi_fy_year episode_group_name epi_std_pmt_fctr post_epi_std_pmt_fctr final_episode 
                                                  where = ((final_episode = 1) and (upcase(substr(episode_group_name, 1, 2)) = "OP"))) 
      out = temp.episodes_w_updt_factors_op;
      by perf_apc epi_fy_year episode_group_name;
   run;
   
   %do a = 1 %to &nwinz_cost_vars.;
   
      *calculate percentiles for IP anchor episodes;
      proc univariate noprint data = temp.episodes_w_updt_factors_ip;
         var &&winz_cost_vars&a..;
         by drg_&update_factor_fy. epi_fy_year episode_group_name;
         output out = temp.ip_episode_percentiles_&&winz_ds_name&a..
                pctlpre = perc_&&winz_ds_name&a.._
                pctlpts = &winsorization_lower_threshs. &winsorization_upper_threshs.;
      run;

      *calculate percentiles for OP anchor episodes;
      proc univariate noprint data = temp.episodes_w_updt_factors_op;
         var &&winz_cost_vars&a..;
         by perf_apc epi_fy_year episode_group_name;
         output out = temp.op_episode_percentiles_&&winz_ds_name&a..
                pctlpre = perc_&&winz_ds_name&a.._
                pctlpts = &winsorization_lower_threshs. &winsorization_upper_threshs.;
      run;
   
   %end;

   data temp.episodes_w_winsorization (drop = rc_: rename = (%do a = 1 %to &nwinsorize_perc.; %do b = 1 %to &nwinz_cost_vars.; perc_&&winz_ds_name&b.._&&winsorize_perc&a.. = &&winz_cost_vars&b.._perc_&&winsorize_perc&a.. %end; %end;)); 

      length %do a = 1 %to &nlower_winsor_perc.; %do b = 1 %to &nwinz_cost_vars.; winsorize_&&winz_ds_name&b.._&&lower_winsor_perc&a.._&&upper_winsor_perc&a.. &&winz_cost_vars&b.._win_&&lower_winsor_perc&a.._&&upper_winsor_perc&a..  %end; %end; 8.;


      if _n_ = 1 then do;
         
         %do a = 1 %to &nwinz_ds_name.;

            *IP anchor episode winsorization percentiles;
            if 0 then set temp.ip_episode_percentiles_&&winz_ds_name&a.. (keep = drg_&update_factor_fy. epi_fy_year episode_group_name perc_:);
            declare hash ip_perc_&&winz_ds_name&a.. (dataset: "temp.ip_episode_percentiles_&&winz_ds_name&a.. (keep = drg_&update_factor_fy. epi_fy_year episode_group_name perc_:)");
            ip_perc_&&winz_ds_name&a...definekey("drg_&update_factor_fy.", "epi_fy_year", "episode_group_name");
            ip_perc_&&winz_ds_name&a...definedata(%do b = 1 %to &nwinsorize_perc.; "perc_&&winz_ds_name&a.._&&winsorize_perc&b.." %if &b. ^= &nwinsorize_perc. %then ,; %end;);
            ip_perc_&&winz_ds_name&a...definedone();

            *OP anchor episode winsorization percentiles;
            if 0 then set temp.op_episode_percentiles_&&winz_ds_name&a.. (keep = perf_apc epi_fy_year episode_group_name perc_:);
            declare hash op_perc_&&winz_ds_name&a.. (dataset: "temp.op_episode_percentiles_&&winz_ds_name&a.. (keep = perf_apc epi_fy_year episode_group_name perc_:)");
            op_perc_&&winz_ds_name&a...definekey("perf_apc", "epi_fy_year", "episode_group_name");
            op_perc_&&winz_ds_name&a...definedata(%do b = 1 %to &nwinsorize_perc.; "perc_&&winz_ds_name&a.._&&winsorize_perc&b.." %if &b. ^= &nwinsorize_perc. %then ,; %end;);
            op_perc_&&winz_ds_name&a...definedone();

         %end;

      end;
      call missing(of _all_);

      set temp.episodes_w_updt_factors;

      *initialize variables;
      %do a = 1 %to &nlower_winsor_perc.;
         %do b = 1 %to &nwinz_ds_name.;
            winsorize_&&winz_ds_name&b.._&&lower_winsor_perc&a.._&&upper_winsor_perc&a.. = 0;
         %end;
      %end;

      *non-final episode will have missing for the winsorized cost variables;
      if (final_episode = 1) then do;
         
         *episode that do not need to be winsorize will have the winsorized episode cost variable equal to its current episode cost;
         %do a = 1 %to &nlower_winsor_perc.;
            %do b = 1 %to &nwinz_cost_vars.;
               &&winz_cost_vars&b.._win_&&lower_winsor_perc&a.._&&upper_winsor_perc&a.. = &&winz_cost_vars&b..;
            %end;
         %end;
         
         if (upcase(substr(episode_group_name, 1, 2)) in ("IP", "MS")) then do;
            %do b = 1 %to &nwinz_ds_name.;
               rc_ip_perc_&&winz_ds_name&b.. = ip_perc_&&winz_ds_name&b...find(key: drg_&update_factor_fy., key: epi_fy_year, key: episode_group_name);
            %end;
         end;
         else if (upcase(substr(episode_group_name, 1, 2)) = "OP") then do;
            %do b = 1 %to &nwinz_ds_name.;
               rc_op_perc_&&winz_ds_name&b.. = op_perc_&&winz_ds_name&b...find(key: perf_apc, key: epi_fy_year, key: episode_group_name);
            %end;
         end;

         *set episodes with cost below the lower percentile thresholds to be equal to the lower percentile;
         %do a = 1 %to &nlower_winsor_perc.; 
            %do b = 1 %to &nwinz_cost_vars.;
               if (&&winz_cost_vars&b.. < perc_&&winz_ds_name&b.._&&lower_winsor_perc&a..) then do;
                  &&winz_cost_vars&b.._win_&&lower_winsor_perc&a.._&&upper_winsor_perc&a.. = perc_&&winz_ds_name&b.._&&lower_winsor_perc&a..;
                  winsorize_&&winz_ds_name&b.._&&lower_winsor_perc&a.._&&upper_winsor_perc&a.. = 1;
               end;
            %end;
         %end;
         *set episodes with cost above the upper percentile thresholds to be equal to the upper percentile;
         %do a = 1 %to &nupper_winsor_perc.;
            %do b = 1 %to &nwinz_cost_vars.;
               if (&&winz_cost_vars&b.. > perc_&&winz_ds_name&b.._&&upper_winsor_perc&a..) then do;
                  &&winz_cost_vars&b.._win_&&lower_winsor_perc&a.._&&upper_winsor_perc&a.. = perc_&&winz_ds_name&b.._&&upper_winsor_perc&a..;
                  winsorize_&&winz_ds_name&b.._&&lower_winsor_perc&a.._&&upper_winsor_perc&a.. = 1;
               end;
            %end;
         %end;

      end;
   run;
   
   
%mend; 
