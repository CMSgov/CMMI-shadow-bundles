/*************************************************************************;
%** PROGRAM: g8_calculate_other_update_factor.sas
%** PURPOSE: To calculate other update factor (MEI) for post-anchor period cost
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro g8_calculate_other_update_factor();

   *all services not categorized as IPPS, PB, IRF, SNF, or HH are considered in the "other" category;
   *use the medicare economic index (MEI) as the update factor for the "other" category;
   data temp.other_post_anchor_update_factor (keep = other_year other_update_factor);

      set mei.medicare_economic_index;
      %do year = %eval(&baseline_start_year.+1) %to &baseline_end_year.;
         other_year = &year.;
         %do yr = &year. %to &update_factor_cy.;
            %let yr_last_2_digits = %sysfunc(substr("&yr.", 4, 2));
            mei_rate_&yr. = cy_&yr_last_2_digits.;
         %end;
         other_update_factor = ((1 + mei_rate_&year./100)**&other_cur_yr_wgt.) * %do yr = %eval(&year.+1) %to &update_factor_cy.; (1 + mei_rate_&yr./100) %if &yr. ^= &update_factor_cy. %then *; %end;;
         output temp.other_post_anchor_update_factor;
      %end;

   run;
   
%mend; 
