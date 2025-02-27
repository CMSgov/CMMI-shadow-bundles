/*************************************************************************;
%** PROGRAM: g7_calculate_irf_update_factor.sas
%** PURPOSE: To calculate IRF update factor for post-anchor period cost
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro g7_calculate_irf_update_factor();

   *calculate the yearly IRF update factors;
   data temp.irf_post_anchor_update_factor (keep = irf_year end_year_rate current_year_rate irf_update_factor);

      %do year = %eval(&baseline_start_year.+1) %to &baseline_end_year.;
         irf_year = &year.;
         end_year_rate = &&irf_base_full_&update_factor_fy..;
         current_year_rate = &&irf_base_full_&year..;
         irf_update_factor = end_year_rate/current_year_rate;         
         output temp.irf_post_anchor_update_factor;
      %end;

   run;
   
%mend; 
