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

enum CapacityField: Hashable {
    case hexadecimal, decimal, gigabytes, megabytes, kilobytes, bytes
}

enum CapacityUnit: CaseIterable, Hashable {
    case gigabytes, megabytes, kilobytes, bytes

    var title: String {
        switch self {
        case .gigabytes: return "GiB"
        case .megabytes: return "MiB"
        case .kilobytes: return "KiB"
        case .bytes: return "B"
        }
    }

    var field: CapacityField {
        switch self {
        case .gigabytes: return .gigabytes
        case .megabytes: return .megabytes
        case .kilobytes: return .kilobytes
        case .bytes: return .bytes
        }
    }
}

struct CapacityParts: Equatable {
    var gigabytes: UInt64
    var megabytes: UInt64
    var kilobytes: UInt64
    var bytes: UInt64

    subscript(unit: CapacityUnit) -> UInt64 {
        get {
            switch unit {
            case .gigabytes: return gigabytes
            case .megabytes: return megabytes
            case .kilobytes: return kilobytes
            case .bytes: return bytes
            }
        }
        set {
            switch unit {
            case .gigabytes: gigabytes = newValue
            case .megabytes: megabytes = newValue
            case .kilobytes: kilobytes = newValue
            case .bytes: bytes = newValue
            }
        }
    }
}

enum CapacityCore {
    struct DecimalParseResult {
        let value: UInt64
        let wasClamped: Bool
    }

    static let radix: UInt64 = 1024
    static let maximumValue = radix * radix * radix * radix - 1
    static let maximumComponent = radix - 1

    static func parseHexadecimal(_ text: String) -> UInt64? {
        var cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")

        if cleaned.lowercased().hasPrefix("0x") {
            cleaned.removeFirst(2)
        }

        let hexadecimalDigits = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        guard !cleaned.isEmpty,
              cleaned.unicodeScalars.allSatisfy(hexadecimalDigits.contains) else {
            return nil
        }

        while cleaned.count > 1 && cleaned.first == "0" {
            cleaned.removeFirst()
        }

        // 1024 GiB - 1 B is 0xFF FFFF FFFF (10 hexadecimal digits).
        guard cleaned.count <= 10 else { return nil }
        guard let value = UInt64(cleaned, radix: 16) else { return nil }
        return value <= maximumValue ? value : nil
    }

    static func parseDecimal(_ text: String, maximum: UInt64) -> UInt64? {
        parseDecimalResult(text, maximum: maximum)?.value
    }

    static func parseDecimalResult(
        _ text: String,
        maximum: UInt64
    ) -> DecimalParseResult? {
        var cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "")

        let decimalDigits = CharacterSet(charactersIn: "0123456789")
        guard !cleaned.isEmpty,
              cleaned.unicodeScalars.allSatisfy(decimalDigits.contains) else {
            return nil
        }

        while cleaned.count > 1 && cleaned.first == "0" {
            cleaned.removeFirst()
        }

        let maximumText = String(maximum)
        if cleaned.count > maximumText.count {
            return DecimalParseResult(value: maximum, wasClamped: true)
        }

        guard let value = UInt64(cleaned) else {
            return DecimalParseResult(value: maximum, wasClamped: true)
        }
        return DecimalParseResult(
            value: min(value, maximum),
            wasClamped: value > maximum
        )
    }

    static func formatHexadecimal(_ value: UInt64, uppercase: Bool) -> String {
        let digits = String(value, radix: 16, uppercase: uppercase)
        var groups: [Substring] = []
        var end = digits.endIndex

        while end > digits.startIndex {
            let start = digits.index(end, offsetBy: -4, limitedBy: digits.startIndex)
                ?? digits.startIndex
            groups.append(digits[start..<end])
            end = start
        }

        return "0x" + groups.reversed().joined(separator: " ")
    }

    static func parts(for value: UInt64) -> CapacityParts {
        let kilobyte = radix
        let megabyte = kilobyte * radix
        let gigabyte = megabyte * radix

        return CapacityParts(
            gigabytes: value / gigabyte,
            megabytes: value / megabyte % radix,
            kilobytes: value / kilobyte % radix,
            bytes: value % radix
        )
    }

    static func compose(_ parts: CapacityParts) -> UInt64? {
        guard parts.gigabytes <= maximumComponent,
              parts.megabytes <= maximumComponent,
              parts.kilobytes <= maximumComponent,
              parts.bytes <= maximumComponent else {
            return nil
        }

        let kilobyte = radix
        let megabyte = kilobyte * radix
        let gigabyte = megabyte * radix
        let terms = [
            parts.gigabytes.multipliedReportingOverflow(by: gigabyte),
            parts.megabytes.multipliedReportingOverflow(by: megabyte),
            parts.kilobytes.multipliedReportingOverflow(by: kilobyte)
        ]
        guard terms.allSatisfy({ !$0.overflow }) else { return nil }

        var total = parts.bytes
        for term in terms {
            let result = total.addingReportingOverflow(term.partialValue)
            guard !result.overflow else { return nil }
            total = result.partialValue
        }

        return total <= maximumValue ? total : nil
    }
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
