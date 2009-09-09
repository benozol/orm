TYPE_CONV_PATH "Variant"

type t = 
  |Foo
  |Bar of int
  |Xyz of string
and
x = {
  foo: t;
  o: int;
}
with persist()

let _ = 
  let db = Orm.init "variant.db" in
  let x1 = Orm.x_new ~foo:Foo ~o:100 db in
  let x2 = Orm.x_new ~foo:(Bar 1) ~o:101 db in
  let x3 = Orm.x_new ~foo:(Xyz "hello") ~o:102 db in
  List.iter (fun x -> Printf.printf "saved: %Lu\n%!" x#save) [x1;x2;x3];
  List.iter (fun x -> Printf.printf "updated: %Lu\n%!" x#save) [x1;x2;x3]

