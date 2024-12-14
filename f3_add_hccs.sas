/*************************************************************************;
%** PROGRAM: f3_add_hccs.sas
%** PURPOSE: To add HCC flags
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

%macro f3_add_hccs();
   
   *list of HCCs;
   %macarray(hcc_vars, &all_hccs.);
   *list of hcc interaction terms;
   %macarray(hcc_ints, &hcc_interact_list.);

   data temp.stay_ccs;
      
      if _n_ = 1 then do;
         
         *all bpci episodes;
         if 0 then set temp.episodes_w_prov_ra (keep = link_id disabl episode_id anchor_beg_dt anchor_lookback_dt);
         declare hash epis (dataset: "temp.episodes_w_prov_ra (keep = link_id disabl episode_id anchor_beg_dt anchor_lookback_dt)", multidata: "y");
         epis.definekey("link_id");
         epis.definedata(all: "y");
         epis.definedone();

      end;
      call missing(of _all_);

      set clm_inp.cc_v&cc_version. (keep = link_id thru_dt cc_v&cc_version. rename = (cc_v&cc_version. = cc));

      if (cc > 189) then cc = -1;
      *find all CCs that overlap with the lookback period;
      if (epis.find(key: link_id) = 0) then do;
         rc_epis = 0;
         do while (rc_epis = 0);
            *NOTE: make sure to start one day prior to anchor begin date as to not include the anchor begin date in HCC construction;
            if (anchor_lookback_dt <= thru_dt <= anchor_beg_dt - 1) then output temp.stay_ccs;
            rc_epis = epis.find_next();
         end;
      end;

   run;

   proc sort nodupkey data = temp.stay_ccs;
      by link_id episode_id cc;
   run;

   data temp.stay_hccs (keep = link_id episode_id &all_hccs. &hcc_interact_list.);

      set temp.stay_ccs;
      by link_id episode_id;

      retain cc1-cc189 8. hcc1-hcc189;
      array ccs {189} 8. cc1-cc189;
      array hcc {189} 8. hcc1-hcc189;

      if first.episode_id then do i = 1 to 189;
         ccs(i) = 0;
      end;
      if (cc > 0) then ccs(cc) = 1;

      if last.episode_id then do;

         do i = 1 to 189;
            hcc(i) = ccs(i);
         end;

         *implement hierarchy. the idea is that within each disease category, we keep only the lowest numbered hcc (the lowest numbered hcc is the most severe manifestation of the condition);
         /*neoplasm 1*/    if hcc8=1 then do i=9,10,11,12;hcc(i)=0;end;
         /*neoplasm 2*/    if hcc9=1 then do i=10,11,12;hcc(i)=0;end;
         /*neoplasm 3*/    if hcc10=1 then do i=11,12;hcc(i)=0;end;
         /*neoplasm 4*/    if hcc11=1 then do i=12;hcc(i)=0;end;
         /*diabetes 1*/    if hcc17=1 then do i=18, 19;hcc(i)=0;end;
         /*diabetes 2*/    if hcc18=1 then do i=19;hcc(i)=0;end;
         /*liver 1*/       if hcc27=1 then do i=28, 29, 80;hcc(i)=0;end;
         /*liver 2*/       if hcc28=1 then do i=29;hcc(i)=0;end;
         /*blood 1*/       if hcc46=1 then do i=48;hcc(i)=0;end;
         /*sa1*/           if hcc54=1 then do i=55;hcc(i)=0;end;
         /*psychiatric 1*/ if hcc57=1 then do i=58;hcc(i)=0;end;
         /*spinal 1*/      if hcc70=1 then do i=71, 72, 103, 104, 169;hcc(i)=0;end;
         /*spinal 2*/      if hcc71=1 then do i=72, 104, 169;hcc(i)=0;end;
         /*spinal 3*/      if hcc72=1 then do i=169;hcc(i)=0;end;
         /*arrest 1*/      if hcc82=1 then do i=83, 84;hcc(i)=0;end;
         /*arrest 2*/      if hcc83=1 then do i=84;hcc(i)=0;end;
         /*heart 2*/       if hcc86=1 then do i=87, 88;hcc(i)=0;end;
         /*heart 3*/       if hcc87=1 then do i=88;hcc(i)=0;end;
         /*cvd 1*/         if hcc99=1 then do i=100;hcc(i)=0;end;
         /*cvd 5*/         if hcc103=1 then do i=104;hcc(i)=0;end;
         /*vascular 1*/    if hcc106=1 then do i=107, 108, 161, 189;hcc(i)=0;end;
         /*vascular 2*/    if hcc107=1 then do i=108;hcc(i)=0;end;
         /*lung 1*/        if hcc110=1 then do i=111, 112;hcc(i)=0;end;
         /*lung 2*/        if hcc111=1 then do i=112;hcc(i)=0;end;
         /*lung 5*/        if hcc114=1 then do i=115;hcc(i)=0;end;
         /*kidney 3*/      if hcc134=1 then do i=135, 136, 137;hcc(i)=0;end;
         /*kidney 4*/      if hcc135=1 then do i=136, 137;hcc(i)=0;end;
         /*kidney 5*/      if hcc136=1 then do i=137;hcc(i)=0;end;
         /*skin 1*/        if hcc157=1 then do i=158, 161;hcc(i)=0;end;
         /*skin 2*/        if hcc158=1 then do i=161;hcc(i)=0;end;
         /*injury 1*/      if hcc166=1 then do i=80, 167;hcc(i)=0;end;

         *community model diagnostic categories;
         cancer         = max(hcc8, hcc9, hcc10, hcc11, hcc12);
         diabetes       = max(hcc17, hcc18, hcc19);
         immune         = hcc47;
         card_resp_fail = max(hcc82, hcc83, hcc84);
         chf            = hcc85;
         copd           = max(hcc110, hcc111);
         renal          = max(hcc134, hcc135, hcc136, hcc137);
         compl          = hcc176;
         sepsis         = hcc2;

         *interactions;
         sepsis_card_resp_fail =  sepsis*card_resp_fail;
         cancer_immune         =  cancer*immune;
         diabetes_chf          =  diabetes*chf ;
         chf_copd              =  chf*copd;
         chf_renal             =  chf*renal;
         copd_card_resp_fail   =  copd*card_resp_fail;

         *interactions with disabled;
         *opportunistic infections;
         disabled_hcc6   = disabl*hcc6;
         *chronic pancreatitis;
         disabled_hcc34  = disabl*hcc34;
         *severe hematol disorders;
         disabled_hcc46  = disabl*hcc46;
         *drug/alcohol psychosis;
         disabled_hcc54  = disabl*hcc54;
         *drug/alcohol dependence;
         disabled_hcc55  = disabl*hcc55;
         *cystic fibrosis;
         disabled_hcc110 = disabl*hcc110;
         disabled_hcc176 = disabl*hcc176;   
         
         n_organ_fail = sum(hcc131, hcc80, hcc25, hcc26, hcc77, hcc79);
         if (n_organ_fail >= 2) then mof = 1;
         else mof = 0; 

         *institutional model diagnostic categories;
         copd_x_asp_bac_pneum = ((hcc111 = 1) and (hcc114 = 1));                                                                                                                              
         schizo_x_seiz_dis_convul = ((hcc57 = 1) and (hcc79 = 1));
         sepsis_x_art_openings = ((hcc2 = 1) and (hcc188 = 1));
         sepsis_x_asp_bac_pneum = ((hcc2 = 1) and (hcc114 = 1));
         sepsis_x_press_ulcer = (((hcc2 = 1) and (hcc157 = 1)) or ((hcc2 = 1) and (hcc158 = 1)));

         output temp.stay_hccs;

      end;

   run;
   
   *use cc version 24 for dementia flags;
   data temp.stay_ccs_dementia;

      if _n_ = 1 then do;

         *all bpci episodes;
         if 0 then set temp.episodes_w_prov_ra (keep = link_id disabl episode_id anchor_beg_dt anchor_lookback_dt);
         declare hash epis (dataset: "temp.episodes_w_prov_ra (keep = link_id disabl episode_id anchor_beg_dt anchor_lookback_dt)", multidata: "y");
         epis.definekey("link_id");
         epis.definedata(all: "y");
         epis.definedone();

      end;
      call missing(of _all_);
      set clm_inp.cc_v&dementia_cc. (keep = link_id thru_dt cc_v&dementia_cc. rename = (cc_v&dementia_cc. = cc));

      *find all CCs that overlap with the lookback period;
      if (epis.find(key: link_id) = 0) then do;
         rc_epis = 0;
         do while (rc_epis = 0);
            *NOTE: make sure to start one day prior to anchor begin date as to not include the anchor begin date in HCC construction;
            if (anchor_lookback_dt <= thru_dt <= anchor_beg_dt - 1) then output temp.stay_ccs_dementia;
            rc_epis = epis.find_next();
         end;
      end;
   run;

   proc sort nodupkey data = temp.stay_ccs_dementia;
      by link_id episode_id cc;
   run;

   data temp.stay_hccs_dementia (keep = link_id episode_id &dementia_list.);
      set temp.stay_ccs_dementia;
      by link_id episode_id;
      retain cc51 cc52 hcc51 hcc52;
      if first.episode_id then do;
         cc51 = 0;
         cc52 = 0;
      end;
      if (cc = 51) then cc51 = 1;
      if (cc = 52) then cc52 = 1;

      if last.episode_id then do;
         hcc51 = cc51;
         hcc52 = cc52;
         *implement hierarchy. the idea is that within each disease category, we keep only the lowest numbered hcc (the lowest numbered hcc is the most severe manifestation of the condition);
         if hcc51 = 1 then hcc52 = 0;
         dementia_w_cc = hcc51;
         dementia_wo_cc = hcc52;
         output;
      end;
   run;

   *merge HCCs back to episode-level dataset;
   data temp.episodes_w_hccs (drop = rc_:);
      
      length hcc_count hcc_cnt_0 hcc_cnt_1_3 hcc_cnt_4_6 hcc_cnt_7_plus 8.;
      if _n_ = 1 then do;
         
         *list of HCCs;
         if 0 then set temp.stay_hccs;
         declare hash hcc_finder (dataset: "temp.stay_hccs");
         hcc_finder.definekey("link_id", "episode_id");
         hcc_finder.definedata(all: "y");
         hcc_finder.definedone();
         
         *list of dementia flags;
         if 0 then set temp.stay_hccs_dementia (keep = link_id episode_id dementia_w_cc dementia_wo_cc);
         declare hash dem_finder (dataset: "temp.stay_hccs_dementia (keep = link_id episode_id dementia_w_cc dementia_wo_cc)");
         dem_finder.definekey("link_id", "episode_id");
         dem_finder.definedata("dementia_w_cc", "dementia_wo_cc");
         dem_finder.definedone();
         
      end;
      call missing(of _all_);

      set temp.episodes_w_prov_ra;

      rc_hcc_finder = hcc_finder.find(key: link_id, key: episode_id);
      %do a = 1 %to &nhcc_vars.;
         if missing(&&hcc_vars&a..) then &&hcc_vars&a.. = 0;
      %end;
      %do a = 1 %to &nhcc_ints.;
         if missing(&&hcc_ints&a..) then &&hcc_ints&a.. = 0;
      %end;

      hcc_count = 0;
      %do a = 1 %to &nhcc_vars.;
         if (&&hcc_vars&a.. = 1) then hcc_count = hcc_count + 1;
      %end;

      *create flag indicating the number of HCCs an episode possesses;
      hcc_cnt_0 = 0;
      hcc_cnt_1_3 = 0;
      hcc_cnt_4_6 = 0;
      hcc_cnt_7_plus = 0;
      if (hcc_count = 0) then hcc_cnt_0 = 1;
      else if (1 <= hcc_count <= 3) then hcc_cnt_1_3 = 1;
      else if (4 <= hcc_count <= 6) then hcc_cnt_4_6 = 1;
      else if (hcc_count >= 7) then hcc_cnt_7_plus = 1;
      
      *add dementia flags;
      rc_dem_finder = dem_finder.find(key: link_id, key: episode_id);
      if missing(dementia_w_cc) then dementia_w_cc = 0;
      if missing(dementia_wo_cc) then dementia_wo_cc = 0;
   run;
 
%mend;

