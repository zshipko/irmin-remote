# irmin-remote

`irmin-remote` is an experiment in using remote storage for [Irmin](https://irmin.io) blobs. The goal for this library is to provide the ability for many irmin instances to share the same data directly.

## Backends

- `irmin-s3-unix`: [Amazon S3](https://aws.amazon.com/s3/)

Examples for each of these can be found in `bin/`

## Installation

```shell
$ opam pin add irmin-remote https://github.com/zshipko/irmin-remote.git
```

### S3 bindings

```shell
$ opam install aws-s3-lwt
$ opam pin add irmin-s3 https://github.com/zshipko/irmin-remote.git
$ opam pin add irmin-s3-unix https://github.com/zshipko/irmin-remote.git
```
