/*************************************************************************;
%** PROGRAM: a3_assign_libnames.sas
%** PURPOSE: To set up input and output directories to be accessed by other macros
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro a3_assign_libnames(run_mkdir = 0);

   *Note: The maximum of a SAS library name is 8 characters; 
   *      The first character must be a letter a through z or an underscore(_);
   *      The remaining characters can be any of these characters or numerals 0 through 9;
   *      Specify access = readonly to avoid modifying the original inputs;    
   
   /*****INPUTS*****/   
   *specify the location to obtain Medicare part A&B claims;
   libname clm_inp "c:\claims\EDB&edb_version._&fa_week.\output_&q_run_date.\&query_start_year._&query_end_year." access = readonly;
   
   *ESRD and other primary payers;
   libname oth_inp "c:\others" access = readonly;
   
   *specify the location of enrollment database;
   libname enrll "c:\enr\edb_%sysfunc(compress(%str(&edb_version.), %str(_)))" access = readonly;
   
   *specify the location of physician fee schedule (PFS) global days datasets;
   libname pfs "c:\pfs" access = readonly; 

   *specify the location of HCPCS datasets used in identiyfing clotting factors/hemophlia during payment standardization;
   libname hemos "c:\part_b_drugs" access = readonly;

   *specify the location of IPPS DRG weights dataset; 
   libname geo "c:\ipps" access = readonly;

   *specify the location of POS dataset;
   libname pos "c:\pos\&pos_version." access = readonly;

   *specify the location of PSF dataset;
   libname psf "c:\ipps_psf\&psf_year.\Q&psf_quarter." access = readonly;

   *specify the location of mapping of states to division regions;
   libname states "c:\ssa_state_codes" access = readonly;

   *specify the location of GPCI datasets to use in PB update factors;
   libname gpci "c:\gpcis" access = readonly;
   
   *specify thelocation of anesthesia datasets to use in PB update factors;
   libname anes "c:\anesthesia_cf" access = readonly;
   
   *specify the location of RVU datasets to use in PB update factors;
   libname rvu "c:\rvu" access = readonly;

   *specify the location of home health HHRGs to use in HH update factors;
   libname hhrg "c:\hhrg_weights" access = readonly;

   *specify the location of SNF PDPM rates;
   libname pdpm "c:\pdpm_rates" access = readonly;
   
   *specify the location of SNF VPD;
   libname vpd "c:\snf_vpd" access = readonly;

   *specify the location of the Medicare Economic Index rates;
   libname mei "c:\mei_rates" access = readonly;

   *specify the location of the COVID intensity rates;
   libname cit_rt "c:\census_tract" access = readonly;
   
   *location of mdm;
   libname mdm "c:\mdm" access = readonly; 
   
   *specify the location of addendum J containing primary J1 ranking of HCPCS codes;
   %global addj_dir;
   %let addj_dir = c:\addj_data;
   libname addj "&addj_dir.";
   
   /*****OUTPUTS*****/
   %if &run_mkdir. = 1 %then %do;
      %mkdirs(&outdir.\working, 
              &outdir.\output)
   %end;    
   *specify the location to save temporary or intermediate output datasets;   
   libname temp "&outdir.\working";    
   *specify the location to save final output datasets;
   libname fin "&outdir.\output";    
  
%mend;
