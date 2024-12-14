/*************************************************************************;
%** PROGRAM: f1_add_bene_ra_vars.sas
%** PURPOSE: To add beneficiary level variables 
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

%macro f1_add_bene_ra_vars();
   
   data temp.episodes_w_bene_ra (drop = rc_: origds_code lti_start_dt lti_end_dt esrd_start_dt esrd_end_dt drg_code  tha_code hemor_code fistula_code uc_code fb_fc_code
                                                     prcdr_code prcdr_group icd9_icd10 fracture_code trauma_code tsa_code);

      length bene_gender $25. bene_age age_50 age_50_sq 8. age_range $25. origds disabl lti esrd 8. knee_arthro_flag total_knee_arthro_flag total_hip_arthro_flag 8. hem_stroke_flag ibd_fistula_flag 
             ibd_uc_flag fb_fc_mdfr_flag 8. PARTIAL_KA THA_HIP_RESURF PARTIAL_HIP ANKLE_REATTACH_OTHER 8. icd9_icd10 $10. IP_TSA TSA_ALL PARTL_SHOULDER TRAUMA_FRAC_FLAG TSA_ALL_TRAUMA_FRAC_FLAG PARTL_SHOULDER_TRAUMA_FRAC_FLAG 8.;
      if _n_ = 1 then do;

         *list of originally disable status codes;
         if 0 then set temp.orig_disable_codes (keep = origds_code);
         declare hash disable (dataset: "temp.orig_disable_codes (keep = origds_code)");
         disable.definekey("origds_code");
         disable.definedone();

         *list of long-term care dates;
         if 0 then set clm_inp.lti (keep = link_id lti_start_dt lti_end_dt);
         declare hash lti_finder (dataset: "clm_inp.lti (keep = link_id lti_start_dt lti_end_dt)", multidata: "y");
         lti_finder.definekey("link_id");
         lti_finder.definedata("lti_start_dt", "lti_end_dt");
         lti_finder.definedone();

         *list of ESRD dates;
         if 0 then set temp.esrd (keep = link_id esrd_start_dt esrd_end_dt);
         declare hash esrd_finder (dataset: "temp.esrd (keep = link_id esrd_start_dt esrd_end_dt)", multidata: "y");
         esrd_finder.definekey("link_id");
         esrd_finder.definedata("esrd_start_dt", "esrd_end_dt");
         esrd_finder.definedone();

         *list of diagnosis codes for hemorrhagic stroke;
         if 0 then set temp.hemorrhagic_codes (keep = drg_code hemor_code icd9_icd10);
         declare hash hemor_cds (dataset: "temp.hemorrhagic_codes (keep = drg_code hemor_code icd9_icd10)");
         hemor_cds.definekey("drg_code", "hemor_code", "icd9_icd10");
         hemor_cds.definedone();
         
         *list of diagnosis codes for IBD fistula;
         if 0 then set temp.fistula_codes (keep = drg_code fistula_code icd9_icd10);
         declare hash fist_cds (dataset: "temp.fistula_codes (keep = drg_code fistula_code icd9_icd10)");
         fist_cds.definekey("drg_code", "fistula_code", "icd9_icd10");
         fist_cds.definedone();
         
         *list of diagnosis codes for IBD ulcerative colitis;
         if 0 then set temp.uc_codes (keep = drg_code uc_code icd9_icd10);
         declare hash uc_cds (dataset: "temp.uc_codes (keep = drg_code uc_code icd9_icd10)");
         uc_cds.definekey("drg_code", "uc_code", "icd9_icd10");
         uc_cds.definedone();

         *list of FB/FC modifier codes;
         if 0 then set temp.fb_fc_modifier_codes (keep = fb_fc_code);
         declare hash fb_fc (dataset: "temp.fb_fc_modifier_codes (keep = fb_fc_code)");
         fb_fc.definekey("fb_fc_code");
         fb_fc.definedone();
         
         *list of THA procedure codes;
         if 0 then set temp.tha_codes (keep = drg_code tha_code);
         declare hash tha_cds (dataset: "temp.tha_codes (keep = drg_code tha_code)");
         tha_cds.definekey("drg_code", "tha_code");
         tha_cds.definedone();
 
         *list of bene names;
         if 0 then set oth_inp.bene (keep = link_id BENE_GVN_NAME BENE_MDL_NAME BENE_SRNM_NAME MBI_ID);
         declare hash name_finder (dataset: "oth_inp.bene (keep = link_id BENE_GVN_NAME BENE_MDL_NAME BENE_SRNM_NAME MBI_ID)");
         name_finder.definekey("link_id");
         name_finder.definedata("BENE_GVN_NAME", "BENE_MDL_NAME", "BENE_SRNM_NAME", "MBI_ID");
         name_finder.definedone();
         
         *list of MJRLE procedure codes;
         %do p = 1 %to &nprcdr_labels.; %let label = &&prcdr_labels&p..; %let type = &&prcdr_types&p..;

            if 0 then set temp.mjrle_procedure_codes (keep = prcdr_code prcdr_group where = (prcdr_group = &type.));
            declare hash &label. (dataset:"temp.mjrle_procedure_codes (keep = prcdr_code prcdr_group where = (prcdr_group = "&type."))");
            &label..defineKey("prcdr_code");
            &label..defineDone();
                              
         %end;
         
         *list of MJRUE procedure codes for all total shoulder groups:
         if 0 then set temp.mjrue_procedure_groups (keep = prcdr_code);
         declare hash tsa_all_cd (dataset: "temp.mjrue_procedure_groups (keep = prcdr_code prcdr_group where = (upcase(strip(prcdr_group)) = 'TOTAL SHOULDER'))");
         tsa_all_cd.definekey("prcdr_code");
         tsa_all_cd.definedone();
         
         *list of MJRUE procedure codes for partial shoulder group:
         if 0 then set temp.mjrue_procedure_groups (keep = prcdr_code);
         declare hash part_shldr_cd (dataset: "temp.mjrue_procedure_groups (keep = prcdr_code prcdr_group where = (upcase(strip(prcdr_group)) = 'PARTIAL SHOULDER'))");
         part_shldr_cd.definekey("prcdr_code");
         part_shldr_cd.definedone();
         
         *list of fracture diagnosis codes;
         if 0 then set temp.fracture_codes (keep = fracture_code);
         declare hash fracture_cd (dataset: "temp.fracture_codes (keep = fracture_code)");
         fracture_cd.definekey("fracture_code");
         fracture_cd.definedone();

         *list of trauma diagnosis codes;
         if 0 then set temp.trauma_codes (keep = trauma_code);
         declare hash trauma_cd (dataset: "temp.trauma_codes (keep = trauma_code)");
         trauma_cd.definekey("trauma_code");
         trauma_cd.definedone();
         
         *list of TSA procedure codes;
         if 0 then set temp.tsa_codes (keep = drg_code tsa_code);
         declare hash tsa_cd (dataset: "temp.tsa_codes (keep = drg_code tsa_code)");
         tsa_cd.definekey("drg_code", "tsa_code");
         tsa_cd.definedone();

      end;
      call missing(of _all_);

      set temp.episodes_w_no_overlap;

      *beneficiary gender derived from sex race code;
      if bene_sex_race_cd in ("A","B","C","D","E","F","G","H") then bene_gender = "Male";
      else if bene_sex_race_cd in ("J","K","L","M","N","P","Q","R") then bene_gender = "Female";
      else bene_gender = "Unknown Gender";

      *beneficiary age on date of admission;
      if (not missing(bene_birth_dt)) then bene_age = floor(yrdif(bene_birth_dt, anchor_beg_dt));

      *age buckets;
      if (0 <= bene_age < 36) then age_range = "0-35";
      else if (36 <= bene_age < 65) then age_range = "36-64";
      else if (65 <= bene_age < 75) then age_range = "65-74";
      else if (75 <= bene_age < 90) then age_range = "75-89";
      else if (90 <= bene_age) then age_range = "90+";
      
      *age variable to determine the marginal effect of each additional year in age above 50;
      age_50 = bene_age - 50;
      age_50_sq = (age_50)**2;

      *create flag inidicating if original enrollment of beneficiary in Medicare was due to disability;
      if (disable.find(key: orig_mscd) = 0) then origds = 1;
      else origds = 0;

      *create flag indicating if orignal enrollement was due to disability and beneficiary is below 65 years old;
      if (origds = 1) and (bene_age < 65) then disabl = 1;
      else disabl = 0;

      *create long-term care indicator;
      lti = 0;
      if (lti_finder.find(key: link_id) = 0) then do;
         rc_lti_finder = 0;
         do while (rc_lti_finder = 0);
            if (not missing(lti_start_dt)) and (missing(lti_end_dt)) then lti_end_dt = "&sysdate."D;
            *NOTE: make sure to start one day prior to anchor begin date as to not include the anchor begin date in lti checking;
            if (anchor_lookback_dt <= lti_start_dt <= anchor_beg_dt - 1) or
               (anchor_lookback_dt <= lti_end_dt <= anchor_beg_dt - 1) or
               (lti_start_dt <= anchor_lookback_dt <= lti_end_dt) or
               (lti_start_dt <= anchor_beg_dt - 1 <= lti_end_dt)
            then lti = 1;
            if (lti = 1) then rc_lti_finder = 1;
            else rc_lti_finder = lti_finder.find_next();
         end;
      end;

      *create ESRD indicator;
      esrd = 0;
      if (esrd_finder.find(key: link_id) = 0) then do;
         rc_esrd_finder = 0;
         do while (rc_esrd_finder = 0);
            if (not missing(esrd_start_dt)) and (missing(esrd_end_dt)) then esrd_end_dt = "&sysdate."D;
            *NOTE: make sure to start one day prior to anchor begin date as to not include the anchor begin date in esrd checking;
            if (anchor_lookback_dt <= esrd_start_dt <= anchor_beg_dt - 1) or
               (anchor_lookback_dt <= esrd_end_dt <= anchor_beg_dt - 1) or
               (esrd_start_dt <= anchor_lookback_dt <= esrd_end_dt) or
               (esrd_start_dt <= anchor_beg_dt - 1 <= esrd_end_dt)
            then esrd = 1;
            if (esrd = 1) then rc_esrd_finder = 1;
            else rc_esrd_finder = esrd_finder.find_next();
         end;
      end;

      knee_arthro_flag = 0;
      total_knee_arthro_flag = 0;
      total_hip_arthro_flag = 0;
      hem_stroke_flag = 0;
      ibd_fistula_flag = 0;
      ibd_uc_flag = 0;
      fb_fc_mdfr_flag = 0;
      if (lowcase(anchor_type) = "ip") then do;
      
         *define ICD9/10;
         if (anchor_end_dt < "&icd9_icd10_date."D) then icd9_icd10 = "ICD-9";
         else icd9_icd10 = "ICD-10";
       
         *flag if stay has total hip arthroplasty (THA) procedure;
         %do a = 1 %to &diag_proc_length.;
            %let b = %sysfunc(putn(&a., z2.));
            if (tha_cds.find(key: drg_&update_factor_fy., key: prcdrcd&b.) = 0) then total_hip_arthro_flag = 1;
            %if &a. ^= &diag_proc_length. %then else;
         %end;
         
         *flag if stay has homorrhagic stroke;
         if (hemor_cds.find(key: drg_&update_factor_fy., key: pdgns_cd, key: icd9_icd10) = 0) then hem_stroke_flag = 1;
         
         *flag if stay has IBD fistula;
         if (fist_cds.find(key: drg_&update_factor_fy., key: pdgns_cd, key: icd9_icd10) = 0) then ibd_fistula_flag = 1;
         else if icd9_icd10 = "ICD-9" then do;
            %do a = 1 %to &diag_proc_length.;
               %let b = %sysfunc(putn(&a., z2.));
               if (fist_cds.find(key: drg_&update_factor_fy., key: dgnscd&b., key: icd9_icd10) = 0) then ibd_fistula_flag = 1;
               %if &a. ^= &diag_proc_length. %then else;
            %end;
         end; 
         
         *flag if stay has IBD ulcerative colitis;
         if (uc_cds.find(key: drg_&update_factor_fy., key: pdgns_cd, key: icd9_icd10) = 0) then ibd_uc_flag = 1;

      end;

      else if (lowcase(anchor_type) = "op") then do;
         
         *turn on TKA flag for OP MJRLE;
         if (upcase(strip(episode_group_name)) = "MS-MAJOR JOINT REPLACEMENT OF THE LOWER EXTREMITY") and (anchor_trigger_cd = "27447") then knee_arthro_flag = 1;
         
         *flag if OP episode has an FB or FC modifier code;
         %do a = 1 %to &mdfr_cd_length_op.;
            if (fb_fc.find(key: mdfr_cd&a.) = 0) then fb_fc_mdfr_flag = 1;
            %if &a. ^= &mdfr_cd_length_op. %then else;
         %end;
         
      end;
                  
      *flag if bene name is available for the beneficiary;
      if name_finder.find() ^= 0 then call missing(BENE_GVN_NAME, BENE_MDL_NAME, BENE_SRNM_NAME, MBI_ID);
      
      *construct MJRLE risk adjustment flags;
      TKA = 0; 
      PARTIAL_KA = 0;
      THA_HIP_RESURF = 0; 
      PARTIAL_HIP = 0;
      ANKLE_REATTACH_OTHER = 0;
      if (upcase(strip(episode_group_name)) = "MS-MAJOR JOINT REPLACEMENT OF THE LOWER EXTREMITY") then do;

         *dentify procedure type based on sub group labels;
         %do p = 1 %to &nprcdr_labels.; %let label = &&prcdr_labels&p..;

            *initialize sub group flags;
            any_&label. = 0; 

            %do a = 1 %to &diag_proc_length.;
               %let b = %sysfunc(putn(&a., z2.));
               if (&label..find(key: prcdrcd&b.)) = 0 then any_&label. = 1; 
               %if &a. ^= &diag_proc_length. %then else;
            %end;

         %end;

         *flag TKA;
         if strip(lowcase(anchor_type)) = "op" and anchor_trigger_cd = "27447" then TKA = 1;
         else if any_TKA_ = 1 or (any_L_FSKA = 1 and any_L_TSKA = 1) or (any_R_FSKA = 1 and any_R_TSKA = 1) then TKA = 1;

         *flag Partial KA episodes;
         if TKA = 0 and (any_PKA = 1 or any_R_FSKA = 1 or any_R_TSKA = 1 or any_L_FSKA = 1 or any_L_TSKA = 1) then PARTIAL_KA = 1;

         *flag THA and HIP resurfacing;
         if strip(lowcase(anchor_type)) = "op" and anchor_trigger_cd = "27130" then THA_HIP_RESURF = 1;
         else if any_THA = 1 or (any_THA_AR = 1 and any_THA_BR = 1) or (any_THA_AL = 1 and any_THA_BL = 1) or 
         (sum(of any_THA_CAR any_THA_CBR any_THA_CAL any_THA_CBL) > 0) then THA_HIP_RESURF = 1;

         *flag Partial HIP ;
         %*no PHA codes included;
         if (THA_HIP_RESURF = 0 and sum(of any_THA_AR any_THA_BR any_THA_AL any_THA_BL) > 0) then PARTIAL_HIP = 1;

         *flag ankle and reattachments;
         if (any_N = 1 and sum(of TKA PARTIAL_KA THA_HIP_RESURF PARTIAL_HIP) = 0) or 
         sum(of TKA PARTIAL_KA THA_HIP_RESURF PARTIAL_HIP) = 0 then ANKLE_REATTACH_OTHER = 1;
         
         *add checks for MJRLE RA variables to ensure that the flags are mutually exclusive;
         if sum(of TKA PARTIAL_KA  THA_HIP_RESURF PARTIAL_HIP ANKLE_REATTACH_OTHER) ^= 1 then do;
            put "ERROR: TKA covariate categories are not mutually exclusive";
            abort;
         end;    
      end;
      
      *construct MJRUE risk adjustment flags;
      IP_TSA = 0;
      TSA_ALL = 0;
      PARTL_SHOULDER = 0;
      TRAUMA_FRAC_FLAG = 0;
      TSA_ALL_TRAUMA_FRAC_FLAG = 0;
      PARTL_SHOULDER_TRAUMA_FRAC_FLAG = 0;
      if (upcase(strip(episode_group_name)) = "MS-MAJOR JOINT REPLACEMENT OF THE UPPER EXTREMITY") then do;
      
         *flag if any IP-TSA code is found on the claim;
         if strip(lowcase(anchor_type)) = "ip" then do;
            %do a = 1 %to &diag_proc_length.;
               %let b = %sysfunc(putn(&a., z2.));
               if (tsa_cd.find(key: drg_&update_factor_fy., key: prcdrcd&b.)) = 0 then IP_TSA = 1; 
               %if &a. ^= &diag_proc_length. %then else;
            %end;
         end;
      
         *identify MJRUE procedure group based on all procedure codes;
         any_tsa_all = 0;
         any_part_shldr = 0;
         %do a = 1 %to &diag_proc_length.;
            %let b = %sysfunc(putn(&a., z2.));
            if (tsa_all_cd.find(key: prcdrcd&b.)) = 0 then any_tsa_all = 1; 
            %if &a. ^= &diag_proc_length. %then else;
         %end;
         %do a = 1 %to &diag_proc_length.;
            %let b = %sysfunc(putn(&a., z2.));
            if (part_shldr_cd.find(key: prcdrcd&b.)) = 0 then any_part_shldr = 1; 
            %if &a. ^= &diag_proc_length. %then else;
         %end;
         
         if strip(lowcase(anchor_type)) = "op" then TSA_ALL = 1;
         else if any_part_shldr = 1 then PARTL_SHOULDER = 1;
         else if any_tsa_all = 1 then TSA_ALL = 1;
         
         *output episodes for check if the RA variables are not mutually exclusive;
         if sum(of TSA_ALL PARTL_SHOULDER) ^= 1 then do;
            put "ERROR: TSA covariate categories are not mutually exclusive";
            abort;
         end;    
         
         *identify fracture/trauma flag based on all diagnosis codes;
         fracture_flag = 0;
         trauma_flag = 0;
         %do a = 1 %to &diag_proc_length.;
            %let b = %sysfunc(putn(&a., z2.));
            if (fracture_cd.find(key: dgnscd&b.) = 0) then fracture_flag = 1;
            %if &a. ^= &diag_proc_length. %then else;
         %end;
         %do a = 1 %to &diag_proc_length.;
            %let b = %sysfunc(putn(&a., z2.));
            if (trauma_cd.find(key: dgnscd&b.) = 0) then trauma_flag = 1;
            %if &a. ^= &diag_proc_length. %then else;
         %end;
         if fracture_flag = 1 or trauma_flag = 1 then TRAUMA_FRAC_FLAG = 1;
         
         *interactions of fracture/trauma flag with procedure group flags;
         TSA_ALL_TRAUMA_FRAC_FLAG = TSA_ALL * TRAUMA_FRAC_FLAG;
         PARTL_SHOULDER_TRAUMA_FRAC_FLAG = PARTL_SHOULDER * TRAUMA_FRAC_FLAG;

      end;
      
      output temp.episodes_w_bene_ra;

   run;

 
%mend;

