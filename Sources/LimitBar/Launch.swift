import AppKit

/// Fork addition (wyndollin/limitbar): click the Claude section to open Claude Code in Terminal, in your
/// home folder. Started only by that click, never on its own.
///
/// `defaults write io.github.dancik.limitbar claudeSkipPermissions -bool true` adds
/// `--dangerously-skip-permissions`, so Claude Code runs commands without asking first. Off by default.
enum Launch {
    static var skipsPermissions: Bool { UserDefaults.standard.bool(forKey: "claudeSkipPermissions") }

    static func claudeCode() {
        guard case .ok(let path) = CLI.find(Vendor.claude.cli) else { NSSound.beep(); return }
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/limitbar", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true,
                                                 attributes: [.posixPermissions: 0o700])
        let quoted = "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
        let flags = skipsPermissions ? " --dangerously-skip-permissions" : ""
        let script = dir.appendingPathComponent("open-claude-code.command")
        do {
            try "#!/bin/zsh -l\ncd ~ && exec \(quoted)\(flags)\n".write(to: script, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: script.path)
        } catch { NSSound.beep(); return }
        guard let terminal = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") else {
            NSSound.beep(); return
        }
        NSWorkspace.shared.open([script], withApplicationAt: terminal, configuration: NSWorkspace.OpenConfiguration())
    }
}
