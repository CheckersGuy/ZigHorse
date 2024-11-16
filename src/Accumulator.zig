const std = @import("std");
const generator = @import("generator.zig");
const Position = generator.Position;
const Color = generator.Color;

pub fn Accumulator(out_dim: comptime_int) type {
    return struct {
        const Self = @This();
        black_acc: [out_dim]i32 align(64) = undefined,
        white_acc: [out_dim]i32 align(64) = undefined,
        ft_weights: []const i16,
        ft_biases: []const i16,
        removed_features: [32]u16 = [_]u16{0} ** 32,
        added_features: [32]u16 = [_]u16{0} ** 32,
        previous_black: Position = Position.new(),
        previous_white: Position = Position.new(),

        pub fn new(allocator: std.mem.Allocator) !Self {
            const num_weights = 120 * out_dim;
            const num_biases = out_dim;
            return .{
                .ft_weights = try allocator.alignedAlloc(i16, 64, num_weights),
                .ft_biases = try allocator.alignedAlloc(i16, 64, num_biases),
            };
        }

        pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
            allocator.free(self.ft_weights);
            allocator.free(self.ft_biases);
        }

        pub fn update(_: Color, _: Position) void {}

        pub fn load(self: *Self, file_pointer: *const u8) *const u8 {
            const num_weights = 120 * out_dim;
            const num_biases = out_dim;
            const params: [*]const i16 = @ptrCast(@alignCast(file_pointer));
            const weights = params[0..num_weights];
            const biases = params[num_weights..(num_weights + num_biases)];
            std.mem.copyForwards(i16, self.ft_weights, weights);
            std.mem.copyForwards(i16, self.ft_biases, biases);
            return file_pointer + (@sizeOf(i16) * num_biases + @sizeOf(i16) * num_weights);
        }
    };
}
