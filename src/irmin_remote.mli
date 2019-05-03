module type STORAGE = sig
  type t

  val t : t Irmin.Type.t

  val config_key : t option Irmin.Private.Conf.key

  val exists : t -> string -> bool Lwt.t

  val get : t -> string -> string option Lwt.t

  val put : t -> string -> string -> unit Lwt.t

  val del : t -> string -> unit Lwt.t
end

module Content_addressable (Storage : STORAGE) :
  Irmin.CONTENT_ADDRESSABLE_STORE_MAKER

module Make (Storage : STORAGE) (AW : Irmin.ATOMIC_WRITE_STORE_MAKER) :
  Irmin.S_MAKER

module KV (Storage : STORAGE) (AW : Irmin.ATOMIC_WRITE_STORE_MAKER) :
  Irmin.KV_MAKER

module Mem : sig
  module Make (Storage : STORAGE) : Irmin.S_MAKER

  module KV (Storage : STORAGE) : Irmin.KV_MAKER
end

module Git : sig
  module Make
      (Storage : STORAGE)
      (AW : Irmin.ATOMIC_WRITE_STORE_MAKER)
      (C : Irmin.Contents.S)
      (P : Irmin.Path.S)
      (B : Irmin.Branch.S) :
    Irmin.S with type contents = C.t and type key = P.t and type branch = B.t

  module KV
      (Storage : STORAGE)
      (AW : Irmin.ATOMIC_WRITE_STORE_MAKER)
      (C : Irmin.Contents.S) : Irmin.KV with type contents = C.t

  module Mem : sig
    module Make
        (Storage : STORAGE)
        (C : Irmin.Contents.S)
        (P : Irmin.Path.S)
        (B : Irmin.Branch.S) :
      Irmin.S with type contents = C.t and type key = P.t and type branch = B.t

    module KV (Storage : STORAGE) (C : Irmin.Contents.S) :
      Irmin.KV with type contents = C.t
  end
end
