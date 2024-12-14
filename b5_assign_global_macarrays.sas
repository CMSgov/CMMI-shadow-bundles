/*************************************************************************;
%** PROGRAM: b5_global_macarrays.sas
%** PURPOSE: To define global macarrays to be accessed by other macros
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

%macro b5_assign_global_macarrays();
   %global gsc_mdfr_cds gsc_glob_days_cds ed_pos_cds rvcntr_visit_codes non_hcpcs_visit_codes other_corona_cds covid_19_cds;
   %do year = &baseline_start_year. %to &update_factor_cy.;
      %global work_gpci_all_&year. pe_gpci_all_&year. mp_gpci_all_&year. cf_all_&year. conv_factor_&year.;
   %end;
   
   *define the list of CMG types to calculte PDPM rate;
   %macarray(pdpm_types, pt ot nta slp nrsg);
   
   *define the list of peer group characteristics; 
   %macarray(prov_chars, &peer_group_list.);

   *define the list of provider types;
   %macarray(flag_vars, ipps state cah ltch irf child_hosp ipf sirf ssnf ipu home_health snf cancer_hosp emerg_hosp veteran_hosp);

   *define the list claim settings;
   %macarray(settings,  opl ip dm pb sn hs hh);
   
   *define the list of price update settings;
   %macarray(update_settings, ip irf hh sn pb other);

   *define the list of cost category types and labels to use during cost aggregation;
   %macarray(catgry_types,    anchor   post_dschrg       post_epi);
   %macarray(catgry_labels,   anchor ~ post-discharged ~ post-episode, dlm = "~");

   *define the list of time trend factor types;
   %macarray(time_factors, quart);
   
   *define the list of short names for each time trend factor types;
   %macarray(time_short,   q    );

   *define the list of all percentiles to winsorize against;
   %macarray(winsorize_perc, &winsorization_lower_threshs &winsorization_upper_threshs.);
   *define the list of lower percentiles to winsorize against;
   %macarray(lower_winsor_perc, &winsorization_lower_threshs.);
   *define the list of upper percentiles to winsorize against;
   %macarray(upper_winsor_perc, &winsorization_upper_threshs.);

   *define the list of all readmission period lengths;
   %macarray(readmission_periods, &readmission_period.);

   *define the list of non-pac settings to check prior hospitalization for;
   %let nonpac_setting_list = s_ip;
   
   *define the list of labels used to identify non-pac settings;
   %let nonpac_labels_list  = "non-pac - ip stay";
   %macarray(nonpac_settings, &nonpac_setting_list.);
   %macarray(nonpac_labels, &nonpac_labels_list., dlm = ~);

   *define the list of pac settings to check prior hospitalization for;
   %let pac_setting_list = snf hh c_irf c_ltch s_irf s_ltch;
   *define the list of labels used to identify pac settings;
   %let pac_labels_list =  "pac - snf" ~ "pac - hh" ~ "pac - ip claim irf" ~ "pac - ip claim ltch" ~ "pac - ip stay irf" ~ "pac - ip stay ltch";
   %macarray(pac_settings, &pac_setting_list.);
   %macarray(pac_labels, &pac_labels_list., dlm = ~);

   *define the list of non-pac and pac settings to check prior hospitalization for;
   %macarray(prior_settings, &nonpac_setting_list. &pac_setting_list.);
   *define the list of non-pac and pac labels to use for prior hospitalization flags;
   %macarray(prior_labels, &nonpac_labels_list. ~ &pac_labels_list., dlm = ~);

   *define the list of NPI types abbreviated;
   %macarray(npi_type_short, at        op);
   *define the list of NPI types long description;
   %macarray(npi_type_long,  attending operating);

   *define the list of cost variable to winsorize;
   %macarray(winz_cost_vars, epi_std_pmt_fctr post_epi_std_pmt_fctr);
   *define the list of dataset name for the winsorized outputs;
   %macarray(winz_ds_name,   epi              post);
   %let winz_cost = ;
   %do b = 1 %to &nwinz_cost_vars.;
      %let winz_cost = &winz_cost. &&winz_cost_vars&b..;
      %do a = 1 %to &nlower_winsor_perc.;
         %let winz_cost = &winz_cost. &&winz_cost_vars&b.._win_&&lower_winsor_perc&a.._&&upper_winsor_perc&a..;
      %end;
   %end;

   *define the list of cost variables;
   %macarray(cost_vars, tot_std_allowed tot_anchor_std_allowed tot_post_dsch_std_allowed tot_post_epi_std_allowed
                        tot_std_allowed_ip tot_std_allowed_opl tot_std_allowed_dm tot_std_allowed_pb tot_std_allowed_sn tot_std_allowed_hs tot_std_allowed_hh
                        anchor_std_allowed_ip anchor_std_allowed_opl anchor_std_allowed_dm anchor_std_allowed_pb anchor_std_allowed_sn anchor_std_allowed_hs anchor_std_allowed_hh 
                        post_dsch_std_allowed_ip post_dsch_std_allowed_opl post_dsch_std_allowed_dm post_dsch_std_allowed_pb post_dsch_std_allowed_sn post_dsch_std_allowed_hs post_dsch_std_allowed_hh 
                        post_epi_std_allowed_ip post_epi_std_allowed_opl post_epi_std_allowed_dm post_epi_std_allowed_pb post_epi_std_allowed_sn post_epi_std_allowed_hs post_epi_std_allowed_hh 
                        tot_raw_allowed tot_anchor_raw_allowed tot_post_dsch_raw_allowed tot_post_epi_raw_allowed
                        tot_raw_allowed_ip tot_raw_allowed_opl tot_raw_allowed_dm tot_raw_allowed_pb tot_raw_allowed_sn tot_raw_allowed_hs tot_raw_allowed_hh 
                        anchor_raw_allowed_ip anchor_raw_allowed_opl anchor_raw_allowed_dm anchor_raw_allowed_pb anchor_raw_allowed_sn anchor_raw_allowed_hs anchor_raw_allowed_hh 
                        post_dsch_raw_allowed_ip post_dsch_raw_allowed_opl post_dsch_raw_allowed_dm post_dsch_raw_allowed_pb post_dsch_raw_allowed_sn post_dsch_raw_allowed_hs post_dsch_raw_allowed_hh 
                        post_epi_raw_allowed_ip post_epi_raw_allowed_opl post_epi_raw_allowed_dm post_epi_raw_allowed_pb post_epi_raw_allowed_sn post_epi_raw_allowed_hs post_epi_raw_allowed_hh 
                        &winz_cost.
                        );


   *define the census division list;
   %let cens_div_list = ;
   %do a = 1 %to 9;
      %let cens_div_list = &cens_div_list. cens_div_&a.;
   %end;

   *insert global surgery medical codes into macrovariable for easy referencing later;
   proc sql noprint;
      
      *GSC modifier codes;
      select strip(gsc_code)
      into :gsc_mdfr_cds separated by " "
      from temp.gsc_codes (where = (lowcase(gsc_code_type) = "modifier code"))
      ;

      *GSC glob days codes;
      select quote(strip(gsc_code))
      into :gsc_glob_days_cds separated by " "
      from temp.gsc_codes (where = (lowcase(gsc_code_type) = "glob days code"))
      ;

   quit;

   *define the list of GSC modifier codes;
   %macarray(gsc_modifiers, &gsc_mdfr_cds.);
   *define the list of GSC glob days;
   %macarray(gsc_glob_days, &gsc_glob_days_cds.);

   *EMERGENCY ROOM PLACE OF SERVICE*;
   proc sql noprint;

      *emergency room place of service;
      select quote(strip(plcsrvc))
      into :ed_pos_cds separated by " "
      from temp.place_of_service_codes (where = (lowcase(plcsrvc_code_descrip) = "emergency room – hospital"))
      ;

   quit;

   *define the list of ED place of service codes;
   %macarray(ed_plcsrvcs, &ed_pos_cds.);

   *HOME HEALTH VISIT*;
   *assign home health visit code to macrovariable for easy referencing;
   proc sql noprint;
     
      *revenue center visit codes;
      select quote(strip(visit_code)) 
      into   :rvcntr_visit_codes separated by " "
      from temp.home_health_visit_codes (where = (lowcase(visit_code_type) = "first three-characters of revenue center code"))
      ;

      *hcpcs code;
      select quote(strip(visit_code)) 
      into :non_hcpcs_visit_codes separated by " "
      from temp.home_health_visit_codes (where = (lowcase(visit_code_type) = "hospice and home health care hcpcs code"))
      ;

   quit;

   *define the list of home health revenue ceter codes;
   %macarray(hh_rvcntr_cds, &rvcntr_visit_codes.);
   *define the list of home health hcpcs codes to not use;
   %macarray(hh_hcpcs_cds, &non_hcpcs_visit_codes.);


   *COVID 19*;
   *assign COVID 19 codes to macrovariable for easy referencing;
   proc sql noprint;

      *other coronavirus as the cause of diseases classified elsewhere;
      select quote(strip(cov_code)) 
      into   :other_corona_cds separated by " "
      from temp.covid_19 (where = (lowcase(cov_code_descrip) = "other coronavirus as the cause of diseases classified elsewhere"))
      ;

      *COVID-19;
      select quote(strip(cov_code)) 
      into   :covid_19_cds separated by " "
      from temp.covid_19 (where = (lowcase(cov_code_descrip) = "covid-19"))
      ;

   quit;

   *define the list of other coronavirus codes;
   %macarray(covid19_corona_cds, &other_corona_cds.);
   *define the list of COVID-19 codes;
   %macarray(covid19_cov_cds, &covid_19_cds.);


   *MJRLE TKA/THA/TSA PROCEDURE LABELS AND TYPES*;

   *assign procedure labels and types to macrovariable for constructing MJRLE risk adjustment flags;
    proc sql noprint;
      
      *procedure labels;
      select prcdr_group 
      into: prcdr_labels separated by " " 
      from temp.prcdr_list_freq (where = (prcdr_group ^= "TKA"))
      ;
      
      *procedure types;
      select quote(strip(prcdr_group)) 
      into: prcdr_types separated by " " 
      from temp.prcdr_list_freq
      ;

   quit;
   
   *define the list of procedure labels and types;
   %macarray(prcdr_labels, &prcdr_labels. TKA_);
   %macarray(prcdr_types, &prcdr_types.);

      
   *AVERAGE GPCI*;
   *generate macrovariables containing means of gpci and anesthesia conversion factor;
   %do year = &baseline_start_year. %to &update_factor_cy.;

      proc sql noprint;

         select mean(work_gpci),
                mean(pe_gpci),
                mean(mp_gpci)
         into :work_gpci_all_&year.,
              :pe_gpci_all_&year.,
              :mp_gpci_all_&year.
         from %if "&year." in ("2015" "2018" "2020") %then %do; gpci.gpcis_&year._2 %end; %else %do; gpci.gpcis_&year. %end;
         ;

         select mean(anes_cf)
         into :cf_all_&year.
         from %if "&year." in ("2015" "2018" "2024") %then %do; anes.anesthesia_cf_&year._2 %end; %else %do; anes.anesthesia_cf_&year. %end;
         ;

      quit;

      %macarray(avg_gpci_&year., &&work_gpci_all_&year. &&pe_gpci_all_&year. &&mp_gpci_all_&year.);
      %macarray(avg_cf_&year., &&cf_all_&year.);

   %end;     

   *PB CONVERSION FACTORS*;
   %let pb_cf_list = ;
   %do year = &baseline_start_year. %to &update_factor_cy.;

      *for the PB update year, use the most recently available quarter data;
      %if "&year." = "&update_factor_cy." %then %do;
         %let quarter = &updt_cons_quart.;
      %end;
      %else %do;
         %let quarter = 4;
      %end;

      proc sort nodupkey data = %if &year. = 2018 and &quarter. = 1 %then %do; rvu.pfs_&year.q&quarter._2 %end; %else %do; rvu.pfs_&year.q&quarter. %end; (keep = conv_factor)
                         out = temp.pb_conv_factor_&year.;
           by conv_factor;
      run;

      data _null_;
         set temp.pb_conv_factor_&year. end = last;
         if last then do;
            *abort if there is more than one converstion factor. there should only be one PB conversion factor for each year;
            if _n_ > 1 then abort;
            else call symputx("conv_factor_&year.", conv_factor);
         end;
      run;

      %let pb_cf_list = &pb_cf_list. &&conv_factor_&year..;

      *define the list of all PB conversion factors across years;
      %macarray(pb_conv_factors, &pb_cf_list.);

   %end;   
%mend; 