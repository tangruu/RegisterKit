import AppKit
import Combine
import Foundation

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published private(set) var value: UInt64 = 0
    @Published private(set) var width: RegisterWidth = .bits32
    @Published private(set) var uppercase = true
    @Published private(set) var signedMode = false

    @Published private(set) var hexText = ""
    @Published private(set) var decText = ""
    @Published private(set) var octText = ""
    @Published private(set) var binText = ""
    @Published var operandText = "0x00000001"
    @Published var shiftAmount = 1
    @Published var alwaysOnTop = true
    @Published private(set) var invalidBases: Set<NumericBase> = []
    @Published private(set) var operandIsInvalid = false

    init() {
        synchronizeFields()
    }

    var bitIndices: [Int] {
        Array(stride(from: width.rawValue - 1, through: 0, by: -1))
    }

    func setWidth(_ newWidth: RegisterWidth) {
        width = newWidth
        value = RegisterCore.normalized(value, width: newWidth)
        shiftAmount = min(shiftAmount, newWidth.rawValue - 1)
        invalidBases.removeAll()
        synchronizeFields()
    }

    func setUppercase(_ enabled: Bool) {
        uppercase = enabled
        synchronizeFields()
    }

    func setSignedMode(_ enabled: Bool) {
        signedMode = enabled
        synchronizeFields()
    }

    func isSet(_ bit: Int) -> Bool {
        (value & (UInt64(1) << bit)) != 0
    }

    func toggleBit(_ bit: Int) {
        setValue(value ^ (UInt64(1) << bit))
    }

    func clear() {
        setValue(0)
    }

    func updateText(_ text: String, for base: NumericBase) {
        assign(text, to: base)

        let candidate = base == .decimal && signedMode
            ? RegisterCore.parseSignedDecimal(text, width: width)
            : RegisterCore.parse(text, base: base)

        guard let parsed = candidate,
              parsed <= RegisterCore.mask(for: width) else {
            invalidBases.insert(base)
            return
        }

        invalidBases.remove(base)
        value = parsed
        synchronizeFields(excluding: base)
    }

    func commit(_ base: NumericBase) {
        if invalidBases.contains(base) {
            invalidBases.remove(base)
        }
        assign(formatted(base), to: base)
    }

    func apply(_ operation: BitwiseOperation) {
        guard let operand = RegisterCore.parseFlexible(operandText),
              operand <= RegisterCore.mask(for: width) else {
            operandIsInvalid = true
            return
        }
        operandIsInvalid = false
        setValue(RegisterCore.applying(operation, lhs: value, rhs: operand, width: width))
    }

    func invert() {
        setValue(RegisterCore.inverted(value, width: width))
    }

    func shiftLeft() {
        setValue(RegisterCore.shiftedLeft(value, by: shiftAmount, width: width))
    }

    func shiftRight() {
        setValue(RegisterCore.shiftedRight(value, by: shiftAmount, width: width))
    }

    func copy(_ base: NumericBase) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(formatted(base), forType: .string)
    }

    func openCalculator() {
        let modernURL = URL(fileURLWithPath: "/System/Applications/Calculator.app")
        let legacyURL = URL(fileURLWithPath: "/Applications/Calculator.app")
        let calculatorURL = FileManager.default.fileExists(atPath: modernURL.path)
            ? modernURL
            : legacyURL
        NSWorkspace.shared.open(calculatorURL)
    }

    func showASCII() {
        let byteCount = width.rawValue / 8
        let currentBytes = stride(from: byteCount - 1, through: 0, by: -1).map { index -> String in
            let byte = UInt8(truncatingIfNeeded: value >> (index * 8))
            return String(format: "0x%02X (%@)", byte, asciiName(for: Int(byte)))
        }

        let tableRows = (0..<32).map { row in
            (0..<4).map { column -> String in
                let code = row + column * 32
                let paddedName = asciiName(for: code)
                    .padding(toLength: 5, withPad: " ", startingAt: 0)
                return String(format: "%3d  %02X  %@", code, code, paddedName)
            }
            .joined(separator: "    ")
        }

        let table = """
        当前寄存器字节（高位 → 低位）
        \(currentBytes.joined(separator: "  "))

        Dec Hex ASCII      Dec Hex ASCII      Dec Hex ASCII      Dec Hex ASCII
        ─────────────────────────────────────────────────────────────────────
        \(tableRows.joined(separator: "\n"))
        """

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 700, height: 510))
        textView.string = table
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 8, height: 8)

        let alert = NSAlert()
        alert.messageText = "完整 ASCII 码表（0–127）"
        alert.accessoryView = textView
        alert.addButton(withTitle: "关闭")
        alert.runModal()
    }

    private func asciiName(for code: Int) -> String {
        let controls = [
            "NUL", "SOH", "STX", "ETX", "EOT", "ENQ", "ACK", "BEL",
            "BS", "TAB", "LF", "VT", "FF", "CR", "SO", "SI",
            "DLE", "DC1", "DC2", "DC3", "DC4", "NAK", "SYN", "ETB",
            "CAN", "EM", "SUB", "ESC", "FS", "GS", "RS", "US"
        ]

        if code < controls.count { return controls[code] }
        if code == 32 { return "SPACE" }
        if code == 127 { return "DEL" }
        return String(Character(UnicodeScalar(code)!))
    }

    func promptAndApply(_ operation: BitwiseOperation) {
        let alert = NSAlert()
        alert.messageText = "\(operationTitle(operation)) 操作"
        alert.informativeText = "请输入操作数，支持 0x、0b、0o 或十进制。"
        alert.addButton(withTitle: "计算")
        alert.addButton(withTitle: "取消")

        let input = NSTextField(string: operandText)
        input.frame = NSRect(x: 0, y: 0, width: 280, height: 24)
        alert.accessoryView = input

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        operandText = input.stringValue
        apply(operation)
    }

    func text(for base: NumericBase) -> String {
        switch base {
        case .hexadecimal: return hexText
        case .decimal: return decText
        case .octal: return octText
        case .binary: return binText
        }
    }

    private func setValue(_ newValue: UInt64) {
        value = RegisterCore.normalized(newValue, width: width)
        invalidBases.removeAll()
        synchronizeFields()
    }

    private func formatted(_ base: NumericBase) -> String {
        if base == .decimal && signedMode {
            return RegisterCore.signedDecimal(value, width: width)
        }
        return RegisterCore.format(value, base: base, width: width, uppercase: uppercase)
    }

    private func operationTitle(_ operation: BitwiseOperation) -> String {
        switch operation {
        case .and: return "AND"
        case .or: return "OR"
        case .xor: return "XOR"
        }
    }

    private func synchronizeFields(excluding excluded: NumericBase? = nil) {
        for base in NumericBase.allCases where base != excluded {
            assign(formatted(base), to: base)
        }
    }

    private func assign(_ text: String, to base: NumericBase) {
        switch base {
        case .hexadecimal: hexText = text
        case .decimal: decText = text
        case .octal: octText = text
        case .binary: binText = text
        }
    }
}
