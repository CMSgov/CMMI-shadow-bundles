/*************************************************************************;
%** PROGRAM: e0_resolve_model_overlap_sub_caller.sas
%** PURPOSE: To select and execute sub-callers/macros in d series
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/
%macro e0_resolve_overlap_sub_caller();

   *print log;
   %create_log_file(log_file_name = e0_resolve_model_overlap_sub_caller);

   *flag episodes that are dropped due to overlapping with other episodes;
   %e1_resolve_bpcia_overlap();


%mend;
