/*************************************************************************;
%** PROGRAM: b2_prep_gpci_and_anes.sas
%** PURPOSE: To pre-process GPCI and Anesthesia conversion factor for PB update factor
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro b2_prep_gpci_and_anes();
   
   *for carriers with only one record in the file, where the carriers match but not the locality, use the values for that carrier;
   *for carriers with more than one locality in the file, but the locality in the data does not match any locality in the file, use the value from the file where the locality=99, which is an overall value for the state usually;
   *for railroad retirement beneficiaries that use carrier 00882, use an unweighted average of work gpci, pe gpci and mp gpci or anesthesia conversion factors across all carrier/localities;
   *for carriers with more than one locality in the file and no 99 locality in the file, use an average of the work gpci, pe gpci and mp gpci or anesthesia conversion factors for that carrier.;
   *for other carrier and locality combination without matched gpci, use an unweighted average of work gpci, pe gpci and mp gpci or anesthesia conversion factors across all carrier/localities.;

   %macarray(prep_types,  gpci anes);
   %macarray(input_names, gpcis anesthesia_cf);

   %do a = 1 %to &nprep_types.;

      %do year = &baseline_start_year. %to &update_factor_cy.;
         
         proc sort data = 
                   %if &&prep_types&a. = gpci %then %do;
                       %if  "&year." in ("2015" "2018" "2020") %then %do; 
                           &&prep_types&a...&&input_names&a.._&year._2 
                       %end; 
                       %else %do; 
                           &&prep_types&a...&&input_names&a.._&year. 
                       %end;
                   %end; 
                   %if &&prep_types&a. = anes %then %do;
                       %if "&year." in ("2015" "2018" "2024") %then %do; 
                          &&prep_types&a...&&input_names&a.._&year._2 
                       %end; 
                       %else %do; 
                          &&prep_types&a...&&input_names&a.._&year. 
                       %end;
                    %end;
                   out = temp.&&prep_types&a.._&year.;
              by carrier locality;
         run;

         data temp.&&prep_types&a.._state_locality_&year. (keep = carrier locality %if "&&prep_types&a.." = "gpci" %then work_gpci mp_gpci pe_gpci; %else %if "&&prep_types&a.." = "anes" %then anes_cf;)
              temp.&&prep_types&a.._nonstate_carriers_&year. (keep = carrier)
              temp.&&prep_types&a.._single_carriers_&year. (keep = carrier locality %if "&&prep_types&a.." = "gpci" %then work_gpci mp_gpci pe_gpci; %else %if "&&prep_types&a.." = "anes" %then anes_cf;)
              temp.&&prep_types&a.._unwght_avg_&year. (keep = hash_var rr_avg_:);

            if _n_ = 1 then do;

               *list of locality codes;
               if 0 then set temp.state_locality_codes (keep = locality_code);
               declare hash local_cd (dataset: "temp.state_locality_codes (keep = locality_code)");
               local_cd.definekey("locality_code");
               local_cd.definedone();

            end;
            call missing(of _all_);

            set temp.&&prep_types&a.._&year. end = last;
            by carrier locality;

            %if "&&prep_types&a.." = "gpci" %then %do;
               retain state_locality_flag rr_sum_work_gpci rr_sum_pe_gpci rr_sum_mp_gpci rr_num_locality 0;
               rr_sum_work_gpci = sum(rr_sum_work_gpci, work_gpci);
               rr_sum_pe_gpci = sum(rr_sum_pe_gpci, pe_gpci);
               rr_sum_mp_gpci = sum(rr_sum_mp_gpci, mp_gpci);
               rr_num_locality = rr_num_locality + 1;
            %end;
            %else %if "&&prep_types&a.." = "anes" %then %do;
               retain state_locality_flag rr_sum_cf rr_num_locality 0;
               rr_sum_cf = sum(rr_sum_cf, anes_cf);
               rr_num_locality = rr_num_locality + 1;
            %end;

            *identify carriers with only one locality on the file;
            if first.carrier and last.carrier then output temp.&&prep_types&a.._single_carriers_&year.;

            if first.carrier then state_locality_flag = 0;

            *identify records with code identifying all remaining localities within a state;
            if (local_cd.find(key: locality) = 0) then do;
               state_locality_flag = 1;
               output temp.&&prep_types&a.._state_locality_&year.;
            end;

            *identify all carriers without the code identifying all remaining localities within a state;
            if (last.carrier) and (state_locality_flag = 0) then output temp.&&prep_types&a.._nonstate_carriers_&year.;

            *calculate the unweighted average for use among railroad retirement carrier;
            if last then do;
               hash_var = 1;
               %if "&&prep_types&a.." = "gpci" %then %do;
                  rr_avg_work_gpci = rr_sum_work_gpci/rr_num_locality;
                  rr_avg_pe_gpci = rr_sum_pe_gpci/rr_num_locality;
                  rr_avg_mp_gpci = rr_sum_mp_gpci/rr_num_locality;
               %end;
               %else %if "&&prep_types&a.." = "anes" %then %do;
                  rr_avg_cf = rr_sum_cf/rr_num_locality;
               %end;
               output temp.&&prep_types&a.._unwght_avg_&year.;
            end;

         run;

         *calculate the average for carriers without the code identifying all remaining localities;
         proc sql noprint;
            
            select carrier
            into   :nonstate_carriers separated by " "
            from temp.&&prep_types&a.._nonstate_carriers_&year.
            ;

            create table temp.&&prep_types&a.._nonstate_carriers_&year. as
               select carrier,
                      %if "&&prep_types&a.." = "gpci" %then %do;
                         mean(work_gpci) as nonstate_avg_work_gpci, 
                         mean(pe_gpci) as nonstate_avg_pe_gpci,
                         mean(mp_gpci) as nonstate_avg_mp_gpci
                     %end;
                     %else %if "&&prep_types&a.." = "anes" %then %do;
                        mean(anes_cf) as nonstate_avg_cf
                     %end;
               from temp.&&prep_types&a.._&year. (where = (carrier in (%quotelst(&nonstate_carriers.))))
               group by carrier
               ;

         quit;

         *identify records for railroad retirement carrier and merge on unweighted averages;
         data temp.&&prep_types&a.._rr_&year. (drop = hash_var);
            
            length hash_var 8.;
            if _n_ = 1 then do;
               
               *list of unweighted averages;
               if 0 then set temp.&&prep_types&a.._unwght_avg_&year.;
               declare hash unwgt_avg (dataset: "temp.&&prep_types&a.._unwght_avg_&year.");
               unwgt_avg.definekey("hash_var");
               %if "&&prep_types&a.." = "gpci" %then %do;
                  unwgt_avg.definedata("rr_avg_work_gpci", "rr_avg_pe_gpci", "rr_avg_mp_gpci");
               %end;
               %else %if "&&prep_types&a.." = "anes" %then %do;
                  unwgt_avg.definedata("rr_avg_cf");
               %end;
               unwgt_avg.definedone();

            end;
            call missing(of _all_);

            set temp.rr_carrier_codes (keep = rr_code rename = (rr_code = carrier));
            hash_var = 1;
            if (unwgt_avg.find(key: hash_var) = 0) then output temp.&&prep_types&a.._rr_&year.;

         run;

         data temp.&&prep_types&a.._carriers_&year. (keep = carrier %if "&&prep_types&a.." = "gpci" %then work_gpci pe_gpci mp_gpci; %else %if "&&prep_types&a.." = "anes" %then anes_cf;);
            set temp.&&prep_types&a.._single_carriers_&year.
                temp.&&prep_types&a.._state_locality_&year.
                temp.&&prep_types&a.._rr_&year. (rename = (%if "&&prep_types&a.." = "gpci" %then %do; rr_avg_work_gpci = work_gpci rr_avg_pe_gpci = pe_gpci rr_avg_mp_gpci = mp_gpci %end; %else %if "&&prep_types&a.." = "anes" %then %do; rr_avg_cf = anes_cf %end;))
                temp.&&prep_types&a.._nonstate_carriers_&year. (rename = (%if "&&prep_types&a.." = "gpci" %then %do; nonstate_avg_work_gpci = work_gpci nonstate_avg_pe_gpci = pe_gpci nonstate_avg_mp_gpci = mp_gpci %end; %else %if "&&prep_types&a.." = "anes" %then %do; nonstate_avg_cf = anes_cf %end;));
         run;

         proc sort nodupkey data = temp.&&prep_types&a.._carriers_&year.;
            by carrier %if "&&prep_types&a.." = "gpci" %then %do; work_gpci pe_gpci mp_gpci %end; %else %if "&&prep_types&a.." = "anes" %then %do; anes_cf %end;;
         run;

      %end;

   %end;
%mend; 