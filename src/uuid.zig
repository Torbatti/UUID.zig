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

/// Returns a UUID from a 16-byte slice.
pub fn fromBytes(bytes: []const u8) Uuid {
    assert(bytes.len == 16); // memcopy checks length as well

    var uuid: Uuid = undefined;
    @memcpy(uuid.bytes[0..], bytes);
    return uuid;
}

test "fromBytes" {
    try std.testing.expectEqual([1]u8{0x0} ** 16, fromBytes(&[1]u8{0x0} ** 16).bytes);
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

/// UUID version or subtype.
pub const Version = enum(u4) {
    /// Version 0 is unused.
    unused = 0,
    /// Version 1 is the Gregorian time-based UUID from RFC4122.
    time_based_gregorian = 1,
    /// Version 2 is the DCE Security UUID with embedded POSIX UIDs from RFC4122.
    dce_security = 2,
    /// Version 3 is the Name-based UUID using MD5 hashing from RFC4122.
    name_based_md5 = 3,
    /// Version 4 is the UUID generated using a pseudo-randomly generated number from RFC4122.
    random = 4,
    /// Version 5 is the Name-based UUID using SHA-1 hashing from RFC4122.
    name_based_sha1 = 5,
    /// Version 6 is the Reordered Gregorian time-based UUID from IETF "New UUID Formats" Draft.
    time_based_gregorian_reordered = 6,
    /// Version 7 is the Unix Epoch time-based UUID specified from IETF "New UUID Formats" Draft.
    time_based_unix = 7,
    /// Version 8 is reserved for custom UUID formats from IETF "New UUID Formats" Draft.
    custom = 8,
};

/// Returns the UUID version.
pub fn getVersion(self: Uuid) Error!Version {
    const version_int: u4 = @truncate(self.bytes[6] >> 4);
    return try std.meta.intToEnum(Version, version_int);
}

/// Sets the UUID version.
pub fn setVersion(uuid: *Uuid, version: Version) void {
    uuid.bytes[6] = @as(u8, @intFromEnum(version)) << 4 | (uuid.bytes[6] & 0xF);
}
