/*************************************************************************;
%** PROGRAM: d8_process_hh_clms.sas
%** PURPOSE: To identify qualifying HH claims to be grouped to episodes 
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


%macro d8_process_hh_clms();

   data temp.inter_hh_clms_to_epi;

      if _n_ = 1 then do;

         *keep track of the number of HH visits from segments greater than 1;
         declare hash hh_visits (ordered: "a");
         hh_visits.definekey("claimno", "sgmt_num", "episode_id");
         hh_visits.definedata("claimno", "sgmt_num", "episode_id", "anchor_visit_count", "post_dschrg_visit_count", "post_epi_visit_count", "tot_visit_count");
         hh_visits.definedone();

      end;

      set temp.hh_clms_to_epi end = last;

      *for non-LUPA claims;
      if (lupa_flag = 0) then do;

         *for when proration is needed;
         if (service_start_dt ^= service_end_dt) and (anchor_beg_dt <= service_start_dt) and ((service_start_dt < anchor_end_dt <= service_end_dt) or (service_start_dt <= post_dsch_end_dt < service_end_dt) or (service_start_dt <= post_epi_end_dt < service_end_dt)) then do;
   
            prorated = 1;
            *calculate the number of overlapping days for each time period;
            if (service_start_dt < anchor_end_dt <= service_end_dt) then do;
               anchor_overlap_days = (min(anchor_end_dt, service_end_dt) - max(anchor_beg_dt, service_start_dt));
               if (anchor_overlap_days > 0) then catgry_num = catgry_num + 1;
            end;
            if (service_start_dt < post_dsch_beg_dt <= service_end_dt) or (service_start_dt <= post_dsch_end_dt < service_end_dt) then do;
               post_dschrg_overlap_days = (min(post_dsch_end_dt, service_end_dt) - max(post_dsch_beg_dt, service_start_dt)) + 1;
               if (post_dschrg_overlap_days > 0) then catgry_num = catgry_num + 1;
            end;
            if (service_start_dt < post_epi_beg_dt <= service_end_dt) or (service_start_dt <= post_epi_end_dt < service_end_dt) then do;
               post_epi_overlap_days = (min(post_epi_end_dt, service_end_dt) - max(post_epi_beg_dt, service_start_dt)) + 1;
               if (post_epi_overlap_days > 0) then catgry_num = catgry_num + 1;
            end;

            *define cost category;
            if (catgry_num = 3) then do;
               cost_category = catx(" ", "prorated -", catx(", ", %do a = 1 %to &ncatgry_types.; "&&catgry_labels&a.." %if &a. ^= &ncatgry_types. %then ,; %end;), " periods");
            end;
            else if (catgry_num = 2) then do;
               %do a = 1 %to &ncatgry_types.;
                  %do b = 1 %to &ncatgry_types.;
                     %if "&&catgry_types&a.." ^= "&&catgry_types&b.." %then %do;
                        if (&&catgry_types&a.._overlap_days > 0) and (&&catgry_types&b.._overlap_days > 0) then cost_category = "prorated - &&catgry_labels&a.. and &&catgry_labels&b.. periods";
                        %if (&a. ^= &ncatgry_types.) or (&a. = &ncatgry_types. and &b. ^= &ncatgry_types.) %then else;
                     %end;
                  %end;
               %end;
            end;
            else if (catgry_num = 1) then do;
               %do a = 1 %to &ncatgry_types.;
                  if (&&catgry_types&a.._overlap_days > 0) then cost_category = "prorated - &&catgry_labels&a.. period only";
               %end;
            end;
   
         end;

         *for when proration is not needed;
         else do;
            if (anchor_beg_dt <= service_start_dt < anchor_end_dt) then cost_category = "anchor period";
            else if (post_dsch_beg_dt <= service_start_dt <= post_dsch_end_dt) then cost_category = "post-discharged period";
            else if (post_epi_beg_dt <= service_start_dt <= post_epi_end_dt) then cost_category = "post-episode period";
         end;

      end;

      *for LUPA claims;
      else if (lupa_flag = 1) then do;
         
         prorated = 1;

         *count the number of visit days for each time period;
         %do a = 1 %to &rev_array_size.;
            %let b = %sysfunc(putn(&a., z2.));
            if (substr(rvcntr&b., 1, 3) in (&rvcntr_visit_codes.)) then do;
               *NOTE: use from_dt whenever rev_dt: is missing;
               if (missing(rev_dt&b.)) then do;
                  if ((rvchrg&b. - rvncvr&b.) > 0) and (hcpscd&b. not in (&non_hcpcs_visit_codes.)) then do;
                     tot_visit_count = tot_visit_count + 1;
                     if (anchor_beg_dt <= service_start_dt < anchor_end_dt) then anchor_visit_count = anchor_visit_count + 1;
                     else if (post_dsch_beg_dt <= service_start_dt <= post_dsch_end_dt) then post_dschrg_visit_count = post_dschrg_visit_count + 1;
                     else if (post_epi_beg_dt <= service_start_dt <= post_epi_end_dt) then post_epi_visit_count = post_epi_visit_count + 1;
                  end;
               end;
               else if (not missing(rev_dt&b.)) then do;
                  if ((rvchrg&b. - rvncvr&b.) > 0) and (hcpscd&b. not in (&non_hcpcs_visit_codes.)) then do;
                     tot_visit_count = tot_visit_count + 1;
                     if (anchor_beg_dt <= rev_dt&b. < anchor_end_dt) then anchor_visit_count = anchor_visit_count + 1;
                     else if (post_dsch_beg_dt <= rev_dt&b. <= post_dsch_end_dt) then post_dschrg_visit_count = post_dschrg_visit_count + 1;
                     else if (post_epi_beg_dt <= rev_dt&b. <= post_epi_end_dt) then post_epi_visit_count = post_epi_visit_count + 1;
                  end;
               end;
            end;
         %end;

         *only keep track of hh visit counts for claims with segment number greater than zero so that these counts can be merged back to the first-segment-numbered claim later on;
         if (sgmt_num > 1) and (hh_visits.find(key: claimno, key: sgmt_num, key: episode_id) ^= 0) then hh_visits.add();

      end;

      *only costs found on the first segment of an hh claim will be used;
      if (sgmt_num = 1) then output temp.inter_hh_clms_to_epi;

      if last then hh_visits.output(dataset: "temp.hh_visit_counts");

   run;

   *merge visit counts from non-first-segment-numbered claims to first-segment-numbered claims;
   data temp.grp_hh_clms_to_epi (drop = rc_: sgmt_num_h anchor_visit_count_h post_dschrg_visit_count_h post_epi_visit_count_h tot_visit_count_h)
        temp.ungrp_hh_clms_to_epi (drop = rc_: sgmt_num_h anchor_visit_count_h post_dschrg_visit_count_h post_epi_visit_count_h tot_visit_count_h)
        ;


      if _n_ = 1 then do;

         *list of hh visit counts;
         if 0 then set temp.hh_visit_counts (keep = episode_id claimno sgmt_num anchor_visit_count post_dschrg_visit_count post_epi_visit_count tot_visit_count rename = (sgmt_num = sgmt_num_h anchor_visit_count = anchor_visit_count_h post_dschrg_visit_count = post_dschrg_visit_count_h 
                                                                 post_epi_visit_count = post_epi_visit_count_h tot_visit_count = tot_visit_count_h));
         declare hash hh_visits (dataset: "temp.hh_visit_counts (keep = episode_id claimno sgmt_num anchor_visit_count post_dschrg_visit_count post_epi_visit_count tot_visit_count rename = (sgmt_num = sgmt_num_h anchor_visit_count = anchor_visit_count_h post_dschrg_visit_count = post_dschrg_visit_count_h
                                                                                     post_epi_visit_count = post_epi_visit_count_h tot_visit_count = tot_visit_count_h))"
                                 ,multidata: "y");
         hh_visits.definekey("episode_id", "claimno");
         hh_visits.definedata("sgmt_num_h", "anchor_visit_count_h", "post_dschrg_visit_count_h", "post_epi_visit_count_h", "tot_visit_count_h");
         hh_visits.definedone();

      end;
      call missing(of _all_);

      set temp.inter_hh_clms_to_epi;

      *sum up all visits across segments for a claim;
      if (hh_visits.find(key: episode_id, key: claimno) = 0) then do;
         rc_hh_visits = 0;
         do while (rc_hh_visits = 0);
            anchor_visit_count = sum(anchor_visit_count, anchor_visit_count_h);
            post_dschrg_visit_count = sum(post_dschrg_visit_count, post_dschrg_visit_count_h);
            post_epi_visit_count = sum(post_epi_visit_count, post_epi_visit_count_h);
            tot_visit_count = sum(tot_visit_count, tot_visit_count_h);
            rc_hh_visits = hh_visits.find_next();
         end;
      end;

      *define cost category for LUPA based on updated visit counts;
      if (lupa_flag = 1) then do;

         if (anchor_visit_count > 0) then catgry_num = catgry_num + 1;
         if (post_dschrg_visit_count > 0) then catgry_num = catgry_num + 1;
         if (post_epi_visit_count > 0) then catgry_num = catgry_num + 1;

         if (catgry_num = 3) then do;
            cost_category = catx(" ", "prorated -", catx(", ", %do a = 1 %to &ncatgry_types.; "&&catgry_labels&a.." %if &a. ^= &ncatgry_types. %then ,; %end;), " periods");
         end;
         else if (catgry_num = 2) then do;
            %do a = 1 %to &ncatgry_types.;
               %do b = 1 %to &ncatgry_types.;
                  %if "&&catgry_types&a.." ^= "&&catgry_types&b.." %then %do;
                     if (&&catgry_types&a.._visit_count > 0) and (&&catgry_types&b.._visit_count > 0) then cost_category = "prorated - &&catgry_labels&a.. and &&catgry_labels&b.. periods";
                     %if (&a. ^= &ncatgry_types.) or (&a. = &ncatgry_types. and &b. ^= &ncatgry_types.) %then else;
                  %end;
               %end;
            %end;
         end;
         else if (catgry_num = 1) then do;
            %do a = 1 %to &ncatgry_types.;
               if (&&catgry_types&a.._visit_count > 0) then cost_category = "prorated - &&catgry_labels&a.. period only";
            %end;
         end;

      end;

      tot_overlap_days = sum(anchor_overlap_days, post_dschrg_overlap_days, post_epi_overlap_days);
      
      *flag COVID-19 claims;
      *COVID-19;
      if (service_start_dt >= "01APR2020"D) or (service_end_dt >= "01APR2020"D) then do;
         *check claim diagnosis codes;
         %do a = 1 %to &diag_proc_length.;
            %let b = %sysfunc(putn(&a., z2.));
            if (dgnscd&b. in (&covid_19_cds.)) then covid_19_clm = 1;
            %if &a. ^= &diag_proc_length. %then else;
         %end;
      end; %*end of COVID-19;
      *other coronavirus as the cause of diseases classified elsewhere;
      if covid_19_clm = 0 and ((service_start_dt > "27JAN2020"D) or (service_end_dt > "27JAN2020"D)) then do;
         *check claim diagnosis codes;
         %do a = 1 %to &diag_proc_length.;
            %let b = %sysfunc(putn(&a., z2.));
            if (dgnscd&b. in (&other_corona_cds.)) then covid_19_clm = 1;
            %if &a. ^= &diag_proc_length. %then else;
         %end;
      end; %*end of other coronavirus;

      *determine if claim should be grouped;
      if (non_positive_payment = 0) and (non_medicare_prpayer = 0) and (lowcase(cost_category) ^= "unattributed") then grouped = 1;

      if (grouped = 1) then output temp.grp_hh_clms_to_epi;
      else if (grouped = 0) then output temp.ungrp_hh_clms_to_epi;

   run;
%mend; 