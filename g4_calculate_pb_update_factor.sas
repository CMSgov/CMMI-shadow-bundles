/*************************************************************************;
%** PROGRAM: g4_calculate_pb_update_factor.sas
%** PURPOSE: To calculate PB update factor for post-anchor period cost
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro g4_calculate_pb_update_factor();
   
   /*SPLIT PB INTO ANESTHESIA AND OTHER SERVICES*/
   
   data temp.pb_price_update_lines (drop = betos_code betos_code_descrip)
        temp.anes_price_update_lines (drop = betos_code betos_code_descrip);
 
       if _n_ = 1 then do;
 
          *list of BETOS codes for evaluation and management, procedures, and imaging;
          if 0 then set temp.betos_codes (keep = betos_code betos_code_descrip where = (lowcase(betos_code_descrip) in ("evaluation and management" "procedures" "imaging")));
          declare hash mpi_cds (dataset: "temp.betos_codes (keep = betos_code betos_code_descrip where = (lowcase(betos_code_descrip) in ('evaluation and management' 'procedures' 'imaging')))");
          mpi_cds.definekey("betos_code");
          mpi_cds.definedone();
 
          *list of BETOS codes for anesthesia;
          if 0 then set temp.betos_codes (keep = betos_code betos_code_descrip where = (lowcase(betos_code_descrip) = "anesthesia"));
          declare hash anes_cds (dataset: "temp.betos_codes (keep = betos_code betos_code_descrip where = (lowcase(betos_code_descrip) = 'anesthesia'))");
          anes_cds.definekey("betos_code");
          anes_cds.definedone();
 
          *list of BETOS codes for other tests, chiropractic, vision/hearing/speech services, and lab tests;
          if 0 then set temp.betos_codes (keep = betos_code betos_code_descrip where = (lowcase(betos_code_descrip) in ("other tests" "chiropractic" "vision, hearing, and speech services" "other lab tests (medicare fee schedule)")));
          declare hash pb_betos (dataset: "temp.betos_codes (keep = betos_code betos_code_descrip where = (lowcase(betos_code_descrip) in ('other tests' 'chiropractic' 'vision, hearing, and speech services' 'other lab tests (medicare fee schedule)')))");
          pb_betos.definekey("betos_code");
          pb_betos.definedone();
 
       end;
       call missing(of _all_);
 
       set temp.grp_pb_for_updates; 
 
       *filter PB claims to those for use in RVU updates and anesthesia updates;
       if ((mpi_cds.find(key: substr(betos, 1, 1)) = 0) and (anes_cds.find(key: substr(betos, 1, 2)) ^= 0)) or 
          (pb_betos.find(key: substr(betos, 1, 2)) = 0) or
          (pb_betos.find(key: betos) = 0) 
       then output temp.pb_price_update_lines;
       else if (anes_cds.find(key: substr(betos, 1, 2)) = 0) then output temp.anes_price_update_lines;
 
   run;
 
   /*PROCESS RVU PB CLAIMS*/
 
   *merge PB with RVU for each year by mod and hcpcs_cd drop PB without RVU date;
   *calculate PE RVU based on whether or not the place of service is a facility;
   data temp.pb_rvu_w_gpci (drop = rc_: non_fac_code mdfr_code carrier locality);
       
       length facility_flag 8.;
       if _n_ = 1 then do;
          
          %do year = &baseline_start_year. %to &baseline_end_year.;
             *NOTE: use the 4th quarter since this is typically the quarter associated with the most recent, up-to-date PFS file; 
             %let quarter = 4;
             if 0 then set rvu.pfs_&year.q&quarter. (keep = hcpcs_cd mod work_rvu nf_pe_rvu f_pe_rvu mp_rvu rename = (work_rvu = work_rvu_&year. nf_pe_rvu = non_fac_pe_rvu_&year. f_pe_rvu = fac_pe_rvu_&year. mp_rvu = mp_rvu_&year.));
             declare hash getrvu&year. (dataset: "rvu.pfs_&year.q&quarter. (keep = hcpcs_cd mod work_rvu nf_pe_rvu f_pe_rvu mp_rvu rename = (work_rvu = work_rvu_&year. nf_pe_rvu = non_fac_pe_rvu_&year. f_pe_rvu = fac_pe_rvu_&year. mp_rvu = mp_rvu_&year.))");
             getrvu&year..definekey("hcpcs_cd", "mod");
             getrvu&year..definedata("work_rvu_&year.", "non_fac_pe_rvu_&year.", "fac_pe_rvu_&year.", "mp_rvu_&year.");
             getrvu&year..definedone();
          %end;
 
          *list of place of service codes for non-facility;
          if 0 then set temp.plcsrvc_non_facility_codes (keep = non_fac_code);
          declare hash nonfac_cds (dataset: "temp.plcsrvc_non_facility_codes (keep = non_fac_code)");
          nonfac_cds.definekey("non_fac_code");
          nonfac_cds.definedone();
 
          *list of modifier codes for technical and professional cs;
          if 0 then set temp.pb_modifier_codes (keep = mdfr_code);
          declare hash pb_mod (dataset: "temp.pb_modifier_codes (keep = mdfr_code)");
          pb_mod.definekey("mdfr_code");
          pb_mod.definedone();
 
          *list of GPCI across years;
          %do year = %eval(&baseline_start_year.-1) %to &update_factor_cy.;
             *NOTE: special circumstance for 2015 and 2018. use the version 2 of the GPCIs;
             %if &year. in (2015 2018) %then %do;
                if 0 then set gpci.gpcis_&year._2 (keep = carrier locality work_gpci pe_gpci mp_gpci rename = (work_gpci = work_gpci_&year. pe_gpci = pe_gpci_&year. mp_gpci = mp_gpci_&year.));
                declare hash gpci_by_cl&year. (dataset: "gpci.gpcis_&year._2 (keep = carrier locality work_gpci pe_gpci mp_gpci rename = (work_gpci = work_gpci_&year. pe_gpci = pe_gpci_&year. mp_gpci = mp_gpci_&year.))");
             %end;
             %else %do;
                if 0 then set gpci.gpcis_&year. (keep = carrier locality work_gpci pe_gpci mp_gpci rename = (work_gpci = work_gpci_&year. pe_gpci = pe_gpci_&year. mp_gpci = mp_gpci_&year.));
                declare hash gpci_by_cl&year. (dataset: "gpci.gpcis_&year. (keep = carrier locality work_gpci pe_gpci mp_gpci rename = (work_gpci = work_gpci_&year. pe_gpci = pe_gpci_&year. mp_gpci = mp_gpci_&year.))");
             %end;
             gpci_by_cl&year..definekey("carrier", "locality");
             gpci_by_cl&year..definedata("work_gpci_&year.", "pe_gpci_&year.", "mp_gpci_&year.");
             gpci_by_cl&year..definedone();
          %end;
 
          *list of GPCI for carriers across years;
          %do year = &baseline_start_year. %to &update_factor_cy.;
             if 0 then set temp.gpci_carriers_&year. (keep = carrier work_gpci pe_gpci mp_gpci rename = (work_gpci = work_gpci_carr_&year. pe_gpci = pe_gpci_carr_&year. mp_gpci = mp_gpci_carr_&year.));
             declare hash gpci_by_c&year. (dataset: "temp.gpci_carriers_&year. (keep = carrier work_gpci pe_gpci mp_gpci rename = (work_gpci = work_gpci_carr_&year. pe_gpci = pe_gpci_carr_&year. mp_gpci = mp_gpci_carr_&year.))");
             gpci_by_c&year..definekey("carrier");
             gpci_by_c&year..definedata("work_gpci_carr_&year.", "pe_gpci_carr_&year.", "mp_gpci_carr_&year.");
             gpci_by_c&year..definedone();
          %end;
 
       end;
       call missing(of _all_);
 
       set temp.pb_price_update_lines;
 
       *determine pb year as fiscal year of anchor end date;
       %do year = &baseline_start_year.+1 %to &baseline_end_year.;
          %let prev_year = %eval(&year.-1);
          if ("01OCT&prev_year."D <= anchor_end_dt <= "30SEP&year."D) then pb_year = &year.;
          %if &year. ^= &baseline_end_year. %then else;
       %end;
 
       *flag facility claims because RVU assignment depends on place of service;
       if (nonfac_cds.find(key: plcsrvc) = 0) then facility_flag = 0;
       else facility_flag = 1;
 
       *technical and professional components;
       *NOTE: only check the first two modifier codes in the array;
       call missing(mod);
       %do a = 1 %to 2;
          if (pb_mod.find(key: mdfr_cd&a.) = 0) then mod = mdfr_code;
          %if &a. ^= 2 %then else;
       %end;
 
       *get the RVU associated with the year of episode;
       %do year = &baseline_start_year. %to &baseline_end_year.;
          rc_getrvu&year. = getrvu&year..find(key: hcpcs_cd, key: mod);
          if (facility_flag = 1) then pe_rvu_&year. = fac_pe_rvu_&year.;
          else pe_rvu_&year. = non_fac_pe_rvu_&year.;
          if year(anchor_end_dt) = &year. then do;
             work_rvu = work_rvu_&year.;
             pe_rvu = pe_rvu_&year.;
             mp_rvu = mp_rvu_&year.;
          end;
       %end;
 
       *get GPCI information;
       %do year = %eval(&baseline_start_year.-1) %to &update_factor_cy.;
          rc_gpci_by_cl&year. = gpci_by_cl&year..find(key: carr_num, key: lclty_cd);
       %end;
       %do year = &baseline_start_year. %to &update_factor_cy.;
          rc_gpci_by_c&year. = gpci_by_c&year..find(key: carr_num);
       %end;
 
       *use the below hierarchy of steps to find values for the GPCIs so that we do not have any missing GPCIs;
 
       *if gpci variable is missing, use the value from the previous year;
       %do year = &baseline_start_year. %to &update_factor_cy.;
          if (missing(work_gpci_&year.)) then work_gpci_&year. = work_gpci_%eval(&year.-1);
          if (missing(pe_gpci_&year.)) then pe_gpci_&year. = pe_gpci_%eval(&year.-1);
          if (missing(mp_gpci_&year.)) then mp_gpci_&year. = mp_gpci_%eval(&year.-1);
       %end;
 
       %do year = &baseline_start_year. %to &update_factor_cy.;
           
          *if GPCI still missing even after looking one year prior, use the calculated GPCI associated with just the carrier;
          if (missing(work_gpci_&year.)) then work_gpci_&year. = work_gpci_carr_&year.;
          if (missing(pe_gpci_&year.)) then pe_gpci_&year. = pe_gpci_carr_&year.;
          if (missing(mp_gpci_&year.)) then mp_gpci_&year. = mp_gpci_carr_&year.;
 
          *if GPCI still missing even after looking for the GPCI associated with just the carrier, use the average GPCI;
          if (missing(work_gpci_&year.)) then work_gpci_&year. = &&work_gpci_all_&year.;
          if (missing(pe_gpci_&year.)) then pe_gpci_&year. = &&pe_gpci_all_&year.;
          if (missing(mp_gpci_&year.)) then mp_gpci_&year. = &&mp_gpci_all_&year.;
 
       %end;
 
       *output only pb claims with RVU. pb claims without RVU are dropped;
       if (not missing(work_rvu)) and (not missing(pe_rvu)) and (not missing(mp_rvu)) then output temp.pb_rvu_w_gpci;
 
   run;
 
 
   *calculate the sum of work, pe, and mp RVU for each anchor provider and region;
   *this step of summary is to avoid stack of PB claims later when generating PB update factors, since the PB claims are too large to run;
   proc sql;       
      create table temp.pb_rvu_ccn as 
      select 
         anchor_provider,
         episode_group_name,
         pb_year,
         sum(work_rvu) as work_rvu_sum_ccn,
         sum(pe_rvu) as pe_rvu_sum_ccn,
         sum(mp_rvu) as mp_rvu_sum_ccn,
         sum(calculated work_rvu_sum_ccn, calculated pe_rvu_sum_ccn, calculated mp_rvu_sum_ccn) as sum_all_ccn,
         calculated work_rvu_sum_ccn/calculated sum_all_ccn as perc_work_rvu_ccn,
         calculated pe_rvu_sum_ccn/calculated sum_all_ccn as perc_pe_rvu_ccn,
         calculated mp_rvu_sum_ccn/calculated sum_all_ccn as perc_mp_rvu_ccn
      from temp.pb_rvu_w_gpci
      group by anchor_provider, episode_group_name, pb_year
      ; 
   quit;


   *deal with the carrier/locality without gpci. also merge with RVU percent to get RVU weighted gpci;
   data temp.pb_gpci (drop = rc_:);

      if _n_ = 1 then do;
         
         *list of CCN level RVUs;
         if 0 then set temp.pb_rvu_ccn (keep = anchor_provider episode_group_name pb_year perc_work_rvu_ccn perc_pe_rvu_ccn perc_mp_rvu_ccn);
         declare hash ccn_rvu (dataset: "temp.pb_rvu_ccn (keep = anchor_provider episode_group_name pb_year perc_work_rvu_ccn perc_pe_rvu_ccn perc_mp_rvu_ccn)");
         ccn_rvu.definekey("anchor_provider", "episode_group_name", "pb_year");
         ccn_rvu.definedata("perc_work_rvu_ccn", "perc_pe_rvu_ccn", "perc_mp_rvu_ccn");
         ccn_rvu.definedone();

      end;
      call missing(of _all_);
      
      set temp.pb_rvu_w_gpci;

      *merge on CCN level RVUs;
      rc_ccn_rvu = ccn_rvu.find(key: anchor_provider, key: episode_group_name, key: pb_year);

      *calculate the CCN weights; 
      %do year = &baseline_start_year. %to &update_factor_cy.;
         wgtgpci_ccn_&year. = sum(perc_work_rvu_ccn * work_gpci_&year., perc_pe_rvu_ccn * pe_gpci_&year., perc_mp_rvu_ccn * mp_gpci_&year.);
      %end;

   run;

   *calculate the weighted average of the weighted GPCI where the weight is the standardized allowed amount;
   proc sql;
      create table temp.pb_update_ccn as
      select anchor_provider,
         episode_group_name,
         pb_year,
         sum(standard_allowed_amt) as total_phy_pay,
         %do year = &baseline_start_year. %to &update_factor_cy.;
            sum(wgtgpci_ccn_&year.*standard_allowed_amt)/calculated total_phy_pay as rvu_wgtgpci_&year.
            %if &year. ^= &update_factor_cy. %then ,;
         %end;
      from temp.pb_gpci
      group by anchor_provider, episode_group_name, pb_year
      ;   
   quit;


   /*PROCESS ANESTHESIA PB CLAIMS*/
 
   data temp.anes_w_cf (drop = rc_: carrier locality);
 
       if _n_ = 1 then do;
          
          *list of anesthesia conversion factors across years;
          %do year = %eval(&baseline_start_year.-1) %to &update_factor_cy.;
             *NOTE: special circumstance for 2015 and 2018. use the version 2 of the anesthesia converion factors;
             %if &year. in (2015 2018) %then %do;
                if 0 then set anes.anesthesia_cf_&year._2 (keep = carrier locality anes_cf rename = (anes_cf = anescf_&year.));
                declare hash anes_by_cl&year. (dataset: "anes.anesthesia_cf_&year._2 (keep = carrier locality anes_cf rename = (anes_cf = anescf_&year.))");
             %end;
             %else %do;
                if 0 then set anes.anesthesia_cf_&year. (keep = carrier locality anes_cf rename = (anes_cf = anescf_&year.));
                declare hash anes_by_cl&year. (dataset: "anes.anesthesia_cf_&year. (keep = carrier locality anes_cf rename = (anes_cf = anescf_&year.))");
             %end;
             anes_by_cl&year..definekey("carrier", "locality");
             anes_by_cl&year..definedata("anescf_&year.");
             anes_by_cl&year..definedone();
          %end;
 
          *list of anesthesia conversion factors for carriers across year;
          %do year = &baseline_start_year. %to &update_factor_cy.;
             if 0 then set temp.anes_carriers_&year. (keep = carrier anes_cf rename = (anes_cf = anescf_carr_&year.));
             declare hash anes_by_c&year. (dataset: "temp.anes_carriers_&year. (keep = carrier anes_cf rename = (anes_cf = anescf_carr_&year.))");
             anes_by_c&year..definekey("carrier");
             anes_by_c&year..definedata("anescf_carr_&year.");
             anes_by_c&year..definedone();
          %end;
 
       end;
       call missing(of _all_);
       
       set temp.anes_price_update_lines;
 
       *determine pb year as fiscal year of anchor end date;
       %do year = &baseline_start_year.+1 %to &baseline_end_year.;
          %let prev_year = %eval(&year.-1);
          if ("01OCT&prev_year."D <= anchor_end_dt <= "30SEP&year."D) then pb_year = &year.;
          %if &year. ^= &baseline_end_year. %then else;
       %end;
 
       %do year = %eval(&baseline_start_year.-1) %to &update_factor_cy.;
          rc_anes_by_cl&year. = anes_by_cl&year..find(key: carr_num, key: lclty_cd);
       %end;
       %do year = &baseline_start_year. %to &update_factor_cy.;
          rc_anes_by_c&year. = anes_by_c&year..find(key: carr_num);
       %end;
 
       *use the below hierarchy of steps to find values for the anesthesia conversion factors so that we do not have any missing anesthesia CFs;
 
       *if missing an anesthesia factor, use the one from the previous year;
       %do year = &baseline_start_year. %to &update_factor_cy.;
          if (missing(anescf_&year.)) then anescf_&year. = anescf_%eval(&year.-1);
       %end;
 
       %do year = &baseline_start_year. %to &update_factor_cy.;
          *if anes CF still missing even after looking one year prior, use the calculated CF associated with just the carrier;
          if (missing(anescf_&year.)) then anescf_&year. = anescf_carr_&year.;
          *if anes CF still missing even after looking for the anes CF associated with just the carrier, use the average anes CF;
          if (missing(anescf_&year.)) then anescf_&year. = &&cf_all_&year.;
       %end;
 
   run;

   *calculate the weighted average of anesthesia conversion factor where the weight is the standardized allowed amount;
   proc sql;
      create table temp.anes_update_ccn as 
      select anchor_provider,
             episode_group_name,
             pb_year,
             sum(standard_allowed_amt) as total_anes_pay,
             %do year = &baseline_start_year. %to &update_factor_cy.;
               sum(anescf_&year.*standard_allowed_amt)/calculated total_anes_pay as wgtanescf_&year.
                %if &year. ^= &update_factor_cy. %then ,;
             %end;
      from temp.anes_w_cf
      group by anchor_provider, episode_group_name, pb_year
      ;               
   quit;


   /*CALCULATE FINAL UPDATE FACTORSFROM RVU AND ANESTHESIA*/

   *merge the PB and anesthesia wieghts together at eh provider level and calculte the update factor for each year;/*{{{*/
   data temp.pb_post_anchor_update_factor;

      length pfs_update_factor 8.;
      
      merge temp.anes_update_ccn
            temp.pb_update_ccn;
            
      by anchor_provider episode_group_name pb_year;

      %do year = %eval(&baseline_start_year.+1) %to &baseline_end_year.;
         if (pb_year = &year.) then do;
            %let prev_year = %eval(&year.-1);
            end_year_rate = &&conv_factor_&update_factor_cy..;
            current_year_rate = &&conv_factor_&year..;
            prev_year_rate = &&conv_factor_&prev_year..;
            phys_update = (rvu_wgtgpci_&update_factor_cy.*end_year_rate)/(&pb_cur_yr_wgt.*(rvu_wgtgpci_&year.*current_year_rate)+&pb_prev_yr_wgt.*(rvu_wgtgpci_&prev_year.*prev_year_rate));
            anes_update = wgtanescf_&update_factor_cy./(wgtanescf_&year.*&pb_cur_yr_wgt.+wgtanescf_&prev_year.*&pb_prev_yr_wgt.);
         end;
         %if &year. ^= &baseline_end_year. %then else;
      %end;

      anes_perc = total_anes_pay/sum(total_anes_pay, total_phy_pay);
      phys_perc = total_phy_pay/sum(total_anes_pay, total_phy_pay);      
      pfs_update_factor = sum(anes_update*total_anes_pay, phys_update*total_phy_pay)/sum(total_anes_pay, total_phy_pay);

   run;
%mend; 
