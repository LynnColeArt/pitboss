import Foundation

public struct PolicyFinding: Codable, Equatable, Sendable, CustomStringConvertible {
    public var path: String
    public var code: String
    public var message: String

    public init(path: String, code: String, message: String) {
        self.path = path
        self.code = code
        self.message = message
    }

    public var description: String {
        "\(code): \(path): \(message)"
    }
}

public struct ZeroPythonPolicyScanner: Sendable {
    public init() {}

    public func scan(root: URL) -> [PolicyFinding] {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return [PolicyFinding(path: root.path, code: "PITBOSS_POLICY_SCAN_FAILED", message: "Could not enumerate repository.")]
        }

        var findings: [PolicyFinding] = []
        for case let fileURL as URL in enumerator {
            let relativePath = fileURL.path.replacingOccurrences(of: root.path + "/", with: "")
            if shouldSkip(relativePath) { continue }
            let name = fileURL.lastPathComponent.lowercased()

            if name.hasSuffix(".py") && !relativePath.hasPrefix("docs/reference-notes/") {
                findings.append(PolicyFinding(path: relativePath, code: "PITBOSS_POLICY_PY_FILE", message: "Python files are not allowed in runtime source."))
            }

            if ["requirements.txt", "pyproject.toml", "setup.py"].contains(name) {
                findings.append(PolicyFinding(path: relativePath, code: "PITBOSS_POLICY_PY_DEPENDENCY_FILE", message: "Python dependency/build files are forbidden."))
            }

            guard relativePath != "Sources/PitbossCore/Policy/ZeroPythonPolicy.swift",
                  isEnforcedSource(relativePath),
                  let contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
                continue
            }

            let lowered = contents.lowercased()
            let invokesSubprocess = lowered.contains("process(") || lowered.contains("subprocess") || lowered.contains("/usr/bin/env")
            if invokesSubprocess {
                for forbidden in ["python", "python3", "pip ", "torch", "diffusers", "transformers"] where lowered.contains(forbidden) {
                    findings.append(PolicyFinding(path: relativePath, code: "PITBOSS_POLICY_FORBIDDEN_RUNTIME_INVOCATION", message: "Runtime/build/test source appears to invoke forbidden token '\(forbidden.trimmingCharacters(in: .whitespaces))'."))
                }
            }
        }
        return findings
    }

    private func shouldSkip(_ relativePath: String) -> Bool {
        relativePath.hasPrefix(".build/") ||
            relativePath.hasPrefix(".swiftpm/") ||
            relativePath.hasPrefix(".git/") ||
            relativePath.hasPrefix("docs/reference-notes/")
    }

    private func isEnforcedSource(_ relativePath: String) -> Bool {
        relativePath == "Package.swift" ||
            relativePath.hasPrefix("Sources/") ||
            relativePath.hasPrefix("Tests/") ||
            relativePath.hasSuffix(".sh")
    }
}
