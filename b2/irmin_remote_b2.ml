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

    let get { token; bucket } key =
      API.list_file_names ~token ~start_file_name:key ~max_file_count:1
        ~bucket_id:bucket.bucket_id ()
      >>= fun (files, _) ->
      match files with
      | f :: _ when f.file_name = key ->
          API.get_download_authorization ~token ~bucket_id:bucket.bucket_id
            ~file_name_prefix:key ~valid_duration_in_seconds:60
          >>= fun auth ->
          API.download_file_by_name ~auth ~file_name:key () >>= Lwt.return_some
      | _ -> Lwt.return_none

    let exists { token; bucket } key =
      API.list_file_names ~token ~start_file_name:key ~max_file_count:1
        ~bucket_id:bucket.bucket_id ()
      >|= fun (files, _) ->
      match files with f :: _ -> f.file_name = key | [] -> false

    let put { token; bucket } key value =
      API.get_upload_url ~token ~bucket_id:bucket.bucket_id >>= fun url ->
      let data = Lwt_stream.of_string value in
      API.upload_file ~url ~data ~file_name:key () >>= fun _ -> Lwt.return_unit

    let del { token; bucket } key =
      API.list_file_names ~token ~start_file_name:key ~max_file_count:1
        ~bucket_id:bucket.bucket_id ()
      >>= fun (files, _) ->
      match files with
      | f :: _ when f.file_name = key ->
          API.delete_file_version ~token ~file_name:key ~file_id:f.file_id
          >>= fun _ -> Lwt.return_unit
      | _ -> Lwt.return_unit

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
end
