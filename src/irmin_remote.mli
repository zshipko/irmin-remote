module type STORAGE = sig
  type t

  val t : t Irmin.Type.t

  val exists : t -> string -> bool Lwt.t

  val get : t -> string -> string option Lwt.t

  val put : t -> string -> string -> unit Lwt.t

  val del : t -> string -> unit Lwt.t
end

module type S = sig
  type storage

  val storage : storage Irmin.Private.Conf.key

  val config : ?confing:Irmin.config -> storage -> Irmin.config

  include Irmin.S
end

module Remote (Storage : STORAGE) : Irmin.CONTENT_ADDRESSABLE_STORE_MAKER

module Make (Storage : STORAGE) (AW : Irmin.ATOMIC_WRITE_STORE_MAKER) :
  Irmin.S_MAKER

module KV (Storage : STORAGE) (AW : Irmin.ATOMIC_WRITE_STORE_MAKER) :
  Irmin.KV_MAKER
