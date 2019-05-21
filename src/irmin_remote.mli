(** [STORAGE] is used to define a remote storage implementation *)
module type STORAGE = sig
  (** Storage context *)
  type t

  (** Context serializer *)
  val t : t Irmin.Type.t

  (** Irmin configuration key *)
  val config_key : t option Irmin.Private.Conf.key

  (** [true] when the key exists, otherwise [false] *)
  val exists : t -> string -> bool Lwt.t

  (** Get the value associated with the given key,
      [None] will be returned when the key is empty. *)
  val get : t -> string -> string option Lwt.t

  (** [put ctx key value] sets [key] to [value] *)
  val put : t -> string -> string -> unit Lwt.t

  (** Removes the given key from the remote store *)
  val del : t -> string -> unit Lwt.t
end

(** [Content_addressable] creates an [Irmin.CONTENT_ADDRESSABLE_STORE_MAKER]
    for the given remote storage implementation *)
module Content_addressable (Storage : STORAGE) :
  Irmin.CONTENT_ADDRESSABLE_STORE_MAKER

(** [Make] creates an [Irmin.S_MAKER] for the given remote storage and
    [Irmin.ATOMIC_WRITE_STORE_MAKER] implementations *)
module Make (Storage : STORAGE) (AW : Irmin.ATOMIC_WRITE_STORE_MAKER) :
  Irmin.S_MAKER

(** [KV] creates an [Irmin.KV_MAKER] for the given remote storage and
    [Irmin.ATOMIC_WRITE_STORE_MAKER] implementations *)
module KV (Storage : STORAGE) (AW : Irmin.ATOMIC_WRITE_STORE_MAKER) :
  Irmin.KV_MAKER

(** Convenience wrappers for creating in-memory stores *)
module Mem : sig
  module Make (Storage : STORAGE) : Irmin.S_MAKER

  module KV (Storage : STORAGE) : Irmin.KV_MAKER
end

(** Convenience wrappers for creating Git stores *)
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
