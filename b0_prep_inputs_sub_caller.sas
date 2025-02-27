/*************************************************************************;
%** PROGRAM: b0_prep_inputs_sub_caller.sas
%** PURPOSE: To select and execute sub-macros in b series
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/
%macro b0_prep_inputs_sub_caller(import = 0);

   *print log;
   %create_log_file(log_file_name = b0_prep_inputs_sub_caller);

   *import clinical logic workbooks;
   %if &import = 1 %then %do;
      %b1_import_clinical_logic();
   %end;
  
   *pre-process GPCI and Anesthesia conversion factor for PB update factor; 
   %b2_prep_gpci_and_anes();

   *pre-process GMLOS data for IPPS update factor and other input data; 
   %b3_prep_gmlos_and_others();

   *pre-process ACO alignment files (if needed); 
   %b4_prep_aco_algnms();
   
      
%mend;
