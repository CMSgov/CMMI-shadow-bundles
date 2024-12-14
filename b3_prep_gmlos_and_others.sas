/*************************************************************************;
%** PROGRAM: b3_prep_gmlos_and_others.sas
%** PURPOSE: To pre-process GMLOS data for IPPS update factor and other input data
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