# Glesia

Safe-ish Gleam bindings for Erlang Mnesia.

Glesia follows the same idea as `glixir`: keep the public API in Gleam, and use
a tiny Erlang FFI layer for the OTP feature that Gleam does not wrap directly.
Mnesia records are dynamic BEAM tuples, so Glesia keeps that boundary explicit
with `Dynamic` values and optional decoders.

## Install

```sh
gleam add glesia
```

## Quick start

```gleam
import glesia
import gleam/dynamic
import gleam/erlang/atom

pub fn main() -> Nil {
  let users = atom.create_from_string("users")

  let _ = glesia.set_dir("/tmp/my_app_mnesia")
  let _ = glesia.create_local_schema()
  let assert Ok(_) = glesia.start()
  let _ = glesia.create_ram_table(users, [
    atom.create_from_string("id"),
    atom.create_from_string("name"),
  ])

  let assert Ok(_) = glesia.dirty_write(dynamic.from(#(users, 1, "Ada")))
  let assert Ok(records) = glesia.dirty_read(users, dynamic.from(1))

  let _ = glesia.stop()
}
```

## API

- `create_schema(nodes)`
- `create_local_schema()`
- `delete_schema(nodes)`
- `delete_local_schema()`
- `set_dir(path)`
- `start()`
- `stop()`
- `create_table(table, attributes, storage_type, table_type)`
- `create_ram_table(table, attributes)`
- `dirty_write(record)`
- `dirty_read(table, key)`
- `dirty_read_decoded(table, key, decoder)`
- `dirty_delete(table, key)`
- `transaction(fun)`

## Safety notes

Mnesia table names and attributes are atoms. Do not create atoms from untrusted
user input. Records are Erlang tuples, so reads return `Dynamic` unless you pass
a decoder with `dirty_read_decoded`.

The wrapper is intentionally small. It gives Gleam code access to Mnesia without
hiding the BEAM interop boundary.

## Development

```sh
gleam test
```
