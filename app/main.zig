const std = @import("std");
const stdout = std.io.getStdOut().writer();
const allocator = std.heap.page_allocator;

const DecodeResult = union(enum) {
    str: *const []const u8,
    int: *const i64,
};

pub fn main() !void {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        try stdout.print("Usage: your_bittorrent.zig <command> <args>\n", .{});
        std.os.exit(1);
    }

    const command = args[1];

    if (std.mem.eql(u8, command, "decode")) {
        const encodedStr = args[2];
        const decoded = decodeBencode(encodedStr) catch {
            try stdout.print("Invalid encoded value\n", .{});
            std.os.exit(1);
        };
        var string = std.ArrayList(u8).init(allocator);
        defer string.deinit();
        switch (decoded) {
            .str => |value| try std.json.stringify(value.*, .{}, string.writer()),
            .int => |value| try std.json.stringify(value.*, .{}, string.writer()),
        }
        const jsonStr = try string.toOwnedSlice();
        try stdout.print("{s}\n", .{jsonStr});
    }
}

fn decodeBencode(encodedValue: []const u8) !DecodeResult {
    if (encodedValue[0] >= '0' and encodedValue[0] <= '9') {
        const firstColon = std.mem.indexOf(u8, encodedValue, ":");
        if (firstColon == null) {
            return error.InvalidArgument;
        }
        return DecodeResult{ .str = &encodedValue[firstColon.? + 1 ..] };
    } else if (encodedValue[0] == 'i' and encodedValue[encodedValue.len - 1] == 'e') {
        var intStr = encodedValue[1 .. encodedValue.len - 1];
        var maybeInt = std.fmt.parseInt(i64, intStr, 10);
        if (maybeInt) |value| {
            return DecodeResult{ .int = &value };
        } else |_| {
            return error.InvalidArgument;
        }
    } else {
        try stdout.print("Only strings and integers are supported at the moment\n", .{});
        std.os.exit(1);
    }
}
