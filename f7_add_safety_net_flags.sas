/*************************************************************************;
%** PROGRAM: f7_add_safety_net_flags.sas
%** PURPOSE: To add flag to indicate safety net hospitals
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

%macro f7_add_safety_net_flags();

   *calculate counts and proportion of each type of dual eligibility;
   proc sql;

      create table temp.safety_net_stats as 
         select provider,
                dschrg_fy_year,
                count(*) as tot_num_admsn,
                sum(full_dual) as num_full_dual_admsn,
                calculated num_full_dual_admsn/calculated tot_num_admsn as perc_full_dual_admsn,
                sum(partial_dual) as num_part_dual_admsn,
                calculated num_part_dual_admsn/calculated tot_num_admsn as perc_part_dual_admsn,
                sum(any_dual) as num_any_dual_admsn,
                calculated num_any_dual_admsn/calculated tot_num_admsn as perc_any_dual_admsn,
                (case when calculated perc_any_dual_admsn > &safety_net_thresh./100 then 1 else 0 end) as safety_net_&safety_net_thresh.
         from temp.cleaned_ip_stays_w_dual (keep = provider dschrg_fy_year full_dual partial_dual any_dual standard_allowed_amt where = (standard_allowed_amt > 0))
         group by provider, dschrg_fy_year
         ;

   quit;

   *merge safety flags back to episode-level dataset;
   data temp.episodes_w_safety_net (drop = rc_: dschrg_fy_year);

      if _n_ = 1 then do;

         *list of safety net flags;
         if 0 then set temp.safety_net_stats (keep = provider dschrg_fy_year tot_num_admsn num_full_dual_admsn perc_full_dual_admsn num_part_dual_admsn perc_part_dual_admsn num_any_dual_admsn perc_any_dual_admsn safety_net_:);
         declare hash safety_net (dataset: "temp.safety_net_stats (keep = provider dschrg_fy_year tot_num_admsn num_full_dual_admsn perc_full_dual_admsn num_part_dual_admsn perc_part_dual_admsn num_any_dual_admsn perc_any_dual_admsn safety_net_:)");
         safety_net.definekey("provider", "dschrg_fy_year");
         safety_net.definedata("tot_num_admsn", "num_full_dual_admsn", "perc_full_dual_admsn", "num_part_dual_admsn", "perc_part_dual_admsn", "num_any_dual_admsn", "perc_any_dual_admsn", "safety_net_&safety_net_thresh.");
         safety_net.definedone();

      end;
      call missing(of _all_);

      set temp.episodes_w_duals;

      *determine fiscal year of anchor end date;
      %do year = &query_start_year. %to %eval(&query_end_year.+1);
         %let prev_year = %eval(&year.-1);
         if ("01OCT&prev_year."D <= anchor_end_dt <= "30SEP&year."D) then dschrg_fy_year = &year.;
         %if &year. ^= %eval(&query_end_year.+1) %then else;
      %end;

      rc_safety_net = safety_net.find(key: anchor_provider, key: dschrg_fy_year);

      if missing(tot_num_admsn) then tot_num_admsn = 0;
      if missing(num_full_dual_admsn) then num_full_dual_admsn = 0;
      if missing(perc_full_dual_admsn) then perc_full_dual_admsn = 0;
      if missing(num_part_dual_admsn) then num_part_dual_admsn = 0;
      if missing(perc_part_dual_admsn) then perc_part_dual_admsn = 0;
      if missing(num_any_dual_admsn) then num_any_dual_admsn = 0;
      if missing(perc_any_dual_admsn) then perc_any_dual_admsn = 0;
      if missing(safety_net_&safety_net_thresh.) then safety_net_&safety_net_thresh. = 0;

      *interaction between safety net and time trend variables;
      %do a = 1 %to &ntime_factors.;
         safety_net_&safety_net_thresh._&&time_short&a.. = safety_net_&safety_net_thresh. * &&time_factors&a.._time_trend;
      %end;

      *interaction between safety net flags and quarter time flags;
      %do quart_year = &quart_trend_start_yr. %to &quart_trend_end_yr.;
         %do q = 1 %to 4;
            safety_net_&safety_net_thresh._&quart_year._q&q. = yr&quart_year._q&q. * safety_net_&safety_net_thresh.;  
         %end;
      %end;

   run;

%mend; 
