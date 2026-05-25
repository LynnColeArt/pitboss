import Foundation
import PitbossApple
import PitbossCompat
import PitbossCore

@main
struct PitbossCLI {
    static func main() {
        var arguments = Array(CommandLine.arguments.dropFirst())
        guard let command = arguments.first else {
            printUsage()
            return
        }
        arguments.removeFirst()

        switch command {
        case "doctor":
            doctor()
        case "inspect":
            inspect(arguments)
        case "validate":
            validate(arguments)
        case "policy-check":
            policyCheck()
        case "help", "--help", "-h":
            printUsage()
        default:
            eprint("Unknown command: \(command)")
            printUsage()
            Foundation.exit(64)
        }
    }

    private static func printUsage() {
        print("""
        pitboss <command>

        Commands:
          doctor                 Print host, backend, plugin, and zero-Python policy status.
          inspect plugins        List registered plugin contracts and capabilities.
          validate <workflow>    Validate a Comfy workflow or API prompt JSON file.
          policy-check           Scan runtime/build/test sources for zero-Python policy violations.
        """)
    }

    private static func doctor() {
        let host = DeviceProbe.current()
        let plugins = PluginRegistry()
        let backends = DeviceProbe.backendDescriptors()
        let policyFindings = ZeroPythonPolicyScanner().scan(root: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))

        print("Pitboss Doctor")
        print("Platform: \(host.platform)")
        print("OS: \(host.osVersion)")
        print("Architecture: \(host.architecture)")
        print("Apple Silicon: \(host.isAppleSilicon ? "yes" : "no")")
        print("Core ML: \(host.coreMLStatus)")
        print("MLX: \(host.mlxStatus)")
        print("Registered plugins: \(plugins.plugins.count)")
        print("Registered backends: \(backends.count)")
        for backend in backends {
            print("  - \(backend.id): \(backend.executionStatus)")
        }
        if policyFindings.isEmpty {
            print("Zero-Python policy: pass")
        } else {
            print("Zero-Python policy: \(policyFindings.count) finding(s)")
            for finding in policyFindings {
                print("  - \(finding)")
            }
        }
    }

    private static func inspect(_ arguments: [String]) {
        guard arguments.first == "plugins" else {
            eprint("Usage: pitboss inspect plugins")
            Foundation.exit(64)
        }

        let registry = PluginRegistry()
        print("Pitboss Plugins")
        for plugin in registry.plugins {
            print("- \(plugin.id) (\(plugin.version))")
            print("  name: \(plugin.displayName)")
            print("  kind: \(plugin.kind.rawValue)")
            print("  capabilities:")
            for capability in plugin.capabilitiesProvided {
                print("    - \(capability.description)")
            }
            if !plugin.nodesProvided.isEmpty {
                print("  nodes:")
                for node in plugin.nodesProvided {
                    print("    - \(node.type): \(node.displayName)")
                }
            }
        }
    }

    private static func validate(_ arguments: [String]) {
        guard let path = arguments.first else {
            eprint("Usage: pitboss validate <workflow.json>")
            Foundation.exit(64)
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            var report = ComfyWorkflowParser().parse(data: data)
            if let graph = report.graph {
                let registry = PluginRegistry()
                report.diagnostics.append(contentsOf: registry.diagnostics(for: graph.requiredCapabilities))
                print("Workflow: \(path)")
                print("Format: \(graph.workflowProvenance.sourceFormat)")
                print("Nodes: \(graph.nodes.count)")
                print("Edges: \(graph.edges.count)")
                print("Required capabilities:")
                for capability in graph.requiredCapabilities {
                    print("  - \(capability.description)")
                }
            }

            if report.diagnostics.isEmpty {
                print("Diagnostics: none")
                print("Executable in prototype: no; validation-only runtime spine")
                return
            }

            print("Diagnostics:")
            for diagnostic in report.diagnostics {
                print("  - \(diagnostic)")
            }
            print("Executable in prototype: no")

            if report.hasErrors {
                Foundation.exit(1)
            }
        } catch {
            eprint("Could not read \(path): \(error.localizedDescription)")
            Foundation.exit(66)
        }
    }

    private static func policyCheck() {
        let findings = ZeroPythonPolicyScanner().scan(root: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
        if findings.isEmpty {
            print("Zero-Python policy: pass")
            return
        }
        print("Zero-Python policy: \(findings.count) finding(s)")
        for finding in findings {
            print("- \(finding)")
        }
        Foundation.exit(1)
    }

    private static func eprint(_ message: String) {
        if let data = "\(message)\n".data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}
