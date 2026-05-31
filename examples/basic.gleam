import gleam/dynamic
import gleam/erlang/atom
import gleam/int
import gleam/io
import gleam/list
import glesia

pub fn main() -> Nil {
  let users = atom.create("users")

  let _ = glesia.create_local_schema()
  let assert Ok(_) = glesia.start()
  let _ =
    glesia.create_ram_table(users, [
      atom.create("id"),
      atom.create("name"),
    ])

  let assert Ok(_) = glesia.dirty_write(dynamic.from(#(users, 1, "Ada")))
  let assert Ok(records) = glesia.dirty_read(users, dynamic.from(1))

  io.println("records found: " <> int.to_string(list.length(records)))
  let _ = glesia.stop()
}
