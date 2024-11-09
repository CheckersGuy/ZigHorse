//here goes the entire search
//

const pos = @import("generator.zig");
const std = @import("std");
const allocator = std.heap.page_allocator;
const MAX_PLY: comptime_int = 128;

const StackItem = struct {
    ply: i32,
    position: pos.Position,
    move: pos.Move,

    //pub fn make_move(self : * StackItem, move : pos.Move, previous : pos.Position) void{
    //to be implemented
    //}
};

pub fn search(_: i32, _: pos.Position) i32 {
    const search_stack = allocator.alloc(StackItem, MAX_PLY);
    defer allocator.free(search_stack);
    //basic iterative deepening
}

pub fn searchValue(depth: i32, _: i32, _: i32, ss: *StackItem) i32 {
    //some basic search

    //handling timeouts
    if (depth == 0) {
        //returning the eval for now
        return 0;
    }

    var move_list: pos.MoveListe(40) = .{};
    pos.get_moves(40, ss.position, &move_list);

    var index = 0;

    while (index < move_list.length) : (index = index + 1) {}
}
