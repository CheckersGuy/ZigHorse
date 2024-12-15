//IMPORTS GO HERE
const generator = @import("generator.zig");

const std = @import("std");
const Simd = @cImport(@cInclude("NetworkHelper.h"));
const Accumulator = @import("Accumulator.zig");
const net_file = @embedFile("finalformshuffled.quant");

pub fn perft(comptime color: generator.Color, pos: generator.Position, depth: usize) usize {
    var counter: usize = 0;
    var liste: generator.MoveListe(40) = .{};
    generator.get_moves(40, pos, &liste);
    if (depth == 1) {
        return liste.length;
    }
    var index: usize = 0;
    while (index < liste.length) : (index += 1) {
        var my_copy = pos;
        my_copy.make_move_color(color, liste.liste[index]);
        counter += perft(@enumFromInt(-@intFromEnum(color)), my_copy, depth - 1);
    }
    return counter;
}

pub fn perft_iter(depth: usize, stdout: anytype) !void {
    for (1..(depth + 1)) |val| {
        const pos = generator.Position.starting_position();
        const count = perft(generator.Color.BLACK, pos, val);
        try stdout.print("Ply {} and number of nodes: {}\n", .{ val, count });
    }
}

pub fn test_simd() void {
    //will continue with this tomorrow
    var input: [256]c_int align(32) = undefined;
    var result: [256]c_char align(32) = undefined;

    for (&input, 0..) |*value, index| {
        value.* = @intCast(index);
        std.debug.print("Value {any}\n", .{input[index]});
    }

    //Simd.accum_activation8_256(@ptrCast(&input), @ptrCast(&result));
    Simd.clipped8_256(@ptrCast(&input), @ptrCast(&result));

    for (result, 0..) |value, index| {
        const test_value: u8 = @bitCast(value);
        std.debug.print("Value at index {any} is {any}\n", .{ index, test_value });
    }
}

pub fn main() !void {
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

    accumulator.apply(generator.Color.BLACK, before_position, after_position);
}
