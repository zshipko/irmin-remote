open Lwt.Infix
open Irmin_s3_unix
module Store =
  Irmin_remote.KV (Storage) (Irmin_unix.FS.Atomic_write)
    (Irmin.Contents.String)

let access_key = Unix.getenv "IRMIN_REMOTE_S3_ACCESS_KEY"

let secret_key = Unix.getenv "IRMIN_REMOTE_S3_SECRET_KEY"

let ctx =
  Irmin_s3_unix.context ~bucket:"zachshipko-testing" ~access_key ~secret_key
    ~region:"us-west-2"

let config = Irmin_fs.config "/tmp/irmin-remote-s3"

let config = Irmin.Private.Conf.add config Storage.config_key (Some ctx)

let main =
  Store.Repo.v config >>= Store.master >>= fun t ->
  Store.set_exn t ~info:(Irmin_unix.info "testing") [ "a"; "b"; "c" ] "123"
  >>= fun () -> Store.get t [ "a"; "b"; "c" ] >>= fun s -> Lwt_io.printl s

let () = Lwt_main.run main
