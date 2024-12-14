/*************************************************************************;
%** PROGRAM: g6_calculate_sn_update_factor.sas
%** PURPOSE: To calculate SN update factor for post-anchor period cost
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

%macro g6_calculate_sn_update_factor();

   /*PROCESS SN CLAIMS TO BE USED IN CALCULATING UPDATE FACTOR*/
   
   *count the prior days associated with claims;
   proc sort data = clm_inp.sn (keep = link_id claimno provider from_dt admsn_dt dschrgdt thru_dt cr_day std_allowed prpayamt std_deductible std_coinsurance sgmt_num rvcntr: rvunt: hcpscd: dgnscd:)
             out = temp.sn;
      by link_id admsn_dt provider thru_dt claimno sgmt_num;
   run;

   data temp.sn;
      set temp.sn;
      by link_id admsn_dt;
      retain prior_day prev_cr_day;
      
      *count the prior days as sum of cr days for all prior claims (not the current claim) on or after 01OCT2019;
      if first.admsn_dt then do;
         prior_day = 0;
         prev_cr_day = 0;
      end;
      else prior_day = prior_day + prev_cr_day;
      if from_dt >= "01OCT2019"D then prev_cr_day = cr_day;
      else prev_cr_day = 0;
      
      *determine fiscal year based on through date with an exception;
      %do year = &query_start_year. %to &query_end_year.;
         %let prev_year = %eval(&year.-1);
         if ("01OCT&prev_year."D <= thru_dt <= "30SEP&year."D) then fiscal_yr = &year.;
         %if &year. ^= &query_end_year. %then else;
      %end;
      if (fiscal_yr = 2020) and (from_dt < "01OCT2019"D and thru_dt = "01OCT2019"D) then fiscal_yr = 2019;
      
      *create AIDS flag using primary and secondary diagnosis codes for claims in or after FY2016;
      aids_flag = 0;
      if fiscal_yr >= 2016 then do;
         %do a = 1 %to &diag_proc_length.;
            %let b = %sysfunc(putn(&a., z2.));
            if substr(dgnscd&b., 1, 3) = "B20" then aids_flag = 1;
            %if &a. ^= &diag_proc_length. %then else;
         %end;
      end;
   run;

   *get SNF claims for FY2020 and beyond with revenue center 0022;
   data temp.sn_lines_pdpm (drop = fac_code fac_code_descrip);

      if _n_ = 1 then do;
         *list of revenue center code identifying a SNF;
         if 0 then set temp.facility_rev_center_codes (keep = fac_code fac_code_descrip where = (lowcase(fac_code_descrip) = "skilled nursing facility"));
         declare hash snf_rev (dataset: "temp.facility_rev_center_codes (keep = fac_code fac_code_descrip where = (lowcase(fac_code_descrip) = 'skilled nursing facility'))");
         snf_rev.definekey("fac_code");
         snf_rev.definedone();
      end;
      call missing(of _all_);
      
      set temp.sn (where = (fiscal_yr >= 2020));

      %do a = 1 %to &rev_array_size.;
         %let b = %sysfunc(putn(&a., z2.));
         rvcntr = rvcntr&b.;
         rvunt = rvunt&b.;
         hcpscd = hcpscd&b.;
         pdpm = substr(hcpscd, 1, 4);
         *do not use a SNF line if the HCPCS is missing regardless of whether the revenue unit is populated;
         if (not missing(hcpscd)) and (upcase(pdpm) ^= "ZZZZ") and (snf_rev.find(key: rvcntr) = 0) then do;
            *modify the 4th character if AIDS flag is on;
            if aids_flag = 1 then do;
               if substr(pdpm, 4) in ("A", "B", "C", "D") then pdpm = compress(substr(hcpscd, 1, 3)||"A");
               else if substr(pdpm, 4) = "E" then pdpm = compress(substr(hcpscd, 1, 3)||"B");
               else if substr(pdpm, 4) = "F" then pdpm = compress(substr(hcpscd, 1, 3)||"C");
            end;
            output temp.sn_lines_pdpm;
         end;
      %end;
   run;

   *count the line level prior days for PDPM codes assiciated with each claim;
   proc sort data = temp.sn_lines_pdpm;
      by claimno;
   run;

   data temp.sn_lines_pdpm_split (drop = %do a = 1 %to &rev_array_size.; %let b = %sysfunc(putn(&a., z2.)); rvcntr&b. rvunt&b. hcpscd&b. %end; dgnscd: prev_: x);
      set temp.sn_lines_pdpm;
      by claimno;
      retain line_prior_day prev_rvunt;
      *count the line prior days as sum of prior days on claim and revenue units for all prior lines;
      if first.claimno then do;
         line_prior_day = prior_day;
         prev_rvunt = 0;
      end;
      else line_prior_day = line_prior_day + prev_rvunt;
      prev_rvunt = rvunt;
      *for each PDPM, split the corresponding n revenue units into n days and output one by one;
      x = 1;
      do while (x <= rvunt);
         vpd_day = line_prior_day + x;
         x = x + 1;
         output temp.sn_lines_pdpm_split;
      end;
   run;

   *calculate pdpm urban rate and pdpm rural rate;
   data temp.sn_lines_pdpm_split (drop = pdpm_group urban_rural rc_: vpd_day_key);

      if _n_ = 1 then do;

         *get PDPM rates for FY2020 and beyond;
         %do year = 2020 %to &update_factor_fy.;
            *urban rates;
            if 0 then set pdpm.sn_pdpm_rates_&year. (rename = (pt_rate = pt_rate_urban_&year. ot_rate = ot_rate_urban_&year. slp_rate = slp_rate_urban_&year. nursing_rate = nursing_rate_urban_&year. nta_rate = nta_rate_urban_&year.));
            declare hash pdpmu&year. (dataset: "pdpm.sn_pdpm_rates_&year. (rename = (pt_rate = pt_rate_urban_&year. ot_rate = ot_rate_urban_&year. slp_rate = slp_rate_urban_&year. nursing_rate = nursing_rate_urban_&year. nta_rate = nta_rate_urban_&year.) where = (lowcase(urban_rural) = 'urban'))");
            pdpmu&year..definekey("pdpm_group");
            pdpmu&year..definedata("pt_rate_urban_&year.", "ot_rate_urban_&year.", "slp_rate_urban_&year.", "nursing_rate_urban_&year.", "nta_rate_urban_&year.");
            pdpmu&year..definedone();

            *rural rates;
            if 0 then set pdpm.sn_pdpm_rates_&year. (rename = (pt_rate = pt_rate_rural_&year. ot_rate = ot_rate_rural_&year. slp_rate = slp_rate_rural_&year. nursing_rate = nursing_rate_rural_&year. nta_rate = nta_rate_rural_&year.));
            declare hash pdpmr&year. (dataset: "pdpm.sn_pdpm_rates_&year. (rename = (pt_rate = pt_rate_rural_&year. ot_rate = ot_rate_rural_&year. slp_rate = slp_rate_rural_&year. nursing_rate = nursing_rate_rural_&year. nta_rate = nta_rate_rural_&year.) where = (lowcase(urban_rural) = 'rural'))");
            pdpmr&year..definekey("pdpm_group");
            pdpmr&year..definedata("pt_rate_rural_&year.", "ot_rate_rural_&year.", "slp_rate_rural_&year.", "nursing_rate_rural_&year.", "nta_rate_rural_&year.");
            pdpmr&year..definedone();
         %end;
         
         *get vpd_pt_ot and vpd_nta for corresponding vpd_day, currently VPD does not change since 2020;
         %*notes: check for any update regarding VPD and use it accordingly;
         if 0 then set vpd.sn_vpd_2020;
         declare hash vpd2020 (dataset: "vpd.sn_vpd_2020 (rename = (vpd_pt_ot = vpd_pt_ot_2020 vpd_nta = vpd_nta_2020))");
         vpd2020.definekey("vpd_day");
         vpd2020.definedata("vpd_pt_ot_2020", "vpd_nta_2020");
         vpd2020.definedone();
         
      end;
      call missing(of _all_);
      set temp.sn_lines_pdpm_split;

      *get urban rates, rural rates and vpd for FY2020 and beyond;
      %do year = 2020 %to &update_factor_fy.;
         rc_pdpmu&year._finder = pdpmu&year..find(key: pdpm);
         rc_pdpmr&year._finder = pdpmr&year..find(key: pdpm);
      %end;
      
      *get vpd_pt_ot and vpd_nta of 100 for vpd > 100;
      if vpd_day > 100 then vpd_day_key = 100;
      else vpd_day_key = vpd_day;
      rc_vpd2020_finder = vpd2020.find(key: vpd_day_key);
            
      *calculate pdpm urban rate and pdpm rural rate;
      %do year = 2020 %to &update_factor_fy.;
         pdpm_urban_rate_&year. = pt_rate_urban_&year.*vpd_pt_ot_2020 + ot_rate_urban_&year.*vpd_pt_ot_2020 + nta_rate_urban_&year.*vpd_nta_2020 + nursing_rate_urban_&year.*(aids_flag*&aids_nursing_adj.+1) + slp_rate_urban_&year. + &&sn_non_case_mix_urban_&year..;
         pdpm_rural_rate_&year. = pt_rate_rural_&year.*vpd_pt_ot_2020 + ot_rate_rural_&year.*vpd_pt_ot_2020 + nta_rate_rural_&year.*vpd_nta_2020 + nursing_rate_rural_&year.*(aids_flag*&aids_nursing_adj.+1) + slp_rate_rural_&year. + &&sn_non_case_mix_rural_&year..;
      %end;
      if %do year = 2020 %to &update_factor_fy.; %if &year. ^= 2020 %then and; not missing(pdpm_urban_rate_&year.) and not missing(pdpm_rural_rate_&year.) %end; then output;
   run;

   *calculate the total pdpm rate at claim level;
   proc sql noprint;
      create table temp.snf_pdpm_rates as
      select distinct claimno,
             link_id,
             admsn_dt,
             %do year = 2020 %to &update_factor_fy.;
                sum(pdpm_urban_rate_&year.) as total_pdpm_urban_rate_&year.,
                sum(pdpm_rural_rate_&year.) as total_pdpm_rural_rate_&year.,
                mean(calculated total_pdpm_urban_rate_&year., calculated total_pdpm_rural_rate_&year.) as total_pdpm_rate_&year. %if &year. ^= &update_factor_fy. %then ,;
             %end;
      from temp.sn_lines_pdpm_split
      group by claimno;
   quit;
   
   *attach total pdpm rate to episodes in FY2020 and beyond;
   data temp.grp_sn_w_pdpm_rate (drop = rc_: %do a = 1 %to &rev_array_size.; %let b = %sysfunc(putn(&a., z2.)); rvcntr&b. rvunt&b. hcpscd&b. %end; fac_code fac_code_descrip cah_code ssnf_code swing_bed);
   
      if _n_ = 1 then do;
      
         *list of code identifying a critical access hospital;
         if 0 then set temp.cah_codes (keep = cah_code);
         declare hash get_cahs (dataset: "temp.cah_codes (keep = cah_code)");
         get_cahs.definekey("cah_code");
         get_cahs.definedone();

         *list of code identifying a swing bed hospital in the SNF setting;
         if 0 then set temp.ssnf_codes (keep = ssnf_code swing_bed where = (lowcase(swing_bed) = "y"));
         declare hash swing (dataset: "temp.ssnf_codes (keep = ssnf_code swing_bed where = (lowcase(swing_bed) = 'y'))");
         swing.definekey("ssnf_code");
         swing.definedone();
         
         *list of revenue center code identifying a SNF;
         if 0 then set temp.facility_rev_center_codes (keep = fac_code fac_code_descrip where = (lowcase(fac_code_descrip) = "skilled nursing facility"));
         declare hash snf_rev (dataset: "temp.facility_rev_center_codes (keep = fac_code fac_code_descrip where = (lowcase(fac_code_descrip) = 'skilled nursing facility'))");
         snf_rev.definekey("fac_code");
         snf_rev.definedone();

         *total pdpm rate at claim level;
         if 0 then set temp.snf_pdpm_rates (keep = claimno total_pdpm_rate_:);
         declare hash get_rate (dataset: "temp.snf_pdpm_rates (keep = claimno total_pdpm_rate_:)");
         get_rate.definekey("claimno");
         get_rate.definedata(all: "yes");
         get_rate.definedone();

      end;
      call missing(of _all_);

      set temp.grp_sn_for_updates (where = (anchor_end_dt >= "01OCT2019"D));

      
      *filter down to SNF providers that are not critical access hospitals and not a swing-bed;
      if (get_cahs.find(key: substr(provider, 3, 4)) ^= 0) and (swing.find(key: substr(provider, 3, 1)) ^= 0) then do;

         *determine snf year as fiscal year of anchor end date;
         %do year = &baseline_start_year. %to &baseline_end_year.;
            %let prev_year = %eval(&year.-1);
            if ("01OCT&prev_year."D <= anchor_end_dt <= "30SEP&year."D) then snf_year = &year.;
            %if &year. ^= &baseline_end_year. %then else;
         %end;
         
         *add PDPM rates to SNF claims;
         rc_get_rate = get_rate.find(key: claimno);
         
         *dertermine total pdpm rate of the corresponding episode year;
         %do year = 2020 %to &baseline_end_year.;
            if (snf_year = &year.) then total_pdpm_rate = total_pdpm_rate_&year.;
            %if &year. ^= &baseline_end_year. %then else;
         %end;

         *filter to claims with at least one SNF facility code 0022;
         flag_snf_fac_code = 0;
         %do a = 1 %to &rev_array_size.;
            %let b = %sysfunc(putn(&a., z2.));
            if (not missing (hcpscd&b.)) and (snf_rev.find(key: rvcntr&b.) = 0) then flag_snf_fac_code = 1;
            %if &b. ^= &rev_array_size. %then else;
         %end;
         
         *exclude claims with excluded PDPM code ZZZZ only;
         count_snf_fac_code = 0;
         count_excl_pdpm = 0;
         flag_excl_pdpm = 0;
         %do a = 1 %to &rev_array_size.;
            %let b = %sysfunc(putn(&a., z2.));
            if (not missing (hcpscd&b.)) and (snf_rev.find(key: rvcntr&b.) = 0) then do;
               count_snf_fac_code = count_snf_fac_code + 1;
               if upcase(substr(hcpscd&b., 1, 4)) = "ZZZZ" then count_excl_pdpm = count_excl_pdpm + 1;
            end;
         %end;
         
         if (count_snf_fac_code ^= 0) and (count_excl_pdpm ^= 0) and (count_snf_fac_code = count_excl_pdpm) then flag_excl_pdpm = 1;
         if flag_snf_fac_code = 1 and flag_excl_pdpm = 0 then output temp.grp_sn_w_pdpm_rate;
      end;

      
   run;

   /*CALCULATE SN UPDATE FACTOR*/
   proc sql;
      create table temp.sn_post_anchor_update_factor as
      select anchor_provider,
             episode_group_name,
             snf_year,
             count(distinct episode_id) as num_epis,
             count(distinct claimno) as num_claims,
             sum(total_pdpm_rate_&update_factor_fy.)/sum(total_pdpm_rate) as snf_update_factor
      from temp.grp_sn_w_pdpm_rate
      group by anchor_provider, episode_group_name, snf_year
      ;   
   quit;

%mend; 
