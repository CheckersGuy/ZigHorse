//IMPORTS etc

const std = @import("std");

//movegenerator for checkers

pub const MASK_L3: u32 = 14737632;
pub const MASK_L5: u32 = 117901063;
pub const MASK_R3: u32 = 117901056;
pub const MASK_R5: u32 = 3772834016;
const PROMO_SQUARES_WHITE: u32 = 0xf;
const PROMO_SQUARES_BLACK: u32 = 0xf0000000;

pub const SquareType = enum {
    WHITE_PAWN,
    BLACK_PAWN,
    WHITE_KING,
    BLACK_KING,
    INVALID,
};

pub const Square = struct {
    const Self = @This();
    type: SquareType,
    index: usize,

    pub fn to_string(self: *const Self, fmt_buffer: []u8) ![]const u8 {
        return std.fmt.bufPrint(fmt_buffer, "({s}, {d})", .{ @tagName(self.type), self.index });
    }
};

pub const PieceType = enum {
    PAWN,
    KING,
    BPAWN,
    BKING,
    WPAWN,
    WKING,
};

const MoveType = enum { PawnMove, KingMove, PromoMove, KingCapture, PawnCapture, PromoCapture };

pub const Color = enum(i32) {
    BLACK = -1,
    WHITE = 1,

    pub fn to_string(self: Color) []const u8 {
        if (self == Color.BLACK)
            return "BLACK";

        return "WHITE";
    }
};

fn defaultShift(comptime color: Color, maske: u32) u32 {
    if (comptime color == Color.BLACK) {
        return maske << 4;
    } else {
        return maske >> 4;
    }
}

fn forwardMask(comptime color: Color, maske: u32) u32 {
    if (comptime color == Color.BLACK) {
        return ((maske & MASK_L3) << 3) | ((maske & MASK_L5) << 5);
    } else {
        return ((maske & MASK_R3) >> 3) | ((maske & MASK_R5) >> 5);
    }
}

fn get_neighbour_squares(comptime color: Color, comptime piece: PieceType, maske: u32) u32 {
    if (piece == PieceType.KING) {
        const squares = defaultShift(color, maske) | forwardMask(color, maske) | forwardMask(@enumFromInt(-@intFromEnum(color)), maske) | defaultShift(@enumFromInt(-@intFromEnum(color)), maske);
        return squares;
    } else {
        return defaultShift(color, maske) | forwardMask(color, maske);
    }
}

pub const Move = struct {
    from: u32,
    to: u32,
    captures: u32,

    fn is_king_move(self: Move, kings: u32) bool {
        return (self.from & kings) != 0;
    }

    fn is_pawn_move(self: Move, kings: u32) bool {
        return !self.is_king_move(kings);
    }

    fn get_from_index(self: Move) u32 {
        return @ctz(self.from);
    }

    fn get_to_index(self: Move) u32 {
        return @ctz(self.to);
    }
};

pub fn MoveListe(size: comptime_int) type {
    return struct {
        liste: [size]Move = undefined,
        length: usize = 0,

        inline fn append(self: *MoveListe(size), move: Move) void {
            self.liste[self.length] = move;
            self.length += 1;
        }

        inline fn shift_right(self: *MoveListe(size)) void {
            var i: i32 = size - 1;
            while (i >= 0) : (i = i - 1) {
                self.liste[i + 1] = self.liste[i];
            }
        }

        inline fn push_front(self: *MoveListe(size), move: Move) void {
            self.shift_right();
            self.liste[0] = move;
        }
    };
}

fn get_mirrored(b: u32) u32 {
    return @bitReverse(b);
}

