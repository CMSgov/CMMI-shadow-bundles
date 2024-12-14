/*************************************************************************;
%** PROGRAM: f5_add_prior_hosp_flags.sas
%** PURPOSE: To add indicator for beneficiary that utilized any post-acute care services prior to the episodes
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

%macro f5_add_prior_hosp_flags();

   %macarray(clmtypes, ip sn hh);
   
   *use the raw claim extracts for hh sn and ip and merge it with episodes to obtain all the claims associated with prior pac utlitization;
   data temp.episodes_w_prior_hosp (drop = rc_: prior_from_dt prior_thru_dt ltch_stay irf_stay);
         
      if _n_ = 1 then do;
         *list of hh sn and ip claims;
         %do i= 1 %to &nclmtypes; %let clmtype= &&clmtypes&i..;
            %if "&clmtype."="ip" %then %do;
            if 0 then set temp.cleaned_&clmtype._stays (keep = link_id admsn_dt dschrgdt ltch_stay irf_stay rename = (admsn_dt = prior_from_dt dschrgdt = prior_thru_dt));
            declare hash &clmtype. (dataset: "temp.cleaned_&clmtype._stays (keep = link_id admsn_dt dschrgdt ltch_stay irf_stay overlap_keep_inner_outer rename = (admsn_dt = prior_from_dt dschrgdt = prior_thru_dt) where= (overlap_keep_inner_outer = 1))", multidata: "y");
            %end;
            %else %do;
            if 0 then set clm_inp.&clmtype. (keep = link_id from_dt thru_dt rename = (from_dt = prior_from_dt thru_dt = prior_thru_dt));
            declare hash &clmtype. (dataset: "clm_inp.&clmtype. (keep = link_id from_dt thru_dt positive_payment_clm rename = (from_dt = prior_from_dt thru_dt = prior_thru_dt) where = (positive_payment_clm = 1))", multidata: "y");
            %end;

            &clmtype..definekey("link_id");
            &clmtype..definedata("prior_from_dt" , "prior_thru_dt" %if "&clmtype."="ip" %then %do; ,"ltch_stay" ,"irf_stay" %end;);
            &clmtype..definedone();
         %end;
      end;
      call missing(of _all_);

      set temp.episodes_w_cvd_inf_rt;
      
      ltch_flag = 0;
      irf_flag = 0;
      sn_flag = 0;
      hh_flag = 0;
      prior_pac_flag = 0;
      prior_hosp_w_non_pac_ip_flag_&lookback_days. = 0;

      %do i= 1 %to &nclmtypes; %let clmtype= &&clmtypes&i..;
         rc_&clmtype. = &clmtype..find();
         do while(rc_&clmtype. = 0);
            if (anchor_beg_dt > prior_from_dt) and ((anchor_beg_dt - &lookback_days.) <= prior_thru_dt < anchor_beg_dt) then do;
               %if "&clmtype." = "ip" %then %do;
                  if ltch_stay = 0 and irf_stay = 0 then prior_hosp_w_non_pac_ip_flag_&lookback_days. = 1;

                  if ltch_stay = 1 then ltch_flag = 1;

                  if irf_stay = 1 then irf_flag = 1;
               %end;
               %else %do;
                  &clmtype._flag = 1; 
               %end;   
            end;
            rc_&clmtype. = &clmtype..find_next(); 
         end;
      %end;

      if ltch_flag = 1 or irf_flag = 1 or sn_flag = 1 or hh_flag = 1 then prior_pac_flag = 1;
   run;
   
%mend; 
