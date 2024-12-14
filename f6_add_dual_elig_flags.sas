/*************************************************************************;
%** PROGRAM: f6_add_dual_elig_flags.sas
%** PURPOSE: To add dual eligibility flag for beneficiaries that are eligible for both Medicare and Medicaid
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

%macro f6_add_dual_elig_flags();

   *list of input datasets to read in to create duals flags for;
   %macarray(input_ds, cleaned_ip_stays_w_remap episodes_w_prior_hosp);
   *list of output dataset names; 
   %macarray(out_ds,   cleaned_ip_stays_w_dual  episodes_w_duals);

   %do a = 1 %to &ninput_ds.;

      data temp.&&out_ds&a.. (drop = dual_elg_status dual_code mdcd_elgbl_yr mdcd_elgbl_mo %if "&&input_ds&a.." = "episodes_w_prior_hosp" %then %do; dschrg_year dschrg_month dschrg_fy_year %end;);
         
         length dschrg_year dschrg_month dschrg_fy_year full_dual partial_dual any_dual 8.;
         if _n_ = 1 then do;
            
            *list of dual status codes by beneficiary, year, and month;
            if 0 then set oth_inp.duals (keep = link_id mdcd_elgbl_yr mdcd_elgbl_mo dual_stus_cd);
            declare hash getdual (dataset: "oth_inp.duals (keep = link_id mdcd_elgbl_yr mdcd_elgbl_mo dual_stus_cd)");
            getdual.definekey("link_id", "mdcd_elgbl_yr", "mdcd_elgbl_mo");
            getdual.definedata("dual_stus_cd");
            getdual.definedone();

            *list of dual eligibility status codes;
            if 0 then set temp.dual_elgb_codes (keep = dual_code dual_elg_status);
            declare hash dual_status_cd (dataset: "temp.dual_elgb_codes (keep = dual_code dual_elg_status)");
            dual_status_cd.definekey("dual_code");
            dual_status_cd.definedata("dual_elg_status");
            dual_status_cd.definedone();

         end;
         call missing(of _all_);

         set temp.&&input_ds&a.. %if ("&&input_ds&a.." = "cleaned_ip_stays_w_remap") %then %do; (where = (overlap_keep_inner = 1)) %end;;

         %if "&&input_ds&a.." = "cleaned_ip_stays_w_remap" %then %do;
            dschrg_year = year(dschrgdt);
            dschrg_month = month(dschrgdt);
            
            *determine fiscal year of discharge date;
            %do year = &query_start_year. %to %eval(&query_end_year.+1);
               %let prev_year = %eval(&year.-1);
               if ("01OCT&prev_year."D <= dschrgdt <= "30SEP&year."D) then dschrg_fy_year = &year.;
               %if &year. ^= %eval(&query_end_year.+1) %then else;
            %end;
         %end;
         %else %if "&&input_ds&a.." = "episodes_w_prior_hosp" %then %do;
            dschrg_year = year(anchor_end_dt);
            dschrg_month = month(anchor_end_dt);
            
            *determine fiscal year of anchor end date;
            %do year = &query_start_year. %to %eval(&query_end_year.+1);
               %let prev_year = %eval(&year.-1);
               if ("01OCT&prev_year."D <= anchor_end_dt <= "30SEP&year."D) then dschrg_fy_year = &year.;
               %if &year. ^= %eval(&query_end_year.+1) %then else;
            %end;
         %end;

         *initialize flags;
         partial_dual = 0;
         full_dual = 0;
         any_dual = 0;

         *flag if stay has partial or full dual eligibility;
         if (getdual.find(key: link_id, key: dschrg_year, key: dschrg_month) = 0) then do;
            if (dual_status_cd.find(key: dual_stus_cd) = 0) then do;
               if (lowcase(dual_elg_status) = "partial") then partial_dual = 1;
               else if (lowcase(dual_elg_status) = "full") then full_dual = 1;
               if (partial_dual = 1) or (full_dual = 1) or (lowcase(dual_elg_status) = "n/a") then any_dual = 1;
            end;
         end;

      run;

   %end;

%mend;
