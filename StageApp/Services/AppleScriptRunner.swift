import Foundation

enum ResourceValidator {
    static func isSafeAbsolutePath(_ path: String) -> Bool {
        path.hasPrefix("/")
            && path.count < 4096
            && !path.contains("\n")
            && !path.contains("\r")
            && !path.contains("\0")
    }

    static func isRestorableFilePath(_ path: String) -> Bool {
        isSafeAbsolutePath(path)
    }

    static func isRestorableWebOrFileURL(_ string: String) -> Bool {
        guard string.count < 8000, let url = URL(string: string), let scheme = url.scheme?.lowercased() else {
            return false
        }
        if scheme == "file" {
            return isSafeAbsolutePath(url.path)
        }
        return scheme == "http" || scheme == "https"
    }
}

enum AppleScript {
    static func literal(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        return "\"\(escaped)\""
    }
}

struct ScriptResult: Sendable, Equatable {
    var output: String
    var error: String?
    var timedOut: Bool

    var succeeded: Bool { error == nil && !timedOut }
}

struct AppleScriptRunner: Sendable {
    func run(_ source: String, timeout: TimeInterval = 2.5) -> ScriptResult {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("stage-script-\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let scriptURL = directory.appendingPathComponent("script.applescript")
            let outURL = directory.appendingPathComponent("out.txt")
            let errURL = directory.appendingPathComponent("err.txt")
            try source.write(to: scriptURL, atomically: true, encoding: .utf8)
            FileManager.default.createFile(atPath: outURL.path, contents: nil)
            FileManager.default.createFile(atPath: errURL.path, contents: nil)
            let stdout = try FileHandle(forWritingTo: outURL)
            let stderr = try FileHandle(forWritingTo: errURL)
            defer {
                try? stdout.close()
                try? stderr.close()
                try? FileManager.default.removeItem(at: directory)
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = [scriptURL.path]
            process.standardOutput = stdout
            process.standardError = stderr
            try process.run()

            let deadline = Date().addingTimeInterval(timeout)
            while process.isRunning && Date() < deadline {
                Thread.sleep(forTimeInterval: 0.02)
            }
            if process.isRunning {
                process.terminate()
                process.waitUntilExit()
                return ScriptResult(output: "", error: "Timed out.", timedOut: true)
            }
            try stdout.close()
            try stderr.close()
            let output = (try? String(contentsOf: outURL, encoding: .utf8)) ?? ""
            let error = (try? String(contentsOf: errURL, encoding: .utf8)) ?? ""
            if process.terminationStatus != 0 {
                return ScriptResult(output: output, error: error.isEmpty ? "osascript failed." : error, timedOut: false)
            }
            return ScriptResult(output: output, error: nil, timedOut: false)
        } catch {
            try? FileManager.default.removeItem(at: directory)
            return ScriptResult(output: "", error: error.localizedDescription, timedOut: false)
        }
    }
}
