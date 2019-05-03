open Aws_s3

type context = { bucket : string; auth : Credentials.t; region : Region.t }

val context :
  bucket:string ->
  access_key:string ->
  secret_key:string ->
  region:string ->
  context

module Make (X : Aws_s3.Types.Io with type 'a Deferred.t = 'a Lwt.t) :
  Irmin_remote.STORAGE with type t = context
