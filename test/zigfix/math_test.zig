const math = @import("math.zig");

pub fn add_test() i32 {
    return math.add(2, 3);
}

test "addition" {
    _ = math.add(4, 5);
}
