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

        print("Core tests passed")
    }
}
