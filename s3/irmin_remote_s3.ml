open Lwt.Infix
open Aws_s3_lwt
module Region = Aws_s3.Region
module Credentials = Aws_s3.Credentials

type context = { bucket : string; auth : Credentials.t; region : Region.t }

let context ~bucket ~access_key ~secret_key ~region =
  let region = Region.of_string region in
  let auth = Credentials.make ~access_key ~secret_key () in
  { bucket; auth; region }

let endpoint t = Aws_s3.Region.endpoint ~inet:`V4 ~scheme:`Https t.region

let string_of_error = function
  | S3.Redirect _ -> "Redirected"
  | S3.Throttled -> "Throttled"
  | S3.Unknown (_, msg) -> msg
  | S3.Failed f -> raise f
  | S3.Not_found -> "Not found"

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
    record "s3" (fun bucket auth region ->
        { bucket; auth; region = Region.of_string region } )
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
    | Error err -> invalid_arg ("Storage.del: " ^ string_of_error err)

  let put t key data =
    let endpoint = endpoint t in
    S3.put ~credentials:t.auth ~bucket:t.bucket ~endpoint ~key ~data ()
    >|= function
    | Ok _ -> ()
    | Error err -> invalid_arg ("Storage.put: " ^ string_of_error err)

  let auth =
    let parser = Irmin.Type.of_string t in
    let fmt = Irmin.Type.pp t in
    (parser, fmt)

  let config_key =
    Irmin.Private.Conf.key ~docv:"AUTH" ~doc:"Remote store credentials"
      "credentials"
      Irmin.Private.Conf.(some auth)
      None
end
