//IMPORTS GO HERE
const generator = @import("generator.zig");
const SquareType = generator.SquareType;
const Square = generator.Square;
const std = @import("std");
const Accumulator = @import("Accumulator.zig");
const net_file = @embedFile("finalformshuffled.quant");
const simd = @import("sse.zig");

pub fn perft_iter(depth: usize, stdout: anytype) !void {
    const pos = generator.Position.starting_position();
    for (1..(depth + 1)) |val| {
        const count = generator.perft(generator.Color.BLACK, pos, val);
        try stdout.print("Ply {} and number of nodes: {}\n", .{ val, count });
        try stdout.flush();
    }
}

pub fn test_simd() void {
    //will continue with this tomorrow
    //var input: [256]c_int align(32) = undefined;
    //var result: [256]c_char align(32) = undefined;

}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // try perft_iter(13, stdout);

    // const position = generator.Position.starting_position();
    // try position.print_position(stdout);
    // try stdout.flush();

    // var iter = position.square_iterator();

    // const square = iter.next();

    // if (square != null) {
    //     try stdout.print("Square Index {}", .{square.?.index});
    // }
    //

    // const position = generator.Position.starting_position();

    const position = generator.Position.starting_position();
    try position.print_position(stdout);
    try stdout.flush();

    const fen_string = try position.get_fen_string(allocator);
    defer allocator.free(fen_string);

    try stdout.print("{s}\n", .{fen_string});
    try stdout.flush();
}
