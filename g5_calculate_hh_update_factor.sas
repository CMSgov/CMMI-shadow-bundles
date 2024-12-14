/*************************************************************************;
%** PROGRAM: g5_calculate_hh_update_factor.sas
%** PURPOSE: To calculate HH update factor for post-anchor period cost
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

%macro g5_calculate_hh_update_factor();
      
   /*PROCESS HH CLAIMS TO BE USED IN CALCULATING UPDATE FACTOR*/
   *the HH update factor considers how the HH base rates and HHRG weights change between the baseline and performance years;
   *make the HH dataset from wide to long;
   data temp.hh_price_update_lines (drop = %do a = 1 %to &rev_array_size.; %let b = %sysfunc(putn(&a., z2.)); rvcntr&b. rvunt&b. hcpscd&b. %end; fac_code fac_code_descrip);

      if _n_ = 1 then do;
         *list of revenue center code identifying a home health facility;
         if 0 then set temp.facility_rev_center_codes (keep = fac_code fac_code_descrip where = (lowcase(fac_code_descrip) = "home health"));
         declare hash hh_rev (dataset: "temp.facility_rev_center_codes (keep = fac_code fac_code_descrip where = (lowcase(fac_code_descrip) = 'home health'))");
         hh_rev.definekey("fac_code");
         hh_rev.definedone();
      end;
      call missing(of _all_);

      *filter down to non-LUPA HH claims;
      set temp.grp_hh_for_updates (where = (lupa_flag = 0));
      
      if year(hh_thru_dt)<2020 then episode_cap=60;
      else if year(hh_thru_dt)=2020 and year(hh_from_dt)=2019 then episode_cap=60;
      else episode_cap=30;
      
      %do a = 1 %to &rev_array_size.;
         %let b = %sysfunc(putn(&a., z2.));
         rvcntr = rvcntr&b.;
         rvunt = rvunt&b.;
         hcpscd = hcpscd&b.;
         apchipps=apcpps&b.;
         hhrg = substr(hcpscd, 1, 4);
         hhrg_pdgm=substr(apchipps, 1, 4);
         
         if not missing(hhrg_pdgm) and verify(strip(hhrg_pdgm),'0')^=0 then do; hhrg_pdgm=hhrg_pdgm; end;
         else do; hhrg_pdgm=hhrg; end;
         
         if (hh_rev.find(key: rvcntr) = 0) then output temp.hh_price_update_lines;
      %end;

   run;

   data temp.hh_lines_w_weights (drop = rc_: weight effective_date);
      
      if _n_ = 1 then do;
      
         *peer group characteristics;
         if 0 then set temp.episodes_w_safety_net (keep = episode_id &peer_group_list.);
         declare hash get_peer_group (dataset: "temp.episodes_w_safety_net (keep = episode_id &peer_group_list.)");
         get_peer_group.definekey("episode_id");
         get_peer_group.definedata(all: "y");
         get_peer_group.definedone();
         
         *list of all hhrgs in 2019;
         if 0 then set hhrg.hhrg_weights_&hhrg_end_year. (keep = hhrg weight effective_date);
         declare hash get_hhrg (dataset: "hhrg.hhrg_weights_&hhrg_end_year. (keep = hhrg weight effective_date)", multidata: "y");
         get_hhrg.definekey("hhrg");
         get_hhrg.definedata("weight", "effective_date");
         get_hhrg.definedone();
         
         *PDGM went in to effect 2020;
         %do year = %eval(&hhrg_end_year.+1) %to &update_factor_cy.;
            if 0 then set hhrg.hhrg_weights_&year.;
            declare hash hhrg_pdgm_weights_&year.(dataset: "hhrg.hhrg_weights_&year.", multidata: "y");
            hhrg_pdgm_weights_&year..definekey("hhrg");
            hhrg_pdgm_weights_&year..definedata("effective_date","weight");
            hhrg_pdgm_weights_&year..definedone();
         %end;

      end;
      call missing(of _all_);

      set temp.hh_price_update_lines;

      *determine hh year as fiscal year of anchor end date;
      %do year = &baseline_start_year.+1 %to &baseline_end_year.;
         %let prev_year = %eval(&year.-1);
         if ("01OCT&prev_year."D <= anchor_end_dt <= "30SEP&year."D) then hh_year = &year.;
         %if &year. ^= &baseline_end_year. %then else;
      %end;
      
      *get peer group characteristics; 
      if get_peer_group.find(key: episode_id) ^= 0 then abort;

      *add HHRG values to HH lines;
      if (get_hhrg.find(key: hhrg) = 0) then do;
         rc_get_hhrg = 0;
         do while (rc_get_hhrg = 0);
            %do year = &baseline_start_year. %to &hhrg_end_year.;
               *NOTE: use the HHRG weight that was effective 01JAN2012 for the 2013 HHRG weight mapping;
               %if (&year. = 2013) %then %do;
                  if (year(effective_date) = 2012) then hhrg_wght_&year. = weight;
               %end;
               %else %do;
                  if (year(effective_date) = &year.) then hhrg_wght_&year. = weight;
               %end;
            %end;
            rc_get_hhrg = get_hhrg.find_next();
         end;
      end;
      %do year = %eval(&hhrg_end_year.+1) %to &update_factor_cy.;     
         if hhrg_pdgm_weights_&year..find(key:hhrg_pdgm) = 0 then do;
            hhrg_wght_&year. = weight;
         end;
      %end;
      
      *coalesce takes the first nonmissing value- until 2019, HHRG system was in place;
      %do year = %eval(&baseline_start_year.+1) %to &hhrg_end_year.;
         %let coalesce_list = ;
         %do yr = &baseline_start_year. %to &year.;
            %let coalesce_list = hhrg_wght_&yr. &coalesce_list.;
         %end;
         hhrg_wght_&year. = coalesce(%clist(&coalesce_list.));
      %end;
       *coalesce takes the first nonmissing value- starting 2020, PDGM system came in;
       %do year = %eval(&hhrg_end_year.+1) %to &update_factor_cy.;
          %let coalesce_list = ;
          %do yr = %eval(&hhrg_end_year.+1) %to &year.;
             %let coalesce_list = hhrg_wght_&yr. &coalesce_list.;
          %end;
          hhrg_wght_&year. = coalesce(%clist(&coalesce_list.));
      %end;
      
      *if all weights are populated then output;
      if %do year = &baseline_start_year. %to &hhrg_end_year.; 
         not missing(hhrg_wght_&year.) %if &year. ^= &hhrg_end_year.
      %then and; %end; then output temp.hh_lines_w_weights;
      
      if %do year = %eval(&hhrg_end_year.+1) %to &update_factor_cy.; 
      not missing(hhrg_wght_&year.) %if &year. ^= &update_factor_cy. 
      %then and; %end; then output temp.hh_lines_w_weights;
   run;

   proc sql;
      create table temp.hh_update_ccn as
      select distinct 
         anchor_provider,
         %clist(&peer_group_list.), 
         episode_group_name,
         hh_year,
         count(distinct episode_id) as num_epis,
         count(distinct claimno) as num_claims,
         sum(rvunt) as num_days,
         %do year = &baseline_start_year.+1 %to &update_factor_cy.;
            sum(hhrg_wght_&year.*rvunt/episode_cap)/ calculated num_days as hhrg&year.
            %if &year. ^= &update_factor_cy. %then ,;
         %end;
      from temp.hh_lines_w_weights
      group by anchor_provider, %clist(&peer_group_list.), episode_group_name, hh_year
      ;
   quit;
   
   *calculate number of final episodes of each CCN;
   proc sql noprint;
      create table temp.ccn_epi_counts as
      select distinct 
         anchor_provider,
         episode_group_name,
         count(distinct episode_id) as epis
      from temp.episodes_w_safety_net (where = (final_episode = 1 and dropflag_episode_overlap = 0))
      group by anchor_provider, episode_group_name;
   quit;
   
   /*CALCULATE HH UPDATE FACTOR*/
   data temp.hh_update_ccn;

      if _n_ = 1 then do;

         *list of ACHs that meet episode threshold;
         if 0 then set temp.ccn_epi_counts (keep = anchor_provider episode_group_name);
         declare hash elig_ach (dataset: "temp.ccn_epi_counts (keep = anchor_provider episode_group_name epis where = (epis > &num_epis_hh.))");
         elig_ach.definekey("anchor_provider", "episode_group_name");
         elig_ach.definedone(); 

      end;
      call missing(of _all_);

      length hh_update_factor 8.;
      set temp.hh_update_ccn;
      
      *identify hospitals that meet episode threshold; 
      elig_ach_flag = 0;
      if elig_ach.find(key: anchor_provider, key: episode_group_name) = 0 then elig_ach_flag = 1;

      *calculate the update for each CCN;
      %do year = %eval(&baseline_start_year.+1) %to &baseline_end_year.;
      
         if (hh_year = &year.) then do;
         
            %let prev_year = %eval(&year.-1);

            current_year_rate = &&hh_base_rate_&year..;
            prev_year_rate = &&hh_base_rate_&prev_year..;
            updt_year_rate = &&hh_base_rate_&update_factor_cy..;
            
            *for FY2020;
            if hh_year = %eval(&hhrg_end_year.+1) then do;
               if missing (hhrg&update_factor_cy.) then hhrg&update_factor_cy. = 0;
               if missing (hhrg&year.) then hhrg&year.=0;               
               numerator   = updt_year_rate * hhrg&update_factor_cy.;
               denominator = current_year_rate * hhrg&year.; 
               if not missing(denominator) then hh_update_factor = numerator/denominator;
            end;  
            *for after FY2020;
            else if hh_year > %eval(&hhrg_end_year.+1) then do;
               denominator = &hh_cur_yr_wgt.*current_year_rate*hhrg&year. + &hh_prev_yr_wgt.*prev_year_rate*hhrg&prev_year.;
               numerator = updt_year_rate * hhrg&update_factor_cy.;
               if not missing(denominator) then hh_update_factor=numerator/denominator;
               %*none of hh claims after 2020 or after should have missing update factor; 
               if missing(hh_update_factor) then abort abend;
            end;    
         end;
         %if &year. ^= &baseline_end_year. %then else;
      %end;
   run;
   
   *calculate average update factor to impute claims (in or before FY2020) with missing update factors; 
   proc sql;
      *FY-CEC-peer group level average; 
      create table temp.hh_avg_uf_year_cec_peer as
      select 
         hh_year, 
         episode_group_name, 
         %clist(&peer_group_list.),   
         mean(hh_update_factor) as hh_update_factor_year_cec_peer
      from temp.hh_update_ccn (where = (elig_ach_flag = 1))  
      group by hh_year, episode_group_name, %clist(&peer_group_list.)
      ;
      
      *FY-CEC level average; 
      create table temp.hh_avg_uf_year_cec as
      select distinct 
         hh_year, 
         episode_group_name,  
         mean(hh_update_factor) as hh_update_factor_year_cec
      from temp.hh_update_ccn (where = (elig_ach_flag = 1))
      group by hh_year, episode_group_name
      ; 
   quit;     


   data temp.hh_post_anchor_update_factor;
      if _n_ = 1 then do;

         *FY-CEC-peer group level average; 
         if 0 then set temp.hh_avg_uf_year_cec_peer;
         declare hash uf_ycp (dataset: "temp.hh_avg_uf_year_cec_peer");
         uf_ycp.definekey("hh_year", "episode_group_name", %clist(%quotelst(&peer_group_list.)));
         uf_ycp.definedata("hh_update_factor_year_cec_peer");
         uf_ycp.definedone();

         *FY-CEC level average;
         if 0 then set temp.hh_avg_uf_year_cec;
         declare hash uf_yc (dataset: "temp.hh_avg_uf_year_cec");
         uf_yc.definekey("hh_year", "episode_group_name");
         uf_yc.definedata("hh_update_factor_year_cec");
         uf_yc.definedone();

      end;
      call missing(of _all_);

      set temp.hh_update_ccn;
      
      if uf_ycp.find() = 0 then hh_update_factor_year_cec_peer = hh_update_factor_year_cec_peer;
      if uf_yc.find()  = 0 then hh_update_factor_year_cec      = hh_update_factor_year_cec;

      *if any anchor provider, cec, hh year has missing update factor, impute them using the average hh year-cec-peer group update factor of only ELIGIBLE ACHs; 
      if missing(hh_update_factor) then hh_update_factor = hh_update_factor_year_cec_peer;
      *if still missing, impute them using the average hh year-cec update factor of only ELIGIBLE ACHs;      
      if missing(hh_update_factor) then hh_update_factor = hh_update_factor_year_cec;
      
      %*everyone should have update factor now; 
      if missing(hh_update_factor) then abort; 
   run;
   
   proc sort data = temp.hh_post_anchor_update_factor; by anchor_provider episode_group_name hh_year; run; 
%mend; 
