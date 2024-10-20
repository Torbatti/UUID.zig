const std = @import("std");
const assert = std.debug.assert;

pub const Error = error{InvalidUUID};
pub const STRING_LENGTH = 36;

// Empty uuid - NIL calls a function / ZERO is already set
pub const NIL = fromInt(0); // Nil UUID with all bits set to zero.
pub const ZERO: Uuid = .{ .bytes = .{0} ** 16 }; // Zero UUID

const Uuid = @This();

bytes: [16]u8,

/// Returns a UUID from a u128-bit integer.
pub fn fromInt(int: u128) Uuid {
    var uuid: Uuid = undefined;
    std.mem.writeInt(u128, uuid.bytes[0..], int, .big);

    return uuid;
}

test "fromInt" {
    try std.testing.expectEqual([1]u8{0x0} ** 16, ZERO.bytes);
    try std.testing.expectEqual([1]u8{0x0} ** 16, NIL.bytes);
    try std.testing.expectEqual(ZERO.bytes, NIL.bytes);
}

/// UUID variant or family.
pub const Variant = enum(u2) {
    /// Legacy Apollo Network Computing System UUIDs.
    ncs = 0,
    /// RFC 4122/DCE 1.1 UUIDs, or "Leach–Salz" UUIDs.
    rfc4122 = 1,
    /// Backwards-compatible Microsoft COM/DCOM UUIDs.
    microsoft = 2,
    /// Reserved for future definition UUIDs.
    future = 3,
};

/// Returns the UUID variant.
pub fn getVariant(self: Uuid) Variant {
    const byte = self.bytes[8];
    if (byte >> 7 == 0b0) {
        return .ncs;
    } else if (byte >> 6 == 0b10) {
        return .rfc4122;
    } else if (byte >> 5 == 0b110) {
        return .microsoft;
    } else {
        return .future;
    }
}

/// Sets the UUID variant.
pub fn setVariant(uuid: *Uuid, variant: Variant) void {
    uuid.bytes[8] = switch (variant) {
        .ncs => uuid.bytes[8] & 0b01111111,
        .rfc4122 => 0b10000000 | (uuid.bytes[8] & 0b00111111),
        .microsoft => 0b11000000 | (uuid.bytes[8] & 0b00011111),
        .future => 0b11100000 | (uuid.bytes[8] & 0b0001111),
    };
}
