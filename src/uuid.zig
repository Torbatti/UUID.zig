const std = @import("std");
const assert = std.debug.assert;

pub const Error = error{InvalidUUID};
pub const STRING_LENGTH = 36;

const Uuid = @This();

bytes: [16]u8,

/// UUID variant or family.
pub const Variant = enum {
    /// Legacy Apollo Network Computing System UUIDs.
    ncs,
    /// RFC 4122/DCE 1.1 UUIDs, or "Leach–Salz" UUIDs.
    rfc4122,
    /// Backwards-compatible Microsoft COM/DCOM UUIDs.
    microsoft,
    /// Reserved for future definition UUIDs.
    future,
};

/// Returns the UUID variant.
pub fn getVariant(self: Uuid) Variant {
    assert(@sizeOf(self) == @sizeOf([16]u8));

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
    assert(@sizeOf(uuid.*) == @sizeOf([16]u8));

    uuid.bytes[8] = switch (variant) {
        .ncs => uuid.bytes[8] & 0b01111111,
        .rfc4122 => 0b10000000 | (uuid.bytes[8] & 0b00111111),
        .microsoft => 0b11000000 | (uuid.bytes[8] & 0b00011111),
        .future => 0b11100000 | (uuid.bytes[8] & 0b0001111),
    };
}
