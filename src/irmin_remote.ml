open Lwt.Infix

module type STORAGE = sig
  type t

  val t : t Irmin.Type.t

  val config_key : t option Irmin.Private.Conf.key

  val exists : t -> string -> bool Lwt.t

  val get : t -> string -> string option Lwt.t

  val put : t -> string -> string -> unit Lwt.t

  val del : t -> string -> unit Lwt.t
end

module Remote (Storage : STORAGE) (Key : Irmin.Hash.S) (Value : Irmin.Type.S) =
struct
  type 'a t = { storage : Storage.t }

  type key = Key.t

  type value = Value.t

  let batch { storage } f = f { storage }

  let mem t key = Storage.exists t.storage (Irmin.Type.to_string Key.t key)

  let find t key =
    Storage.get t.storage (Irmin.Type.to_string Key.t key) >|= function
    | None -> None
    | Some x -> (
      match Irmin.Type.of_string Value.t x with Ok x -> Some x | _ -> None )

  let add t value =
    let s = Irmin.Type.to_string Value.t value in
    let hash = Key.digest s in
    let hash_s = Irmin.Type.to_string Key.t hash in
    Storage.put t.storage hash_s s >|= fun () -> hash

  let v config =
    let storage =
      match Irmin.Private.Conf.get config Storage.config_key with
      | Some x -> x
      | None -> raise (Invalid_argument "Remote.v: Invalid credentials")
    in
    Lwt.return { storage }
end

module Make (Storage : STORAGE) (AW : Irmin.ATOMIC_WRITE_STORE_MAKER) =
  Irmin.Make (Remote (Storage)) (AW)
module KV
    (Storage : STORAGE)
    (AW : Irmin.ATOMIC_WRITE_STORE_MAKER)
    (C : Irmin.Contents.S) =
  Irmin.Make (Remote (Storage)) (AW) (Irmin.Metadata.None) (C)
    (Irmin.Path.String_list)
    (Irmin.Branch.String)
    (Irmin.Hash.SHA1)

module Mem = struct
  module Make (Storage : STORAGE) = Make (Storage) (Irmin_mem.Atomic_write)
  module KV (Storage : STORAGE) = KV (Storage) (Irmin_mem.Atomic_write)
end
