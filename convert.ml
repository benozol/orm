open Printf

let _ =
   let fin = open_in Sys.argv.(1) in
   let fout = open_out Sys.argv.(2) in
   fprintf fout "(* autogenerated from convert.ml and sql_access.ml *)\n";
   fprintf fout "open Printer_utils.Printer\n";
   fprintf fout "let print_header e =\n";
   (try while true do
      let l = input_line fin in
      fprintf fout "  e.p \"%s\";\n" (String.escaped l);
    done with End_of_file -> ());
   fprintf fout "  ()";
   close_out fout;
   close_in fin