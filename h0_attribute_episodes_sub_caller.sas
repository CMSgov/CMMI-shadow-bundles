/*************************************************************************;
%** PROGRAM: h0_attribute_episodes_sub_caller.sas
%** PURPOSE: To call macros under h series. 
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

%macro h0_attribute_episodes_sub_caller();

   *print log;
   %create_log_file(log_file_name = h0_attribute_episodes_sub_caller);
   
   *attribute episodes to ACOs using MDM data or ACO alignment files;
   %h1_attribute_episodes_to_aco();
         
%mend; 
