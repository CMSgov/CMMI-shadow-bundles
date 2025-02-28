/*************************************************************************;
%** PROGRAM: a0_program_main_caller.sas
%** PURPOSE: To select and execute sub-callers/macros
%** AUTHOR: Acumen, LLC
%** DATE CREATED: 09/06/2024
%** DATE LAST MODIFIED: 09/06/2024
************************************************************************;
This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the CC0 1.0 Universal public domain dedication as indicated in LICENSE.

************************************************************************/

options ls=220 ps=max nocenter mprint noxwait compress=yes fullstimer validvarname=upcase mergenoby=warn extendobscounter=no minoperator;
%macro a0_program_main_caller(code_dir = , /*specify the location of codebase*/
                              log_dir =  , /*specify the location of logs*/
                              run_date =   /*specify date of running code*/
                              );
                              
   options append=(sasautos=("&code_dir."                          
                   sasautos)); 
             
   *call frequently used/supporting macros; 
   *Note: always run with other subsequent macros;
   %a1_utility_macros();
   
   *print log;
   *Note: run to create a log file in the specified location;
   %create_log_file(log_file_name = a0_program_main_caller);

   *assign global macrovariables;   
   *Note: always run with other subsequent macros;
   *      most of the key updates and parameters are made in this macro;    
   %a2_assign_globals();

   *assign library references;
   *Note: always run with other subsequent macros;
   *      all input and output directories are referenced in this macro; 
   %*set run_mkdir to 1 to create desired output folders for first time execution; 
   %a3_assign_libnames(run_mkdir = 0); 
  
   *call and run all macros under b series;
   *Main focus: importing workbooks, cleaning up and restructuring inputs;
   %*set import to 1 to read in clinical logic workbooks; 
   %*tips: open macro to self select sub-macros to run as needed or comment out unwanted macros; 
   %b0_prep_inputs_sub_caller(import = 0);

   *define arrays of things to be accessed by other macros; 
   *Note: always run with other subsequent macros;
   %b5_assign_global_macarrays();
    
   *call and run all macros under c series;
   *Main focus: integrating Medicare Part A&B claims and other data sources to build episodes and their attributes;
   %*tips: open macro to self select sub-macros to run as needed or comment out unwanted macros; 
   %c0_construct_episodes_sub_caller();
  
   *call and run all macros under d series;
   *Main focus: pulling and identifying eligible claims across seven service settings to group to episode spending;
   %*tips: open macro to self select sub-macros to run as needed or comment out unwanted macros; 
   %d0_calc_episode_cost_sub_caller();

   *call and run all macros under e series;
   *Main focus: resolving episodes that overlap with each other or with other models;
   %*tips: open macro to self select sub-macros to run as needed or comment out unwanted macros; 
   %e0_resolve_overlap_sub_caller();
 
   *call and run all macros under f series;
   *Main focus: adding beneficiary-level, provider-level, time trend indicators and other variables for risk adjustment;
   %*tips: open macro to self select sub-macros to run as needed or comment out unwanted macros; 
   %f0_create_ra_vars_sub_caller();

   *call and run all macros under g series;
   *Main focus: calculating price update factors and winsorizing episode cost;
   %*tips: open macro to self select sub-macros to run as needed or comment out unwanted macros; 
   %g0_calc_updt_factors_sub_caller();

   *call and run all macros under h series;
   *Main focus: attributing episodes to ACOs;
   %*tips: open macro to self select sub-macros to run as needed or comment out unwanted macros; 
   %h0_attribute_episodes_sub_caller();

%mend;

%a0_program_main_caller(code_dir = c:\project\code,
                        log_dir = c:\project\logs, 
                        run_date = 2024_11_22 
                        );
                     
