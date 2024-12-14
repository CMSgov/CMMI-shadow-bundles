/*************************************************************************;
%** PROGRAM: e1_resolve_bpcia_overlap.sas
%** PURPOSE: To flag episodes that will be dropped due to overlapping with other episodes 
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

%macro e1_resolve_bpcia_overlap();

   *helper macro for re-initializing prev_ related variables for resolving overlaps;
   %macro prev_vars_initialize();
      prev_anchor_type = anchor_type;
      prev_episode_id = episode_id;
      prev_beg_dt = anchor_beg_dt;
      prev_end_dt = post_dsch_end_dt;
      prev_mjrle_flag = mjrle_flag;
      prev_pci_flag = pci_flag;
   %mend;
   
   data temp.flags_mjrle_pci_tavr;
   
      set temp.episodes_w_costs;
      
      *initialize;
      mjrle_flag = 0;
      pci_flag = 0;
      tavr_flag = 0;
      
      *flag IP and OP MJRLE episodes;
      if (upcase(strip(episode_group_name)) = 'MS-MAJOR JOINT REPLACEMENT OF THE LOWER EXTREMITY') then mjrle_flag = 1;

      *flag PCI episodes;
      if (lowcase(anchor_type) = "ip" and upcase(strip(episode_group_name)) = 'IP-PERCUTANEOUS CORONARY INTERVENTION') or 
         (lowcase(anchor_type) = "op" and upcase(strip(episode_group_name)) = 'OP-PERCUTANEOUS CORONARY INTERVENTION') 
      then pci_flag = 1;

      *flag TAVR episodes;
      if (lowcase(anchor_type) = "ip") and (upcase(strip(episode_group_name)) = 'IP-TRANSCATHETER AORTIC VALVE REPLACEMENT') 
      then tavr_flag = 1;   
   run;

   *sort episodes from earliest to latest for each link id; 
   proc sort data = temp.flags_mjrle_pci_tavr (where = (final_episode = 1))
             out = epis_sorted;
       by link_id anchor_beg_dt anchor_type anchor_end_dt;
   run;
   
   *output a dataset containing all episodes that are dropped due to overlap;
   data temp.overlapping_episodes (keep = link_id final_episode anchor_beg_dt anchor_end_dt post_dsch_beg_dt post_dsch_end_dt episode_group_name anchor_type episode_id mjrle_flag pci_flag tavr_flag prev_:);

      length drop_episode_id prev_beg_dt prev_end_dt 8. prev_anchor_type $10. prev_episode_id prev_mjrle_flag prev_pci_flag 8.;

      if _n_ = 1 then do;
      
         *keep track of episodes that need to be dropped;
         declare hash overlap_drop (ordered: "a");
         overlap_drop.definekey("drop_episode_id");
         overlap_drop.definedata("drop_episode_id", "dropflag_bpcia_overlap");
         overlap_drop.definedone();

      end;

      set epis_sorted end = last;
      
      by link_id anchor_beg_dt anchor_type anchor_end_dt;
      
      retain prev_beg_dt prev_end_dt prev_anchor_type prev_episode_id prev_mjrle_flag prev_pci_flag;
  
      if first.link_id then do;
         %prev_vars_initialize();
      end;
      
      *condition A: if the benficiary has more than one episodes;
      else do;
         
         *condition B: if the current episode starts at any point within the prior episode window;
         if (prev_beg_dt <= anchor_beg_dt <= prev_end_dt) then do;
         
            *condition C: if both episodes are MJRLE or;
            *             if prior episode is PCI and current episode is TAVR;             
            if (overlap_drop.find(key: prev_episode_id) ^= 0) and 
               ((prev_anchor_type = anchor_type and prev_mjrle_flag = 1 and mjrle_flag = 1) or
               (prev_anchor_type ^= anchor_type and prev_beg_dt ^= anchor_beg_dt and prev_mjrle_flag = 1 and mjrle_flag = 1) or
               (prev_pci_flag = 1 and tavr_flag = 1)) then do;
                  
                  *keep the current episode, drop the prior episode and use the current episode to resolve with the next episode; 
                  drop_episode_id = prev_episode_id;
                  dropflag_bpcia_overlap = 1;
                  overlap_drop.add();
                  %prev_vars_initialize();
            end; %*end condition C;
            
            *otherwise, drop the current episode, keep the prior episode and use it to resolve with the next episode; 
            else do;
               if (overlap_drop.find(key: episode_id) ^= 0) then do;
                  drop_episode_id = episode_id;
                  dropflag_bpcia_overlap = 1;
                  overlap_drop.add();
               end;
            end;       
         end; %*end condition B;   
         
         *if two episodes do not overlap, keep both and use the later (current) episode to resolve with the next episode; 
         else do;
            %prev_vars_initialize();
         end;
      
      end; %*end condition A;
      output temp.overlapping_episodes;

      if last then overlap_drop.output(dataset: "temp.all_overlap_drops");
   run;  
   
   *idenfity episodes to be dropped due to overlapping; 
   data temp.episodes_w_no_overlap (drop = drop_episode_id);

      length dropflag_bpci_a_overlap 8.;
      
      if _n_ = 1 then do;

         *list of episodes to be dropped;
         if 0 then set temp.all_overlap_drops (keep = drop_episode_id);
         declare hash overlap_drop (dataset: "temp.all_overlap_drops (keep = drop_episode_id)");
         overlap_drop.definekey("drop_episode_id");
         overlap_drop.definedone();

      end;
      call missing(of _all_);
      
      set temp.flags_mjrle_pci_tavr;

      *create flag to indicate if episode has bpci epi overlap;
      if (overlap_drop.find(key: episode_id) = 0) then dropflag_episode_overlap = 1;
      else dropflag_episode_overlap = 0;
      
      output temp.episodes_w_no_overlap;
   run;
%mend;