pub const Position = struct {
    bp: u32,
    wp: u32,
    k: u32,
    color: Color = Color.BLACK,

    const Self = @This();

    const SquareIterator = struct {
        pos: Position,
        pieces: u32,

        pub fn next(self: *SquareIterator) ?Square {
            if (self.pieces == 0) {
                return null;
            }
            const index: u5 = @intCast(@ctz(self.pieces));
            const type_index =
                1 * @as(u32, @intFromBool(((self.pos.wp & @shlExact(@as(u32, 1), index) & (self.pos.k)) != 0))) +
                2 * @as(u32, @intFromBool(((self.pos.bp & @shlExact(@as(u32, 1), index) & (self.pos.k)) != 0))) +
                4 * @as(u32, @intFromBool(((self.pos.wp & @shlExact(@as(u32, 1), index) & (~self.pos.k)) != 0))) +
                8 * @as(u32, @intFromBool(((self.pos.bp & @shlExact(@as(u32, 1), index) & (~self.pos.k)) != 0)));

            const square_type = switch (type_index) {
                1 => SquareType.WHITE_KING,
                2 => SquareType.BLACK_KING,
                4 => SquareType.WHITE_PAWN,
                8 => SquareType.BLACK_PAWN,
                else => SquareType.INVALID,
            };

            self.pieces &= self.pieces - 1;
            return Square{ .index = index, .type = square_type };
        }
    };

    pub fn square_iterator(self: *const Self) SquareIterator {
        return .{ .pos = self.*, .pieces = self.bp | self.wp };
    }

    pub fn new() Position {
        return .{ .bp = 0, .wp = 0, .k = 0, .color = Color.BLACK };
    }

    pub fn color_flip(self: Self) Position {
        return .{ .color = if (self.color == Color.BLACK) Color.WHITE else Color.BLACK, .bp = @bitReverse(self.bp), .wp = @bitReverse(self.wp), .k = @bitReverse(self.k) };
    }

    pub fn perspective(self: Self) Self {
        if (self.color == Color.BLACK) {
            return self.color_flip();
        }
        return self;
    }

    pub fn starting_position() Position {
        var pos: Position = .{ .wp = 0, .bp = 0, .k = 0, .color = Color.BLACK };

        for (0..12) |i| {
            pos.bp |= std.math.shl(u32, 1, i);
        }
        for (20..32) |i| {
            pos.wp |= std.math.shl(u32, 1, i);
        }
        return pos;
    }

    pub fn get_current(self: Position, comptime color: Color) u32 {
        if (color == Color.BLACK)
            return self.bp;

        return self.wp;
    }

    pub fn get_movers(self: Position, comptime color: Color) u32 {
        const nocc: u32 = ~(self.bp | self.wp);
        const current: u32 = self.get_current(color);
        const kings: u32 = current & self.k;

        var movers: u32 =
            (defaultShift(@enumFromInt(-@intFromEnum(color)), nocc) | forwardMask(@enumFromInt(-@intFromEnum(color)), nocc)) & current;
        if (kings != 0) {
            movers |= (defaultShift(color, nocc) | forwardMask(color, nocc)) & kings;
        }
        return movers;
    }

    pub fn get_jumpers(self: Position, comptime color: Color) u32 {
        const nocc = ~(self.bp | self.wp);
        const current = self.get_current(color);
        const opp = self.get_current(@enumFromInt(-@intFromEnum(color)));
        const kings = current & self.k;

        var movers: u32 = 0;
        var temp = defaultShift(@enumFromInt(-@intFromEnum(color)), nocc) & opp;
        if (temp != 0) {
            movers |= forwardMask(@enumFromInt(-@intFromEnum(color)), temp) & current;
        }
        temp = forwardMask(@enumFromInt(-@intFromEnum(color)), nocc) & opp;
        if (temp != 0) {
            movers |= defaultShift(@enumFromInt(-@intFromEnum(color)), temp) & current;
        }
        if (kings != 0) {
            temp = defaultShift(color, nocc) & opp;
            if (temp != 0) {
                movers |= forwardMask(color, temp) & kings;
            }
            temp = forwardMask(color, nocc) & opp;

            if (temp != 0) {
                movers |= defaultShift(color, temp) & kings;
            }
        }
        return movers;
    }

    pub fn has_jumps(self: Position, comptime color: Color) bool {
        return (self.get_jumpers(color) != 0);
    }

    pub fn make_move_color(self: *Position, comptime color: Color, move: Move) void {
        if (color == Color.BLACK) {
            if (move.captures != 0) {
                self.wp &= ~move.captures;
                self.k &= ~move.captures;
            }
            self.bp &= ~move.from;
            self.bp |= move.to;

            if (((move.to & PROMO_SQUARES_BLACK) != 0) and ((move.from & self.k) == 0))
                self.k |= move.to;
        } else {
            if (move.captures != 0) {
                self.bp &= ~move.captures;
                self.k &= ~move.captures;
            }
            self.wp &= ~move.from;
            self.wp |= move.to;

            if (((move.to & PROMO_SQUARES_WHITE) != 0) and ((move.from & self.k) == 0))
                self.k |= move.to;
        }
        if ((move.from & self.k) != 0) {
            self.k &= ~move.from;
            self.k |= move.to;
        }
        self.color = @enumFromInt(-@intFromEnum(self.color));
    }

    pub fn make_move(self: *Position, move: Move) void {
        if (self.color == Color.BLACK) {
            self.make_move_color(Color.BLACK, move);
        } else {
            self.make_move_color(Color.WHITE, move);
        }
    }

    pub fn get_fen_string2(self: Self, allocator: std.mem.Allocator) ![]u8 {
        var list: std.ArrayList(u8) = .empty;
        try list.appendSlice(allocator, if (self.color == Color.BLACK) "B:" else "W:", allocator);
        const positions: [2]Self = .{ .{ .wp = self.wp, .k = self.k & self.wp, .bp = 0 }, .{ .wp = 0, .k = self.k & self.bp, .bp = self.bp } };
        for (0..2) |index| {
            var it = positions[index].square_iterator();
            try list.appendSlice(allocator, if (index == 0) ":W" else "B:");
            while (it.next()) |square| {
                if (square.type == .BLACK_KING or square.type == .WHITE_KING) {
                    try list.append(allocator, 'K');
                }
                const square_string = std.fmt.allocPrint(allocator, "{d}, ", .{square.index});
                defer allocator.free(square_string);
                try list.appendSlice(allocator, square_string);
            }
        }
        try list.pop();
        try list.pop();
        return list.toOwnedSlice(allocator);
    }

    pub fn print_position(self: Position, writer: anytype) !void {
        try writer.print("Color: {s}\n", .{self.color.to_string()});
        for (0..8) |row| {
            for (0..4) |col| {
                const rev_row = 7 - row;
                const rev_col = 3 - col;
                const bit_index = 4 * rev_row + rev_col;
                const maske: u32 = std.math.shl(u32, 1, bit_index);

                if (rev_row % 2 == 1) {
                    try writer.print("[ ]", .{});
                }

                if (((self.bp & self.k) & maske) == maske) {
                    try writer.print("[B]", .{});
                } else if (((self.bp) & maske) == maske) {
                    try writer.print("[O]", .{});
                } else if (((self.wp & self.k) & maske) == maske) {
                    try writer.print("[W]", .{});
                } else if (((self.wp) & maske) == maske) {
                    try writer.print("[X]", .{});
                } else {
                    try writer.print("[ ]", .{});
                }

                if (rev_row % 2 == 0) {
                    try writer.print("[ ]", .{});
                }
            }
            try writer.print("\n", .{});
        }
    }

    fn get_fen_string(pos: Position, buffer: []u8) []u8 {
        const pieces = [_]u32{ pos.wp, pos.bp };
        var length: usize = 0;
        buffer[length] = if (pos.color == Color.BLACK) 'B' else 'W';
        length += 1;
        for (pieces, 0..) |piece, index| {
            if (piece != 0) {
                buffer[length] = ':';
                buffer[length + 1] = if (index == 0) 'W' else 'B';
                length += 2;
            }
            var current = piece;
            while (current != 0) {
                const square: u32 = @ctz(current);
                const mask: u32 = std.math.shl(u32, 1, square);
                if ((mask & pos.k) != 0) {
                    buffer[length] = 'K';
                    length += 1;
                }
                const first = (square + 1) / 10;
                if (first != 0) {
                    buffer[length] = @intCast(48 + first);
                    length += 1;
                }

                const second = (square + 1) % 10;
                buffer[length] = @intCast(48 + second);
                length += 1;

                if ((current & (~mask)) != 0) {
                    buffer[length] = ',';
                    length += 1;
                }
                current &= current - 1;
            }
        }

        return buffer[0..length];
    }

    pub fn pos_from_fen(fen_string: []const u8) !Position {
        var it = std.mem.splitScalar(u8, fen_string, ':');
        var position = Position.new();
        const pieces = [_]*u32{ &position.wp, &position.bp };
        while (it.next()) |value| {
            if (std.mem.eql(u8, "B", value)) {
                position.color = Color.BLACK;
            } else if (std.mem.eql(u8, "W", value)) {
                position.color = Color.WHITE;
            } else if (std.mem.startsWith(u8, value, "W") or std.mem.startsWith(u8, value, "B")) {
                const c_ind: usize = if (value[0] == 'W') 0 else 1;
                var squares = std.mem.tokenizeAny(u8, value[1..], &[_]u8{ ',', ' ' });
                while (squares.next()) |square| {
                    const has_king: usize = @intFromBool(std.mem.startsWith(u8, square, &[_]u8{'K'}));
                    const sq_index = try std.fmt.parseUnsigned(u32, square[has_king..], 10);
                    const bit_mask = std.math.shl(u32, 1, sq_index - 1);
                    if (has_king != 0) {
                        position.k |= bit_mask;
                    }
                    pieces[c_ind].* = pieces[c_ind].* | bit_mask;
                }
            }
        }

        return position;
    }
};

