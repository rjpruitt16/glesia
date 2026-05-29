//// Safe-ish Gleam bindings for Erlang Mnesia.
////
//// Glesia wraps the common Mnesia lifecycle and data operations while keeping
//// the dynamic BEAM boundary explicit. Table names and attributes are atoms;
//// records cross the FFI boundary as `Dynamic` values and can be decoded by
//// callers with normal Gleam decoders.

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{type Decoder}
import gleam/erlang/atom.{type Atom}
import gleam/list
import gleam/result
import gleam/string

pub type MnesiaError {
  AlreadyExists
  NotFound
  Timeout
  BadType(String)
  Abort(String)
  Unknown(String)
}

pub type StorageType {
  RamCopies
  DiscCopies
  DiscOnlyCopies
}

pub type TableType {
  Set
  OrderedSet
  Bag
}

pub type SchemaResult {
  SchemaOk
  SchemaError(reason: Dynamic)
}

pub type SimpleResult {
  SimpleOk
  SimpleError(reason: Dynamic)
}

pub type TableCreateResult {
  TableCreateOk
  TableCreateAlreadyExists
  TableCreateError(reason: Dynamic)
}

pub type ReadResult {
  ReadOk(records: List(Dynamic))
  ReadError(reason: Dynamic)
}

pub type TransactionResult {
  TransactionOk(value: Dynamic)
  TransactionAbort(reason: Dynamic)
}

@external(erlang, "glesia_ffi", "create_schema")
fn create_schema_ffi(nodes: List(Atom)) -> SchemaResult

@external(erlang, "glesia_ffi", "delete_schema")
fn delete_schema_ffi(nodes: List(Atom)) -> SchemaResult

@external(erlang, "glesia_ffi", "set_dir")
fn set_dir_ffi(path: String) -> SimpleResult

@external(erlang, "glesia_ffi", "start")
fn start_ffi() -> SimpleResult

@external(erlang, "glesia_ffi", "stop")
fn stop_ffi() -> SimpleResult

@external(erlang, "glesia_ffi", "create_table")
fn create_table_ffi(
  table: Atom,
  attributes: List(Atom),
  storage_type: String,
  table_type: String,
) -> TableCreateResult

@external(erlang, "glesia_ffi", "dirty_write")
fn dirty_write_ffi(record: Dynamic) -> SimpleResult

@external(erlang, "glesia_ffi", "dirty_read")
fn dirty_read_ffi(table: Atom, key: Dynamic) -> ReadResult

@external(erlang, "glesia_ffi", "dirty_delete")
fn dirty_delete_ffi(table: Atom, key: Dynamic) -> SimpleResult

@external(erlang, "glesia_ffi", "transaction")
fn transaction_ffi(fun: fn() -> value) -> TransactionResult

pub fn create_schema(nodes: List(Atom)) -> Result(Nil, MnesiaError) {
  case create_schema_ffi(nodes) {
    SchemaOk -> Ok(Nil)
    SchemaError(reason) -> Error(classify(reason))
  }
}

pub fn create_local_schema() -> Result(Nil, MnesiaError) {
  create_schema([node()])
}

pub fn delete_schema(nodes: List(Atom)) -> Result(Nil, MnesiaError) {
  case delete_schema_ffi(nodes) {
    SchemaOk -> Ok(Nil)
    SchemaError(reason) -> Error(classify(reason))
  }
}

pub fn delete_local_schema() -> Result(Nil, MnesiaError) {
  delete_schema([node()])
}

pub fn set_dir(path: String) -> Result(Nil, MnesiaError) {
  case set_dir_ffi(path) {
    SimpleOk -> Ok(Nil)
    SimpleError(reason) -> Error(classify(reason))
  }
}

pub fn start() -> Result(Nil, MnesiaError) {
  case start_ffi() {
    SimpleOk -> Ok(Nil)
    SimpleError(reason) -> Error(classify(reason))
  }
}

pub fn stop() -> Result(Nil, MnesiaError) {
  case stop_ffi() {
    SimpleOk -> Ok(Nil)
    SimpleError(reason) -> Error(classify(reason))
  }
}

pub fn create_table(
  table: Atom,
  attributes: List(Atom),
  storage_type: StorageType,
  table_type: TableType,
) -> Result(Nil, MnesiaError) {
  case
    create_table_ffi(
      table,
      attributes,
      storage_type_to_string(storage_type),
      table_type_to_string(table_type),
    )
  {
    TableCreateOk -> Ok(Nil)
    TableCreateAlreadyExists -> Error(AlreadyExists)
    TableCreateError(reason) -> Error(classify(reason))
  }
}

pub fn create_ram_table(
  table: Atom,
  attributes: List(Atom),
) -> Result(Nil, MnesiaError) {
  create_table(table, attributes, RamCopies, Set)
}

pub fn dirty_write(record: Dynamic) -> Result(Nil, MnesiaError) {
  case dirty_write_ffi(record) {
    SimpleOk -> Ok(Nil)
    SimpleError(reason) -> Error(classify(reason))
  }
}

pub fn dirty_read(
  table: Atom,
  key: Dynamic,
) -> Result(List(Dynamic), MnesiaError) {
  case dirty_read_ffi(table, key) {
    ReadOk(records) -> Ok(records)
    ReadError(reason) -> Error(classify(reason))
  }
}

pub fn dirty_read_decoded(
  table: Atom,
  key: Dynamic,
  decoder: Decoder(value),
) -> Result(List(value), MnesiaError) {
  dirty_read(table, key)
  |> result.try(fn(records) {
    records
    |> list.try_map(fn(record) {
      decode.run(record, decoder)
      |> result.map_error(fn(error) { BadType(string.inspect(error)) })
    })
  })
}

pub fn dirty_delete(table: Atom, key: Dynamic) -> Result(Nil, MnesiaError) {
  case dirty_delete_ffi(table, key) {
    SimpleOk -> Ok(Nil)
    SimpleError(reason) -> Error(classify(reason))
  }
}

pub fn transaction(fun: fn() -> value) -> Result(Dynamic, MnesiaError) {
  case transaction_ffi(fun) {
    TransactionOk(value) -> Ok(value)
    TransactionAbort(reason) -> Error(Abort(string.inspect(reason)))
  }
}

fn storage_type_to_string(storage_type: StorageType) -> String {
  case storage_type {
    RamCopies -> "ram_copies"
    DiscCopies -> "disc_copies"
    DiscOnlyCopies -> "disc_only_copies"
  }
}

fn table_type_to_string(table_type: TableType) -> String {
  case table_type {
    Set -> "set"
    OrderedSet -> "ordered_set"
    Bag -> "bag"
  }
}

fn classify(reason: Dynamic) -> MnesiaError {
  let inspected = string.inspect(reason)

  case inspected {
    "already_exists" -> AlreadyExists
    "not_found" -> NotFound
    "timeout" -> Timeout
    _ -> Unknown(inspected)
  }
}

@external(erlang, "erlang", "node")
fn node() -> Atom
