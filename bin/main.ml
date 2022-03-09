let port = ref None

let server_port = ref 8080

let destination = ref None

let out_file = ref "dump.json"

let proto_roots = ref None

let () =
  Arg.parse
    [
      ( "--port",
        Int (fun p -> port := Some p),
        Printf.sprintf "Listen for gRPC requests on port" );
      ( "--dst",
        String (fun d -> destination := Some d),
        Printf.sprintf "Destination for gRPC requests" );
      ( "--http-port",
        Set_int server_port,
        Printf.sprintf "Start http server on this port (default: %i)"
          !server_port );
      ( "--proto-roots",
        String (fun d -> proto_roots := Some d),
        Printf.sprintf "Path to the proto roots file" );
    ]
    (fun name -> raise (Arg.Bad ("Don't know what I should do with : " ^ name)))
    (Printf.sprintf "Usage: %s [--port PORT] [--dst DESTINATION]" Sys.argv.(0))

let port = Option.get !port

let dst = Option.get !destination

let proto_roots = Option.get !proto_roots

let command =
  ( "",
    [|
      "grpc-dump";
      "-port";
      string_of_int port;
      "-destination";
      dst;
      "-proto_roots";
      proto_roots;
    |] )

let () =
  let subprocess =
    Lwt_process.pread_lines ~stderr:(`FD_copy Unix.stdout) command
  in
  let sink = Lwt_stream.iter ignore subprocess in
  let server =
    Dream.serve ~port:!server_port
    @@ Dream.logger
    @@ Dream.router
         [
           Dream.get "/tail" (fun _ ->
               Dream.stream ~status:`OK (fun response_stream ->
                   let stream = Lwt_stream.clone subprocess in
                   Lwt_stream.iter_p
                     (fun x ->
                       Lwt.bind
                         (Dream.write response_stream (x ^ "\n"))
                         (fun () -> Dream.flush response_stream))
                     stream));
         ]
  in
  Lwt.pick [ sink; server ] |> Lwt_main.run
