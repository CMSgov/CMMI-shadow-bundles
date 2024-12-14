/*************************************************************************;
%** PROGRAM: b0_prep_inputs_sub_caller.sas
%** PURPOSE: To select and execute sub-macros in b series
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
