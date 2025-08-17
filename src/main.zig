//IMPORTS GO HERE
const generator = @import("generator.zig");

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
    // const stdout = std.io.getStdOut().writer();
    // try perft_iter(13, stdout);
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // try stdout.print("Das ist noch ein kleienr Test\n", .{});
    // try stdout.flush();

    try perft_iter(13, stdout);
}

test "perft-check" {
    const depth = 10;
    const pos = generator.Position.starting_position();
    var liste: std.ArrayList(usize) = .empty;
    defer liste.deinit(std.testing.allocator);
    for (1..(depth + 1)) |val| {
        const count = generator.perft(generator.Color.BLACK, pos, val);
        try liste.append(std.testing.allocator, count);
    }

    try std.testing.expectEqualSlices(usize, &[_]usize{ 7, 49, 302, 1469, 7361, 36768, 179740, 845931, 3963680, 18391564 }, liste.items);
}

pub fn main_testing() !void {
    const stdout = std.io.getStdOut().writer();
    //to be continued
    // var buf: [132]u8 = undefined;
    //var reader = std.io.fixedBufferStream((net_file.*)[0..]).reader();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var accumulator = try Accumulator.Accumulator(2 * 4096).new(allocator);
    defer accumulator.deinit(allocator);
    _ = accumulator.load(net_file);
    try stdout.print("Number of weights {} and biases {}\n", .{ accumulator.ft_weights.len, accumulator.ft_biases.len });

    //for (accumulator.ft_biases) |value| {
    //   try stdout.print("{any}\n", .{value});
    //}

    const after_position = generator.Position.starting_position();
    const before_position = generator.Position.new();

    try after_position.print_position(stdout);

    try accumulator.apply(generator.Color.BLACK, before_position, after_position);
}
