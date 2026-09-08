const std = @import("std");

pub const Point = struct { x: i32, y: i32 };
pub const Color = enum { red, green };
pub const Value = union(enum) { integer: i32, text: []const u8 };

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

fn increment(value: i32) i32 {
    return add(value, 1);
}

pub fn calculate(value: i32) i32 {
    return add(increment(value), 2);
}

pub fn announce(value: i32) void {
    std.debug.print("value={d}\n", .{value});
}
