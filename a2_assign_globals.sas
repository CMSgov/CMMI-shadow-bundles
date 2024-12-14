/*************************************************************************;
%** PROGRAM: a2_assign_globals.sas
%** PURPOSE: To define global variables to be accessed by other macros
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

%macro a2_assign_globals();

   /*****EPISODE CONSTRUCTION PARAMETERS*****/
            
   %global /*PARAMETERS RELATED TO RUNNING MAIN CALLER*/ 
            base_or_perf outdir 
           /*PARAMETERS RELATED TO INPUT DATASET VERSIONS*/
            edb_version fa_week q_run_date query_start_year query_end_year 
            hemo_quart_end pos_version psf_version psf_year psf_quarter bpci_trig_version med_code_version updt_fctr_version hcpcs_apc_version drg_map_version addj_year_list addj_rundate_list clin_dir    
           /*PARAMETERS RELATED TO DEFINING THE BASELINE PERIOD*/
            baseline_start_dt baseline_end_dt baseline_start_year baseline_end_year 
           /*PARAMETERS RELATED TO DEFINING THE PERFORMANCE PERIOD*/
            perf_start_dt perf_end_dt perf_start_year perf_end_year
           /*PARAMETERS RELATED TO DEFINING AN EPISODE*/
            post_dschrg_days post_epi_days part_a_b_codes max_stay_length lookback_days gsc_ed_lookback_days attr_lookback_days
           /*PARAMETERS RELATED TO DEFINING THE PHYSICIAN FEE FOR SERVICE INPUT DATASET*/
            start_pfs_year start_pfs_quarter end_pfs_year end_pfs_quarter
           /*PARAMETERS FOR DEFINING RISK-ADJUSTMENT VARIABLES*/   
            ibratio_thresh safety_net_thresh cc_version cc_max_num all_hccs hcc_interact_list dementia_cc dementia_list            
           /*PARARMETERS RELATED TO DEFINING THE PRICE UPDATE*/
            update_factor_cy update_factor_fy ipps_oper_base_full_2020 ipps_oper_base_full_2021 ipps_oper_base_full_2022 ipps_oper_base_full_2023 ipps_oper_base_full_2024 
            irf_base_full_2020 irf_base_full_2021 irf_base_full_2022 irf_base_full_2023 irf_base_full_2024
            updt_cons_quart peer_group_list cmg_urban_rates cmg_rural_rates cmg_days 
            sn_non_case_mix_urban_2020 sn_non_case_mix_rural_2020 sn_non_case_mix_urban_2021 sn_non_case_mix_rural_2021 sn_non_case_mix_urban_2022 sn_non_case_mix_rural_2022
            sn_non_case_mix_urban_2023 sn_non_case_mix_rural_2023 sn_non_case_mix_urban_2024 sn_non_case_mix_rural_2024 aids_nursing_adj           
            hh_cur_yr_wgt hh_prev_yr_wgt pb_cur_yr_wgt pb_prev_yr_wgt other_cur_yr_wgt pdpm_non_case_mix num_epis_hh hhrg_end_year           
            hh_base_rate_2019 hh_base_rate_2020 hh_base_rate_2021 hh_base_rate_2022 hh_base_rate_2023 hh_base_rate_2024
           /*PARAMETERS RELATED TO WINSORIZATION OF EPISODE COSTS*/
            winsorization_lower_threshs winsorization_upper_threshs
           /*PARAMETERS RELATED TO ACO*/
            mssp_program_id reach_program_id
           /*MISCELLANEOUS*/          
            icd9_icd10_date num_transplnt_days readmission_period provider_length mdfr_cd_length_pb mdfr_cd_length_op rev_array_size diag_proc_length sec_hcpcs_array_size demo_array_size visit_length diag_length_pb_dm cens_div_num          
           /*CALCULATE YEAR-QUARTERS FOR RISK ADJUSTMENT TREND FACTOR (DO NOT TOUCH)*/
            quart_trend_start_yr quart_trend_end_yr quart_trend_yrs quart_trend_qus quart_trend_incr
            ;   
          
   /*PARAMETERS RELATED TO RUNNING MAIN CALLER*/
   
   *determine whether episodes are generated for baseline periods (i.e. base) or performance periods (i.e. perf);
   %*action: change based on the period of episodes to be constructed;
   %let base_or_perf = base;
   *define location to save output datasets; 
   %*action: change according to users; 
   %let outdir = c:\project;   
   
   /*PARAMETERS RELATED TO INPUT DATASET VERSIONS*/
      *the following parameters can be adjusted based on the data source;      
      *please refer to the libnames to see where they are being used;
      
   *define the enrollement database (EDB) version used in data query;
   %*action: change according to data source; 
   %let edb_version = 2024_02;
   *define the query final action week;
   %*action: change according to data source; 
   %let fa_week = 24w11;
   *query run date;
   %*action: change according to data source; 
   %let q_run_date = 2024_06_20;
   *define the start year of queried claims;
   %*action: change according to data source; 
   %let query_start_year = 2019;
   *define the end year of queried claims;
   %*action: change according to data source; 
   %let query_end_year = 2024;
   *define the last quarter of available data for the given query_end_year for the hemohilia/clotting factor input dataset;
   %*note: the value is determined by the latest available service in the claim query, for example, the data is queried as of 2024_06_20 which contains claim services up to 2024Q2;  
   %*action: change according to data source; 
   %let hemo_quart_end = 2;
   *define the Provider of Services (POS) dataset version;
   %*note: this is the latest available version at the point of running the program; 
   %*action: change according to data source; 
   %let pos_version = 202406;
   *define the Provider specific files (PSF) version;
   %*note: this is the latest available version at the point of running the program; 
   %*action: change according to data source; 
   %let psf_version = 2024_04_01; 
   *define the year to use for the PSF file;
   %*note: this is the latest available version at the point of running the program; 
   %*action: change according to data source; 
   %let psf_year = 2024;
   *define the quarter to use for the PSF file;
   %*note: this is the latest available version at the point of running the program; 
   %*action: change according to data source; 
   %let psf_quarter = 2;
   *define the version date of the BPCIA trigger list clinical logic workbook;
   %*action: change according to data source; 
   %let bpci_trig_version = 2024_06_14; 
   *define the version date of the BPCIA Medial code list clinical logic workbook;
   %*action: change according to data source; 
   %let med_code_version = 2024_08_19; 
   *define the version date of the update factor workbook;
   %*action: change according to data source; 
   %let updt_fctr_version = 2024_06_14;  
   *define the version date of the HCPCS to APC crosswalk workbook;
   %*action: change according to data source; 
   %let hcpcs_apc_version = 2024_06_14;  
   *define the version date of the DRG mapping workbook;
   %*action: change according to data source; 
   %let drg_map_version = 2024_05_20;  
   *define all years to use for addendum J primary ranking workbook in list format;
   %*note: baseline addj_year_list takes the same value as the pricing update calendar year; 
   %*action: change according to pricing update calendar year (i.e. update_factor_cy); 
   %let addj_year_list = 2024;  
   *define the run date associated with each year listed for the above addendum J primary ranking workbook in parallel with the year listed in addj_years parameter;
   %*action: change according to data source; 
   %let addj_rundate_list = 2024_01_03;  
   *define the location of clinical logic workbooks; 
   %*action: change according to data source; 
   %let clin_dir = c:\project\clinical_logic;
    
   /*PARAMETERS RELATED TO DEFINING THE BASELINE PERIOD*/
      *baseline or historical period to construct preliminary benchmark price;
      *baseline period can be set according to resreach interest; 
      
   *define the start date of the baseline period;
   %*action: change according to resreach interest; 
   %let baseline_start_dt = 01OCT2019;
   *define the end date of the baseline_period;
   %*action: change according to resreach interest; 
   %let baseline_end_dt = 30SEP2023;
   *calculate the start year of the baseline period;
   %*no action;
   %let baseline_start_year = %sysfunc(year("&baseline_start_dt."D));
   *calculate the end year of the baseline period;
   %*no action;
   %let baseline_end_year = %sysfunc(year("&baseline_end_dt."D));
   
   /*PARAMETERS RELATED TO DEFINING THE PERFORMANCE PERIOD*/
      *performance period can be set according to resreach interest; 
   
   *define the start date of the performance period;
   %*action: change according to resreach interest; 
   %let perf_start_dt = 01JAN2025;
   *define the end date of the performance period;
   %*action: change according to resreach interest; 
   %let perf_end_dt = 31DEC2025;
   *calculate the year of the performance period start date;
   %*no action; 
   %let perf_start_year = %sysfunc(year("&perf_start_dt."D));
   *calculate the year of the performance period end date;
   %*no action; 
   %let perf_end_year = %sysfunc(year("&perf_end_dt."D));

   /*PARAMETERS RELATED TO DEFINING AN EPISODE*/
      *the following parameters are specific to BPCIA methodology;  
      *no action is needed unless intentional commitment is made; 
      
   *define the number of post-discharged days;
   %*no action;
   %let post_dschrg_days = 90;
   *define the number of days after the post-discharged window of an episode;
   %*no action;
   %let post_epi_days = 30;
   *define Medicare Part A and B codes;
   %*note: these codes are specific to Medicare claims; 
   %*action: change if different from Medicare; 
   %let part_a_b_codes = EM;
   *define maximum allowable length of days for an ip stay; 
   %*no action;
   %let max_stay_length = 60;
   *define the number of days to lookback (for risk-adjustment and episode exclusion purposes);
   %*no action;
   %let lookback_days = 180;
   *define the number of days to lookback for GSC and ED claims;
   %*no action;
   %let gsc_ed_lookback_days = 1;
   *define the number of days to lookback for attribution;
   %*no action; 
   %let attr_lookback_days = 1;
   
   /*PARAMETERS RELATED TO DEFINING THE PHYSICIAN FEE FOR SERVICE INPUT DATASET*/

   *define the starting physician fee schedule (PFS) year to use;
   %*no action;
   %let start_pfs_year = &query_start_year.;
   *define the starting physician fee schedule (PFS) quarter to use;
   %*no action;
   %let start_pfs_quarter = 1;
   *define the ending physician fee schedule (PFS) year to use;
   %*no action;
   %let end_pfs_year = &query_end_year.;
   *define the ending physician fee schedule (PFS) quarter to use;
   %*note: the value is determined by the latest available service in the claim query, for example, the data is queried as of 2024_06_20 which contains claim services up to 2024Q2;  
   %*action: change according to data source; 
   %let end_pfs_quarter = 2;

   /*PARAMETERS FOR DEFINING RISK-ADJUSTMENT VARIABLES*/
      *the following parameters are specific to BPCIA methodology; 
      *no action is needed unless intentional commitment is made; 
      *CCs or HCCs can change their definition in different cc versions, modify the params below as needed if a different cc version is used; 
      
   *define the threshold of intern to bed ratio used to identify major teaching hospital flag;
   %*no action;
   %let ibratio_thresh = 0.25;
   *define a list out all the dual eligibility thresholds (in percent) to use for calculating safety net variable for risk-adjustment; 
   %*no action;
   %let safety_net_thresh = 60;
   *define which CC version to use for construction of HCC in risk-adjustment;
   %*no action;
   %let cc_version = 22;   
   *define the total number of ccs;
   %*no action;
   %let cc_max_num = 189;
   *define a list of HCCs to use in risk-adjustment;
   %*note: the list of hccs below is corresponding to CC version 22 and may change for different cc versions; 
   %*no action;
   %let all_hccs =   hcc1 hcc2 hcc6 hcc8 hcc9 hcc10 hcc11 hcc12 hcc17 hcc18 hcc19 hcc21 hcc22 hcc23 hcc27 hcc28 hcc29 hcc33 hcc34 hcc35 hcc39 hcc40 hcc46 hcc47 hcc48 hcc54 hcc55 hcc57 hcc58 hcc70 hcc71 
                     hcc72 hcc73 hcc74 hcc75 hcc76 hcc77 hcc78 hcc79 hcc80 hcc82 hcc83 hcc84 hcc85 hcc86 hcc87 hcc88 hcc96 hcc99 hcc100 hcc103 hcc104 hcc106 hcc107 hcc108 hcc110 hcc111 hcc112 hcc114 hcc115
                     hcc122 hcc124 hcc134 hcc135 hcc136 hcc137 hcc157 hcc158 hcc161 hcc162 hcc166 hcc167 hcc169 hcc170 hcc173 hcc176 hcc186 hcc188 hcc189;
   *define a list of covariates to create nteraction terms with HCCs;
   %*no action;
   %let hcc_interact_list = cancer diabetes immune card_resp_fail chf copd renal compl sepsis sepsis_card_resp_fail cancer_immune diabetes_chf chf_copd chf_renal copd_card_resp_fail disabled_hcc6 disabled_hcc34 disabled_hcc46 disabled_hcc54 disabled_hcc55
                            disabled_hcc110 disabled_hcc176 n_organ_fail mof copd_x_asp_bac_pneum schizo_x_seiz_dis_convul sepsis_x_art_openings sepsis_x_asp_bac_pneum sepsis_x_press_ulcer;    
   *define which CC version to use for construction of dementia variables in risk-adjustment;
   %*note: dementia cc are available in version 24 and after; 
   %*no action;
   %let dementia_cc = 24; 
   *define a list of hcc variables in risk-adjustment - dementia;
   %*no action;
   %let dementia_list = cc51 cc52 hcc51 hcc52 dementia_w_cc dementia_wo_cc;                         
   
   /*PARARMETERS RELATED TO DEFINING THE PRICE UPDATE*/ 

   *define the calendar year for updating baseline episode payment rates;
   %*action: change according to performance periods; 
   %let update_factor_cy = 2024;
   *define the calendar year for updating baseline episode payment rates;
   %*action: change according to performance periods; 
   %let update_factor_fy = 2024;
   *define the latest available quarter of PB conversion factor in the update factor calendar year;
   %*action: change according to data source; 
   %let updt_cons_quart = 2;
   *define IPPS operating base full rates;
   %*note: these values must be specified for the update factor fiscal year and all fiscal years relevant to the baseline period;
   %*action: change according to baseline period and CMS final rules; 
   %let ipps_oper_base_full_2020 = 5796.63;
   %let ipps_oper_base_full_2021 = 5961.31;
   %let ipps_oper_base_full_2022 = 6121.65;
   %let ipps_oper_base_full_2023 = 6375.74;
   %let ipps_oper_base_full_2024 = 6497.77;
   *define IRF base rates;
   %*note: these values must be specified for the update factor fiscal year and all fiscal years relevant to the baseline period;
   %*action: change according to baseline period and CMS final rules; 
   %let irf_base_full_2020 = 16489;
   %let irf_base_full_2021 = 16856;
   %let irf_base_full_2022 = 17240;
   %let irf_base_full_2023 = 17878;
   %let irf_base_full_2024 = 18541; 
   *define a list of provider characteristics to calculate SNF and HH update factors;
   %*no action; 
   %let peer_group_list = urban mth 
                          cens_div_1 cens_div_2 cens_div_3 cens_div_4 cens_div_5 cens_div_6 cens_div_7 cens_div_8 cens_div_9 cens_div_other
                          safety_net_&safety_net_thresh.;                
   *define a list of variables to calculte PDPM rate;
   %*no action;
   %let cmg_urban_rates = pt_cmi_urban pt_rate_urban ot_cmi_urban ot_rate_urban nta_cmi_urban nta_rate_urban slp_cmi_urban slp_rate_urban nrsg_cmi_urban nrsg_rate_urban;
   %let cmg_rural_rates = pt_cmi_rural pt_rate_rural ot_cmi_rural ot_rate_rural nta_cmi_rural nta_rate_rural slp_cmi_rural slp_rate_rural nrsg_cmi_rural nrsg_rate_rural;
   %let cmg_days = sum_pt_af sum_ot_af sum_nta_af sum_slp_af sum_nrsg_af;    
   *define the weight to give to the current year for the HH update factor;
   %*no action;
   %let hh_cur_yr_wgt = 0.75;
   *define the weight to give to the previous year for the HH update factor;
   %*no action;
   %let hh_prev_yr_wgt = 0.25;
   *define the weight to give to the current year for the PB update factor;
   %*no action;
   %let pb_cur_yr_wgt = 0.75;
   *define the weight to give to the previous year for the PB update factor;
   %*no action;
   %let pb_prev_yr_wgt = 0.25;   
   *define the weight to give to the current year for the update factor of other costs;
   %*no action;
   %let other_cur_yr_wgt = 0.25;  
   *define the SN urban and rural non-casemix;
   %*note: these values must be specified for update factor fiscal year and all fiscal years relevant to the baseline period;
   %*action: change according to baseline periods and CMS final rules; 
   %let sn_non_case_mix_urban_2020 = 94.84;
   %let sn_non_case_mix_rural_2020 = 96.59;
   %let sn_non_case_mix_urban_2021 = 96.85;
   %let sn_non_case_mix_rural_2021 = 98.64;
   %let sn_non_case_mix_urban_2022 = 98.07;
   %let sn_non_case_mix_rural_2022 = 99.88;
   %let sn_non_case_mix_urban_2023 = 103.12;
   %let sn_non_case_mix_rural_2023 = 105.03;
   %let sn_non_case_mix_urban_2024 = 109.69;
   %let sn_non_case_mix_rural_2024 = 111.72;   
   *define ADIS adjustment that is applicable to nursing component of PDPM rate;
   %*action: check if the rate changes, otherwise no action needed;   
   %let aids_nursing_adj = 0.18;
   *define the pdpm non-casemix by taking the average of urban and rural non-casemix in the update factor fiscal year;
   %*action: change according to the pricing update fiscal year (i.e. update_factor_fy);   
   %let pdpm_non_case_mix = 110.705;  
   *define episode volume required for hospitals to be included when imputing HH uf;
   %*action: change according to the number of baseline years, for example, in BPCIA 40 episodes for 4-year baseline;
   %let num_epis_hh = 40;
   *define end year of hhrg system;
   %*no action;
   %let hhrg_end_year = 2019;
   *define HH base rates;
   %*note: these values must be specified for update factor calendar year and all calendar years relevant to the baseline period;
   %*action: change according to baseline periods and CMS final rules; 
   %let hh_base_rate_2019=3154.27;
   %let hh_base_rate_2020=1864.03;
   %let hh_base_rate_2021=1901.12;
   %let hh_base_rate_2022=2031.64;
   %let hh_base_rate_2023=2010.69;
   %let hh_base_rate_2024=2038.13;


   /*PARAMETERS RELATED TO WINSORIZATION OF EPISODE COSTS*/
      *the following parameters are specific to BPCIA methodology; 
      *no action is needed unless intentional commitment is made; 
      
   *define the lower percentiles to winsorize/bottom code costs to;
   %*no action;
   %let winsorization_lower_threshs = 1;
   *define the upper percentiles to winsorize/bottom code costs to;
   %*no action;
   %let winsorization_upper_threshs = 99;

   /*PARAMETERS RELATED TO ACO*/
      *add or modify the ACO program ids or other info; 
      
   *define MSSP program id;
   %*no action;
   %let mssp_program_id = "08";
   *define REACH program id;
   %*no action;
   %let reach_program_id = "63";

   /*MISCELLANEOUS*/
      *the following parameters are specific to BPCIA methodology and data sources/formats that are used at Acumen, LLC; 
      *no action is needed unless a different data source/format is used or intentional commitment is made; 
   
   *define date of transition from ICD9 to ICD10 codes;
   %*no action;
   %let icd9_icd10_date = 01OCT2015;
   *define the number of days to used for defining the length of an ESRD transplant coverage period;
   %*no action;
   %let num_transplnt_days = 1095;
   *define readmission period length in days;
   %*no action;
   %let readmission_period = 90;
   *define the total length or maximum number of characters the provider identifier variable contains;
   %*no action;
   %let provider_length = 6;
   *define the length of the modifier code array for PB claims;
   %*no action;
   %let mdfr_cd_length_pb = 4;
   *define the length of the modifier code array for OP claims;
   %*no action;
   %let mdfr_cd_length_op = 5;
   *define length of array for rev_dt;
   %*no action;
   %let rev_array_size = 45;
   *define length of diagnosis and procedure code array;
   %*no action;
   %let diag_proc_length = 25;
   *define the maximum array size for the secondary J1/add-on HCPCS associated with a triggering HCPCS;
   %*no action;
   %let sec_hcpcs_array_size = 8;
   *define the maximum array size for the demonstration numbers;
   %*no action;
   %let demo_array_size = 5;
   *define length of reason for visit diagnosis code array for OP claims;
   %*no action;
   %let visit_length = 3;
   *define length of diagnosis code array for PB and DM claims;
   %*no action;
   %let diag_length_pb_dm = 12;
   *define number of census divisions; 
   %*no action;
   %let cens_div_num = 9;    

   /*CALCULATE YEAR-QUARTERS FOR RISK ADJUSTMENT TREND FACTOR*/
      *the following parameters are specific to BPCIA methodology; 
      *no action is needed unless intentional commitment is made; 

   *define the starting year for quarter time trend variable in risk-adjustment;
   %*no action;
   %let quart_trend_start_yr = &query_start_year.; 
   *define the end year for quarter time trend variable in risk-adjustment;
   %*no action;
   %let quart_trend_end_yr = &query_end_year.;
   *define the center year for quarter time trend variable in risk-adjustment;
   %*no action;
   %let quart_trend_center_yr = %eval(&query_end_year. - 1);
   *define the center quarter for the quarter time trend variable in risk-adjustment;
   %*no action;
   %let quart_trend_center_qu = 3;
   *create a list of all the years used for the quarter trend time factor in risk-adjustment;
   %*no action;
   %let quart_trend_yrs = ;
   *create a list of all the quarters used for the quarter trend time factor in risk-adjustment;
   %*no action;
   %let quart_trend_qus = ;
   *create a list of the time increments to use for the quarter trend time factor in risk-adjustment;
   %*no action;
   %let quart_trend_incr = ;
   *calculate the number of increments from the start to the center;
   %*no action;
   %let num_incr_to_cntr = %eval((&quart_trend_center_yr. - &query_start_year.)*4 + &quart_trend_center_qu.);
   %let incr = %eval(-1*(&num_incr_to_cntr. - 1));
   %do yr = &query_start_year. %to &query_end_year.;
      %do qu = 1 %to 4;
         %let quart_trend_yrs = &quart_trend_yrs. &yr.;
         %let quart_trend_qus = &quart_trend_qus. &qu.;
         %let quart_trend_incr = &quart_trend_incr. &incr.;
         %let incr = %eval(&incr. + 1);
      %end;
   %end;
   %put THE QUARTER TREND FACTOR YEARS: &quart_trend_yrs.;
   %put THE QUARTER TREND FACTOR QUARTERS: &quart_trend_qus.;
   %put THE QUARTER TREND FACTOR INCREMENTS: &quart_trend_incr.;
   
%mend;