pub fn get_silent_moves(size: comptime_int, comptime color: Color, pos: Position, liste: *MoveListe(size)) void {
    var pawn_movers = pos.get_movers(color) & (~pos.k);
    var king_movers = pos.get_movers(color) & pos.k;

    const nocc = ~(pos.bp | pos.wp);
    while (king_movers != 0) {
        const maske = king_movers & ~(king_movers - 1);
        var squares = get_neighbour_squares(color, PieceType.KING, maske);
        squares &= nocc;
        while (squares != 0) {
            const next = squares & ~(squares - 1);
            liste.*.append(.{ .from = maske, .to = next, .captures = 0 });
            squares &= squares - 1;
        }
        king_movers &= ~maske;
    }

    while (pawn_movers != 0) {
        const maske = pawn_movers & ~(pawn_movers - 1);
        var squares = get_neighbour_squares(color, PieceType.PAWN, maske);
        squares &= nocc;
        while (squares != 0) {
            const next = squares & ~(squares - 1);
            liste.*.append(.{ .from = maske, .to = next, .captures = 0 });
            squares &= squares - 1;
        }
        pawn_movers &= ~maske;
    }
}

fn add_capture(size: comptime_int, comptime color: Color, comptime piece: MoveType, pos: Position, orig: u32, current: u32, captures: u32, liste: *MoveListe(size)) void {
    const opp_color: Color = @enumFromInt(-@intFromEnum(color));
    const opp = pos.get_current(opp_color) ^ captures;
    const nocc = (~(opp | pos.get_current(color))) | orig;
    const temp0 = defaultShift(color, current) & opp;
    const temp1 = forwardMask(color, current) & opp;
    const dest0 = forwardMask(color, temp0) & nocc;
    const dest1 = defaultShift(color, temp1) & nocc;

    var imed = (forwardMask(opp_color, dest0) | defaultShift(opp_color, dest1));
    var dest = dest0 | dest1;
    if (piece == MoveType.KingCapture) {
        const temp2 = defaultShift(opp_color, current) & opp;
        const temp3 = forwardMask(opp_color, current) & opp;
        const dest2 = forwardMask(opp_color, temp2) & nocc;
        const dest3 = defaultShift(opp_color, temp3) & nocc;
        imed |= forwardMask(color, dest2) | defaultShift(color, dest3);
        dest |= dest2 | dest3;
    }
    if (dest == 0) {
        liste.append(.{ .from = orig, .to = current, .captures = captures });
        return;
    }
    while (dest != 0) {
        const destMask = dest & ~(dest - 1);
        const capMask = imed & ~(imed - 1);
        add_capture(size, color, piece, pos, orig, destMask, (captures | capMask), liste);
        dest &= dest - 1;
        imed &= imed - 1;
    }
}

