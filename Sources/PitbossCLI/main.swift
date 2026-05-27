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
        case "validate-manifest":
            validateManifest(arguments)
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
          validate [--json] <workflow>
                                 Validate a Comfy workflow or API prompt JSON file.
          validate-manifest [--json] <manifest>
                                 Validate a Pitboss model bundle manifest.
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
        let options = parsePathOptions(arguments)
        guard let path = options.path else {
            eprint("Usage: pitboss validate [--json] <workflow.json>")
            Foundation.exit(64)
        }

        do {
            let report = try validationReport(path: path)
            if options.json {
                printJSON(ValidationSummary(workflowPath: path, report: report))
            } else {
                printHumanValidation(path: path, report: report)
            }
            if report.hasErrors {
                Foundation.exit(1)
            }
        } catch {
            let diagnostic = Diagnostic(
                severity: .error,
                code: "PITBOSS_WORKFLOW_READ_FAILED",
                message: "Could not read \(path): \(error.localizedDescription)",
                suggestedFix: "Check that the workflow path exists and is readable."
            )
            let report = ValidationReport(graph: nil, diagnostics: [diagnostic])
            if options.json {
                printJSON(ValidationSummary(workflowPath: path, report: report))
            } else {
                eprint(diagnostic.message)
            }
            Foundation.exit(66)
        }
    }

    private static func validateManifest(_ arguments: [String]) {
        let options = parsePathOptions(arguments)
        guard let path = options.path else {
            eprint("Usage: pitboss validate-manifest [--json] <manifest.json>")
            Foundation.exit(64)
        }

        let report: ManifestValidationReport
        do {
            report = try manifestValidationReport(path: path)
        } catch ManifestReadError.readFailed(let message) {
            let diagnostic = Diagnostic(
                severity: .error,
                code: "PITBOSS_MANIFEST_READ_FAILED",
                message: message,
                suggestedFix: "Check that the manifest path exists and is readable."
            )
            let failedReport = ManifestValidationReport(manifest: nil, diagnostics: [diagnostic])
            if options.json {
                printJSON(ManifestValidationSummary(manifestPath: path, report: failedReport))
            } else {
                eprint(diagnostic.message)
            }
            Foundation.exit(66)
        } catch ManifestReadError.decodeFailed(let message) {
            let diagnostic = Diagnostic(
                severity: .error,
                code: "PITBOSS_MANIFEST_DECODE_FAILED",
                message: message,
                suggestedFix: "Check the manifest JSON shape and enum values."
            )
            let failedReport = ManifestValidationReport(manifest: nil, diagnostics: [diagnostic])
            if options.json {
                printJSON(ManifestValidationSummary(manifestPath: path, report: failedReport))
            } else {
                eprint(diagnostic.message)
            }
            Foundation.exit(65)
        } catch {
            let diagnostic = Diagnostic(
                severity: .error,
                code: "PITBOSS_MANIFEST_VALIDATION_FAILED",
                message: "Could not validate \(path): \(error.localizedDescription)",
                suggestedFix: "Retry with --json for structured diagnostics."
            )
            let failedReport = ManifestValidationReport(manifest: nil, diagnostics: [diagnostic])
            if options.json {
                printJSON(ManifestValidationSummary(manifestPath: path, report: failedReport))
            } else {
                eprint(diagnostic.message)
            }
            Foundation.exit(1)
        }

        if options.json {
            printJSON(ManifestValidationSummary(manifestPath: path, report: report))
        } else {
            printHumanManifestValidation(path: path, report: report)
        }
        if report.hasErrors {
            Foundation.exit(1)
        }
    }

    private struct PathOptions {
        var path: String?
        var json: Bool
    }

    private static func parsePathOptions(_ arguments: [String]) -> PathOptions {
        var options = PathOptions(path: nil, json: false)
        for argument in arguments {
            if argument == "--json" {
                options.json = true
            } else if options.path == nil {
                options.path = argument
            } else {
                eprint("Ignoring extra validate argument: \(argument)")
            }
        }
        return options
    }

    private enum ManifestReadError: Error {
        case readFailed(String)
        case decodeFailed(String)
    }

    private static func validationReport(path: String) throws -> ValidationReport {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        var report = ComfyWorkflowParser().parse(data: data)
        if let graph = report.graph {
            let registry = PluginRegistry()
            report.diagnostics.append(contentsOf: registry.diagnostics(for: graph.requiredCapabilities))
        }
        return report
    }

    private static func manifestValidationReport(path: String) throws -> ManifestValidationReport {
        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            throw ManifestReadError.readFailed("Could not read \(path): \(error.localizedDescription)")
        }

        do {
            let manifest = try JSONDecoder().decode(PitbossModelManifest.self, from: data)
            return PitbossModelManifestValidator().validate(manifest)
        } catch {
            throw ManifestReadError.decodeFailed("Could not decode \(path): \(error.localizedDescription)")
        }
    }

    private static func printHumanValidation(path: String, report: ValidationReport) {
        if let graph = report.graph {
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
    }

    private static func printHumanManifestValidation(path: String, report: ManifestValidationReport) {
        if let manifest = report.manifest {
            print("Manifest: \(path)")
            print("Bundle: \(manifest.bundleId)")
            print("Model family: \(manifest.modelFamily.rawValue)")
            print("Pipelines:")
            for pipeline in manifest.pipelineTypes {
                print("  - \(pipeline.rawValue)")
            }
            print("Assets: \(manifest.assets.count)")
            print("Modules: \(manifest.modules.count)")
            print("Tokenizers: \(manifest.tokenizerRequirements.count)")
            print("Backend artifacts: \(manifest.backendArtifacts.count)")
        }

        if report.diagnostics.isEmpty {
            print("Diagnostics: none")
            return
        }

        print("Diagnostics:")
        for diagnostic in report.diagnostics {
            print("  - \(diagnostic)")
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

    private static func printJSON<T: Encodable>(_ value: T) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(value)
            if let string = String(data: data, encoding: .utf8) {
                print(string)
            }
        } catch {
            eprint("Could not encode JSON: \(error.localizedDescription)")
            Foundation.exit(70)
        }
    }

    private static func eprint(_ message: String) {
        if let data = "\(message)\n".data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}
