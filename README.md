# irmin-remote

`irmin-remote` is an experimental library that enables remote storage for [Irmin](https://irmin.io) blob. The goal for this library is to provide the ability for objects to be stored in the *cloud*, enabling many irmin instances to share the same data directly.

## Backends

- `irmin-remote-s3`: [Amazon S3](https://aws.amazon.com/s3/)

Examples for each of these can be found in `bin/`

## Installation

```shell
$ opam pin add irmin-remote https://github.com/zshipko/irmin-remote.git
```

### S3 bindings

```shell
$ opam install aws-s3
$ opam pin add irmin-remote-s3 https://github.com/zshipko/irmin-remote.git
```
