const std = @import("std");
const assert = std.debug.assert;

// pub const Error = error{InvalidUUID};
// pub const Error = error{
//     InvalidCharacter,
//     InvalidEnumTag,
// };
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
pub const Version = enum {
    /// Version 0 is unused.
    unused,
    /// Version 1 is the Gregorian time-based UUID from RFC4122.
    time_based_gregorian,
    /// Version 2 is the DCE Security UUID with embedded POSIX UIDs from RFC4122.
    dce_security,
    /// Version 3 is the Name-based UUID using MD5 hashing from RFC4122.
    name_based_md5,
    /// Version 4 is the UUID generated using a pseudo-randomly generated number from RFC4122.
    random,
    /// Version 5 is the Name-based UUID using SHA-1 hashing from RFC4122.
    name_based_sha1,
    /// Version 6 is the Reordered Gregorian time-based UUID from IETF "New UUID Formats" Draft.
    time_based_gregorian_reordered,
    /// Version 7 is the Unix Epoch time-based UUID specified from IETF "New UUID Formats" Draft.
    time_based_unix,
    /// Version 8 is reserved for custom UUID formats from IETF "New UUID Formats" Draft.
    custom,
};

/// Returns the UUID version.
pub fn getVersion(self: Uuid) !Version {
    const version_int: u4 = @truncate(self.bytes[6] >> 4);
    return try std.meta.intToEnum(Version, version_int);
}

/// Sets the UUID version.
pub fn setVersion(uuid: *Uuid, version: Version) void {
    uuid.bytes[6] = @as(u8, @intFromEnum(version)) << 4 | (uuid.bytes[6] & 0xF);
}

// init defaults to version-4 uuid.
pub fn init() Uuid {
    var prng = std.rand.DefaultPrng.init(0);

    return Uuid.new_ver4_var1(prng.random());
}

pub fn new_ver4_var1(random: std.rand.Random) Uuid {
    var uuid = Uuid{ .bytes = undefined };

    random.bytes(&uuid.bytes);
    // bun.rand(&uuid.bytes);

    // Version 4
    uuid.bytes[6] = (uuid.bytes[6] & 0x0f) | 0x40;
    // Variant 1
    uuid.bytes[8] = (uuid.bytes[8] & 0x3f) | 0x80;

    return uuid;
}

test "version 4 var 1 test" {
    const v4 = Uuid.init();

    const v4_variant = v4.getVariant();
    try std.testing.expect(v4_variant == Uuid.Variant.rfc4122);

    const v4_version = try v4.getVersion();
    try std.testing.expect(v4_version == Uuid.Version.random);
}
