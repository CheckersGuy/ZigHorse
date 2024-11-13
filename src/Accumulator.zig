const std = @import("std");
const generator = @import("generator.zig");
const Position = generator.Position;
const Color = generator.Color;

pub fn Accumulator(out_dim: comptime_int) type {
    return struct {
        black_acc: [out_dim]i32 align(64),
        white_acc: [out_dim]i32 align(64),
        removed_features: [32]u16,
        added_features: [32]u16,
        previous_black: Position,
        previous_white: Position,

        pub fn update(_: Color, _: Position) void {}
    };
}
