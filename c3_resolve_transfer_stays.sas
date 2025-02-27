/*************************************************************************;
%** PROGRAM: c3_resolve_transfer_stays.sas
%** PURPOSE: To resolve acute to acute transfer stays 
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro c3_resolve_transfer_stays();
   
   *create ID for stays involved in transfer; 
   data temp.all_potential_transfers (drop = prev_:);

      set temp.cleaned_ip_stays_w_remap (where = ((overlap_keep_inner = 1) and ((ipps_flag = 1) or (cah_flag = 1) or (emerg_hosp_flag = 1) or (veteran_hosp_flag = 1))));
      by link_id admsn_dt dschrgdt daily_dt provider;

      retain prev_provider prev_admission_date prev_discharge_date transfer_id;

      if _n_ = 1 then transfer_id = 0;
      if first.link_id then do;
         prev_provider = provider;
         prev_admission_date = admsn_dt;
         prev_discharge_date = dschrgdt;
         transfer_id = transfer_id + 1;
         output temp.all_potential_transfers;
      end;
      else do;
         *transfer_id will continue to be updated for each visit unless the current visit is not the final leg in a tranfer process;
         if (provider ^= prev_provider) and (prev_admission_date <= admsn_dt) and (prev_discharge_date = admsn_dt) then transfer_id = transfer_id;
         else transfer_id = transfer_id + 1;
         output temp.all_potential_transfers;
         *reset prev_ values;
         prev_provider = provider;
         prev_admission_date = admsn_dt;
         prev_discharge_date = dschrgdt;
      end;

   run;

   *calculate the maximum number of ip stay transfers possible;
   proc sql noprint;

      select max(num_stays) 
      into   : max_num_trans
      from (select transfer_id,
                   count(distinct ip_stay_id) as num_stays
            from temp.all_potential_transfers
            group by transfer_id);

   quit;
   
   *identify info for the first and last transfer leg; 
   data temp.all_final_transfers (keep = link_id transfer_id transfer_flag first_: last_: fin_: trans_ip_stay_: attr_:)
        temp.transfers_prov_crosswalk (keep = transfer_id ip_stay_id link_id admsn_dt dschrgdt drg_: mdc provider at_npi op_npi standard_allowed_amt cancer_hosp_flag cah_flag attr_:);
      
      length first_ip_stay_id last_ip_stay_id first_admsn_dt 8. first_provider $6. first_at_npi first_op_npi $10. last_drg_cd $3. last_dschrgdt 8. %do a = 1 %to &nflag_vars.; first_&&flag_vars&a.._flag %end; first_missing_provider_flag 
             fin_num_transfers_ip fin_standard_allowed_amt fin_allowed_amt fin_clm_prpay 8. attr_start_dt attr_end_dt 8.;
      format first_admsn_dt last_dschrgdt attr_start_dt attr_end_dt date9.;
      set temp.all_potential_transfers;
      by transfer_id;

      array trans_ip_stay_{&max_num_trans.} 8.;
      retain first_ip_stay_id first_admsn_dt first_provider first_at_npi first_op_npi %do a = 1 %to &nflag_vars.; first_&&flag_vars&a.._flag %end; first_missing_provider_flag
             fin_standard_allowed_amt fin_allowed_amt fin_clm_prpay fin_num_transfers_ip attr_start_dt attr_end_dt counter trans_ip_stay_1-trans_ip_stay_%sysfunc(strip(&max_num_trans.));

      *create flag to indicate if visit was involved in a transfer;
      if not (first.transfer_id and last.transfer_id) then transfer_flag = 1;
      else transfer_flag = 0;

      *sum up all the costs from every leg of transfers;
      if first.transfer_id then do;
         first_ip_stay_id = ip_stay_id;
         first_admsn_dt = admsn_dt;
         first_provider = provider;
         first_at_npi = at_npi;
         first_op_npi = op_npi;
         %do a = 1 %to &nflag_vars.;
            first_&&flag_vars&a.._flag = &&flag_vars&a.._flag;
         %end;
         first_missing_provider_flag = missing_provider_flag;
         fin_standard_allowed_amt = standard_allowed_amt;
         fin_allowed_amt = allowed_amt;
         fin_clm_prpay = clm_prpay;
         fin_num_transfers_ip = 0;
         attr_start_dt = admsn_dt - &attr_lookback_days.; 
         attr_end_dt = dschrgdt; 
         counter = 0;
         call missing(of trans_ip_stay_1-trans_ip_stay_%sysfunc(strip(&max_num_trans.)));
      end;
      else do;
         fin_standard_allowed_amt = sum(fin_standard_allowed_amt, standard_allowed_amt);
         fin_allowed_amt = sum(fin_allowed_amt, allowed_amt);
         fin_clm_prpay = sum(fin_clm_prpay, clm_prpay);
         fin_num_transfers_ip = fin_num_transfers_ip + 1;
      end;
      counter = counter + 1;
      trans_ip_stay_{counter} = ip_stay_id;
      if last.transfer_id then do;
         last_ip_stay_id = ip_stay_id;
         last_drg_cd = drg_cd;
         last_dschrgdt = dschrgdt;
         output temp.all_final_transfers;
      end;

      *keep track of the provider/NPI information of each IP stay in a transfer. this dataaset will be needed for doing ACH/PGP attribution for transfers;
      if (transfer_flag = 1) then output temp.transfers_prov_crosswalk;

   run;

   *output a dataset containing all the ip stays that were part of a transfer but were not the final legs of said transfer;
   data temp.ip_stays_w_transfers (drop = last_ip_stay_id transfer_flag)
        temp.excluded_transfer_ip_stays (drop = last_ip_stay_id first_: last_: fin_: transfer_flag);

        length transfer_stay 8.;
        if _n_ = 1 then do;
            
            *list of all transfer stays;
            if 0 then set temp.all_final_transfers (keep = first_: last_: fin_: trans_ip_stay_: transfer_flag attr_:);
            declare hash transfer_list (dataset: "temp.all_final_transfers (keep = first_: last_: fin_: trans_ip_stay_: transfer_flag attr_:)");
            transfer_list.definekey("last_ip_stay_id");
            transfer_list.definedata(all: "y");
            transfer_list.definedone();

        end;
        call missing(of _all_);

        set temp.cleaned_ip_stays_w_remap (where = ((overlap_keep_inner = 1) and ((ipps_flag = 1) or (cah_flag = 1) or (emerg_hosp_flag = 1) or (veteran_hosp_flag = 1))));

        *initialize flags;
        transfer_stay = 0;

        *only ip stays that were part of a transfer but were not the final leg of the transfer would not be found;
        if (transfer_list.find(key: ip_stay_id) ^= 0) then do;
            transfer_stay = 1;
            output temp.excluded_transfer_ip_stays;
        end;
        *the only way an ip stay would be found is if it is a non-transfer ip stay or it is the final leg ip stay in the transfer process;
        else do;
            if (transfer_flag = 1) then transfer_stay = 1;
            else call missing(of trans_ip_stay_1-trans_ip_stay_%sysfunc(strip(&max_num_trans.)));
            output temp.ip_stays_w_transfers;
        end;

   run;

   *keep track of what the maximum number of transfer IP stays;
   data temp.max_ip_transfers;
      set sashelp.vmacro (keep = name value where = (lowcase(name) = "max_num_trans"));
   run;
%mend; 