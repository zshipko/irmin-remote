module Store =
  Irmin_remote.Mem.KV (Irmin_remote_s3.Storage) (Irmin.Contents.String)
