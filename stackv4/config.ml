open Mirage

let ipv4_config = 
  let address = Ipaddr.V4.of_string_exn "192.95.61.162" in
  let netmask = Ipaddr.V4.of_string_exn "255.255.255.0" in
  let gateways = [Ipaddr.V4.of_string_exn "192.95.61.254"] in
  { address; netmask; gateways }

let handler = foreign "Unikernel.Main" (console @-> stackv4 @-> job)

let direct =
  let stack = direct_stackv4_with_static_ipv4 default_console tap0 ipv4_config in
  handler $ default_console $ stack

(* Only add the Unix socket backend if the configuration mode is Unix *)
let socket =
  let c = default_console in
  match get_mode () with
  | `Xen -> []
  | `Unix -> [ handler $ c $ socket_stackv4 c [Ipaddr.V4.any] ]

let () =
  add_to_ocamlfind_libraries ["mirage-http"];
  add_to_opam_packages ["mirage-http"];
  register "stackv4" [direct]
