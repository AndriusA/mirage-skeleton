open Lwt
open V1_LWT
open Printf

let red fmt    = sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = sprintf ("\027[36m"^^fmt^^"\027[m")

module Main (C:CONSOLE) (S:STACKV4) = struct

  module T  = S.TCPV4
  module CH = Channel.Make(T)
  module H  = HTTP.Make(CH)

  let start console s =
  ignore begin
    while_lwt true do OS.Time.sleep 1.0 >> C.log_s console "Heartbeat" done
  end;


    C.log_s console "Console started" 
      >>= fun() ->
    C.log_s console (sprintf "IP address: %s\n" (Ipaddr.V4.to_string (S.IPV4.get_ipv4 (S.ipv4 s)))) >>= fun () ->
    let http_callback conn_id req body =
      let path = Uri.path (H.Server.Request.uri req) in
      C.log_s console (sprintf "Got request for %s\n" path) 
      >>= fun () ->
      H.Server.respond_string ~status:`OK ~body:"hello mirage world!\n" ()
    in

    let spec = {
      H.Server.callback = http_callback;
      conn_closed = fun _ () -> ();
    } in

    S.listen_udpv4 s 53 (
      fun ~src ~dst ~src_port buf ->
        C.log_s console "got udp on 53"
    );

    C.log_s console "listen 8080" 
      >>= fun() ->
    S.listen_tcpv4 s 8080 (
      fun flow ->
        let dst, dst_port = T.get_dest flow in
        C.log_s console
          (green "new tcp from %s %d" 
            (Ipaddr.V4.to_string dst) dst_port
          )
        >>= fun () ->
        T.read flow
        >>= function
        | `Ok b ->
          C.log_s console
            (yellow "read: %d\n%s" 
              (Cstruct.len b) (Cstruct.to_string b)
            )
          >>= fun () ->
          T.close flow
        | `Eof -> C.log_s console (red "read: eof")
        | `Error e -> C.log_s console (red "read: error")
    );

    C.log_s console "listen 80" 
      >>= fun() ->
    S.listen_tcpv4 s 80 (H.Server.listen spec);
    S.listen s

end
