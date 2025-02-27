/*************************************************************************;
%** PROGRAM: c2_flag_provider_types.sas
%** PURPOSE: To create provider type indicators for IP stays and OP claim-lines
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro c2_flag_provider_types();
   
   *define name of provider code dataset to be hashed in;
   %macarray(ds_names,     ipps        state          cah         ltch        irf         children_hospital    inpatient_psych   sirf        ssnf        ipu         home_health    skilled_nursing   cancer_hospital      emergency_hosp    veteran_hosp);
   *define name of hash for the provider code dataset;
   %macarray(hash_names,   ipps        state          cah         ltch        irf         child                ipf               sirf        ssnf        ipu         hh             snf               cancer               emerg        veteran);
   
   *variables to be kept;
   %let clean_ip_keep_vars = link_id ip_stay_id drg: mdc provider admsn_dt dschrgdt daily_dt from_dt thru_dt stus_cd at_npi op_npi sum_util clm_prpay clm_allowed deductible coinsurance 
                             standard_allowed_amt standard_allowed_amt_w_o_outlier outlier_pmt allowed_amt allowed_amt_w_o_outlier dgnscd: ad_dgns prcdrcd: pdgns_cd stay_outlier stay_new_tech_pmt stay_clotting_pmt
                             missing_provider_flag excluded_provider ipps_provider overlap_keep_acute overlap_keep_inner overlap_keep_outer overlap_keep_inner_outer;   
   %let opl_keep_vars = link_id claimno lineitem provider hcpcs_cd apchipps line_std_allowed line_allowed rev_msp1 rev_msp2 from_dt thru_dt at_npi op_npi rev_dt stus_cd daily_dt rev_chrg rstusind
                        missing_provider_flag excluded_provider pdgns_cd dgnscd: mdfr_cd:;
   
   data temp.cleaned_ip_stays_w_remap (keep = &clean_ip_keep_vars. %do a = 1 %to &nflag_vars.; &&flag_vars&a.._flag %end;)
        temp.excluded_provider_ip_stays (keep = &clean_ip_keep_vars. %do a = 1 %to &nflag_vars.; &&flag_vars&a.._flag %end;)
        temp.opl (keep = &opl_keep_vars. %do a = 1 %to &nflag_vars.; &&flag_vars&a.._flag %end;);

      length prov_last_4_chars prov_first_2_chars prov_third_char $6. %do a = 1 %to &nflag_vars.; &&flag_vars&a.._flag %end; missing_provider_flag excluded_provider ipps_provider 8.;
      if _n_ = 1 then do;

         *list of provider codes;
         %do a = 1 %to &nds_names.;
            if 0 then set temp.&&ds_names&a.._codes (keep = &&hash_names&a.._code);
            declare hash &&hash_names&a.._codes (dataset: "temp.&&ds_names&a.._codes (keep = &&hash_names&a.._code)");
            &&hash_names&a.._codes.definekey("&&hash_names&a.._code");
            &&hash_names&a.._codes.definedone();
         %end;

         *list of provider numbers to specifically exclude;
         if 0 then set temp.excluded_providers (keep = provider_num);
         declare hash ex_provs (dataset: "temp.excluded_providers (keep = provider_num)");
         ex_provs.definekey("provider_num");
         ex_provs.definedone();

      end; 
      call missing(of _all_);

      set temp.cleaned_ip_stays_w_remap (in = in_clean_ip)
          clm_inp.opl (in = in_opl)
          ;

      *initialize flags;
      %do a = 1 %to &nflag_vars.;
         &&flag_vars&a.._flag = 0;
      %end;
      missing_provider_flag = 0;
      excluded_provider = 0;
      ipps_provider = 0;

      *substring specific digits from provider CCN;
      prov_last_4_chars = substr(provider, 3, 4);
      prov_first_2_chars = substr(provider, 1, 2);
      prov_third_char = substr(provider, 3, 1);
      prov_fifth_char = substr(provider, 5, 1);
      prov_sixth_char = substr(provider, 6, 1);

      *flag provider types;
      *NOTE: for IPPS, CAH, LTCH, IRF, children hospitals, IPF, SNF, and HH, provider number cannot contain any characters, only digits;
      if (lengthn(compress(provider, , "AL")) = &provider_length. and ipps_codes.find(key: prov_last_4_chars) = 0) or (ipps_codes.find(key: provider) = 0) then ipps_flag = 1;
      if (state_codes.find(key: prov_first_2_chars) = 0) then state_flag = 1;
      if (lengthn(compress(provider, , "AL")) = &provider_length.) and (cah_codes.find(key: prov_last_4_chars) = 0) then cah_flag = 1;
      if (lengthn(compress(provider, , "AL")) = &provider_length.) and ((ltch_codes.find(key: prov_last_4_chars) = 0) or (prov_third_char = "W")) then ltch_flag = 1;
      if (lengthn(compress(provider, , "AL")) = &provider_length.) and ((irf_codes.find(key: prov_last_4_chars) = 0) or (prov_third_char in ("T", "R"))) then irf_flag = 1;
      if (lengthn(compress(provider, , "AL")) = &provider_length.) and (child_codes.find(key: prov_last_4_chars) = 0) then child_hosp_flag = 1;
      if (lengthn(compress(provider, , "AL")) = &provider_length.) and (ipf_codes.find(key: prov_last_4_chars) = 0) then ipf_flag = 1;
      if (sirf_codes.find(key: prov_third_char) = 0) then sirf_flag = 1;
      if (ssnf_codes.find(key: prov_third_char) = 0) then ssnf_flag = 1;
      if (ipu_codes.find(key: prov_third_char) = 0) then ipu_flag = 1;
      if (length(compress(provider, , "AL")) = &provider_length.) and (hh_codes.find(key: prov_last_4_chars) = 0) then home_health_flag = 1;
      if (lengthn(compress(provider, , "AL")) = &provider_length.) and (snf_codes.find(key: prov_last_4_chars) = 0) then snf_flag = 1;
      if (cancer_codes.find(key: provider) = 0) then cancer_hosp_flag = 1;
      if (emerg_codes.find(key: prov_sixth_char) = 0) then emerg_hosp_flag = 1;
      if (veteran_codes.find(key: prov_fifth_char) = 0) then veteran_hosp_flag = 1;

      *create a missing flag to indicate if none of the provider types apply to a certain provider;
      if %do a = 1 %to &nflag_vars.;
            %if "&&flag_vars&a.." ^= "state" %then %do;
                (&&flag_vars&a.._flag = 0)
                %if &a. ^= &nflag_vars. %then and;
            %end;
        %end;
      then missing_provider_flag = 1;

      if (in_clean_ip = 1) then do;
         *exclude ip stays belonging to providers in the excluded provider list;
         if (ex_provs.find(key: provider) = 0) then excluded_provider = 1;
         *apply slightly modified definition for ipps provider to exclude Maryland, emergency, veteran, and cancer hospitals;
         if (state_flag = 0) and (emerg_hosp_flag = 0) and (veteran_hosp_flag = 0) and (cancer_hosp_flag = 0) and (ipps_flag = 1) then ipps_provider = 1;
      end;

      *output observations accordingly;
      if (in_clean_ip = 1) then do;
         if (excluded_provider = 0) then output temp.cleaned_ip_stays_w_remap;
         else if (excluded_provider = 1) then output temp.excluded_provider_ip_stays;
      end;
      else if (in_opl = 1) then output temp.opl;

   run;
   
%mend;