fn loop_captures(size: comptime_int, comptime color: Color, pos: Position, liste: *MoveListe(size)) void {
    const movers = pos.get_jumpers(color);
    var king_jumpers = movers & pos.k;
    var pawn_jumpers = movers & (~pos.k);
    while (king_jumpers != 0) {
        const maske = king_jumpers & ~(king_jumpers - 1);
        add_capture(size, color, MoveType.KingCapture, pos, maske, maske, 0, liste);
        king_jumpers &= king_jumpers - 1;
    }

    while (pawn_jumpers != 0) {
        const maske = pawn_jumpers & ~(pawn_jumpers - 1);
        add_capture(size, color, MoveType.PawnCapture, pos, maske, maske, 0, liste);
        pawn_jumpers &= pawn_jumpers - 1;
    }
}
pub fn get_moves(size: comptime_int, pos: Position, liste: *MoveListe(size)) void {
    if (pos.color == Color.BLACK) {
        if (pos.has_jumps(Color.BLACK)) {
            loop_captures(size, Color.BLACK, pos, liste);
        } else {
            get_silent_moves(size, Color.BLACK, pos, liste);
        }
    } else {
        if (pos.has_jumps(Color.WHITE)) {
            loop_captures(size, Color.WHITE, pos, liste);
        } else {
            get_silent_moves(size, Color.WHITE, pos, liste);
        }
    }
}

