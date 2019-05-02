# irmin-remote

`irmin-remote` is an experiment in using remote storage backends for [irmin](https://irmin.io) blobs

## Backends

- `irmin-remote-s3`: [Amazon S3](https://aws.amazon.com/s3/)
- `irmin-remote-b2`: [Backblaze B2](https://www.backblaze.com/b2/) (using [b2](https://github.com/zshipko/ocaml-b2), which is not yet on opam)

Examples for each of these can be found in `bin/`

## Installation

```shell
$ opam pin add irmin-remote https://github.com/zshipko/irmin-remote.git
```

### S3 bindings

```shell
$ opam install aws-s3-lwt
$ opam pin add irmin-remote-s3 https://github.com/zshipko/irmin-remote.git
```

### B2 bindings

```shell
$ opam pin add b2 https://github.com/zshipko/ocaml-b2.git
$ opam pin add irmin-remote-b2 https://github.com/zshipko/irmin-remote.git
```

