open Lwt.Infix

module Client (Client : Cohttp_lwt.S.Client) = struct
  module API = B2.V1 (Client)

  type context = { token : API.Token.t; bucket : API.Bucket.t }

  let context ~bucket ~token = { bucket; token }

  module Storage = struct
    type t = context

    let token =
      let open Irmin.Type in
      record "token"
        (fun account_id
        authorization_token
        api_url
        download_url
        minimum_part_size
        ->
          API.Token.
            { account_id;
              authorization_token;
              api_url;
              download_url;
              minimum_part_size
            } )
      |+ field "account_id" string (fun x -> x.API.Token.account_id)
      |+ field "authorization_token" string (fun x ->
             x.API.Token.authorization_token )
      |+ field "api_url" string (fun x -> x.API.Token.api_url)
      |+ field "download_url" string (fun x -> x.API.Token.download_url)
      |+ field "minimum_part_size" int (fun x -> x.API.Token.minimum_part_size)
      |> sealr

    let bucket_type =
      let open Irmin.Type in
      enum "bucket_type" [ ("Public", `Public); ("Private", `Private) ]

    let bucket =
      let open Irmin.Type in
      record "bucket"
        (fun account_id
        bucket_id
        bucket_name
        bucket_type
        bucket_info
        revision
        ->
          let bucket_info = Ezjsonm.from_string bucket_info in
          API.Bucket.
            { account_id;
              bucket_id;
              bucket_name;
              bucket_type;
              bucket_info;
              revision
            } )
      |+ field "account_id" string (fun x -> x.API.Bucket.account_id)
      |+ field "bucket_id" string (fun x -> x.API.Bucket.bucket_id)
      |+ field "bucket_name" string (fun x -> x.API.Bucket.bucket_name)
      |+ field "bucket_type" bucket_type (fun x -> x.API.Bucket.bucket_type)
      |+ field "bucket_info" string (fun x ->
             Ezjsonm.value_to_string x.API.Bucket.bucket_info )
      |+ field "revision" int64 (fun x -> x.API.Bucket.revision)
      |> sealr

    let t =
      let open Irmin.Type in
      record "b2" (fun token bucket -> { token; bucket })
      |+ field "token" token (fun x -> x.token)
      |+ field "bucket" bucket (fun x -> x.bucket)
      |> sealr
  end

  module Mem = struct
    module Make = Irmin_remote.Make (Storage) (Irmin_mem.Atomic_write)
    module KV = Irmin_remote.KV (Storage) (Irmin_mem.Atomic_write)
  end
end
