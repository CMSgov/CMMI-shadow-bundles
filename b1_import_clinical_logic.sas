/*************************************************************************;
%** PROGRAM: b1_import_clinical_logic.sas
%** PURPOSE: To import Clinical Logic workbooks
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

%macro b1_import_clinical_logic();
   
   *switches to select workbooks to import; 
   %*1 = run, 0 = not run; 
   %let import_trigger_list = 1;
   %let import_medical_code_list = 1;
   %let import_update_factors_code_list = 1;
   %let import_j1_primary_assn_ranking = 1;
   %let import_hcpcs_to_apc = 1;
   %let import_drg_mapping_workbook = 1;    

   *BPCIA TRIGGER CODE LIST*;   
   %if &import_trigger_list. = 1 %then %do;
      *define the row number in the workbook for where to start importing in the data;
      %let start_row_num = 8;

      *define the workbook sheet names to be imported;
      %macarray(sheet_names, IP_Anchor_Episode_List ~
                             OP_Anchor_Episode_List ~
                             TAVR Procedure Codes ~
                             Service_Line ~
                             MJRUE_Trigger_Procedure_Codes ~
                             MJRUE_Dropped_Procedure_Codes
                             , dlm = "~" );

      *define the name of the output datasets for the imported sheet names;
      %macarray(ds_names, ip_anchor_episode_list ~
                          op_anchor_episode_list ~
                          tavr_procedure_codes ~
                          service_line ~
                          mjrue_trigger_procedure_codes ~
                          mjrue_dropped_procedure_codes
                          , dlm = "~");

      *define the columns to be kept from each workbook sheet;
      %macarray(keep_cols, C D E H ~ %*ip_anchor_episode_list;
                           C D G J ~ %*op_anchor_episode_list;
                           c D ~ %*tavr_procedure_codes;
                           C D E ~ %*service_line;
                           C D ~ %*mjrue_trigger_procedure_codes;
                           C D  %*mjrue_dropped_procedure_codes;
                           , dlm = "~");

      *define the new column name that each kept column will be renamed to;
      %macarray(rename_cols, episode_group_name episode_group_id drg_cd cec_type ~ %*ip_anchor_episode_list;
                             episode_group_name episode_group_id hcpcs_cd cec_type ~ %*op_anchor_episode_list;
                             procedure_cd icd9_icd10 ~ %*tavr_procedure_codes;
                             service_line_group episode_group_name episode_group_id ~ %*service_line;
                             procedure_cd procedure_cd_descrip ~ %*mjrue_trigger_procedure_codes;
                             procedure_cd procedure_cd_descrip %*mjrue_dropped_procedure_codes;
                             , dlm = "~");

      *define the column length of each kept column;
      %macarray(length_cols, $100. $10. $3. $10. ~ %*ip_anchor_episode_list;
                             $100. $10. $5. $10. ~ %*op_anchor_episode_list;
                             $10.  $10. ~ %*tavr_procedure_codes;
                             $50.  $100. $10. ~ %*service_line;
                             $10.  $3200. ~ %*mjrue_trigger_procedure_codes;
                             $10.  $3200. %*mjrue_dropped_procedure_codes;
                             , dlm = "~");

      %do a = 1 %to &nsheet_names.;
         %macarray(kept_var, &&keep_cols&a..);
         %macarray(rename_var, &&rename_cols&a..);
         %macarray(len, &&length_cols&a..);

         *import trigger codes from clinical logic workbook;
         proc import out = temp.&&ds_names&a.. (keep = &&keep_cols&a..
                                                rename = (%do b = 1 %to &nkept_var.; 
                                                             &&kept_var&b.. = &&rename_var&b..
                                                          %end;))
            datafile = "&clin_dir.\&bpci_trig_version._bpci_a_trigger_list.xlsx"
            dbms = xlsx
            replace;
            sheet = "&&sheet_names&a..";
            datarow = &start_row_num.;
            getnames = no;
         run;

         *apply basic formatting edits to imported datasets;
         data temp.&&ds_names&a..;
            length %do b = 1 %to &nrename_var.; &&rename_var&b.. &&len&b.. %end;;
            set temp.&&ds_names&a..;
            %do b = 1 %to &nrename_var.;
                &&rename_var&b.. = strip(&&rename_var&b..);
            %end;
            %if &&ds_names&a.. = service_line %then %do;
               episode_group_name = upcase(strip(episode_group_name));
            %end;
            if not (%do b = 1 %to &nrename_var.; missing(&&rename_var&b..) %if &b. ^= &nrename_var. %then and; %end;) then output temp.&&ds_names&a..;
         run;
      %end;
   %end; 

   *BPCIA MEDICAL CODE LIST*;   
   %if &import_medical_code_list. = 1 %then %do;
      *define the row number in the workbook for where to start importing in the data;
      %let start_row_num = 8;

      *define the workbook sheet names to be imported;
      %macarray(sheet_names, IPPS_Codes ~
                             State_Codes ~
                             CAH_Codes ~
                             LTCH_Codes ~
                             IRF_Codes ~
                             Children_Hospital_Codes ~
                             Inpatient_Psych_Codes ~
                             SIRF_Codes ~
                             SSNF_Codes ~
                             IPU_Codes ~
                             Home_Health_Codes ~
                             Skilled_Nursing_Codes ~
                             Cancer_Hospital_Codes ~
                             Emergency_Hosp_Codes ~
                             Veteran_Hosp_Codes ~
                             Excluded_Providers ~
                             Excluded_Status_Codes ~
                             Hemophilia_Codes ~
                             Excluded_Readmissions ~
                             OPPS_Pass_Through ~
                             Excluded_OCM_PBPM ~
                             Excluded_EOM_PBPM ~
                             Excluded_MCCM_PBPM ~
                             Emerg_Depart_Codes ~
                             GSC_Codes ~
                             Place_of_Service_Codes ~
                             Home_Health_Visit_Codes ~
                             Dual_Elgb_Codes ~
                             Orig_Disable_Codes ~
                             Urban_Prov_Codes ~                         
                             FB_FC_Modifier_Codes ~
                             CCN_State_Codes ~
                             State_to_Census_Reg ~
                             Overlap Rural CCN ~
                             PA Rural Health Hospital ~
                             Excluded_Part_B_Drugs ~
                             Excluded_MDC ~
                             Excluded_IBD_PartB ~
                             Excluded_HCPCS_Cardiac_Rehab ~
                             Excluded_PCSRVC_Cardiac_Rehab ~
                             Hemorrhage_Codes ~
                             Fistula_Codes ~
                             UC_Codes ~
                             MJRLE_Procedure_Codes ~
                             THA_Codes ~
                             COVID_19 ~
                             MJRUE_Procedure_Groups ~
                             Trauma_Codes ~
                             Fracture_Codes ~
                             TSA_Codes
                             , dlm = "~" );

      *define the name of the output datasets for the imported sheet names;
      %macarray(ds_names, ipps_codes ~
                          state_codes ~
                          cah_codes ~
                          ltch_codes ~
                          irf_codes ~
                          children_hospital_codes ~
                          inpatient_psych_codes ~
                          sirf_codes ~
                          ssnf_codes ~
                          ipu_codes ~
                          home_health_codes ~
                          skilled_nursing_codes ~
                          cancer_hospital_codes ~
                          emergency_hosp_codes ~
                          veteran_hosp_codes ~
                          excluded_providers ~
                          excluded_status_codes ~
                          hemophilia_codes ~
                          excluded_readmissions ~
                          opps_pass_through ~
                          excluded_ocm_pbpm ~
                          excluded_eom_pbpm ~
                          excluded_mccm_pbpm ~
                          emerg_depart_codes ~
                          gsc_codes ~
                          place_of_service_codes ~
                          home_health_visit_codes ~
                          dual_elgb_codes ~
                          orig_disable_codes ~
                          urban_prov_codes ~
                          fb_fc_modifier_codes ~
                          ccn_state_codes ~
                          state_to_census_reg ~
                          overlap_rural_ccn ~
                          pa_rural_health_hospital ~
                          excluded_part_b_drugs ~
                          excluded_mdc ~
                          excluded_ibd_partb ~
                          excluded_hcpcs_cr ~
                          excluded_pcsrvc_cr ~
                          hemorrhagic_codes ~
                          fistula_codes ~
                          uc_codes ~
                          mjrle_procedure_codes ~
                          tha_codes ~
                          covid_19 ~
                          mjrue_procedure_groups ~
                          trauma_codes ~
                          fracture_codes ~
                          tsa_codes
                          , dlm = "~");

      *define the columns to be kept from each workbook sheet;
      %macarray(keep_cols, C D E ~  %*ipps_codes;
                           C D E ~  %*state_codes;
                           C D E ~  %*cah_codes;
                           C D E ~  %*ltch_codes;
                           C D E ~  %*irf_codes;
                           C D E ~  %*children_hospital_codes;
                           C D E ~  %*inpatient_psych_codes;
                           C D E ~  %*sirf_codes;
                           C D E F ~  %*ssnf_codes;
                           C D E ~  %*ipu_codes;
                           C D E ~  %*home_health_codes;
                           C D E ~  %*skilled_nursing_codes;
                           C D E ~  %*cancer_hospital_codes;
                           C D E ~  %*emergency_hosp_codes;
                           C D E ~  %*veteran_hosp_codes;
                           C D E ~  %*excluded_providers;
                           C D E ~  %*excluded_status_codes;
                           C D E F ~  %*hemophilia_codes;
                           C D E F G H ~  %*excluded_readmissions;
                           C D E ~  %*opps_pass_through;
                           C D E ~  %*excluded_ocm_pbpm;
                           C D E ~  %*excluded_eom_pbpm;
                           C D E ~  %*excluded_mccm_pbpm;
                           C D E ~  %*emerg_depart_codes;
                           C D E ~  %*gsc_codes;
                           C D E ~  %*place_of_service_codes;
                           C D E ~  %*home_health_visit_codes;
                           C D E F ~  %*dual_elgb_codes;
                           C D E ~  %*orig_disable_codes;
                           C D E ~  %*urban_prov_codes;                       
                           C D E ~  %*fb_fc_modifier_codes;
                           C D E F ~  %*ccn_state_codes;
                           C D E ~  %*state_to_census_reg;
                           C D E F G H ~  %*overlap_rural_ccn;
                           C D E F G H ~  %*pa_rural_health_hospital;
                           C D E ~  %*excluded_part_b_drugs;
                           C D ~  %*excluded_mdc;
                           C D E ~  %*excluded_ibd_partb;
                           C D ~  %*excluded_hcpcs_cr;
                           C D E F G ~  %*excluded_pcsrvc_cr;
                           C D E F G ~  %*hemorrhagic_codes;
                           C D E F G ~  %*fistula_codes;
                           C D E F G ~  %*uc_codes;
                           C D E F ~  %*mjrle_procedure_codes;
                           C D E ~  %*tha_codes;
                           C D E F G ~  %*covid_19;
                           C D E ~  %*mjrue_procedure_groups;
                           C D ~  %*trauma_codes;
                           C D ~  %*fracture_codes;
                           C D E  %*tsa_codes;
                           , dlm = "~");

      *define the new column name that each kept column will be renamed to;
      %macarray(rename_cols, ipps_code_type ipps_code ipps_code_descrip ~  %*ipps_codes;/*{{{*/
                             state_code_type state_code state_code_descrip ~  %*state_codes;
                             cah_code_type cah_code code_code_descrip ~  %*cah_codes;
                             ltch_code_type ltch_code ltch_code_descrip ~  %*ltch_codes;
                             irf_code_type irf_code irf_code_descrip ~  %*irf_codes;
                             child_code_type child_code child_code_descrip ~  %*children_hospital_codes;
                             ipf_code_type ipf_code ipf_code_descrip ~  %*inpatient_psych_codes;
                             sirf_code_type sirf_code sirf_code_descrip ~  %*sirf_codes;
                             ssnf_code_type ssnf_code ssnf_code_descrip swing_bed ~  %*ssnf_codes;
                             ipu_code_type ipu_code ipu_code_descrip ~  %*ipu_codes;
                             hh_code_type hh_code hh_code_descrip ~  %*home_health_codes;
                             snf_code_type snf_code snf_code_descrip ~  %*skilled_nursing_codes;
                             cancer_code_type cancer_code cancer_code_descrip ~  %*cancer_hospital_codes;
                             emerg_code_type emerg_code emerg_code_descrip ~  %*emergency_hosp_codes;
                             veteran_code_type veteran_code veteran_code_descrip ~  %*veteran_hosp_codes;
                             prov_code_type provider_num exclusion_reason ~  %*excluded_providers;
                             stus_code_type stus_cd stus_cd_descrip ~  %*excluded_status_codes;
                             hemo_code_type hcpcs_cd hemo_code_descrip notes ~  %*hemophilia_codes;
                             readmsn_code_type ms_drg readmsn_code_descrip mdc_code mdc_code_descrip notes ~  %*excluded_readmissions;
                             pass_thru_code_type pass_thru_code pass_thru_code_descrip ~  %*opps_pass_through;
                             ocm_code_type ocm_code ocm_code_descrip ~  %*excluded_ocm_pbpm;
                             eom_code_type eom_code eom_code_descrip ~ %*excluded_eom_pbpm;
                             mccm_code_type mccm_code mccm_code_descrip ~  %*excluded_mccm_pbpm;
                             ed_code_type ed_code ed_code_descrip ~  %*emerg_depart_codes;
                             gsc_code_type gsc_code gsc_code_descrip ~  %*gsc_codes;
                             plcsrvc_code_type plcsrvc plcsrvc_code_descrip ~  %*place_of_service_codes;
                             visit_code_type visit_code vist_code_descrip ~  %*home_health_visit_codes;
                             dual_code_type dual_code dual_elg_status dual_code_descrip ~  %*dual_elgb_codes;
                             origds_code_type origds_code origds_code_descrip ~  %*orig_disable_codes;
                             urban_code_type urban_code urban_code_descrip ~  %*urban_prov_codes;
                             fb_fc_code_type fb_fc_code fc_fc_code_descrip ~  %*fb_fc_modifier_codes;
                             ccn_code_type ccn_code state_name state_abbr ~  %*ccn_state_codes;
                             state_abbr division_code division_name ~  %*state_to_census_reg;
                             hospital_location ccn county demo_start_date demo_end_date notes ~  %*overlap_rural_ccn;
                             hospital_name ccn hospital_type model_start_date county notes ~  %*pa_rural_health_hospital;
                             hcpcs_cd hcpcs_descrip excl_reason ~  %*excluded_part_b_drugs;
                             mdc mdc_descrip ~  %*excluded_mdc;
                             drg_code hcpcs_cd hcpcs_descrip ~  %*excluded_ibd_partb;
                             hcpcs_cd hcpcs_descrip ~  %*excluded_hcpcs_cr;
                             cr_code_type plcsrvc_code plcsrvc_name plcsrvc_code_descrip plcsrvc_date_res ~  %*excluded_pcsrvc_cr;
                             drg_code hemor_code_type hemor_code icd9_icd10 hemor_code_descrip ~  %*hemorrhagic_codes;
                             drg_code fistula_code_type fistula_code icd9_icd10 fistula_code_descrip ~  %*fistula_codes;
                             drg_code uc_code_type uc_code icd9_icd10 uc_code_descrip ~  %*uc_codes;
                             prcdr_code prcdr_code_descrip icd9_icd10 prcdr_group ~  %*mjrle_procedure_codes;
                             drg_code tha_code tha_code_descrip ~  %*tha_codes;
                             cov_code_type cov_code icd9_icd10 cov_code_descrip code_active_date ~  %*covid_19;
                             prcdr_code prcdr_code_descrip prcdr_group ~  %*mjrue_procedure_groups;
                             trauma_code trauma_code_descrip ~  %*trauma_codes;
                             fracture_code fracture_code_descrip ~  %*fracture_codes;
                             drg_code tsa_code tsa_code_descrip  %*tsa_codes;
                             , dlm = "~");

      *define the column length of each kept column;
      %macarray(length_cols, $50.  $6. $3200. ~  %*ipps_codes;
                             $50.  $2. $3200. ~  %*state_codes;
                             $50.  $4. $3200. ~  %*cah_codes;
                             $50.  $4. $3200. ~  %*ltch_codes;
                             $50.  $4. $3200. ~  %*irf_codes;
                             $50.  $4. $3200. ~  %*children_hospital_codes;
                             $50.  $4. $3200. ~  %*inpatient_psych_codes;
                             $50.  $2. $3200. ~  %*sirf_codes;
                             $50.  $2. $3200. $2. ~  %*ssnf_codes;
                             $50.  $2. $3200. ~  %*ipu_codes;
                             $50.  $4. $3200. ~  %*home_health_codes;
                             $50.  $4. $3200. ~  %*skilled_nursing_codes;
                             $50.  $6. $3200. ~  %*cancer_hospital_codes;
                             $50.  $2. $3200. ~  %*emergency_hosp_codes;
                             $50.  $2. $3200. ~  %*veteran_hosp_codes;
                             $50.  $6. $3200. ~  %*excluded_providers;
                             $50.  $2. $3200. ~  %*excluded_status_codes;
                             $50.  $5. $3200. $3200. ~  %*hemophilia_codes;
                             $50.  $3. $3200. $10. $3200. $3200. ~  %*excluded_readmission;
                             $50.  $2. $3200. ~  %*opps_pass_through;
                             $50.  $10. $3200. ~  %*excluded_ocm_pbpm;
                             $50.  $10. $3200. ~  %*excluded_eom_pbpm;
                             $50.  $10. $3200. ~  %*excluded_mccm_pbpm;
                             $50.  $4. $3200. ~  %*emerg_depart_codes;
                             $50.  $5. $3200. ~  %*gsc_codes;
                             $50.  $2. $3200. ~  %*place_of_service_codes;
                             $50.  $5. $3200. ~  %*home_health_visit_codes;
                             $50.  $2. $10. $3200. ~  %*dual_elgb_codes;
                             $50.  $2. $3200. ~  %*orig_disable_codes;
                             $50.  $2. $3200. ~  %*urban_prov_codes;
                             $50.  $10. $3200. ~  %*fb_fc_modifier_codes;
                             $50.  $10. $3200. $10. ~  %*ccn_state_codes;
                             $10.  $10. $3200. ~  %*state_to_census_reg;
                             $100. $6. $100. 8. 8. $3200. ~  %*overlap_rural_ccn;
                             $100. $6. $3. 8. $100. $3200. ~  %*pa_rural_health_hospital;
                             $5.   $3200. $3200. ~  %*excluded_part_b_drugs;
                             $5.   $3200. ~  %*excluded_mdc;
                             $3.   $5.  $3200. ~  %*excluded_ibd_partb;
                             $5.   $3200. ~  %*excluded_hcpcs_cr;
                             $50.  $2.  $3200. $3200. 8. ~  %*excluded_pcsrvc_cr;
                             $3.   $50. $10. $10. $3200. ~  %*hemorrhagic_codes;
                             $3.   $50. $10. $10. $3200. ~  %*fistula_codes;
                             $3.   $50. $10. $10. $3200. ~  %*uc_codes;
                             $10.  $3200. $10. $50. ~  %*mjrle_procedure_codes;
                             $3.   $10. $3200. ~  %*tha_codes;
                             $50.  $10. $10. $3200. $10. ~  %*covid_19;
                             $10.  $3200. $50. ~  %*mjrue_procedure_groups;
                             $10.  $3200. ~  %*trauma_codes;
                             $10.  $3200. ~  %*fracture_codes;
                             $3.   $10. $3200.  %*tsa_codes;
                             , dlm = "~");

      %do a = 1 %to &nsheet_names.;
         %macarray(kept_var, &&keep_cols&a..);
         %macarray(rename_var, &&rename_cols&a..);
         %macarray(len, &&length_cols&a..);

         *import medical codes from clinical logic workbook;
         proc import out = temp.&&ds_names&a.. (keep = &&keep_cols&a..
                                                rename = (%do b = 1 %to &nkept_var.; &&kept_var&b.. = &&rename_var&b.. %end;))
            datafile = "&clin_dir.\&med_code_version._bpci_medical_code_lists.xlsx"
            dbms = xlsx
            replace;
            sheet = "&&sheet_names&a..";
            datarow = &start_row_num.;
            getnames = no;
         run;

         *apply basic formatting edits to imported datasets;
         data temp.&&ds_names&a..;
            length %do b = 1 %to &nrename_var.; &&rename_var&b.. &&len&b.. %end;;
            set temp.&&ds_names&a..;
            %do b = 1 %to &nrename_var.;
                &&rename_var&b.. = strip(&&rename_var&b..);
            %end;
            %if &&ds_names&a.. = cjr_hospital %then %do;
               format model_end_date date9. ;
            %end;
            %if &&ds_names&a.. = overlap_rural_ccn %then %do;
               format demo_start_date date9. demo_end_date date9.;
            %end;
            %if &&ds_names&a.. = pa_rural_health_hospital %then %do;
               format model_start_date date9.;
            %end;
            %if &&ds_names&a.. = excluded_pcsrvc_cr %then %do;
               format plcsrvc_date_res date9.;
            %end;
            %if &&ds_names&a.. = mjrle_procedure_codes %then %do;
               prcdr_group = translate(strip(prcdr_group),"_","-");
            %end;
            if not (%do b = 1 %to &nrename_var.; missing(&&rename_var&b..) %if &b. ^= &nrename_var. %then and; %end;) then output temp.&&ds_names&a..;
         run;
      %end;
   %end; 
   
   *UPDATE FACTOR CODE LIST*;
   %if &import_update_factors_code_list. = 1 %then %do;
      *define the row number in the workbook for where to start importing in the data;
      %let start_row_num = 8;
      *define the workbook sheet names to be imported;
      %macarray(sheet_names, Facility_Rev_Center_Codes ~
                             SNF_Excluded_RUG ~
                             SNF_Excluded_PDPM ~
                             State_Locality_Codes ~
                             RR_Carrier_Codes ~
                             BETOS_Codes ~
                             PLCSRVC_Non_Facility_Codes ~
                             PB_Modifier_Codes ~
                             OPPS_Status_Indicators
                             ,dlm = "~");

      *define the name of the output datasets for the imported sheet names;
      %macarray(ds_names, facility_rev_center_codes ~
                          snf_excluded_rug ~
                          snf_excluded_pdpm ~
                          state_locality_codes ~
                          rr_carrier_codes ~
                          betos_codes ~
                          plcsrvc_non_facility_codes ~
                          pb_modifier_codes ~
                          opps_status_indicators
                          ,dlm = "~");

      *define the columns to be kept from each workbook sheet;
      %macarray(keep_cols, C D E ~  %*facility_rev_center_codes;
                           C D E ~  %*snf_excluded_rug;
                           C D E ~  %*snf_excluded_pdpm;
                           C D E ~  %*state_locality_codes;
                           C D E ~  %*rr_carrier_codes;
                           C D E ~  %*betos_codes;
                           C D E ~  %*plcsrvc_non_facility_codes;
                           C D E ~  %*pb_modifier_codes;
                           C D E  %*opps_status_indicators;
                           ,dlm = "~");

      *define the new column name that each kept column will be renamed to;
      %macarray(rename_cols, fac_code_type fac_code fac_code_descrip ~  %*facility_rev_center_codes;
                             rug_code_type rug_code reason_for_exclusion ~  %*snf_excluded_rug;
                             pdpm_code_type pdpm_code reason_for_exclusion ~  %*snf_excluded_pdpm;
                             locality_code_type locality_code locality_descrip ~  %*state_locality_codes;
                             rr_code_type rr_code rr_descrip ~  %*rr_carrier_codes;
                             betos_code_type betos_code betos_code_descrip ~  %*betos_codes;
                             non_fac_code_type non_fac_code non_fac_code_descrip ~  %*plcsrvc_non_facility_codes;
                             mdfr_code_type mdfr_code mdfr_code_descrip ~  %*pb_modifier_codes;
                             status_ind_code status_ind_code_descrip included_in_opps %*opps_status_indicators;
                             ,dlm = "~");

      *define the column length of each kept column;
      %macarray(length_cols, $50. $4. $3200. ~  %*facility_rev_center_codes;
                             $50. $3. $3200. ~  %*snf_excluded_rug;
                             $50. $5. $3200. ~  %*snf_excluded_pdpm;
                             $50. $2. $3200. ~  %*state_locality_codes;
                             $50. $5. $3200. ~  %*rr_carrier_codes;
                             $50. $3. $3200. ~  %*betos_codes;
                             $50. $2. $3200. ~  %*plcsrvc_non_facility_codes;
                             $50. $2. $3200. ~ %*pb_modifier_codes;
                             $2. $3200. $2. %*opps_status_indicators;
                             ,dlm = "~");

      %do a = 1 %to &nsheet_names.; 
         %macarray(kept_var, &&keep_cols&a..);
         %macarray(rename_var, &&rename_cols&a..);
         %macarray(len, &&length_cols&a..);

         *import update factor codes from clinical logic workbook;
         proc import out = temp.&&ds_names&a.. (keep = &&keep_cols&a..
                                                rename = (%do b = 1 %to &nkept_var.; &&kept_var&b.. = &&rename_var&b.. %end;))
            datafile = "&clin_dir.\&updt_fctr_version._update_factors_code_lists.xlsx"
            dbms = xlsx
            replace;
            sheet = "&&sheet_names&a..";
            datarow = &start_row_num.;
            getnames = no;
         run;

         *apply basic formatting edits to imported datasets;
         data temp.&&ds_names&a..;
            length %do b = 1 %to &nrename_var.; &&rename_var&b.. &&len&b.. %end;;
            set temp.&&ds_names&a..;
            %do b = 1 %to &nrename_var.;
                &&rename_var&b.. = strip(&&rename_var&b..);
            %end;
            if not (%do b = 1 %to &nrename_var.; missing(&&rename_var&b..) %if &b. ^= &nrename_var. %then and; %end;) then output temp.&&ds_names&a..;
         run;
      %end;
   %end;    
   
   *J1 PRIMARY ASSIGNMENT RANKING WORKBOOK*; 
   %if &import_j1_primary_assn_ranking. = 1 %then %do; 
      *define the row number in the workbook for where to start importing in the data;
      %let start_row_num = 3;
   
      *define the list of all years to read in for addendum J workbooks;
      %macarray(j_years, &addj_year_list.);
      
      *define the list of run dates associated with each addendum J workbook to be read in;
      %macarray(j_rundates, &addj_rundate_list.);

      *define the workbook sheet names to be imported;
      %macarray(sheet_names, Rank for Primary Assignment
                             ,dlm = "~");

      *define the name of the output datasets for the imported sheet names;
      %macarray(ds_names, prim_assignment_rankings
                          ,dlm = "~");

      *define the columns to be kept from each workbook sheet;
      %macarray(keep_cols, A C I  %*prim_assignment_rankings;
                           ,dlm = "~");

      *define the new column name that each kept column will be renamed to;
      %macarray(rename_cols, hcpcs_code status_ind prim_assign_rank %*prim_assignment_rankings;
                             ,dlm = "~");

      *define the column length of each kept column;
      %macarray(length_cols, $5. $2. 8. %*prim_assignment_rankings;
                             ,dlm = "~");

      %do j = 1 %to &nj_years.;
         %do a = 1 %to &nsheet_names.; 

            %macarray(kept_var, &&keep_cols&a..);
            %macarray(rename_var, &&rename_cols&a..);
            %macarray(len, &&length_cols&a..);

            *import update factor codes from clinical logic workbook;
            proc import out = temp.&&ds_names&a.._&&j_years&j.. (keep = &&keep_cols&a..
                                                                 rename = (%do b = 1 %to &nkept_var.; &&kept_var&b.. = &&rename_var&b.. %end;))
               datafile = "&addj_dir.\&&j_years&j.._cy\&&j_rundates&j..\raw\&&j_years&j.._add_j.xlsx"
               dbms = xlsx
               replace;
               sheet = "&&sheet_names&a..";
               datarow = &start_row_num.;
               getnames = no;
            run;

            *apply basic formatting edits to imported datasets;
            data temp.&&ds_names&a.._&&j_years&j..;
               length %do b = 1 %to &nrename_var.; &&rename_var&b.. &&len&b.. %end;;
               set temp.&&ds_names&a.._&&j_years&j..;
               %do b = 1 %to &nrename_var.;
                   &&rename_var&b.. = strip(&&rename_var&b..);
               %end;
               if not (%do b = 1 %to &nrename_var.; missing(&&rename_var&b..) %if &b. ^= &nrename_var. %then and; %end;) then output temp.&&ds_names&a.._&&j_years&j..;
            run;
   
         %end;
      %end;
   %end;   
   
   *HCPCS TO APC CROSSWALK WORKBOOK*; 
   %if &import_hcpcs_to_apc. %then %do;    
      
      *define the row number in the workbook for where to start importing in the data;
      %let start_row_num = 8;

      *define the workbook sheet names to be imported;
      %macarray(sheet_names, BPCI_A_Historical_Mapping 
                             ,dlm = "~");

      *define the name of the output datasets for the imported sheet names;
      %macarray(ds_names, hcpcs_to_apc_xwalk
                          ,dlm = "~");

      *define the columns to be kept from each workbook sheet;
      %macarray(keep_cols, C D E F G H I J K L M N O %*hcpcs_to_apc_xwalk;
                           ,dlm = "~");

      *define the new column name that each kept column will be renamed to;
      %macarray(rename_cols, episode_group_name cy_year hcpcs_code hcpcs_code_descrip apc status_ind apc_payment_rate is_c_apc sec_j1_add_on sec_j1_add_on_descrip comp_adj_hcpcs comp_adj_apc comp_adj_apc_payment_rate  %*hcpcs_to_apc_xwalk;
                             ,dlm = "~");

      *define the column length of each kept column;
      %macarray(length_cols, $100. 8. $5. $3200. $10. $2. 8. $2. $5. $3200. $5. $10. 8. %*hcpcs_to_apc_xwalk;
                             ,dlm = "~");

      %do a = 1 %to &nsheet_names.; 
         %macarray(kept_var, &&keep_cols&a..);
         %macarray(rename_var, &&rename_cols&a..);
         %macarray(len, &&length_cols&a..);

         *import update factor codes from clinical logic workbook;
         proc import out = temp.&&ds_names&a.. (keep = &&keep_cols&a..
                                                rename = (%do b = 1 %to &nkept_var.; &&kept_var&b.. = &&rename_var&b.. %end;))
            datafile = "&clin_dir.\&hcpcs_apc_version._bpci_a_hcpcs_apc_mapping.xlsx"
            dbms = xlsx
            replace;
            sheet = "&&sheet_names&a..";
            datarow = &start_row_num.;
            getnames = no;
         run;

         *apply basic formatting edits to imported datasets;
         data temp.&&ds_names&a..;
            length %do b = 1 %to &nrename_var.; &&rename_var&b.. &&len&b.. %end;;
            set temp.&&ds_names&a..;
            %do b = 1 %to &nrename_var.;
                &&rename_var&b.. = strip(&&rename_var&b..);
            %end;
            if not (%do b = 1 %to &nrename_var.; missing(&&rename_var&b..) %if &b. ^= &nrename_var. %then and; %end;) then output temp.&&ds_names&a..;
         run;   
      %end;
   %end;

   *DRG MAPPING WORKBOOK*; 
   %if &import_drg_mapping_workbook. = 1 %then %do;

      *define the row number in the workbook for where to start importing in the data;
      %let start_row_num = 8;

      *define the workbook sheet names to be imported;
      %macarray(sheet_names, DRG_Remapped ~
                             Excluded_DRG_Mappings ~
                             Supp_Cardiac_Codes ~
                             Aortic_Proc_Codes ~
                             Repair_Thoracic_Codes ~
                             Mitral_Valve_Codes ~
                             ICDCPT_Remap_Codes ~
                             LVAD_Codes ~
                             Neuro_Codes ~
                             Device_Codes ~
                             Invasive_Complex_Codes ~
                             PCI_Intracardiac_Codes ~
                             Enc_Dialysis_Codes ~
                             Enc_Dialysis_Codes_BM ~
                             Sterilization_Codes ~
                             Sterilization_Codes_BM1 ~
                             Sterilization_Codes_BM2 ~
                             Neoplasm_Kidney_Codes ~
                             Neoplasm_Kidney_Codes_BM ~
                             Neoplasm_Gen_Codes ~
                             Neoplasm_Gen_Codes_BM ~
                             Extr_Endo_Codes ~
                             Extr_Endo_Codes_BM ~
                             FY12_CC_Codes ~
                             FY12_MCC_Codes ~
                             FY12_CC_Exclusions ~
                             FY20_CC_Codes ~
                             FY20_MCC_Codes ~
                             ECMO_Codes ~
                             Autologous_BM_Codes ~
                             Carotid_Artery_Codes ~
                             Endovasc_Cardiac_Valve_Codes ~
                             Other_Endovasc_Valve_Codes ~
                             Other_Endovasc_Valve_Codes_bm1 ~
                             Other_Endovasc_Valve_Codes_bm2 ~
                             Knee_Procedure_Codes ~
                             Cervical_Spinal_Fusion ~
                             Spinal_Fusion_Proc ~
                             Repro_System_Codes ~
                             Male_Repro_Codes ~
                             Male_Diagn_Malig_Codes ~
                             Male_Diagn_No_Malig_Codes ~
                             Female_Diagn_Codes ~
                             Musculoskeletal_Codes ~
                             Abnormal_Radiological_Codes ~
                             Stomach_Codes ~
                             Pulmonary_Embolism_Codes ~
                             Skin_SubTissue_Codes ~
                             Scoliosis_Codes ~
                             Antepartum_Codes ~
                             FY21_CAR_T_Codes ~
                             FY21_CAR_T_Codes_BM ~
                             FY21_Cartoid_Artery_Codes ~
                             FY21_Cartoid_Artery_Codes_BM1 ~
                             FY21_Cartoid_Artery_Codes_BM2 ~
                             FY21_Head_Neck_Codes ~
                             FY21_DRG-129a_BM ~
                             FY21_DRG-129b_BM ~
                             FY21_DRG-130a_BM ~
                             FY21_DRG-130b_BM ~
                             FY21_DRG-131a_BM ~
                             FY21_DRG-131b_BM ~
                             FY21_DRG-132a_BM ~
                             FY21_DRG-132b_BM ~
                             FY21_DRG-133a_BM ~
                             FY21_DRG-133b_BM ~
                             FY21_DRG-134a_BM ~
                             FY21_DRG-134b_BM ~
                             FY21_Head_Neck_Diag_Codes ~
                             FY21_Ear_Nose_Mouth_Codes ~
                             FY21_Ear_Nose_Mouth_Diag_Codes ~
                             FY21_LAAC_Codes ~
                             FY21_LAAC_Codes_BM ~
                             FY21_HipFracture_Codes ~
                             FY21_HipFracture_Codes_BM ~
                             FY21_Hemodialysis_Codes ~
                             FY21_Hemodialysis_Codes_BM ~
                             FY21_Kidney_Transplant_Codes ~
                             FY21_Kidney_Transplant_Codes_BM ~
                             FY21_Vascular_Dialysis_Code ~
                             FY21_Vascular_Dialysis_Code_BM ~
                             FY21_Non_OR_Codes ~
                             FY21_Non_OR_Codes_BM ~
                             FY21_PeritonealCavity_Codes ~
                             FY21_PeritonealCavity_Codes_BM ~
                             FY21_Mediastinum_Excision_Codes ~
                             FY21_Mediastinum_Excision_BM ~
                             FY21_MCC_List ~
                             FY21_CC_List ~
                             FY22_Excision_Sub_Tissue_Codes ~
                             FY22_Excision_Sub_Tissue_BM ~
                             FY22_LITT_Codes_FM1 ~
                             FY22_LITT_Codes_BM1 ~
                             FY22_LITT_Codes_FM2 ~
                             FY22_LITT_Codes_BM2 ~
                             FY22_LITT_Codes_FM3 ~
                             FY22_LITT_Codes_BM3 ~
                             FY22_LITT_Codes_FM4 ~
                             FY22_LITT_Codes_BM4 ~
                             FY22_Esophagus_Repair_Codes ~
                             FY22_Esophagus_Repair_Codes_BM ~
                             FY22_Cowpers_Gland_Codes ~
                             FY22_Cowpers_Gland_Codes_BM ~
                             FY22_LITT_Codes_FM5 ~
                             FY22_LITT_Codes_BM5 ~
                             FY22_LITT_Codes_FM6 ~
                             FY22_LITT_Codes_BM6 ~
                             FY22_LITT_Codes_FM7 ~
                             FY22_LITT_Codes_BM7 ~
                             FY22_LITT_Codes_FM8 ~
                             FY22_LITT_Codes_BM8 ~
                             FY22_Right_Knee_Joint_Codes_FM1 ~
                             FY22_Right_Knee_Joint_Codes_BM1 ~
                             FY22_LITT_Codes_FM9 ~
                             FY22_LITT_Codes_BM9 ~
                             FY22_LITT_Codes_FM10 ~
                             FY22_LITT_Codes_BM10 ~
                             FY22_Pulm_Thor_Ster_Ribs_Codes ~
                             FY22_Pulm_Thor_Ster_Ribs_BM ~
                             FY22_Heart_Device_Codes ~
                             FY22_Heart_Device_Codes_BM ~
                             FY22_Cardiac_Cath_Codes ~
                             FY22_Cardiac_Cath_Codes_BM ~
                             FY22_Viral_Cardiomyopathy_Codes ~
                             FY22_Viral_Cardiomyopathy_BM ~
                             FY22_Right_Knee_Joint_Codes_FM2 ~
                             FY22_Right_Knee_Joint_Codes_BM2 ~
                             FY22_Bilateral_Mult_Codes ~
                             FY22_Bilateral_Mult_Codes_BM ~
                             FY22_Coronary_Artery_Byp_Codes ~
                             FY22_Coronary_Artery_Byp_BM ~
                             FY22_Surgical_Ablation_Codes ~
                             FY22_Surgical_Ablation_Codes_BM ~
                             FY22_MCC_List ~
                             FY22_CC_List ~
                             FY22_Major_Device_Codes_BM ~
                             FY22_Acute_Complex_Codes_BM ~
                             FY19_Vaginal_Delivery_BM ~
                             FY19_Complication_Codes_BM ~
                             FY21_MDC_3_BM ~
                             FY21_Perc_embol_BM ~
                             FY23_Acute_Resp_Synd_Code ~
                             FY23_Acute_Resp_Synd_Code_BM ~
                             FY23_Cardiac_Mapping_Code ~
                             FY23_Cardiac_Mapping_Code_BM ~
                             FY23_Drug_Elute_Stent_Code_BM ~
                             FY23_Arteries_Stents_4+_Code_BM ~
                             FY23_NonDrug_Elut_Stent_Code_BM ~
                             FY23_Extremely_LBW_Imm_Codes ~ 
                             FY23_Extremely_LBW_Imm_Code_BM ~
                             FY23_Newborn_Maj_Prob_Diag_BM ~
                             FY23_Extreme_Immaturity_Code ~
                             FY23_Extreme_Immaturity_Code_BM ~
                             FY23_Supplem_Mitral_Valve_Code ~
                             FY23_Supplem_Mitral_Valve_Cd_BM ~
                             FY23_MDC07_Codes ~
                             FY23_MDC07_Codes_BM ~
                             FY23_Occ_Restr_Vein_Code ~
                             FY23_Occ_Restr_Vein_Code_BM ~
                             FY23_CDE_Code ~
                             FY23_CDE_Code_BM ~
                             FY23_Liveborn_Infant_Codes ~
                             FY23_Liveborn_Infant_Codes_BM ~
                             FY23_Infectious_Disease_Codes ~
                             FY23_Infectious_Disease_Code_BM ~
                             FY23_MCC_List ~
                             FY23_CC_List ~
                             FY24_Intraluminal_Device ~
                             FY24_Coronary_IVL ~
                             FY24_Artery_Intraluminal_4+ ~
                             FY24_Cardiac_Defib_Imp ~
                             FY24_Cardiac_Catheter ~
                             FY24_Ultra_Accel_Thrombo ~
                             FY24_Aortic_Valve ~
                             FY24_Mitral_Valve ~
                             FY24_Other_Concomitant ~
                             FY24_Pulmonary_Embolism ~
                             FY24_Ultra_Accel_Thrombo_PE ~
                             FY24_Appendectomy ~
                             FY24_CRAO_BRAO ~
                             FY24_Thrombo_Agent ~
                             FY24_DRGs_177-179 ~
                             FY24_Resp_Infect_Inflam ~
                             FY24_Implant_Heart_Assist ~
                             FY24_Kidney_UT ~
                             FY24_Vesicointestinal_Fistula ~
                             FY24_Open_Excision_Musc ~
                             FY24_Gangrene ~
                             FY24_Endoscopic_Dilation ~
                             FY24_Hyper_Heart_Chron_Kidn ~
                             FY24_Skin_Subcut_Breast ~
                             FY24_MDC_09 ~
                             FY24_Occl_Splenic_Artery ~
                             FY24_Maj_Lac_Spleen_Initial ~
                             FY24_MCC_List ~
                             FY24_CC_List ~
                             FY24_Drug_Eluting_Stent_BM ~
                             FY24_Artery_Intraluminal_4+_BM ~
                             FY24_AMI_HF_Shock_BM ~
                             FY24_Cardiac_Catheter_277_BM ~
                             FY24_Ultra_Accel_Thrombo_BM ~
                             FY24_Cardiac_Catheter_212_BM ~
                             FY24_Append_Complicated_BM ~
                             FY24_CRAO_BRAO_BM ~
                             FY24_Resp_Infect_Inflam_BM ~
                             FY24_Implant_Heart_Assist_BM ~
                             FY24_Kidney_UT_BM ~
                             FY24_Vesicointestin_Fistula_BM ~
                             FY24_Open_Excision_Musc_BM ~
                             FY24_Gangrene_BM ~
                             FY24_Endoscopic_Dilation_BM ~
                             FY24_Hyper_Heart_Chron_Kidn_BM ~
                             FY24_Skin_Subcut_Breast_BM ~
                             FY24_MDC_09_BM ~
                             FY24_Occl_Splenic_Artery_BM ~
                             FY24_Maj_Lac_Spleen_Initial_BM 
                             , dlm = "~" );

      *define the name of the output datasets for the imported sheet names;
      %macarray(ds_names, drg_remapped ~
                          excluded_drg_mappings ~
                          supp_cardiac_codes ~
                          aortic_proc_codes ~
                          repair_thoracic_codes ~
                          mitral_valve_codes ~
                          icdcpt_remap_codes ~
                          lvad_codes ~
                          neuro_codes ~
                          device_codes ~
                          invasive_complex_codes ~
                          pci_intracardiac_codes ~
                          enc_dialysis_codes ~
                          enc_dialysis_codes_bm ~
                          sterilization_codes ~
                          sterilization_codes_bm1 ~
                          sterilization_codes_bm2 ~
                          neoplasm_kidney_codes ~
                          neoplasm_kidney_codes_bm ~
                          neoplasm_gen_codes ~
                          neoplasm_gen_codes_bm ~
                          extr_endo_codes ~
                          extr_endo_codes_bm ~
                          fy12_cc_codes ~
                          fy12_mcc_codes ~
                          fy12_cc_exclusions ~
                          fy20_cc_codes ~
                          fy20_mcc_codes ~
                          ecmo_codes ~
                          autologous_bm_codes ~
                          carotid_artery_codes ~
                          endovasc_cardiac_valve_codes ~
                          other_endovasc_valve_codes ~
                          other_endovasc_valve_codes_bm1 ~
                          other_endovasc_valve_codes_bm2 ~
                          knee_procedure_codes ~
                          cervical_spinal_fusion ~
                          spinal_fusion_proc ~
                          repro_system_codes ~
                          male_repro_codes ~
                          male_diagn_malig_codes ~
                          male_diagn_no_malig_codes ~
                          female_diagn_codes ~
                          musculoskeletal_codes ~
                          abnormal_radiological_codes ~
                          stomach_codes ~
                          pulmonary_embolism_codes ~
                          skin_subtissue_codes ~
                          scoliosis_codes ~
                          antepartum_codes ~
                          car_t_codes ~
                          car_t_codes_bm ~
                          cartoid_artery_dilation_codes ~
                          cartoid_artery_dilation_code_bm1 ~
                          cartoid_artery_dilation_code_bm2 ~
                          head_neck_codes ~
                          fy21_drg_129a_bm ~
                          fy21_drg_129b_bm ~
                          fy21_drg_130a_bm ~
                          fy21_drg_130b_bm ~
                          fy21_drg_131a_bm ~
                          fy21_drg_131b_bm ~
                          fy21_drg_132a_bm ~
                          fy21_drg_132b_bm ~
                          fy21_drg_133a_bm ~
                          fy21_drg_133b_bm ~
                          fy21_drg_134a_bm ~
                          fy21_drg_134b_bm ~
                          head_neck_diag_codes ~
                          ear_nose_mouth_codes ~
                          ear_nose_mouth_diag_codes ~
                          laac_codes ~
                          laac_codes_bm ~
                          hip_fracture_codes ~
                          hip_fracture_codes_bm ~
                          hemodialysis_codes ~
                          hemodialysis_codes_bm ~
                          kidney_transplant_codes ~
                          kidney_transplant_codes_bm ~
                          vascular_dialysis_codes ~
                          vascular_dialysis_codes_bm ~
                          non_or_codes ~
                          non_or_codes_bm ~
                          peritoneal_cavity_codes ~
                          peritoneal_cavity_codes_bm ~
                          mediastinum_excision_codes ~
                          mediastinum_excision_bm ~
                          fy21_mcc_codes ~
                          fy21_cc_codes ~
                          excision_sub_tissue_codes ~
                          excision_sub_tissue_bm ~
                          litt_codes_fm1 ~
                          litt_codes_bm1 ~
                          litt_codes_fm2 ~
                          litt_codes_bm2 ~
                          litt_codes_fm3 ~
                          litt_codes_bm3 ~
                          litt_codes_fm4 ~
                          litt_codes_bm4 ~
                          esophagus_repair_codes ~
                          esophagus_repair_codes_bm ~
                          cowpers_gland_codes ~
                          cowpers_gland_codes_bm ~
                          litt_codes_fm5 ~
                          litt_codes_bm5 ~
                          litt_codes_fm6 ~
                          litt_codes_bm6 ~
                          litt_codes_fm7 ~
                          litt_codes_bm7 ~
                          litt_codes_fm8 ~
                          litt_codes_bm8 ~
                          right_knee_joint_codes_fm1 ~
                          right_knee_joint_codes_bm1 ~
                          litt_codes_fm9 ~
                          litt_codes_bm9 ~
                          litt_codes_fm10 ~
                          litt_codes_bm10 ~
                          pulm_thor_ster_ribs_codes ~
                          pulm_thor_ster_ribs_bm ~
                          heart_device_codes ~
                          heart_device_codes_bm ~
                          cardiac_cath_codes ~
                          cardiac_cath_codes_bm ~
                          viral_cardiomyopathy_codes ~
                          viral_cardiomyopathy_bm ~
                          right_knee_joint_codes_fm2 ~
                          right_knee_joint_codes_bm2 ~
                          bilateral_mult_codes ~
                          bilateral_mult_codes_bm ~
                          coronary_artery_byp_codes ~
                          coronary_artery_byp_bm ~
                          surgical_ablation_codes ~
                          surgical_ablation_codes_bm ~
                          fy22_mcc_list ~
                          fy22_cc_list ~
                          major_device_codes_bm ~
                          acute_complex_codes_bm ~
                          vaginal_delivery_bm ~
                          complication_codes_bm ~
                          mdc_3_codes_bm ~
                          perc_embol_codes_bm ~ 
                          acute_resp_synd_code ~
                          acute_resp_synd_code_bm ~
                          cardiac_mapping_code ~
                          cardiac_mapping_code_bm ~
                          drug_elute_stent_code_bm ~
                          art_stents_4plus_bm ~
                          nondrug_elut_stent_code_bm ~
                          extremely_lbw_imm_codes ~ 
                          extremely_lbw_imm_codes_bm ~
                          newborn_maj_prob_diag_bm ~
                          extreme_immaturity_code ~
                          extreme_immaturity_code_bm ~
                          supplem_mitral_valve_code ~
                          supplem_mitral_valve_code_bm ~
                          mdc07_codes ~
                          mdc07_codes_bm ~
                          occ_restr_vein_code ~
                          occ_restr_vein_code_bm ~
                          cde_code ~
                          cde_code_bm ~
                          liveborn_infant_codes ~
                          liveborn_infant_codes_bm ~
                          infectious_disease_codes ~
                          infectious_disease_codes_bm ~
                          fy23_mcc_list ~
                          fy23_cc_list ~
                          fy24_intralumi_device ~
                          fy24_coronary_ivl ~
                          fy24_artery_intralumi_4plus ~
                          fy24_cardiac_defib_imp ~
                          fy24_cardiac_catheter ~
                          fy24_ultra_accel_thrombo ~
                          fy24_aortic_valve ~
                          fy24_mitral_valve ~
                          fy24_other_concomitant ~
                          fy24_pulmonary_embolism ~
                          fy24_ultra_accel_thrombo_pe ~
                          fy24_appendectomy ~
                          fy24_crao_brao ~
                          fy24_thrombo_agent ~
                          fy24_DRGs_177_179 ~
                          fy24_resp_infect_inflam ~                      
                          fy24_implant_heart_assist ~
                          fy24_kidney_ut ~
                          fy24_vesicointestinal_fistula ~
                          fy24_open_excision_musc ~
                          fy24_gangrene ~
                          fy24_endoscopic_dilation ~
                          fy24_hyper_heart_chron_kidn ~
                          fy24_skin_subcut_breast ~
                          fy24_mdc_09 ~
                          fy24_occl_splenic_artery ~
                          fy24_maj_lac_spleen_initial ~
                          fy24_mcc_list ~
                          fy24_cc_list ~
                          fy24_drug_eluting_stent_bm ~
                          fy24_artery_intraluminal_4pl_bm ~
                          fy24_ami_hf_shock_bm ~
                          fy24_cardiac_catheter_277_bm ~
                          fy24_ultra_accel_thrombo_bm ~
                          fy24_cardiac_catheter_212_bm ~
                          fy24_append_complicated_bm ~
                          fy24_crao_brao_bm ~
                          fy24_resp_infect_inflam_bm ~
                          fy24_implant_heart_assist_bm ~
                          fy24_kidney_ut_bm ~
                          fy24_vesicointestin_fistula_bm ~
                          fy24_open_excision_musc_bm ~
                          fy24_gangrene_bm ~
                          fy24_endoscopic_dilation_bm ~
                          fy24_hyper_heart_chron_kidn_bm ~
                          fy24_skin_subcut_breast_bm ~
                          fy24_mdc_09_bm ~
                          fy24_occl_splenic_artery_bm ~
                          fy24_maj_lac_spleen_initial_bm 
                          , dlm = "~");

      *define the columns to be kept from each workbook sheet;
      %macarray(keep_cols, C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ AR AS AT AU AV AW AX AY AZ BA BB BC BD BE BF BG BH BI BJ BK BL BM BN BO BP BQ BR BS BT BU BV BW BX BY BZ 
                           CA CB CC CD CE CF CG CH CI CJ CK CL CM CN CO CP CQ CR CS CT CU CV CW CX CY CZ DA DB DC DD DE DF DG DH DI DJ DK DL DM DN DO DP DQ DR DS DT DU DV DW DX DY DZ EA EB EC ED EE EF EG EH 
                           EI EJ EK EL EM EN EO EP EQ ER ES ET EU EV EW EX EY EZ FA FB FC FD FE FF FG FH FI FJ FK FL FM FN FO FP FQ FR FS FT FU FV FW FX FY FZ GA GB GC GD GE GF GG GH 
                           GI GJ GK GL GM GN GO GP GQ GR GS GT GU GV GW GX GY GZ HA HB HC ~  %*drg_remapped;/*{{{*/                        
                           C D E ~ %*excluded_drg_mappings;
                           C D E F ~ %*supp_cardiac_codes;
                           C D E F ~ %*aortic_proc_codes;
                           C D E F ~ %*repair_thoracic_codes;
                           C D E F ~ %*mitral_valve_codes;
                           C D E F G H ~  %*icdcpt_remap_codes;
                           C D E F G H ~  %*lvad_codes;
                           C D E F G H I ~  %*neuro_codes;
                           C D E F G ~  %*device_codes;
                           C D E F ~  %*invasive_complex_codes;
                           C D E F ~ %*pci_intracardiac_codes;
                           C D E F ~ %*enc_dialysis_codes;
                           C D E F ~ %*enc_dialysis_codes_bm;
                           C D E F G ~ %*sterilization_codes;
                           C D E F G ~ %*sterilization_codes_bm1;
                           C D E F G ~ %*sterilization_codes_bm2;
                           C D E F ~ %*neoplasm_kidney_codes;
                           C D E F ~ %*neoplasm_kidney_codes_bm;
                           C D E F ~ %*neoplasm_gen_codes;
                           C D E F ~ %*neoplasm_gen_codes_bm;
                           C D E F ~ %*extr_endo_codes;
                           C D E F ~ %*extr_endo_codes_bm;
                           C D E ~  %*fy12_cc_codes;
                           C D E ~  %*fy12_mcc_codes;
                           C D ~  %*fy12_cc_exclusions;
                           C D E ~ %*fy20_cc_codes;
                           C D E ~ %*fy20_mcc_codes;
                           C D E F ~ %*ecmo_codes;
                           C D E F ~ %*autologous_bm_codes;
                           C D E F ~ %*carotid_artery_codes;
                           C D E F G ~ %*endovasc_cardiac_valve_codes;
                           C D E F G ~ %*other_endovasc_valve_codes;
                           C D E F G ~ %*other_endovasc_valve_codes_bm1;
                           C D E F G ~ %*other_endovasc_valve_codes_bm2;
                           C D E F G ~ %*knee_procedure_codes;
                           C D E F ~ %*cervical_spinal_fusion;
                           C D E F ~ %*spinal_fusion_proc;
                           C D E F ~ %*repro_system_codes;
                           C D E F ~ %*male_repro_codes;
                           C D E F ~ %*male_diagn_malig_codes;
                           C D E F ~ %*male_diagn_no_malig_codes;
                           C D E F ~ %*female_diagn_codes;
                           C D E F ~ %*musculoskeletal_codes;
                           C D E F ~ %*abnormal_radiological_codes;
                           C D E F ~ %*stomach_codes;                   
                           C D E F ~ %*pulmonary_embolism_codes;
                           C D E F ~ %*skin_subtissue_codes;
                           C D E F ~ %*scoliosis_codes;
                           C D E F ~ %*antepartum_codes;
                           C D E F ~ %*car_t_codes;
                           C D E F ~ %*car_t_codes_bm;
                           C D E F G H I J K L M ~ %*cartoid_artery_dilation_codes;
                           C D E F G H I J K L M ~ %*cartoid_artery_dilation_code_bm1;
                           C D E F G H I J K L M ~ %*cartoid_artery_dilation_code_bm2;
                           C D E F ~ %*head_neck_codes;
                           C D E F ~ %*fy21_drg_129a_bm;
                           C D E F ~ %*fy21_drg_129b_bm;
                           C D E F ~ %*fy21_drg_130a_bm;
                           C D E F ~ %*fy21_drg_130b_bm;
                           C D E F ~ %*fy21_drg_131a_bm;
                           C D E F ~ %*fy21_drg_131b_bm;
                           C D E F ~ %*fy21_drg_132a_bm;
                           C D E F ~ %*fy21_drg_132b_bm;
                           C D E F ~ %*fy21_drg_133a_bm;
                           C D E F ~ %*fy21_drg_133b_bm; 
                           C D E F ~ %*fy21_drg_134a_bm;
                           C D E F ~ %*fy21_drg_134b_bm;
                           C D E F ~ %*head_neck_diag_codes;
                           C D E F ~ %*ear_nose_mouth_codes;
                           C D E F ~ %*ear_nose_mouth_diag_codes;
                           C D E F ~ %*laac_codes;
                           C D E F ~ %*laac_codes_bm;
                           C D E F ~ %*hip_fracture_codes;
                           C D E F ~ %*hip_fracture_codes_bm;
                           C D E F ~ %*hemodialysis_codes;
                           C D E F ~ %*hemodialysis_codes_bm;
                           C D E F ~ %*kidney_transplant_codes;
                           C D E F ~ %*kidney_transplant_codes_bm;
                           C D E F ~ %*vascular_dialysis_codes;
                           C D E F ~ %*vascular_dialysis_codes_bm;
                           C D E F ~ %*non_or_codes;
                           C D E F ~ %*non_or_codes_bm;
                           C D E F ~ %*peritoneal_cavity_codes;
                           C D E F ~ %*peritoneal_cavity_codes_bm;
                           C D E F ~ %*mediastinum_excision_codes;
                           C D E F ~ %*mediastinum_excision_bm;
                           C D E ~ %*fy21_mcc_codes;
                           C D E ~ %*fy21_cc_codes;
                           C D E F ~ %*excision_sub_tissue_codes;
                           C D E F ~ %*excision_sub_tissue_bm;
                           C D E F ~ %*litt_codes_fm1;
                           C D E F ~ %*litt_codes_bm1;
                           C D E F ~ %*litt_codes_fm2;
                           C D E F ~ %*litt_codes_bm2;
                           C D E F ~ %*litt_codes_fm3;
                           C D E F ~ %*litt_codes_bm3;
                           C D E F ~ %*litt_codes_fm4;
                           C D E F ~ %*litt_codes_bm4;
                           C D E F ~ %*esophagus_repair_codes;
                           C D E F ~ %*esophagus_repair_codes_bm;
                           C D E F ~ %*cowpers_gland_codes;
                           C D E F ~ %*cowpers_gland_codes_bm;
                           C D E F ~ %*litt_codes_fm5;
                           C D E F ~ %*litt_codes_bm5;
                           C D E F ~ %*litt_codes_fm6;
                           C D E F ~ %*litt_codes_bm6;
                           C D E F ~ %*litt_codes_fm7;
                           C D E F ~ %*litt_codes_bm7;
                           C D E F ~ %*litt_codes_fm8;
                           C D E F ~ %*litt_codes_bm8;
                           C D E F G H I ~ %*right_knee_joint_codes_fm1;
                           C D E F G H I ~ %*right_knee_joint_codes_bm1;
                           C D E F ~ %*litt_codes_fm9;
                           C D E F ~ %*litt_codes_bm9;
                           C D E F ~ %*litt_codes_fm10;
                           C D E F ~ %*litt_codes_bm10;
                           C D E F ~ %*pulm_thor_ster_ribs_codes;
                           C D E F ~ %*pulm_thor_ster_ribs_bm;
                           C D E F ~ %*heart_device_codes;
                           C D E F ~ %*heart_device_codes_bm;
                           C D E F ~ %*cardiac_cath_codes;
                           C D E F ~ %*cardiac_cath_codes_bm;
                           C D E F ~ %*viral_cardiomyopathy_codes;
                           C D E F ~ %*viral_cardiomyopathy_bm;
                           C D E F G H I ~ %*right_knee_joint_codes_fm2;
                           C D E F G H I ~ %*right_knee_joint_codes_bm2;
                           C D E F ~ %*bilateral_mult_codes;
                           C D E F ~ %*bilateral_mult_codes_bm;
                           C D E F ~ %*coronary_artery_byp_codes;
                           C D E F ~ %*coronary_artery_byp_bm;
                           C D E F ~ %*surgical_ablation_codes;
                           C D E F ~ %*surgical_ablation_codes_bm;
                           C D E ~ %*fy22_mcc_list;
                           C D E ~ %*fy22_cc_list;
                           C D E F G H ~ %*major_device_codes_bm;
                           C D E F ~ %*acute_complex_codes_bm;
                           C D E F ~ %*vaginal_delivery_bm;
                           C D E F ~ %*complication_codes_bm;
                           C D E F ~ %*mdc_3_codes_bm;
                           C D E F ~ %*perc_embol_codes_bm;
                           C D E F ~ %*acute_resp_synd_code;
                           C D E F ~ %*acute_resp_synd_code_bm;
                           C D E F ~ %*cardiac_mapping_code; 
                           C D E F ~ %*cardiac_mapping_code_bm;
                           C D E F ~ %*drug_elute_stent_code_bm;
                           C D E F G H I ~ %*arteries_stents_4plus_code_bm;
                           C D E F ~ %*nondrug_elut_stent_code_bm;                      
                           C D E F ~ %*extremely_lbw_imm_codes; 
                           C D E F ~ %*extremely_lbw_imm_codes_bm; 
                           C D E F ~ %*newborn_maj_prob_diag_bm;
                           C D E F ~ %*extreme_immaturity_code; 
                           C D E F ~ %*extreme_immaturity_code_bm; 
                           C D E F ~ %*supplem_mitral_valve_code; 
                           C D E F ~ %*supplem_mitral_valve_code_bm; 
                           C D E F ~ %*mdc07_codes; 
                           C D E F ~ %*mdc07_codes_bm; 
                           C D E F ~ %*occ_restr_vein_code; 
                           C D E F ~ %*occ_restr_vein_code_bm; 
                           C D E F ~ %*cde_code; 
                           C D E F ~ %*cde_code_bm;
                           C D E F ~ %*liveborn_infant_codes; 
                           C D E F ~ %*liveborn_infant_codes_bm; 
                           C D E F ~ %*infectious_disease_codes; 
                           C D E F ~ %*infectious_disease_codes_bm; 
                           C D E ~ %*fy23_mcc_list; 
                           C D E ~ %*fy23_cc_list;                                                 
                           C D E F ~ %*fy24_intralumi_device; 
                           C D E F ~ %*fy24_coronary_ivl; 
                           C D E F G H I ~ %*fy24_artery_intralumi_4plus; 
                           C D E F G H  ~ %*fy24_cardiac_defib_imp; 
                           C D E F ~ %*fy24_cardiac_catheter; 
                           C D E F ~ %*fy24_ultra_accel_thrombo; 
                           C D E F ~ %*fy24_aortic_valve; 
                           C D E F ~ %*fy24_mitral_valve; 
                           C D E F ~ %*fy24_other_concomitant; 
                           C D E F ~ %*fy24_pulmonary_embolism; 
                           C D E F ~ %*fy24_ultra_accel_thrombo_pe; 
                           C D E F ~ %*fy24_appendectomy; 
                           C D E F ~ %*fy24_crao_brao; 
                           C D E F ~ %*fy24_thrombo_agent; 
                           C D E F ~ %*fy24_DRGs_177_179; 
                           C D E F ~ %*fy24_resp_infect_inflam; 
                           C D E F ~ %*fy24_implant_heart_assist; 
                           C D E F ~ %*fy24_kidney_ut; 
                           C D E F ~ %*fy24_vesicointestinal_fistula; 
                           C D E F ~ %*fy24_open_excision_musc; 
                           C D E F ~ %*fy24_gangrene; 
                           C D E F ~ %*fy24_endoscopic_dilation; 
                           C D E F ~ %*fy24_hyper_heart_chron_kidn; 
                           C D E F ~ %*fy24_skin_subcut_breast; 
                           C D E F ~ %*fy24_mdc_09; 
                           C D E F ~ %*fy24_occl_splenic_artery; 
                           C D E F ~ %*fy24_maj_lac_spleen_initial; 
                           C D E  ~ %*fy24_mcc_list; 
                           C D E  ~ %*fy24_cc_list; 
                           C D E F ~   %*fy24_drug_eluting_stent_bm ;
                           C D E F ~   %*fy24_artery_intraluminal_4pl_bm ;
                           C D E F ~   %*fy24_ami_hf_shock_bm ;
                           C D E F ~   %*fy24_cardiac_catheter_277_bm ;
                           C D E F ~   %*fy24_ultra_accel_thrombo_bm ;
                           C D E F ~   %*fy24_cardiac_catheter_212_bm ;
                           C D E F ~   %*fy24_append_complicated_bm ;
                           C D E F ~   %*fy24_crao_brao_bm ;
                           C D E F ~   %*fy24_resp_infect_inflam_bm ;
                           C D E F ~   %*fy24_implant_heart_assist_bm ;
                           C D E F ~   %*fy24_kidney_ut_bm ;
                           C D E F ~   %*fy24_vesicointestinal_fistula_bm ;
                           C D E F ~   %*fy24_open_excision_musc_bm ;
                           C D E F ~   %*fy24_gangrene_bm ;
                           C D E F ~   %*fy24_endoscopic_dilation_bm ;
                           C D E F ~   %*fy24_hyper_heart_chron_kidn_bm ;
                           C D E F ~   %*fy24_skin_subcut_breast_bm ;
                           C D E F ~   %*fy24_mdc_09_bm ;
                           C D E F ~   %*fy24_occl_splenic_artery_bm ;
                           C D E F  %*fy24_maj_lac_spleen_initial_bm ;
                           , dlm = "~");


      *define the new column name that each kept column will be renamed to;
      %macarray(rename_cols, mapping_type date_of_remap remap_drg_cd remap_drg_descrip require_neuro_check require_abn_radio_check require_male_repro_check require_caro_check require_ante_check require_endo_card_check/*{{{*/
                             require_pul_emb_check require_auto_bm_check require_ecmo_check require_repro_check require_male_malig_check require_male_no_malig_check require_fem_diagn_check require_stomach_check 
                             require_musc_check require_skin_sub_check require_othr_endo_check require_cerv_spin_check require_scol_check require_spin_proc_check require_knee_check require_device_check require_prcdrcd_check 
                             require_mcc_check require_cc_check require_cc_excl_check require_inv_comp_check require_supp_cardiac_check require_aortic_check require_repair_check require_mitral_check require_intracardiac_check 
                             require_enc_d_check require_steril_check require_neo_kid_check require_neo_gen_check require_extr_endo_check require_car_t_check require_caro_dila_check require_head_check require_head_diag_check 
                             require_ear_check require_ear_diag_check require_laac_check require_hip_frac_check require_hemo_check require_kid_trans_check require_vascular_check require_non_or_check require_peritoneal_check 
                             require_media_check require_endo_bm1_check require_endo_bm2_check require_cart_bm_check require_hemo_bm_check require_hip_fracbm_check require_kid_transbm_check require_drg129a_check require_drg130a_check 
                             require_drg131a_check require_drg132a_check require_drg133a_check require_drg134a_check require_drg129b_check require_drg130b_check require_drg131b_check require_drg132b_check require_drg133b_check require_drg134b_check 
                             require_sub_tiss_check require_litt1_check require_litt2_check require_litt3_check require_litt4_check require_eso_repair_check 
                             require_cowpers_check require_litt5_check require_litt6_check require_litt7_check require_litt8_check require_r_knee1_check require_litt9_check require_litt10_check require_pulm_thor_check 
                             require_h_device_check require_card_cath_check require_viral_card_check require_r_knee2_check require_bl_mult_check require_cor_alt_check require_surg_ab_check 
                             require_caro_dilabm1_check require_caro_dilabm2_check require_laac_bm_check require_vascular_bm_check require_non_orbm_check require_periton_bm_check require_media_bm_check require_sub_tissbm_check require_litt1_bm_check require_litt2_bm_check 
                             require_litt3_bm_check require_litt4_bm_check require_eso_repairbm_check require_cowpers_bm_check require_litt5_bm_check require_litt6_bm_check require_litt7_bm_check require_litt8_bm_check require_r_kneebm1_check 
                             require_litt9_bm_check require_litt10_bm_check require_pulm_thorbm_check require_h_devicebm_check require_card_cathbm_check require_viral_cardbm_check require_r_kneebm2_check require_bl_multbm_check require_cor_altbm_check require_surg_abbm_check 
                             require_neo_kidbm_check require_neo_genbm_check require_enc_bm_check require_ster_bm1_check require_ster_bm2_check require_extr_endobm_check require_mj_devicebm_check require_acute_compbm_check require_vgnl_bm_check require_complicat_bm_check require_mdc_3bm_check require_perc_embolbm_check 
                             require_resp_synd_check require_cardiac_map_check require_lbw_imm_check require_extreme_imm_check require_supp_mit_valve_check require_mdc07_check require_occ_restr_check require_cde_check require_liveborn_infant_check require_inf_disease_check
                             require_resp_syndbm_check require_cardiac_mapbm_check require_delst_bm_check require_as4p_bm_check require_dgel_bm_check require_lbw_immbm_check require_extreme_immbm_check require_nbmjpb_bm_check require_supp_mit_valvebm_check
                             require_mdc07_bm_check require_occ_restrbm_check require_cde_bm_check require_liveborn_infantbm_check require_inf_diseasebm_check
                             require_ild_check require_cor_ivl_check require_ac_4p_check require_cfeb_imp_check require_ccath_check require_ultaccth_check require_at_val_check
                             require_mit_val_check require_other_conc_check require_pul_emb_diag_check require_ulth_pe_check require_appen_check require_cbrao_check
                             require_thragnt_check require_DRGs_177179_check require_resp_inf_check require_imp_hrt_check require_kidney_ut_check
                             require_vesi_fist_check require_open_exc_check require_gang_check require_endo_dil_check require_hy_htkd_check require_skin_bst_check
                             require_mdc_09_check require_occl_spl_check require_maj_spl_check 
                             require_imp_hrt_bm_check require_cbrao_bm_check require_resp_inf_bm_check require_ccath212_bm_check require_open_exc_bm_check require_gang_bm_check require_endo_dil_bm_check require_hy_htkd_bm_check require_ami_hf_shock_bm_check require_ccath277_bm_check require_ultaccth_bm_check require_elute_stent_bm_check require_ac_4p_bm_check require_append_bm_check require_skin_bst_bm_check require_mdc_09_bm_check require_kidney_ut_bm_check require_vesi_fist_bm_check require_occl_spl_bm_check require_maj_spl_bm_check 
                             new_drg_cd new_drg_descrip ~  %*drg_remapped;
                             drop_drg_code drop_drg_code_descrip note ~ %*excluded_drg_mappings;
                             icd9_icd10 supp_code_type supp_code supp_code_descrip ~ %*supp_cardiac_codes;
                             icd9_icd10 aortic_code_type aortic_code aortic_code_descrip ~ %*aortic_proc_codes;
                             icd9_icd10 repair_code_type repair_code repair_code_descrip ~ %*repair_thoracic_codes;
                             icd9_icd10 mitral_code_type mitral_code mitral_code_descrip ~ %*mitral_valve_codes;
                             remap_drg_cd remap_drg_descrip date_of_remap icdcpt_code icd9_icd10 icdcpt_descrip ~  %*icdcpt_remap_codes;
                             episode_group_name drg_cd icd9_icd10 lvad_code_type lvad_code lvad_code_descrip ~  %*lvad_codes;
                             remap_drg_cd neuro_code_type required neuro_code icd9_icd10 neuro_code_descrip note ~  %*neuro_codes;
                             remap_drg_cd device_code_type device_code icd9_icd10 device_code_descrip ~  %*device_codes;
                             inv_comp_code_type inv_comp_code icd9_icd10 inv_comp_code_descrip ~  %*invasive_complex_codes;
                             pci_code_type icd9_icd10 pci_code pci_code_descrip ~ %*pci_intracardiac_codes;
                             enc_d_code_type icd9_icd10 enc_d_code enc_d_code_descrip ~ %*enc_dialysis_codes;
                             enc_bm_code_type icd9_icd10 enc_bm_code enc_bm_code_descrip ~ %*enc_dialysis_codes_bm;
                             ster_drg_cd ster_code_type icd9_icd10 ster_code ster_code_descrip ~ %*sterilization_codes;
                             ster_bm1_drg_cd ster_bm1_code_type icd9_icd10 ster_bm1_code ster_bm1_code_descrip ~ %*sterilization_codes_bm1;
                             ster_bm2_drg_cd ster_bm2_code_type icd9_icd10 ster_bm2_code ster_bm2_code_descrip ~ %*sterilization_codes_bm2;
                             icd9_icd10 neo_kid_code_type neo_kid_code neo_kid_code_descrip ~ %*neoplasm_kidney_codes;
                             icd9_icd10 neo_kidbm_code_type neo_kidbm_code neo_kidbm_code_descrip ~ %*neoplasm_kidney_codes_bm;
                             icd9_icd10 neo_gen_code_type neo_gen_code neo_gen_code_descrip ~ %*neoplasm_gen_codes;
                             icd9_icd10 neo_genbm_code_type neo_genbm_code neo_genbm_code_descrip ~ %*neoplasm_gen_codes_bm;
                             icd9_icd10 extr_endo_code_type extr_endo_code extr_endo_code_descrip ~ %*extr_endo_codes;
                             icd9_icd10 extr_endobm_code_type extr_endobm_code extr_endobm_code_descrip ~ %*extr_endo_codes_bm;
                             cc_code_type cc_code cc_code_descrip ~  %*fy12_cc_codes;
                             mcc_code_type mcc_code mcc_code_descrip ~  %*fy12_mcc_codes;
                             prim_dgnscd sec_dgnscd ~  %*fy12_cc_exclusions;
                             cc_code_type cc_code cc_code_descrip ~ %*fy20_cc_codes;
                             mcc_code_type mcc_code mcc_code_descrip ~ %*fy20_mcc_codes;
                             icd9_icd10 ecmo_code_type ecmo_code ecmo_code_descrip ~ %*ecmo_codes;
                             icd9_icd10 auto_bm_code_type auto_bm_code auto_bm_code_descrip ~ %*autologous_bm_codes;
                             icd9_icd10 caro_code_type caro_code caro_code_descrip ~ %*carotid_artery_codes;
                             endo_card_drg_cd icd9_icd10 endo_card_code_type endo_card_code endo_card_code_descrip ~ %*endovasc_cardiac_valve_codes;
                             othr_endo_drg_cd icd9_icd10 othr_endo_code_type othr_endo_code othr_endo_code_descrip ~ %*other_endovasc_valve_codes;
                             endo_bm1_drg_cd icd9_icd10 endo_bm1_code_type endo_bm1_code endo_bm1_code_descrip ~ %*other_endovasc_valve_codes_bm1;
                             endo_bm2_drg_cd icd9_icd10 endo_bm2_code_type endo_bm2_code endo_bm2_code_descrip ~ %*other_endovasc_valve_codes_bm2;
                             knee_drg_cd icd9_icd10 knee_code_type knee_code knee_code_descrip ~ %*knee_procedure_codes;
                             icd9_icd10 cerv_spin_code_type cerv_spin_code cerv_spin_code_descrip ~ %*cervical_spinal_fusion;
                             icd9_icd10 spin_proc_code_type spin_proc_code spin_proc_code_descrip ~ %*spinal_fusion_proc;
                             icd9_icd10 repro_code_type repro_code repro_code_descrip ~ %*repro_system_codes;
                             icd9_icd10 male_repro_code_type male_repro_code male_repro_code_descrip ~ %*male_repro_codes;
                             icd9_icd10 male_malig_code_type male_malig_code male_malig_code_descrip ~ %*male_diagn_malig_codes;
                             icd9_icd10 male_no_malig_code_type male_no_malig_code male_no_malig_code_descrip ~ %*male_diagn_no_malig_codes;
                             icd9_icd10 fem_diagn_code_type fem_diagn_code fem_diagn_code_descrip ~ %*female_diagn_codes;
                             icd9_icd10 musc_code_type musc_code musc_code_descrip ~ %*musculoskeletal_codes;
                             icd9_icd10 abn_radio_code_type abn_radio_code abn_radio_code_descrip ~ %*abnormal_radiological_codes;
                             icd9_icd10 stomach_code_type stomach_code stomach_code_descrip ~ %*stomach_codes;                
                             icd9_icd10 pul_emb_code_type pul_emb_code pul_emb_code_descrip ~ %*pulmonary_embolism_codes;
                             icd9_icd10 skin_sub_code_type skin_sub_code skin_sub_code_descrip ~ %*skin_subtissue_codes;
                             icd9_icd10 scol_code_type scol_code scol_code_descrip ~ %*scoliosis_codes;
                             icd9_icd10 ante_code_type ante_code ante_code_descrip ~ %*antepartum_codes;
                             icd9_icd10 car_t_code_type car_t_code car_t_code_descrip ~ %*car_t_codes;
                             icd9_icd10 cart_bm_code_type cart_bm_code cart_bm_code_descrip ~ %*car_t_codes_bm;
                             caro_dila_drg_cd icd9_icd10 caro_dila_code_type caro_dila_code1 caro_dila_code1_descrip caro_dila_code2 caro_dila_code2_descrip caro_dila_code3 caro_dila_code3_descrip caro_dila_code4 caro_dila_code4_descrip ~ %*cartoid_artery_dilation_codes;
                             caro_dilabm1_drg_cd icd9_icd10 caro_dilabm1_code_type caro_dilabm1_code1 caro_dilabm1_code1_descrip caro_dilabm1_code2 caro_dilabm1_code2_descrip caro_dilabm1_code3 caro_dilabm1_code3_descrip caro_dilabm1_code4 caro_dilabm1_code4_descrip ~ %*cartoid_artery_dilation_code_bm1;
                             caro_dilabm2_drg_cd icd9_icd10 caro_dilabm2_code_type caro_dilabm2_code1 caro_dilabm2_code1_descrip caro_dilabm2_code2 caro_dilabm2_code2_descrip caro_dilabm2_code3 caro_dilabm2_code3_descrip caro_dilabm2_code4 caro_dilabm2_code4_descrip ~ %*cartoid_artery_dilation_code_bm2;
                             icd9_icd10 head_code_type head_code head_code_descrip ~ %*head_neck_codes;
                             icd9_icd10 drg129a_code_type drg129a_code drg129a_code_descrip ~ %*fy21_drg_129a_bm;
                             icd9_icd10 drg129b_code_type drg129b_code drg129b_code_descrip ~ %*fy21_drg_129b_bm;
                             icd9_icd10 drg130a_code_type drg130a_code drg130a_code_descrip ~ %*fy21_drg_130a_bm;
                             icd9_icd10 drg130b_code_type drg130b_code drg130b_code_descrip ~ %*fy21_drg_130b_bm;
                             icd9_icd10 drg131a_code_type drg131a_code drg131a_code_descrip ~ %*fy21_drg_131a_bm;
                             icd9_icd10 drg131b_code_type drg131b_code drg131b_code_descrip ~ %*fy21_drg_131b_bm;
                             icd9_icd10 drg132a_code_type drg132a_code drg132a_code_descrip ~ %*fy21_drg_132a_bm;
                             icd9_icd10 drg132b_code_type drg132b_code drg132b_code_descrip ~ %*fy21_drg_132b_bm;
                             icd9_icd10 drg133a_code_type drg133a_code drg133a_code_descrip ~ %*fy21_drg_133a_bm;
                             icd9_icd10 drg133b_code_type drg133b_code drg133b_code_descrip ~ %*fy21_drg_133b_bm; 
                             icd9_icd10 drg134a_code_type drg134a_code drg134a_code_descrip ~ %*fy21_drg_134a_bm;
                             icd9_icd10 drg134b_code_type drg134b_code drg134b_code_descrip ~ %*fy21_drg_134b_bm;
                             icd9_icd10 head_diag_code_type head_diag_code head_diag_code_descrip ~ %*head_neck_diag_codes;
                             icd9_icd10 ear_code_type ear_code ear_code_descrip ~ %*ear_nose_mouth_codes;
                             icd9_icd10 ear_diag_code_type ear_diag_code ear_diag_code_descrip ~ %*ear_nose_mouth_diag_codes;
                             icd9_icd10 laac_code_type laac_code laac_code_descrip ~ %*laac_codes;
                             icd9_icd10 laac_bm_code_type laac_bm_code laac_bm_code_descrip ~ %*laac_codes_bm;
                             icd9_icd10 hip_frac_code_type hip_frac_code hip_frac_code_descrip ~ %*hip_fracture_codes;
                             icd9_icd10 hip_fracbm_code_type hip_fracbm_code hip_fracbm_code_descrip ~ %*hip_fracture_codes_bm;
                             icd9_icd10 hemo_code_type hemo_code hemo_code_descrip ~ %*hemodialysis_codes;
                             icd9_icd10 hemo_bm_code_type hemo_bm_code hemo_bm_code_descrip ~ %*hemodialysis_codes_bm;
                             icd9_icd10 kid_trans_code_type kid_trans_code kid_trans_code_descrip ~ %*kidney_transplant_codes;
                             icd9_icd10 kid_transbm_code_type kid_transbm_code kid_transbm_code_descrip ~ %*kidney_transplant_codes_bm;
                             icd9_icd10 vascular_code_type vascular_code vascular_code_descrip ~ %*vascular_dialysis_codes;
                             icd9_icd10 vascular_bm_code_type vascular_bm_code vascular_bm_code_descrip ~ %*vascular_dialysis_codes_bm;
                             icd9_icd10 non_or_code_type non_or_code non_or_code_descrip ~ %*non_or_codes;
                             icd9_icd10 non_orbm_code_type non_orbm_code non_orbm_code_descrip ~ %*non_or_codes_bm;
                             icd9_icd10 periton_code_type periton_code periton_code_descrip ~ %*peritoneal_cavity_codes;
                             icd9_icd10 periton_bm_code_type periton_bm_code periton_bm_code_descrip ~ %*peritoneal_cavity_codes_bm;
                             icd9_icd10 media_code_type media_code media_code_descrip ~ %*mediastinum_excision_codes;
                             icd9_icd10 media_bm_code_type media_bm_code media_bm_code_descrip ~ %*mediastinum_excision_bm;
                             mcc_code_type mcc_code mcc_code_descrip ~ %*fy21_mcc_codes;
                             cc_code_type cc_code cc_code_descrip ~  %*fy21_cc_codes;
                             icd9_icd10 sub_tiss_code_type sub_tiss_code sub_tiss_code_descrip ~ %*excision_sub_tissue_codes;
                             icd9_icd10 sub_tissbm_code_type sub_tissbm_code sub_tissbm_code_descrip ~ %*excision_sub_tissue_bm;
                             icd9_icd10 litt1_code_type litt1_code litt1_code_descrip ~ %*litt_codes_fm1;
                             icd9_icd10 litt1_bm_code_type litt1_bm_code litt1_bm_code_descrip ~ %*litt_codes_bm1;
                             icd9_icd10 litt2_code_type litt2_code litt2_code_descrip ~ %*litt_codes_fm2;
                             icd9_icd10 litt2_bm_code_type litt2_bm_code litt2_bm_code_descrip ~ %*litt_codes_bm2;
                             icd9_icd10 litt3_code_type litt3_code litt3_code_descrip ~ %*litt_codes_fm3;
                             icd9_icd10 litt3_bm_code_type litt3_bm_code litt3_bm_code_descrip ~ %*litt_codes_bm3;
                             icd9_icd10 litt4_code_type litt4_code litt4_code_descrip ~ %*litt_codes_fm4;
                             icd9_icd10 litt4_bm_code_type litt4_bm_code litt4_bm_code_descrip ~ %*litt_codes_bm4;
                             icd9_icd10 eso_repair_code_type eso_repair_code eso_repair_code_descrip ~ %*esophagus_repair_codes;
                             icd9_icd10 eso_repairbm_code_type eso_repairbm_code eso_repairbm_code_descrip ~ %*esophagus_repair_codes_bm;
                             icd9_icd10 cowpers_code_type cowpers_code cowpers_code_descrip ~ %*cowpers_gland_codes;
                             icd9_icd10 cowpers_bm_code_type cowpers_bm_code cowpers_bm_code_descrip ~ %*cowpers_gland_codes_bm;
                             icd9_icd10 litt5_code_type litt5_code litt5_code_descrip ~ %*litt_codes_fm5;
                             icd9_icd10 litt5_bm_code_type litt5_bm_code litt5_bm_code_descrip ~ %*litt_codes_bm5;
                             icd9_icd10 litt6_code_type litt6_code litt6_code_descrip ~ %*litt_codes_fm6;
                             icd9_icd10 litt6_bm_code_type litt6_bm_code litt6_bm_code_descrip ~ %*litt_codes_bm6;
                             icd9_icd10 litt7_code_type litt7_code litt7_code_descrip ~ %*litt_codes_fm7;
                             icd9_icd10 litt7_bm_code_type litt7_bm_code litt7_bm_code_descrip ~ %*litt_codes_bm7;
                             icd9_icd10 litt8_code_type litt8_code litt8_code_descrip ~ %*litt_codes_fm8;
                             icd9_icd10 litt8_bm_code_type litt8_bm_code litt8_bm_code_descrip ~ %*litt_codes_bm8;
                             r_knee1_drg_cd icd9_icd10 r_knee1_code_type r_knee1_code1 r_knee1_code1_descrip r_knee1_code2 r_knee1_code2_descrip ~ %*right_knee_joint_codes_fm1;
                             r_kneebm1_drg_cd icd9_icd10 r_kneebm1_code_type r_kneebm1_code1 r_kneebm1_code1_descrip r_kneebm1_code2 r_kneebm1_code2_descrip ~ %*right_knee_joint_codes_bm1;
                             icd9_icd10 litt9_code_type litt9_code litt9_code_descrip ~ %*litt_codes_fm9;
                             icd9_icd10 litt9_bm_code_type litt9_bm_code litt9_bm_code_descrip ~ %*litt_codes_bm9;
                             icd9_icd10 litt10_code_type litt10_code litt10_code_descrip ~ %*litt_codes_fm10;
                             icd9_icd10 litt10_bm_code_type litt10_bm_code litt10_bm_code_descrip ~ %*litt_codes_bm10;
                             icd9_icd10 pulm_thor_code_type pulm_thor_code pulm_thor_code_descrip ~ %*pulm_thor_ster_ribs_codes;
                             icd9_icd10 pulm_thorbm_code_type pulm_thorbm_code pulm_thorbm_code_descrip ~ %*pulm_thor_ster_ribs_bm;
                             icd9_icd10 h_device_code_type h_device_code h_device_code_descrip ~ %*heart_device_codes;
                             icd9_icd10 h_devicebm_code_type h_devicebm_code h_devicebm_code_descrip ~ %*heart_device_codes_bm;
                             icd9_icd10 card_cath_code_type card_cath_code card_cath_code_descrip ~ %*cardiac_cath_codes;
                             icd9_icd10 card_cathbm_code_type card_cathbm_code card_cathbm_code_descrip ~ %*cardiac_cath_codes_bm;
                             icd9_icd10 viral_card_code_type viral_card_code viral_card_code_descrip ~ %*viral_cardiomyopathy_codes;
                             icd9_icd10 viral_cardbm_code_type viral_cardbm_code viral_cardbm_code_descrip ~ %*viral_cardiomyopathy_bm;
                             r_knee2_drg_cd icd9_icd10 r_knee2_code_type r_knee2_code1 r_knee2_code1_descrip r_knee2_code2 r_knee2_code2_descrip ~ %*right_knee_joint_codes_fm2;
                             r_kneebm2_drg_cd icd9_icd10 r_kneebm2_code_type r_kneebm2_code1 r_kneebm2_code1_descrip r_kneebm2_code2 r_kneebm2_code2_descrip ~ %*right_knee_joint_codes_bm2;
                             icd9_icd10 bl_mult_code_type bl_mult_code bl_mult_code_descrip ~ %*bilateral_mult_codes;
                             icd9_icd10 bl_multbm_code_type bl_multbm_code bl_multbm_code_descrip ~ %*bilateral_mult_codes_bm;
                             icd9_icd10 cor_alt_code_type cor_alt_code cor_alt_code_descrip ~ %*coronary_artery_byp_codes;
                             icd9_icd10 cor_altbm_code_type cor_altbm_code cor_altbm_code_descrip ~ %*coronary_artery_byp_bm;
                             icd9_icd10 surg_ab_code_type surg_ab_code surg_ab_code_descrip ~ %*surgical_ablation_codes;
                             icd9_icd10 surg_abbm_code_type surg_abbm_code surg_abbm_code_descrip ~ %*surgical_ablation_codes_bm;
                             mcc_code_type mcc_code mcc_code_descrip ~ %*fy22_mcc_list;
                             cc_code_type cc_code cc_code_descrip ~ %*fy22_cc_list;
                             icd9_icd10 mj_devicebm_code_type mj_devicebm_code1 mj_devicebm_code1_descrip mj_devicebm_code2 mj_devicebm_code2_descrip ~ %*major_device_codes_bm;
                             icd9_icd10 acute_compbm_code_type acute_compbm_code acute_compbm_code_descrip ~ %*acute_complex_codes_bm;
                             icd9_icd10 vgnl_bm_code_type vgnl_bm_code vgnl_bm_code_descrip ~ %*vaginal_delivery_bm;
                             icd9_icd10 complicat_bm_code_type complicat_bm_code complicat_bm_code_descrip ~ %*complication_codes_bm;
                             icd9_icd10 mdc_3bm_code_type mdc_3bm_code mdc_3bm_code_descrip ~ %*mdc_3_codes_bm;
                             icd9_icd10 perc_embolbm_code_type perc_embolbm_code perc_embolbm_code_descrip ~ %*perc_embol_codes_bm;
                             icd9_icd10 resp_synd_code_type resp_synd_code resp_synd_code_descrip ~ %*acute_resp_synd_code;
                             icd9_icd10 resp_syndbm_code_type resp_syndbm_code resp_syndbm_code_descrip ~ %*acute_resp_synd_code_bm;
                             icd9_icd10 cardiac_map_code_type cardiac_map_code cardiac_map_code_descrip ~ %*cardiac_mapping_code; 
                             icd9_icd10 cardiac_mapbm_code_type cardiac_mapbm_code cardiac_mapbm_code_descrip ~ %*cardiac_mapping_code_bm; 
                             icd9_icd10 dgel_stent_code_type dgel_stent_code dgel_stent_code_descrip ~ %*drug_elute_stent_code_bm;
                             icd9_icd10 artst_4plus_code_type artst_4plus_code artst_4plus_nart artst_4plus_nstent artst_4plus_total_artstent artst_4plus_code_descrip ~  %*arteries_stents_4plus_code_bm;                                                                          
                             icd9_icd10 ndg_elst_code_type ndg_elst_code ndg_elst_code_descrip ~ %*nondrug_elut_stent_code_bm;                          
                             icd9_icd10 lbw_imm_code_type lbw_imm_code lbw_imm_code_descrip ~ %*extremely_lbw_imm_codes; 
                             icd9_icd10 lbw_immbm_code_type lbw_immbm_code lbw_immbm_code_descrip ~ %*extremely_lbw_imm_codes_bm; 
                             icd9_icd10 nb_mjpb_code_type nb_mjpb_code nb_mjpb_code_descrip ~ %*newborn_maj_prob_diag_bm;                          
                             icd9_icd10 extreme_imm_code_type extreme_imm_code extreme_imm_code_descrip ~ %*extreme_immaturity_code; 
                             icd9_icd10 extreme_immbm_code_type extreme_immbm_code extreme_immbm_code_descrip ~ %*extreme_immaturity_code_bm; 
                             icd9_icd10 supp_mit_valve_code_type supp_mit_valve_code supp_mit_valve_code_descrip ~ %*supplem_mitral_valve_code; 
                             icd9_icd10 supp_mit_valvebm_code_type supp_mit_valvebm_code supp_mit_valvebm_code_descrip ~ %*supplem_mitral_valve_code_bm; 
                             icd9_icd10 mdc07_code_type mdc07_code mdc07_code_descrip ~ %*mdc07_codes; 
                             icd9_icd10 mdc07_bm_code_type mdc07_bm_code mdc07_bm_code_descrip ~ %*mdc07_codes_bm; 
                             icd9_icd10 occ_restr_code_type occ_restr_code occ_restr_code_descrip ~ %*occ_restr_vein_code; 
                             icd9_icd10 occ_restrbm_code_type occ_restrbm_code occ_restrbm_code_descrip ~ %*occ_restr_vein_code_bm; 
                             icd9_icd10 cde_code_type cde_code cde_code_descrip ~ %*cde_code; 
                             icd9_icd10 cde_bm_code_type cde_bm_code cde_bm_code_descrip ~ %*cde_code_bm;                           
                             icd9_icd10 liveborn_infant_code_type liveborn_infant_code liveborn_infant_code_descrip ~ %*liveborn_infant_codes; 
                             icd9_icd10 liveborn_infantbm_code_type liveborn_infantbm_code liveborn_infantbm_code_descrip ~ %*liveborn_infant_codes_bm; 
                             icd9_icd10 inf_disease_code_type inf_disease_code inf_disease_code_descrip ~ %*infectious_disease_codes; 
                             icd9_icd10 inf_diseasebm_code_type inf_diseasebm_code inf_diseasebm_code_descrip ~ %*infectious_disease_codes_bm; 
                             mcc_code_type mcc_code mcc_code_descrip ~ %*fy23_mcc_list; 
                             cc_code_type cc_code cc_code_descrip ~ %*fy23_cc_list;                                                                            
                             icd9_icd10 fy24_intlumidev_code_type fy24_intlumidev_code fy24_intlumidev_code_descrip ~ %*fy24_intralumi_device; 
                             icd9_icd10 fy24_coronary_ivl_code_type fy24_coronary_ivl_code fy24_coronary_ivl_code_descrip ~ %*fy24_coronary_ivl; 
                             icd9_icd10 fy24_artintralu4p_code_type fy24_artintralu4p_code fy24_artintlu_numart fy24_artintlu_numstn fy24_artintlu_totcnt fy24_artintlu_code_descrip ~ %*fy24_artery_intralumi_4plus; 
                             icd9_icd10 fy24_car_defibimp_code_type fy24_car_defibimp_code1 fy24_car_defibimp_descrip1 fy24_car_defibimp_code2 fy24_car_defibimp_descrip2 ~ %*fy24_cardiac_defib_imp; 
                             icd9_icd10 fy24_carcath_code_type fy24_carcath_code fy24_carcath_code_descrip ~ %*fy24_cardiac_catheter; 
                             icd9_icd10 fy24_utth_code_type fy24_utth_code fy24_utth_code_descrip ~ %*fy24_ultra_accel_thrombo; 
                             icd9_icd10 fy24_artval_code_type fy24_artval_code fy24_artval_code_descrip ~ %*fy24_aortic_valve; 
                             icd9_icd10 fy24_mitvsl_code_type fy24_mitvsl_code fy24_mitvsl_code_descrip ~ %*fy24_mitral_valve; 
                             icd9_icd10 fy24_othcon_code_type fy24_othcon_code fy24_othcon_code_descrip ~ %*fy24_other_concomitant; 
                             icd9_icd10 fy24_pulemb_code_type fy24_pulemb_code fy24_pulemb_code_descrip ~ %*fy24_pulmonary_embolism; 
                             icd9_icd10 fy24_ulacth_code_type fy24_ulacth_code fy24_ulacth_code_descrip ~ %*fy24_ultra_accel_thrombo_pe; 
                             icd9_icd10 fy24_append_code_type fy24_append_code fy24_append_code_descrip ~ %*fy24_appendectomy; 
                             icd9_icd10 fy24_crbro_code_type fy24_crbro_code fy24_crbro_code_descrip ~ %*fy24_crao_brao; 
                             icd9_icd10 fy24_thagt_code_type fy24_thagt_code fy24_thagt_code_descrip ~ %*fy24_thrombo_agent; 
                             icd9_icd10 fy24_D177179_code_type fy24_D177179_code fy24_D177179_code_descrip ~ %*fy24_DRGs_177_179; 
                             icd9_icd10 fy24_reinflm_code_type fy24_reinflm_code fy24_reinflm_code_descrip ~ %*fy24_resp_infect_inflam; 
                             icd9_icd10 fy24_imhtast_code_type fy24_imhtast_code fy24_imhtast_code_descrip ~ %*fy24_implant_heart_assist; 
                             icd9_icd10 fy24_kd_ut_code_type fy24_kd_ut_code fy24_kd_ut_code_descrip ~ %*fy24_kidney_ut; 
                             icd9_icd10 fy24_vsfist_code_type fy24_vsfist_code fy24_vsfist_code_descrip ~ %*fy24_vesicointestinal_fistula; 
                             icd9_icd10 fy24_opexc_code_type fy24_opexc_code fy24_opexc_code_descrip ~ %*fy24_open_excision_musc;                       
                             icd9_icd10 fy24_gang_code_type fy24_gang_code fy24_gang_code_descrip ~ %*fy24_gangrene;                              
                             icd9_icd10 fy24_enddil_code_type fy24_enddil_code fy24_enddil_code_descrip ~ %*fy24_endoscopic_dilation;                              
                             icd9_icd10 fy24_hhck_code_type fy24_hhck_code fy24_hhck_code_descrip ~ %*fy24_hyper_heart_chron_kidn;                              
                             icd9_icd10 fy24_skssbrt_code_type fy24_skssbrt_code fy24_skssbrt_code_descrip ~ %*fy24_skin_subcut_breast;                              
                             icd9_icd10 fy24_mdc_09_code_type fy24_mdc_09_code fy24_mdc_09_code_descrip ~ %*fy24_mdc_09;                      
                             icd9_icd10 fy24_osart_code_type fy24_osart_code fy24_osart_code_descrip ~ %*fy24_occl_splenic_artery;                           
                             icd9_icd10 fy24_mlspln_code_type fy24_mlspln_code fy24_mlspln_code_descrip ~ %*fy24_maj_lac_spleen_initial; 
                             fy24_mcc_code_type fy24_mcc_code fy24_mcc_code_descrip ~ %*fy24_mcc_list; 
                             fy24_cc_code_type fy24_cc_code fy24_cc_code_descrip ~ %*fy24_cc_list; 
                             icd9_icd10 fy24_drug_estbm_code_type fy24_drug_estbm_code fy24_drug_estbm_code_descrip ~ %*fy24_drug_eluting_stent_bm ;
                             icd9_icd10 fy24_ailmnl_4plbm_code_type fy24_ailmnl_4plbm_code fy24_ailmnl_4plbm_code_descrip ~ %*fy24_artery_intraluminal_4pl_bm ;
                             icd9_icd10 fy24_amihf_shkbm_code_type fy24_amihf_shkbm_code fy24_amihf_shkbm_code_descrip ~ %*fy24_ami_hf_shock_bm ;
                             icd9_icd10 fy24_ccath277bm_code_type fy24_ccath277bm_code fy24_ccath277bm_code_descrip ~ %*fy24_cardiac_catheter_277_bm ;
                             icd9_icd10 fy24_ua_tbobm_code_type fy24_ua_tbobm_code fy24_ua_tbobm_code_descrip ~ %*fy24_ultra_accel_thrombo_bm ;
                             icd9_icd10 fy24_ccath212bm_code_type fy24_ccath212bm_code fy24_ccath212bm_code_descrip ~ %*fy24_cardiac_catheter_212_bm ;
                             icd9_icd10 fy24_acompbm_code_type fy24_acompbm_code fy24_acompbm_code_descrip ~ %*fy24_append_complicated_bm ;
                             icd9_icd10 fy24_craobraobm_code_type fy24_craobraobm_code fy24_craobraobm_code_descrip ~ %*fy24_crao_brao_bm ;
                             icd9_icd10 fy24_rifct_infbm_code_type fy24_rifct_infbm_code fy24_rifct_infbm_code_descrip ~ %*fy24_resp_infect_inflam_bm ;
                             icd9_icd10 fy24_ihrtastbm_code_type fy24_ihrtastbm_code fy24_ihrtastbm_code_descrip ~ %*fy24_implant_heart_assist_bm ;
                             icd9_icd10 fy24_kidney_utbm_code_type fy24_kidney_utbm_code fy24_kidney_utbm_code_descrip ~ %*fy24_kidney_ut_bm ;
                             icd9_icd10 fy24_vfistbm_code_type fy24_vfistbm_code fy24_vfistbm_code_descrip ~ %*fy24_vesicointestinal_fistula_bm ;
                             icd9_icd10 fy24_oexc_muscbm_code_type fy24_oexc_muscbm_code fy24_oexc_muscbm_code_descrip ~ %*fy24_open_excision_musc_bm ;
                             icd9_icd10 fy24_gang_bm_code_type fy24_gang_bm_code fy24_gang_bm_code_descrip ~ %*fy24_gangrene_bm ;
                             icd9_icd10 fy24_endo_dilbm_code_type fy24_endo_dilbm_code fy24_endo_dilbm_code_descrip ~ %*fy24_endoscopic_dilation_bm ;
                             icd9_icd10 fy24_hh_ckidnbm_code_type fy24_hh_ckidnbm_code fy24_hh_ckidnbm_code_descrip ~ %*fy24_hyper_heart_chron_kidn_bm ;
                             icd9_icd10 fy24_ss_brstbm_code_type fy24_ss_brstbm_code fy24_ss_brstbm_code_descrip ~ %*fy24_skin_subcut_breast_bm ;
                             icd9_icd10 fy24_mdc_09bm_code_type fy24_mdc_09bm_code fy24_mdc_09bm_code_descrip ~ %*fy24_mdc_09_bm ;
                             icd9_icd10 fy24_ospln_artbm_code_type fy24_ospln_artbm_code fy24_ospln_artbm_code_descrip ~ %*fy24_occl_splenic_artery_bm ;
                             icd9_icd10 fy24_mlspln_intbm_code_type fy24_mlspln_intbm_code fy24_mlspln_intbm_code_descrip  %*fy24_maj_lac_spleen_initial_bm ;
                             , dlm = "~");

      *define the column length of each kept column;
      %macarray(length_cols, $50.  $10.  $3. $3200. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. 
                             $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. 
                             $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. 
                             $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2.
                             $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2.
                             $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. $2. 
                             $3. $3200. ~  %*drg_remapped;/*{{{*/
                             $3.   $3200. $3200. ~ %*excluded_drg_mappings;
                             $50.  $50. $10. $3200. ~ %*supp_cardiac_codes;
                             $50.  $50. $10. $3200. ~ %*aortic_proc_codes;
                             $50.  $50. $10. $3200. ~ %*repair_thoracic_codes;
                             $50.  $50. $10. $3200. ~ %*mitral_valve_codes;
                             $3.   $3200. $10. $7.  $10. $3200. ~  %*icdcpt_remap_codes;
                             $100. $3.  $10.  $100. $10. $3200. ~  %*lvad_codes;
                             $3.   $50. $2. $10. $10. $3200. $3200. ~  %*neuro_codes;
                             $3.   $50. $10. $10. $3200. ~  %*device_codes;
                             $50.  $10. $10. $3200. ~  %*invasive_complex_codes;
                             $50.  $10.  $10. $3200. ~ %*pci_intracardiac_codes;
                             $50.  $10.  $10. $3200. ~ %*enc_dialysis_codes;
                             $50.  $10.  $10. $3200. ~ %*enc_dialysis_codes_bm;
                             $3. $50.  $10. $10.  $3200. ~ %*sterilization_codes;
                             $3. $50.  $10. $10.  $3200. ~ %*sterilization_codes_bm1;
                             $3. $50.  $10. $10.  $3200. ~ %*sterilization_codes_bm2;
                             $10.  $50.  $10. $3200. ~ %*neoplasm_kidney_codes;
                             $10.  $50.  $10. $3200. ~ %*neoplasm_kidney_codes_bm;
                             $10.  $50.  $10. $3200. ~ %*neoplasm_gen_codes;
                             $10.  $50.  $10. $3200. ~ %*neoplasm_gen_codes_bm;
                             $10.  $50.  $10. $3200. ~ %*extr_endo_codes;
                             $10.  $50.  $10. $3200. ~ %*extr_endo_codes_bm;
                             $50.  $10. $3200. ~  %*fy12_cc_codes;
                             $50.  $10. $3200. ~  %*fy12_mcc_codes;
                             $10.  $10. ~  %*fy12_cc_exclusions;
                             $50.  $10. $3200. ~ %*fy20_cc_codes;
                             $50.  $10. $3200. ~ %*fy20_mcc_codes;
                             $50.  $50. $10. $3200. ~ %*ecmo_codes;
                             $50.  $50. $10. $3200. ~ %*autologous_bm_codes;
                             $50.  $50. $10. $3200. ~ %*carotid_artery_codes;
                             $3.   $50. $50. $10. $3200. ~ %*endovasc_cardiac_valve_codes;
                             $3.   $50. $50. $10. $3200. ~ %*other_endovasc_valve_codes;
                             $3.   $50. $50. $10. $3200. ~ %*other_endovasc_valve_codes_bm1;
                             $3.   $50. $50. $10. $3200. ~ %*other_endovasc_valve_codes_bm2;
                             $3.   $50. $50. $10. $3200. ~ %*knee_procedure_codes;
                             $50.  $50. $10. $3200. ~ %*cervical_spinal_fusion;
                             $50.  $50. $10. $3200. ~ %*spinal_fusion_proc;
                             $50.  $50. $10. $3200. ~ %*repro_system_codes;
                             $50.  $50. $10. $3200. ~ %*male_repro_codes;
                             $50.  $50. $10. $3200. ~ %*male_diagn_malig_codes;
                             $50.  $50. $10. $3200. ~ %*male_diagn_no_malig_codes;
                             $50.  $50. $10. $3200. ~ %*female_diagn_codes;
                             $50.  $50. $10. $3200. ~ %*musculoskeletal_codes; 
                             $50.  $50. $10. $3200. ~ %*abnormal_radiological_codes;
                             $50.  $50. $10. $3200. ~ %*stomach_codes;
                             $50.  $50. $10. $3200. ~ %*pulmonary_embolism_codes;
                             $50.  $50. $10. $3200. ~ %*skin_subtissue_codes;
                             $50.  $50. $10. $3200. ~ %*scoliosis_codes; 
                             $50.  $50. $10. $3200. ~ %*antepartum_codes; 
                             $50.  $50. $10. $3200. ~ %*car_t_codes;
                             $50.  $50. $10. $3200. ~ %*car_t_codes_bm;
                             $3.   $50. $50. $10. $3200. $10. $3200. $10. $3200. $10. $3200. ~ %*cartoid_artery_dilation_codes;
                             $3.   $50. $50. $10. $3200. $10. $3200. $10. $3200. $10. $3200. ~ %*cartoid_artery_dilation_code_bm1;
                             $3.   $50. $50. $10. $3200. $10. $3200. $10. $3200. $10. $3200. ~ %*cartoid_artery_dilation_code_bm2;
                             $50.  $50. $10. $3200. ~ %*head_neck_codes;
                             $50.  $50. $10. $3200. ~ %*fy21_drg_129a_bm;
                             $50.  $50. $10. $3200. ~ %*fy21_drg_129b_bm;
                             $50.  $50. $10. $3200. ~ %*fy21_drg_130a_bm;
                             $50.  $50. $10. $3200. ~ %*fy21_drg_130b_bm;
                             $50.  $50. $10. $3200. ~ %*fy21_drg_131a_bm;
                             $50.  $50. $10. $3200. ~ %*fy21_drg_131b_bm;
                             $50.  $50. $10. $3200. ~ %*fy21_drg_132a_bm;
                             $50.  $50. $10. $3200. ~ %*fy21_drg_132b_bm;
                             $50.  $50. $10. $3200. ~ %*fy21_drg_133a_bm;
                             $50.  $50. $10. $3200. ~ %*fy21_drg_133b_bm; 
                             $50.  $50. $10. $3200. ~ %*fy21_drg_134a_bm;
                             $50.  $50. $10. $3200. ~ %*fy21_drg_134b_bm;
                             $50.  $50. $10. $3200. ~ %*head_neck_diag_codes;
                             $50.  $50. $10. $3200. ~ %*ear_nose_mouth_codes;
                             $50.  $50. $10. $3200. ~ %*ear_nose_mouth_diag_codes;
                             $50.  $50. $10. $3200. ~ %*laac_codes;
                             $50.  $50. $10. $3200. ~ %*laac_codes_bm;
                             $50.  $50. $10. $3200. ~ %*hip_fracture_codes;
                             $50.  $50. $10. $3200. ~ %*hip_fracture_codes_bm;
                             $50.  $50. $10. $3200. ~ %*hemodialysis_codes;
                             $50.  $50. $10. $3200. ~ %*hemodialysis_codes_bm;
                             $50.  $50. $10. $3200. ~ %*kidney_transplant_codes;
                             $50.  $50. $10. $3200. ~ %*kidney_transplant_codes_bm;
                             $50.  $50. $10. $3200. ~ %*vascular_dialysis_codes;
                             $50.  $50. $10. $3200. ~ %*vascular_dialysis_codes_bm;
                             $50.  $50. $10. $3200. ~ %*non_or_codes;
                             $50.  $50. $10. $3200. ~ %*non_or_codes_bm;
                             $50.  $50. $10. $3200. ~ %*peritoneal_cavity_codes;
                             $50.  $50. $10. $3200. ~ %*peritoneal_cavity_codes_bm;
                             $50.  $50. $10. $3200. ~ %*mediastinum_excision_codes;
                             $50.  $50. $10. $3200. ~ %*mediastinum_excision_bm;
                             $50.  $10. $3200. ~ %*fy21_mcc_codes;
                             $50.  $10. $3200. ~ %*fy21_cc_codes;
                             $50.  $50. $10. $3200. ~ %*excision_sub_tissue_codes;
                             $50.  $50. $10. $3200. ~ %*excision_sub_tissue_bm;
                             $50.  $50. $10. $3200. ~ %*litt_codes_fm1;
                             $50.  $50. $10. $3200. ~ %*litt_codes_bm1;
                             $50.  $50. $10. $3200. ~ %*litt_codes_fm2;
                             $50.  $50. $10. $3200. ~ %*litt_codes_bm2;
                             $50.  $50. $10. $3200. ~ %*litt_codes_fm3;
                             $50.  $50. $10. $3200. ~ %*litt_codes_bm3;
                             $50.  $50. $10. $3200. ~ %*litt_codes_fm4;
                             $50.  $50. $10. $3200. ~ %*litt_codes_bm4;
                             $50.  $50. $10. $3200. ~ %*esophagus_repair_codes;
                             $50.  $50. $10. $3200. ~ %*esophagus_repair_codes_bm;
                             $50.  $50. $10. $3200. ~ %*cowpers_gland_codes;
                             $50.  $50. $10. $3200. ~ %*cowpers_gland_codes_bm;
                             $50.  $50. $10. $3200. ~ %*litt_codes_fm5;
                             $50.  $50. $10. $3200. ~ %*litt_codes_bm5;
                             $50.  $50. $10. $3200. ~ %*litt_codes_fm6;
                             $50.  $50. $10. $3200. ~ %*litt_codes_bm6;
                             $50.  $50. $10. $3200. ~ %*litt_codes_fm7;
                             $50.  $50. $10. $3200. ~ %*litt_codes_bm7;
                             $50.  $50. $10. $3200. ~ %*litt_codes_fm8;
                             $50.  $50. $10. $3200. ~ %*litt_codes_bm8;
                             $3.   $50. $50. $10. $3200. $10. $3200. ~ %*right_knee_joint_codes_fm1;
                             $3.   $50. $50. $10. $3200. $10. $3200. ~ %*right_knee_joint_codes_bm1;
                             $50.  $50. $10. $3200. ~ %*litt_codes_fm9;
                             $50.  $50. $10. $3200. ~ %*litt_codes_bm9;
                             $50.  $50. $10. $3200. ~ %*litt_codes_fm10;
                             $50.  $50. $10. $3200. ~ %*litt_codes_bm10;
                             $50.  $50. $10. $3200. ~ %*pulm_thor_ster_ribs_codes;
                             $50.  $50. $10. $3200. ~ %*pulm_thor_ster_ribs_bm;
                             $50.  $50. $10. $3200. ~ %*heart_device_codes;
                             $50.  $50. $10. $3200. ~ %*heart_device_codes_bm;
                             $50.  $50. $10. $3200. ~ %*cardiac_cath_codes;
                             $50.  $50. $10. $3200. ~ %*cardiac_cath_codes_bm;
                             $50.  $50. $10. $3200. ~ %*viral_cardiomyopathy_codes;
                             $50.  $50. $10. $3200. ~ %*viral_cardiomyopathy_bm;
                             $3.   $50. $50. $10. $3200. $10. $3200. ~ %*right_knee_joint_codes_fm2;
                             $3.   $50. $50. $10. $3200. $10. $3200. ~ %*right_knee_joint_codes_bm2;
                             $50.  $50. $10. $3200. ~ %*bilateral_mult_codes;
                             $50.  $50. $10. $3200. ~ %*bilateral_mult_codes_bm;
                             $50.  $50. $10. $3200. ~ %*coronary_artery_byp_codes;
                             $50.  $50. $10. $3200. ~ %*coronary_artery_byp_bm;
                             $50.  $50. $10. $3200. ~ %*surgical_ablation_codes;
                             $50.  $50. $10. $3200. ~ %*surgical_ablation_codes_bm;
                             $50.  $10. $3200. ~ %*fy22_mcc_list;
                             $50.  $10. $3200. ~ %*fy22_cc_list;
                             $50.  $50. $10. $3200. $10. $3200. ~ %*major_device_codes_bm;
                             $50.  $50. $10. $3200. ~ %*acute_complex_codes_bm;
                             $50.  $50. $10. $3200. ~ %*vaginal_delivery_bm;
                             $50.  $50. $10. $3200. ~ %*complication_codes_bm;
                             $50.  $50. $10. $3200. ~ %*mdc_3_codes_bm;
                             $50.  $50. $10. $3200. ~ %*perc_embol_codes_bm;
                             $50.  $50. $10. $3200. ~ %*acute_resp_synd_code;
                             $50.  $50. $10. $3200. ~ %*acute_resp_synd_code_bm;
                             $50.  $50. $10. $3200. ~ %*cardiac_mapping_code; 
                             $50.  $50. $10. $3200. ~ %*cardiac_mapping_code_bm; 
                             $50.  $50. $10. $3200. ~ %*drug_elute_stent_code_bm; 
                             $50.  $50. $10. 8. 8. 8. $3200. ~ %*arteries_stents_4plus_code_bm; 
                             $50.  $50. $10. $3200. ~ %*nondrug_elut_stent_code_bm;
                             $50.  $50. $10. $3200. ~ %*extremely_lbw_imm_codes; 
                             $50.  $50. $10. $3200. ~ %*extremely_lbw_imm_codes_bm; 
                             $50.  $50. $10. $3200. ~ %*newborn_maj_prob_diag_bm;
                             $50.  $50. $10. $3200. ~ %*extreme_immaturity_code; 
                             $50.  $50. $10. $3200. ~ %*extreme_immaturity_code_bm; 
                             $50.  $50. $10. $3200. ~ %*supplem_mitral_valve_code; 
                             $50.  $50. $10. $3200. ~ %*supplem_mitral_valve_code_bm; 
                             $50.  $50. $10. $3200. ~ %*mdc07_codes; 
                             $50.  $50. $10. $3200. ~ %*mdc07_codes_bm; 
                             $50.  $50. $10. $3200. ~ %*occ_restr_vein_code; 
                             $50.  $50. $10. $3200. ~ %*occ_restr_vein_code_bm; 
                             $50.  $50. $10. $3200. ~ %*cde_code; 
                             $50.  $50. $10. $3200. ~ %*cde_code_bm; 
                             $50.  $50. $10. $3200. ~ %*liveborn_infant_codes; 
                             $50.  $50. $10. $3200. ~ %*liveborn_infant_codes_bm; 
                             $50.  $50. $10. $3200. ~ %*infectious_disease_codes; 
                             $50.  $50. $10. $3200. ~ %*infectious_disease_codes_bm; 
                             $50.  $10. $3200. ~ %*fy23_mcc_list; 
                             $50.  $10. $3200. ~ %*fy23_cc_list;   
                             $50.  $50. $10. $3200. ~ %*fy24_intralumi_device;  
                             $50.  $50. $10. $3200. ~ %*fy24_coronary_ivl; 
                             $50.  $50. $10. 8. 8. 8. $3200. ~ %*fy24_artery_intralumi_4plus; 
                             $50.  $50. $10. $3200. $10. $3200. ~ %*fy24_cardiac_defib_imp;                               
                             $50.  $50. $10. $3200. ~ %*fy24_cardiac_catheter;       
                             $50.  $50. $10. $3200. ~ %*fy24_ultra_accel_thrombo;   
                             $50.  $50. $10. $3200. ~ %*fy24_aortic_valve;    
                             $50.  $50. $10. $3200. ~ %*fy24_mitral_valve; 
                             $50.  $50. $10. $3200. ~ %*fy24_other_concomitant;  
                             $50.  $50. $10. $3200. ~ %*fy24_pulmonary_embolism;  
                             $50.  $50. $10. $3200. ~ %*fy24_ultra_accel_thrombo_pe;  
                             $50.  $50. $10. $3200. ~ %*fy24_appendectomy;
                             $50.  $50. $10. $3200. ~ %*fy24_crao_brao;
                             $50.  $50. $10. $3200. ~ %*fy24_thrombo_agent;  
                             $50.  $50. $10. $3200. ~ %*fy24_DRGs_177_179;  
                             $50.  $50. $10. $3200. ~ %*fy24_resp_infect_inflam;  
                             $50.  $50. $10. $3200. ~ %*fy24_implant_heart_assist;  
                             $50.  $50. $10. $3200. ~ %*fy24_kidney_ut; 
                             $50.  $50. $10. $3200. ~ %*fy24_vesicointestinal_fistula; 
                             $50.  $50. $10. $3200. ~ %*fy24_open_excision_musc; 
                             $50.  $50. $10. $3200. ~ %*fy24_gangrene; 
                             $50.  $50. $10. $3200. ~ %*fy24_endoscopic_dilation; 
                             $50.  $50. $10. $3200. ~ %*fy24_hyper_heart_chron_kidn; 
                             $50.  $50. $10. $3200. ~ %*fy24_skin_subcut_breast;
                             $50.  $50. $10. $3200. ~ %*fy24_mdc_09;
                             $50.  $50. $10. $3200. ~ %*fy24_occl_splenic_artery; 
                             $50.  $50. $10. $3200. ~ %*fy24_maj_lac_spleen_initial; 
                             $50. $10. $3200. ~ %*fy24_mcc_list; 
                             $50. $10. $3200. ~ %*fy24_cc_list;                             
                             $50.  $50. $10. $3200. ~    %*fy24_drug_eluting_stent_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_artery_intraluminal_4pl_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_ami_hf_shock_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_cardiac_catheter_277_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_ultra_accel_thrombo_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_cardiac_catheter_212_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_append_complicated_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_crao_brao_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_resp_infect_inflam_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_implant_heart_assist_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_kidney_ut_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_vesicointestinal_fistula_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_open_excision_musc_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_gangrene_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_endoscopic_dilation_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_hyper_heart_chron_kidn_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_skin_subcut_breast_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_mdc_09_bm ;
                             $50.  $50. $10. $3200. ~    %*fy24_occl_splenic_artery_bm ;
                             $50.  $50. $10. $3200. %*fy24_maj_lac_spleen_initial_bm ;
                             , dlm = "~");

      %do a = 1 %to &nsheet_names.;

         %macarray(kept_var, &&keep_cols&a..);
         %macarray(rename_var, &&rename_cols&a..);
         %macarray(len, &&length_cols&a..);

         *import medical codes from clinical logic workbook;
         proc import out = temp.&&ds_names&a.. (keep = &&keep_cols&a..
                                                rename = (%do b = 1 %to &nkept_var.; &&kept_var&b.. = &&rename_var&b.. %end;))
            datafile = "&clin_dir.\&drg_map_version._FY%substr(&update_factor_fy., 3)_DRG_Mapping_w_pseudo_bm.xlsx"
            dbms = xlsx
            replace;
            sheet = "&&sheet_names&a..";
            datarow = &start_row_num.;
            getnames = no;
         run;

         *apply basic formatting edits to imported datasets;
         data temp.&&ds_names&a..;
            length %do b = 1 %to &nrename_var.; &&rename_var&b.. &&len&b.. %end;;
            set temp.&&ds_names&a..;
            %do b = 1 %to &nrename_var.;
                &&rename_var&b.. = strip(&&rename_var&b..);
            %end;
            if not (%do b = 1 %to &nrename_var.; missing(&&rename_var&b..) %if &b. ^= &nrename_var. %then and; %end;) then output temp.&&ds_names&a..;
         run;
      %end;
   %end;
%mend;
