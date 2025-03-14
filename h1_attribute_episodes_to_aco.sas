/*************************************************************************;
%** PROGRAM: g11_winsorize_episode_cost.sas
%** PURPOSE: To attribute episodes to ACOs using MDM data or ACO alignment files.
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro h1_attribute_episodes_to_aco();


   *create a crosswalk of episode IDs and attributed ACOs; 
   data fin.episodes (drop = rc_: program_id aco_id aco_name afltn_efctv_dt afltn_end_dt);

      if _n_ = 1 then do;      
         *mdm dataset;            
         if 0 then set mdm.mdm_bene_20240227_t0708473 (keep = link_id org_id program_id afltn_efctv_dt afltn_end_dt rename = (org_id = aco_id));
         declare hash getmdm (dataset: "mdm.mdm_bene_20240227_t0708473 (keep = link_id org_id program_id afltn_efctv_dt afltn_end_dt rename = (org_id = aco_id))", multidata: "y");
         getmdm.definekey("link_id");
         getmdm.definedata("aco_id", "program_id", "afltn_efctv_dt", "afltn_end_dt");
         getmdm.definedone();

         *participating ACOs;
         if 0 then set mdm.aco_participant_list;
         declare hash partaco (dataset: "mdm.aco_participant_list");
         partaco.definekey("aco_id");
         partaco.definedata("aco_name");
         partaco.definedone();

         *keep track of episodes that need to be dropped;
         declare hash attr_aco (ordered: "a");
         attr_aco.definekey("aco_id", "program_id", "episode_id");
         attr_aco.definedata("aco_id", "aco_name", "participating_aco", "program_id", "link_id", "episode_id", "episode_group_name", "service_line_group", "episode_group_id", "anchor_type", "anchor_provider", "anchor_beg_dt", "anchor_end_dt", "post_dsch_end_dt", "post_dsch_end_dt_int", "final_episode");
         attr_aco.definedone();

      end;
      call missing(of _all_);

      set temp.episodes_w_winsorization (rename = (post_dsch_end_dt = post_dsch_end_dt_int post_dsch_end_dt_&post_dschrg_days. = post_dsch_end_dt))
      end = last; 

      *create episode type variable;
      length epi_type $5.;
      epi_type = lowcase(substr(episode_group_name, 1, 2));
      
      *add log of winsorized and updated episode cost;
      if (epi_std_pmt_fctr_win_1_99 > 0) then log_epi_std_pmt = log(epi_std_pmt_fctr_win_1_99);
      else call missing(log_epi_std_pmt);
      if (post_epi_std_pmt_fctr_win_1_99 > 0) then log_postepi_std_pmt = log(post_epi_std_pmt_fctr_win_1_99);
      else call missing(log_postepi_std_pmt);
      
      *update drop_episode and final_episode to reflect the overlap episode exclusion;
      if (drop_episode = 0) and (dropflag_episode_overlap = 1) then drop_episode = 1;
      if (drop_episode = 0) and (episode_in_study_period = 1) then final_episode = 1;
      else final_episode = 0;
      
      *flag episodes overlapping with ACO alignments; 
      aco_mssp_overlap = 0;
      aco_reach_overlap = 0;
      participating_aco = 0;
      
      if getmdm.find(key: link_id) = 0 then do;
         rc_getmdm = 0;
         do while (rc_getmdm = 0);
            if (anchor_beg_dt <= afltn_efctv_dt <= post_dsch_end_dt_int) or
               (anchor_beg_dt <= afltn_end_dt <= post_dsch_end_dt_int) or
               (afltn_efctv_dt <= anchor_beg_dt <= afltn_end_dt) or
               (afltn_efctv_dt <= post_dsch_end_dt_int <= afltn_end_dt) then do;
               if program_id = &mssp_program_id. then aco_mssp_overlap = 1;
               else if program_id = &reach_program_id. then aco_reach_overlap = 1;
               if partaco.find(key: aco_id) = 0 then do;
                  participating_aco = 1; 
                  if attr_aco.find(key: aco_id, key: program_id, key: episode_id) ^= 0 then attr_aco.add();
               end;
            end;
            rc_getmdm = getmdm.find_next();
         end;
      end;             
      if last then attr_aco.output(dataset: "fin.attr_xwalk_epi_aco");     
   run;     

   
%mend; 
