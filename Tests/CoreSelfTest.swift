import Foundation

@main
struct CoreSelfTest {
    static func main() {
        assert(RegisterCore.parse("0xFFFF_FFFF", base: .hexadecimal) == UInt64(UInt32.max))
        assert(RegisterCore.parse("0b1010", base: .binary) == 10)
        assert(RegisterCore.parseFlexible("0o17") == 15)
        assert(RegisterCore.parseFlexible("18446744073709551615") == UInt64.max)

        assert(RegisterCore.format(0xABCD, base: .hexadecimal, width: .bits32, uppercase: true) == "0xABCD")
        assert(RegisterCore.format(5, base: .binary, width: .bits32, uppercase: true) == "101")
        assert(RegisterCore.signedDecimal(0xFFFF_FFFF, width: .bits32) == "-1")

        assert(RegisterCore.applying(.and, lhs: 0b1100, rhs: 0b1010, width: .bits32) == 0b1000)
        assert(RegisterCore.applying(.or, lhs: 0b1100, rhs: 0b0011, width: .bits32) == 0b1111)
        assert(RegisterCore.applying(.xor, lhs: 0b1100, rhs: 0b1010, width: .bits32) == 0b0110)
        assert(RegisterCore.inverted(0, width: .bits32) == UInt64(UInt32.max))
        assert(RegisterCore.shiftedLeft(1, by: 31, width: .bits32) == 0x8000_0000)
        assert(RegisterCore.shiftedLeft(1, by: 32, width: .bits32) == 0)
        assert(RegisterCore.shiftedRight(0x8000_0000, by: 31, width: .bits32) == 1)

        assert(CapacityCore.parseHexadecimal("0x1 2345") == 0x12345)
        assert(CapacityCore.parseHexadecimal("0x0000 0001 2345") == 0x12345)
        assert(CapacityCore.parseHexadecimal("0x200000000") == 0x200000000)
        assert(CapacityCore.parseHexadecimal("0x1 0000 0000 00") == nil)
        assert(CapacityCore.parseDecimal("999999999999999999999", maximum: 1023) == 1023)
        assert(CapacityCore.parseDecimalResult("1023", maximum: 1023)?.wasClamped == false)
        assert(CapacityCore.parseDecimalResult("1024", maximum: 1023)?.wasClamped == true)
        assert(CapacityCore.formatHexadecimal(0x12345, uppercase: true) == "0x1 2345")
        assert(CapacityCore.parts(for: 1025) == CapacityParts(
            gigabytes: 0,
            megabytes: 0,
            kilobytes: 1,
            bytes: 1
        ))
        assert(CapacityCore.compose(CapacityParts(
            gigabytes: 0,
            megabytes: 0,
            kilobytes: 0,
            bytes: 1024
        )) == nil)
        assert(CapacityCore.parts(for: CapacityCore.maximumValue) == CapacityParts(
            gigabytes: 1023,
            megabytes: 1023,
            kilobytes: 1023,
            bytes: 1023
        ))

        print("Core tests passed")
    }
}
