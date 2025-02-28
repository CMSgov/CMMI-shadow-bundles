/*************************************************************************;
%** PROGRAM: d3_process_ip_clms.sas
%** PURPOSE: To identify qualifying IP stays to be grouped to episodes 
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro d3_process_ip_clms();

  *maximum number of IP transfers;
   data _null_;
      set temp.max_ip_transfers;
      call symputx("max_num_trans", value);
   run;

   data temp.grp_ip_clms_to_epi (drop = rc_: ms_drg geo_year drg ip_year pci_drg pci_hcpcs tavr_drg icd9_icd10 procedure_cd anchor_drg_&update_factor_fy. pci_tavr_flag)
        temp.ungrp_ip_clms_to_epi (drop = rc_: ms_drg geo_year drg ip_year pci_drg pci_hcpcs tavr_drg icd9_icd10 procedure_cd anchor_drg_&update_factor_fy. pci_tavr_flag)
        ;

      length episode_id ip_stay_id link_id 8. provider $6. service_start_dt service_end_dt 8. drg_cd $3.;
      format service_start_dt service_end_dt date9.;
      if _n_ = 1 then do;

         *list of readmission exclusion drg codes;
         if 0 then set temp.excluded_readmissions (keep = ms_drg);
         declare hash excl_readmsn (dataset: "temp.excluded_readmissions (keep = ms_drg)");
         excl_readmsn.definekey("ms_drg");
         excl_readmsn.definedata("ms_drg");
         excl_readmsn.definedone();

         *list of geomteric mean length of stay for each drg code;
         if 0 then set temp.stacked_gmlos_&query_start_year._&query_end_year. (keep = geo_year drg gmlos);
         declare hash geo_los (dataset: "temp.stacked_gmlos_&query_start_year._&query_end_year. (keep = geo_year drg gmlos)");
         geo_los.definekey("geo_year", "drg");
         geo_los.definedata("gmlos");
         geo_los.definedone();

         *keep track of the ip stays that were excluded due to having an excluded readmission drg code for use later in excluding pb claims;
         declare hash excl_ip (ordered: "a");
         excl_ip.definekey("episode_id", "ip_stay_id");
         excl_ip.definedata("episode_id", "ip_stay_id", "link_id", "provider", "service_start_dt", "service_end_dt", "drg_&update_factor_fy.");
         excl_ip.definedone();
         
         *list of MDC to be excluded;
         if 0 then set temp.excluded_mdc (keep = mdc);
         declare hash h_mdc (dataset: "temp.excluded_mdc (keep = mdc)");
         h_mdc.definekey("mdc");
         h_mdc.definedone();
         
         *keep track of the ip stays that were excluded due to having an excluded MDC for use later in excluding pb claims;
         declare hash excl_mdc (ordered: "a");
         excl_mdc.definekey("episode_id", "ip_stay_id");
         excl_mdc.definedata("episode_id", "ip_stay_id", "mdc", "link_id", "provider", "service_start_dt", "service_end_dt", "drg_&update_factor_fy.");
         excl_mdc.definedone();

         *list of PCI episode trigger codes to identify IP PCI;
         if 0 then set temp.ip_anchor_episode_list (keep = drg_cd rename = (drg_cd = pci_drg));
         declare hash ip_pci_cds (dataset: "temp.ip_anchor_episode_list (keep = episode_group_name drg_cd rename = (drg_cd = pci_drg) where = (upcase(strip(episode_group_name)) = 'IP-PERCUTANEOUS CORONARY INTERVENTION'))");
         ip_pci_cds.definekey("pci_drg");
         ip_pci_cds.definedone();
         
         *list of PCI episode trigger codes to identify OP PCI;
         if 0 then set temp.op_anchor_episode_list (keep = hcpcs_cd rename = (hcpcs_cd = pci_hcpcs));
         declare hash op_pci_cds (dataset: "temp.op_anchor_episode_list (keep = episode_group_name hcpcs_cd rename = (hcpcs_cd = pci_hcpcs) where = (upcase(strip(episode_group_name)) = 'OP-PERCUTANEOUS CORONARY INTERVENTION'))");
         op_pci_cds.definekey("pci_hcpcs");
         op_pci_cds.definedone();
         
         *list of TAVR episode trigger codes for exclusion from PCI;
         if 0 then set temp.ip_anchor_episode_list (keep = drg_cd rename = (drg_cd = tavr_drg));
         declare hash tavr_cds (dataset: "temp.ip_anchor_episode_list (keep = episode_group_name drg_cd rename = (drg_cd = tavr_drg) where = (upcase(strip(episode_group_name)) = 'IP-TRANSCATHETER AORTIC VALVE REPLACEMENT'))");
         tavr_cds.definekey("tavr_drg");
         tavr_cds.definedone();

         *list of TAVR procedure codes ICD9;
         if 0 then set temp.tavr_procedure_codes (keep = procedure_cd icd9_icd10 where = (upcase(icd9_icd10) = 'ICD-9'));
         declare hash tavr_icd9 (dataset: "temp.tavr_procedure_codes (keep = procedure_cd icd9_icd10 where = (upcase(icd9_icd10) = 'ICD-9'))");
         tavr_icd9.definekey("procedure_cd");
         tavr_icd9.definedata("icd9_icd10");
         tavr_icd9.definedone();

         *list of TAVR procedure codes ICD10;
         if 0 then set temp.tavr_procedure_codes (keep = procedure_cd icd9_icd10 where = (upcase(icd9_icd10) = 'ICD-10'));
         declare hash tavr_icd10 (dataset: "temp.tavr_procedure_codes (keep = procedure_cd icd9_icd10 where = (upcase(icd9_icd10) = 'ICD-10'))");
         tavr_icd10.definekey("procedure_cd");
         tavr_icd10.definedata("icd9_icd10");
         tavr_icd10.definedone();
         
         *keep track of the ip stays that were excluded due to having an excluded PCI-TAVR code for use later in excluding pb claims;
         declare hash excl_pci_tavr (ordered: "a");
         excl_pci_tavr.definekey("episode_id", "ip_stay_id");
         excl_pci_tavr.definedata("episode_id", "ip_stay_id", "anchor_drg_&update_factor_fy.", "link_id", "provider", "service_start_dt", "service_end_dt", "drg_&update_factor_fy.");
         excl_pci_tavr.definedone();

      end;
      call missing(of _all_);

      set temp.ip_clms_to_epi end = last;

      *merge on geometric mean length of stay;
      *determine which fiscal year an IP anchor episode falls within since DRG assignment and GMLOS are based on a fiscal year;
      %do year = &query_start_year. %to &query_end_year.;
         %let prev_year = %eval(&year.-1);
         if ("01OCT&prev_year."D <= service_end_dt <= "30SEP&year."D) then ip_year = &year.;
         %if &year. ^= &query_end_year. %then else;
      %end;
      rc_geo_los = geo_los.find(key: ip_year, key: drg_cd);

      *anchor period claims;
      *grab the anchoring IP stay and all IP stay in the chain of transfer;
      if (ip_stay_id = anchor_stay_id) or ((transfer_stay = 1) and (%do a = 1 %to &max_num_trans.; (ip_stay_id = trans_ip_stay_&a.) %if &a. ^= &max_num_trans. %then or; %end;)) then do;
         grouped = 1;
         cost_category = "anchor period";
         anchor_overlap_days = service_end_dt - service_start_dt; 
         if ((transfer_stay = 1) and (%do a = 1 %to &max_num_trans.; (ip_stay_id = trans_ip_stay_&a.) %if &a. ^= &max_num_trans. %then or; %end;)) then part_of_transfer_flag = 1;
      end;

      *post-discharge and post-episode claims;
      else if (lowcase(anchor_type) = "op") or ((lowcase(anchor_type) = "ip") and (anchor_end_dt <= service_start_dt)) then do;

         *for when proration is needed;
         if (service_start_dt <= post_dsch_end_dt < service_end_dt) or (service_start_dt <= post_epi_end_dt < service_end_dt) then do;

            prorated = 1;
            *calculate the number of overlap days for each period;
            if (service_start_dt <= post_dsch_end_dt < service_end_dt) then do;
               post_dschrg_overlap_days = (min(post_dsch_end_dt, service_end_dt) - max(post_dsch_beg_dt, service_start_dt)) + 1;
               if (post_dschrg_overlap_days > 0) then catgry_num = catgry_num + 1;
            end;
            if (service_start_dt < post_epi_beg_dt <= service_end_dt) or (service_start_dt <= post_epi_end_dt < service_end_dt) then do;
               post_epi_overlap_days = (min(post_epi_end_dt, service_end_dt) - max(post_epi_beg_dt, service_start_dt)) + 1;
               if (post_epi_overlap_days > 0) then catgry_num = catgry_num + 1;
            end;

            *define cost category;
            if (catgry_num = 2) then do;
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
            if (post_dsch_beg_dt <= service_start_dt <= post_dsch_end_dt) then cost_category = "post-discharged period";
            else if (post_epi_beg_dt <= service_start_dt <= post_epi_end_dt) then cost_category = "post-episode period";
         end;

      end;

      *calculate the total number of overlap days;
      tot_overlap_days = sum(anchor_overlap_days, post_dschrg_overlap_days, post_epi_overlap_days);

      *determine if claim is an excluded readmission;
      if (excl_readmsn.find(key: drg_&update_factor_fy.) = 0) then do;
         excluded_readmission = 1;
         *keep track of all post-discharge/post-episode ip stays that have been excluded for use later in PB grouping;
         if (non_positive_payment = 0) and (non_medicare_prpayer = 0) and (excluded_readmission = 1) and
            (lowcase(cost_category) in ("post-discharged period" "post-episode period" "prorated - post-discharged and post-episode periods" "prorated - post-discharged period only" "prorated - post-episode period only")) then do;
            if (excl_ip.find(key: episode_id, key: ip_stay_id) ^= 0) then excl_ip.add();
         end;
      end;
      
      *determine if claim has excluded MDC;
      if (h_mdc.find(key: mdc) = 0) then do;
         excluded_mdc = 1;
         *keep track of all post-discharge/post-episode ip stays that have been excluded for use later in PB grouping;
         if (non_positive_payment = 0) and (non_medicare_prpayer = 0) and (excluded_mdc = 1) and
            (lowcase(cost_category) in ("post-discharged period" "post-episode period" "prorated - post-discharged and post-episode periods" "prorated - post-discharged period only" "prorated - post-episode period only")) then do;
            if (excl_mdc.find(key: episode_id, key: ip_stay_id) ^= 0) then excl_mdc.add();
         end;
      end;

      *determine if IP or OP PCI episodes has TAVR inpatient stays;
      pci_tavr_flag = 0;
      if (lowcase(anchor_type) = "ip" and ip_pci_cds.find(key: anchor_drg_&update_factor_fy.) = 0) or (lowcase(anchor_type) = "op" and op_pci_cds.find(key: anchor_trigger_cd) = 0) then do;
         if (tavr_cds.find(key: drg_&update_factor_fy.) = 0) then do;
            if (service_end_dt < "&icd9_icd10_date."D) then do;
               %do a = 1 %to &diag_proc_length.;
                  %let b = %sysfunc(putn(&a., z2.));
                  if (tavr_icd9.find(key: prcdrcd&b.) = 0) then pci_tavr_flag = 1;
                  %if &a. ^= &diag_proc_length. %then else;
               %end;
            end;
            else do;
               %do a = 1 %to &diag_proc_length.;
                  %let b = %sysfunc(putn(&a., z2.));
                  if (tavr_icd10.find(key: prcdrcd&b.) = 0) then pci_tavr_flag = 1;
                  %if &a. ^= &diag_proc_length. %then else;
               %end;
            end;
            if pci_tavr_flag = 1 then do;
               excluded_pci_tavr = 1;
               *do not turn on pci tavr exclusion for post-episode period;
               if (lowcase(cost_category) in ("post-episode period" "prorated - post-episode period only")) then do;
                  excluded_pci_tavr = 0;
               end;
               *keep track of all post-discharge ip stays that have been excluded for use later in PB grouping;
               if (non_positive_payment = 0) and (non_medicare_prpayer = 0) and (excluded_pci_tavr = 1) and
                  (lowcase(cost_category) in ("post-discharged period" "prorated - post-discharged and post-episode periods" "prorated - post-discharged period only")) then do;
                  if (excl_pci_tavr.find(key: episode_id, key: ip_stay_id) ^= 0) then excl_pci_tavr.add();
               end;
            end;
         end; %*end of TAVR stays identification;
      end; %*end of PCI episodes identification;
      
      *flag COVID-19 claims;
      *COVID-19;
      if (service_start_dt >= "01APR2020"D) or (service_end_dt >= "01APR2020"D) then do;
         *check claim admitting diagnosis code;
         if (ad_dgns in (&covid_19_cds.)) then covid_19_clm = 1;
         *check claim diagnosis codes;
         else do;
            %do a = 1 %to &diag_proc_length.;
               %let b = %sysfunc(putn(&a., z2.));
               if (dgnscd&b. in (&covid_19_cds.)) then covid_19_clm = 1;
               %if &a. ^= &diag_proc_length. %then else;
            %end;
         end;
      end; %*end of COVID-19;
      *other coronavirus as the cause of diseases classified elsewhere;
      if covid_19_clm = 0 and ((service_start_dt > "27JAN2020"D) or (service_end_dt > "27JAN2020"D)) then do;
         *check claim admitting diagnosis code;
         if (ad_dgns in (&other_corona_cds.)) then covid_19_clm = 1;
         *check claim diagnosis codes;
         else do;
            %do a = 1 %to &diag_proc_length.;
               %let b = %sysfunc(putn(&a., z2.));
               if (dgnscd&b. in (&other_corona_cds.)) then covid_19_clm = 1;
               %if &a. ^= &diag_proc_length. %then else;
            %end;
         end;
      end; %*end of other coronavirus;

      *determine if claim should be grouped;
      if (non_positive_payment = 0) and (non_medicare_prpayer = 0) and (excluded_readmission = 0) and (excluded_mdc = 0) and (excluded_pci_tavr = 0) and (lowcase(cost_category) ^= "unattributed") then grouped = 1;

      if (grouped = 1) then output temp.grp_ip_clms_to_epi;
      else if (grouped = 0) then output temp.ungrp_ip_clms_to_epi;

      if last then excl_ip.output(dataset: "temp.excluded_readmsn_ip_stays");
      if last then excl_mdc.output(dataset: "temp.excluded_mdc_ip_stays");
      if last then excl_pci_tavr.output(dataset: "temp.excluded_pci_tavr_ip_stays");

   run;

%mend; 