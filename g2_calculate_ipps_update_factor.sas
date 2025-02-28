/*************************************************************************;
%** PROGRAM: g2_calculate_ipps_update_factor.sas
%** PURPOSE: To calculate IPPS update factor for anchor and post-anchor period cost
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro g2_calculate_ipps_update_factor();
   
   /*CALCULATE IPPS ANCHOR UPDATE FACTOR*/
   *merge on DRG weight to each ip stay for each year;
   data  temp.ipps_anchor_update_factor (drop = rc_:)   
         temp.ip_for_post_anchor_uf (drop = rc_:)  
         temp.irf_ip_for_post_anchor_uf (drop = rc_:)  
         ;
      if _n_ = 1 then do;         
         *list of DRG weights;
         %do year = &baseline_start_year.+1 %to &update_factor_fy.;
            if 0 then set geo.ipps_drg_weights_&year. (keep = drg weight rename = (drg = drg_&year. weight = weights_&year.));
            declare hash drg_wgt&year. (dataset: "geo.ipps_drg_weights_&year. (keep = drg weight rename = (drg = drg_&year. weight = weights_&year.))");
            drg_wgt&year..definekey("drg_&year.");
            drg_wgt&year..definedata("weights_&year.");
            drg_wgt&year..definedone();
         %end;
      end;
      call missing(of _all_);

      *filter to the IPPS providers;
      set temp.grp_ip_for_updates (where = ((irf_flag = 1) or (ipps_flag = 1 and cancer_hosp_flag = 0 and state_flag = 0) or (anchor_ipps_flag = 1 and anchor_cancer_hosp_flag = 0 and anchor_state_flag = 0)));

      *create fiscal years for ip stays;
      %do year = &baseline_start_year. %to &baseline_end_year.;
         %let prev_year = %eval(&year.-1);
         if ("01OCT&prev_year."D <= anchor_end_dt <= "30SEP&year."D) then ip_year = &year.;
         %if &year. ^= &baseline_end_year. %then else;
      %end;
      
      *obtain DRG weights; 
      %do year = &baseline_start_year.+1 %to &update_factor_fy.;
         rc_drg_wgt&year. = drg_wgt&year..find(key: drg_&year.);         
      %end;
      
      *calculate IPPS update factor for anchor cost using triggered IP stays; 
      if (anchor_ipps_flag = 1 and anchor_cancer_hosp_flag = 0 and anchor_state_flag = 0) then do; 
         *if weights are populated for anchor end year and ip update year then calculate the anchor ipps update factor;
         %do year = &baseline_start_year.+1 %to &baseline_end_year.;
            if (ip_year = &year.) then do;
               if not missing(weights_&year.) and not missing(weights_&update_factor_fy.) then do;
                  anchor_ipps_update_factor = (weights_&update_factor_fy.*&&ipps_oper_base_full_&update_factor_fy..)/(weights_&year.*&&ipps_oper_base_full_&year..);
               end;            
               else abort; %*throw an error if weight is missing;                
            end;
            %if &year. ^= &baseline_end_year. %then else;
         %end;    
         
         output temp.ipps_anchor_update_factor; 
      end;
      
      *output IP stays to calculate IPPS post-anchor update factor; 
      if (ipps_flag = 1 and cancer_hosp_flag = 0 and state_flag = 0) then output temp.ip_for_post_anchor_uf;
      
      *output IP stays that are IRF or IPPS grouped to the post-anchor period; 
      IF (irf_flag = 1) or (ipps_flag = 1 and cancer_hosp_flag = 0 and state_flag = 0) then output temp.irf_ip_for_post_anchor_uf;
   run;


   /*CALCULATE IPPS POST-ANCHOR UPDATE FACTOR*/   
   proc sql;      
      create table temp.ipps_post_anchor_update_factor as 
      select 
         anchor_provider, 
         episode_group_name,
         ip_year,
         count(*) as num_stays,
         %do year = &baseline_start_year.+1 %to &update_factor_fy.;
            sum(weights_&year.)/calculated num_stays as drg_wt_&year., 
         %end;
         case 
            %do year = &baseline_start_year.+1 %to &baseline_end_year.;
               when ip_year = &year. then (calculated drg_wt_&update_factor_fy.*&&ipps_oper_base_full_&update_factor_fy..)/(calculated drg_wt_&year.*&&ipps_oper_base_full_&year..) 
            %end; 
          else . end as post_dsch_ipps_update_factor
      from temp.ip_for_post_anchor_uf
      group by anchor_provider, episode_group_name, ip_year
      ;
   quit;
   

%mend; 
