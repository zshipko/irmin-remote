open Lwt.Infix
open Aws_s3_lwt
module Region = Aws_s3.Region
module Credentials = Aws_s3.Credentials

type context = { bucket : string; auth : Credentials.t; region : Region.t }

let context ~bucket ~auth ~region =
  let region = Region.of_string region in
  { bucket; auth; region }

let endpoint t = Aws_s3.Region.endpoint ~inet:`V4 ~scheme:`Https t.region

module Storage = struct
  type t = context

  let credentials =
    let open Irmin.Type in
    record "s3_credentials" (fun access_key secret_key token expiration ->
        Credentials.make ~access_key ~secret_key ?token ?expiration () )
    |+ field "access_key" string (fun x -> x.Credentials.access_key)
    |+ field "secret_key" string (fun x -> x.Credentials.secret_key)
    |+ field "token" (option string) (fun x -> x.Credentials.token)
    |+ field "expiration" (option float) (fun x -> x.Credentials.expiration)
    |> sealr

  let t =
    let open Irmin.Type in
    record "s3" (fun bucket auth region -> context ~bucket ~auth ~region)
    |+ field "bucket" string (fun x -> x.bucket)
    |+ field "auth" credentials (fun x -> x.auth)
    |+ field "region" string (fun x -> Region.to_string x.region)
    |> sealr

  let get t key =
    let endpoint = endpoint t in
    S3.get ~credentials:t.auth ~bucket:t.bucket ~endpoint ~key () >|= function
    | Ok x -> Some x
    | Error _ -> None

  let exists t key =
    get t key >>= function
    | Some _ -> Lwt.return_true
    | None -> Lwt.return_false

  let del t key =
    let endpoint = endpoint t in
    S3.delete ~credentials:t.auth ~bucket:t.bucket ~endpoint ~key ()
    >|= function
    | Ok _ -> ()
    | Error _ -> invalid_arg "Storage.del"

  let put t key data =
    let endpoint = endpoint t in
    S3.put ~credentials:t.auth ~bucket:t.bucket ~endpoint ~key ~data ()
    >|= function
    | Ok _ -> ()
    | Error _ -> invalid_arg "Storage.put"
end

module Mem = struct
  module Make = Irmin_remote.Make (Storage) (Irmin_mem.Atomic_write)
  module KV = Irmin_remote.KV (Storage) (Irmin_mem.Atomic_write)
end
