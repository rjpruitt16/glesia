import gleam/dynamic
import gleam/erlang/atom
import gleam/list
import gleam/string
import gleeunit
import glesia

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn dirty_write_and_read_test() {
  let table = atom.create_from_string("glesia_test_user")
  let id = dynamic.from(1)
  let record = dynamic.from(#(table, 1, "Rahmi"))

  let _ = glesia.stop()
  let assert Ok(_) = glesia.set_dir("/tmp/glesia_test_mnesia")
  let _ = glesia.delete_local_schema()
  let assert Ok(_) = glesia.create_local_schema()
  let assert Ok(_) = glesia.start()
  case
    glesia.create_ram_table(table, [
      atom.create_from_string("id"),
      atom.create_from_string("name"),
    ])
  {
    Ok(_) -> Nil
    Error(glesia.AlreadyExists) -> Nil
    Error(error) ->
      panic as { "table create failed: " <> string.inspect(error) }
  }

  let assert Ok(_) = glesia.dirty_write(record)
  let assert Ok(records) = glesia.dirty_read(table, id)
  assert list.length(records) == 1

  let assert Ok(_) = glesia.dirty_delete(table, id)
  let assert Ok([]) = glesia.dirty_read(table, id)
  let _ = glesia.stop()
}
