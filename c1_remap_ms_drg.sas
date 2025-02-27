/*************************************************************************;
%** PROGRAM: c1_remap_ms_drg.sas
%** PURPOSE: To map MS-DRGs to represent the performing FYs
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro c1_remap_ms_drg();
   
   /*RESTRICT TO PAID IP STAYS AND THE NUMBER OF VARIABLES TO BE KEPT*/

   *define list of variables to keep in processed ip stays dataset;
   %let ip_keep_vars = link_id ip_stay_id stay_drg_cd provider stay_admsn_dt stay_dschrgdt stay_daily_dt stay_from_dt stay_thru_dt stus_cd at_npi op_npi stay_cr_day stay_prpayamt stay_allowed stay_std_outlier_wo_nta stay_std_deductible stay_std_coinsurance 
                       stay_std_allowed_wo_hemo_nta stay_std_allwd_wo_outlier_wo_nta dgnscd: ad_dgns prcdrcd: pdgns_cd stay_outlier stay_new_tech_pmt stay_clotting_pmt overlap_keep_acute overlap_keep_inner overlap_keep_outer overlap_keep_inner_outer ltch_stay irf_stay;

   *define the variables to be renamed in the ip stays dataset;
   %macarray(orig_vars,    stay_drg_cd    stay_admsn_dt     stay_dschrgdt     stay_daily_dt     stay_from_dt      stay_thru_dt      stay_cr_day    stay_prpayamt     stay_allowed      stay_std_deductible     stay_std_coinsurance
                           stay_std_allowed_wo_hemo_nta     stay_std_allwd_wo_outlier_wo_nta    stay_std_outlier_wo_nta);
   *define the new names to rename the variables to;
   %macarray(rename_vars,  drg_cd         admsn_dt          dschrgdt          daily_dt          from_dt           thru_dt           sum_util       clm_prpay         clm_allowed       deductible              coinsurance
                           standard_allowed_amt             standard_allowed_amt_w_o_outlier    outlier_pmt);

   *sort processed ip stays;
   proc sort data = clm_inp.ip_stays (keep = &ip_keep_vars. rename = (%do a = 1 %to &norig_vars.; &&orig_vars&a.. = &&rename_vars&a.. %end;))
             out = temp.ip_stays;
        by link_id admsn_dt dschrgdt daily_dt provider;
   run;

   *restrict to IP stays with positive standard allowed amount and create additional payment variables;
   data temp.cleaned_ip_stays;   
      length allowed_amt allowed_amt_w_o_outlier 8.;      
      set temp.ip_stays (where = (standard_allowed_amt > 0));
      
      *calculate standardized allowed amounts without new technology, clotting factors, and outlier add-on payments;
      allowed_amt = clm_allowed - sum(stay_new_tech_pmt, stay_clotting_pmt);
      allowed_amt_w_o_outlier = clm_allowed - sum(stay_new_tech_pmt, stay_clotting_pmt, stay_outlier);
   run;
   

   /*RUN DRG MAPPING*/
   
   *list of requirements to be met when mapping DRG; 
   *NOTE: be careful when changing the order of the list of variables below. may impact DRG mapping;
   %let req_check_list = require_inv_comp_check 
                         require_neuro_check 
                         require_device_check 
                         require_prcdrcd_check 
                         require_supp_cardiac_check 
                         require_aortic_check 
                         require_repair_check 
                         require_mitral_check 
                         require_intracardiac_check 
                         require_enc_d_check 
                         require_steril_check 
                         require_neo_kid_check  
                         require_neo_gen_check 
                         require_extr_endo_check
                         require_male_repro_check 
                         require_abn_radio_check 
                         require_caro_check 
                         require_ante_check 
                         require_endo_card_check 
                         require_pul_emb_check 
                         require_auto_bm_check 
                         require_ecmo_check 
                         require_repro_check
                         require_knee_check
                         require_skin_sub_check 
                         require_male_malig_check 
                         require_male_no_malig_check 
                         require_fem_diagn_check 
                         require_stomach_check 
                         require_musc_check 
                         require_othr_endo_check 
                         require_scol_check 
                         require_cerv_spin_check 
                         require_spin_proc_check
                         require_car_t_check 
                         require_caro_dila_check 
                         require_head_check 
                         require_head_diag_check 
                         require_ear_check 
                         require_ear_diag_check 
                         require_laac_check 
                         require_hip_frac_check 
                         require_hemo_check 
                         require_kid_trans_check 
                         require_vascular_check 
                         require_non_or_check 
                         require_peritoneal_check 
                         require_media_check
                         require_endo_bm1_check
                         require_endo_bm2_check
                         require_cart_bm_check 
                         require_hemo_bm_check 
                         require_hip_fracbm_check 
                         require_kid_transbm_check 
                         require_drg129a_check 
                         require_drg130a_check 
                         require_drg131a_check 
                         require_drg132a_check 
                         require_drg133a_check 
                         require_drg134a_check 
                         require_drg129b_check 
                         require_drg130b_check 
                         require_drg131b_check 
                         require_drg132b_check 
                         require_drg133b_check 
                         require_drg134b_check
                         require_sub_tiss_check 
                         require_litt1_check 
                         require_litt2_check 
                         require_litt3_check 
                         require_litt4_check 
                         require_eso_repair_check 
                         require_cowpers_check 
                         require_litt5_check 
                         require_litt6_check 
                         require_litt7_check 
                         require_litt8_check 
                         require_r_knee1_check 
                         require_litt9_check 
                         require_litt10_check 
                         require_pulm_thor_check 
                         require_h_device_check 
                         require_card_cath_check 
                         require_viral_card_check 
                         require_r_knee2_check 
                         require_bl_mult_check 
                         require_cor_alt_check 
                         require_surg_ab_check 
                         require_caro_dilabm1_check 
                         require_caro_dilabm2_check 
                         require_laac_bm_check 
                         require_vascular_bm_check 
                         require_non_orbm_check 
                         require_periton_bm_check 
                         require_media_bm_check 
                         require_sub_tissbm_check 
                         require_litt1_bm_check 
                         require_litt2_bm_check 
                         require_litt3_bm_check 
                         require_litt4_bm_check 
                         require_eso_repairbm_check 
                         require_cowpers_bm_check 
                         require_litt5_bm_check 
                         require_litt6_bm_check 
                         require_litt7_bm_check 
                         require_litt8_bm_check 
                         require_r_kneebm1_check 
                         require_litt9_bm_check 
                         require_litt10_bm_check 
                         require_pulm_thorbm_check 
                         require_h_devicebm_check 
                         require_card_cathbm_check 
                         require_viral_cardbm_check 
                         require_r_kneebm2_check 
                         require_bl_multbm_check 
                         require_cor_altbm_check 
                         require_surg_abbm_check 
                         require_neo_kidbm_check 
                         require_neo_genbm_check 
                         require_enc_bm_check 
                         require_ster_bm1_check 
                         require_ster_bm2_check 
                         require_extr_endobm_check
                         require_mj_devicebm_check
                         require_acute_compbm_check
                         require_vgnl_bm_check
                         require_complicat_bm_check
                         require_mdc_3bm_check
                         require_perc_embolbm_check
                         require_resp_synd_check
                         require_cardiac_map_check
                         require_lbw_imm_check
                         require_extreme_imm_check
                         require_supp_mit_valve_check
                         require_mdc07_check
                         require_occ_restr_check
                         require_cde_check
                         require_liveborn_infant_check
                         require_inf_disease_check                
                         require_resp_syndbm_check
                         require_cardiac_mapbm_check
                         require_delst_bm_check
                         require_as4p_bm_check
                         require_dgel_bm_check
                         require_lbw_immbm_check
                         require_extreme_immbm_check                            
                         require_nbmjpb_bm_check
                         require_supp_mit_valvebm_check
                         require_mdc07_bm_check
                         require_occ_restrbm_check
                         require_cde_bm_check
                         require_liveborn_infantbm_check
                         require_inf_diseasebm_check
                         require_ild_check
                         require_cor_ivl_check
                         require_ac_4p_check
                         require_cfeb_imp_check
                         require_ccath_check
                         require_ultaccth_check
                         require_at_val_check
                         require_mit_val_check
                         require_other_conc_check
                         require_pul_emb_diag_check
                         require_ulth_pe_check
                         require_appen_check
                         require_cbrao_check
                         require_thragnt_check
                         require_DRGs_177179_check
                         require_resp_inf_check
                         require_imp_hrt_check
                         require_kidney_ut_check
                         require_vesi_fist_check
                         require_open_exc_check
                         require_gang_check
                         require_endo_dil_check
                         require_hy_htkd_check
                         require_skin_bst_check
                         require_mdc_09_check
                         require_occl_spl_check
                         require_maj_spl_check  
                         require_elute_stent_bm_check
                         require_ac_4p_bm_check
                         require_ami_hf_shock_bm_check
                         require_ccath277_bm_check
                         require_ultaccth_bm_check
                         require_ccath212_bm_check
                         require_append_bm_check
                         require_cbrao_bm_check
                         require_resp_inf_bm_check
                         require_imp_hrt_bm_check
                         require_kidney_ut_bm_check
                         require_vesi_fist_bm_check
                         require_open_exc_bm_check
                         require_gang_bm_check
                         require_endo_dil_bm_check
                         require_hy_htkd_bm_check
                         require_skin_bst_bm_check
                         require_mdc_09_bm_check
                         require_occl_spl_bm_check
                         require_maj_spl_bm_check
                         ;                          
                   
   %macarray(req_checks, &req_check_list.);
   
   *list of the types of requirements that need to be checked/met to be mapped to a certain DRG (by FY);
   %macarray(require_types, neuro abn_radio male_repro caro ante endo_card pul_emb auto_bm ecmo repro male_malig male_no_malig fem_diagn stomach musc skin_sub othr_endo scol cerv_spin spin_proc knee
                            device prcdrcd cc mcc cc_excl inv_comp supp_cardiac aortic repair mitral intracardiac enc_d steril neo_kid neo_gen extr_endo car_t caro_dila head head_diag ear ear_diag laac hip_frac hemo 
                            kid_trans vascular non_or peritoneal media endo_bm1 endo_bm2 cart_bm hemo_bm hip_fracbm kid_transbm drg129a drg130a drg131a drg132a drg133a drg134a drg129b drg130b drg131b drg132b drg133b drg134b 
                            sub_tiss litt1 litt2 litt3 litt4 eso_repair cowpers litt5 litt6 litt7 litt8 r_knee1 litt9 litt10 pulm_thor h_device card_cath viral_card r_knee2 bl_mult cor_alt surg_ab 
                            caro_dilabm1 caro_dilabm2 laac_bm vascular_bm non_orbm periton_bm media_bm sub_tissbm litt1_bm litt2_bm litt3_bm litt4_bm eso_repairbm cowpers_bm litt5_bm litt6_bm litt7_bm litt8_bm r_kneebm1 
                            litt9_bm litt10_bm pulm_thorbm h_devicebm card_cathbm viral_cardbm r_kneebm2 bl_multbm cor_altbm surg_abbm neo_kidbm neo_genbm enc_bm ster_bm1 ster_bm2 extr_endobm 
                            mj_devicebm acute_compbm vgnl_bm complicat_bm mdc_3bm perc_embolbm
                            resp_synd cardiac_map lbw_imm extreme_imm supp_mit_valve mdc07 occ_restr cde liveborn_infant inf_disease
                            resp_syndbm cardiac_mapbm delst_bm as4p_bm dgel_bm lbw_immbm extreme_immbm nbmjpb_bm supp_mit_valvebm mdc07_bm occ_restrbm cde_bm liveborn_infantbm inf_diseasebm
                            ild cor_ivl ac_4p cfeb_imp ccath ultaccth at_val mit_val other_conc pul_emb_diag ulth_pe appen
                            cbrao thragnt DRGs_177179 resp_inf imp_hrt kidney_ut vesi_fist open_exc gang endo_dil hy_htkd skin_bst mdc_09 occl_spl maj_spl
                            elute_stent_bm ac_4p_bm ami_hf_shock_bm ccath277_bm ultaccth_bm ccath212_bm append_bm cbrao_bm resp_inf_bm imp_hrt_bm kidney_ut_bm vesi_fist_bm open_exc_bm gang_bm endo_dil_bm hy_htkd_bm skin_bst_bm 
                            mdc_09_bm occl_spl_bm maj_spl_bm);
   %macarray(fy21_require_types, car_t caro_dila head head_diag ear ear_diag laac hip_frac hemo kid_trans vascular non_or peritoneal media);
   %macarray(fy22_require_types, sub_tiss litt1 litt2 litt3 litt4 eso_repair cowpers litt5 litt6 litt7 litt8 r_knee1 litt9 litt10 pulm_thor h_device card_cath viral_card r_knee2 bl_mult cor_alt surg_ab);
   %macarray(fy21_bm_require_types, cart_bm hemo_bm hip_fracbm kid_transbm drg129a drg130a drg131a drg132a drg133a drg134a drg129b drg130b drg131b drg132b drg133b drg134b caro_dilabm1 caro_dilabm2 laac_bm vascular_bm non_orbm periton_bm media_bm mdc_3bm perc_embolbm);
   %macarray(fy22_bm_require_types, sub_tissbm litt1_bm litt2_bm litt3_bm litt4_bm eso_repairbm cowpers_bm litt5_bm litt6_bm litt7_bm litt8_bm r_kneebm1 litt9_bm litt10_bm pulm_thorbm h_devicebm card_cathbm viral_cardbm r_kneebm2 bl_multbm cor_altbm surg_abbm mj_devicebm acute_compbm);
   %macarray(fy23_require_types, resp_synd cardiac_map lbw_imm extreme_imm supp_mit_valve mdc07 occ_restr cde liveborn_infant inf_disease);
   %macarray(fy23_bm_require_types, resp_syndbm cardiac_mapbm delst_bm as4p_bm dgel_bm lbw_immbm extreme_immbm nbmjpb_bm supp_mit_valvebm mdc07_bm occ_restrbm cde_bm liveborn_infantbm inf_diseasebm);
   %macarray(fy24_require_types, ild cor_ivl ac_4p cfeb_imp ccath ultaccth at_val mit_val other_conc pul_emb_diag ulth_pe appen cbrao thragnt DRGs_177179 resp_inf imp_hrt kidney_ut vesi_fist open_exc gang endo_dil hy_htkd skin_bst mdc_09 occl_spl maj_spl); 
   %macarray(fy24_bm_require_types, elute_stent_bm ac_4p_bm ami_hf_shock_bm ccath277_bm ultaccth_bm ccath212_bm append_bm cbrao_bm resp_inf_bm imp_hrt_bm kidney_ut_bm vesi_fist_bm open_exc_bm gang_bm endo_dil_bm hy_htkd_bm skin_bst_bm mdc_09_bm occl_spl_bm maj_spl_bm); 

   *sort so that cases when a require_: variable has the value Y, it will show up on top of cases when the value is N for each DRG;
   *the reason for this sorting is so that we check the cases with the strictest criteria for remapping (i.e the cases with the most Y in its require_: variables) before the more simple cases because cases with more criteria to be checked tend to be the more severe DRG;
   *make sure to sort require_mcc before require_cc since MCC is the stricter requirement than CC;
   *we want to map an episode to the highest/strictest DRG possible;
   proc sort data = temp.drg_remapped
             out = temp.drg_remapped;
      by mapping_type date_of_remap remap_drg_cd %do a = 1 %to &nreq_checks.; descending &&req_checks&a.. %end; descending require_mcc_check descending require_cc_check descending require_cc_excl_check;
   run;

   *list of all variables to drop from final cleaned_ip_stays_w_remap_: datasets;
   %let drop_variables_list = rc_: prim_dgnscd sec_dgnscd cc_code_fybp cc_code_fypp mcc_code_fybp mcc_code_fypp remap_drg_cd date_of_remap new_drg_cd require_: icdcpt_code icd9_icd10 remap required neuro_code device_code inv_comp_code forwrd_num_y_need backwrd_num_y_need 
                              forwrd_num_y_have backwrd_num_y_have  prcdrcd_match cc_match mcc_match required_neuro_match additional_neuro_match device_match inv_comp_match supp_cardiac_match aortic_match repair_match mitral_match pci_intracardiac_match enc_d_match steril_match 
                              neo_kid_match neo_gen_match extr_endo_match abn_radio_match male_repro_match caro_match ante_match endo_card_match pul_emb_match auto_bm_match ecmo_match repro_match male_malig_match male_no_malig_match fem_diagn_match stomach_match musc_match 
                              skin_sub_match othr_endo_match scol_match cerv_spin_match spin_proc_match knee_match car_t_match caro_dila_match caro_dila_match_1 caro_dila_match_2 caro_dila_match_3 caro_dila_match_4 head_match head_diag_match ear_match ear_diag_match laac_match 
                              p_hip_frac_match d_hip_frac_match hemo_match kid_trans_match vascular_match non_or_match peritoneal_match media_match endo_bm1_match endo_bm2_match cart_bm_match hemo_bm_match p_hip_fracbm_match d_hip_fracbm_match kid_transbm_match drg129a_match drg130a_match
                              drg131a_match drg132a_match drg133a_match drg134a_match drg129b_match drg130b_match drg131b_match drg132b_match drg133b_match drg134b_match sub_tiss_match litt1_match litt2_match litt3_match litt4_match eso_repair_match cowpers_match 
                              litt5_match litt6_match litt7_match litt8_match r_knee1_match r_knee1_match_1 r_knee1_match_2 litt9_match litt10_match pulm_thor_match h_device_match card_cath_match viral_card_match r_knee2_match r_knee2_match_1 r_knee2_match_2 bl_mult_match cor_alt_match 
                              surg_ab_match caro_dilabm1_match caro_dilabm2_match laac_bm_match vascular_bm_match non_orbm_match periton_bm_match media_bm_match sub_tissbm_match litt1_bm_match litt2_bm_match litt3_bm_match litt4_bm_match eso_repairbm_match cowpers_bm_match 
                              litt5_bm_match litt6_bm_match litt7_bm_match litt8_bm_match r_kneebm1_match litt9_bm_match litt10_bm_match pulm_thorbm_match h_devicebm_match card_cathbm_match viral_cardbm_match r_kneebm2_match bl_multbm_match cor_altbm_match surg_abbm_match 
                              neo_kidbm_match neo_genbm_match enc_bm_match ster_bm1_match ster_bm2_match extr_endobm_match mj_devicebm_match acute_compbm_match vgnl_bm_match complicat_bm_match mdc_3bm_match perc_embolbm_match special_case_flag 
                              supp_code repair_code aortic_code mitral_code pci_code enc_d_code ster_drg_cd ster_code neo_kid_code neo_gen_code extr_endo_code abn_radio_code male_repro_code caro_code ante_code endo_card_drg_cd endo_card_code auto_bm_code ecmo_code repro_code 
                              male_malig_code male_no_malig_code fem_diagn_code stomach_code musc_code skin_sub_code othr_endo_drg_cd othr_endo_code scol_code cerv_spin_code spin_proc_code knee_drg_cd knee_code car_t_code caro_dila_drg_cd caro_dila_code1 caro_dila_code2 caro_dila_code3 caro_dila_code4 
                              head_code head_diag_code ear_code ear_diag_code laac_code hip_frac_code hemo_code kid_trans_code vascular_code non_or_code periton_code media_code endo_bm1_code endo_bm2_code cart_bm_code drg129a_code drg129b_code drg130a_code drg130b_code drg131a_code drg131b_code 
                              drg132a_code drg132b_code drg133a_code drg133b_code drg134a_code drg134b_code hip_fracbm_code hemo_bm_code kid_transbm_code sub_tiss_code litt1_code litt2_code litt3_code litt4_code eso_repair_code cowpers_code litt5_code litt6_code litt7_code litt8_code 
                              r_knee1_drg_cd r_knee1_code1 r_knee1_code2 litt9_code litt10_code pulm_thor_code h_device_code card_cath_code viral_card_code r_knee2_drg_cd r_knee2_code1 r_knee2_code2 bl_mult_code cor_alt_code surg_ab_code enc_bm_code ster_bm1_code ster_bm2_code 
                              neo_kidbm_code neo_genbm_code extr_endobm_code caro_dilabm1_code1 caro_dilabm2_code1 laac_bm_code vascular_bm_code non_orbm_code periton_bm_code media_bm_code sub_tissbm_code litt1_bm_code litt2_bm_code litt3_bm_code litt4_bm_code eso_repairbm_code 
                              cowpers_bm_code litt5_bm_code litt6_bm_code litt7_bm_code litt8_bm_code r_kneebm1_code1 r_kneebm1_code2 litt9_bm_code litt10_bm_code pulm_thorbm_code h_devicebm_code card_cathbm_code viral_cardbm_code r_kneebm2_code1 r_kneebm2_code2 bl_multbm_code 
                              cor_altbm_code surg_abbm_code mj_devicebm_code1 mj_devicebm_code2 acute_compbm_code vgnl_bm_code complicat_bm_code mdc_3bm_code perc_embolbm_code 
                              resp_synd_code cardiac_map_code lbw_imm_code extreme_imm_code supp_mit_valve_code mdc07_code occ_restr_code cde_code liveborn_infant_code inf_disease_code
                              resp_syndbm_code cardiac_mapbm_code dgel_stent_code artst_4plus_code_type artst_4plus_code artst_4plus_total_artstent ndg_elst_code lbw_immbm_code nb_mjpb_code
                              extreme_immbm_code supp_mit_valvebm_code mdc07_bm_code occ_restrbm_code cde_bm_code liveborn_infantbm_code inf_diseasebm_code     
                              fy24_intlumidev_code fy24_coronary_ivl_code fy24_artintralu4p_code fy24_artintlu_numart fy24_artintlu_numstn fy24_artintlu_totcnt
                              fy24_car_defibimp_code1 fy24_car_defibimp_code2 fy24_carcath_code fy24_utth_code fy24_artval_code fy24_mitvsl_code fy24_othcon_code fy24_pulemb_code
                              fy24_ulacth_code fy24_append_code fy24_crbro_code fy24_thagt_code fy24_D177179_code fy24_reinflm_code fy24_imhtast_code fy24_kd_ut_code fy24_vsfist_code
                              fy24_opexc_code fy24_gang_code fy24_enddil_code fy24_hhck_code fy24_skssbrt_code fy24_mdc_09_code fy24_osart_code fy24_mlspln_code
                              mapping_type drg_%sysfunc(min(&query_start_year., &baseline_start_year.));

   *helper macro for initializing procedure/diagnosis code match flags;
   %macro init_match_flags(); 
      remap = 0;
      prcdrcd_match = 0;
      cc_match = 0;
      mcc_match = 0;
      required_neuro_match = 0;
      additional_neuro_match = 0;
      device_match = 0;
      inv_comp_match = 0;
      supp_cardiac_match = 0;
      aortic_match = 0;
      repair_match = 0;
      mitral_match = 0;
      pci_intracardiac_match = 0;
      enc_d_match = 0;
      steril_match = 0;
      neo_kid_match = 0;
      neo_gen_match = 0;
      extr_endo_match = 0;
      abn_radio_match = 0;
      male_repro_match = 0;
      caro_match = 0;
      ante_match = 0;
      endo_card_match = 0;
      pul_emb_match = 0;
      auto_bm_match = 0;
      ecmo_match = 0;
      repro_match = 0;
      male_malig_match = 0;
      male_no_malig_match = 0;
      fem_diagn_match = 0;
      stomach_match = 0;
      musc_match = 0;
      skin_sub_match = 0;
      othr_endo_match = 0;
      scol_match = 0;
      cerv_spin_match = 0;
      spin_proc_match = 0;
      knee_match = 0;
      car_t_match = 0;
      caro_dila_match = 0;
      caro_dila_match_1 = 0;
      caro_dila_match_2 = 0;
      caro_dila_match_3 = 0;
      caro_dila_match_4 = 0;
      head_match = 0;
      head_diag_match = 0;
      ear_match = 0;
      ear_diag_match = 0;
      laac_match = 0;
      p_hip_frac_match = 0;
      d_hip_frac_match = 0;
      hemo_match = 0;
      kid_trans_match = 0;
      vascular_match = 0;
      non_or_match = 0;
      peritoneal_match = 0;
      media_match = 0;
      endo_bm1_match = 0;
      endo_bm2_match = 0;
      cart_bm_match = 0;
      hemo_bm_match = 0;
      p_hip_fracbm_match = 0;
      d_hip_fracbm_match = 0;
      kid_transbm_match = 0;
      drg129a_match = 0;
      drg130a_match = 0;
      drg131a_match = 0;
      drg132a_match = 0;
      drg133a_match = 0;
      drg134a_match = 0;
      drg129b_match = 0;
      drg130b_match = 0;
      drg131b_match = 0;
      drg132b_match = 0;
      drg133b_match = 0;
      drg134b_match = 0;
      sub_tiss_match = 0;
      litt1_match = 0;
      litt2_match = 0;
      litt3_match = 0;
      litt4_match = 0;
      eso_repair_match = 0;
      cowpers_match = 0;
      litt5_match = 0;
      litt6_match = 0;
      litt7_match = 0;
      litt8_match = 0;
      r_knee1_match = 0;
      r_knee1_match_1 = 0;
      r_knee1_match_2 = 0;
      litt9_match = 0;
      litt10_match = 0;
      pulm_thor_match = 0;
      h_device_match = 0;
      card_cath_match = 0;
      viral_card_match = 0;
      r_knee2_match = 0;
      r_knee2_match_1 = 0;
      r_knee2_match_2 = 0;
      bl_mult_match = 0;
      cor_alt_match = 0;
      surg_ab_match = 0;
      caro_dilabm1_match = 0;
      caro_dilabm2_match = 0;
      laac_bm_match = 0;
      vascular_bm_match = 0;
      non_orbm_match = 0;
      periton_bm_match = 0;
      media_bm_match = 0;
      sub_tissbm_match = 0;
      litt1_bm_match = 0;
      litt2_bm_match = 0;
      litt3_bm_match = 0;
      litt4_bm_match = 0;
      eso_repairbm_match = 0;
      cowpers_bm_match = 0;
      litt5_bm_match = 0;
      litt6_bm_match = 0;
      litt7_bm_match = 0;
      litt8_bm_match = 0;
      r_kneebm1_match = 0;
      litt9_bm_match = 0;
      litt10_bm_match = 0;
      pulm_thorbm_match = 0;
      h_devicebm_match = 0;
      card_cathbm_match = 0;
      viral_cardbm_match = 0;
      r_kneebm2_match = 0;
      bl_multbm_match = 0;
      cor_altbm_match = 0;
      surg_abbm_match = 0;
      neo_kidbm_match = 0;
      neo_genbm_match = 0;
      enc_bm_match = 0;
      ster_bm1_match = 0;
      ster_bm2_match = 0;
      extr_endobm_match = 0;
      mj_devicebm_match = 0;
      acute_compbm_match = 0;
      vgnl_bm_match = 0;
      complicat_bm_match = 0;
      mdc_3bm_match = 0;
      perc_embolbm_match = 0;
      resp_synd_match = 0;
      resp_syndbm_match = 0;
      cardiac_map_match = 0;
      cardiac_mapbm_match = 0;
      delst_bm_match =0;
      as4p_bm_match=0;
      dgel_bm_match=0;
      lbw_imm_match = 0;
      lbw_immbm_match = 0;
      nbmjpb_bm_match =0;
      extreme_imm_match = 0;
      extreme_immbm_match = 0;
      supp_mit_valve_match = 0;
      supp_mit_valvebm_match = 0;
      mdc07_match = 0;
      mdc07_bm_match = 0;
      occ_restr_match = 0;
      occ_restrbm_match = 0;
      cde_match = 0;
      cde_bm_match = 0;      
      liveborn_infant_match = 0;
      liveborn_infantbm_match = 0;
      inf_disease_match = 0;     
      inf_diseasebm_match = 0;    
      intralumid_match=0;
      coronary_ivl_match=0;
      ail4plus_match=0;
      cardef_imp_match=0;
      car_cath_match=0;
      ulaccth_match=0;
      art_valve_match=0;
      mit_valve_match=0;
      oth_con_match=0;
      pul_emb_diag_match=0;
      ulaccth_pe_match=0;
      appendectomy_match=0;
      crao_brao_match=0;
      thrb_agent_match=0;
      DRGs_177_179_match=0;
      re_infinflam_match=0;
      imp_hrta_match=0;
      kidney_ut_match=0;
      vesi_fist_match=0;
      on_exci_musc_match=0;
      gangrene_match=0;
      end_dilation_match=0;
      hy_heart_chrkidn_match=0;
      sksub_brst_match=0;
      mdc_09_match=0;
      occl_spl_art_match=0;
      maj_lac_spn_init_match=0;     
      elute_stent_bm = 0;    
      ac_4p_bm = 0; 
      ami_hf_shock_bm = 0; 
      ccath277_bm = 0; 
      ultaccth_bm = 0; 
      ccath212_bm = 0; 
      append_bm = 0; 
      cbrao_bm = 0; 
      resp_inf_bm = 0; 
      imp_hrt_bm = 0; 
      kidney_ut_bm = 0; 
      vesi_fist_bm = 0; 
      open_exc_bm = 0; 
      gang_bm = 0; 
      endo_dil_bm = 0; 
      hy_htkd_bm = 0; 
      skin_bst_bm = 0; 
      mdc_09_bm = 0; 
      occl_spl_bm = 0;   
      maj_spl_bm = 0;
      des_bm_match = 0;
      i4pl_bm_match = 0;
      amihfs_bm_match = 0;
      cc277_bm_match = 0;
      uat_bm_match = 0;
      cc212_bm_match = 0;
      acom_bm_match = 0;
      cbrao_bm_match = 0;
      rinf_bm_match = 0;
      imha_bm_match = 0;
      kidut_bm_match = 0;
      vesif_bm_match = 0;
      openem_bm_match = 0;
      gang_bm_match = 0;
      endod_bm_match = 0;
      hhck_bm_match = 0;
      ssbr_bm_match = 0;
      mdc09_bm_match = 0;
      ocspa_bm_match = 0;
      mlacs_bm_match = 0;          
      
      *the number of Ys or requirements that need to be met to be mapped to a certain DRG;
      forwrd_num_y_need = 0;
      backwrd_num_y_need = 0;
      
      *the number of Ys or requirements that was actually met;
      forwrd_num_y_have = 0;
      backwrd_num_y_have = 0;
      special_case_flag = 0;
   %mend;


   *the below code will loop through all possible mappings for a DRG, checking to see if the requirements for that mapping has been met. the code will then assign the DRG to the first mapping where all requirements have been met;
   *thus, it is important that the sorting of drg_remapped from strictest to least strictest criteria is correct so that the first mapping a DRG goes to is the strictest possible DRG mapping;
   data temp.cleaned_ip_stays_w_remap (drop = &drop_variables_list.)
        temp.ip_stays_w_missing_wght (drop = &drop_variables_list.);

      length remap prcdrcd_match cc_match mcc_match required_neuro_match additional_neuro_match device_match inv_comp_match pci_intracardiac_match forwrd_num_y_need backwrd_num_y_need forwrd_num_y_have backwrd_num_y_have special_case_flag forwrd_remap_drg_flag backwrd_remap_drg_flag 8.
             %do year = %sysfunc(min(&query_start_year., &baseline_start_year.)) %to &update_factor_fy.; drg_&year. %end; drg_cd $3.;
      
      if _n_ = 1 then do;

         *list of DRGs remapped across years;
         if 0 then set temp.drg_remapped (keep = remap_drg_cd date_of_remap new_drg_cd require_: mapping_type);
         declare hash remap_drg (dataset: "temp.drg_remapped ( keep = remap_drg_cd date_of_remap new_drg_cd require_: mapping_type)", multidata: "y");
         remap_drg.definekey("remap_drg_cd");
         remap_drg.definedata("date_of_remap", "new_drg_cd", "mapping_type", %do r = 1 %to &nrequire_types.; "require_&&require_types&r.._check" %if &r. ^= &nrequire_types. %then ,; %end;);
         remap_drg.definedone();
         
         *list of baseline period FY CC to exclude;
         if 0 then set temp.fy12_cc_exclusions (keep = prim_dgnscd sec_dgnscd);
         declare hash bpfy_excl_cc (dataset: "temp.fy12_cc_exclusions (keep = prim_dgnscd sec_dgnscd)");
         bpfy_excl_cc.definekey("prim_dgnscd", "sec_dgnscd");
         bpfy_excl_cc.definedone();

         *list of baseline period FY CC;
         if 0 then set temp.fy12_cc_codes (keep = cc_code rename = (cc_code = cc_code_fybp));
         declare hash bpfy_list_cc (dataset: "temp.fy12_cc_codes (keep = cc_code rename = (cc_code = cc_code_fybp))");
         bpfy_list_cc.definekey("cc_code_fybp");
         bpfy_list_cc.definedone();

         *list of baseline period FY MCC;
         if 0 then set temp.fy12_mcc_codes (keep = mcc_code rename = (mcc_code = mcc_code_fybp));
         declare hash bpfy_list_mcc (dataset: "temp.fy12_mcc_codes (keep = mcc_code rename = (mcc_code = mcc_code_fybp))");
         bpfy_list_mcc.definekey("mcc_code_fybp");
         bpfy_list_mcc.definedone();

         *list of performance period FY20 CC;
         if 0 then set temp.fy20_cc_codes (keep = cc_code rename = (cc_code = cc_code_fypp));
         declare hash ppfy_list_cc (dataset: "temp.fy20_cc_codes (keep = cc_code rename = (cc_code = cc_code_fypp))");
         ppfy_list_cc.definekey("cc_code_fypp");
         ppfy_list_cc.definedone();

         *list of performance period FY20 MCC;
         if 0 then set temp.fy20_mcc_codes (keep = mcc_code rename = (mcc_code = mcc_code_fypp));
         declare hash ppfy_list_mcc (dataset: "temp.fy20_mcc_codes (keep = mcc_code rename = (mcc_code = mcc_code_fypp))");
         ppfy_list_mcc.definekey("mcc_code_fypp");
         ppfy_list_mcc.definedone();

         *list of performance period FY21 CC;
         if 0 then set temp.fy21_cc_codes (keep = cc_code rename = (cc_code = cc_code_fypp));
         declare hash ppfy21_cc (dataset: "temp.fy21_cc_codes (keep = cc_code rename = (cc_code = cc_code_fypp))");
         ppfy21_cc.definekey("cc_code_fypp");
         ppfy21_cc.definedone();

         *list of performance period FY21 MCC;
         if 0 then set temp.fy21_mcc_codes (keep = mcc_code rename = (mcc_code = mcc_code_fypp));
         declare hash ppfy21_mcc (dataset: "temp.fy21_mcc_codes (keep = mcc_code rename = (mcc_code = mcc_code_fypp))");
         ppfy21_mcc.definekey("mcc_code_fypp");
         ppfy21_mcc.definedone();
         
          *list of performance period FY22 CC;
         if 0 then set temp.fy22_cc_list (keep = cc_code rename = (cc_code = cc_code_fypp));
         declare hash ppfy22_cc (dataset: "temp.fy22_cc_list (keep = cc_code rename = (cc_code = cc_code_fypp))");
         ppfy22_cc.definekey("cc_code_fypp");
         ppfy22_cc.definedone();

         *list of performance period FY22 MCC;
         if 0 then set temp.fy22_mcc_list (keep = mcc_code rename = (mcc_code = mcc_code_fypp));
         declare hash ppfy22_mcc (dataset: "temp.fy22_mcc_list (keep = mcc_code rename = (mcc_code = mcc_code_fypp))");
         ppfy22_mcc.definekey("mcc_code_fypp");
         ppfy22_mcc.definedone();

          *list of performance period FY23 CC;
         if 0 then set temp.fy23_cc_list (keep = cc_code rename = (cc_code = cc_code_fypp));
         declare hash ppfy23_cc (dataset: "temp.fy23_cc_list (keep = cc_code rename = (cc_code = cc_code_fypp))");
         ppfy23_cc.definekey("cc_code_fypp");
         ppfy23_cc.definedone();

         *list of performance period FY23 MCC;
         if 0 then set temp.fy23_mcc_list (keep = mcc_code rename = (mcc_code = mcc_code_fypp));
         declare hash ppfy23_mcc (dataset: "temp.fy23_mcc_list (keep = mcc_code rename = (mcc_code = mcc_code_fypp))");
         ppfy23_mcc.definekey("mcc_code_fypp");
         ppfy23_mcc.definedone();
         
         *list of performance period FY24 CC;
         if 0 then set temp.fy24_cc_list (keep = fy24_cc_code rename = (fy24_cc_code = cc_code_fypp));
         declare hash ppfy24_cc (dataset: "temp.fy24_cc_list (keep = fy24_cc_code rename = (fy24_cc_code = cc_code_fypp))");
         ppfy24_cc.definekey("cc_code_fypp");
         ppfy24_cc.definedone();

         *list of performance period FY24 MCC;
         if 0 then set temp.fy24_mcc_list (keep = fy24_mcc_code rename = (fy24_mcc_code = mcc_code_fypp));
         declare hash ppfy24_mcc (dataset: "temp.fy24_mcc_list (keep = fy24_mcc_code rename = (fy24_mcc_code = mcc_code_fypp))");
         ppfy24_mcc.definekey("mcc_code_fypp");
         ppfy24_mcc.definedone();                                           
         
         *list of icd/cpt codes needed for remapping DRGs;
         if 0 then set temp.icdcpt_remap_codes (keep = remap_drg_cd date_of_remap icdcpt_code icd9_icd10);
         declare hash icdcpt (dataset: "temp.icdcpt_remap_codes (keep = remap_drg_cd date_of_remap icdcpt_code icd9_icd10)", multidata: "y");
         icdcpt.definekey("remap_drg_cd", "date_of_remap");
         icdcpt.definedata("icdcpt_code", "icd9_icd10");
         icdcpt.definedone();

         *list of neuro procedure codes;
         if 0 then set temp.neuro_codes (keep = remap_drg_cd required neuro_code icd9_icd10);
         declare hash neuro (dataset: "temp.neuro_codes (keep = remap_drg_cd required neuro_code icd9_icd10)", multidata: "y");
         neuro.definekey("remap_drg_cd");
         neuro.definedata("required", "neuro_code", "icd9_icd10");
         neuro.definedone();

         *list of device procedure codes;
         if 0 then set temp.device_codes (keep = remap_drg_cd device_code icd9_icd10);
         declare hash device (dataset: "temp.device_codes (keep = remap_drg_cd device_code icd9_icd10)", multidata: "y");
         device.definekey("remap_drg_cd");
         device.definedata("device_code", "icd9_icd10");
         device.definedone();

         *list of invasive/complex procedure codes;
         if 0 then set temp.invasive_complex_codes (keep = inv_comp_code);
         declare hash inv_comp (dataset: "temp.invasive_complex_codes (keep = inv_comp_code)");
         inv_comp.definekey("inv_comp_code");
         inv_comp.definedone();

         *list of supplementary cardiac codes;
         if 0 then set temp.supp_cardiac_codes (keep = supp_code icd9_icd10);
         declare hash supp_cd (dataset: "temp.supp_cardiac_codes (keep = supp_code icd9_icd10)");
         supp_cd.definekey("supp_code");
         supp_cd.definedata("supp_code", "icd9_icd10");
         supp_cd.definedone();

         *list of repair thoracic codes;
         if 0 then set temp.repair_thoracic_codes (keep = repair_code icd9_icd10);
         declare hash repair_cd (dataset: "temp.repair_thoracic_codes (keep = repair_code icd9_icd10)");
         repair_cd.definekey("repair_code");
         repair_cd.definedata("repair_code", "icd9_icd10");
         repair_cd.definedone();

         *list of aortic procedure codes;
         if 0 then set temp.aortic_proc_codes (keep = aortic_code icd9_icd10);
         declare hash aortic_cd (dataset: "temp.aortic_proc_codes (keep = aortic_code icd9_icd10)");
         aortic_cd.definekey("aortic_code");
         aortic_cd.definedata("aortic_code", "icd9_icd10");
         aortic_cd.definedone();

         *list of mitral valve codes;
         if 0 then set temp.mitral_valve_codes (keep = mitral_code icd9_icd10);
         declare hash mitral_cd (dataset: "temp.mitral_valve_codes (keep = mitral_code icd9_icd10)");
         mitral_cd.definekey("mitral_code");
         mitral_cd.definedata("mitral_code", "icd9_icd10");
         mitral_cd.definedone();

         *list of PCI intracardiac codes;
         if 0 then set temp.pci_intracardiac_codes (keep = pci_code icd9_icd10);
         declare hash pci_cd (dataset: "temp.pci_intracardiac_codes (keep = pci_code icd9_icd10)");
         pci_cd.definekey("pci_code");
         pci_cd.definedata("pci_code", "icd9_icd10");
         pci_cd.definedone();

         *list of encounter dialysis codes;
         if 0 then set temp.enc_dialysis_codes (keep = enc_d_code icd9_icd10);
         declare hash enc_cd (dataset: "temp.enc_dialysis_codes (keep = enc_d_code icd9_icd10)");
         enc_cd.definekey("enc_d_code");
         enc_cd.definedata("enc_d_code", "icd9_icd10");
         enc_cd.definedone();

         *list of sterilization codes;
         if 0 then set temp.sterilization_codes (keep = ster_drg_cd ster_code icd9_icd10);
         declare hash ster_cd (dataset: "temp.sterilization_codes (keep = ster_drg_cd ster_code icd9_icd10)");
         ster_cd.definekey("ster_drg_cd", "ster_code");
         ster_cd.definedata("ster_drg_cd", "ster_code", "icd9_icd10");
         ster_cd.definedone();

         *list of neoplasm kidney codes;
         if 0 then set temp.neoplasm_kidney_codes (keep = neo_kid_code icd9_icd10);
         declare hash neo_kid_cd (dataset: "temp.neoplasm_kidney_codes (keep = neo_kid_code icd9_icd10)");
         neo_kid_cd.definekey("neo_kid_code");
         neo_kid_cd.definedata("neo_kid_code", "icd9_icd10");
         neo_kid_cd.definedone();

         *list of neoplasm genitourinary codes;
         if 0 then set temp.neoplasm_gen_codes (keep = neo_gen_code icd9_icd10);
         declare hash neo_gen_cd (dataset: "temp.neoplasm_gen_codes (keep = neo_gen_code icd9_icd10)");
         neo_gen_cd.definekey("neo_gen_code");
         neo_gen_cd.definedata("neo_gen_code", "icd9_icd10");
         neo_gen_cd.definedone();

         *list of manual extraction of products of conceptions codes;
         if 0 then set temp.extr_endo_codes (keep = extr_endo_code icd9_icd10);
         declare hash extr_endo_cd (dataset: "temp.extr_endo_codes (keep = extr_endo_code icd9_icd10)");
         extr_endo_cd.definekey("extr_endo_code");
         extr_endo_cd.definedata("extr_endo_code", "icd9_icd10");
         extr_endo_cd.definedone();

         *list of abnormal radiologic codes;
         if 0 then set temp.abnormal_radiological_codes (keep = abn_radio_code icd9_icd10);
         declare hash abn_radio_cd (dataset: "temp.abnormal_radiological_codes (keep = abn_radio_code icd9_icd10)");
         abn_radio_cd.definekey("abn_radio_code");
         abn_radio_cd.definedata("abn_radio_code", "icd9_icd10");
         abn_radio_cd.definedone();

         *list of male reproductive system codes;
         if 0 then set temp.male_repro_codes (keep = male_repro_code icd9_icd10);
         declare hash male_repro_cd (dataset: "temp.male_repro_codes (keep = male_repro_code icd9_icd10)");
         male_repro_cd.definekey("male_repro_code");
         male_repro_cd.definedata("male_repro_code", "icd9_icd10");
         male_repro_cd.definedone();

         *list of carotid artery codes;
         if 0 then set temp.carotid_artery_codes (keep = caro_code icd9_icd10);
         declare hash caro_cd (dataset: "temp.carotid_artery_codes (keep = caro_code icd9_icd10)");
         caro_cd.definekey("caro_code");
         caro_cd.definedata("caro_code", "icd9_icd10");
         caro_cd.definedone();

         *list of codes describing conditions complicating pregnancy, childbirth and the puerperium;
         if 0 then set temp.antepartum_codes (keep = ante_code icd9_icd10);
         declare hash ante_cd (dataset: "temp.antepartum_codes (keep = ante_code icd9_icd10)");
         ante_cd.definekey("ante_code");
         ante_cd.definedata("ante_code", "icd9_icd10");
         ante_cd.definedone();

         *list of codes describing a transcatheter cardiac valve repair;
         if 0 then set temp.endovasc_cardiac_valve_codes (keep = endo_card_drg_cd endo_card_code icd9_icd10);
         declare hash endo_card_cd (dataset: "temp.endovasc_cardiac_valve_codes (keep = endo_card_drg_cd endo_card_code icd9_icd10)");
         endo_card_cd.definekey("endo_card_drg_cd", "endo_card_code");
         endo_card_cd.definedata("endo_card_drg_cd", "endo_card_code", "icd9_icd10");
         endo_card_cd.definedone();

         *list of pulmonary embolism codes;
         if 0 then set temp.pulmonary_embolism_codes (keep = pul_emb_code icd9_icd10);
         declare hash pul_emb_cd (dataset: "temp.pulmonary_embolism_codes (keep = pul_emb_code icd9_icd10)");
         pul_emb_cd.definekey("pul_emb_code");
         pul_emb_cd.definedata("pul_emb_code", "icd9_icd10");
         pul_emb_cd.definedone();

         *list of codes specifying autologous cordblood stem cell as the donor source;
         if 0 then set temp.autologous_bm_codes (keep = auto_bm_code icd9_icd10);
         declare hash auto_bm_cd (dataset: "temp.autologous_bm_codes (keep = auto_bm_code icd9_icd10)");
         auto_bm_cd.definekey("auto_bm_code");
         auto_bm_cd.definedata("auto_bm_code", "icd9_icd10");
         auto_bm_cd.definedone();

         *list of extracorporeal membrane oxygenation codes;
         if 0 then set temp.ecmo_codes (keep = ecmo_code icd9_icd10);
         declare hash ecmo_cd (dataset: "temp.ecmo_codes (keep = ecmo_code icd9_icd10)");
         ecmo_cd.definekey("ecmo_code");
         ecmo_cd.definedata("ecmo_code", "icd9_icd10");
         ecmo_cd.definedone();

         *list of codes describing revision or removal of extraluminal device in stomach, percutaneous endoscopic approach;
         if 0 then set temp.repro_system_codes (keep = repro_code icd9_icd10);
         declare hash repro_cd (dataset: "temp.repro_system_codes (keep = repro_code icd9_icd10)");
         repro_cd.definekey("repro_code");
         repro_cd.definedata("repro_code", "icd9_icd10");
         repro_cd.definedone();

         *list of male diagnosis codes with malignancy;
         if 0 then set temp.male_diagn_malig_codes (keep = male_malig_code icd9_icd10);
         declare hash male_malig_cd (dataset: "temp.male_diagn_malig_codes (keep = male_malig_code icd9_icd10)");
         male_malig_cd.definekey("male_malig_code");
         male_malig_cd.definedata("male_malig_code", "icd9_icd10");
         male_malig_cd.definedone();

         *list of male diagnosis codes without malignancy;
         if 0 then set temp.male_diagn_no_malig_codes (keep = male_no_malig_code icd9_icd10);
         declare hash male_no_malig_cd (dataset: "temp.male_diagn_no_malig_codes (keep = male_no_malig_code icd9_icd10)");
         male_no_malig_cd.definekey("male_no_malig_code");
         male_no_malig_cd.definedata("male_no_malig_code", "icd9_icd10");
         male_no_malig_cd.definedone();

         *list of female diagnosis codes;
         if 0 then set temp.female_diagn_codes (keep = fem_diagn_code icd9_icd10);
         declare hash fem_diagn_cd (dataset: "temp.female_diagn_codes (keep = fem_diagn_code icd9_icd10)");
         fem_diagn_cd.definekey("fem_diagn_code");
         fem_diagn_cd.definedata("fem_diagn_code", "icd9_icd10");
         fem_diagn_cd.definedone();

         *list of codes describing revision or removal of axtraluminal device in stomach, percutaneuos endoscopic approach;
         if 0 then set temp.stomach_codes (keep = stomach_code icd9_icd10);
         declare hash stomach_cd (dataset: "temp.stomach_codes (keep = stomach_code icd9_icd10)");
         stomach_cd.definekey("stomach_code");
         stomach_cd.definedata("stomach_code", "icd9_icd10");
         stomach_cd.definedone();

         *list of codes describing infected bursa and other infections of the joints;
         if 0 then set temp.musculoskeletal_codes (keep = musc_code icd9_icd10);
         declare hash musc_cd (dataset: "temp.musculoskeletal_codes (keep = musc_code icd9_icd10)");
         musc_cd.definekey("musc_code");
         musc_cd.definedata("musc_code", "icd9_icd10");
         musc_cd.definedone();

         *list of codes describing conditions involving the cervical region;
         if 0 then set temp.skin_subtissue_codes (keep = skin_sub_code icd9_icd10);
         declare hash skin_sub_cd (dataset: "temp.skin_subtissue_codes (keep = skin_sub_code icd9_icd10)");
         skin_sub_cd.definekey("skin_sub_code");
         skin_sub_cd.definedata("skin_sub_code", "icd9_icd10");
         skin_sub_cd.definedone();

         *list of non-supplement transcatheter cardiac valve codes;
         if 0 then set temp.other_endovasc_valve_codes (keep = othr_endo_drg_cd othr_endo_code icd9_icd10);
         declare hash othr_endo_cd (dataset: "temp.other_endovasc_valve_codes (keep = othr_endo_drg_cd othr_endo_code icd9_icd10)");
         othr_endo_cd.definekey("othr_endo_drg_cd", "othr_endo_code");
         othr_endo_cd.definedata("othr_endo_drg_cd", "othr_endo_code", "icd9_icd10");
         othr_endo_cd.definedone();
         
         *list of non-supplement transcatheter cardiac valve codes for backward mapping 1;
         if 0 then set temp.other_endovasc_valve_codes_bm1 (keep = endo_bm1_code icd9_icd10);
         declare hash othr_endo_bm1 (dataset: "temp.other_endovasc_valve_codes_bm1 (keep = endo_bm1_code icd9_icd10)");
         othr_endo_bm1.definekey("endo_bm1_code");
         othr_endo_bm1.definedata("endo_bm1_code", "icd9_icd10");
         othr_endo_bm1.definedone();
         
         *list of non-supplement transcatheter cardiac valve codes for backward mapping 2;
         if 0 then set temp.other_endovasc_valve_codes_bm2 (keep = endo_bm2_code icd9_icd10);
         declare hash othr_endo_bm2 (dataset: "temp.other_endovasc_valve_codes_bm2 (keep = endo_bm2_code icd9_icd10)");
         othr_endo_bm2.definekey("endo_bm2_code");
         othr_endo_bm2.definedata("endo_bm2_code", "icd9_icd10");
         othr_endo_bm2.definedone();

         *list of scoliosis, secondary scoliosis and secondary kyphosis codes;
         if 0 then set temp.scoliosis_codes (keep = scol_code icd9_icd10);
         declare hash scol_cd (dataset: "temp.scoliosis_codes (keep = scol_code icd9_icd10)");
         scol_cd.definekey("scol_code");
         scol_cd.definedata("scol_code", "icd9_icd10");
         scol_cd.definedone();

         *list of cervical spinal fusion principal diagnosis codes;
         if 0 then set temp.cervical_spinal_fusion (keep = cerv_spin_code icd9_icd10);
         declare hash pd_cerv_spin_cd (dataset: "temp.cervical_spinal_fusion (where=(upcase(strip(cerv_spin_code_type))='PRINCIPAL DIAGNOSIS') keep = cerv_spin_code_type cerv_spin_code icd9_icd10)");
         pd_cerv_spin_cd.definekey("cerv_spin_code");
         pd_cerv_spin_cd.definedata("cerv_spin_code", "icd9_icd10");
         pd_cerv_spin_cd.definedone();

         *list of cervical spinal fusion secondary diagnosis codes;
         if 0 then set temp.cervical_spinal_fusion (keep = cerv_spin_code icd9_icd10);
         declare hash sd_cerv_spin_cd (dataset: "temp.cervical_spinal_fusion (where=(upcase(strip(cerv_spin_code_type))='SECONDARY DIAGNOSIS') keep = cerv_spin_code_type cerv_spin_code icd9_icd10)");
         sd_cerv_spin_cd.definekey("cerv_spin_code");
         sd_cerv_spin_cd.definedata("cerv_spin_code", "icd9_icd10");
         sd_cerv_spin_cd.definedone();

         *list of spinal fusion procedure codes;
         if 0 then set temp.spinal_fusion_proc (keep = spin_proc_code icd9_icd10);
         declare hash spin_proc_cd (dataset: "temp.spinal_fusion_proc (keep = spin_proc_code icd9_icd10)");
         spin_proc_cd.definekey("spin_proc_code");
         spin_proc_cd.definedata("spin_proc_code", "icd9_icd10");
         spin_proc_cd.definedone();

         *list of codes describing infected bursa and other infections of the joints;
         if 0 then set temp.knee_procedure_codes (keep = knee_drg_cd knee_code icd9_icd10);
         declare hash knee_cd (dataset: "temp.knee_procedure_codes (keep = knee_drg_cd knee_code icd9_icd10)");
         knee_cd.definekey("knee_drg_cd", "knee_code");
         knee_cd.definedata("knee_drg_cd", "knee_code", "icd9_icd10");
         knee_cd.definedone();

         *list of car t-cell therapies procedure codes outlined in FY2021 ipps rule;
         if 0 then set temp.car_t_codes (keep = car_t_code icd9_icd10);
         declare hash car_t_cd (dataset: "temp.car_t_codes (keep = car_t_code icd9_icd10)");
         car_t_cd.definekey("car_t_code");
         car_t_cd.definedata("car_t_code", "icd9_icd10");
         car_t_cd.definedone();
         
         *list of car t-cell therapies procedure codes outlined in FY2021 ipps rule for backward mapping;
         if 0 then set temp.car_t_codes_bm (keep = cart_bm_code icd9_icd10);
         declare hash car_t_bm (dataset: "temp.car_t_codes_bm (keep = cart_bm_code icd9_icd10)");
         car_t_bm.definekey("cart_bm_code");
         car_t_bm.definedata("cart_bm_code", "icd9_icd10");
         car_t_bm.definedone();

         *list of codes describing dilation of a carotid artery with an intraluminal device;
         if 0 then set temp.cartoid_artery_dilation_codes (keep = caro_dila_drg_cd caro_dila_code1 icd9_icd10);
         declare hash s_caro_dila_cd (dataset: "temp.cartoid_artery_dilation_codes (where=(upcase(icd9_icd10) = 'ICD-10') keep = caro_dila_drg_cd caro_dila_code1 icd9_icd10)");
         s_caro_dila_cd.definekey("caro_dila_drg_cd", "caro_dila_code1");
         s_caro_dila_cd.definedata("caro_dila_drg_cd", "caro_dila_code1", "icd9_icd10");
         s_caro_dila_cd.definedone();

         *list of code combinations describing dilation of a carotid artery with an intraluminal device;
         if 0 then set temp.cartoid_artery_dilation_codes (keep = caro_dila_drg_cd caro_dila_code1 caro_dila_code2 caro_dila_code3 caro_dila_code4 icd9_icd10);
         declare hash c_caro_dila_cd (dataset: "temp.cartoid_artery_dilation_codes (where=(upcase(icd9_icd10) = 'ICD-9') keep = caro_dila_drg_cd caro_dila_code1 caro_dila_code2 caro_dila_code3 caro_dila_code4 icd9_icd10)", multidata: "y");
         c_caro_dila_cd.definekey("caro_dila_drg_cd");
         c_caro_dila_cd.definedata("caro_dila_code1", "caro_dila_code2", "caro_dila_code3", "caro_dila_code4", "icd9_icd10");
         c_caro_dila_cd.definedone();

         *list of procedure codes related to head, neck, cranial and facial procedures;
         if 0 then set temp.head_neck_codes (keep = head_code icd9_icd10);
         declare hash p_head_cd (dataset: "temp.head_neck_codes (keep = head_code icd9_icd10)");
         p_head_cd.definekey("head_code");
         p_head_cd.definedata("head_code", "icd9_icd10");
         p_head_cd.definedone();
         
         *list of procedure codes related to MS-DRG 129 to be used for backward mapping from MS-DRGs 140, 141, and 142;
         if 0 then set temp.fy21_drg_129a_bm (keep = drg129a_code icd9_icd10);
         declare hash drg129a_cd (dataset: "temp.fy21_drg_129a_bm (keep = drg129a_code icd9_icd10)");
         drg129a_cd.definekey("drg129a_code");
         drg129a_cd.definedata("drg129a_code", "icd9_icd10");
         drg129a_cd.definedone();
         
         *list of procedure codes related to MS-DRG 129 to be used for backward mapping from MS-DRGs 143, 144, and 145;
         if 0 then set temp.fy21_drg_129b_bm (keep = drg129b_code icd9_icd10);
         declare hash drg129b_cd (dataset: "temp.fy21_drg_129b_bm (keep = drg129b_code icd9_icd10)");
         drg129b_cd.definekey("drg129b_code");
         drg129b_cd.definedata("drg129b_code", "icd9_icd10");
         drg129b_cd.definedone();
         
         *list of procedure codes related to MS-DRG 130 to be used for backward mapping from MS-DRGs 140, 141, and 142;
         if 0 then set temp.fy21_drg_130a_bm (keep = drg130a_code icd9_icd10);
         declare hash drg130a_cd (dataset: "temp.fy21_drg_130a_bm (keep = drg130a_code icd9_icd10)");
         drg130a_cd.definekey("drg130a_code");
         drg130a_cd.definedata("drg130a_code", "icd9_icd10");
         drg130a_cd.definedone();
         
         *list of procedure codes related to MS-DRG 130 to be used for Backwards Mapping from MS-DRGs 143, 144, and 145;
         if 0 then set temp.fy21_drg_130b_bm (keep = drg130b_code icd9_icd10);
         declare hash drg130b_cd (dataset: "temp.fy21_drg_130b_bm (keep = drg130b_code icd9_icd10)");
         drg130b_cd.definekey("drg130b_code");
         drg130b_cd.definedata("drg130b_code", "icd9_icd10");
         drg130b_cd.definedone();
         
         *list of procedure codes related to MS-DRG 131 to be used for backward mapping from MS-DRGs 140, 141, and 142;
         if 0 then set temp.fy21_drg_131a_bm (keep = drg131a_code icd9_icd10);
         declare hash drg131a_cd (dataset: "temp.fy21_drg_131a_bm (keep = drg131a_code icd9_icd10)");
         drg131a_cd.definekey("drg131a_code");
         drg131a_cd.definedata("drg131a_code", "icd9_icd10");
         drg131a_cd.definedone();

         *list of procedure codes related to MS-DRG 131 to be used for Backwards Mapping from MS-DRGs 143, 144, and 145;
         if 0 then set temp.fy21_drg_131b_bm (keep = drg131b_code icd9_icd10);
         declare hash drg131b_cd (dataset: "temp.fy21_drg_131b_bm (keep = drg131b_code icd9_icd10)");
         drg131b_cd.definekey("drg131b_code");
         drg131b_cd.definedata("drg131b_code", "icd9_icd10");
         drg131b_cd.definedone();
         
         *list of procedure codes related to MS-DRG 132 to be used for backward mapping from MS-DRGs 140, 141, and 142;
         if 0 then set temp.fy21_drg_132a_bm (keep = drg132a_code icd9_icd10);
         declare hash drg132a_cd (dataset: "temp.fy21_drg_132a_bm (keep = drg132a_code icd9_icd10)");
         drg132a_cd.definekey("drg132a_code");
         drg132a_cd.definedata("drg132a_code", "icd9_icd10");
         drg132a_cd.definedone();

         *list of procedure codes related to MS-DRG 132 to be used for Backwards Mapping from MS-DRGs 143, 144, and 145;
         if 0 then set temp.fy21_drg_132b_bm (keep = drg132b_code icd9_icd10);
         declare hash drg132b_cd (dataset: "temp.fy21_drg_132b_bm (keep = drg132b_code icd9_icd10)");
         drg132b_cd.definekey("drg132b_code");
         drg132b_cd.definedata("drg132b_code", "icd9_icd10");
         drg132b_cd.definedone();
         
         *list of procedure codes related to MS-DRG 133 to be used for backward mapping from MS-DRGs 140, 141, and 142;
         if 0 then set temp.fy21_drg_133a_bm (keep = drg133a_code icd9_icd10);
         declare hash drg133a_cd (dataset: "temp.fy21_drg_133a_bm (keep = drg133a_code icd9_icd10)");
         drg133a_cd.definekey("drg133a_code");
         drg133a_cd.definedata("drg133a_code", "icd9_icd10");
         drg133a_cd.definedone();

         *list of procedure codes related to MS-DRG 133 to be used for Backwards Mapping from MS-DRGs 143, 144, and 145;
         if 0 then set temp.fy21_drg_133b_bm (keep = drg133b_code icd9_icd10);
         declare hash drg133b_cd (dataset: "temp.fy21_drg_133b_bm (keep = drg133b_code icd9_icd10)");
         drg133b_cd.definekey("drg133b_code");
         drg133b_cd.definedata("drg133b_code", "icd9_icd10");
         drg133b_cd.definedone();
         
         *list of procedure codes related to MS-DRG 134 to be used for backward mapping from MS-DRGs 140, 141, and 142;
         if 0 then set temp.fy21_drg_134a_bm (keep = drg134a_code icd9_icd10);
         declare hash drg134a_cd (dataset: "temp.fy21_drg_134a_bm (keep = drg134a_code icd9_icd10)");
         drg134a_cd.definekey("drg134a_code");
         drg134a_cd.definedata("drg134a_code", "icd9_icd10");
         drg134a_cd.definedone();

         *list of procedure codes related to MS-DRG 134 to be used for Backwards Mapping from MS-DRGs 143, 144, and 145;
         if 0 then set temp.fy21_drg_134b_bm (keep = drg134b_code icd9_icd10);
         declare hash drg134b_cd (dataset: "temp.fy21_drg_134b_bm (keep = drg134b_code icd9_icd10)");
         drg134b_cd.definekey("drg134b_code");
         drg134b_cd.definedata("drg134b_code", "icd9_icd10");
         drg134b_cd.definedone();

         *list of diagnosis codes related to head, neck, cranial and facial procedures;
         if 0 then set temp.head_neck_diag_codes (keep = head_diag_code icd9_icd10);
         declare hash d_head_cd (dataset: "temp.head_neck_diag_codes (keep = head_diag_code icd9_icd10)");
         d_head_cd.definekey("head_diag_code");
         d_head_cd.definedata("head_diag_code", "icd9_icd10");
         d_head_cd.definedone();

         *list of procedure codes related to ear, nose, mouth and throat O.R. procedure;
         if 0 then set temp.ear_nose_mouth_codes (keep = ear_code icd9_icd10);
         declare hash p_ear_cd (dataset: "temp.ear_nose_mouth_codes (keep = ear_code icd9_icd10)");
         p_ear_cd.definekey("ear_code");
         p_ear_cd.definedata("ear_code", "icd9_icd10");
         p_ear_cd.definedone();

         *list of diagnosis codes related to ear, nose, mouth and throat O.R. procedure;
         if 0 then set temp.ear_nose_mouth_diag_codes (keep = ear_diag_code icd9_icd10);
         declare hash d_ear_cd (dataset: "temp.ear_nose_mouth_diag_codes (keep = ear_diag_code icd9_icd10)");
         d_ear_cd.definekey("ear_diag_code");
         d_ear_cd.definedata("ear_diag_code", "icd9_icd10");
         d_ear_cd.definedone();

         *list of left atrial appendage closure procedure codes;
         if 0 then set temp.laac_codes (keep = laac_code icd9_icd10);
         declare hash laac_cd (dataset: "temp.laac_codes (keep = laac_code icd9_icd10)");
         laac_cd.definekey("laac_code");
         laac_cd.definedata("laac_code", "icd9_icd10");
         laac_cd.definedone();

         *list of diagnosis and procedure codes that describe hip fractures and hip replacement procedures;
         if 0 then set temp.hip_fracture_codes (keep = hip_frac_code icd9_icd10);
         declare hash p_hip_frac_cd (dataset: "temp.hip_fracture_codes (where=(upcase(strip(hip_frac_code_type))='PROCEDURE CODE') keep = hip_frac_code_type hip_frac_code icd9_icd10)");
         p_hip_frac_cd.definekey("hip_frac_code");
         p_hip_frac_cd.definedata("hip_frac_code", "icd9_icd10");
         p_hip_frac_cd.definedone();

         *list of diagnosis and procedure codes that describe hip fractures and hip replacement procedures;
         if 0 then set temp.hip_fracture_codes (keep = hip_frac_code icd9_icd10);
         declare hash d_hip_frac_cd (dataset: "temp.hip_fracture_codes (where=(upcase(strip(hip_frac_code_type))='DIAGNOSIS CODE') keep = hip_frac_code_type hip_frac_code icd9_icd10)");
         d_hip_frac_cd.definekey("hip_frac_code");
         d_hip_frac_cd.definedata("hip_frac_code", "icd9_icd10");
         d_hip_frac_cd.definedone();
         
         *list of diagnosis and procedure codes that describe hip fractures and hip replacement procedures for backward mapping;
         if 0 then set temp.hip_fracture_codes_bm (keep = hip_fracbm_code icd9_icd10);
         declare hash p_hip_frac_bm (dataset: "temp.hip_fracture_codes_bm (where=(upcase(strip(hip_fracbm_code_type))='PROCEDURE CODE') keep = hip_fracbm_code_type hip_fracbm_code icd9_icd10)");
         p_hip_frac_bm.definekey("hip_fracbm_code");
         p_hip_frac_bm.definedata("hip_fracbm_code", "icd9_icd10");
         p_hip_frac_bm.definedone();

         *list of diagnosis and procedure codes that describe hip fractures and hip replacement procedures for backward mapping;
         if 0 then set temp.hip_fracture_codes_bm (keep = hip_fracbm_code icd9_icd10);
         declare hash d_hip_frac_bm (dataset: "temp.hip_fracture_codes_bm (where=(upcase(strip(hip_fracbm_code_type))='DIAGNOSIS CODE') keep = hip_fracbm_code_type hip_fracbm_code icd9_icd10)");
         d_hip_frac_bm.definekey("hip_fracbm_code");
         d_hip_frac_bm.definedata("hip_fracbm_code", "icd9_icd10");
         d_hip_frac_bm.definedone();

         *list of procedure codes that identify the performance of hemodialysis;
         if 0 then set temp.hemodialysis_codes (keep = hemo_code icd9_icd10);
         declare hash hemo_cd (dataset: "temp.hemodialysis_codes (keep = hemo_code icd9_icd10)");
         hemo_cd.definekey("hemo_code");
         hemo_cd.definedata("hemo_code", "icd9_icd10");
         hemo_cd.definedone();
         
         *list of procedure codes that identify the performance of hemodialysis for backward mapping;
         if 0 then set temp.hemodialysis_codes_bm (keep = hemo_bm_code icd9_icd10);
         declare hash hemo_bm (dataset: "temp.hemodialysis_codes_bm (keep = hemo_bm_code icd9_icd10)");
         hemo_bm.definekey("hemo_bm_code");
         hemo_bm.definedata("hemo_bm_code", "icd9_icd10");
         hemo_bm.definedone();

         *list of procedure codes that identify kidney transplant;
         if 0 then set temp.kidney_transplant_codes (keep = kid_trans_code icd9_icd10);
         declare hash kid_trans_cd (dataset: "temp.kidney_transplant_codes (keep = kid_trans_code icd9_icd10)");
         kid_trans_cd.definekey("kid_trans_code");
         kid_trans_cd.definedata("kid_trans_code", "icd9_icd10");
         kid_trans_cd.definedone();
         
         *list of procedure codes that identify kidney transplant for backward mapping;
         if 0 then set temp.kidney_transplant_codes_bm (keep = kid_transbm_code icd9_icd10);
         declare hash kid_trans_bm (dataset: "temp.kidney_transplant_codes_bm (keep = kid_transbm_code icd9_icd10)");
         kid_trans_bm.definekey("kid_transbm_code");
         kid_trans_bm.definedata("kid_transbm_code", "icd9_icd10");
         kid_trans_bm.definedone();

         *list of diagnosis codes describing mechanical complications of vascular dialysis catheters;
         if 0 then set temp.vascular_dialysis_codes (keep = vascular_code icd9_icd10);
         declare hash vascular_cd (dataset: "temp.vascular_dialysis_codes (keep = vascular_code icd9_icd10)");
         vascular_cd.definekey("vascular_code");
         vascular_cd.definedata("vascular_code", "icd9_icd10");
         vascular_cd.definedone();

         *list of non-operating room procedure codes related to MS-DRGs 673-675;
         if 0 then set temp.non_or_codes (keep = non_or_code icd9_icd10);
         declare hash non_or_cd (dataset: "temp.non_or_codes (keep = non_or_code icd9_icd10)");
         non_or_cd.definekey("non_or_code");
         non_or_cd.definedata("non_or_code", "icd9_icd10");
         non_or_cd.definedone();

         *list of procedure codes mapped to MS-DRGs 987 through 989;
         if 0 then set temp.peritoneal_cavity_codes (keep = periton_code icd9_icd10);
         declare hash periton_cd (dataset: "temp.peritoneal_cavity_codes (keep = periton_code icd9_icd10)");
         periton_cd.definekey("periton_code");
         periton_cd.definedata("periton_code", "icd9_icd10");
         periton_cd.definedone();

         *list of procedure codes describing excision of mediastinum;
         if 0 then set temp.mediastinum_excision_codes (keep = media_code icd9_icd10);
         declare hash media_cd (dataset: "temp.mediastinum_excision_codes (keep = media_code icd9_icd10)");
         media_cd.definekey("media_code");
         media_cd.definedata("media_code", "icd9_icd10");
         media_cd.definedone();
         
         *list of procedures codes describing excision of subcutaneous tissue from the chest, back, and abdomen;
         if 0 then set temp.excision_sub_tissue_codes (keep = sub_tiss_code icd9_icd10);
         declare hash sub_tiss_cd (dataset: "temp.excision_sub_tissue_codes (keep = sub_tiss_code icd9_icd10)");
         sub_tiss_cd.definekey("sub_tiss_code");
         sub_tiss_cd.definedata("sub_tiss_code", "icd9_icd10");
         sub_tiss_cd.definedone();

         *list of procedure codes describing laser interstitial thermal therapy for remapping from 023, 024, 025, 026, 027 to 040, 041, 042;
         if 0 then set temp.litt_codes_fm1 (keep = litt1_code icd9_icd10);
         declare hash litt1_cd (dataset: "temp.litt_codes_fm1 (keep = litt1_code icd9_icd10)");
         litt1_cd.definekey("litt1_code");
         litt1_cd.definedata("litt1_code", "icd9_icd10");
         litt1_cd.definedone();

         *list of procedure codes describing laser interstitial thermal therapy for remapping from 163, 164, 165 to 040, 041,  042;
         if 0 then set temp.litt_codes_fm2 (keep = litt2_code icd9_icd10);
         declare hash litt2_cd (dataset: "temp.litt_codes_fm2 (keep = litt2_code icd9_icd10)");
         litt2_cd.definekey("litt2_code");
         litt2_cd.definedata("litt2_code", "icd9_icd10");
         litt2_cd.definedone();

         *list of procedure codes describing laser interstitial thermal therapy for remapping from 981, 982, 983 to 987, 988, 989;
         if 0 then set temp.litt_codes_fm3 (keep = litt3_code icd9_icd10);
         declare hash litt3_cd (dataset: "temp.litt_codes_fm3 (keep = litt3_code icd9_icd10)");
         litt3_cd.definekey("litt3_code");
         litt3_cd.definedata("litt3_code", "icd9_icd10");
         litt3_cd.definedone();

         *list of procedure codes describing laser interstitial thermal therapy for remapping from 715, 716 to 987, 988, 989;
         if 0 then set temp.litt_codes_fm4 (keep = litt4_code icd9_icd10);
         declare hash litt4_cd (dataset: "temp.litt_codes_fm4 (keep = litt4_code icd9_icd10)");
         litt4_cd.definekey("litt4_code");
         litt4_cd.definedata("litt4_code", "icd9_icd10");
         litt4_cd.definedone();

         *list of procedures codes describing repair of the esophagus;
         if 0 then set temp.esophagus_repair_codes (keep = eso_repair_code icd9_icd10);
         declare hash eso_repair_cd (dataset: "temp.esophagus_repair_codes (keep = eso_repair_code icd9_icd10)");
         eso_repair_cd.definekey("eso_repair_code");
         eso_repair_cd.definedata("eso_repair_code", "icd9_icd10");
         eso_repair_cd.definedone();

         *list of procedure codes describing procedures performed on the cowpers gland in males;
         if 0 then set temp.cowpers_gland_codes (keep = cowpers_code icd9_icd10);
         declare hash cowpers_cd (dataset: "temp.cowpers_gland_codes (keep = cowpers_code icd9_icd10)");
         cowpers_cd.definekey("cowpers_code");
         cowpers_cd.definedata("cowpers_code", "icd9_icd10");
         cowpers_cd.definedone();

         *list of procedure codes describing laser interstitial thermal therapy for remapping to 166, 167, and 168;
         if 0 then set temp.litt_codes_fm5 (keep = litt5_code icd9_icd10);
         declare hash litt5_cd (dataset: "temp.litt_codes_fm5 (keep = litt5_code icd9_icd10)");
         litt5_cd.definekey("litt5_code");
         litt5_cd.definedata("litt5_code", "icd9_icd10");
         litt5_cd.definedone();

         *list of procedure codes describing laser interstitial thermal therapy for remapping to 356, 357, and 358;
         if 0 then set temp.litt_codes_fm6 (keep = litt6_code icd9_icd10);
         declare hash litt6_cd (dataset: "temp.litt_codes_fm6 (keep = litt6_code icd9_icd10)");
         litt6_cd.definekey("litt6_code");
         litt6_cd.definedata("litt6_code", "icd9_icd10");
         litt6_cd.definedone();

         *list of procedure codes describing laser interstitial thermal therapy for remapping to 423, 424, and 425;
         if 0 then set temp.litt_codes_fm7 (keep = litt7_code icd9_icd10);
         declare hash litt7_cd (dataset: "temp.litt_codes_fm7 (keep = litt7_code icd9_icd10)");
         litt7_cd.definekey("litt7_code");
         litt7_cd.definedata("litt7_code", "icd9_icd10");
         litt7_cd.definedone();

         *list of procedure codes describing laser interstitial thermal therapy for remapping to 628, 629, and 630;
         if 0 then set temp.litt_codes_fm8 (keep = litt8_code icd9_icd10);
         declare hash litt8_cd (dataset: "temp.litt_codes_fm8 (keep = litt8_code icd9_icd10)");
         litt8_cd.definekey("litt8_code");
         litt8_cd.definedata("litt8_code", "icd9_icd10");
         litt8_cd.definedone();

         *list of procedure code combinations describing removal and replacement of the right knee joint to 628, 629, 630;
         if 0 then set temp.right_knee_joint_codes_fm1 (keep = r_knee1_drg_cd r_knee1_code1 r_knee1_code2 icd9_icd10);
         declare hash r_knee1_cd (dataset: "temp.right_knee_joint_codes_fm1 (keep = r_knee1_drg_cd r_knee1_code1 r_knee1_code2 icd9_icd10)", multidata: "y");
         r_knee1_cd.definekey("r_knee1_drg_cd");
         r_knee1_cd.definedata("r_knee1_code1", "r_knee1_code2", "icd9_icd10");
         r_knee1_cd.definedone();

         *list of procedure codes describing laser interstitial thermal therapy for remapping to 584 and 585;
         if 0 then set temp.litt_codes_fm9 (keep = litt9_code icd9_icd10);
         declare hash litt9_cd (dataset: "temp.litt_codes_fm9 (keep = litt9_code icd9_icd10)");
         litt9_cd.definekey("litt9_code");
         litt9_cd.definedata("litt9_code", "icd9_icd10");
         litt9_cd.definedone();

         *list of procedure codes describing laser interstitial thermal therapy for remapping to 715, 716, 717, 718;
         if 0 then set temp.litt_codes_fm10 (keep = litt10_code icd9_icd10);
         declare hash litt10_cd (dataset: "temp.litt_codes_fm10 (keep = litt10_code icd9_icd10)");
         litt10_cd.definekey("litt10_code");
         litt10_cd.definedata("litt10_code", "icd9_icd10");
         litt10_cd.definedone();

         *list of procedure codes that describe repair of pulmonary or thoracic structures and codes that describe procedures performed on the sternum or ribs;
         if 0 then set temp.pulm_thor_ster_ribs_codes (keep = pulm_thor_code icd9_icd10);
         declare hash pulm_thor_cd (dataset: "temp.pulm_thor_ster_ribs_codes (keep = pulm_thor_code icd9_icd10)");
         pulm_thor_cd.definekey("pulm_thor_code");
         pulm_thor_cd.definedata("pulm_thor_code", "icd9_icd10");
         pulm_thor_cd.definedone();

         *list of procedure codes that describe insertion of heart assist device;
         if 0 then set temp.heart_device_codes (keep = h_device_code icd9_icd10);
         declare hash h_device_cd (dataset: "temp.heart_device_codes (keep = h_device_code icd9_icd10)");
         h_device_cd.definekey("h_device_code");
         h_device_cd.definedata("h_device_code", "icd9_icd10");
         h_device_cd.definedone();

         *list of procedure codes that describe performance of cardiac catheterization;
         if 0 then set temp.cardiac_cath_codes (keep = card_cath_code icd9_icd10);
         declare hash card_cath_cd (dataset: "temp.cardiac_cath_codes (keep = card_cath_code icd9_icd10)");
         card_cath_cd.definekey("card_cath_code");
         card_cath_cd.definedata("card_cath_code", "icd9_icd10");
         card_cath_cd.definedone();

         *list of diagnosis codes that describing viral cardiomyopathy;
         if 0 then set temp.viral_cardiomyopathy_codes (keep = viral_card_code icd9_icd10);
         declare hash viral_card_cd (dataset: "temp.viral_cardiomyopathy_codes (keep = viral_card_code icd9_icd10)");
         viral_card_cd.definekey("viral_card_code");
         viral_card_cd.definedata("viral_card_code", "icd9_icd10");
         viral_card_cd.definedone();

         *list of procedure code combinations describing removal and replacement of the right knee joint remapped to 461, 462, 466, 467, 468;
         if 0 then set temp.right_knee_joint_codes_fm2 (keep = r_knee2_drg_cd r_knee2_code1 r_knee2_code2 icd9_icd10);
         declare hash r_knee2_cd (dataset: "temp.right_knee_joint_codes_fm2 (keep = r_knee2_drg_cd r_knee2_code1 r_knee2_code2 icd9_icd10)", multidata: "y");
         r_knee2_cd.definekey("r_knee2_drg_cd");
         r_knee2_cd.definedata("r_knee2_code1", "r_knee2_code2", "icd9_icd10");
         r_knee2_cd.definedone();

         *list of procedure codes describing removal and replacement of the left knee joint, right/left hip joint, right/left ankle joint;
         if 0 then set temp.bilateral_mult_codes (keep = bl_mult_code icd9_icd10);
         declare hash bl_mult_cd (dataset: "temp.bilateral_mult_codes (keep = bl_mult_code icd9_icd10)");
         bl_mult_cd.definekey("bl_mult_code");
         bl_mult_cd.definedata("bl_mult_code", "icd9_icd10");
         bl_mult_cd.definedone();

         *list of procedure codes describing coronary artery bypass graft;
         if 0 then set temp.coronary_artery_byp_codes (keep = cor_alt_code icd9_icd10);
         declare hash cor_alt_cd (dataset: "temp.coronary_artery_byp_codes (keep = cor_alt_code icd9_icd10)");
         cor_alt_cd.definekey("cor_alt_code");
         cor_alt_cd.definedata("cor_alt_code", "icd9_icd10");
         cor_alt_cd.definedone();

         *list of procedure codes describing open surgical ablation;
         if 0 then set temp.surgical_ablation_codes (keep = surg_ab_code icd9_icd10);
         declare hash surg_ab_cd (dataset: "temp.surgical_ablation_codes (keep = surg_ab_code icd9_icd10)");
         surg_ab_cd.definekey("surg_ab_code");
         surg_ab_cd.definedata("surg_ab_code", "icd9_icd10");
         surg_ab_cd.definedone();
  
         *list of encounter dialysis diagnosis codes to be used for backwards mapping;
         if 0 then set temp.enc_dialysis_codes_bm (keep = enc_bm_code icd9_icd10);
         declare hash enc_bm_cd (dataset: "temp.enc_dialysis_codes_bm (keep = enc_bm_code icd9_icd10)");
         enc_bm_cd.definekey("enc_bm_code");
         enc_bm_cd.definedata("enc_bm_code", "icd9_icd10");
         enc_bm_cd.definedone();
         
         *list of sterilization procedure codes for backwards mapping ms-drgs 765 and 766;
         if 0 then set temp.sterilization_codes_bm1 (keep = ster_bm1_code icd9_icd10);
         declare hash ster_bm1_cd (dataset: "temp.sterilization_codes_bm1 (keep = ster_bm1_code icd9_icd10)");
         ster_bm1_cd.definekey("ster_bm1_code");
         ster_bm1_cd.definedata("ster_bm1_code", "icd9_icd10");
         ster_bm1_cd.definedone();
         
         *list of sterilization procedure codes or backwards mapping ms-drgs 767 and 774;
         if 0 then set temp.sterilization_codes_bm2 (keep = ster_bm2_code icd9_icd10);
         declare hash ster_bm2_cd (dataset: "temp.sterilization_codes_bm2 (keep = ster_bm2_code icd9_icd10)");
         ster_bm2_cd.definekey("ster_bm2_code");
         ster_bm2_cd.definedata("ster_bm2_code", "icd9_icd10");
         ster_bm2_cd.definedone();
         
         *list of neoplasm of the kidney diagnosis codes to be used for backwards mapping;
         if 0 then set temp.neoplasm_kidney_codes_bm (keep = neo_kidbm_code icd9_icd10);
         declare hash neo_kidbm_cd (dataset: "temp.neoplasm_kidney_codes_bm (keep = neo_kidbm_code icd9_icd10)");
         neo_kidbm_cd.definekey("neo_kidbm_code");
         neo_kidbm_cd.definedata("neo_kidbm_code", "icd9_icd10");
         neo_kidbm_cd.definedone();
         
         *list of neoplasm of genitourinary organs diagnosis codes to be used for backwards mapping;
         if 0 then set temp.neoplasm_gen_codes_bm (keep = neo_genbm_code icd9_icd10);
         declare hash neo_genbm_cd (dataset: "temp.neoplasm_gen_codes_bm (keep = neo_genbm_code icd9_icd10)");
         neo_genbm_cd.definekey("neo_genbm_code");
         neo_genbm_cd.definedata("neo_genbm_code", "icd9_icd10");
         neo_genbm_cd.definedone();
         
         *list of extraction of endometrium procedure codes to be used for backwards mapping;
         if 0 then set temp.extr_endo_codes_bm (keep = extr_endobm_code icd9_icd10);
         declare hash extr_endobm_cd (dataset: "temp.extr_endo_codes_bm (keep = extr_endobm_code icd9_icd10)");
         extr_endobm_cd.definekey("extr_endobm_code");
         extr_endobm_cd.definedata("extr_endobm_code", "icd9_icd10");
         extr_endobm_cd.definedone();
    
         *list of codes describing dilation of a carotid artery with an intraluminal device to be used for backwards mapping;
         if 0 then set temp.cartoid_artery_dilation_code_bm1 (keep = caro_dilabm1_code1 icd9_icd10);
         declare hash caro_dilabm1_cd (dataset: "temp.cartoid_artery_dilation_code_bm1 (where=(upcase(icd9_icd10) = 'ICD-10') keep = caro_dilabm1_code1 icd9_icd10)");
         caro_dilabm1_cd.definekey("caro_dilabm1_code1");
         caro_dilabm1_cd.definedata("caro_dilabm1_code1", "icd9_icd10");
         caro_dilabm1_cd.definedone();

         *list of codes describing dilation of a carotid artery with an intraluminal device to be used for backwards mapping;
         if 0 then set temp.cartoid_artery_dilation_code_bm2 (keep = caro_dilabm2_code1 icd9_icd10);
         declare hash caro_dilabm2_cd (dataset: "temp.cartoid_artery_dilation_code_bm2 (where=(upcase(icd9_icd10) = 'ICD-10') keep = caro_dilabm2_code1 icd9_icd10)");
         caro_dilabm2_cd.definekey("caro_dilabm2_code1");
         caro_dilabm2_cd.definedata("caro_dilabm2_code1", "icd9_icd10");
         caro_dilabm2_cd.definedone();
         
         *list of left atrial appendage closure (laac) procedure codes to be used for backwards mapping;
         if 0 then set temp.laac_codes_bm (keep = laac_bm_code icd9_icd10);
         declare hash laac_bm_cd (dataset: "temp.laac_codes_bm (keep = laac_bm_code icd9_icd10)");
         laac_bm_cd.definekey("laac_bm_code");
         laac_bm_cd.definedata("laac_bm_code", "icd9_icd10");
         laac_bm_cd.definedone();
         
         *list of diagnosis codes describing mechanical complications of vascular dialysis catheters to be used for backwards mapping;
         if 0 then set temp.vascular_dialysis_codes_bm (keep = vascular_bm_code icd9_icd10);
         declare hash vas_bm_cd (dataset: "temp.vascular_dialysis_codes_bm (keep = vascular_bm_code icd9_icd10)");
         vas_bm_cd.definekey("vascular_bm_code");
         vas_bm_cd.definedata("vascular_bm_code", "icd9_icd10");
         vas_bm_cd.definedone();
         
         *list of non-operating room procedure codes related to ms-drgs 673-675 to be used for backwards mapping;
         if 0 then set temp.non_or_codes_bm (keep = non_orbm_code icd9_icd10);
         declare hash non_orbm_cd (dataset: "temp.non_or_codes_bm (keep = non_orbm_code icd9_icd10)");
         non_orbm_cd.definekey("non_orbm_code");
         non_orbm_cd.definedata("non_orbm_code", "icd9_icd10");
         non_orbm_cd.definedone();
         
         *list of procedure codes mapped to ms-drgs 987 through 989 to be used for backwards mapping;
         if 0 then set temp.peritoneal_cavity_codes_bm (keep = periton_bm_code icd9_icd10);
         declare hash periton_bm_cd (dataset: "temp.peritoneal_cavity_codes_bm (keep = periton_bm_code icd9_icd10)");
         periton_bm_cd.definekey("periton_bm_code");
         periton_bm_cd.definedata("periton_bm_code", "icd9_icd10");
         periton_bm_cd.definedone();
         
         *list of procedure codes describing excision of mediastinum to be used for backwards mapping;
         if 0 then set temp.mediastinum_excision_bm (keep = media_bm_code icd9_icd10);
         declare hash media_bm_cd (dataset: "temp.mediastinum_excision_bm (keep = media_bm_code icd9_icd10)");
         media_bm_cd.definekey("media_bm_code");
         media_bm_cd.definedata("media_bm_code", "icd9_icd10");
         media_bm_cd.definedone();
         
         *list of procedures codes describing excision of subcutaneous tissue from the chest, back and abdomen to be used for backwards mapping;
         if 0 then set temp.excision_sub_tissue_bm (keep = sub_tissbm_code icd9_icd10);
         declare hash sub_tissbm_cd (dataset: "temp.excision_sub_tissue_bm (keep = sub_tissbm_code icd9_icd10)");
         sub_tissbm_cd.definekey("sub_tissbm_code");
         sub_tissbm_cd.definedata("sub_tissbm_code", "icd9_icd10");
         sub_tissbm_cd.definedone();
         
         *list of procedure codes describing laser interstitial thermal therapy for remapping from 023 024 025 026 027 to 040 041 042 to be used for backwards mapping;
         if 0 then set temp.litt_codes_bm1 (keep = litt1_bm_code icd9_icd10);
         declare hash litt1_bm_cd (dataset: "temp.litt_codes_bm1 (keep = litt1_bm_code icd9_icd10)");
         litt1_bm_cd.definekey("litt1_bm_code");
         litt1_bm_cd.definedata("litt1_bm_code", "icd9_icd10");
         litt1_bm_cd.definedone();
         
         *list of procedure codes describing laser interstitial thermal therapy for remapping from 163 164 165 to 040 041 042 to be used for backwards mapping;
         if 0 then set temp.litt_codes_bm2 (keep = litt2_bm_code icd9_icd10);
         declare hash litt2_bm_cd (dataset: "temp.litt_codes_bm2 (keep = litt2_bm_code icd9_icd10)");
         litt2_bm_cd.definekey("litt2_bm_code");
         litt2_bm_cd.definedata("litt2_bm_code", "icd9_icd10");
         litt2_bm_cd.definedone();
         
         *list of procedure codes describing laser interstitial thermal therapy for remapping from 981 982 983 to 987 988 989 to be used for backwards mapping;
         if 0 then set temp.litt_codes_bm3 (keep = litt3_bm_code icd9_icd10);
         declare hash litt3_bm_cd (dataset: "temp.litt_codes_bm3 (keep = litt3_bm_code icd9_icd10)");
         litt3_bm_cd.definekey("litt3_bm_code");
         litt3_bm_cd.definedata("litt3_bm_code", "icd9_icd10");
         litt3_bm_cd.definedone();
         
         *list of procedure codes describing laser interstitial thermal therapy for remapping from 715 716 to 987 988 989 to be used for backwards mapping;
         if 0 then set temp.litt_codes_bm4 (keep = litt4_bm_code icd9_icd10);
         declare hash litt4_bm_cd (dataset: "temp.litt_codes_bm4 (keep = litt4_bm_code icd9_icd10)");
         litt4_bm_cd.definekey("litt4_bm_code");
         litt4_bm_cd.definedata("litt4_bm_code", "icd9_icd10");
         litt4_bm_cd.definedone();
         
         *list of procedures codes describing repair of the esophagus to be used for backwards mapping;
         if 0 then set temp.esophagus_repair_codes_bm (keep = eso_repairbm_code icd9_icd10);
         declare hash eso_repairbm_cd (dataset: "temp.esophagus_repair_codes_bm (keep = eso_repairbm_code icd9_icd10)");
         eso_repairbm_cd.definekey("eso_repairbm_code");
         eso_repairbm_cd.definedata("eso_repairbm_code", "icd9_icd10");
         eso_repairbm_cd.definedone();
         
         *list of procedure codes describing procedures performed on the cowpers gland in males to be used for backwards mapping;
         if 0 then set temp.cowpers_gland_codes_bm (keep = cowpers_bm_code icd9_icd10);
         declare hash cowpers_bm_cd (dataset: "temp.cowpers_gland_codes_bm (keep = cowpers_bm_code icd9_icd10)");
         cowpers_bm_cd.definekey("cowpers_bm_code");
         cowpers_bm_cd.definedata("cowpers_bm_code", "icd9_icd10");
         cowpers_bm_cd.definedone();
        
         *list of procedure codes describing laser interstitial thermal therapy for remapping to 166 167 and 168 to be used for backwards mapping;
         if 0 then set temp.litt_codes_bm5 (keep = litt5_bm_code icd9_icd10);
         declare hash litt5_bm_cd (dataset: "temp.litt_codes_bm5 (keep = litt5_bm_code icd9_icd10)");
         litt5_bm_cd.definekey("litt5_bm_code");
         litt5_bm_cd.definedata("litt5_bm_code", "icd9_icd10");
         litt5_bm_cd.definedone();
         
         *list of procedure codes describing laser interstitial thermal therapy for remapping to 356 357 and 358 to be used for backwards mapping;
         if 0 then set temp.litt_codes_bm6 (keep = litt6_bm_code icd9_icd10);
         declare hash litt6_bm_cd (dataset: "temp.litt_codes_bm6 (keep = litt6_bm_code icd9_icd10)");
         litt6_bm_cd.definekey("litt6_bm_code");
         litt6_bm_cd.definedata("litt6_bm_code", "icd9_icd10");
         litt6_bm_cd.definedone();
         
         *list of procedure codes describing laser interstitial thermal therapy for remapping to 423 424 and 425 to be used for backwards mapping;
         if 0 then set temp.litt_codes_bm7 (keep = litt7_bm_code icd9_icd10);
         declare hash litt7_bm_cd (dataset: "temp.litt_codes_bm7 (keep = litt7_bm_code icd9_icd10)");
         litt7_bm_cd.definekey("litt7_bm_code");
         litt7_bm_cd.definedata("litt7_bm_code", "icd9_icd10");
         litt7_bm_cd.definedone();
         
         *list of procedure codes describing laser interstitial thermal therapy for remapping to 628 629 and 630 to be used for backwards mapping;
         if 0 then set temp.litt_codes_bm8 (keep = litt8_bm_code icd9_icd10);
         declare hash litt8_bm_cd (dataset: "temp.litt_codes_bm8 (keep = litt8_bm_code icd9_icd10)");
         litt8_bm_cd.definekey("litt8_bm_code");
         litt8_bm_cd.definedata("litt8_bm_code", "icd9_icd10");
         litt8_bm_cd.definedone();
    
         *list of procedure code combinations describing removal and replacement of the right knee joint to 628 629 630 to be used for backwards mapping;
         if 0 then set temp.right_knee_joint_codes_bm1 (keep = r_kneebm1_code1 r_kneebm1_code2 icd9_icd10);
         declare hash r_kneebm1_cd (dataset: "temp.right_knee_joint_codes_bm1 (keep = r_kneebm1_code1 r_kneebm1_code2 icd9_icd10)", multidata: "y");
         r_kneebm1_cd.definekey("r_kneebm1_code1");
         r_kneebm1_cd.definedata("r_kneebm1_code2", "icd9_icd10");
         r_kneebm1_cd.definedone();
         
         *list of procedure codes describing laser interstitial thermal therapy for remapping to 584 and 585 to be used for backwards mapping;
         if 0 then set temp.litt_codes_bm9 (keep = litt9_bm_code icd9_icd10);
         declare hash litt9_bm_cd (dataset: "temp.litt_codes_bm9 (keep = litt9_bm_code icd9_icd10)");
         litt9_bm_cd.definekey("litt9_bm_code");
         litt9_bm_cd.definedata("litt9_bm_code", "icd9_icd10");
         litt9_bm_cd.definedone();
         
         *list of procedure codes describing laser interstitial thermal therapy for remapping to 715 716 717 718 to be used for backwards mapping;
         if 0 then set temp.litt_codes_bm10 (keep = litt10_bm_code icd9_icd10);
         declare hash litt10_bm_cd (dataset: "temp.litt_codes_bm10 (keep = litt10_bm_code icd9_icd10)");
         litt10_bm_cd.definekey("litt10_bm_code");
         litt10_bm_cd.definedata("litt10_bm_code", "icd9_icd10");
         litt10_bm_cd.definedone();
         
         *list of procedure codes that describe repair of pulmonary or thoracic structures and codes that describe procedures performed on the sternum or ribs to be used for backwards mapping;
         if 0 then set temp.pulm_thor_ster_ribs_bm (keep = pulm_thorbm_code icd9_icd10);
         declare hash pulm_thorbm_cd (dataset: "temp.pulm_thor_ster_ribs_bm (keep = pulm_thorbm_code icd9_icd10)");
         pulm_thorbm_cd.definekey("pulm_thorbm_code");
         pulm_thorbm_cd.definedata("pulm_thorbm_code", "icd9_icd10");
         pulm_thorbm_cd.definedone();
         
         *list of procedure codes that describe insertion of heart assist device to be used for backwards mapping;
         if 0 then set temp.heart_device_codes_bm (keep = h_devicebm_code icd9_icd10);
         declare hash h_devicebm_cd (dataset: "temp.heart_device_codes_bm (keep = h_devicebm_code icd9_icd10)");
         h_devicebm_cd.definekey("h_devicebm_code");
         h_devicebm_cd.definedata("h_devicebm_code", "icd9_icd10");
         h_devicebm_cd.definedone();
         
         *list of procedure codes that describe performance of cardiac catheterization to be used for backwards mapping;
         if 0 then set temp.cardiac_cath_codes_bm (keep = card_cathbm_code icd9_icd10);
         declare hash card_cathbm_cd (dataset: "temp.cardiac_cath_codes_bm (keep = card_cathbm_code icd9_icd10)");
         card_cathbm_cd.definekey("card_cathbm_code");
         card_cathbm_cd.definedata("card_cathbm_code", "icd9_icd10");
         card_cathbm_cd.definedone();
         
         *list of diagnosis codes that describing viral cardiomyopathy to be used for backwards mapping;
         if 0 then set temp.viral_cardiomyopathy_bm (keep = viral_cardbm_code icd9_icd10);
         declare hash viral_cardbm_cd (dataset: "temp.viral_cardiomyopathy_bm (keep = viral_cardbm_code icd9_icd10)");
         viral_cardbm_cd.definekey("viral_cardbm_code");
         viral_cardbm_cd.definedata("viral_cardbm_code", "icd9_icd10");
         viral_cardbm_cd.definedone();
         
         *list of procedure code combinations describing removal and replacement of the right knee joint remapped to 461, 462, 466, 467, 468 to be used for backwards mapping;
         if 0 then set temp.right_knee_joint_codes_bm2 (keep = r_kneebm2_code1 r_kneebm2_code2 icd9_icd10);
         declare hash r_kneebm2_cd (dataset: "temp.right_knee_joint_codes_bm2 (keep = r_kneebm2_code1 r_kneebm2_code2 icd9_icd10)", multidata: "y");
         r_kneebm2_cd.definekey("r_kneebm2_code1");
         r_kneebm2_cd.definedata("r_kneebm2_code2", "icd9_icd10");
         r_kneebm2_cd.definedone();
         
         *list of procedure codes describing removal and replacement of the left knee joint, right/left hip joint, right/left ankle joint to be used for backwards mapping;
         if 0 then set temp.bilateral_mult_codes_bm (keep = bl_multbm_code icd9_icd10);
         declare hash bl_multbm_cd (dataset: "temp.bilateral_mult_codes_bm (keep = bl_multbm_code icd9_icd10)");
         bl_multbm_cd.definekey("bl_multbm_code");
         bl_multbm_cd.definedata("bl_multbm_code", "icd9_icd10");
         bl_multbm_cd.definedone();
         
         *list of procedure codes describing coronary artery bypass graft to be used for backwards mapping;
         if 0 then set temp.coronary_artery_byp_bm (keep = cor_altbm_code icd9_icd10);
         declare hash cor_altbm_cd (dataset: "temp.coronary_artery_byp_bm (keep = cor_altbm_code icd9_icd10)");
         cor_altbm_cd.definekey("cor_altbm_code");
         cor_altbm_cd.definedata("cor_altbm_code", "icd9_icd10");
         cor_altbm_cd.definedone();
         
         *list of procedure codes describing open surgical ablation to be used for backwards mapping;
         if 0 then set temp.surgical_ablation_codes_bm (keep = surg_abbm_code icd9_icd10);
         declare hash surg_abbm_cd (dataset: "temp.surgical_ablation_codes_bm (keep = surg_abbm_code icd9_icd10)");
         surg_abbm_cd.definekey("surg_abbm_code");
         surg_abbm_cd.definedata("surg_abbm_code", "icd9_icd10");
         surg_abbm_cd.definedone();
         
         *list of major device implant procedure code combinations to backwards map 040-042 to 023-024;
         if 0 then set temp.major_device_codes_bm (keep = mj_devicebm_code1 mj_devicebm_code2 icd9_icd10);
         declare hash mj_devicebm_cd (dataset: "temp.major_device_codes_bm (keep = mj_devicebm_code1 mj_devicebm_code2 icd9_icd10)", multidata: "y");
         mj_devicebm_cd.definekey("mj_devicebm_code1");
         mj_devicebm_cd.definedata("mj_devicebm_code2", "icd9_icd10");
         mj_devicebm_cd.definedone();
         
         *list of diagnosis codes describing acute complex cns for backwards mapping 040-042 to 023-024;
         if 0 then set temp.acute_complex_codes_bm (keep = acute_compbm_code icd9_icd10);
         declare hash acute_compbm_cd (dataset: "temp.acute_complex_codes_bm (keep = acute_compbm_code icd9_icd10)");
         acute_compbm_cd.definekey("acute_compbm_code");
         acute_compbm_cd.definedata("acute_compbm_code", "icd9_icd10");
         acute_compbm_cd.definedone();
         
         *list of diagnosis codes describing vaginal delivery to be used to backwards mapping to 767 and 774;
         if 0 then set temp.vaginal_delivery_bm (keep = vgnl_bm_code icd9_icd10);
         declare hash vgnl_bm_cd (dataset: "temp.vaginal_delivery_bm (keep = vgnl_bm_code icd9_icd10)");
         vgnl_bm_cd.definekey("vgnl_bm_code");
         vgnl_bm_cd.definedata("vgnl_bm_code", "icd9_icd10");
         vgnl_bm_cd.definedone();
         
         *list of complicating diagnosis codes to be used for backwards mapping to 774;
         if 0 then set temp.complication_codes_bm (keep = complicat_bm_code icd9_icd10);
         declare hash complicat_bm_cd (dataset: "temp.complication_codes_bm (keep = complicat_bm_code icd9_icd10)");
         complicat_bm_cd.definekey("complicat_bm_code");
         complicat_bm_cd.definedata("complicat_bm_code", "icd9_icd10");
         complicat_bm_cd.definedone();
         
         *list of diagnosis codes in mdc 03 to be used for backwards mapping from 981-983;
         if 0 then set temp.mdc_3_codes_bm (keep = mdc_3bm_code icd9_icd10);
         declare hash mdc_3bm_cd (dataset: "temp.mdc_3_codes_bm (keep = mdc_3bm_code icd9_icd10)");
         mdc_3bm_cd.definekey("mdc_3bm_code");
         mdc_3bm_cd.definedata("mdc_3bm_code", "icd9_icd10");
         mdc_3bm_cd.definedone();
         
         *list of procedure codes describing percutaneous arterial emblzation to be used for backwards mapping to 981-983;
         if 0 then set temp.perc_embol_codes_bm (keep = perc_embolbm_code icd9_icd10);
         declare hash perc_embolbm_cd (dataset: "temp.perc_embol_codes_bm (keep = perc_embolbm_code icd9_icd10)");
         perc_embolbm_cd.definekey("perc_embolbm_code");
         perc_embolbm_cd.definedata("perc_embolbm_code", "icd9_icd10");
         perc_embolbm_cd.definedone();

         *list of diagnosis codes describing acute respiratory distress syndrome;
         if 0 then set temp.acute_resp_synd_code (keep = resp_synd_code icd9_icd10);
         declare hash resp_synd_cd (dataset: "temp.acute_resp_synd_code (keep = resp_synd_code icd9_icd10)");
         resp_synd_cd.definekey("resp_synd_code");
         resp_synd_cd.definedata("resp_synd_code", "icd9_icd10");
         resp_synd_cd.definedone();
         
          *list of diagnosis codes describing acute respiratory distress syndrome to be used for backwards mapping;
         if 0 then set temp.acute_resp_synd_code_bm (keep = resp_syndbm_code icd9_icd10);
         declare hash resp_syndbm_cd (dataset: "temp.acute_resp_synd_code_bm (keep = resp_syndbm_code icd9_icd10)");
         resp_syndbm_cd.definekey("resp_syndbm_code");
         resp_syndbm_cd.definedata("resp_syndbm_code", "icd9_icd10");
         resp_syndbm_cd.definedone();

         *list of procedure codes describing cardiac mapping;
         if 0 then set temp.cardiac_mapping_code (keep = cardiac_map_code icd9_icd10);
         declare hash cardiac_map_cd (dataset: "temp.cardiac_mapping_code (keep = cardiac_map_code icd9_icd10)");
         cardiac_map_cd.definekey("cardiac_map_code");
         cardiac_map_cd.definedata("cardiac_map_code", "icd9_icd10");
         cardiac_map_cd.definedone();  

         *list of diagnosis codes describing cardiac mapping to be used for backwards mapping; 
         if 0 then set temp.cardiac_mapping_code_bm (keep = cardiac_mapbm_code icd9_icd10);
         declare hash cardiac_mapbm_cd (dataset: "temp.cardiac_mapping_code_bm (keep = cardiac_mapbm_code icd9_icd10)");
         cardiac_mapbm_cd.definekey("cardiac_mapbm_code");
         cardiac_mapbm_cd.definedata("cardiac_mapbm_code", "icd9_icd10");
         cardiac_mapbm_cd.definedone();  
         
         *list of diagnosis codes describing drug elute stent code to be used for backwards mapping; 
         if 0 then set temp.drug_elute_stent_code_bm (keep =  dgel_stent_code icd9_icd10);
         declare hash delst_bm_cd (dataset: "temp.drug_elute_stent_code_bm (keep =  dgel_stent_code icd9_icd10)");
         delst_bm_cd.definekey("dgel_stent_code");
         delst_bm_cd.definedata("dgel_stent_code", "icd9_icd10");
         delst_bm_cd.definedone();
         
         *list of diagnosis codes stents 4 arteries to be used for backwards mapping; 
         if 0 then set temp.art_stents_4plus_bm (keep = artst_4plus_code icd9_icd10 artst_4plus_code_type artst_4plus_total_artstent);
         declare hash as4p_bm_cd (dataset: "temp.art_stents_4plus_bm (keep = artst_4plus_code icd9_icd10 artst_4plus_total_artstent)");
         as4p_bm_cd.definekey("artst_4plus_code");
         as4p_bm_cd.definedata("artst_4plus_code", "icd9_icd10","artst_4plus_total_artstent");
         as4p_bm_cd.definedone();
         
         *list of procedure codes nondrug elut_stents to be used for backward mapping; 
         if 0 then set temp.nondrug_elut_stent_code_bm (keep =  ndg_elst_code icd9_icd10);
         declare hash dgel_bm_cd (dataset: "temp.nondrug_elut_stent_code_bm (keep = ndg_elst_code icd9_icd10)");
         dgel_bm_cd.definekey("ndg_elst_code");
         dgel_bm_cd.definedata("ndg_elst_code", "icd9_icd10");
         dgel_bm_cd.definedone();
         
         *list of diagnosis codes describing extremely low birth weight newborn and extreme immaturity of newborn;
         if 0 then set temp.extremely_lbw_imm_codes (keep = lbw_imm_code icd9_icd10);
         declare hash lbw_imm_cd (dataset: "temp.extremely_lbw_imm_codes (keep = lbw_imm_code icd9_icd10)");
         lbw_imm_cd.definekey("lbw_imm_code");
         lbw_imm_cd.definedata("lbw_imm_code", "icd9_icd10");
         lbw_imm_cd.definedone(); 
         
         *list of diagnosis codes describing extremely low birth weight newborn and extreme immaturity of newborn used for backward mapping;
         if 0 then set temp.extremely_lbw_imm_codes_bm (keep = lbw_immbm_code icd9_icd10);
         declare hash lbw_immbm_cd (dataset: "temp.extremely_lbw_imm_codes_bm (keep = lbw_immbm_code icd9_icd10)");
         lbw_immbm_cd.definekey("lbw_immbm_code");
         lbw_immbm_cd.definedata("lbw_immbm_code", "icd9_icd10");
         lbw_immbm_cd.definedone(); 
         
         *list of diagnosis codes describing newborn major diagnosis for backward mapping;
         if 0 then set temp.newborn_maj_prob_diag_bm (keep = icd9_icd10 nb_mjpb_code);
         declare hash nbmjpb_bm_cd (dataset: "temp.newborn_maj_prob_diag_bm (keep = icd9_icd10 nb_mjpb_code)");
         nbmjpb_bm_cd.definekey("nb_mjpb_code");
         nbmjpb_bm_cd.definedata("nb_mjpb_code", "icd9_icd10");
         nbmjpb_bm_cd.definedone(); 

         *list of diagnosis codes describing extreme immaturity of newborn;
         if 0 then set temp.extreme_immaturity_code (keep = extreme_imm_code icd9_icd10);
         declare hash extreme_imm_cd (dataset: "temp.extreme_immaturity_code (keep = extreme_imm_code icd9_icd10)");
         extreme_imm_cd.definekey("extreme_imm_code");
         extreme_imm_cd.definedata("extreme_imm_code", "icd9_icd10");
         extreme_imm_cd.definedone();    
         
         *list of diagnosis codes describing extreme immaturity of newborn used for backward mapping;
         if 0 then set temp.extreme_immaturity_code_bm (keep = extreme_immbm_code icd9_icd10);
         declare hash ext_imm_bm_cd (dataset: "temp.extreme_immaturity_code_bm (keep = extreme_immbm_code icd9_icd10)");
         ext_imm_bm_cd.definekey("extreme_immbm_code");
         ext_imm_bm_cd.definedata("extreme_immbm_code", "icd9_icd10");
         ext_imm_bm_cd.definedone(); 
         
         *list of procedure codes describing supplemental mitral valve;
         if 0 then set temp.supplem_mitral_valve_code (keep = supp_mit_valve_code icd9_icd10);
         declare hash supp_mit_valve_cd (dataset: "temp.supplem_mitral_valve_code (keep = supp_mit_valve_code icd9_icd10)");
         supp_mit_valve_cd.definekey("supp_mit_valve_code");
         supp_mit_valve_cd.definedata("supp_mit_valve_code", "icd9_icd10");
         supp_mit_valve_cd.definedone(); 
         
         *list of procedure codes describing supplemental mitral valve;
         if 0 then set temp.supplem_mitral_valve_code_bm (keep = supp_mit_valvebm_code icd9_icd10);
         declare hash supp_mit_valvebm_cd (dataset: "temp.supplem_mitral_valve_code_bm (keep = supp_mit_valvebm_code icd9_icd10)");
         supp_mit_valvebm_cd.definekey("supp_mit_valvebm_code");
         supp_mit_valvebm_cd.definedata("supp_mit_valvebm_code", "icd9_icd10");
         supp_mit_valvebm_cd.definedone(); 

         *list of diagnosis codes in MDC 07 (Diseases and disorders of the hepatobiliary system and pancreas);
         if 0 then set temp.mdc07_codes (keep = mdc07_code icd9_icd10);
         declare hash mdc07_cd (dataset: "temp.mdc07_codes (keep = mdc07_code icd9_icd10)");
         mdc07_cd.definekey("mdc07_code");
         mdc07_cd.definedata("mdc07_code", "icd9_icd10");
         mdc07_cd.definedone(); 

         *list of diagnosis codes in MDC 07 (Diseases and disorders of the hepatobiliary system and pancreas) used for backward mapping;
         if 0 then set temp.mdc07_codes_bm (keep = mdc07_bm_code icd9_icd10);
         declare hash mdc07_bm_cd (dataset: "temp.mdc07_codes_bm (keep = mdc07_bm_code icd9_icd10)");
         mdc07_bm_cd.definekey("mdc07_bm_code");
         mdc07_bm_cd.definedata("mdc07_bm_code", "icd9_icd10");
         mdc07_bm_cd.definedone(); 

         *list of procedure codes describing occlusion and restrictions of veins with intraluminal devices via a percutaneous approach;
         if 0 then set temp.occ_restr_vein_code (keep = occ_restr_code icd9_icd10);
         declare hash occ_restr_cd (dataset: "temp.occ_restr_vein_code (keep = occ_restr_code icd9_icd10)");
         occ_restr_cd.definekey("occ_restr_code");
         occ_restr_cd.definedata("occ_restr_code", "icd9_icd10");
         occ_restr_cd.definedone(); 
         
         *list of procedure codes describing occlusion and restrictions of veins with intraluminal devices via a percutaneous approach used for backward mapping;
         if 0 then set temp.occ_restr_vein_code_bm (keep = occ_restrbm_code icd9_icd10);
         declare hash occ_restrbm_cd (dataset: "temp.occ_restr_vein_code_bm (keep = occ_restrbm_code icd9_icd10)");
         occ_restrbm_cd.definekey("occ_restrbm_code");
         occ_restrbm_cd.definedata("occ_restrbm_code", "icd9_icd10");
         occ_restrbm_cd.definedone(); 

         *list of procedure codes describing the common bile duct exploration (CDE);
         if 0 then set temp.cde_code (keep = cde_code icd9_icd10);
         declare hash cde_cd (dataset: "temp.cde_code (keep = cde_code icd9_icd10)");
         cde_cd.definekey("cde_code");
         cde_cd.definedata("cde_code", "icd9_icd10");
         cde_cd.definedone(); 

         *list of procedure codes describing the common bile duct exploration (CDE) used for backward mapping;
         if 0 then set temp.cde_code_bm (keep = cde_bm_code icd9_icd10);
         declare hash cde_bm_cd (dataset: "temp.cde_code_bm (keep = cde_bm_code icd9_icd10)");
         cde_bm_cd.definekey("cde_bm_code");
         cde_bm_cd.definedata("cde_bm_code", "icd9_icd10");
         cde_bm_cd.definedone(); 
         
         *list of diagnosis codes describing liveborn infants according to place of delivery;
         if 0 then set temp.liveborn_infant_codes (keep = liveborn_infant_code icd9_icd10);
         declare hash liveborn_infant_cd (dataset: "temp.liveborn_infant_codes (keep = liveborn_infant_code icd9_icd10)");
         liveborn_infant_cd.definekey("liveborn_infant_code");
         liveborn_infant_cd.definedata("liveborn_infant_code", "icd9_icd10");
         liveborn_infant_cd.definedone(); 

         *list of diagnosis codes describing liveborn infants according to place of delivery used for backward mapping;
         if 0 then set temp.liveborn_infant_codes_bm (keep = liveborn_infantbm_code icd9_icd10);
         declare hash liveborn_infantbm_cd (dataset: "temp.liveborn_infant_codes_bm (keep = liveborn_infantbm_code icd9_icd10)");
         liveborn_infantbm_cd.definekey("liveborn_infantbm_code");
         liveborn_infantbm_cd.definedata("liveborn_infantbm_code", "icd9_icd10");
         liveborn_infantbm_cd.definedone(); 

         *list of procedure codes describing exposure to infectious disease;
         if 0 then set temp.infectious_disease_codes (keep = inf_disease_code icd9_icd10);
         declare hash inf_disease_cd (dataset: "temp.infectious_disease_codes (keep = inf_disease_code icd9_icd10)");
         inf_disease_cd.definekey("inf_disease_code");
         inf_disease_cd.definedata("inf_disease_code", "icd9_icd10");
         inf_disease_cd.definedone(); 
         
         *list of procedure codes describing exposure to infectious disease used for backward mapping;
         if 0 then set temp.infectious_disease_codes_bm (keep = inf_diseasebm_code icd9_icd10);
         declare hash inf_diseasebm_cd (dataset: "temp.infectious_disease_codes_bm (keep = inf_diseasebm_code icd9_icd10)");
         inf_diseasebm_cd.definekey("inf_diseasebm_code");
         inf_diseasebm_cd.definedata("inf_diseasebm_code", "icd9_icd10");
         inf_diseasebm_cd.definedone(); 
         
         *list of procedure codes describing percutaneous cardiovascular procedures with intraluminal device ;
         if 0 then set temp.fy24_intralumi_device (keep = fy24_intlumidev_code icd9_icd10);
         declare hash fy24_ild_cd (dataset: "temp.fy24_intralumi_device (keep = fy24_intlumidev_code icd9_icd10)");
         fy24_ild_cd.definekey("fy24_intlumidev_code");
         fy24_ild_cd.definedata("fy24_intlumidev_code", "icd9_icd10");
         fy24_ild_cd.definedone(); 
         
         *list of procedure codes describing coronary intravascular lithotripsy;
         if 0 then set temp.fy24_coronary_ivl (keep = fy24_coronary_ivl_code icd9_icd10);
         declare hash fy24_crn_cd (dataset: "temp.fy24_coronary_ivl (keep = fy24_coronary_ivl_code icd9_icd10)");
         fy24_crn_cd.definekey("fy24_coronary_ivl_code");
         fy24_crn_cd.definedata("fy24_coronary_ivl_code", "icd9_icd10");
         fy24_crn_cd.definedone(); 
         
         *list of procedure codes describing percutaneous cardiovascular procedures with 4+ arteries and intraluminal devices;
         if 0 then set temp.fy24_artery_intralumi_4plus (keep = fy24_artintralu4p_code icd9_icd10 fy24_artintlu_numart fy24_artintlu_numstn fy24_artintlu_totcnt);
         declare hash fy24_ild4_cd (dataset: "temp.fy24_artery_intralumi_4plus (keep = fy24_artintralu4p_code icd9_icd10 fy24_artintlu_numart fy24_artintlu_numstn fy24_artintlu_totcnt)");
         fy24_ild4_cd.definekey("fy24_artintralu4p_code");
         fy24_ild4_cd.definedata("fy24_artintralu4p_code", "icd9_icd10", "fy24_artintlu_numart", "fy24_artintlu_numstn", "fy24_artintlu_totcnt");
         fy24_ild4_cd.definedone(); 
         
         *list of procedure codes describing cardiac defibrillator implant ;
         if 0 then set temp.fy24_cardiac_defib_imp (keep =  fy24_car_defibimp_code1  fy24_car_defibimp_code2 icd9_icd10);
         declare hash fy24_crddef_cd (dataset: "temp.fy24_cardiac_defib_imp (keep =  fy24_car_defibimp_code1  fy24_car_defibimp_code2 icd9_icd10)", multidata: "y");
         fy24_crddef_cd.definekey("fy24_car_defibimp_code1");
         fy24_crddef_cd.definedata("fy24_car_defibimp_code1", "fy24_car_defibimp_code2", "icd9_icd10");
         fy24_crddef_cd.definedone(); 
         
         *list of procedure codes describing cardiac catheterization ;
         if 0 then set temp.fy24_cardiac_catheter (keep =  fy24_carcath_code  icd9_icd10);
         declare hash fy24_carcath_cd (dataset: "temp.fy24_cardiac_catheter (keep =  fy24_carcath_code  icd9_icd10)");
         fy24_carcath_cd.definekey("fy24_carcath_code");
         fy24_carcath_cd.definedata("fy24_carcath_code", "icd9_icd10");
         fy24_carcath_cd.definedone(); 
         
         *list of procedure codes describing ultrasound accelerated and other thrombolysis ;
         if 0 then set temp.fy24_ultra_accel_thrombo (keep =  fy24_utth_code  icd9_icd10);
         declare hash fy24_ulthr_cd (dataset: "temp.fy24_ultra_accel_thrombo (keep =  fy24_utth_code  icd9_icd10)");
         fy24_ulthr_cd.definekey("fy24_utth_code");
         fy24_ulthr_cd.definedata("fy24_utth_code", "icd9_icd10");
         fy24_ulthr_cd.definedone(); 
         
         *list of procedure codes describing aortic valve repair/replacement;
         if 0 then set temp.fy24_aortic_valve (keep =  fy24_artval_code  icd9_icd10);
         declare hash fy24_artvl_cd (dataset: "temp.fy24_aortic_valve (keep =  fy24_artval_code  icd9_icd10)");
         fy24_artvl_cd.definekey("fy24_artval_code");
         fy24_artvl_cd.definedata("fy24_artval_code", "icd9_icd10");
         fy24_artvl_cd.definedone(); 
         
         *list of procedure codes describing mitral valve repair/replacement;
         if 0 then set temp.fy24_mitral_valve (keep =  fy24_mitvsl_code  icd9_icd10);
         declare hash fy24_mitvl_cd (dataset: "temp.fy24_mitral_valve (keep =  fy24_mitvsl_code  icd9_icd10)");
         fy24_mitvl_cd.definekey("fy24_mitvsl_code");
         fy24_mitvl_cd.definedata("fy24_mitvsl_code", "icd9_icd10");
         fy24_mitvl_cd.definedone(); 
         
         *list of procedure codes describing other concomitant;
         if 0 then set temp.fy24_other_concomitant (keep =  fy24_othcon_code  icd9_icd10);
         declare hash fy24_oth_com_cd (dataset: "temp.fy24_other_concomitant (keep =  fy24_othcon_code  icd9_icd10)");
         fy24_oth_com_cd.definekey("fy24_othcon_code");
         fy24_oth_com_cd.definedata("fy24_othcon_code", "icd9_icd10");
         fy24_oth_com_cd.definedone(); 
         
         *list of diagnosis codes for pulmonary embolism;
         if 0 then set temp.fy24_pulmonary_embolism (keep =  fy24_pulemb_code  icd9_icd10);
         declare hash fy24_pul_emb_diag (dataset: "temp.fy24_pulmonary_embolism (keep =  fy24_pulemb_code  icd9_icd10)");
         fy24_pul_emb_diag.definekey("fy24_pulemb_code");
         fy24_pul_emb_diag.definedata("fy24_pulemb_code", "icd9_icd10");
         fy24_pul_emb_diag.definedone(); 
         
         *list of diagnosis codes for ultrasound accelerated and other thrombolysis;
         if 0 then set temp.fy24_ultra_accel_thrombo_pe (keep =  fy24_ulacth_code  icd9_icd10);
         declare hash fy24_ultthb_cd (dataset: "temp.fy24_ultra_accel_thrombo_pe (keep =  fy24_ulacth_code  icd9_icd10)");
         fy24_ultthb_cd.definekey("fy24_ulacth_code");
         fy24_ultthb_cd.definedata("fy24_ulacth_code", "icd9_icd10");
         fy24_ultthb_cd.definedone(); 
         
         *list of diagnosis codes for appendectomy;
         if 0 then set temp.fy24_appendectomy (keep =  fy24_append_code  icd9_icd10);
         declare hash fy24_appendectomy (dataset: "temp.fy24_appendectomy (keep =  fy24_append_code  icd9_icd10)");
         fy24_appendectomy.definekey("fy24_append_code");
         fy24_appendectomy.definedata("fy24_append_code", "icd9_icd10");
         fy24_appendectomy.definedone(); 
         
         *list of diagnosis codes for central retinal artery occlusion (CRAO) and branch retinal artery occlusion (BRAO);
         if 0 then set temp.fy24_crao_brao (keep =  fy24_crbro_code  icd9_icd10);
         declare hash fy24_crb_cd (dataset: "temp.fy24_crao_brao (keep =  fy24_crbro_code  icd9_icd10)");
         fy24_crb_cd.definekey("fy24_crbro_code");
         fy24_crb_cd.definedata("fy24_crbro_code", "icd9_icd10");
         fy24_crb_cd.definedone(); 
         
         *list of procedure codes for thrombolytic agent, including non-operating room procedures;
         if 0 then set temp.fy24_thrombo_agent (keep =  fy24_thagt_code  icd9_icd10);
         declare hash fy24_thbag_cd (dataset: "temp.fy24_thrombo_agent (keep =  fy24_thagt_code  icd9_icd10)");
         fy24_thbag_cd.definekey("fy24_thagt_code");
         fy24_thbag_cd.definedata("fy24_thagt_code", "icd9_icd10");
         fy24_thbag_cd.definedone(); 
         
         *principal diagnosis codes for MSDRGs 177 178 and 179;         
         if 0 then set temp.fy24_DRGs_177_179 (keep =  fy24_D177179_code  icd9_icd10);
         declare hash fy24_DRG177_179_cd (dataset: "temp.fy24_DRGs_177_179 (keep =  fy24_D177179_code  icd9_icd10)");
         fy24_DRG177_179_cd.definekey("fy24_D177179_code");
         fy24_DRG177_179_cd.definedata("fy24_D177179_code", "icd9_icd10");
         fy24_DRG177_179_cd.definedone(); 
         
         *list of diagnosis codes for respiratory infections and inflammations;
         if 0 then set temp.fy24_resp_infect_inflam (keep =  fy24_reinflm_code  icd9_icd10);
         declare hash fy24_resp_inf_cd (dataset: "temp.fy24_resp_infect_inflam (keep =  fy24_reinflm_code  icd9_icd10)");
         fy24_resp_inf_cd.definekey("fy24_reinflm_code");
         fy24_resp_inf_cd.definedata("fy24_reinflm_code", "icd9_icd10");
         fy24_resp_inf_cd.definedone(); 
         
         *list of diagnosis codes for respiratory infections and inflammations;
         if 0 then set temp.fy24_implant_heart_assist (keep =  fy24_imhtast_code  icd9_icd10);
         declare hash fy24_imp_hrt_cd (dataset: "temp.fy24_implant_heart_assist (keep =  fy24_imhtast_code  icd9_icd10)");
         fy24_imp_hrt_cd.definekey("fy24_imhtast_code");
         fy24_imp_hrt_cd.definedata("fy24_imhtast_code", "icd9_icd10");
         fy24_imp_hrt_cd.definedone(); 
         
         *list of diagnosis codes for other kidney and urinary tract procedures;
         if 0 then set temp.fy24_kidney_ut (keep =  fy24_kd_ut_code  icd9_icd10);
         declare hash fy24_kd_ut_cd (dataset: "temp.fy24_kidney_ut (keep =  fy24_kd_ut_code  icd9_icd10)");
         fy24_kd_ut_cd.definekey("fy24_kd_ut_code");
         fy24_kd_ut_cd.definedata("fy24_kd_ut_code", "icd9_icd10");
         fy24_kd_ut_cd.definedone(); 
         
         *list of procedure codes for vesicointestinal fistula;
         if 0 then set temp.fy24_vesicointestinal_fistula (keep =  fy24_vsfist_code  icd9_icd10);
         declare hash fy24_ves_fist_cd (dataset: "temp.fy24_vesicointestinal_fistula (keep =  fy24_vsfist_code  icd9_icd10)");
         fy24_ves_fist_cd.definekey("fy24_vsfist_code");
         fy24_ves_fist_cd.definedata("fy24_vsfist_code", "icd9_icd10");
         fy24_ves_fist_cd.definedone(); 
         
         *list of procedure codes for open excision of muscle;
         if 0 then set temp.fy24_open_excision_musc (keep =  fy24_opexc_code  icd9_icd10);
         declare hash fy24_opexc_cd (dataset: "temp.fy24_open_excision_musc (keep =  fy24_opexc_code  icd9_icd10)");
         fy24_opexc_cd.definekey("fy24_opexc_code");
         fy24_opexc_cd.definedata("fy24_opexc_code", "icd9_icd10");
         fy24_opexc_cd.definedone(); 
                  
         *list of principal diagnosis code for gangrene;
         if 0 then set temp.fy24_gangrene (keep =  fy24_gang_code  icd9_icd10);
         declare hash fy24_gangrene_cd (dataset: "temp.fy24_gangrene (keep =  fy24_gang_code  icd9_icd10)");
         fy24_gangrene_cd.definekey("fy24_gang_code");
         fy24_gangrene_cd.definedata("fy24_gang_code", "icd9_icd10");
         fy24_gangrene_cd.definedone(); 
         
         *list of principal diagnosis code for endoscopic dilation of ureters with an intraluminal device;
         if 0 then set temp.fy24_endoscopic_dilation (keep =  fy24_enddil_code  icd9_icd10);
         declare hash fy24_end_dil_cd (dataset: "temp.fy24_endoscopic_dilation (keep =  fy24_enddil_code  icd9_icd10)");
         fy24_end_dil_cd.definekey("fy24_enddil_code");
         fy24_end_dil_cd.definedata("fy24_enddil_code", "icd9_icd10");
         fy24_end_dil_cd.definedone(); 
         
         *list of principal diagnosis code for principal diagnosis code for hypertensive heart and chronic kidney disease;
         if 0 then set temp.fy24_hyper_heart_chron_kidn (keep =  fy24_hhck_code  icd9_icd10);
         declare hash fy24_hykid_cd (dataset: "temp.fy24_hyper_heart_chron_kidn (keep =  fy24_hhck_code  icd9_icd10)");
         fy24_hykid_cd.definekey("fy24_hhck_code");
         fy24_hykid_cd.definedata("fy24_hhck_code", "icd9_icd10");
         fy24_hykid_cd.definedone(); 
         
         *list of procedure codes for other skin, subcutaneous tissue and breast procedures;
         if 0 then set temp.fy24_skin_subcut_breast (keep =  fy24_skssbrt_code  icd9_icd10);
         declare hash fy24_skbreast_cd (dataset: "temp.fy24_skin_subcut_breast (keep =  fy24_skssbrt_code  icd9_icd10)");
         fy24_skbreast_cd.definekey("fy24_skssbrt_code");
         fy24_skbreast_cd.definedata("fy24_skssbrt_code", "icd9_icd10");
         fy24_skbreast_cd.definedone(); 
         
         *list of principal diagnosis codes for mdc 09;
         if 0 then set temp.fy24_mdc_09 (keep = fy24_mdc_09_code  icd9_icd10);
         declare hash fy24_mdc_09_cd (dataset: "temp.fy24_mdc_09 (keep =  fy24_mdc_09_code  icd9_icd10)");
         fy24_mdc_09_cd.definekey("fy24_mdc_09_code");
         fy24_mdc_09_cd.definedata("fy24_mdc_09_code", "icd9_icd10");
         fy24_mdc_09_cd.definedone(); 
         
         *list of Procedure codes for splenic artery;
         if 0 then set temp.fy24_occl_splenic_artery (keep = fy24_osart_code  icd9_icd10);
         declare hash fy24_occl_splart_cd (dataset: "temp.fy24_occl_splenic_artery (keep =  fy24_osart_code  icd9_icd10)");
         fy24_occl_splart_cd.definekey("fy24_osart_code");
         fy24_occl_splart_cd.definedata("fy24_osart_code", "icd9_icd10");
         fy24_occl_splart_cd.definedone();
         
         *list of Procedure codes for major laceration of spleen, initial encounter;
         if 0 then set temp.fy24_maj_lac_spleen_initial (keep =  fy24_mlspln_code  icd9_icd10);
         declare hash fy24_oc_sp_cd (dataset: "temp.fy24_maj_lac_spleen_initial (keep =  fy24_mlspln_code  icd9_icd10)");
         fy24_oc_sp_cd.definekey("fy24_mlspln_code");
         fy24_oc_sp_cd.definedata("fy24_mlspln_code", "icd9_icd10");
         fy24_oc_sp_cd.definedone();                            
         
         *list of Procedure codes for drug eluting stent bm code;
         if 0 then set temp.fy24_drug_eluting_stent_bm (keep =  fy24_drug_estbm_code icd9_icd10);
         declare hash fy24_des_bm(dataset: "temp.fy24_drug_eluting_stent_bm (keep = fy24_drug_estbm_code  icd9_icd10)");
         fy24_des_bm.definekey("fy24_drug_estbm_code");
         fy24_des_bm.definedata("fy24_drug_estbm_code", "icd9_icd10");
         fy24_des_bm.definedone();                            

         
         *list of Procedure codes for percutaneous cardiovascular procedures with 4+ arteries and intraluminal devices;
         if 0 then set temp.fy24_artery_intraluminal_4pl_bm (keep =  fy24_ailmnl_4plbm_code icd9_icd10);
         declare hash fy24_i4pl_bm(dataset: "temp.fy24_artery_intraluminal_4pl_bm (keep = fy24_ailmnl_4plbm_code icd9_icd10)");
         fy24_i4pl_bm.definekey("fy24_ailmnl_4plbm_code");
         fy24_i4pl_bm.definedata("fy24_ailmnl_4plbm_code", "icd9_icd10");
         fy24_i4pl_bm.definedone();     
 
         *list of principal diagnosis codes for AMI/HF/Shock;
         if 0 then set temp.fy24_ami_hf_shock_bm (keep =  fy24_amihf_shkbm_code  icd9_icd10);
         declare hash fy24_amihfs_bm_pd(dataset: "temp.fy24_ami_hf_shock_bm (where = (upcase(strip(fy24_amihf_shkbm_code_type)) = 'PRINCIPAL DIAGNOSIS CODE') keep = fy24_amihf_shkbm_code fy24_amihf_shkbm_code_type icd9_icd10)");
         fy24_amihfs_bm_pd.definekey("fy24_amihf_shkbm_code");
         fy24_amihfs_bm_pd.definedata("fy24_amihf_shkbm_code", "icd9_icd10");
         fy24_amihfs_bm_pd.definedone();     

         *list of secondary diagnosis codes for AMI/HF/Shock;
         if 0 then set temp.fy24_ami_hf_shock_bm (keep =  fy24_amihf_shkbm_code  icd9_icd10);
         declare hash fy24_amihfs_bm_sd(dataset: "temp.fy24_ami_hf_shock_bm (where = (upcase(strip(fy24_amihf_shkbm_code_type)) = 'SECONDARY DIAGNOSIS CODE') keep = fy24_amihf_shkbm_code fy24_amihf_shkbm_code_type icd9_icd10)");
         fy24_amihfs_bm_sd.definekey("fy24_amihf_shkbm_code");
         fy24_amihfs_bm_sd.definedata("fy24_amihf_shkbm_code", "icd9_icd10");
         fy24_amihfs_bm_sd.definedone();     

         *list of non-operating procedure codes for cardiac catheterization;
         if 0 then set temp.fy24_cardiac_catheter_277_bm (keep =  fy24_ccath277bm_code  icd9_icd10);
         declare hash fy24_cc277_bm(dataset: "temp.fy24_cardiac_catheter_277_bm (keep = fy24_ccath277bm_code icd9_icd10)");
         fy24_cc277_bm.definekey("fy24_ccath277bm_code");
         fy24_cc277_bm.definedata("fy24_ccath277bm_code", "icd9_icd10");
         fy24_cc277_bm.definedone();   

         *list of procedure codes for ultrasound accelerated and other thrombolysis;
         if 0 then set temp.fy24_ultra_accel_thrombo_bm  (keep = fy24_ua_tbobm_code  icd9_icd10);
         declare hash fy24_uat_bm(dataset: "temp.fy24_ultra_accel_thrombo_bm  (keep = fy24_ua_tbobm_code icd9_icd10)");
         fy24_uat_bm.definekey("fy24_ua_tbobm_code");
         fy24_uat_bm.definedata("fy24_ua_tbobm_code", "icd9_icd10");
         fy24_uat_bm.definedone();     

         *list of non-operating procedure codes for cardiac catheterization;
         if 0 then set temp.fy24_cardiac_catheter_212_bm (keep =  fy24_ccath212bm_code icd9_icd10);
         declare hash fy24_cc212_bm(dataset: "temp.fy24_cardiac_catheter_212_bm (keep = fy24_ccath212bm_code icd9_icd10)");
         fy24_cc212_bm.definekey("fy24_ccath212bm_code");
         fy24_cc212_bm.definedata("fy24_ccath212bm_code", "icd9_icd10");
         fy24_cc212_bm.definedone();   

         *list of principal diagnosis codes for complicated appendectomy;
         if 0 then set temp.fy24_append_complicated_bm  (keep = fy24_acompbm_code  icd9_icd10);
         declare hash fy24_acom_bm(dataset: "temp.fy24_append_complicated_bm (keep = fy24_acompbm_code icd9_icd10)");
         fy24_acom_bm.definekey("fy24_acompbm_code");
         fy24_acom_bm.definedata("fy24_acompbm_code", "icd9_icd10");
         fy24_acom_bm.definedone();     

         *list of Procedure codes for ;
         if 0 then set temp.fy24_crao_brao_bm  (keep = fy24_craobraobm_code icd9_icd10);
         declare hash fy24_cbrao_bm(dataset: "temp.fy24_crao_brao_bm  (keep = fy24_craobraobm_code icd9_icd10)");
         fy24_cbrao_bm.definekey("fy24_craobraobm_code");
         fy24_cbrao_bm.definedata("fy24_craobraobm_code", "icd9_icd10");
         fy24_cbrao_bm.definedone();   

         *list of principal diagnosis codes for central retinal artery occlusion (CRAO) and branch retinal artery occlusion (BRAO);
         if 0 then set temp.fy24_resp_infect_inflam_bm  (keep =  fy24_rifct_infbm_code  icd9_icd10);
         declare hash fy24_rinf_bm(dataset: "temp.fy24_resp_infect_inflam_bm (keep = fy24_rifct_infbm_code icd9_icd10)");
         fy24_rinf_bm.definekey("fy24_rifct_infbm_code");
         fy24_rinf_bm.definedata("fy24_rifct_infbm_code", "icd9_icd10");
         fy24_rinf_bm.definedone();  

         *list of operating room procedure code for implant of heart assist system;
         if 0 then set temp.fy24_implant_heart_assist_bm (keep = fy24_ihrtastbm_code  icd9_icd10);
         declare hash fy24_imha_bm(dataset: "temp.fy24_implant_heart_assist_bm (keep = fy24_ihrtastbm_code icd9_icd10)");
         fy24_imha_bm.definekey("fy24_ihrtastbm_code");
         fy24_imha_bm.definedata("fy24_ihrtastbm_code", "icd9_icd10");
         fy24_imha_bm.definedone();  

         *list of procedure code for other kidney and urinary tract procedures;
         if 0 then set temp.fy24_kidney_ut_bm (keep = fy24_kidney_utbm_code  icd9_icd10);
         declare hash fy24_kidut_bm(dataset: "temp.fy24_kidney_ut_bm (keep = fy24_kidney_utbm_code icd9_icd10)");
         fy24_kidut_bm.definekey("fy24_kidney_utbm_code");
         fy24_kidut_bm.definedata("fy24_kidney_utbm_code", "icd9_icd10");
         fy24_kidut_bm.definedone();   

         *list of principal diagnosis code for vesicointestinal fistula;
         if 0 then set temp.fy24_vesicointestin_fistula_bm (keep = fy24_vfistbm_code  icd9_icd10);
         declare hash fy24_vesif_bm(dataset: "temp.fy24_vesicointestin_fistula_bm (keep = fy24_vfistbm_code icd9_icd10)");
         fy24_vesif_bm.definekey("fy24_vfistbm_code");
         fy24_vesif_bm.definedata("fy24_vfistbm_code", "icd9_icd10");
         fy24_vesif_bm.definedone();  

         *list of procedure code for open excision of muscle;
         if 0 then set temp.fy24_open_excision_musc_bm (keep = fy24_oexc_muscbm_code  icd9_icd10);
         declare hash fy24_openem_bm(dataset: "temp.fy24_open_excision_musc_bm (keep = fy24_oexc_muscbm_code  icd9_icd10)");
         fy24_openem_bm.definekey("fy24_oexc_muscbm_code");
         fy24_openem_bm.definedata("fy24_oexc_muscbm_code", "icd9_icd10");
         fy24_openem_bm.definedone();  

         *list of principal diagnosis code for gangrene;
         if 0 then set temp.fy24_gangrene_bm (keep = fy24_gang_bm_code  icd9_icd10);
         declare hash fy24_gang_bm(dataset: "temp.fy24_gangrene_bm (keep = fy24_gang_bm_code icd9_icd10)");
         fy24_gang_bm.definekey("fy24_gang_bm_code");
         fy24_gang_bm.definedata("fy24_gang_bm_code", "icd9_icd10");
         fy24_gang_bm.definedone();   

         *List of Procedure codes for ;
         if 0 then set temp.fy24_endoscopic_dilation_bm (keep = fy24_endo_dilbm_code  icd9_icd10);
         declare hash fy24_endod_bm(dataset: "temp.fy24_endoscopic_dilation_bm (keep = fy24_endo_dilbm_code icd9_icd10)");
         fy24_endod_bm.definekey("fy24_endo_dilbm_code");
         fy24_endod_bm.definedata("fy24_endo_dilbm_code", "icd9_icd10");
         fy24_endod_bm.definedone();  

         *list of procedure codes for endoscopic dilation of ureters with an intraluminal device;
         if 0 then set temp.fy24_hyper_heart_chron_kidn_bm (keep = fy24_hh_ckidnbm_code  icd9_icd10);
         declare hash fy24_hhck_bm(dataset: "temp.fy24_hyper_heart_chron_kidn_bm (keep = fy24_hh_ckidnbm_code icd9_icd10)");
         fy24_hhck_bm.definekey("fy24_hh_ckidnbm_code ");
         fy24_hhck_bm.definedata("fy24_hh_ckidnbm_code ", "icd9_icd10");
         fy24_hhck_bm.definedone();  

         *list of procedure codes for other skin, subcutaneous tissue and breast procedures;
         if 0 then set temp.fy24_skin_subcut_breast_bm (keep = fy24_ss_brstbm_code  icd9_icd10);
         declare hash fy24_ssbr_bm(dataset: " temp.fy24_skin_subcut_breast_bm (keep = fy24_ss_brstbm_code icd9_icd10)");
         fy24_ssbr_bm.definekey("fy24_ss_brstbm_code");
         fy24_ssbr_bm.definedata("fy24_ss_brstbm_code", "icd9_icd10");
         fy24_ssbr_bm.definedone();  
         
         *list of principal diagnosis codes for mdc 10;
         if 0 then set temp.fy24_mdc_09_bm (keep = fy24_mdc_09bm_code  icd9_icd10);
         declare hash fy24_mdc09_bm(dataset: "temp.fy24_mdc_09_bm (keep = fy24_mdc_09bm_code  icd9_icd10)");
         fy24_mdc09_bm.definekey("fy24_mdc_09bm_code");
         fy24_mdc09_bm.definedata("fy24_mdc_09bm_code", "icd9_icd10");
         fy24_mdc09_bm.definedone();  
 
         *list of procedure codes for occlusion of the splenic artery;
         if 0 then set temp.fy24_occl_splenic_artery_bm (keep = fy24_ospln_artbm_code  icd9_icd10);
         declare hash fy24_ocspa_bm(dataset: "temp.fy24_occl_splenic_artery_bm  (keep = fy24_ospln_artbm_code icd9_icd10)");
         fy24_ocspa_bm.definekey("fy24_ospln_artbm_code");
         fy24_ocspa_bm.definedata("fy24_ospln_artbm_code", "icd9_icd10");
         fy24_ocspa_bm.definedone();  

         *list of principal diagnosis code for major laceration of spleen, initial encounter;
         if 0 then set temp.fy24_maj_lac_spleen_initial_bm (keep = fy24_mlspln_intbm_code icd9_icd10);
         declare hash fy24_mlacs_bm(dataset: "temp.fy24_maj_lac_spleen_initial_bm (keep = fy24_mlspln_intbm_code icd9_icd10)");
         fy24_mlacs_bm.definekey("fy24_mlspln_intbm_code");
         fy24_mlacs_bm.definedata("fy24_mlspln_intbm_code", "icd9_icd10");
         fy24_mlacs_bm.definedone();  

         *list of MDCs;
         if 0 then set geo.ipps_drg_weights_&update_factor_fy. (keep = drg mdc rename = (drg = drg_&update_factor_fy.));
         declare hash drg_mdc (dataset: "geo.ipps_drg_weights_&update_factor_fy. (keep = drg mdc rename = (drg = drg_&update_factor_fy.))");
         drg_mdc.definekey("drg_&update_factor_fy.");
         drg_mdc.definedata("mdc");
         drg_mdc.definedone(); 

         *list of DRG weights;
         %do year = &baseline_start_year. %to &update_factor_fy.;
            if 0 then set geo.ipps_drg_weights_&year. (keep = drg weight rename = (drg = drg_&year. weight = weights_&year.));
            declare hash drg_wgt&year. (dataset: "geo.ipps_drg_weights_&year. (keep = drg weight rename = (drg = drg_&year. weight = weights_&year.))");
            drg_wgt&year..definekey("drg_&year.");
            drg_wgt&year..definedata("weights_&year.");
            drg_wgt&year..definedone();
         %end;

      end;
      call missing(of _all_);

      set temp.cleaned_ip_stays (in = in_clean_ip);

      *initialize values;
      %init_match_flags();
      forwrd_remap_drg_flag = 0;
      backwrd_remap_drg_flag = 0;
      call missing(%do year = &baseline_start_year. %to &update_factor_fy.; drg_&year. %if &year. ^= &update_factor_fy. %then ,; %end;);      
      
      *map the DRGs across years;
      *condition A: if the DRG can be potentially remapped;
      if (remap_drg.find(key: drg_cd) = 0) then do;
         
         *condition B: if the DRG can be potentially remapped, loop thru all FYs and mapping rules;
         rc_remap_drg = 0;
         do while (rc_remap_drg = 0);

            *re-initialize;
            %init_match_flags();

            if (lowcase(mapping_type) = "forward") then do; 

               *if no diagnosis code or procedure code checking needs to be done;
               if %do r = 1 %to &nrequire_types.; (lowcase(require_&&require_types&r.._check) ^= "y") %if &r. ^= &nrequire_types. %then and; %end; then do;
                  %do year = &baseline_start_year. %to %eval(&update_factor_fy.-1);
                     if (year(input(date_of_remap, date9.)) = &year.) and (dschrgdt < input(date_of_remap, date9.)) and missing(drg_%eval(&year. + 1)) then do;
                        forwrd_remap_drg_flag = 1;
                        drg_%eval(&year. + 1) = new_drg_cd;
                     end;
                     %if &year. ^= %eval(&update_factor_fy.-1) %then else;
                  %end;
               end;
               
               *condition C: if diagnosis code or procedure code checking needs to be done;
               else do;

                  *count the number of requirements that need to be met;
                  *NOTE: special circumstance when dealing with DRG 490. count the below requirements as being equal to 1 overall requirement rather than 3 separate individual ones;
                  if (lowcase(require_neuro_check) = "y") and (lowcase(require_device_check) = "y") and (lowcase(require_cc_excl_check) = "y") and (lowcase(require_mcc_check) = "y") then do;
                     forwrd_num_y_need = 1;
                     special_case_flag = 1;
                  end;
                  else do;
                     if ((lowcase(require_mcc_check) = "y") and (lowcase(require_cc_check) = "y")) or (lowcase(require_mcc_check) = "y") or (lowcase(require_cc_check) = "y") then forwrd_num_y_need = forwrd_num_y_need + 1;
                     %do r = 1 %to &nrequire_types.;
                        %if "&&require_types&r.." ^= "cc" and "&&require_types&r.." ^= "mcc" %then %do;
                           if (lowcase(require_&&require_types&r.._check) = "y") then forwrd_num_y_need = forwrd_num_y_need + 1;
                        %end;
                     %end;
                  end;

                  *if procedure code checking needs to be done;
                  if (lowcase(require_prcdrcd_check) = "y") then do;
   
                     *check the procedure code array;
                     if (icdcpt.find(key: drg_cd, key: date_of_remap) = 0) then do;
                        rc_icdcpt = 0;
                        do while (rc_icdcpt = 0);
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (prcdrcd&b. = icdcpt_code) then prcdrcd_match = 1;
                              %if &a. ^= &diag_proc_length. %then else;
                           %end;
                           rc_icdcpt = icdcpt.find_next();
                        end;
                     end;

                     if (prcdrcd_match = 1) then forwrd_num_y_have = forwrd_num_y_have + 1;
   
                  end;

                  *if neuro code checking needs to be done;
                  if (lowcase(require_neuro_check) = "y") then do;
   
                     if(neuro.find(key: drg_cd) = 0) then do;
                        rc_neuro = 0;
                        do while (rc_neuro = 0);
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (prcdrcd&b. = neuro_code) then do;
                                 if (lowcase(required) = "y") then required_neuro_match = 1;
                                 else if (lowcase(required) = "n") then additional_neuro_match = 1;
                              end;
                              %if &a. ^= &diag_proc_length. %then else;
                           %end;
                           rc_neuro = neuro.find_next();
                        end;
                     end;

                     if (required_neuro_match = 1) and (additional_neuro_match = 1) then forwrd_num_y_have = forwrd_num_y_have + 1;
   
                  end;

                  *if device code checking needs to be done;
                  if (lowcase(require_device_check) = "y") then do;
   
                     if (device.find(key: drg_cd) = 0) then do;
                        rc_device = 0;
                        do while (rc_device = 0);
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (prcdrcd&b. = device_code) then device_match = 1;
                              %if &a. ^= &diag_proc_length. %then else;
                           %end;
                           rc_device = device.find_next();
                        end;
                     end;

                     if (device_match = 1) then forwrd_num_y_have = forwrd_num_y_have + 1;
   
                  end;
                  
                  *if CC exclusion and CC/MCC checking needs to be done;                  
                  *if CC exclusion and CC/MCC checking needs for FY24;
                  if %do r = 1 %to &nfy24_require_types.; (lowcase(require_&&fy24_require_types&r.._check) = "y") %if &r. ^= &nfy24_require_types. %then or; %end; then do;
                     if (lowcase(require_cc_excl_check) = "y") and ((lowcase(require_cc_check) = "y") or (lowcase(require_mcc_check) = "y")) then do;
                           
                        *for CC exclusion;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_excl_cc.find(key: PDGNS_CD, key: dgnscd&b.) ^= 0) then do;
                               if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy24_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                               if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy24_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           end;
                        %end;

                        *add 2 because 1 is for the y in require_cc_excl_check and 1 is for the y in either cc_match or mcc_match;
                        if ((lowcase(require_cc_check) = "y") and (cc_match = 1)) or ((lowcase(require_mcc_check) = "y") and (mcc_match = 1)) then forwrd_num_y_have = forwrd_num_y_have + 2;
      
                     end;
                     else do;
      
                        *individual CC checking;
                        if (lowcase(require_cc_check) = "y") then do;
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy24_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                           %end;
                        end;

                        *individual MCC checking;
                        if (lowcase(require_mcc_check) = "y") then do;
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy24_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           %end;
                        end;

                        if ((lowcase(require_cc_check) = "y") and (cc_match = 1)) or ((lowcase(require_mcc_check) = "y") and (mcc_match = 1)) then forwrd_num_y_have = forwrd_num_y_have + 1;
      
                     end;
                  end; %*end of FY24 cc/mcc checks;   
                  
                  *if CC exclusion and CC/MCC checking needs for FY23;
                  else if %do r = 1 %to &nfy23_require_types.; (lowcase(require_&&fy23_require_types&r.._check) = "y") %if &r. ^= &nfy23_require_types. %then or; %end; then do;
                     if (lowcase(require_cc_excl_check) = "y") and ((lowcase(require_cc_check) = "y") or (lowcase(require_mcc_check) = "y")) then do;
                           
                        *for CC exclusion;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_excl_cc.find(key: pdgns_cd, key: dgnscd&b.) ^= 0) then do;
                               if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy23_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                               if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy23_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           end;
                        %end;

                        *add 2 because 1 is for the y in require_cc_excl_check and 1 is for the y in either cc_match or mcc_match;
                        if ((lowcase(require_cc_check) = "y") and (cc_match = 1)) or ((lowcase(require_mcc_check) = "y") and (mcc_match = 1)) then forwrd_num_y_have = forwrd_num_y_have + 2;
      
                     end;
                     else do;
      
                        *individual CC checking;
                        if (lowcase(require_cc_check) = "y") then do;
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy23_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                           %end;
                        end;

                        *individual MCC checking;
                        if (lowcase(require_mcc_check) = "y") then do;
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy23_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           %end;
                        end;

                        if ((lowcase(require_cc_check) = "y") and (cc_match = 1)) or ((lowcase(require_mcc_check) = "y") and (mcc_match = 1)) then forwrd_num_y_have = forwrd_num_y_have + 1;
      
                     end;
                  end; %*end of FY23 cc/mcc checks;     
                  
                  *if CC exclusion and CC/MCC checking needs for FY22;
                  else if %do r = 1 %to &nfy22_require_types.; (lowcase(require_&&fy22_require_types&r.._check) = "y") %if &r. ^= &nfy22_require_types. %then or; %end; then do;
                     if (lowcase(require_cc_excl_check) = "y") and ((lowcase(require_cc_check) = "y") or (lowcase(require_mcc_check) = "y")) then do;
                           
                        *for CC exclusion;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_excl_cc.find(key: pdgns_cd, key: dgnscd&b.) ^= 0) then do;
                               if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy22_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                               if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy22_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           end;
                        %end;

                        *add 2 because 1 is for the y in require_cc_excl_check and 1 is for the y in either cc_match or mcc_match;
                        if ((lowcase(require_cc_check) = "y") and (cc_match = 1)) or ((lowcase(require_mcc_check) = "y") and (mcc_match = 1)) then forwrd_num_y_have = forwrd_num_y_have + 2;
      
                     end;
                     else do;
      
                        *individual CC checking;
                        if (lowcase(require_cc_check) = "y") then do;
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy22_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                           %end;
                        end;

                        *individual MCC checking;
                        if (lowcase(require_mcc_check) = "y") then do;
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy22_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           %end;
                        end;

                        if ((lowcase(require_cc_check) = "y") and (cc_match = 1)) or ((lowcase(require_mcc_check) = "y") and (mcc_match = 1)) then forwrd_num_y_have = forwrd_num_y_have + 1;
      
                     end;
                  end; %*end of FY22 cc/mcc checks;
                  
                  *if CC exclusion and CC/MCC checking needs for FY21;
                  else if %do r = 1 %to &nfy21_require_types.; (lowcase(require_&&fy21_require_types&r.._check) = "y") %if &r. ^= &nfy21_require_types. %then or; %end; then do;
                     if (lowcase(require_cc_excl_check) = "y") and ((lowcase(require_cc_check) = "y") or (lowcase(require_mcc_check) = "y")) then do;
                           
                        *for CC exclusion;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_excl_cc.find(key: pdgns_cd, key: dgnscd&b.) ^= 0) then do;
                               if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy21_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                               if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy21_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           end;
                        %end;

                        *add 2 because 1 is for the y in require_cc_excl_check and 1 is for the y in either cc_match or mcc_match;
                        if ((lowcase(require_cc_check) = "y") and (cc_match = 1)) or ((lowcase(require_mcc_check) = "y") and (mcc_match = 1)) then forwrd_num_y_have = forwrd_num_y_have + 2;
      
                     end;
                     else do;
      
                        *individual CC checking;
                        if (lowcase(require_cc_check) = "y") then do;
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy21_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                           %end;
                        end;

                        *individual MCC checking;
                        if (lowcase(require_mcc_check) = "y") then do;
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy21_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           %end;
                        end;

                        if ((lowcase(require_cc_check) = "y") and (cc_match = 1)) or ((lowcase(require_mcc_check) = "y") and (mcc_match = 1)) then forwrd_num_y_have = forwrd_num_y_have + 1;
      
                     end;
                  end; %*end of FY21 cc/mcc checks;
                  
                  *if CC exclusion and CC/MCC checking needs for FY20;
                  else do;
                     if (lowcase(require_cc_excl_check) = "y") and ((lowcase(require_cc_check) = "y") or (lowcase(require_mcc_check) = "y")) then do;
                           
                        *for CC exclusion;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_excl_cc.find(key: pdgns_cd, key: dgnscd&b.) ^= 0) then do;
                               if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy_list_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                               if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy_list_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           end;
                        %end;

                        *add 2 because 1 is for the y in require_cc_excl_check and 1 is for the y in either cc_match or mcc_match;
                        if ((lowcase(require_cc_check) = "y") and (cc_match = 1)) or ((lowcase(require_mcc_check) = "y") and (mcc_match = 1)) then forwrd_num_y_have = forwrd_num_y_have + 2;
      
                     end;
                     else do;
      
                        *individual CC checking;
                        if (lowcase(require_cc_check) = "y") then do;
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy_list_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                           %end;
                        end;

                        *individual MCC checking;
                        if (lowcase(require_mcc_check) = "y") then do;
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy_list_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           %end;
                        end;

                        if ((lowcase(require_cc_check) = "y") and (cc_match = 1)) or ((lowcase(require_mcc_check) = "y") and (mcc_match = 1)) then forwrd_num_y_have = forwrd_num_y_have + 1;
      
                     end;
                  end; %*end of FY20 cc/mcc checks;
                  
                  *if invasive/complex procedure checking needs to be done;
                  if (lowcase(require_inv_comp_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (inv_comp.find(key: prcdrcd&b.) = 0) then do;
                           inv_comp_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if PCI intracardiac procedure checking needs to be done;
                  if (lowcase(require_intracardiac_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (pci_cd.find(key: prcdrcd&b.) = 0) then do;
                           pci_intracardiac_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if encounter dialysis checking needs to be done;
                  if (lowcase(require_enc_d_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (enc_cd.find(key: dgnscd&b.) = 0) then do;
                           enc_d_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if sterilization checking needs to be done;
                  if (lowcase(require_steril_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (ster_cd.find(key: drg_cd, key: prcdrcd&b.) = 0) then do;
                           steril_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if neoplasm kidney checking needs to be done;
                  if (lowcase(require_neo_kid_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (neo_kid_cd.find(key: dgnscd&b.) = 0) then do;
                           neo_kid_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if neoplasm genitourinary checking needs to be done;
                  if (lowcase(require_neo_gen_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (neo_gen_cd.find(key: dgnscd&b.) = 0) then do;
                           neo_gen_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if extraction of endometrium checking needs to be done;
                  if (lowcase(require_extr_endo_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (extr_endo_cd.find(key: prcdrcd&b.) = 0) then do;
                           extr_endo_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if male reproductive system checking needs to be done;
                  if (lowcase(require_male_repro_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (male_repro_cd.find(key: dgnscd&b.) = 0) then do;
                           male_repro_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if abnormal radiologic checking needs to be done;
                  if (lowcase(require_abn_radio_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (abn_radio_cd.find(key: dgnscd&b.) = 0) then do;
                           abn_radio_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if carotid artery checking needs to be done;
                  if (lowcase(require_caro_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (caro_cd.find(key: prcdrcd&b.) = 0) then do;
                           caro_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if complicating pregnancy, childbirth and the puerperium checking needs to be done;
                  if (lowcase(require_ante_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (ante_cd.find(key: dgnscd&b.) = 0) then do;
                           ante_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if a transcatheter cardiac valve repair checking needs to be done;
                  if (lowcase(require_endo_card_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (endo_card_cd.find(key: drg_cd, key: prcdrcd&b.) = 0) then do;
                           endo_card_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if pulmonary embolism checking needs to be done;
                  if (lowcase(require_pul_emb_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (pul_emb_cd.find(key: dgnscd&b.) = 0) then do;
                           pul_emb_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if autologous cordblood stem cell checking needs to be done;
                  if (lowcase(require_auto_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (auto_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           auto_bm_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if extracorporeal membrane oxygenation checking needs to be done;
                  if (lowcase(require_ecmo_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (ecmo_cd.find(key: prcdrcd&b.) = 0) then do;
                           ecmo_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if revision or removal of extraluminal device checking needs to be done;
                  if (lowcase(require_repro_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (repro_cd.find(key: prcdrcd&b.) = 0) then do;
                           repro_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                   *if infected bursa and other infections of the joints checking needs to be done;
                  if (lowcase(require_musc_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (musc_cd.find(key: dgnscd&b.) = 0) then do;
                           musc_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if infected bursa and other infections of the joints checking needs to be done;
                  if (lowcase(require_knee_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (knee_cd.find(key: drg_cd, key: dgnscd&b.) = 0) then do;
                           knee_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if conditions involving the cervical region checking needs to be done;
                  if (lowcase(require_skin_sub_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (skin_sub_cd.find(key: prcdrcd&b.) = 0) then do;
                           skin_sub_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if male with malignancy checking needs to be done;
                  if (lowcase(require_male_malig_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (male_malig_cd.find(key: dgnscd&b.) = 0) then do;
                           male_malig_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if male without malignancy checking needs to be done;
                  if (lowcase(require_male_no_malig_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (male_no_malig_cd.find(key: dgnscd&b.) = 0) then do;
                           male_no_malig_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if female diagnosis code checking needs to be done;
                  if (lowcase(require_fem_diagn_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fem_diagn_cd.find(key: dgnscd&b.) = 0) then do;
                           fem_diagn_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if revision or removal of extraluminal device in stomach needs to be done;
                  if (lowcase(require_stomach_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (stomach_cd.find(key: prcdrcd&b.) = 0) then do;
                           stomach_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if non-supplement transcatheter cardiac valve checking needs to be done;
                  if (lowcase(require_othr_endo_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (othr_endo_cd.find(key: drg_cd, key: prcdrcd&b.) = 0) then do;
                           othr_endo_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if scoliosis, secondary scoliosis and secondary kyphosis checking needs to be done;
                  if (lowcase(require_scol_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (scol_cd.find(key: dgnscd&b.) = 0) then do;
                           scol_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if cervical spinal fusion code checking needs to be done;
                  if (lowcase(require_cerv_spin_check) = "y") then do;
                     %***check only for principal diagnosis;
                     if (pd_cerv_spin_cd.find(key: PDGNS_CD) = 0) then do;
                        cerv_spin_match = 1;
                        forwrd_num_y_have = forwrd_num_y_have + 1;
                     end;
                     %***check only for secondary diagnosis;
                     %do a = 2 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        else if (sd_cerv_spin_cd.find(key: dgnscd&b.) = 0) then do;
                           cerv_spin_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                     %end;
                  end;

                  *if spinal fusion procedure code checking needs to be done;
                  if (lowcase(require_spin_proc_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (spin_proc_cd.find(key: prcdrcd&b.) = 0) then do;
                           spin_proc_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if mitral valve code checking needs to be done;
                  if (lowcase(require_mitral_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (mitral_cd.find(key: prcdrcd&b.) = 0) then do;
                           mitral_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if car t-cell therapies code checking needs to be done;
                  if (lowcase(require_car_t_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (car_t_cd.find(key: prcdrcd&b.) = 0) then do;
                           car_t_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if dilation of cartoid artery code checking needs to be done;
                  if (lowcase(require_caro_dila_check) = "y") then do;
                     if (dschrgdt >= "&icd9_icd10_date."D) then do;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (s_caro_dila_cd.find(key: drg_cd, key: prcdrcd&b.) = 0) then do;
                              caro_dila_match = 1;
                              forwrd_num_y_have = forwrd_num_y_have + 1;
                           end;
                           %if &a. ^= &diag_proc_length. %then else;
                        %end;
                     end;
                     else do;
                        if (c_caro_dila_cd.find(key: drg_cd) = 0) then do;
                           rc_caro_dila = 0;
                           do while (rc_caro_dila = 0);
                              %do a = 1 %to &diag_proc_length.;
                                 %let b = %sysfunc(putn(&a., z2.));
                                 if (prcdrcd&b. = caro_dila_code1) then caro_dila_match_1 = 1;
                                 if (prcdrcd&b. = caro_dila_code2) then caro_dila_match_2 = 1;
                                 if (prcdrcd&b. = caro_dila_code3) then caro_dila_match_3 = 1;
                                 if (prcdrcd&b. = caro_dila_code4) then caro_dila_match_4 = 1;
                              %end;
                              if (caro_dila_match_1 = 1) and (caro_dila_match_2 = 1) and (caro_dila_match_3 = 1) and (caro_dila_match_4 = 1) then do;
                                 caro_dila_match = 1;
                                 forwrd_num_y_have = forwrd_num_y_have + 1;
                              end;
                              if (caro_dila_match = 1) then rc_caro_dila = 1;
                              else rc_caro_dila = c_caro_dila_cd.find_next();
                           end;
                        end; 
                     end; 
                  end; 

                  *if head, neck, cranial and facial procedures related procedure code needs to be checked;
                  if (lowcase(require_head_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (p_head_cd.find(key: prcdrcd&b.) = 0) then do;
                           head_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if head, neck, cranial and facial procedures related diagnosis code needs to be checked;
                  if (lowcase(require_head_diag_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (d_head_cd.find(key: dgnscd&b.) = 0) then do;
                           head_diag_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if ear, nose, mouth and throat related procedure code needs to be checked;
                  if (lowcase(require_ear_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (p_ear_cd.find(key: prcdrcd&b.) = 0) then do;
                           ear_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if ear, nose, mouth and throat related diagnosis code needs to be checked;
                     if (lowcase(require_ear_diag_check) = "y") then do;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (d_ear_cd.find(key: dgnscd&b.) = 0) then do;
                              ear_diag_match = 1;
                              forwrd_num_y_have = forwrd_num_y_have + 1;
                           end;
                           %if &a. ^= &diag_proc_length. %then else;
                        %end;
                  end;

                  *if left atrial appendage closure code checking needs to be done;
                  if (lowcase(require_laac_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (laac_cd.find(key: prcdrcd&b.) = 0) then do;
                           laac_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if hip fracture and hip replacement procedure code checking needs to be done;
                  if (lowcase(require_hip_frac_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (p_hip_frac_cd.find(key: prcdrcd&b.) = 0) then p_hip_frac_match = 1;
                        if (d_hip_frac_cd.find(key: dgnscd&b.) = 0) then d_hip_frac_match = 1;
                     %end;
                     if (p_hip_frac_match = 1) and (d_hip_frac_match = 1) then forwrd_num_y_have = forwrd_num_y_have + 1;
                  end;

                  *if hemodialysis code checking needs to be done;
                  if (lowcase(require_hemo_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (hemo_cd.find(key: prcdrcd&b.) = 0) then do;
                           hemo_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if kidney transplant code checking needs to be done;
                  if (lowcase(require_kid_trans_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (kid_trans_cd.find(key: prcdrcd&b.) = 0) then do;
                           kid_trans_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if mechanical complications of vascular dialysis catheters code checking needs to be done;
                  if (lowcase(require_vascular_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (vascular_cd.find(key: dgnscd&b.) = 0) then do;
                           vascular_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if non-operating room procedure code checking needs to be done;
                  if (lowcase(require_non_or_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (non_or_cd.find(key: prcdrcd&b.) = 0) then do;
                           non_or_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if peritoneal cavity procedure code checking needs to be done;
                  if (lowcase(require_peritoneal_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (periton_cd.find(key: prcdrcd&b.) = 0) then do;
                           peritoneal_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if excision of mediastinum code checking needs to be done;
                  if (lowcase(require_media_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (media_cd.find(key: prcdrcd&b.) = 0) then do;
                           media_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *FY2022 MAPPINGS;
                  *if excision of subcutaneous tissue code checking needs to be done;
                  if (lowcase(require_sub_tiss_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (sub_tiss_cd.find(key: prcdrcd&b.) = 0) then do;
                           sub_tiss_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if laser interstitial thermal therapy code checking needs to be done for remapping from 023, 024, 025, 026, 027 to 040, 041, 042;
                  if (lowcase(require_litt1_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt1_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt1_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if laser interstitial thermal therapy code checking needs to be done for remapping from 163, 164, 165 to 040, 041,  042;
                  if (lowcase(require_litt2_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt2_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt2_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if laser interstitial thermal therapy code checking needs to be done for remapping from 981, 982, 983 to 987, 988, 989;
                  if (lowcase(require_litt3_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt3_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt3_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if laser interstitial thermal therapy code checking needs to be done for remapping from 715, 716 to 987, 988, 989;
                  if (lowcase(require_litt4_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt4_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt4_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if repair of the esophagus code checking needs to be done;
                  if (lowcase(require_eso_repair_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (eso_repair_cd.find(key: prcdrcd&b.) = 0) then do;
                           eso_repair_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if cowpers gland code checking needs to be done;
                  if (lowcase(require_cowpers_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (cowpers_cd.find(key: prcdrcd&b.) = 0) then do;
                           cowpers_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if laser interstitial thermal therapy code checking needs to be done for remapping to 166, 167, and 168;
                  if (lowcase(require_litt5_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt5_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt5_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if laser interstitial thermal therapy code checking needs to be done for remapping to 356, 357, and 358;
                  if (lowcase(require_litt6_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt6_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt6_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if laser interstitial thermal therapy code checking needs to be done for remapping to 423, 424, and 425;
                  if (lowcase(require_litt7_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt7_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt7_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if laser interstitial thermal therapy code checking needs to be done for remapping to 628, 629, and 630;
                  if (lowcase(require_litt8_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt8_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt8_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if removal and replacement of the right knee joint code checking needs to be done for remapping to 628, 629, 630;
                  if (lowcase(require_r_knee1_check) = "y") then do;
                     if (r_knee1_cd.find(key: drg_cd) = 0) then do;
                        rc_r_knee1 = 0;
                        do while (rc_r_knee1 = 0);
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (prcdrcd&b. = r_knee1_code1) then r_knee1_match_1 = 1;
                              if (prcdrcd&b. = r_knee1_code2) then r_knee1_match_2 = 1;
                           %end;
                           if (r_knee1_match_1 = 1) and (r_knee1_match_2 = 1) then do;
                              r_knee1_match = 1;
                              forwrd_num_y_have = forwrd_num_y_have + 1;
                           end;
                           if (r_knee1_match = 1) then rc_r_knee1 = 1;
                           else rc_r_knee1 = r_knee1_cd.find_next();
                        end;
                     end;
                  end;
                  
                  *if laser interstitial thermal therapy code checking needs to be done for remapping to 584 and 585;
                  if (lowcase(require_litt9_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt9_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt9_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if laser interstitial thermal therapy code checking needs to be done for remapping to 715, 716, 717, 718;
                  if (lowcase(require_litt10_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt10_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt10_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if pulmonary or thoracic structures code checking needs to be done;
                  if (lowcase(require_pulm_thor_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (pulm_thor_cd.find(key: prcdrcd&b.) = 0) then do;
                           pulm_thor_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if heart assist device code checking needs to be done;
                  if (lowcase(require_h_device_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (h_device_cd.find(key: prcdrcd&b.) = 0) then do;
                           h_device_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if cardiac catheterization code checking needs to be done;
                  if (lowcase(require_card_cath_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (card_cath_cd.find(key: prcdrcd&b.) = 0) then do;
                           card_cath_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if viral cardiomyopathy code checking needs to be done;
                  if (lowcase(require_viral_card_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (viral_card_cd.find(key: dgnscd&b.) = 0) then do;
                           viral_card_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if removal and replacement of the right knee joint code checking needs to be done for remapping to 461, 462, 466, 467, 468;
                  if (lowcase(require_r_knee2_check) = "y") then do;
                     if (r_knee2_cd.find(key: drg_cd) = 0) then do;
                        rc_r_knee2 = 0;
                        do while (rc_r_knee2 = 0);
                           %do a = 1 %to &diag_proc_length.;
                              %let b = %sysfunc(putn(&a., z2.));
                              if (prcdrcd&b. = r_knee2_code1) then r_knee2_match_1 = 1;
                              if (prcdrcd&b. = r_knee2_code2) then r_knee2_match_2 = 1;
                           %end;
                           if (r_knee2_match_1 = 1) and (r_knee2_match_2 = 1) then do;
                              r_knee2_match = 1;
                              forwrd_num_y_have = forwrd_num_y_have + 1;
                           end;
                           if (r_knee2_match = 1) then rc_r_knee2 = 1;
                           else rc_r_knee2 = r_knee2_cd.find_next();
                        end;
                     end;
                  end;
                  
                  *if left knee joint, right/left hip joint, right/left ankle joint code checking needs to be done;
                  if (lowcase(require_bl_mult_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (bl_mult_cd.find(key: prcdrcd&b.) = 0) then do;
                           bl_mult_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if coronary artery bypass graft code checking needs to be done;
                  if (lowcase(require_cor_alt_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (cor_alt_cd.find(key: prcdrcd&b.) = 0) then do;
                           cor_alt_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if open surgical ablation code checking needs to be done;
                  if (lowcase(require_surg_ab_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (surg_ab_cd.find(key: prcdrcd&b.) = 0) then do;
                           surg_ab_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *FY2023 MAPPINGS;
                  *if acute respiratory distress syndrome code checking needs to be done;
                  if (lowcase(require_resp_synd_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (resp_synd_cd.find(key: dgnscd&b.) = 0) then do;
                           resp_synd_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if cardiac mapping code checking needs to be done;
                  if (lowcase(require_cardiac_map_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (cardiac_map_cd.find(key: prcdrcd&b.) = 0) then do;
                           cardiac_map_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;    
                  
                  *if extremely low birth weight newborn and extreme immaturity of newborn code checking needs to be done;
                  if (lowcase(require_lbw_imm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (lbw_imm_cd.find(key: dgnscd&b.) = 0) then do;
                           lbw_imm_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;                  

                  *if extreme immaturity of newborn code checking needs to be done;
                  if (lowcase(require_extreme_imm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (extreme_imm_cd.find(key: dgnscd&b.) = 0) then do;
                           extreme_imm_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end; 
                  
                  *if supplemental mitral valve code checking needs to be done;
                  if (lowcase(require_supp_mit_valve_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (supp_mit_valve_cd.find(key: prcdrcd&b.) = 0) then do;
                           supp_mit_valve_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end; 

                  *if MDC 07 code checking needs to be done;
                  if (lowcase(require_mdc07_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (mdc07_cd.find(key: dgnscd&b.) = 0) then do;
                           mdc07_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end; 

                  *if occlusion and restrictions of veins code checking needs to be done;
                  if (lowcase(require_occ_restr_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (occ_restr_cd.find(key: prcdrcd&b.) = 0) then do;
                           occ_restr_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end; 

                  *if common bile duct exploration code checking needs to be done;
                  if (lowcase(require_cde_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (cde_cd.find(key: prcdrcd&b.) = 0) then do;
                           cde_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if liveborn infants code checking needs to be done;
                  if (lowcase(require_liveborn_infant_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (liveborn_infant_cd.find(key: dgnscd&b.) = 0) then do;
                           liveborn_infant_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if exposure to infectious disease code checking needs to be done;
                  if (lowcase(require_inf_disease_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (inf_disease_cd.find(key: dgnscd&b.) = 0) then do;
                           inf_disease_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                
                  *FY2024 MAPPINGS;
                  *if percutaneous cardiovascular procedures with intraluminal device checking needs to be done;
                  if (lowcase(require_ild_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_ild_cd.find(key: prcdrcd&b.) = 0) then do;
                           intralumid_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if coronary intravascular lithotripsy checking needs to be done;
                  if (lowcase(require_cor_ivl_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_crn_cd.find(key: prcdrcd&b.) = 0) then do;
                           coronary_ivl_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     
                  end;
                  
                  *if percutaneous cardiovascular procedures with 4+ arteries and intraluminal devices needs to be done; 
                  if (lowcase(require_ac_4p_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_ild4_cd.find(key: prcdrcd&b.) = 0) then do;
                           ail4plus_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;                       
                        %if &a. ^= &diag_proc_length. %then else;                                                
                     %end;                     
                  end;
                  *if Procedure code combinations for cardiac defibrillator implant;              
                  if (lowcase(require_cfeb_imp_check) = "y") then do;
                      %do a = 1 %to &diag_proc_length.; 
                           %let b = %sysfunc(putn(&a., z2.));
                           rc_Crdc_Dfb = 0;

                           if (fy24_crddef_cd.find(key: prcdrcd&b.) = 0) then do;
                              do while (rc_Crdc_Dfb = 0);
                                 %do c = 1 %to &diag_proc_length.; 
                                    %let d = %sysfunc(putn(&c., z2.));
                                    if strip(prcdrcd&d.) = fy24_car_defibimp_code2 then do;
                                       cardef_imp_match = 1;
                                    end;
                                 %end;
                                 if (cardef_imp_match = 1) then do;
                                    rc_Crdc_Dfb = 1;
                                 end;
                                 else rc_Crdc_Dfb = fy24_crddef_cd.find_next();
                              end;
                           end;

                        %end;
                                                                  
                     if cardef_imp_match = 1 then forwrd_num_y_have = forwrd_num_y_have + 1;                        
                  end;
                  
                  *Non-operating procedure codes for cardiac catheterization;
                  if (lowcase(require_ccath_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_carcath_cd.find(key: prcdrcd&b.) = 0) then do;
                           car_cath_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Procedure codes for ultrasound accelerated and other thrombolysis;
                  if (lowcase(require_ultaccth_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_ulthr_cd.find(key: prcdrcd&b.) = 0) then do;
                           ulaccth_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Procedure codes for Procedure codes for aortic valve repair/replacement;
                  if (lowcase(require_at_val_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_artvl_cd.find(key: prcdrcd&b.) = 0) then do;
                           art_valve_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Procedure codes for Procedure codes for mitral valve repair/replacement;
                  if (lowcase(require_mit_val_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_mitvl_cd.find(key: prcdrcd&b.) = 0) then do;
                           mit_valve_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Procedure codes for Procedure codes for for other concomitant;
                  if (lowcase(require_other_conc_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_oth_com_cd.find(key: prcdrcd&b.) = 0) then do;
                           oth_con_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Principal diagnosis code for pulmonary embolism (PE);
                  if (lowcase(require_pul_emb_diag_check) = "y") then do;
                     if (fy24_pul_emb_diag.find(key: PDGNS_CD) = 0) then do;
                        pul_emb_diag_match = 1;
                        forwrd_num_y_have = forwrd_num_y_have + 1;
                     end;                      
                  end;
                  
                  *Principal diagnosis code for ultrasound accelerated and other thrombolysis;
                  if (lowcase(require_ulth_pe_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_ultthb_cd.find(key: prcdrcd&b.) = 0) then do;
                           ulaccth_pe_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Procedure codes for appendectomy;
                  if (lowcase(require_appen_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_appendectomy.find(key: prcdrcd&b.) = 0) then do;
                           appendectomy_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Diagnosis codes for central retinal artery occlusion (CRAO) and branch retinal artery occlusion (BRAO);
                  if (lowcase(require_cbrao_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_crb_cd.find(key: dgnscd&b.) = 0) then do;
                           crao_brao_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Procedure codes for thrombolytic agent, including non-operating room procedures;
                  if (lowcase(require_thragnt_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_thbag_cd.find(key: prcdrcd&b.) = 0) then do;
                           thrb_agent_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Procedure codes for Principal Diagnosis codes for MS-DRGs 177 178 and 179;
                  if (lowcase(require_DRGs_177179_check) = "y") then do;
                     if (fy24_DRG177_179_cd.find(key: PDGNS_CD) = 0) then do;
                       DRGs_177_179_match = 1;
                       forwrd_num_y_have = forwrd_num_y_have + 1;
                     end;                       
                  end;
                  
                  *Diagnosis codes for respiratory infections and inflammations;
                  if (lowcase(require_resp_inf_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_resp_inf_cd.find(key: dgnscd&b.) = 0) then do;
                           re_infinflam_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Procedure code for implant of heart assist system;
                  if (lowcase(require_imp_hrt_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_imp_hrt_cd.find(key: prcdrcd&b.) = 0) then do;
                           imp_hrta_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Procedure code for other kidney and urinary tract procedures;
                  if (lowcase(require_kidney_ut_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_kd_ut_cd.find(key: prcdrcd&b.) = 0) then do;
                           kidney_ut_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Principal diagnosis code for vesicointestinal fistula;
                  if (lowcase(require_vesi_fist_check) = "y") then do;
                     if (fy24_ves_fist_cd.find(key: PDGNS_CD) = 0) then do;
                        vesi_fist_match = 1;
                        forwrd_num_y_have = forwrd_num_y_have + 1;
                     end;                     
                  end;
                  
                  *Procedure code for open excision of muscle;
                  if (lowcase(require_open_exc_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_opexc_cd.find(key: prcdrcd&b.) = 0) then do;
                           on_exci_musc_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Principal diagnosis code for gangrene;
                  if (lowcase(require_gang_check) = "y") then do;
                     if (fy24_gangrene_cd.find(key: PDGNS_CD) = 0) then do;
                        gangrene_match = 1;
                        forwrd_num_y_have = forwrd_num_y_have + 1;
                     end;                       
                  end;
                  
                  *Procedure codes for endoscopic dilation of ureters with an intraluminal device;
                  if (lowcase(require_endo_dil_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_end_dil_cd.find(key: prcdrcd&b.) = 0) then do;
                           end_dilation_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Principal diagnosis code for hypertensive heart and chronic kidney disease;
                  if (lowcase(require_hy_htkd_check) = "y") then do;
                       if (fy24_hykid_cd.find(key: PDGNS_CD) = 0) then do;
                          hy_heart_chrkidn_match = 1;
                          forwrd_num_y_have = forwrd_num_y_have + 1;
                       end;                     
                  end;
                  
                  *Procedure codes for other skin, subcutaneous tissue and breast procedures;
                  if (lowcase(require_skin_bst_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_skbreast_cd.find(key: prcdrcd&b.) = 0) then do;
                           sksub_brst_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Principal diagnosis codes for MDC 09;
                  if (lowcase(require_mdc_09_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_mdc_09_cd.find(key: PDGNS_CD) = 0) then do;
                           mdc_09_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                 
                  *Procedure codes for occl spleen;
                  if (lowcase(require_occl_spl_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_occl_splart_cd.find(key: prcdrcd&b.) = 0) then do;
                           occl_spl_art_match = 1;
                           forwrd_num_y_have = forwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *Principal diagnosis codes for maj spleen;
                  if (lowcase(require_maj_spl_check) = "y") then do;
                     if (fy24_oc_sp_cd.find(key: PDGNS_CD) = 0) then do;
                        maj_lac_spn_init_match = 1;
                        forwrd_num_y_have = forwrd_num_y_have + 1;
                     end;
                  end;
                                                                                
                  *NOTE: special circumstance when dealing with DRG 490. count the below matches as being equivalent to 1 overall match rather than separate multiple matches;
                  if (special_case_flag = 1) and
                     (((lowcase(require_neuro_check) = "y") and (required_neuro_match = 1) and (additional_neuro_match = 1)) or
                     ((lowcase(require_device_check) = "y") and (device_match = 1)) or
                     ((lowcase(require_cc_excl_check) = "y") and (lowcase(require_mcc_check) = "y") and (mcc_match = 1))) then forwrd_num_y_have = 1;

                  *determine if requirements for remapping have been met;
                  if (forwrd_num_y_need ^= 0) and (forwrd_num_y_have ^= 0) and (forwrd_num_y_need = forwrd_num_y_have) then remap = 1;

                  if (remap = 1) then do;
                     %do year = &baseline_start_year. %to %eval(&update_factor_fy.-1);
                        if (year(input(date_of_remap, date9.)) = &year.) and (dschrgdt < input(date_of_remap, date9.)) and (missing(drg_%eval(&year.+ 1))) then do;
                           forwrd_remap_drg_flag = 1;
                           forwrd_num_y_need_=forwrd_num_y_need;
                           forwrd_num_y_have_=forwrd_num_y_have;
                           drg_%eval(&year.+ 1) = new_drg_cd;
                        end;
                        %if &year. ^= %eval(&update_factor_fy.-1) %then else;
                     %end;
                  end;

               end; %*end of condition C;
               
            end; %*end of forward mapping; 

            else if (lowcase(mapping_type) = "backward") then do; 

               *if no diagnosis code or procedure code checking needs to be done;
               if %do r = 1 %to &nrequire_types.; (lowcase(require_&&require_types&r.._check) = "n") %if &r. ^= &nrequire_types. %then and; %end; then do;
                  %do year = &baseline_start_year. %to &update_factor_fy.;
                     if (year(input(date_of_remap, date9.)) = &year.) and (dschrgdt >= input(date_of_remap, date9.)) and (missing(drg_&year.)) then do;
                        backwrd_remap_drg_flag = 1;
                        drg_&year. = new_drg_cd;
                     end;
                     %if &year. ^= &update_factor_fy. %then else;
                  %end;
               end;

               *condition D;
               else do;

                  *count the number of requirements that need to be met;
                  *NOTE: special circumstance when dealing with DRG 483. count the below requirement as being equal to 1 overall requirement rather than 2 separate individual ones;
                  if (lowcase(require_cc_check) = "y") and (lowcase(require_mcc_check) = "y") then do;
                     backwrd_num_y_need = 1;
                     special_case_flag = 1;
                  end;
                  else do;
                     if ((lowcase(require_mcc_check) = "y") and (lowcase(require_cc_check) = "y")) or (lowcase(require_mcc_check) = "y") or (lowcase(require_cc_check) = "y") then backwrd_num_y_need = backwrd_num_y_need + 1;
                     %do r = 1 %to &nrequire_types.;
                        %if "&&require_types&r.." ^= "cc" and "&&require_types&r.." ^= "mcc" %then %do;
                           if (lowcase(require_&&require_types&r.._check) = "y") then backwrd_num_y_need = backwrd_num_y_need + 1;
                        %end;
                     %end;
                  end;

                  *if supplemental cardiac code checking needs to be done;
                  if (lowcase(require_supp_cardiac_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (supp_cd.find(key: prcdrcd&b.) = 0) then supp_cardiac_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (supp_cardiac_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;

                  *if aortic procedure code checking needs to be done;
                  if (lowcase(require_aortic_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (aortic_cd.find(key: prcdrcd&b.) = 0) then aortic_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (aortic_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;

                  *if thoracic repair code checking needs to be done;
                  if (lowcase(require_repair_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (repair_cd.find(key: prcdrcd&b.) = 0) then repair_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (repair_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;

                  *if mitral valve code checking needs to be done;
                  if (lowcase(require_mitral_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (mitral_cd.find(key: prcdrcd&b.) = 0) then mitral_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (mitral_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                      
                  *if non-supplement transcatheter cardiac valve checking needs to be done for bm1;
                  if (lowcase(require_endo_bm1_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (othr_endo_bm1.find(key: prcdrcd&b.) = 0) then endo_bm1_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;                    
                     %end;
                     if (endo_bm1_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if non-supplement transcatheter cardiac valve checking needs to be done for bm2;
                  if (lowcase(require_endo_bm2_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (othr_endo_bm2.find(key: prcdrcd&b.) = 0) then endo_bm2_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;                       
                     %end;
                     if (endo_bm2_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if car t-cell therapies code checking needs to be done for bm;
                  if (lowcase(require_cart_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (car_t_bm.find(key: prcdrcd&b.) = 0) then cart_bm_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (cart_bm_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if hemodialysis code checking needs to be done for bm;
                  if (lowcase(require_hemo_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (hemo_bm.find(key: prcdrcd&b.) = 0) then hemo_bm_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (hemo_bm_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if hip fracture and hip replacement procedure code checking needs to be done for bm;
                  if (lowcase(require_hip_fracbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (p_hip_frac_bm.find(key: prcdrcd&b.) = 0) then p_hip_fracbm_match = 1;
                        if (d_hip_frac_bm.find(key: dgnscd&b.) = 0) then d_hip_fracbm_match = 1;
                     %end;
                     if (p_hip_fracbm_match = 1) and (d_hip_fracbm_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if kidney transplant code checking needs to be done for bm;
                  if (lowcase(require_kid_transbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (kid_trans_bm.find(key: prcdrcd&b.) = 0) then kid_transbm_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (kid_transbm_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if DRG129 related procedure code needs to be checked for bm from DRGs 140, 141 and 142;
                  if (lowcase(require_drg129a_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (drg129a_cd.find(key: prcdrcd&b.) = 0) then drg129a_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (drg129a_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;

                  *if DRG130 related procedure code needs to be checked for bm from DRGs 140, 141 and 142;
                  if (lowcase(require_drg130a_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (drg130a_cd.find(key: prcdrcd&b.) = 0) then drg130a_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (drg130a_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if DRG131 related procedure code needs to be checked for bm from DRGs 140, 141 and 142;
                  if (lowcase(require_drg131a_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (drg131a_cd.find(key: prcdrcd&b.) = 0) then drg131a_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (drg131a_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if DRG132 related procedure code needs to be checked for bm from DRGs 140, 141 and 142;
                  if (lowcase(require_drg132a_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (drg132a_cd.find(key: prcdrcd&b.) = 0) then drg132a_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (drg132a_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if DRG133 related procedure code needs to be checked for bm from DRGs 140, 141 and 142;
                  if (lowcase(require_drg133a_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (drg133a_cd.find(key: prcdrcd&b.) = 0) then drg133a_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (drg133a_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if DRG134 related procedure code needs to be checked for bm from DRGs 140, 141 and 142;
                  if (lowcase(require_drg134a_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (drg134a_cd.find(key: prcdrcd&b.) = 0) then drg134a_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (drg134a_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if DRG129 related procedure code needs to be checked for bm from DRGs 143, 144 and 145;
                  if (lowcase(require_drg129b_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (drg129b_cd.find(key: prcdrcd&b.) = 0) then drg129b_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (drg129b_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if DRG130 related procedure code needs to be checked for bm from DRGs 143, 144 and 145;
                  if (lowcase(require_drg130b_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (drg130b_cd.find(key: prcdrcd&b.) = 0) then drg130b_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (drg130b_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if DRG131 related procedure code needs to be checked for bm from DRGs 143, 144 and 145;
                  if (lowcase(require_drg131b_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (drg131b_cd.find(key: prcdrcd&b.) = 0) then drg131b_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (drg131b_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                 end;
                  
                  *if DRG132 related procedure code needs to be checked for bm from DRGs 143, 144 and 145;
                  if (lowcase(require_drg132b_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (drg132b_cd.find(key: prcdrcd&b.) = 0) then drg132b_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (drg132b_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if DRG133 related procedure code needs to be checked for bm from DRGs 143, 144 and 145;
                  if (lowcase(require_drg133b_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (drg133b_cd.find(key: prcdrcd&b.) = 0) then drg133b_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (drg133b_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if DRG134 related procedure code needs to be checked for bm from DRGs 143, 144 and 145;
                  if (lowcase(require_drg134b_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (drg134b_cd.find(key: prcdrcd&b.) = 0) then drg134b_match = 1;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                     if (drg134b_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if dilation of cartoid artery code checking needs to be done for bm1;
                  if (lowcase(require_caro_dilabm1_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (caro_dilabm1_cd.find(key: prcdrcd&b.) = 0) then do;
                           caro_dilabm1_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if dilation of cartoid artery code checking needs to be done for bm2;
                  if (lowcase(require_caro_dilabm2_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (caro_dilabm2_cd.find(key: prcdrcd&b.) = 0) then do;
                           caro_dilabm2_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if left atrial appendage closure code checking needs to be done for bm;
                  if (lowcase(require_laac_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (laac_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           laac_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if mechanical complications of vascular dialysis catheters code checking needs to be done for bm;
                  if (lowcase(require_vascular_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (vas_bm_cd.find(key: dgnscd&b.) = 0) then do;
                           vascular_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if non-operating room procedure code checking needs to be done for bm;
                  if (lowcase(require_non_orbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (non_orbm_cd.find(key: prcdrcd&b.) = 0) then do;
                           non_orbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if peritoneal cavity procedure code checking needs to be done for bm;
                  if (lowcase(require_periton_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (periton_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           periton_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if excision of mediastinum code checking needs to be done for bm;
                  if (lowcase(require_media_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (media_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           media_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *FY2022 BACKWARD MAPPINGS;
                  *if excision of subcutaneous tissue code checking needs to be done for bm;
                  if (lowcase(require_sub_tissbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (sub_tissbm_cd.find(key: prcdrcd&b.) = 0) then do;
                           sub_tissbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if laser interstitial thermal therapy code checking needs to be done for remapping from 023, 024, 025, 026, 027 to 040, 041, 042 for bm;
                  if (lowcase(require_litt1_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt1_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt1_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if laser interstitial thermal therapy code checking needs to be done for remapping from 163, 164, 165 to 040, 041, 042 for bm;
                  if (lowcase(require_litt2_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt2_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt2_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if laser interstitial thermal therapy code checking needs to be done for remapping from 981, 982, 983 to 987, 988, 989 for bm;
                  if (lowcase(require_litt3_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt3_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt3_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if laser interstitial thermal therapy code checking needs to be done for remapping from 715, 716 to 987, 988, 989 for bm;
                  if (lowcase(require_litt4_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt4_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt4_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if repair of the esophagus code checking needs to be done for bm;
                  if (lowcase(require_eso_repairbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (eso_repairbm_cd.find(key: prcdrcd&b.) = 0) then do;
                           eso_repairbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if cowpers gland code checking needs to be done for bm;
                  if (lowcase(require_cowpers_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (cowpers_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           cowpers_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if laser interstitial thermal therapy code checking needs to be done for remapping to 166, 167, and 168 for bm;
                  if (lowcase(require_litt5_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt5_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt5_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if laser interstitial thermal therapy code checking needs to be done for remapping to 356, 357, and 358 for bm;
                  if (lowcase(require_litt6_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt6_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt6_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if laser interstitial thermal therapy code checking needs to be done for remapping to 423, 424, and 425 for bm;
                  if (lowcase(require_litt7_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt7_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt7_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if laser interstitial thermal therapy code checking needs to be done for remapping to 628, 629, and 630 for bm;
                  if (lowcase(require_litt8_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt8_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt8_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if removal and replacement of the right knee joint code checking needs to be done for remapping to 628, 629, 630 for bm;
                  if (lowcase(require_r_kneebm1_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.; 
                        %let b = %sysfunc(putn(&a., z2.));
                        if (r_kneebm1_match = 0) and (r_kneebm1_cd.find(key: prcdrcd&b.) = 0) then do;
                           rc_r_kneebm1 = 0;
                           do while (rc_r_kneebm1 = 0);
                              %do c = 1 %to &diag_proc_length.; 
                                 %let d = %sysfunc(putn(&a., z2.));
                                 if (prcdrcd&d. = r_kneebm1_code2) then r_kneebm1_match = 1;
                              %end;
                              if (r_kneebm1_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                              if (r_kneebm1_match = 1) then rc_r_kneebm1 = 1;
                              else rc_r_kneebm1 = r_kneebm1_cd.find_next();
                           end;
                        end;
                     %end;
                  end;

                  *if laser interstitial thermal therapy code checking needs to be done for remapping to 584 and 585 for bm;
                  if (lowcase(require_litt9_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt9_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt9_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if laser interstitial thermal therapy code checking needs to be done for remapping to 715, 716, 717, 718 for bm;
                  if (lowcase(require_litt10_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (litt10_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           litt10_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if pulmonary or thoracic structures code checking needs to be done for bm;
                  if (lowcase(require_pulm_thorbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (pulm_thorbm_cd.find(key: prcdrcd&b.) = 0) then do;
                           pulm_thorbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if heart assist device code checking needs to be done for bm;
                  if (lowcase(require_h_devicebm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (h_devicebm_cd.find(key: prcdrcd&b.) = 0) then do;
                           h_devicebm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if cardiac catheterization code checking needs to be done for bm;
                  if (lowcase(require_card_cathbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (card_cathbm_cd.find(key: prcdrcd&b.) = 0) then do;
                           card_cathbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if viral cardiomyopathy code checking needs to be done for bm;
                  if (lowcase(require_viral_cardbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (viral_cardbm_cd.find(key: dgnscd&b.) = 0) then do;
                           viral_cardbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if removal and replacement of the right knee joint code checking needs to be done for remapping to 461, 462, 466, 467, 468 for bm;
                  if (lowcase(require_r_kneebm2_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.; 
                        %let b = %sysfunc(putn(&a., z2.));
                        if (r_kneebm2_match = 0) and (r_kneebm2_cd.find(key: prcdrcd&b.) = 0) then do;
                           rc_r_kneebm2 = 0;
                           do while (rc_r_kneebm2 = 0);
                              %do c = 1 %to &diag_proc_length.; 
                                 %let d = %sysfunc(putn(&a., z2.));
                                 if (prcdrcd&d. = r_kneebm2_code2) then r_kneebm2_match = 1;
                              %end;
                              if (r_kneebm2_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                              if (r_kneebm2_match = 1) then rc_r_kneebm2 = 1;
                              else rc_r_kneebm2 = r_kneebm2_cd.find_next();
                           end;
                        end;
                     %end;
                  end;

                  *if left knee joint, right/left hip joint, right/left ankle joint code checking needs to be done for bm;
                  if (lowcase(require_bl_multbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (bl_multbm_cd.find(key: prcdrcd&b.) = 0) then do;
                           bl_multbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if coronary artery bypass graft code checking needs to be done for bm;
                  if (lowcase(require_cor_altbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (cor_altbm_cd.find(key: prcdrcd&b.) = 0) then do;
                           cor_altbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if open surgical ablation code checking needs to be done for bm;
                  if (lowcase(require_surg_abbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (surg_abbm_cd.find(key: prcdrcd&b.) = 0) then do;
                           surg_abbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *FY2023 BACKWARD MAPPINGS;
                  *if neoplasm kidney checking needs to be done for bm;
                  if (lowcase(require_neo_kidbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (neo_kidbm_cd.find(key: dgnscd&b.) = 0) then do;
                           neo_kidbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if neoplasm genitourinary checking needs to be done for bm;
                  if (lowcase(require_neo_genbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (neo_genbm_cd.find(key: dgnscd&b.) = 0) then do;
                           neo_genbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if encounter dialysis checking needs to be done for bm;
                  if (lowcase(require_enc_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (enc_bm_cd.find(key: dgnscd&b.) = 0) then do;
                           enc_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if sterilization checking of DRG 765 and 766 needs to be done for bm;
                  if (lowcase(require_ster_bm1_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (ster_bm1_cd.find(key: prcdrcd&b.) = 0) then do;
                           ster_bm1_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if sterilization checking of DRG 767 and 774 needs to be done for bm;
                  if (lowcase(require_ster_bm2_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (ster_bm2_cd.find(key: prcdrcd&b.) = 0) then do;
                           ster_bm2_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if extraction of endometrium checking needs to be done;
                  if (lowcase(require_extr_endobm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (extr_endobm_cd.find(key: prcdrcd&b.) = 0) then do;
                           extr_endobm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if major device implant checking needs to be done for bm;
                  if (lowcase(require_mj_devicebm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.; 
                        %let b = %sysfunc(putn(&a., z2.));
                        if (mj_devicebm_match = 0) and (mj_devicebm_cd.find(key: prcdrcd&b.) = 0) then do;
                           rc_mj_devicebm = 0;
                           do while (rc_mj_devicebm = 0);
                              %do c = 1 %to &diag_proc_length.; 
                                 %let d = %sysfunc(putn(&a., z2.));
                                 if (prcdrcd&d. = mj_devicebm_code2) then mj_devicebm_match = 1;
                              %end;
                              if (mj_devicebm_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                              if (mj_devicebm_match = 1) then rc_mj_devicebm = 1;
                              else rc_mj_devicebm = mj_devicebm_cd.find_next();
                           end;
                        end;
                     %end;
                  end;
                  
                  *if acute complex cns checking needs to be done for bm;
                  if (lowcase(require_acute_compbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (acute_compbm_cd.find(key: dgnscd&b.) = 0) then do;
                           acute_compbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if vaginal delivery checking needs to be done for bm;
                  if (lowcase(require_vgnl_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (vgnl_bm_cd.find(key: dgnscd&b.) = 0) then do;
                           vgnl_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if complicating diagnosis code checking needs to be done for bm;
                  if (lowcase(require_complicat_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (complicat_bm_cd.find(key: dgnscd&b.) = 0) then do;
                           complicat_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if MDC 03 diagnosis code checking needs to be done for bm;
                  if (lowcase(require_mdc_3bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (mdc_3bm_cd.find(key: dgnscd&b.) = 0) then do;
                           mdc_3bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if percutaneous arterial emblzation checking needs to be done for bm;
                  if (lowcase(require_perc_embolbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (perc_embolbm_cd.find(key: prcdrcd&b.) = 0) then do;
                           perc_embolbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;                              
                            
                  *if acute respiratory syndrome code checking needs to be done for bm;
                  if (lowcase(require_resp_syndbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (resp_syndbm_cd.find(key: dgnscd&b.) = 0) then do;
                           resp_syndbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if acute cardiac syndrome code checking needs to be done for bm;
                  if (lowcase(require_cardiac_mapbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (cardiac_mapbm_cd.find(key: prcdrcd&b.) = 0) then do;
                           cardiac_mapbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;                                          
                            
                  *if acute elute stent code checking needs to be done for bm;
                  if (lowcase(require_delst_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (delst_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           delst_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if arteries stents 4 plus checking needs to be done for bm;
                  if (lowcase(require_as4p_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (as4p_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           num_art_stents=sum(num_art_stents, artst_4plus_total_artstent);                           
                        end;
                     %end;
                     if num_art_stents >=4 then as4p_bm_match = 1;
                     if as4p_bm_match = 1 then backwrd_num_y_have = backwrd_num_y_have + 1;
                  end;
                  
                  *if acute elute stent code checking needs to be done for bm;
                  if (lowcase(require_dgel_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (dgel_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           dgel_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if lbw imm code checking needs to be done for bm;
                  if (lowcase(require_lbw_immbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (lbw_immbm_cd.find(key: dgnscd&b.) = 0) then do;
                           lbw_immbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if extreme immaturity code checking needs to be done for bm;
                  if (lowcase(require_extreme_immbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (ext_imm_bm_cd.find(key: dgnscd&b.) = 0) then do;
                           extreme_immbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if newborns with major problems code checking needs to be done for bm;
                  if (lowcase(require_nbmjpb_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (nbmjpb_bm_cd.find(key: dgnscd&b.) = 0) then do;
                           nbmjpb_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if supp mitral valve code checking needs to be done for bm;
                  if (lowcase(require_supp_mit_valvebm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (supp_mit_valvebm_cd.find(key: prcdrcd&b.) = 0) then do;
                           supp_mit_valvebm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if mdc07 code checking needs to be done for bm;
                  if (lowcase(require_mdc07_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (mdc07_bm_cd.find(key: dgnscd&b.) = 0) then do;
                           mdc07_bm_cd_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if occlusion and restriction of veins code checking needs to be done for bm;
                  if (lowcase(require_occ_restrbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (occ_restrbm_cd.find(key: prcdrcd&b.) = 0) then do;
                           occ_restrbm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if cde code checking needs to be done for bm;
                  if (lowcase(require_cde_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (cde_bm_cd.find(key: prcdrcd&b.) = 0) then do;
                           cde_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if liveborn infant code checking needs to be done for bm;
                  if (lowcase(require_liveborn_infantbm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (liveborn_infantbm_cd.find(key: dgnscd&b.) = 0) then do;
                           liveborn_infantbm_cd_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                  *if infectious disease code checking needs to be done for bm;
                  if (lowcase(require_inf_diseasebm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (inf_diseasebm_cd.find(key: dgnscd&b.) = 0) then do;
                           inf_diseasebm_cd_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *FY2024 BACKWARD MAPPINGS;
                  *if drug elute stent code checking needs to be done for bm;
                  if (lowcase(require_elute_stent_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_des_bm.find(key: prcdrcd&b.) = 0) then do;
                           des_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                 *if artery intraluminal code checking needs to be done for bm;
                  if (lowcase(require_ac_4p_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_i4pl_bm.find(key: prcdrcd&b.) = 0) then do;
                           i4pl_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if ami hf shock code checking needs to be done for bm;
                  if (lowcase(require_ami_hf_shock_bm_check) = "y") then do;
                     %*check for principal diagnosis;
                     if (fy24_amihfs_bm_pd.find(key: PDGNS_CD) = 0) then do;
                         amihfs_bm_match  = 1;
                         backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;                     
                     %*check for secondary diagnosis;
                     %do a = 2 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        else if (fy24_amihfs_bm_sd.find(key: dgnscd&b.) = 0) then do;
                           amihfs_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                     %end;
                  end;

                 *if cardiac catheter 277 code checking needs to be done for bm;
                  if (lowcase(require_ccath277_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_cc277_bm.find(key: prcdrcd&b.) = 0) then do;
                           cc277_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if ultra accel thrombo code checking needs to be done for bm;
                  if (lowcase(require_ultaccth_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_uat_bm.find(key: prcdrcd&b.) = 0) then do;
                           uat_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                 *if cardiac catheter 212 code checking needs to be done for bm;
                  if (lowcase(require_ccath212_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_cc212_bm.find(key: prcdrcd&b.) = 0) then do;
                           cc212_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if append complicated thrombo code checking needs to be done for bm;
                  if (lowcase(require_append_bm_check) = "y") then do;
                     if (fy24_acom_bm.find(key: PDGNS_CD) = 0) then do;
                        acom_bm_match = 1;
                        backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end;

                  *if crao brao bm code checking needs to be done for bm;
                  if (lowcase(require_cbrao_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_cbrao_bm.find(key: dgnscd&b.) = 0) then do;
                           cbrao_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                  *if resp inf code checking needs to be done for bm;
                  if (lowcase(require_resp_inf_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_rinf_bm.find(key: dgnscd&b.) = 0) then do;
                           rinf_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;
                  
                 *if implant heart assist  code checking needs to be done for bm;
                  if (lowcase(require_imp_hrt_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_imha_bm.find(key: prcdrcd&b.) = 0) then do;
                           imha_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                 *if kidney ut code checking needs to be done for bm;
                  if (lowcase(require_kidney_ut_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_kidut_bm.find(key: prcdrcd&b.) = 0) then do;
                           kidut_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                 *if vesico intestinal fistula code checking needs to be done for bm;
                  if (lowcase(require_vesi_fist_bm_check) = "y") then do;
                     if (fy24_vesif_bm.find(key: PDGNS_CD) = 0) then do;
                        vesif_bm_match = 1;
                        backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end;

                 *if open excision musc code checking needs to be done for bm;
                  if (lowcase(require_open_exc_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_openem_bm.find(key: prcdrcd&b.) = 0) then do;
                           openem_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                 *if gangrene code checking needs to be done for bm;
                  if (lowcase(require_gang_bm_check) = "y") then do;
                     if (fy24_gang_bm.find(key: PDGNS_CD) = 0) then do;
                        gang_bm_match = 1;
                        backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end;

                 *if endoscopic dilation code checking needs to be done for bm;
                  if (lowcase(require_endo_dil_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_endod_bm.find(key: prcdrcd&b.) = 0) then do;
                           endod_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                 *if hyper heart and chronic kidney code checking needs to be done for bm;
                  if (lowcase(require_hy_htkd_bm_check) = "y") then do;
                     if (fy24_hhck_bm.find(key: PDGNS_CD) = 0) then do;
                        hhck_bm_match = 1;
                        backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end;

                 *if skin subcut breast code checking needs to be done for bm;
                  if (lowcase(require_skin_bst_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_ssbr_bm.find(key: prcdrcd&b.) = 0) then do;
                           ssbr_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                 *if mdc09 code checking needs to be done for bm;
                  if (lowcase(require_mdc_09_bm_check) = "y") then do;
                     if (fy24_mdc09_bm.find(key: PDGNS_CD) = 0) then do;
                        mdc09_bm_match = 1;
                        backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end;

                 *if occl splenic artery code checking needs to be done for bm;
                  if (lowcase(require_occl_spl_bm_check) = "y") then do;
                     %do a = 1 %to &diag_proc_length.;
                        %let b = %sysfunc(putn(&a., z2.));
                        if (fy24_ocspa_bm.find(key: prcdrcd&b.) = 0) then do;
                           ocspa_bm_match = 1;
                           backwrd_num_y_have = backwrd_num_y_have + 1;
                        end;
                        %if &a. ^= &diag_proc_length. %then else;
                     %end;
                  end;

                 *if major lac spleen initial code checking needs to be done for bm;
                  if (lowcase(require_maj_spl_bm_check) = "y") then do;
                     if (fy24_mlacs_bm.find(key: PDGNS_CD) = 0) then do;
                        mlacs_bm_match = 1;
                        backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end;

                  *individual CC checking;
                  *if individual CC checking needs for FY24;
                  if %do r = 1 %to &nfy24_bm_require_types.; (lowcase(require_&&fy24_bm_require_types&r.._check) = "y") %if &r. ^= &nfy24_bm_require_types. %then or; %end; then do;
                     if (lowcase(require_cc_check) = "y") then do;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy24_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                           %if &a. ^= &diag_proc_length. %then else;
                        %end;
                        if (cc_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end; %*end of FY24 cc checking;
                  *if individual CC checking needs for FY23;
                  else if %do r = 1 %to &nfy23_bm_require_types.; (lowcase(require_&&fy23_bm_require_types&r.._check) = "y") %if &r. ^= &nfy23_bm_require_types. %then or; %end; then do;
                     if (lowcase(require_cc_check) = "y") then do;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy23_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                           %if &a. ^= &diag_proc_length. %then else;
                        %end;
                        if (cc_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end; %*end of FY23 cc checking;

                  *if individual CC checking needs for FY22;
                  else if %do r = 1 %to &nfy22_bm_require_types.; (lowcase(require_&&fy22_bm_require_types&r.._check) = "y") %if &r. ^= &nfy22_bm_require_types. %then or; %end; then do;
                     if (lowcase(require_cc_check) = "y") then do;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy22_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                           %if &a. ^= &diag_proc_length. %then else;
                        %end;
                        if (cc_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end; %*end of FY22 cc checking;
                  *if individual CC checking needs for FY21;
                  else if %do r = 1 %to &nfy21_bm_require_types.; (lowcase(require_&&fy21_bm_require_types&r.._check) = "y") %if &r. ^= &nfy21_bm_require_types. %then or; %end; then do;
                     if (lowcase(require_cc_check) = "y") then do;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy21_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                           %if &a. ^= &diag_proc_length. %then else;
                        %end;
                        if (cc_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end; %*end of FY21 cc checking;
                  *if individual CC checking needs to be done;
                  else do;
                     if (lowcase(require_cc_check) = "y") then do;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_list_cc.find(key: dgnscd&b.) = 0) or (ppfy_list_cc.find(key: dgnscd&b.) = 0) then cc_match = 1;
                           %if &a. ^= &diag_proc_length. %then else;
                        %end;
                        if (cc_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end; %*end of cc checking;

                  *individual MCC checking;
                  *if individual MCC checking needs for FY24;
                  if %do r = 1 %to &nfy24_bm_require_types.; (lowcase(require_&&fy24_bm_require_types&r.._check) = "y") %if &r. ^= &nfy24_bm_require_types. %then or; %end; then do;
                     if (lowcase(require_mcc_check) = "y") then do;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy24_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           %if &a. ^= &diag_proc_length. %then else;
                        %end;
                        if (mcc_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end; %*end of FY24 mcc checking;    
                  *if individual MCC checking needs for FY23;
                  else if %do r = 1 %to &nfy23_bm_require_types.; (lowcase(require_&&fy23_bm_require_types&r.._check) = "y") %if &r. ^= &nfy23_bm_require_types. %then or; %end; then do;
                     if (lowcase(require_mcc_check) = "y") then do;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy23_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           %if &a. ^= &diag_proc_length. %then else;
                        %end;
                        if (mcc_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end; %*end of FY23 mcc checking;                 
                  *if individual MCC checking needs for FY22;
                  else if %do r = 1 %to &nfy22_bm_require_types.; (lowcase(require_&&fy22_bm_require_types&r.._check) = "y") %if &r. ^= &nfy22_bm_require_types. %then or; %end; then do;
                     if (lowcase(require_mcc_check) = "y") then do;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy22_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           %if &a. ^= &diag_proc_length. %then else;
                        %end;
                        if (mcc_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end; %*end of FY22 mcc checking;
                  *if individual MCC checking needs for FY21;
                  else if %do r = 1 %to &nfy21_bm_require_types.; (lowcase(require_&&fy21_bm_require_types&r.._check) = "y") %if &r. ^= &nfy21_bm_require_types. %then or; %end; then do;
                     if (lowcase(require_mcc_check) = "y") then do;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy21_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           %if &a. ^= &diag_proc_length. %then else;
                        %end;
                        if (mcc_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end; %*end of FY21 mcc checking;
                  *if individual MCC checking needs to be done;
                  else do;
                     if (lowcase(require_mcc_check) = "y") then do;
                        %do a = 1 %to &diag_proc_length.;
                           %let b = %sysfunc(putn(&a., z2.));
                           if (bpfy_list_mcc.find(key: dgnscd&b.) = 0) or (ppfy_list_mcc.find(key: dgnscd&b.) = 0) then mcc_match = 1;
                           %if &a. ^= &diag_proc_length. %then else;
                        %end;
                        if (mcc_match = 1) then backwrd_num_y_have = backwrd_num_y_have + 1;
                     end;
                  end; %*end of mcc checking;

                  *NOTE: special circumstance when dealing with DRG 483. count the below matches as being equivalent to 1 overall match rather than separate multiple matches;
                  if (special_case_flag = 1) and
                     (((lowcase(require_cc_check) = "y") and (cc_match = 1)) or
                     ((lowcase(require_mcc_check) = "y") and (mcc_match = 1))) then backwrd_num_y_have = 1;

                  *determine if requirements for remapping have been met;
                  if (backwrd_num_y_need ^= 0) and (backwrd_num_y_have ^= 0) and (backwrd_num_y_need = backwrd_num_y_have) then remap = 1;

                  if (remap = 1) then do;
                     %do year = &baseline_start_year. %to &update_factor_fy.;
                        if (year(input(date_of_remap, date9.)) = &year.) and (dschrgdt >= input(date_of_remap, date9.)) and (missing(drg_&year.)) then do;
                           backwrd_remap_drg_flag = 1;
                           drg_&year. = new_drg_cd;
                        end;
                        %if &year. ^= &update_factor_fy. %then else;
                     %end;
                  end;

               end; %*end of condition D;

            end; %*end of backward mapping; %*e;

            rc_remap_drg = remap_drg.find_next();

         end; %*end of condition B;

      end; %*end of condition A;

      *NOTE: if the DRG code did not meet the requirements of a certain remapping or no remapping needs to be done for a certain year, set remap_drg_ to the most recent version of a DRG code;
      %do year = &query_start_year. %to &update_factor_fy.;
         %let prev_year = %eval(&year.-1);
         if "01OCT&prev_year."D <= dschrgdt <= "30SEP&year."D then do;           
            fy_dschrgdt = &year.; 
            drg_&year. = drg_cd;
            *go backwards;
            %if &year. ^= &baseline_start_year. %then %do;
               %do yr = %eval(&year.-1) %to &baseline_start_year. %by -1;
                  if (missing(drg_&yr.)) then drg_&yr. = drg_%eval(&yr.+1);
               %end;
            %end;
            *go forwards;
            %if &year. ^= &update_factor_fy. %then %do;
               %do yr = %eval(&year.+1) %to &update_factor_fy.;
                  if (missing(drg_&yr.)) then drg_&yr. = drg_%eval(&yr.-1);
               %end;
            %end;
         end;
      %end;
      
      *link MDC by remapped DRG;
      if (drg_mdc.find(key: drg_&update_factor_fy.) = 0) then mdc = strip(mdc);

      *obtain DRG weights; 
      %do year = &baseline_start_year. %to &update_factor_fy.;
         if drg_wgt&year..find(key: drg_&year.) ^= 0 then do;
            *output stays with missing weights; 
            %*DRG weight should not be missing for the non-mapped DRG (i.e. DRG_CD) and the DRG mapped to the update factor FY; 
            %*DRG weights can be missing for stays outside of the study period and invalid stays (e.g. 000), otherwise, check DRG mapping rules and logic;             
            if (drg_cd ^= "000") and ((&year. = fy_dschrgdt) or (&year. = &update_factor_fy.)) then output temp.ip_stays_w_missing_wght;            
         end;
      %end;
      
      output temp.cleaned_ip_stays_w_remap;

   run;



%mend;
