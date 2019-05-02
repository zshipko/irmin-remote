open Lwt.Infix
module Store =
  Irmin_remote.KV (Irmin_remote_s3.Storage) (Irmin_unix.FS.Atomic_write)
    (Irmin.Contents.String)

let access_key = Unix.getenv "IRMIN_REMOTE_S3_ACCESS_KEY"

let secret_key = Unix.getenv "IRMIN_REMOTE_S3_SECRET_KEY"

let auth = Aws_s3.Credentials.make ~access_key ~secret_key ()

let ctx =
  Irmin_remote_s3.context ~bucket:"zachshipko-testing" ~auth
    ~region:"us-west-2"

let config = Irmin_fs.config "/tmp/irmin-remote-s3"

let config =
  Irmin.Private.Conf.add config Irmin_remote_s3.Storage.config_key (Some ctx)

let main =
  Store.Repo.v config >>= Store.master >>= fun t ->
  Store.set_exn t ~info:(Irmin_unix.info "testing") [ "a"; "b"; "c" ] "123"
  >>= fun () -> Store.get t [ "a"; "b"; "c" ] >>= fun s -> Lwt_io.printl s

let () = Lwt_main.run main
