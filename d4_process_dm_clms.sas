/*************************************************************************;
%** PROGRAM: d4_process_dm_clms.sas
%** PURPOSE: Identify qualifying DM claims grouped to episodes 
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro d4_process_dm_clms();

   data temp.grp_dm_clms_to_epi (drop = cy_year cy_quarter drg_code anchor_drg_&update_factor_cy.)
        temp.ungrp_dm_clms_to_epi (drop = cy_year cy_quarter drg_code anchor_drg_&update_factor_cy.);
      
      if _n_ = 1 then do;

         *list of hemophilia/clotting factor drugs by year and quarter;
         %* _2 is the most updated version that is available at the time of running the program;         
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

         *list of IBD related part B drugs for exclusion;
         if 0 then set temp.excluded_ibd_partb (keep = drg_code hcpcs_cd);
         declare hash ibd_partb (dataset: "temp.excluded_ibd_partb (keep = drg_code hcpcs_cd)");
         ibd_partb.definekey("drg_code", "hcpcs_cd");
         ibd_partb.definedone();

      end;
      call missing(of _all_);

      set temp.dm_clms_to_epi;

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
      
      *determine if claim has IBD related part B drugs;
      if (ibd_partb.find(key: anchor_drg_&update_factor_cy., key: hcpcs_cd) = 0) then excluded_ibd_partb = 1;
      
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

      *determine where to attribute the cost;
      if (anchor_beg_dt <= service_start_dt < anchor_end_dt) then cost_category = "anchor period";
      else if (post_dsch_beg_dt <= service_start_dt <= post_dsch_end_dt) then cost_category = "post-discharged period";
      else if (post_epi_beg_dt <= service_start_dt <= post_epi_end_dt) then cost_category = "post-episode period";

      *determine if claim should be grouped;
      if (non_positive_payment = 0) and (non_medicare_prpayer = 0) and (hemophilia_flag = 0) and (part_b_dropflag = 0) and (excluded_ibd_partb = 0) and (lowcase(cost_category) ^= "unattributed") then grouped = 1;

      if (grouped = 1) then output temp.grp_dm_clms_to_epi;
      else if (grouped = 0) then output temp.ungrp_dm_clms_to_epi;

   run;
%mend;