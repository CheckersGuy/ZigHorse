const std = @import("std");
const generator = @import("generator.zig");
const Position = generator.Position;
const Color = generator.Color;
pub fn Accumulator(out_dim: comptime_int) type {
    return struct {
        const Self = @This();
        const num_weights: comptime_int = 120 * out_dim;
        const num_biases: comptime_int = out_dim;
        black_acc: [out_dim]i16 align(64) = [_]i16{0} ** out_dim,
        white_acc: [out_dim]i16 align(64) = [_]i16{0} ** out_dim,
        ft_weights: []i16,
        ft_biases: []i16,
        removed_features: [32]i32 = [_]i32{0} ** 32,
        added_features: [32]i32 = [_]i32{0} ** 32,
        previous_black: Position = Position.new(),
        previous_white: Position = Position.new(),

        pub fn new(allocator: std.mem.Allocator) !Self {
            return .{
                .ft_weights = try allocator.alignedAlloc(i16, 64, num_weights),
                .ft_biases = try allocator.alignedAlloc(i16, 64, num_biases),
            };
        }

        pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
            allocator.free(self.ft_weights);
            allocator.free(self.ft_biases);
        }

        pub fn load(self: *Self, file_pointer: [*]const u8) [*]const u8 {
            const params: [*]const i16 = @ptrCast(@alignCast(file_pointer));
            const weights = params[0..num_weights];
            const biases = params[num_weights..(num_weights + num_biases)];
            std.mem.copyForwards(i16, self.ft_weights, weights);
            std.mem.copyForwards(i16, self.ft_biases, biases);
            std.mem.copyForwards(i16, &self.black_acc, biases);
            std.mem.copyForwards(i16, &self.white_acc, biases);
            return file_pointer + (@sizeOf(i16) * num_biases + @sizeOf(i16) * num_weights);
        }

        pub fn update(_: Color, _: Position) void {}

        pub fn apply(self: *Self, _: Color, before: Position, after: Position) !void {
            var added = [_]u32{ after.wp & (~before.wp) & (~after.k), after.bp & (~before.bp) & (~after.k), after.wp & (~before.wp) & after.k, after.bp & (~before.bp) & after.k };
            var removed = [_]u32{ before.wp & (~after.wp) & (~before.k), before.bp & (~after.bp) & (~before.k), before.wp & (~after.wp) & before.k, before.bp & (~after.bp) & before.k };
            const offsets = [_]i32{ -4, 28, 28 + 28, 28 + 28 + 32 };
            // var input = if (perp == Color.BLACK) self.black_acc else self.white_acc;
            var num_removed: usize = 0;
            var num_active: usize = 0;
            const stdout = std.io.getStdOut().writer();
            inline for ([_]*const [4]u32{ &added, &removed }, 0..) |features, p| {
                for (features, 0..) |*feature, index| {
                    const offset = offsets[index];
                    var pieces: u32 = feature.*;
                    while (pieces != 0) {
                        const ind: i32 = @ctz(pieces) + offset;
                        //try stdout.print("{}:{}\n", .{ ind, @ctz(pieces) });
                        //std.debug.print("{any}\n", .{num_active});
                        if (comptime p == 0) {
                            self.added_features[num_active] = @intCast(ind);
                            num_active += 1;
                        } else {
                            self.removed_features[num_removed] = @intCast(ind);
                            num_removed += 1;
                        }
                        pieces &= pieces - 1;
                    }
                }
            }
            //Simd.accum_forward_8192(@ptrCast(&input), @ptrCast(&self.ft_weights), @ptrCast(&self.added_features), @ptrCast(&self.removed_features), @intCast(num_active), @intCast(num_removed));
            try stdout.print("", .{});
        }
    };
}
