import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: RegisterViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 9) {
                bitPanel
                numberPanel
                bottomBar
            }
            .padding(10)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .background(WindowLevelController(
            alwaysOnTop: model.alwaysOnTop,
            preferredContentSize: preferredWindowSize
        ))
    }

    private var preferredWindowSize: NSSize {
        model.width == .bits32
            ? NSSize(width: 560, height: 350)
            : NSSize(width: 680, height: 470)
    }

    private var hexRowWidth: CGFloat {
        model.width == .bits32 ? 180 : 235
    }

    private var pairedRowWidth: CGFloat {
        model.width == .bits32 ? 210 : 275
    }

    private var binaryRowWidth: CGFloat {
        model.width == .bits32 ? 340 : 620
    }

    // 16 bits per row. Four bits form a nibble; two nibbles form a byte.
    private var bitPanel: some View {
        VStack(spacing: 9) {
            ForEach(bitRows, id: \.self) { row in
                HStack(spacing: 20) {
                    byteBlock(Array(row.prefix(8)))
                    byteBlock(Array(row.suffix(8)))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
    }

    private var bitRows: [[Int]] {
        stride(from: 0, to: model.bitIndices.count, by: 16).map { start in
            Array(model.bitIndices[start..<min(start + 16, model.bitIndices.count)])
        }
    }

    private func byteBlock(_ bits: [Int]) -> some View {
        HStack(spacing: 14) {
            nibbleBlock(Array(bits.prefix(4)))
            nibbleBlock(Array(bits.suffix(4)))
        }
        .frame(maxWidth: .infinity)
    }

    private func nibbleBlock(_ bits: [Int]) -> some View {
        HStack(spacing: 5) {
            ForEach(bits, id: \.self) { bit in
                bitCell(bit)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func bitCell(_ bit: Int) -> some View {
        let active = model.isSet(bit)

        return VStack(spacing: 3) {
            Text("\(bit)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))

            Button {
                model.toggleBit(bit)
            } label: {
                Text(active ? "1" : "0")
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(active ? .white : .primary)
                    .frame(width: 26, height: 30)
                    .background(active ? Color.accentColor : Color(nsColor: .controlColor))
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.secondary.opacity(active ? 0 : 0.4), lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("bit \(bit)")
            .accessibilityValue(active ? "1" : "0")
        }
    }

    private var numberPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                numberField(.hexadecimal, label: "十六进制：")
                    .frame(width: hexRowWidth, alignment: .leading)

                Toggle("有符号", isOn: Binding(
                    get: { model.signedMode },
                    set: { model.setSignedMode($0) }
                ))
                .fixedSize()

                Toggle("大写", isOn: Binding(
                    get: { model.uppercase },
                    set: { model.setUppercase($0) }
                ))
                .fixedSize()

                Toggle("置顶", isOn: $model.alwaysOnTop)
                    .fixedSize()
            }

            HStack(spacing: 12) {
                numberField(.decimal, label: "十进制：")
                    .frame(width: pairedRowWidth, alignment: .leading)
                numberField(.octal, label: "八进制：")
                    .frame(width: pairedRowWidth, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            numberField(.binary, label: "二进制：")
                .frame(width: binaryRowWidth, alignment: .leading)
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func numberField(_ base: NumericBase, label: String) -> some View {
        HStack(spacing: 6) {
            Button {
                model.copy(base)
            } label: {
                Text(label)
                    .fontWeight(.medium)
                    .frame(width: 66, alignment: .leading)
            }
            .buttonStyle(.plain)
            .help("复制\(label.replacingOccurrences(of: "：", with: ""))")

            TextField(base.title, text: Binding(
                get: { model.text(for: base) },
                set: { model.updateText($0, for: base) }
            ))
            .font(.system(.body, design: .monospaced))
            .textFieldStyle(.roundedBorder)
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(model.invalidBases.contains(base) ? Color.red : Color.clear, lineWidth: 1)
            }
            .onSubmit { model.commit(base) }
        }
        .frame(maxWidth: .infinity)
    }

    private var bottomBar: some View {
        HStack(spacing: 7) {
            wideButton("清除") { model.clear() }
            wideButton("ASCII") { model.showASCII() }
            wideButton("计算器") { model.openCalculator() }

            Button("左移") { model.shiftLeft() }
                .frame(minWidth: 52)

            TextField("", value: $model.shiftAmount, format: .number)
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.roundedBorder)
                .frame(width: 46)

            Button("右移") { model.shiftRight() }
                .frame(minWidth: 52)

            Toggle("64位模式", isOn: Binding(
                get: { model.width == .bits64 },
                set: { model.setWidth($0 ? .bits64 : .bits32) }
            ))
            .toggleStyle(.button)
            .frame(maxWidth: .infinity)
        }
        .controlSize(.regular)
        .buttonStyle(.bordered)
    }

    private func wideButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .frame(maxWidth: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(RegisterViewModel())
            .frame(width: 560, height: 350)
    }
}
