open Lwt.Infix

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

module Remote (Storage : STORAGE) (Key : Irmin.Hash.S) (Value : Irmin.Type.S) =
struct
  type 'a t = { storage : Storage.t }

  type key = Key.t

  type value = Value.t

  let auth =
    let parser = Irmin.Type.of_string Storage.t in
    let fmt = Irmin.Type.pp Storage.t in
    (parser, fmt)

  let credentials =
    Irmin.Private.Conf.key ~docv:"AUTH" ~doc:"Remote store credentials"
      "credentials"
      Irmin.Private.Conf.(some auth)
      None

  let v config =
    let storage =
      match Irmin.Private.Conf.get config credentials with
      | Some x -> x
      | None -> raise (Invalid_argument "Remote.v: Invalid credentials")
    in
    Lwt.return { storage }

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
