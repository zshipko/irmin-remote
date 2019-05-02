open Lwt.Infix
include Irmin_remote_b2.Client (Cohttp_lwt_unix.Client)
module Store =
  Irmin_remote.KV (Storage) (Irmin_unix.FS.Atomic_write)
    (Irmin.Contents.String)

let account_id = Unix.getenv "IRMIN_REMOTE_B2_ACCOUNT_ID"

let application_key = Unix.getenv "IRMIN_REMOTE_B2_APPLICATION_KEY"

let config = Irmin_fs.config "/tmp/irmin-remote-b2"

let config ctx = Irmin.Private.Conf.add config Storage.config_key (Some ctx)

let main =
  API.authorize_account ~account_id ~application_key >>= fun token ->
  API.list_buckets ~token >>= fun buckets ->
  let bucket =
    List.find
      (fun x -> x.API.Bucket.bucket_name = "zachshipko-testing")
      buckets
  in
  let ctx = context ~bucket ~token in
  let config = config ctx in
  Store.Repo.v config >>= Store.master >>= fun t ->
  Store.set_exn t ~info:(Irmin_unix.info "testing") [ "a"; "b"; "c" ] "123"
  >>= fun () -> Store.get t [ "a"; "b"; "c" ] >>= fun s -> Lwt_io.printl s

let () = Lwt_main.run main
