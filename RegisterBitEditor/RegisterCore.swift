import Foundation

enum RegisterWidth: Int, CaseIterable, Identifiable {
    case bits32 = 32
    case bits64 = 64

    var id: Int { rawValue }
    var title: String { "\(rawValue) 位" }
}

enum NumericBase: Int, CaseIterable, Hashable {
    case hexadecimal = 16
    case decimal = 10
    case octal = 8
    case binary = 2

    var title: String {
        switch self {
        case .hexadecimal: return "Hex"
        case .decimal: return "Dec"
        case .octal: return "Oct"
        case .binary: return "Bin"
        }
    }
}

enum BitwiseOperation {
    case and, or, xor
}

enum RegisterCore {
    static func mask(for width: RegisterWidth) -> UInt64 {
        width == .bits64 ? UInt64.max : UInt64(UInt32.max)
    }

    static func normalized(_ value: UInt64, width: RegisterWidth) -> UInt64 {
        value & mask(for: width)
    }

    static func parse(_ text: String, base: NumericBase) -> UInt64? {
        var cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "")

        switch base {
        case .hexadecimal:
            if cleaned.lowercased().hasPrefix("0x") { cleaned.removeFirst(2) }
        case .binary:
            if cleaned.lowercased().hasPrefix("0b") { cleaned.removeFirst(2) }
        case .octal:
            if cleaned.lowercased().hasPrefix("0o") { cleaned.removeFirst(2) }
        case .decimal:
            break
        }

        guard !cleaned.isEmpty else { return nil }
        return UInt64(cleaned, radix: base.rawValue)
    }

    static func parseFlexible(_ text: String) -> UInt64? {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "")
        let lowered = cleaned.lowercased()

        if lowered.hasPrefix("0x") {
            return parse(cleaned, base: .hexadecimal)
        }
        if lowered.hasPrefix("0b") {
            return parse(cleaned, base: .binary)
        }
        if lowered.hasPrefix("0o") {
            return parse(cleaned, base: .octal)
        }
        return parse(cleaned, base: .decimal)
    }

    static func format(
        _ value: UInt64,
        base: NumericBase,
        width: RegisterWidth,
        uppercase: Bool
    ) -> String {
        let value = normalized(value, width: width)
        let prefix: String

        switch base {
        case .hexadecimal:
            prefix = "0x"
        case .decimal:
            prefix = ""
        case .octal:
            prefix = ""
        case .binary:
            prefix = ""
        }

        let body = String(value, radix: base.rawValue, uppercase: uppercase)
        return prefix + body
    }

    static func signedDecimal(_ value: UInt64, width: RegisterWidth) -> String {
        switch width {
        case .bits32:
            return String(Int32(bitPattern: UInt32(truncatingIfNeeded: value)))
        case .bits64:
            return String(Int64(bitPattern: value))
        }
    }

    static func parseSignedDecimal(_ text: String, width: RegisterWidth) -> UInt64? {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "")

        switch width {
        case .bits32:
            guard let signed = Int32(cleaned) else { return nil }
            return UInt64(UInt32(bitPattern: signed))
        case .bits64:
            guard let signed = Int64(cleaned) else { return nil }
            return UInt64(bitPattern: signed)
        }
    }

    static func applying(
        _ operation: BitwiseOperation,
        lhs: UInt64,
        rhs: UInt64,
        width: RegisterWidth
    ) -> UInt64 {
        let result: UInt64
        switch operation {
        case .and: result = lhs & rhs
        case .or: result = lhs | rhs
        case .xor: result = lhs ^ rhs
        }
        return normalized(result, width: width)
    }

    static func inverted(_ value: UInt64, width: RegisterWidth) -> UInt64 {
        normalized(~value, width: width)
    }

    static func shiftedLeft(_ value: UInt64, by amount: Int, width: RegisterWidth) -> UInt64 {
        guard amount >= 0, amount < width.rawValue else { return 0 }
        return normalized(value << amount, width: width)
    }

    static func shiftedRight(_ value: UInt64, by amount: Int, width: RegisterWidth) -> UInt64 {
        guard amount >= 0, amount < width.rawValue else { return 0 }
        return normalized(value >> amount, width: width)
    }
}
