-module(glesia_ffi).

-export([
    create_schema/1,
    delete_schema/1,
    set_dir/1,
    start/0,
    stop/0,
    create_table/4,
    dirty_write/1,
    dirty_read/2,
    dirty_delete/2,
    transaction/1
]).

create_schema(Nodes) ->
    case mnesia:create_schema(Nodes) of
        ok -> schema_ok;
        {error, {_, {already_exists, _}}} -> schema_ok;
        {error, {already_exists, _}} -> schema_ok;
        {error, Reason} -> {schema_error, Reason}
    end.

delete_schema(Nodes) ->
    case mnesia:delete_schema(Nodes) of
        ok -> schema_ok;
        {error, {no_exists, _}} -> schema_ok;
        {error, Reason} -> {schema_error, Reason}
    end.

set_dir(Path) when is_binary(Path) ->
    application:set_env(mnesia, dir, binary_to_list(Path)),
    simple_ok.

start() ->
    case mnesia:start() of
        ok -> simple_ok;
        {error, Reason} -> {simple_error, Reason}
    end.

stop() ->
    case mnesia:stop() of
        stopped -> simple_ok;
        ok -> simple_ok;
        {error, Reason} -> {simple_error, Reason};
        Other -> {simple_error, Other}
    end.

create_table(Table, Attributes, StorageTypeBin, TableTypeBin) ->
    StorageType = to_existing_atom(StorageTypeBin),
    TableType = to_existing_atom(TableTypeBin),
    Options = [
        {attributes, Attributes},
        {StorageType, [node()]},
        {type, TableType}
    ],
    case mnesia:create_table(Table, Options) of
        {atomic, ok} -> table_create_ok;
        {aborted, {already_exists, Table}} -> table_create_already_exists;
        {aborted, Reason} -> {table_create_error, Reason}
    end.

dirty_write(Record) ->
    try
        mnesia:dirty_write(Record),
        simple_ok
    catch
        exit:Reason -> {simple_error, Reason};
        error:Reason -> {simple_error, Reason}
    end.

dirty_read(Table, Key) ->
    try
        {read_ok, mnesia:dirty_read(Table, Key)}
    catch
        exit:Reason -> {read_error, Reason};
        error:Reason -> {read_error, Reason}
    end.

dirty_delete(Table, Key) ->
    try
        mnesia:dirty_delete(Table, Key),
        simple_ok
    catch
        exit:Reason -> {simple_error, Reason};
        error:Reason -> {simple_error, Reason}
    end.

transaction(Fun) ->
    case mnesia:transaction(Fun) of
        {atomic, Value} -> {transaction_ok, Value};
        {aborted, Reason} -> {transaction_abort, Reason}
    end.

to_existing_atom(Bin) when is_binary(Bin) ->
    binary_to_existing_atom(Bin, utf8).
