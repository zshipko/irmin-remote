open Aws_s3

type context = { bucket : string; auth : Credentials.t; region : Region.t }

val context : bucket:string -> auth:Credentials.t -> region:string -> context

module Storage : Irmin_remote.STORAGE with type t = context
