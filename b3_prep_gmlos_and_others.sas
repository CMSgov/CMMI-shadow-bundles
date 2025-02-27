/*************************************************************************;
%** PROGRAM: b3_prep_gmlos_and_others.sas
%** PURPOSE: To pre-process GMLOS data for IPPS update factor and other input data
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro b3_prep_gmlos_and_others();

   *stack all gmlos datasets;
   data temp.stacked_gmlos_&query_start_year._&query_end_year.;
      length geo_year 8.;
      set %do year = &query_start_year. %to &query_end_year.;
            geo.ipps_drg_weights_&year. (in = in_&year.)
          %end;;

      %do year = &query_start_year. %to &query_end_year.;
         if (in_&year. = 1) then geo_year = &year.;
         %if &year. ^= &query_end_year. %then else;
      %end;
   run;

   *dedup so that crosswalk is unique by trigger HCPCS and calendar year;
   proc sort nodupkey data = temp.hcpcs_to_apc_xwalk (keep = cy_year hcpcs_code apc apc_payment_rate comp_adj_hcpcs comp_adj_apc comp_adj_apc_payment_rate is_c_apc)
                      out = temp.hcpcs_to_apc_dedup;
      by hcpcs_code cy_year;
   run;
   
   *create a PSF finder file where the provider information associated with the most recent effective date is use for generating provider-level risk-adjustment variables later on;
   proc sort data = psf.ipsf_inp_sas_&psf_version. (where = (not missing(oscarNumber)))
             out = temp.inp_sas_psf&psf_version.   (rename = (oscarNumber        = provider 
                                                              effectiveDate      = fectdate 
                                                              capitalIndirectMedicalEducationR = imeratio
                                                              internsToBedsRatio = ibratio 
                                                              censusDivision     = censdivi))
                                                            ;
      by oscarNumber descending effectiveDate;
   run;

   data temp.inp_sas_psf&psf_version.;
      set temp.inp_sas_psf&psf_version. (keep = provider fectdate imeratio ibratio censdivi bedsize);
      by provider descending fectdate;
      if first.provider then output temp.inp_sas_psf&psf_version.;
   run;
   
   *create MJRLE procedure list for constructing MJRLE risk adjustment flags;
   proc freq noprint data = temp.mjrle_procedure_codes;
      tables prcdr_group/missing out = temp.prcdr_list_freq;
   run;
   

%mend; 