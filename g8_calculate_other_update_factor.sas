/*************************************************************************;
%** PROGRAM: g8_calculate_other_update_factor.sas
%** PURPOSE: To calculate other update factor (MEI) for post-anchor period cost
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
