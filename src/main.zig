//IMPORTS GO HERE
const generator = @import("generator.zig");

const std = @import("std");
const print = std.debug.print;
const allocator = std.heap.page_allocator;
const Simd = @cImport(@cInclude("bindings.h"));

const stdout_file = std.io.getStdOut().writer();
var buf_reader = std.io.bufferedWriter(stdout_file);
const stdout = buf_reader.writer();

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

pub fn perft_iter(depth: usize) !void {
    for (1..(depth + 1)) |val| {
        const pos = generator.Position.starting_position();
        const count = perft(generator.Color.BLACK, pos, val);
        try stdout.print("Ply {} and number of nodes: {}\n", .{ val, count });
        try buf_reader.flush();
    }
}

pub fn main() !void {
    //will continue with this tomorrow 
    var input: [256]c_int align(32) = undefined;
    var input2: [256]c_int align(32) = undefined;
    //var result: [256]c_int align(32) = undefined;

    for (&input, 0..) |*value, index| {
        value.* = @intCast(index);
        std.debug.print("Index: {any}\n", .{input[index]});
    }
    for (&input2, 0..) |*value, index| {
        value.* = @intCast(index);
    }
    Simd.testing_simd() 
    //const c_pointer: [*c]c_int = @ptrCast(&array);
}
//use splitSequence and possibly tokenizeAny for there reverse function

test "testingPosition" {
    //std.debug.print("Something {?}", .{value});

    //testing out simd stuff

    var input: [256]i16 align(32) = undefined;
    var output: [256]u8 align(32) = undefined;

    for (&input, 0..) |*value, i| {
        value.* = @intCast(i);
    }
    Simd.accum_activation8_256(@as([*c]i16, @ptrCast(&input)), @as([*c]u8, @ptrCast(&output)));
}
