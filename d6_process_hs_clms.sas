/*************************************************************************;
%** PROGRAM: d6_process_sn_clms.sas
%** PURPOSE: To identify qualifying HS claims to be grouped to episodes 
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/


%macro d6_process_hs_clms();

   data temp.grp_hs_clms_to_epi (drop = mccm_code mccm_code_type billing_code billing_type demo_code)
        temp.ungrp_hs_clms_to_epi(drop = mccm_code mccm_code_type billing_code billing_type demo_code); 

      if _n_ = 1 then do;

         *list of codes for identifying medicare care choices model PBPM for exclusion;
         if 0 then set temp.excluded_mccm_pbpm (keep = mccm_code_type mccm_code);
         declare hash mccm_pbpm (dataset: "temp.excluded_mccm_pbpm (keep = mccm_code_type mccm_code)");
         mccm_pbpm.definekey("mccm_code");
         mccm_pbpm.definedata("mccm_code_type");
         mccm_pbpm.definedone();

      end;
      call missing(of _all_);

      set temp.hs_clms_to_epi;

      *flag if the billing code is MCCM;
      billing_code = catt(fac_type, typesrvc);
      if (mccm_pbpm.find(key: billing_code) = 0) then do;
         if (lowcase(mccm_code_type) = "billing code") then billing_type = 1;
      end;

      *check if the demonstration code is MCCM;
      %do a = 1 %to &demo_array_size.;
         %let b = %sysfunc(putn(&a., z2.));
         if (mccm_pbpm.find(key: demonum&b.) = 0) then do;
            if (lowcase(mccm_code_type) = "demonstration code") then demo_code = 1;
         end;
         %if &a. ^= &demo_array_size. %then else;
      %end;

      *flag claim for exclusion if MCCM;
      if (billing_type = 1) and (demo_code = 1) then mccm_pbpm_flag = 1;
         
      *for when proration is needed;
      if (service_start_dt ^= service_end_dt) and (anchor_beg_dt <= service_start_dt) and ((service_start_dt < anchor_end_dt <= service_end_dt) or (service_start_dt <= post_dsch_end_dt < service_end_dt) or (service_start_dt <= post_epi_end_dt < service_end_dt)) then do;

         prorated = 1;
         *calculate the number of days overlapping each period;
         if (service_start_dt < anchor_end_dt <= service_end_dt) then do;
            anchor_overlap_days = (min(anchor_end_dt , service_end_dt) - max(anchor_beg_dt, service_start_dt));
            if (anchor_overlap_days > 0) then catgry_num = catgry_num + 1;
         end;
         if (service_start_dt < post_dsch_beg_dt <= service_end_dt) or (service_start_dt <= post_dsch_end_dt < service_end_dt) then do;
            post_dschrg_overlap_days = (min(post_dsch_end_dt, service_end_dt) - max(post_dsch_beg_dt, service_start_dt)) + 1;
            if (post_dschrg_overlap_days > 0) then catgry_num = catgry_num + 1;
         end;
         if (service_start_dt < post_epi_beg_dt <= service_end_dt) or (service_start_dt <= post_epi_end_dt < service_end_dt) then do;
            post_epi_overlap_days = (min(post_epi_end_dt, service_end_dt) - max(post_epi_beg_dt, service_start_dt)) + 1;
            if (post_epi_overlap_days > 0) then catgry_num = catgry_num + 1;
         end;

         *define cost category;
         if (catgry_num = 3) then do;
            cost_category = catx(" ", "prorated -", catx(", ", %do a = 1 %to &ncatgry_types.; "&&catgry_labels&a.." %if &a. ^= &ncatgry_types. %then ,; %end;), " periods");
         end;
         else if (catgry_num = 2) then do;
            %do a = 1 %to &ncatgry_types.;
               %do b = 1 %to &ncatgry_types.;
                  %if "&&catgry_types&a.." ^= "&&catgry_types&b.." %then %do;
                     if (&&catgry_types&a.._overlap_days > 0) and (&&catgry_types&b.._overlap_days > 0) then cost_category = "prorated - &&catgry_labels&a.. and &&catgry_labels&b.. periods";
                     %if (&a. ^= &ncatgry_types.) or (&a. = &ncatgry_types. and &b. ^= &ncatgry_types.) %then else;
                  %end;
               %end;
            %end;
         end;
         else if (catgry_num = 1) then do;
            %do a = 1 %to &ncatgry_types.;
               if (&&catgry_types&a.._overlap_days > 0) then cost_category = "prorated - &&catgry_labels&a.. period only";
            %end;
         end;

      end;

      *for when proration is not needed;
      else do;
         if (anchor_beg_dt <= service_start_dt < anchor_end_dt) then cost_category = "anchor period";
         else if (post_dsch_beg_dt <= service_start_dt <= post_dsch_end_dt) then cost_category = "post-discharged period";
         else if (post_epi_beg_dt <= service_start_dt <= post_epi_end_dt) then cost_category = "post-episode period";
      end;

      tot_overlap_days = sum(anchor_overlap_days, post_dschrg_overlap_days, post_epi_overlap_days);
      
      *flag COVID-19 claims;
      *COVID-19;
      if (service_start_dt >= "01APR2020"D) or (service_end_dt >= "01APR2020"D) then do;
         *check claim diagnosis codes;
         %do a = 1 %to &diag_proc_length.;
            %let b = %sysfunc(putn(&a., z2.));
            if (dgnscd&b. in (&covid_19_cds.)) then covid_19_clm = 1;
            %if &a. ^= &diag_proc_length. %then else;
         %end;
      end; %*end of COVID-19;
      *other coronavirus as the cause of diseases classified elsewhere;
      if covid_19_clm = 0 and ((service_start_dt > "27JAN2020"D) or (service_end_dt > "27JAN2020"D)) then do;
         *check claim diagnosis codes;
         %do a = 1 %to &diag_proc_length.;
            %let b = %sysfunc(putn(&a., z2.));
            if (dgnscd&b. in (&other_corona_cds.)) then covid_19_clm = 1;
            %if &a. ^= &diag_proc_length. %then else;
         %end;
      end; %*end of other coronavirus;

      *determine if claim should be grouped;
      if (non_positive_payment = 0) and (non_medicare_prpayer = 0) and (mccm_pbpm_flag = 0) and (lowcase(cost_category) ^= "unattributed") then grouped = 1;

      if (grouped = 1) then output temp.grp_hs_clms_to_epi;
      else if (grouped = 0) then output temp.ungrp_hs_clms_to_epi;

   run;
%mend; 