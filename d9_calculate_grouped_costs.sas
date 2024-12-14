/*************************************************************************;
%** PROGRAM: d9_calculate_grouped_costs.sas
%** PURPOSE: To calculate total cost of all qualifying claims grouped to episodes 
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

%macro d9_calculate_grouped_costs();

   *define cost variables for each setting;
   %let ep_cost_vars = tot_num_claims tot_prorated_claims tot_unprorated_claims tot_anchor_std_allowed tot_post_dsch_std_allowed tot_post_epi_std_allowed tot_std_allowed 
                       tot_anchor_raw_allowed tot_post_dsch_raw_allowed tot_post_epi_raw_allowed tot_raw_allowed;
   %do a = 1 %to &nsettings.;
      %let ep_cost_vars = &ep_cost_vars. num_prorated_claims_&&settings&a.. num_unprorated_claims_&&settings&a.. num_claims_&&settings&a.. anchor_std_allowed_&&settings&a.. post_dsch_std_allowed_&&settings&a.. 
                          post_epi_std_allowed_&&settings&a.. tot_std_allowed_&&settings&a.. anchor_raw_allowed_&&settings&a.. post_dsch_raw_allowed_&&settings&a.. post_epi_raw_allowed_&&settings&a.. tot_raw_allowed_&&settings&a..;
   %end;
   %macarray(cost_vars, &ep_cost_vars.);

   data temp.all_grp_clms_to_epi (drop = &ep_cost_vars. anchor_std_cost anchor_raw_cost post_dsch_std_cost post_dsch_raw_cost post_epi_std_cost post_epi_raw_cost);

      length trigger_line std_cost_epi_total std_cost_anchor std_cost_post_dsch std_cost_post_epi  std_cost_post_dsch_wo_outlier std_cost_post_dsch_w_outlier std_cost_post_epi_wo_outlier std_cost_post_epi_w_outlier 
             raw_cost_epi_total raw_cost_anchor raw_cost_post_dsch raw_cost_post_epi  raw_cost_post_dsch_wo_outlier raw_cost_post_dsch_w_outlier raw_cost_post_epi_wo_outlier raw_cost_post_epi_w_outlier
             anchor_std_cost post_dsch_std_cost post_epi_std_cost  anchor_raw_cost post_dsch_raw_cost post_epi_raw_cost &ep_cost_vars. 8.;
      if _n_ = 1 then do;
         
         *keep track of episode costs;
         declare hash ep_cost (ordered: "a");
         ep_cost.definekey("episode_id");
         ep_cost.definedata("episode_id", %clist(%quotelst(&ep_cost_vars.)));
         ep_cost.definedone();

      end;

      set %do a = 1 %to &nsettings.; 
             temp.grp_&&settings&a.._clms_to_epi (in = in_&&settings&a..)
          %end;
          end = last;

      *initialize flags;
      ipps_ltch_irf_provider = 0;
      trigger_line = 0;
      tot_episode_proportion = 0;
      anchor_episode_proportion = 0;
      post_dsch_episode_proportion = 0;
      post_epi_episode_proportion = 0;
      std_per_diem_wo_outlier = 0;
      raw_per_diem_wo_outlier = 0;
      std_per_diem_outlier = 0;
      raw_per_diem_outlier = 0;
      anchor_visit_proportion = 0;
      post_dsch_visit_proportion = 0;
      post_epi_visit_proportion = 0;

      *flag if the grouped IP/OP line is also the triggering IP/OP line;
      if (lowcase(anchor_type) = "ip") and (in_ip = 1) and (anchor_stay_id = ip_stay_id) then trigger_line = 1;
      else if (lowcase(anchor_type) = "op") and (in_opl = 1) and (anchor_claimno = claimno) and (anchor_lineitem = lineitem) then trigger_line = 1;

      *calculate proration multipliers;
      if (in_ip = 1) or (in_sn = 1) or (in_hs = 1) or (in_hh = 1) then do;
         if (tot_overlap_days ^= 0) then tot_episode_proportion = (tot_overlap_days/tot_claim_length);
         if (anchor_overlap_days ^= 0) then anchor_episode_proportion = (anchor_overlap_days/tot_claim_length);
         if (post_dschrg_overlap_days ^= 0) then post_dsch_episode_proportion = (post_dschrg_overlap_days/tot_claim_length);
         if (post_epi_overlap_days ^= 0) then post_epi_episode_proportion = (post_epi_overlap_days/tot_claim_length);
      end;
      if (in_ip = 1) then do;
         if (gmlos ^= 0) then do;
            std_per_diem_wo_outlier = (standard_allowed_amt_w_o_outlier/gmlos);
            raw_per_diem_wo_outlier = (raw_allowed_amt_w_o_outlier/gmlos);
         end;
         std_per_diem_outlier = (outlier_pmt/tot_claim_length);
         raw_per_diem_outlier = (raw_outlier_pmt/tot_claim_length);
      end;
      if (in_hh = 1) then do;
         if (anchor_visit_count ^= 0) and (tot_visit_count ^= 0) then anchor_visit_proportion = (anchor_visit_count/tot_visit_count);
         if (post_dschrg_visit_count ^= 0) and (tot_visit_count ^= 0) then post_dsch_visit_proportion = (post_dschrg_visit_count/tot_visit_count);
         if (post_epi_visit_count ^= 0) and (tot_visit_count ^= 0) then post_epi_visit_proportion = (post_epi_visit_count/tot_visit_count);
      end;

      *for opl;
      if (in_opl = 1) then do;

         anchor_std_cost = standard_allowed_amt;
         anchor_raw_cost = raw_allowed_amt;
         post_dsch_std_cost = standard_allowed_amt;
         post_dsch_raw_cost = raw_allowed_amt;
         post_epi_std_cost = standard_allowed_amt;
         post_epi_raw_cost = raw_allowed_amt;

      end;
      
      *for ip;
      else if (in_ip = 1) then do;

         anchor_std_cost = standard_allowed_amt;
         anchor_raw_cost = raw_allowed_amt;
         post_dsch_wo_outlier_std = 0;
         post_dsch_wo_outlier_raw = 0;
         post_epi_wo_outlier_std = 0;
         post_epi_wo_outlier_raw = 0;
         post_dsch_w_outlier_std = 0;
         post_dsch_w_outlier_raw = 0;
         post_epi_w_outlier_std = 0;
         post_epi_w_outlier_raw = 0;

         *condition A;
         if (prorated = 1) then do;

             *proration for ipps, ltch, and irf providers;
             *condition B;
             if (ipps_provider = 1) or (ltch_flag = 1) or (irf_flag = 1) then do;

                ipps_ltch_irf_provider = 1;

                *calculate the prorated without outlier cost;
                *condition C;
                if (post_dschrg_overlap_days > 0) then do;

                   *calculate non-outlier cost;
                   if (post_dschrg_overlap_days >= (gmlos - 1)) then do;
                      post_dsch_wo_outlier_std = standard_allowed_amt_w_o_outlier;
                      post_dsch_wo_outlier_raw = raw_allowed_amt_w_o_outlier;
                   end;
                   else do;
                      post_dsch_wo_outlier_std = min(((post_dschrg_overlap_days + 1)*std_per_diem_wo_outlier), standard_allowed_amt_w_o_outlier);
                      post_dsch_wo_outlier_raw = min(((post_dschrg_overlap_days + 1)*raw_per_diem_wo_outlier), raw_allowed_amt_w_o_outlier);
                      if (standard_allowed_amt_w_o_outlier > post_dsch_wo_outlier_std) then post_epi_wo_outlier_std = standard_allowed_amt_w_o_outlier - post_dsch_wo_outlier_std;
                      if (raw_allowed_amt_w_o_outlier > post_dsch_wo_outlier_raw) then post_epi_wo_outlier_raw = raw_allowed_amt_w_o_outlier - post_dsch_wo_outlier_raw;
                   end;

                   *calculate the prorated outlier cost;
                   post_dsch_w_outlier_std = (std_per_diem_outlier*post_dschrg_overlap_days);
                   post_dsch_w_outlier_raw = (raw_per_diem_outlier*post_dschrg_overlap_days);
                   if (outlier_pmt > post_dsch_w_outlier_std) then post_epi_w_outlier_std = (std_per_diem_outlier*post_epi_overlap_days);
                   if (raw_outlier_pmt > post_dsch_w_outlier_raw) then post_epi_w_outlier_raw = (raw_per_diem_outlier*post_epi_overlap_days);

                end; %*end of condition C;
                *condition D;
                else if (post_epi_overlap_days > 0) then do;

                  *calculate non-outlier cost;
                  if (post_epi_overlap_days >= (gmlos - 1)) then do;
                     post_epi_wo_outlier_std = standard_allowed_amt_w_o_outlier;
                     post_epi_wo_outlier_raw = raw_allowed_amt_w_o_outlier;
                  end;
                  else do;
                     post_epi_wo_outlier_std = min(((post_epi_overlap_days + 1)*std_per_diem_wo_outlier), standard_allowed_amt_w_o_outlier);
                     post_epi_wo_outlier_raw = min(((post_epi_overlap_days + 1)*raw_per_diem_wo_outlier), raw_allowed_amt_w_o_outlier);
                  end;

                  *calculate the prorated outlier cost;
                  post_epi_w_outlier_std = (std_per_diem_outlier*post_epi_overlap_days);
                  post_epi_w_outlier_raw = (raw_per_diem_outlier*post_epi_overlap_days);

                end; %*end of condition D;

                *calculate final prorated cost amounts;
                post_dsch_std_cost = sum(post_dsch_wo_outlier_std, post_dsch_w_outlier_std);
                post_dsch_raw_cost = sum(post_dsch_wo_outlier_raw, post_dsch_w_outlier_raw);
                post_epi_std_cost = sum(post_epi_wo_outlier_std, post_epi_w_outlier_std);
                post_epi_raw_cost = sum(post_epi_wo_outlier_raw, post_epi_w_outlier_raw);

             end; %*end of condition B;

             *proration for all other providers;
             else do;
                post_dsch_std_cost = post_dsch_episode_proportion*standard_allowed_amt;
                post_dsch_raw_cost = post_dsch_episode_proportion*raw_allowed_amt;
                post_epi_std_cost = post_epi_episode_proportion*standard_allowed_amt;
                post_epi_raw_cost = post_epi_episode_proportion*raw_allowed_amt;
             end;

         end; %*end of condition A;
         else do;
            post_dsch_std_cost = standard_allowed_amt;
            post_dsch_raw_cost = raw_allowed_amt;
            post_epi_std_cost = standard_allowed_amt;
            post_epi_raw_cost = raw_allowed_amt;
         end;


      end;
      
      *for dm;
      else if (in_dm = 1) then do;

         anchor_std_cost = standard_allowed_amt;
         anchor_raw_cost = raw_allowed_amt;
         post_dsch_std_cost = standard_allowed_amt;
         post_dsch_raw_cost = raw_allowed_amt;
         post_epi_std_cost = standard_allowed_amt;
         post_epi_raw_cost = raw_allowed_amt;

      end;
      
      *for pb;
      else if (in_pb = 1) then do;

         anchor_std_cost = standard_allowed_amt;
         anchor_raw_cost = raw_allowed_amt;
         post_dsch_std_cost = standard_allowed_amt;
         post_dsch_raw_cost = raw_allowed_amt;
         post_epi_std_cost = standard_allowed_Amt;
         post_epi_raw_cost = raw_allowed_amt;

      end;
      
      *for snf;
      else if (in_sn = 1) then do;

         if (prorated = 1) then do;
            anchor_std_cost = anchor_episode_proportion * standard_allowed_amt;
            anchor_raw_cost = anchor_episode_proportion * raw_allowed_amt;
            post_dsch_std_cost = post_dsch_episode_proportion * standard_allowed_amt;
            post_dsch_raw_cost = post_dsch_episode_proportion * raw_allowed_amt;
            post_epi_std_cost = post_epi_episode_proportion * standard_allowed_amt;
            post_epi_raw_cost = post_epi_episode_proportion * raw_allowed_amt;
         end; 
         else do;
            anchor_std_cost = standard_allowed_amt;
            anchor_raw_cost = raw_allowed_amt;
            post_dsch_std_cost = standard_allowed_amt;
            post_dsch_raw_cost = raw_allowed_amt;
            post_epi_std_cost = standard_allowed_amt;
            post_epi_raw_cost = raw_allowed_amt;
         end;

      end;
      
      *for hs;
      else if (in_hs = 1) then do;

         if (prorated = 1) then do;
            anchor_std_cost = anchor_episode_proportion * standard_allowed_amt;
            anchor_raw_cost = anchor_episode_proportion * raw_allowed_amt;
            post_dsch_std_cost = post_dsch_episode_proportion * standard_allowed_amt;
            post_dsch_raw_cost = post_dsch_episode_proportion * raw_allowed_amt;
            post_epi_std_cost = post_epi_episode_proportion * standard_allowed_amt;
            post_epi_raw_cost = post_epi_episode_proportion * raw_allowed_amt;
         end;
         else do;
            anchor_std_cost = standard_allowed_amt;
            anchor_raw_cost = raw_allowed_amt;
            post_dsch_std_cost = standard_allowed_amt;
            post_dsch_raw_cost = raw_allowed_amt;
            post_epi_std_cost = standard_allowed_amt;
            post_epi_raw_cost = raw_allowed_amt;
         end;

      end;
      
      *for hh;
      else if (in_hh = 1) then do;

         if (lupa_flag = 1) then do;
            anchor_std_cost = anchor_visit_proportion * standard_allowed_amt;
            anchor_raw_cost = anchor_visit_proportion * raw_allowed_amt;
            post_dsch_std_cost = post_dsch_visit_proportion * standard_allowed_amt;
            post_dsch_raw_cost = post_dsch_visit_proportion * raw_allowed_amt;
            post_epi_std_cost = post_epi_visit_proportion * standard_allowed_amt;
            post_epi_raw_cost = post_epi_visit_proportion * raw_allowed_amt;
         end;
         else do;
            if (prorated = 1) then do;
               anchor_std_cost = anchor_episode_proportion * standard_allowed_amt;
               anchor_raw_cost = anchor_episode_proportion * raw_allowed_amt;
               post_dsch_std_cost = post_dsch_episode_proportion * standard_allowed_amt;
               post_dsch_raw_cost = post_dsch_episode_proportion * raw_allowed_amt;
               post_epi_std_cost = post_epi_episode_proportion * standard_allowed_amt;
               post_epi_raw_cost = post_epi_episode_proportion * raw_allowed_amt;
            end;
            else do;
               anchor_std_cost = standard_allowed_amt; 
               anchor_raw_cost = raw_allowed_amt;
               post_dsch_std_cost = standard_allowed_amt;
               post_dsch_raw_cost = raw_allowed_amt;
               post_epi_std_cost = standard_allowed_amt;
               post_epi_raw_cost = raw_allowed_amt;
            end;
         end;
      end;
      
      *calculate costs by settings for each episode;
      if (ep_cost.find(key: episode_id) ^= 0) then do;

         *initialize all cost variables;
         %do a = 1 %to &ncost_vars.;
            &&cost_vars&a.. = 0;
         %end;
         
         *count the number of claims that were prorated for each episode;
         if (prorated = 1) then do;
            %do a = 1 %to &nsettings.; 
               if (in_&&settings&a.. = 1) then do;
                  num_prorated_claims_&&settings&a.. = 1;
               end;
               %if &a. ^= &nsettings. %then else;
            %end;
         end;
         *count the number of claims were not prorated for each episode;
         else do;
            %do a = 1 %to &nsettings.; 
               if (in_&&settings&a.. = 1) then do;
                  num_unprorated_claims_&&settings&a.. = 1;
               end;
               %if &a. ^= &nsettings. %then else;
            %end;
         end;

         *calculate anchor, post-discharge, and post-episode cost categories;
         %do a = 1 %to &nsettings.;
            if (in_&&settings&a.. = 1) then do;
               if (lowcase(cost_category) in ("anchor period" "prorated - anchor period only" "prorated - anchor and post-discharged periods" "prorated - anchor and post-episode periods" "prorated - anchor, post-discharged, post-episode periods")) then do;
                  anchor_std_allowed_&&settings&a.. = anchor_std_cost;
                  anchor_raw_allowed_&&settings&a.. = anchor_raw_cost;
               end;
               if (lowcase(cost_category) in ("post-discharged period" "prorated - post-discharged period only" "prorated - anchor and post-discharged periods" "prorated - post-discharged and post-episode periods" "prorated - anchor, post-discharged, post-episode periods")) then do;
                   post_dsch_std_allowed_&&settings&a.. = post_dsch_std_cost;
                   post_dsch_raw_allowed_&&settings&a.. = post_dsch_raw_cost;
               end;
               if (lowcase(cost_category) in ("post-episode period" "prorated - post-episode period only" "prorated - anchor and post-episode periods" "prorated - post-discharged and post-episode periods" "prorated - anchor, post-discharged, post-episode periods")) then do;
                  post_epi_std_allowed_&&settings&a.. = post_epi_std_cost;
                  post_epi_raw_allowed_&&settings&a.. = post_epi_raw_cost;
               end;
            end;
            %if &a. ^= &nsettings. %then else;
         %end;

         *calculate total;
         %do a = 1 %to &nsettings.; 
            if (in_&&settings&a.. = 1) then do;
               num_claims_&&settings&a.. = sum(num_prorated_claims_&&settings&a.., num_unprorated_claims_&&settings&a..);
               tot_std_allowed_&&settings&a.. = sum(anchor_std_allowed_&&settings&a.., post_dsch_std_allowed_&&settings&a..);
               tot_raw_allowed_&&settings&a.. = sum(anchor_raw_allowed_&&settings&a.., post_dsch_raw_allowed_&&settings&a..);
            end;
            %if &a. ^= &nsettings. %then else;
         %end;

         tot_num_claims = sum(%do a = 1 %to &nsettings.; num_claims_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_prorated_claims = sum(%do a = 1 %to &nsettings.; num_prorated_claims_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_unprorated_claims = sum(%do a = 1 %to &nsettings.; num_unprorated_claims_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_anchor_std_allowed = sum(%do a = 1 %to &nsettings.; anchor_std_allowed_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_post_dsch_std_allowed = sum(%do a = 1 %to &nsettings.; post_dsch_std_allowed_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_post_epi_std_allowed = sum(%do a = 1 %to &nsettings.; post_epi_std_allowed_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_std_allowed = sum(tot_anchor_std_allowed, tot_post_dsch_std_allowed);
         tot_anchor_raw_allowed = sum(%do a = 1 %to &nsettings.; anchor_raw_allowed_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_post_dsch_raw_allowed = sum(%do a = 1 %to &nsettings.; post_dsch_raw_allowed_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_post_epi_raw_allowed = sum(%do a = 1 %to &nsettings.; post_epi_raw_allowed_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_raw_allowed = sum(tot_anchor_raw_allowed, tot_post_dsch_raw_allowed);

         ep_cost.add();

      end;
      else do;

         *count the number of claims that were prorated for each episode;
         if (prorated = 1) then do;
            %do a = 1 %to &nsettings.; 
               if (in_&&settings&a.. = 1) then do;
                  num_prorated_claims_&&settings&a.. = num_prorated_claims_&&settings&a.. + 1;
               end;
               %if &a. ^= &nsettings. %then else;
           %end;
         end;
         *count the number of claims were not prorated for each episode;
         else do;
            %do a = 1 %to &nsettings.;
               if (in_&&settings&a.. = 1) then do;
                  num_unprorated_claims_&&settings&a.. = num_unprorated_claims_&&settings&a.. + 1;
               end;
               %if &a. ^= &nsettings. %then else;
            %end;
         end;

         *calculate anchor and post-discharge cost categories;
         %do a = 1 %to &nsettings.;
            if (in_&&settings&a.. = 1) then do;
               if (lowcase(cost_category) in ("anchor period" "prorated - anchor period only" "prorated - anchor and post-discharged periods" "prorated - anchor and post-episode periods" "prorated - anchor, post-discharged, post-episode periods")) then do;
                  anchor_std_allowed_&&settings&a.. = sum(anchor_std_allowed_&&settings&a.., anchor_std_cost);
                  anchor_raw_allowed_&&settings&a.. = sum(anchor_raw_allowed_&&settings&a.., anchor_raw_cost);
               end;
               if (lowcase(cost_category) in ("post-discharged period" "prorated - post-discharged period only" "prorated - anchor and post-discharged periods" "prorated - post-discharged and post-episode periods" "prorated - anchor, post-discharged, post-episode periods")) then do;
                  post_dsch_std_allowed_&&settings&a.. = sum(post_dsch_std_allowed_&&settings&a.., post_dsch_std_cost);
                  post_dsch_raw_allowed_&&settings&a.. = sum(post_dsch_raw_allowed_&&settings&a.., post_dsch_raw_cost);
               end;
               if (lowcase(cost_category) in ("post-episode period" "prorated - post-episode period only" "prorated - anchor and post-episode periods" "prorated - post-discharged and post-episode periods" "prorated - anchor, post-discharged, post-episode periods")) then do;
                  post_epi_std_allowed_&&settings&a.. = sum(post_epi_std_allowed_&&settings&a.., post_epi_std_cost);
                  post_epi_raw_allowed_&&settings&a.. = sum(post_epi_raw_allowed_&&settings&a.., post_epi_raw_cost);
               end;
            end;
            %if &a. ^= &nsettings. %then else;
         %end;

         *calculate total;
         %do a = 1 %to &nsettings.; 
            if (in_&&settings&a.. = 1) then do;
               num_claims_&&settings&a.. = sum(num_prorated_claims_&&settings&a.., num_unprorated_claims_&&settings&a..);
               tot_std_allowed_&&settings&a.. = sum(anchor_std_allowed_&&settings&a.., post_dsch_std_allowed_&&settings&a..);
               tot_raw_allowed_&&settings&a.. = sum(anchor_raw_allowed_&&settings&a.., post_dsch_raw_allowed_&&settings&a..);
            end;
            %if &a. ^= &nsettings. %then else;
         %end;
         tot_num_claims = sum(%do a = 1 %to &nsettings.; num_claims_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_prorated_claims = sum(%do a = 1 %to &nsettings.; num_prorated_claims_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_unprorated_claims = sum(%do a = 1 %to &nsettings.; num_unprorated_claims_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_anchor_std_allowed = sum(%do a = 1 %to &nsettings.; anchor_std_allowed_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_post_dsch_std_allowed = sum(%do a = 1 %to &nsettings.; post_dsch_std_allowed_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_post_epi_std_allowed = sum(%do a = 1 %to &nsettings.; post_epi_std_allowed_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_std_allowed = sum(tot_anchor_std_allowed, tot_post_dsch_std_allowed);
         tot_anchor_raw_allowed = sum(%do a = 1 %to &nsettings.; anchor_raw_allowed_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_post_dsch_raw_allowed = sum(%do a = 1 %to &nsettings.; post_dsch_raw_allowed_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_post_epi_raw_allowed = sum(%do a = 1 %to &nsettings.; post_epi_raw_allowed_&&settings&a.. %if &a. ^= &nsettings. %then ,; %end;);
         tot_raw_allowed = sum(tot_anchor_raw_allowed, tot_post_dsch_raw_allowed);

         ep_cost.replace();

      end;

      *determine the final payment amounts used for a claim;
      std_cost_epi_total = 0; raw_cost_epi_total = 0;
      std_cost_anchor = 0; raw_cost_anchor = 0;
      std_cost_post_dsch = 0; raw_cost_post_dsch = 0;
      std_cost_post_epi = 0; raw_cost_post_epi = 0;
      std_cost_post_dsch_wo_outlier = 0; std_cost_post_dsch_w_outlier = 0;
      raw_cost_post_dsch_wo_outlier = 0; raw_cost_post_dsch_w_outlier = 0;
      std_cost_post_epi_wo_outlier = 0; std_cost_post_epi_w_outlier = 0;
      raw_cost_post_epi_wo_outlier = 0; raw_cost_post_epi_w_outlier = 0;

      if (lowcase(cost_category) in ("anchor period" "prorated - anchor period only" "prorated - anchor and post-discharged periods" "prorated - anchor and post-episode periods" "prorated - anchor, post-discharged, post-episode periods")) then do;
         std_cost_anchor = anchor_std_cost;
         raw_cost_anchor = anchor_raw_cost;
      end;
      if (lowcase(cost_category) in ("post-discharged period" "prorated - post-discharged period only" "prorated - anchor and post-discharged periods" "prorated - post-discharged and post-episode periods" "prorated - anchor, post-discharged, post-episode periods")) then do;
          std_cost_post_dsch = post_dsch_std_cost;
          raw_cost_post_dsch = post_dsch_raw_cost;
          if (prorated = 1) and (ipps_ltch_irf_provider = 1) then do;
             std_cost_post_dsch_wo_outlier = post_dsch_wo_outlier_std;
             std_cost_post_dsch_w_outlier = post_dsch_w_outlier_std;
             raw_cost_post_dsch_wo_outlier = post_dsch_wo_outlier_raw;
             raw_cost_post_dsch_w_outlier = post_dsch_w_outlier_raw;
          end;
      end;
      if (lowcase(cost_category) in ("post-episode period" "prorated - post-episode period only" "prorated - anchor and post-episode periods" "prorated - post-discharged and post-episode periods" "prorated - anchor, post-discharged, post-episode periods")) then do;
         std_cost_post_epi = post_epi_std_cost;
         raw_cost_post_epi = post_epi_raw_cost;
         if (prorated = 1) and (ipps_ltch_irf_provider = 1) then do;
             std_cost_post_epi_wo_outlier = post_epi_wo_outlier_std;
             std_cost_post_epi_w_outlier = post_epi_w_outlier_std;
             raw_cost_post_epi_wo_outlier = post_epi_wo_outlier_raw;
             raw_cost_post_epi_w_outlier = post_epi_w_outlier_raw;
         end;
      end;
      std_cost_epi_total = sum(std_cost_anchor, std_cost_post_dsch);
      raw_cost_epi_total = sum(raw_cost_anchor, raw_cost_post_dsch);

      if last then ep_cost.output(dataset: "temp.episode_grouped_costs");

   run;
   
   *gather grouped claims with COVID-19 flag on;
   data temp.episode_grouped_covid19 (keep = episode_id file_type cost_category link_id claimno lineitem ip_stay_id service_start_dt service_end_dt dgnscd: pvisit: ad_dgns linedgns covid_19_clm);
      set %do a = 1 %to &nsettings.; 
             temp.grp_&&settings&a.._clms_to_epi (where = ((covid_19_clm = 1) and (lowcase(cost_category) not in ("post-episode period" "prorated - post-episode period only"))))
          %end;
          ;
   run;

   proc sort nodupkey data = temp.episode_grouped_covid19 (keep = episode_id) out = temp.epi_level_grp_covid19;
      by episode_id;
   run;

   *gather ungrouped claims with COVID-19 flag on;
   data temp.episode_ungrouped_covid19 (keep = episode_id file_type cost_category link_id claimno lineitem ip_stay_id service_start_dt service_end_dt dgnscd: pvisit: ad_dgns linedgns covid_19_clm);
      set %do a = 1 %to &nsettings.; 
             temp.ungrp_&&settings&a.._clms_to_epi (where = ((covid_19_clm = 1) and (lowcase(cost_category) not in ("post-episode period" "prorated - post-episode period only"))))
          %end;
          ;
   run;

   proc sort nodupkey data = temp.episode_ungrouped_covid19 (keep = episode_id) out = temp.epi_level_ungrp_covid19;
      by episode_id;
   run;

   *merge on grouped costs information and add COVID-19 flag;
   data temp.episodes_w_costs;

      length num_prorated_claims_hh num_unprorated_claims_hh num_claims_hh anchor_std_allowed_hh anchor_raw_allowed_hh post_dsch_std_allowed_hh post_dsch_raw_allowed_hh
             post_epi_std_allowed_hh post_epi_raw_allowed_hh tot_std_allowed_hh tot_raw_allowed_hh covid_19_flag covid_19_flag_ungrp 8.;
      if _n_ = 1 then do;
         
         *COVID-19 flag of grouped claims;
         if 0 then set temp.epi_level_grp_covid19 (keep = episode_id);
         declare hash grp_cov (dataset: "temp.epi_level_grp_covid19 (keep = episode_id)");
         grp_cov.definekey("episode_id");
         grp_cov.definedone();

         *COVID-19 flag of ungrouped claims;
         if 0 then set temp.epi_level_ungrp_covid19 (keep = episode_id);
         declare hash ungrp_cov (dataset: "temp.epi_level_ungrp_covid19 (keep = episode_id)");
         ungrp_cov.definekey("episode_id");
         ungrp_cov.definedone();
      end;
      call missing(of _all_);
      
      merge temp.episodes_w_dropflags
            temp.episode_grouped_costs
            ;
      by episode_id;

      *set all missings to zeroes;
      %do a = 1 %to &ncost_vars.;
         if missing(&&cost_vars&a..) then &&cost_vars&a.. = 0;
      %end;

      *add COVID-19 flag;
      if grp_cov.find(key: episode_id) = 0 and (anchor_beg_dt >= "01JAN2020"D) then covid_19_flag = 1;
      else covid_19_flag = 0;

      *add COVID-19 flag of ungrouped claims;
      if ungrp_cov.find(key: episode_id) = 0 and (anchor_beg_dt >= "01JAN2020"D) then covid_19_flag_ungrp = 1;
      else covid_19_flag_ungrp = 0;
   run;

%mend;

