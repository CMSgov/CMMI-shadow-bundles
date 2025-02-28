/*************************************************************************;
%** PROGRAM: f2_add_prov_ra_vars.sas
%** PURPOSE: To add provider level variables and time trend variables
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro f2_add_prov_ra_vars();
   

   *list of time increments for the quarter time trend factors;
   %macarray(qtime_yrs, &quart_trend_yrs.);
   %macarray(qtime_qus, &quart_trend_qus.);
   %macarray(qtime_incr, &quart_trend_incr.);


   data temp.episodes_w_prov_ra (drop = prvdr_num cbsa_urbn_rrl_ind urban_code imeratio ibratio censdivi bedsize);

      if _n_ = 1 then do;

         *CBSA urban/rural hospital indicator dataset;
         if 0 then set pos.pos_other (keep = prvdr_num cbsa_urbn_rrl_ind);
         declare hash urb_rur (dataset: "pos.pos_other (keep = prvdr_num cbsa_urbn_rrl_ind)");
         urb_rur.definekey("prvdr_num");
         urb_rur.definedata("cbsa_urbn_rrl_ind");
         urb_rur.definedone();

         *list of the codes identifying an urban hospital;
         if 0 then set temp.urban_prov_codes (keep = urban_code);
         declare hash urban_cd (dataset: "temp.urban_prov_codes (keep = urban_code)");
         urban_cd.definekey("urban_code");
         urban_cd.definedone();

         *IME ratio and bed size;
         if 0 then set temp.inp_sas_psf&psf_version. (keep = provider imeratio ibratio censdivi bedsize);
         declare hash psf_ds (dataset: "temp.inp_sas_psf&psf_version. (keep = provider imeratio ibratio censdivi bedsize)");
         psf_ds.definekey("provider");
         psf_ds.definedata("imeratio", "ibratio", "censdivi", "bedsize");
         psf_ds.definedone();

         *crosswalk of CCN codes to state;
         if 0 then set temp.ccn_state_codes (keep = ccn_code state_abbr state_name);
         declare hash ccn_state_cd (dataset: "temp.ccn_state_codes (keep = ccn_code state_abbr state_name)");
         ccn_state_cd.definekey("ccn_code");
         ccn_state_cd.definedata("state_abbr", "state_name");
         ccn_state_cd.definedone();

         *crosswalk of state abbreviation to census region;
         if 0 then set temp.state_to_census_reg (keep = state_abbr division_code division_name);
         declare hash cens_region (dataset: "temp.state_to_census_reg (keep = state_abbr division_code division_name)");
         cens_region.definekey("state_abbr");
         cens_region.definedata("division_code", "division_name");
         cens_region.definedone();

      end;
      call missing(of _all_);

      set temp.episodes_w_bene_ra;

      *create quarter time trend variable;
      %do a = 1 %to &nqtime_yrs.;
         if (year(anchor_end_dt) = &&qtime_yrs&a..) and (qtr(anchor_end_dt) = &&qtime_qus&a..) then do;
            quart_time_trend = &&qtime_incr&a..;
         end;
         %if &a. ^= &nqtime_yrs. %then else;
      %end;

      *create year-quarter flags;
      %do quart_year = &quart_trend_start_yr. %to &quart_trend_end_yr.;
         %do q = 1 %to 4;
            if (year(anchor_end_dt) = &quart_year.) and (qtr(anchor_end_dt) = &q.) then yr&quart_year._q&q. = 1;
            else yr&quart_year._q&q. = 0;
         %end;
      %end;

      *create quarter dummies;
      %do a = 1 %to 4; season_q&a. = 0; %end;
      if (1 <= month(anchor_end_dt) <= 3) then season_q1 = 1;
      else if (4 <= month(anchor_end_dt) <= 6) then season_q2 = 1;
      else if (7 <= month(anchor_end_dt) <= 9) then season_q3 = 1;
      else if (10 <= month(anchor_end_dt) <= 12) then season_q4 = 1;

      *create fiscal year dummies;
      %do year = &query_start_year. %to %eval(&query_end_year.+1);
         %let prev_year = %eval(&year.-1);
         fy&year. = 0;
         if ("01OCT&prev_year."D <= anchor_end_dt <= "30SEP&year."D) then fy&year. = 1;
      %end;

      *flag if provider is an urban hospital;
      urban = 0;
      if (not missing(anchor_provider)) and (urb_rur.find(key: anchor_provider) = 0) then do;
         if (urban_cd.find(key: cbsa_urbn_rrl_ind) = 0) then urban = 1;
      end;

      teaching = 0;
      mth = 0;
      bed_size_small = 0;
      bed_size_medium = 0;
      bed_size_large = 0;
      bed_size_xlarge = 0;
      bed_size_missing = 0;
      if (psf_ds.find(key: anchor_provider) = 0) then do;

         *flag if provider is teaching hospital;
         if (imeratio > 0) then teaching = 1;
         
         *flag if provider is major teaching hospital;
         if (ibratio >= &ibratio_thresh.) then mth = 1;

         *create a bed size indicator;
         bed_size_num = put(bedsize, 8.);
         if (0 <= bed_size_num <= 250) then bed_size_small = 1;
         else if (250 < bed_size_num <= 500) then bed_size_medium = 1;
         else if (500 < bed_size_num <= 850) then bed_size_large = 1;
         else if (850 < bed_size_num) then bed_size_xlarge = 1;

      end;
      if (bed_size_small = 0) and (bed_size_medium = 0) and (bed_size_large = 0) and (bed_size_xlarge = 0) then bed_size_missing = 1;

      *census region flags;
      %do a = 1 %to 9; cens_div_&a. = 0; %end;
      cens_div_other = 0;
      if (ccn_state_cd.find(key: substr(anchor_provider, 1, 2)) = 0) then do;
         rc_cens_region = cens_region.find(key: state_abbr);
         *create census region flags;
         %do a = 1 %to 9;
            if (strip(division_code) = "&a.") then cens_div_&a. = 1;
            %if &a. ^= 9 %then else;
         %end;
      end;
      if %do a = 1 %to 9; (cens_div_&a. = 0) %if &a. ^= 9 %then and; %end; then cens_div_other = 1;
      
      *interaction between urban and major teaching hospital flags;
      urban_mth = urban*mth;
      rural_mth = (1 - urban)*mth;
      urban_nonmth = urban*(1-mth);
      rural_nonmth = (1 - urban)*(1 - mth);

      *interaction between teach, urban, bed size, and time trend variables;
      %do a = 1 %to &ntime_factors.;
         urban_&&time_short&a.. = urban * &&time_factors&a.._time_trend;
         teaching_&&time_short&a.. = teaching * &&time_factors&a.._time_trend;
         mth_&&time_short&a.. = mth * &&time_factors&a.._time_trend;
         urban_mth_&&time_short&a.. = urban_mth * &&time_factors&a.._time_trend;
         rural_mth_&&time_short&a.. = rural_mth * &&time_factors&a.._time_trend;
         urban_nonmth_&&time_short&a.. = urban_nonmth * &&time_factors&a.._time_trend;
         rural_nonmth_&&time_short&a.. = rural_nonmth * &&time_factors&a.._time_trend;
         %do b = 1 %to 9;
            cens_div_&b._&&time_short&a.. = cens_div_&b. * &&time_factors&a.._time_trend;
         %end;
         cens_div_other_&&time_short&a.. = cens_div_other * &&time_factors&a.._time_trend;
         bed_size_small_&&time_short&a.. = bed_size_small * &&time_factors&a.._time_trend;
         bed_size_medium_&&time_short&a.. = bed_size_medium * &&time_factors&a.._time_trend;
         bed_size_large_&&time_short&a.. = bed_size_large * &&time_factors&a.._time_trend;
         bed_size_xlarge_&&time_short&a.. = bed_size_xlarge * &&time_factors&a.._time_trend;
         bed_size_missing_&&time_short&a.. = bed_size_missing * &&time_factors&a.._time_trend;
      %end;

     *interaction between teach, urban, census division, and quarter time flags;
      %do quart_year = &quart_trend_start_yr. %to &quart_trend_end_yr.;
         %do q = 1 %to 4;
            urban_&quart_year._q&q. = yr&quart_year._q&q. * urban;
            teaching_&quart_year._q&q. = yr&quart_year._q&q. * teaching;
            mth_&quart_year._q&q. = yr&quart_year._q&q. * mth;
            urban_mth_&quart_year._q&q. = yr&quart_year._q&q. *urban_mth;
            rural_mth_&quart_year._q&q. = yr&quart_year._q&q. *rural_mth;
            urban_nonmth_&quart_year._q&q. = yr&quart_year._q&q. * urban_nonmth;
            rural_nonmth_&quart_year._q&q. = yr&quart_year._q&q. * rural_nonmth;
            %do b = 1 %to 9;
               cens_div_&b._&quart_year._q&q. = yr&quart_year._q&q. * cens_div_&b.;
            %end;
            cens_div_other_&quart_year._q&q. = yr&quart_year._q&q. * cens_div_other;
            bed_size_small_&quart_year._q&q. = yr&quart_year._q&q. * bed_size_small;
            bed_size_medium_&quart_year._q&q. = yr&quart_year._q&q. * bed_size_medium;
            bed_size_large_&quart_year._q&q. = yr&quart_year._q&q. * bed_size_large;
            bed_size_xlarge_&quart_year._q&q. = yr&quart_year._q&q. * bed_size_xlarge;
            bed_size_missing_&quart_year._q&q. = yr&quart_year._q&q. * bed_size_missing;
         %end;
      %end;
                              
   run;

 
%mend;

