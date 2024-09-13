/*************************************************************************;
%** PROGRAM: b1_import_clinical_logic.sas
%** PURPOSE: Imports Clinical Logic workbooks
%** AUTHOR: Acumen
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

%macro b1_import_clinical_logic();

   /*****BPCIA trigger code list*****/   

   *define the row number in the workbook for where to start importing in the data;
   %let start_row_num = 8;

   *define the workbook sheet names to be imported;/*{{{*/
   %macarray(sheet_names, IP_Anchor_Episode_List ~
                          OP_Anchor_Episode_List ~
                          TAVR Procedure Codes ~
                          Service_Line ~
                          MJRUE_Trigger_Procedure_Codes ~
                          MJRUE_Dropped_Procedure_Codes
                          , dlm = "~" );

   *define the name of the output datasets for the imported sheet names;
   %macarray(ds_names, ip_anchor_episode_list ~
                       op_anchor_episode_list ~
                       tavr_procedure_codes ~
                       service_line ~
                       mjrue_trigger_procedure_codes ~
                       mjrue_dropped_procedure_codes
                       , dlm = "~");

   *define the columns to be kept from each workbook sheet;
   %macarray(keep_cols, C D E H ~ %*ip_anchor_episode_list;
                        C D G J ~ %*op_anchor_episode_list;
                        c D ~ %*tavr_procedure_codes;
                        C D E ~ %*service_line;
                        C D ~ %*mjrue_trigger_procedure_codes;
                        C D  %*mjrue_dropped_procedure_codes;
                        , dlm = "~");

   *define the new column name that each kept column will be renamed to;
   %macarray(rename_cols, episode_group_name episode_group_id drg_cd cec_type ~ %*ip_anchor_episode_list;
                          episode_group_name episode_group_id hcpcs_cd cec_type ~ %*op_anchor_episode_list;
                          procedure_cd icd9_icd10 ~ %*tavr_procedure_codes;
                          service_line_group episode_group_name episode_group_id ~ %*service_line;
                          procedure_cd procedure_cd_descrip ~ %*mjrue_trigger_procedure_codes;
                          procedure_cd procedure_cd_descrip %*mjrue_dropped_procedure_codes;
                          , dlm = "~");

   *define the column length of each kept column;
   %macarray(length_cols, $100. $10. $3. $10. ~ %*ip_anchor_episode_list;
                          $100. $10. $5. $10. ~ %*op_anchor_episode_list;
                          $10.  $10. ~ %*tavr_procedure_codes;
                          $50.  $100. $10. ~ %*service_line;
                          $10.  $3200. ~ %*mjrue_trigger_procedure_codes;
                          $10.  $3200. %*mjrue_dropped_procedure_codes;
                          , dlm = "~");

   %do a = 1 %to &nsheet_names.;
      %macarray(kept_var, &&keep_cols&a..);
      %macarray(rename_var, &&rename_cols&a..);
      %macarray(len, &&length_cols&a..);

      *import trigger codes from clinical logic workbook;
      proc import out = temp.&&ds_names&a.. (keep = &&keep_cols&a..
                                             rename = (%do b = 1 %to &nkept_var.; 
                                                          &&kept_var&b.. = &&rename_var&b..
                                                       %end;))
         datafile = "&clin_dir.\&bpci_trig_version._bpci_a_trigger_list.xlsx"
         dbms = xlsx
         replace;
         sheet = "&&sheet_names&a..";
         datarow = &start_row_num.;
         getnames = no;
      run;

      *apply basic formatting edits to imported datasets;
      data temp.&&ds_names&a..;
         length %do b = 1 %to &nrename_var.; &&rename_var&b.. &&len&b.. %end;;
         set temp.&&ds_names&a..;
         %do b = 1 %to &nrename_var.;
             &&rename_var&b.. = strip(&&rename_var&b..);
         %end;
         %if &&ds_names&a.. = service_line %then %do;
            episode_group_name = upcase(strip(episode_group_name));
         %end;
         if not (%do b = 1 %to &nrename_var.; missing(&&rename_var&b..) %if &b. ^= &nrename_var. %then and; %end;) then output temp.&&ds_names&a..;
      run;
   %end;

%mend;
