/*************************************************************************;
%** PROGRAM: f4_add_covid_inf_rates.sas
%** PURPOSE: To add covid infection rates
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro f4_add_covid_inf_rates();
   
   *add covid infection rates to episode files;
   data temp.episodes_w_cvd_inf_rt;

      if _n_ = 1 then do;

         *CIT dataset used to obtain covid infection rate;
         if 0 then set cit_rt.cit_by_bpci_provider_all (keep = anchor_provider week_start_date cvd_19_inf_rt);
         declare hash covid_inf_rt (dataset: "cit_rt.cit_by_bpci_provider_all (keep = anchor_provider week_start_date cvd_19_inf_rt)");
         covid_inf_rt.definekey("anchor_provider", "week_start_date");
         covid_inf_rt.definedata("cvd_19_inf_rt");
         covid_inf_rt.definedone();

      end;
      call missing(of _all_);

      set temp.episodes_w_hccs;

      *obtain covid infection rate;
      %*create year and week of anchor begin date to be merged to CIT dataset;
      if episode_in_study_period = 1 and anchor_beg_dt >= "01JAN2020"D then week_start_date = intnx('week', anchor_beg_dt,0, 'b');
      
      %*obtain COVID infection rate by anchor provider, year and week;
      if covid_inf_rt.find(key: anchor_provider, key: week_start_date) ^= 0 then call missing(cvd_19_inf_rt);
      if not missing (cvd_19_inf_rt) then cvd_19_inf_rt_type = "Provider-Week Level Avg";
      
   run;
   
   *impute covid infection rates for provider-week with missing rates; 
   proc sql noprint;
      *take the average of COVID infection rate at CEC-week level;
      create table temp.cec_week_avg_inf_rt as
      select
         episode_group_name,
         week_start_date,
         mean(cvd_19_inf_rt) as cvd_19_inf_rt
      from temp.episodes_w_cvd_inf_rt (where = (final_episode = 1 and dropflag_episode_overlap = 0 and not missing(cvd_19_inf_rt)) )
      group by episode_group_name, week_start_date;
      
      *take the average of COVID infection rate at CEC level;
      create table temp.cec_avg_inf_rt as
      select
         episode_group_name,
         mean(cvd_19_inf_rt) as cvd_19_inf_rt
      from temp.episodes_w_cvd_inf_rt (where = (final_episode = 1 and dropflag_episode_overlap = 0 and not missing(cvd_19_inf_rt)) )
      group by episode_group_name;

   quit; 
   
   
   data temp.episodes_w_cvd_inf_rt;
        
      if _n_ = 1 then do;

         *average COVID infection rate at CEC-week level;
         if 0 then set temp.cec_week_avg_inf_rt (keep = episode_group_name week_start_date cvd_19_inf_rt);
         declare hash cec_wk_rt (dataset: "temp.cec_week_avg_inf_rt (keep = episode_group_name week_start_date cvd_19_inf_rt)");
         cec_wk_rt.definekey("episode_group_name", "week_start_date");
         cec_wk_rt.definedata("cvd_19_inf_rt");
         cec_wk_rt.definedone();

         *average COVID infection rate at CEC level;
         if 0 then set temp.cec_avg_inf_rt (keep = episode_group_name cvd_19_inf_rt);
         declare hash cec_rt (dataset: "temp.cec_avg_inf_rt (keep = episode_group_name cvd_19_inf_rt)");
         cec_rt.definekey("episode_group_name");
         cec_rt.definedata("cvd_19_inf_rt");
         cec_rt.definedone();
         
      end;
      call missing(of _all_);

      set temp.episodes_w_cvd_inf_rt;
      
      *obtain CEC-week level COVID infection rate for missing rates from CIT dataset;
      if not missing(week_start_date) and missing(cvd_19_inf_rt) then do;
         cvd_19_inf_rt_type = "CEC-Week Level Avg";
         if cec_wk_rt.find(key: episode_group_name, key: week_start_date) ^= 0 then call missing(cvd_19_inf_rt);
      end;

      *if still missing, use CEC level COVID infection rate for missing rates from CIT dataset;      
      if missing(cvd_19_inf_rt) then do;      
         cvd_19_inf_rt_type = "CEC Level Avg";
         if cec_rt.find(key: episode_group_name) ^= 0 then call missing(cvd_19_inf_rt);
      end; 
      
      *sanity check: all rates should be available;
      if missing(cvd_19_inf_rt) then do;
         put "WARNING: Missing covid infection rate after imputation!";
      end;    
      
      *initialize flags for each covid related period;
      P1_EA20_MDL20     = 0;
      P2_LT20_EA21      = 0;
      P3_EA21_MDL21     = 0;
      P4_LT21_EA22      = 0;
      P5_EA22_MDL22     = 0;
      P6_LT22_EA23      = 0;
      P7_EA23_AND_LTR   = 0;
      
      if "01MAR2020"D <= anchor_beg_dt <= "31OCT2020"D      then P1_EA20_MDL20 = 1;
      else if "01NOV2020"D <= anchor_beg_dt <= "28FEB2021"D then P2_LT20_EA21 = 1;
      else if "01MAR2021"D <= anchor_beg_dt <= "31OCT2021"D then P3_EA21_MDL21 = 1;
      else if "01NOV2021"D <= anchor_beg_dt <= "28FEB2022"D then P4_LT21_EA22 = 1;
      else if "01MAR2022"D <= anchor_beg_dt <= "31OCT2022"D then P5_EA22_MDL22 = 1;
      else if "01NOV2022"D <= anchor_beg_dt <= "28FEB2023"D then P6_LT22_EA23 = 1;
      else if "01MAR2023"D <= anchor_beg_dt then P7_EA23_AND_LTR = 1;
      
      *scale COVID_19 Infection rate;
      CVD_19_INF_RT = CVD_19_INF_RT * 100;

      *interact covid infection rates with time periods;       
      CVD_19_INF_RT_P1_EA20_MDL20   = CVD_19_INF_RT * P1_EA20_MDL20;
      CVD_19_INF_RT_P2_LT20_EA21    = CVD_19_INF_RT * P2_LT20_EA21;
      CVD_19_INF_RT_P3_EA21_MDL21   = CVD_19_INF_RT * P3_EA21_MDL21;
      CVD_19_INF_RT_P4_LT21_EA22    = CVD_19_INF_RT * P4_LT21_EA22;
      CVD_19_INF_RT_P5_EA22_MDL22   = CVD_19_INF_RT * P5_EA22_MDL22;
      CVD_19_INF_RT_P6_LT22_EA23    = CVD_19_INF_RT * P6_LT22_EA23;
      CVD_19_INF_RT_P7_EA23_AND_LTR = CVD_19_INF_RT * P7_EA23_AND_LTR;

      output temp.episodes_w_cvd_inf_rt;
   run;   
%mend; 