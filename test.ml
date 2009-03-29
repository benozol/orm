(* test out the ORM library *)

open OUnit
open Ormtest
open Printf

let db_name = ref "test.db"

let must = function
   |None -> assert_failure "must"
   |Some x -> x

let never = function
   |Some x -> assert_failure "never"
   |None -> ()

let open_db ?(rm=false) () =
  if Sys.file_exists !db_name && rm then Sys.remove !db_name;
  Init.t !db_name

let test_init () =
   (* do two inits, should be idempotent *)
   let _ = open_db () in
   let _ = open_db () in
   let _ = open_db ~rm:true () in
   ()

let gen_contact fname lname db =
   let now = Unix.gettimeofday () in
   Contact.t ~first_name:fname ~last_name:lname
     ~email:(sprintf "%s.%s@example.com" fname lname) ~mtime:now db 

let test_simple_insert_update_delete () =
   let db = open_db ~rm:true () in
   let contact = gen_contact "John" "Smith" db in
   let id = contact#save in
   "contact has id" @? (contact#id <> None);
   let contact' = Contact.get ~id:(Some id) db in
   assert_equal (List.length contact') 1; 
   let id2 = contact#save in
   assert_equal id id2;
   let contact'' = Contact.get ~id:(Some id2) db in
   assert_equal (List.length contact'') 1;
   assert_equal (List.hd contact'')#id (List.hd contact')#id;
   assert_equal contact#id (List.hd contact')#id;
   contact#set_first_name "Foo";
   ignore(contact#save);
   assert_equal contact#first_name "Foo";
   let contact' = List.hd (Contact.get ~id:(Some id) db) in
   assert_equal contact'#first_name "Foo";
   contact#delete;
   assert_equal contact#id None;
   let id' = contact#save in
   "contact has new id" @? (id' <> id)

let test_new_foreign_map () =
   let db = open_db ~rm:true () in
   let now = Unix.gettimeofday () in
   let from = gen_contact "John" "Smith" db in
   let cto = List.map (fun (a,b) -> gen_contact a b db) [
      ("Alice","Aardvark"); ("Bob","Bear"); ("Charlie","Chaplin") ] in
   let atts = [] in
   let e = Entry.t ~body:"Test Body" ~received:now ~people_from:from
     ~atts:atts ~people_to:cto db in
   let eid = e#save in
   ()

let suite = "SQL ORM test" >:::
    [  "test_init" >:: test_init ;
       "test_simple_insert" >:: test_simple_insert_update_delete; 
       "test_new_foreign_map" >:: test_new_foreign_map;
    ]

(* Returns true if the result list contains successes only *)
let rec was_successful results =
  match results with
      [] -> true
    | RSuccess _::t
    | RSkip _::t -> was_successful t
    | RFailure _::_
    | RError _::_
    | RTodo _::_ -> false

let _ =
  let verbose = ref false in
  let set_verbose _ = verbose := true in
  Arg.parse
    [("-verbose", Arg.Unit set_verbose, "Run the tests in verbose mode.");]
    (fun x -> raise (Arg.Bad ("Bad argument : " ^ x)))
    ("Usage: " ^ Sys.argv.(0) ^ " [-verbose]");

  if not (was_successful (run_test_tt ~verbose:!verbose suite)) then
    exit 1