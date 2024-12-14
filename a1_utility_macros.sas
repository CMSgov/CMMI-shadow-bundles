/*************************************************************************;
%** PROGRAM: a1_utility_macros.sas
%** PURPOSE: To provide functions that perform quick and regular tasks
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

%macro a1_utility_macros();

   *function to create a list of objects separated by a specified delimiter;
   %macro macarray(k , str, start=1, noise=1, dlm=%STR( )) / des="Creates an array of global macro variables" ;   
      %local i j; %global n&k.;
      %let i=1;

      %do %while(%length(%scan(&str,&i,%str(&dlm))) GT 0);
         %let i=%eval(&i + 1);
      %end;   
      %let n&k.=%eval(&i - 1);
      %If &Noise %Then %put (&SYSMACRONAME.:) n&k.= &&n&k.., str=&str.;


      %do i=&start. %to  %eval(&start.+&&n&k..-1);
         %let j=%eval(&i.-&start.+1);
         %global &&k.&i.;
         %let &k.&i.=%scan(&str., &j, %STR(&dlm));
      %end;

      %do i=&start. %to  %eval(&start.+&&n&k..-1);
         %If &Noise %Then %put (&SYSMACRONAME.:) &k.&i. = &&&&&k.&i. ;
      %end;

   %mend;
   
   *function of create folder(s); 
   %macro MkDirs / parmbuff;


      %local sysbuff D;
      %*get rid of parenthesis in syspbuff, and turn comma into colon;
      %let sysbuff=%substr(&syspbuff,2,%length(&syspbuff)-2);
      %Let sysbuff=%sysfunc(translate(%BQuote(&sysbuff),#,%BQUOTE(,)));
      %Macarray(Dir,&sysbuff, dlm=%Str(#));

      %Let MSG=;
      %Let Term=;

      Data _Null_;
         length Path $1000;
         Array Directory{&NDir} $1000 (%Do D=1 %to &NDir; "&&Dir&D" %End;);

         do d=1 to dim(Directory);
            if substr(directory{d}, 1, 1) ='\' then do;
               path='\';
               N_Folders=countc(Directory{d},'\') -1;
            end;
            else do;
               path='';
               N_Folders=countc(Directory{d},'\') +1;
            end;
            *Put (d N_Folders Directory{d}) (=);
            do f=1 to N_Folders;
               Folder=scan(directory{d}, f, '\');
               path=catx('\', path, Folder);
               *Put (d path) (=);
               if f>1 and fileexist(path)=0 then do; 
                  DirCreated = modulen ('CreateDirectoryA', path, 0)  ;
                  if DirCreated=0 and fileexist(path)=0 then do;
                     put 'CreateDirectory Failure: ' DirCreated= path=;
                     MSG=cat('Mkdirs cannot create directory ',trim(path));
                     **MSG='Mkdirs cannot create directory';
                     put msg=;
                     call symputx('MSG', MSG);
                     Call SymPutX('TERM', "Permissions Problem creating Folder");
                  end;
                  else put "New Dir Created: " path=;
                  *put "DirCreated: " path=;
               End;
               *else put "Dir Already Exists:  " path=;
            end;

         end;
      Run;

      %If %Length(&MSG) %Then %Do;
         %MessageBox(Message=&MSG, Line2=, Title=&TERM) ;
      %End;

   %mend MkDirs;

   *function to create log file;
   %macro create_log_file(log_file_name =);
      *set log file location; 
      x "mkdir &log_dir.";
      x "mkdir &log_dir.\&run_date.";
      %mkdirs(&log_dir.\&run_date.);
      proc printto log = "&log_dir.\&run_date.\&log_file_name..log" new;
      run;
   %mend;
   
   *function to make a lit separated by commas; 
   %macro clist(input_list, DLM=%str( ), noise=0);
      %local return_list i;

      %*create macarray using input_list, so we can loop through and add commas in between the items in the list;
      %macarray(_tmp_list_, &input_list, DLM=&DLM, noise=&noise)

      %let return_list = ;
      %do i=1 %to &n_tmp_list_;
         %*add a comma before every item, starting with the second item;
         %if &i>1 %then %let return_list = &return_list, &&_tmp_list_&i;
         %else          %let return_list = &return_list  &&_tmp_list_&i;
      %end;

      %*here is the "return statement", the value of return_list will be placed where the %clist macro call occurs. %clist(...) --> &return_list;
      &return_list
   %mend;   
   
   *function to make a list of quoted elements, separated by a specified delimiter; 
   %macro quotelst(str, quote=%str(%"), delim=%str( ));
      %local i quotelst;
      %let i=1;

      %do %while(%length(%scan(&str,&i,%str( ))) GT 0);
         %if %length(&quotelst.) EQ 0 %then %let quotelst=&quote.%scan(&str,&i,%str( ))&quote;
         %else %let quotelst=&quotelst.&quote.%scan(&str,&i,%str( ))&quote;
         %let i=%eval(&i.+1);
         %if %length(%scan(&str,&i,%str( ))) GT 0 %then %let quotelst=&quotelst.&delim;
      %end;

      %unquote(&quotelst)
   %mend;
   
%mend;
