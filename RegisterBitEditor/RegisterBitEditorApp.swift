import SwiftUI

@main
struct RegisterBitEditorApp: App {
    @StateObject private var model = RegisterViewModel()

    var body: some Scene {
        WindowGroup("RegisterKit — 寄存器工具箱") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 540, minHeight: 400)
        }
        .defaultSize(width: 560, height: 420)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 RegisterKit") {
                    model.showAbout()
                }
            }

            CommandMenu("寄存器") {
                Button("清零") {
                    model.clear()
                }
                .keyboardShortcut("k", modifiers: [.command])

                Button("复制十六进制值") {
                    model.copy(.hexadecimal)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }

            CommandMenu("位运算") {
                Button("AND…") { model.promptAndApply(.and) }
                Button("OR…") { model.promptAndApply(.or) }
                Button("XOR…") { model.promptAndApply(.xor) }
                Divider()
                Button("NOT") { model.invert() }
            }
        }
    }
}
