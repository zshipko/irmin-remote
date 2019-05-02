open Aws_s3

type context = { bucket : string; auth : Credentials.t; region : Region.t }

val context :
  bucket:string ->
  access_key:string ->
  secret_key:string ->
  region:string ->
  context

module Storage : Irmin_remote.STORAGE with type t = context
