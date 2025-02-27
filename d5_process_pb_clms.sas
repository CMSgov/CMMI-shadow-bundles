/*************************************************************************;
%** PROGRAM: d5_process_pb_clms.sas
%** PURPOSE: To identify qualifying PB claims grouped to episodes 
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro d5_process_pb_clms();
   
   data temp.grp_pb_clms_to_epi (drop = rc_: cy_year cy_quarter ed_date ip_stay_id service_start_dt_ip service_end_dt_ip ip_stay_id_mdc service_start_dt_mdc service_end_dt_mdc ip_stay_id_pci_tavr service_start_dt_pci_tavr service_end_dt_pci_tavr ocm_code eom_code clotting_factor plcsrvc_code plcsrvc_date_res drg_code anchor_drg_&update_factor_cy.)
        temp.ungrp_pb_clms_to_epi (drop = rc_: cy_year cy_quarter ed_date ip_stay_id service_start_dt_ip service_end_dt_ip ip_stay_id_mdc service_start_dt_mdc service_end_dt_mdc ip_stay_id_pci_tavr service_start_dt_pci_tavr service_end_dt_pci_tavr ocm_code eom_code clotting_factor plcsrvc_code plcsrvc_date_res drg_code anchor_drg_&update_factor_cy.);

      length cy_year cy_quarter 8.;
      if _n_ = 1 then do;

         *list of hemophilia/clotting factor drugs by year and quarter;
         %* _2 is the most updated processed version that is available at the time of running the program;
         %do year = &query_start_year. %to &query_end_year.;
            %if &year. ^= &query_end_year. %then %do;
               %do quart = 1 %to 4;
                  %if &year. = 2019 and &quart. = 3 %then %do;
                     if 0 then set hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1));
                     declare hash drug&year.q&quart. (dataset: "hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1))");
                  %end;
                  %else %if &year. = 2019 and &quart. = 4 %then %do;
                     if 0 then set hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1));
                     declare hash drug&year.q&quart. (dataset: "hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1))");
                  %end;
                  %else %if &year. = 2020 and &quart. = 1 %then %do;
                     if 0 then set hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1));
                     declare hash drug&year.q&quart. (dataset: "hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1))");
                  %end;
                  %else %if &year. = 2020 and &quart. = 2 %then %do;
                     if 0 then set hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1));
                     declare hash drug&year.q&quart. (dataset: "hemos.part_b_drug_asp_&year.q&quart._2 (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1))");
                  %end;
                  %else %do;
                     if 0 then set hemos.part_b_drug_asp_&year.q&quart. (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1));
                     declare hash drug&year.q&quart. (dataset: "hemos.part_b_drug_asp_&year.q&quart. (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1))");
                  %end;
                  drug&year.q&quart..definekey("hcpcs_cd");
                  drug&year.q&quart..definedone();
               %end;
            %end;
            %else %do;
               %do quart = 1 %to &hemo_quart_end.;
                  if 0 then set hemos.part_b_drug_asp_&year.q&quart. (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1));
                  declare hash drug&year.q&quart. (dataset: "hemos.part_b_drug_asp_&year.q&quart. (keep = hcpcs_cd clotting_factor where = (clotting_factor = 1))");
                  drug&year.q&quart..definekey("hcpcs_cd");
                  drug&year.q&quart..definedone();
               %end;
            %end;
         %end;

         *list of additional hemophilia codes to check for;
         if 0 then set temp.hemophilia_codes (keep = hcpcs_cd);
         declare hash hemo (dataset: "temp.hemophilia_codes (keep = hcpcs_cd)");
         hemo.definekey("hcpcs_cd");
         hemo.definedone();
         
         *list of part B drugs to be excluded;
         if 0 then set temp.excluded_part_b_drugs (keep = hcpcs_cd);
         declare hash partb (dataset: "temp.excluded_part_b_drugs (keep = hcpcs_cd)");
         partb.definekey("hcpcs_cd");
         partb.definedone();
         
         *list of cardiac rehab HCPCS for exclusion;
         if 0 then set temp.excluded_hcpcs_cr (keep = hcpcs_cd);
         declare hash hcpcs_cr (dataset: "temp.excluded_hcpcs_cr (keep = hcpcs_cd)");
         hcpcs_cr.definekey("hcpcs_cd");
         hcpcs_cr.definedone();
         
         *list of cardiac rehab place of service code for exclusion;
         if 0 then set temp.excluded_pcsrvc_cr (keep = plcsrvc_code plcsrvc_date_res);
         declare hash pcsrvc_cr (dataset: "temp.excluded_pcsrvc_cr (keep = plcsrvc_code plcsrvc_date_res)");
         pcsrvc_cr.definekey("plcsrvc_code");
         pcsrvc_cr.definedata("plcsrvc_date_res");
         pcsrvc_cr.definedone();

         *list of IBD related part B drugs for exclusion;
         if 0 then set temp.excluded_ibd_partb (keep = drg_code hcpcs_cd);
         declare hash ibd_partb (dataset: "temp.excluded_ibd_partb (keep = drg_code hcpcs_cd)");
         ibd_partb.definekey("drg_code", "hcpcs_cd");
         ibd_partb.definedone();

         *list of global days for each hcpcs code;
         %* _2 or _3 is the most updated processed version that is available at the time of running the program;
         %do year = &query_start_year. %to &query_end_year.;
            %if &year. ^= &query_end_year. %then %do; %let end_quart = 4; %end;
            %else %do; %let end_quart = &end_pfs_quarter.; %end;
            %do quart = 1 %to &end_quart.;
               %if &year. = 2018 and &quart. = 1 %then %do;
                  if 0 then set pfs.pfs_&year.q&quart._2_hcpcs_level (keep = hcpcs_cd glob_days_:); 
                  declare hash pfs&year._&quart. (dataset: "pfs.pfs_&year.q&quart._2_hcpcs_level (keep = hcpcs_cd glob_days_:)");
               %end;
               %else %if &year. = 2020 and &quart. = 1 %then %do;
                  if 0 then set pfs.pfs_&year.q&quart._3_hcpcs_level (keep = hcpcs_cd glob_days_:); 
                  declare hash pfs&year._&quart. (dataset: "pfs.pfs_&year.q&quart._3_hcpcs_level (keep = hcpcs_cd glob_days_:)");
               %end;
               %else %if &year. = 2020 and &quart. = 2 %then %do;
                  if 0 then set pfs.pfs_&year.q&quart._2_hcpcs_level (keep = hcpcs_cd glob_days_:); 
                  declare hash pfs&year._&quart. (dataset: "pfs.pfs_&year.q&quart._2_hcpcs_level (keep = hcpcs_cd glob_days_:)");
               %end;
               %else %do;
                  if 0 then set pfs.pfs_&year.q&quart._hcpcs_level (keep = hcpcs_cd glob_days_:); 
                  declare hash pfs&year._&quart. (dataset: "pfs.pfs_&year.q&quart._hcpcs_level (keep = hcpcs_cd glob_days_:)");
               %end;
               pfs&year._&quart..definekey("hcpcs_cd");
               pfs&year._&quart..definedata(all: "y");
               pfs&year._&quart..definedone();
            %end;               
         %end;

         *list of OP emergency department days;
         if 0 then set temp.op_ed_days (keep = episode_id ed_date);
         declare hash ed_days (dataset: "temp.op_ed_days (keep = episode_id ed_date)");
         ed_days.definekey("episode_id", "ed_date");
         ed_days.definedone();

         *list of excluded readmission ip stays;
         if 0 then set temp.excluded_readmsn_ip_stays (keep = episode_id ip_stay_id service_start_dt service_end_dt rename = (service_start_dt = service_start_dt_ip service_end_dt = service_end_dt_ip));
         declare hash excl_ip (dataset: "temp.excluded_readmsn_ip_stays (keep = episode_id ip_stay_id service_start_dt service_end_dt rename = (service_start_dt = service_start_dt_ip service_end_dt = service_end_dt_ip))", multidata: "y");
         excl_ip.definekey("episode_id");
         excl_ip.definedata("ip_stay_id", "service_start_dt_ip", "service_end_dt_ip");
         excl_ip.definedone();
         
         *list of excluded MDC ip stays;
         if 0 then set temp.excluded_mdc_ip_stays (keep = episode_id ip_stay_id service_start_dt service_end_dt rename = (ip_stay_id = ip_stay_id_mdc service_start_dt = service_start_dt_mdc service_end_dt = service_end_dt_mdc));
         declare hash excl_mdc (dataset: "temp.excluded_mdc_ip_stays (keep = episode_id ip_stay_id service_start_dt service_end_dt rename = (ip_stay_id = ip_stay_id_mdc service_start_dt = service_start_dt_mdc service_end_dt = service_end_dt_mdc))", multidata: "y");
         excl_mdc.definekey("episode_id");
         excl_mdc.definedata("ip_stay_id_mdc", "service_start_dt_mdc", "service_end_dt_mdc");
         excl_mdc.definedone();
         
         *list of excluded PCI-TAVR ip stays;
         if 0 then set temp.excluded_pci_tavr_ip_stays (keep = episode_id ip_stay_id service_start_dt service_end_dt rename = (ip_stay_id = ip_stay_id_pci_tavr service_start_dt = service_start_dt_pci_tavr service_end_dt = service_end_dt_pci_tavr));
         declare hash excl_pci_tavr (dataset: "temp.excluded_pci_tavr_ip_stays (keep = episode_id ip_stay_id service_start_dt service_end_dt rename = (ip_stay_id = ip_stay_id_pci_tavr service_start_dt = service_start_dt_pci_tavr service_end_dt = service_end_dt_pci_tavr))", multidata: "y");
         excl_pci_tavr.definekey("episode_id");
         excl_pci_tavr.definedata("ip_stay_id_pci_tavr", "service_start_dt_pci_tavr", "service_end_dt_pci_tavr");
         excl_pci_tavr.definedone();

         *list of allowable place of services;
         if 0 then set temp.place_of_service_codes (keep = plcsrvc);
         declare hash pos (dataset: "temp.place_of_service_codes (keep = plcsrvc)");
         pos.definekey("plcsrvc");
         pos.definedone();

         *list of codes identifying oncology care model per-beneficiary-per-month payments for exclusion;
         if 0 then set temp.excluded_ocm_pbpm (keep = ocm_code);
         declare hash ocm_pbpm (dataset: "temp.excluded_ocm_pbpm (keep = ocm_code)");
         ocm_pbpm.definekey("ocm_code");
         ocm_pbpm.definedone();
         
         *list of codes identifying enhanced oncology model per-beneficiary-per-month payments for exclusion;
         if 0 then set temp.excluded_eom_pbpm (keep = eom_code);
         declare hash eom_pbpm (dataset: "temp.excluded_eom_pbpm (keep = eom_code)");
         eom_pbpm.definekey("eom_code");
         eom_pbpm.definedone();
      end;
      call missing(of _all_);

      set temp.pb_clms_to_epi;

      *determine if claim has hemophilia code;
      cy_year = year(service_start_dt);
      cy_quarter = qtr(service_start_dt);
      if (hemo.find(key: hcpcs_cd) = 0) then hemophilia_flag = 1;
      else do;
         %do year = &query_start_year. %to &query_end_year.;
            %if &year. ^= &query_end_year. %then %do;
               %do quart = 1 %to 4;
                  if (cy_year = &year.) and (cy_quarter = &quart.) then do;
                     if (drug&year.q&quart..find(key: hcpcs_cd) = 0) then hemophilia_flag = 1;
                  end;
               %end;
            %end;
            %else %do;
               %do quart = 1 %to &hemo_quart_end.;
                  if (cy_year = &year.) and (cy_quarter = &quart.) then do;
                     if (drug&year.q&quart..find(key: hcpcs_cd) = 0) then hemophilia_flag = 1;
                  end;
               %end;
            %end;
         %end;
      end;
      
      *determine if claim has excluded part B drugs;
      if (partb.find(key: hcpcs_cd) = 0) then part_b_dropflag = 1;
      
      *determine if claim has excluded cardiac rehab place of service code;
      if (hcpcs_cr.find(key: hcpcs_cd) = 0) and (pcsrvc_cr.find(key: plcsrvc) = 0) and (service_start_dt >= plcsrvc_date_res) then excluded_cardiac_rehab = 1;
      
      *determine if claim has IBD related part B drugs;
      if (ibd_partb.find(key: anchor_drg_&update_factor_cy., key: hcpcs_cd) = 0) then excluded_ibd_partb = 1;

      *determine if claim is a global surgery;
      *merge on global day variables;      
      %do year = &query_start_year. %to &query_end_year.;
         %if &year. ^= &query_end_year. %then %do; %let end_quart = 4; %end;
         %else %do; %let end_quart = &end_pfs_quarter.; %end;
         %do quart = 1 %to &end_quart.;
            if (cy_year = &year.) and (cy_quarter = &quart.) then rc_pfs = pfs&year._&quart..find(key: hcpcs_cd);                                 
         %end;
      %end;    
         
      *check to see if any of the modifier codes on the PB is a GSC modifier code and if so, then use the global day variable associated with that modifier code;
      %do a = 1 %to &mdfr_cd_length_pb.;
         %do b = 1 %to &ngsc_modifiers.;
            if (mdfr_cd&a. = "&&gsc_modifiers&b..") then do;
               gsc_num = gsc_num + 1;
               if (not missing(glob_days_&&gsc_modifiers&b..)) and (glob_days_&&gsc_modifiers&b.. in (&gsc_glob_days_cds.)) then gsc_flag = 1;
            end;
            %if &b. ^= &ngsc_modifiers. %then else;
         %end;
      %end;

      *if claim does not have any of the GSC modifier codes on it then use the global_days_global variable for GSC checking;
      *NOTE: gsc_num = 0 implies that the PB claim does not have any GSC modifier codes found on it;
      if (gsc_flag = 0) and (gsc_num = 0) then do;
         if (not missing(glob_days_global)) and (glob_days_global in (&gsc_glob_days_cds.)) then gsc_flag = 1;
      end;

      *claims should have at most one GSC;
      *if more than one GSC found, then flag claim for exclusion;
      if (gsc_num > 1) then gsc_exclude = 1;

      *determine if claim is an emergency department code;
      *NOTE: PB claim has to occur on the same day as on OP emergency department claim to be considered an ED itself;
      if (plcsrvc in (&ed_pos_cds.)) then do;
         if (ed_days.find(key: episode_id, key: service_start_dt) = 0) then ed_flag = 1;
      end;

      *assign GSC and ED claims to the anchor period;
      if ((ed_flag = 1) or ((gsc_flag = 1) and (gsc_exclude ^= 1))) and (anchor_beg_dt - &gsc_ed_lookback_days. <= service_start_dt <= anchor_beg_dt) then cost_category = "anchor period";
      else do;
         *determine which cost category to attribute claim to;
         if (anchor_beg_dt <= service_start_dt < anchor_end_dt) then cost_category = "anchor period";
         else if ((service_end_dt = anchor_end_dt)) and (pos.find(key: plcsrvc) = 0) then cost_category = "anchor period";
         else if (post_dsch_beg_dt <= service_start_dt <= post_dsch_end_dt) then cost_category = "post-discharged period";
         else if (post_epi_beg_dt <= service_start_dt <= post_epi_end_dt) then cost_category = "post-episode period";
      end;

      *exclude pb claims that overlap with an excluded readmissions ip stay;
      *NOTE: if an excluded readmission starts on the discharge date of a triggering stay and pb claim has a certain place of service code, then do not exclude;
      if (excl_ip.find(key: episode_id) = 0) then do;
         rc_excl_ip = 0;
         do while (rc_excl_ip = 0);
            if not ((lowcase(cost_category) = "anchor period") and (non_positive_payment = 0) and (non_medicare_prpayer = 0)) then do;
               if (service_start_dt_ip <= service_start_dt <= service_end_dt_ip) then overlap_w_excluded_readmsn = 1;
            end;
            if (overlap_w_excluded_readmsn = 1) then rc_excl_ip = 1;
            else rc_excl_ip = excl_ip.find_next();
         end;
      end;
      
      *exclude pb claims that overlap with an excluded MDC ip stay;
      *NOTE: if an excluded MDC starts on the discharge date of a triggering stay and pb claim has a certain place of service code, then do not exclude;
      if (excl_mdc.find(key: episode_id) = 0) then do;
         rc_excl_mdc = 0;
         do while (rc_excl_mdc = 0);
            if not ((lowcase(cost_category) = "anchor period") and (non_positive_payment = 0) and (non_medicare_prpayer = 0)) then do;
               if (service_start_dt_mdc <= service_start_dt <= service_end_dt_mdc) then overlap_w_excluded_mdc = 1;
            end;
            if (overlap_w_excluded_mdc = 1) then rc_excl_mdc = 1;
            else rc_excl_mdc = excl_mdc.find_next();
         end;
      end;
      
      *exclude pb claims that overlap with an excluded PCI-TAVR ip stay;
      *NOTE: if an excluded PCI-TAVR stay starts on the discharge date of a triggering stay and pb claim has a certain place of service code, then do not exclude;
      if (excl_pci_tavr.find(key: episode_id) = 0) then do;
         rc_excl_pci_tavr = 0;
         do while (rc_excl_pci_tavr = 0);
            if not ((lowcase(cost_category) = "anchor period") and (non_positive_payment = 0) and (non_medicare_prpayer = 0)) then do;
               if (service_start_dt_pci_tavr <= service_start_dt <= service_end_dt_pci_tavr) then overlap_w_excluded_pci_tavr = 1;
            end;
            if (overlap_w_excluded_pci_tavr = 1) then rc_excl_pci_tavr = 1;
            else rc_excl_pci_tavr = excl_pci_tavr.find_next();
         end;
      end;

      *flag claims with OCM PBPM;
      if (ocm_pbpm.find(key: hcpcs_cd) = 0) then ocm_pbpm_flag = 1;
      
      *flag claims with OCM PBPM;
      if (eom_pbpm.find(key: hcpcs_cd) = 0) then eom_pbpm_flag = 1;      
      
      *flag COVID-19 claims;
      *COVID-19;
      if (service_start_dt >= "01APR2020"D) or (service_end_dt >= "01APR2020"D) then do;
         *check line diagnosis code;
         if (linedgns in (&covid_19_cds.)) then covid_19_clm = 1;
         *check claim diagnosis codes;
         else do;
            %do a = 1 %to &diag_length_pb_dm.;
               %let b = %sysfunc(putn(&a., z2.));
               if (dgnscd&b. in (&covid_19_cds.)) then covid_19_clm = 1;
               %if &a. ^= &diag_length_pb_dm. %then else;
            %end;
         end;
      end; %*end of COVID-19;
      *other coronavirus as the cause of diseases classified elsewhere;
      if covid_19_clm = 0 and ((service_start_dt > "27JAN2020"D) or (service_end_dt > "27JAN2020"D)) then do;
         *check line diagnosis code;
         if (linedgns in (&other_corona_cds.)) then covid_19_clm = 1;
         *check claim diagnosis codes;
         else do;
            %do a = 1 %to &diag_length_pb_dm.;
               %let b = %sysfunc(putn(&a., z2.));
               if (dgnscd&b. in (&other_corona_cds.)) then covid_19_clm = 1;
               %if &a. ^= &diag_length_pb_dm. %then else;
            %end;
         end;
      end; %*end of other coronavirus;

      *determine if claims should be grouped;
      *NOTE: need to deal with fringe case of when claims meet the GSC exclusion but meet some other criteria for grouping as well. in such fringe cases, group the claim;
      if (non_positive_payment = 0) and (non_medicare_prpayer = 0) and (hemophilia_flag = 0) and (part_b_dropflag = 0) and (excluded_cardiac_rehab = 0) and (excluded_ibd_partb = 0) and (overlap_w_excluded_readmsn = 0) and (overlap_w_excluded_mdc = 0) and (overlap_w_excluded_pci_tavr = 0) and (ocm_pbpm_flag = 0) and (eom_pbpm_flag = 0) and (lowcase(cost_category) ^= "unattributed") then grouped = 1;

      if (grouped = 1) then output temp.grp_pb_clms_to_epi;
      else if (grouped = 0) then output temp.ungrp_pb_clms_to_epi;

   run;
   
%mend; 