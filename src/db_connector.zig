const std = @import("std");
const teste_conn_string = "host=/run/postgresql dbname=teste user=pedro password=123456";

const c = @cImport({
    @cInclude("libpq-fe.h");
});

pub const db_conn_config = struct {
    alloc: std.mem.Allocator,
    conn_string: []const u8,
};

pub const db_connection = struct {
    conn: *c.pg_conn,

    pub fn init(config: db_conn_config) !db_connection {
        const conn = c.PQconnectdb(@ptrCast(config.conn_string));
        if (c.PQstatus(conn) != c.CONNECTION_OK) {
            return error.ConnectionError;
        }
        return db_connection{ .conn = conn.? };
    }

    pub fn deinit(self: *db_connection) void {
        c.PQfinish(self.conn);
    }

    pub fn raw_query(self: *db_connection, query: []const u8) ![*c]u8 {
        const result = c.PQexec(self.conn, @ptrCast(query));
        defer c.PQclear(result);

        if (c.PQresultStatus(result) != c.PGRES_TUPLES_OK) {
            std.debug.print("exec query failed, query:{s}, err: {s}\n", .{ query, c.PQerrorMessage(self.conn) });
            return error.queryTable;
        }
        const return_value = c.PQgetvalue(result, 0, 0);
        return return_value;
    }
};