pub fn get_captures(size: comptime_int, pos: Position, liste: *MoveListe(size)) void {
    liste.length = 0;
    if (pos.color == Color.BLACK) {
        loop_captures(size, Color.BLACK, pos, liste);
    } else {
        loop_captures(size, Color.WHITE, pos, liste);
    }
}

pub fn perft(comptime color: Color, pos: Position, depth: usize) usize {
    var counter: usize = 0;
    var liste: MoveListe(40) = .{};
    get_moves(40, pos, &liste);
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

test "perft-check" {
    const depth = 10;
    const pos = Position.starting_position();
    var liste: std.ArrayList(usize) = .empty;
    defer liste.deinit(std.testing.allocator);
    for (1..(depth + 1)) |val| {
        const count = perft(Color.BLACK, pos, val);
        try liste.append(std.testing.allocator, count);
    }

    try std.testing.expectEqualSlices(usize, &[_]usize{ 7, 49, 302, 1469, 7361, 36768, 179740, 845931, 3963680, 18391564 }, liste.items);
}

test "square_iterator" {

    //just a very small test to see
    // if we can extract the square given below
    const position: Position = .{ .bp = (1 << 30) | (1 << 20), .wp = (1 << 10) | (1 << 15) | (1 << 7), .k = (1 << 7), .color = Color.BLACK };

    var it = position.square_iterator();
    var squares: std.ArrayList(Square) = .empty;
    defer squares.deinit(std.testing.allocator);
    while (it.next()) |square| {
        try squares.append(std.testing.allocator, square);
    }

    try std.testing.expectEqualSlices(Square, squares.items, &[_]Square{ Square{ .type = .WHITE_KING, .index = 7 }, Square{ .index = 10, .type = .WHITE_PAWN }, Square{ .index = 15, .type = .WHITE_PAWN }, Square{ .index = 20, .type = .BLACK_PAWN }, Square{ .index = 30, .type = .BLACK_PAWN } });
}
