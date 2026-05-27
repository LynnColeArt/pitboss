import Foundation
import PitbossCore
import XCTest

final class CoreTypesTests: XCTestCase {
    func testCapabilityParsingSplitsNamespaceAndName() {
        let capability = Capability.parse("workflow.import.comfy")

        XCTAssertEqual(capability.namespace, "workflow.import")
        XCTAssertEqual(capability.name, "comfy")
        XCTAssertEqual(capability.description, "workflow.import.comfy")
    }

    func testBuiltInRegistryProvidesExpectedCapabilities() {
        let registry = PluginRegistry()

        XCTAssertNotNil(registry.pluginProviding(.parse("workflow.import.comfy")))
        XCTAssertNotNil(registry.pluginProviding(.parse("adapter.lora")))
        XCTAssertNil(registry.pluginProviding(.parse("backend.coreml")))
    }

    func testModelManifestFixtureDecodes() throws {
        let manifestURL = try fixtureURL("Fixtures/manifests/sdxl-coreml-example.json")
        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(PitbossModelManifest.self, from: data)

        XCTAssertEqual(manifest.bundleId, "org.pitboss.example.sdxl-coreml")
        XCTAssertEqual(manifest.modelFamily, .sdxl)
        XCTAssertEqual(manifest.backendArtifacts.first?.kind, .coreml)
    }

    func testValidModelManifestHasNoValidationDiagnostics() throws {
        let manifest = try decodeManifest("Fixtures/manifests/sdxl-coreml-example.json")
        let report = PitbossModelManifestValidator().validate(manifest)

        XCTAssertFalse(report.hasErrors)
        XCTAssertTrue(report.diagnostics.isEmpty, "Expected no diagnostics, got \(report.diagnostics)")
    }

    func testManifestValidatorCatchesUnknownBackendArtifactModule() throws {
        let manifest = try decodeManifest("Fixtures/manifests/invalid-artifact-unknown-module.json")
        let report = PitbossModelManifestValidator().validate(manifest)

        XCTAssertTrue(report.hasErrors)
        XCTAssertTrue(report.diagnostics.map(\.code).contains("PITBOSS_MANIFEST_BACKEND_ARTIFACT_UNKNOWN_MODULE"))
    }

    func testManifestValidatorCatchesIncompleteClipBPETokenizer() throws {
        let manifest = try decodeManifest("Fixtures/manifests/invalid-tokenizer-clip-bpe.json")
        let codes = PitbossModelManifestValidator().validate(manifest).diagnostics.map(\.code)

        XCTAssertTrue(codes.contains("PITBOSS_MANIFEST_TOKENIZER_USAGE_EMPTY"))
        XCTAssertTrue(codes.contains("PITBOSS_MANIFEST_CLIP_BPE_VOCAB_MISSING"))
        XCTAssertTrue(codes.contains("PITBOSS_MANIFEST_CLIP_BPE_MERGES_MISSING"))
    }

    func testManifestValidatorCatchesUnknownCapability() throws {
        let manifest = try decodeManifest("Fixtures/manifests/invalid-unknown-capability.json")
        let report = PitbossModelManifestValidator().validate(manifest)

        XCTAssertTrue(report.hasErrors)
        XCTAssertTrue(report.diagnostics.map(\.code).contains("PITBOSS_MANIFEST_UNKNOWN_CAPABILITY"))
    }

    func testManifestValidationSummaryIsAgentReadable() throws {
        let manifest = try decodeManifest("Fixtures/manifests/invalid-unknown-capability.json")
        let report = PitbossModelManifestValidator().validate(manifest)
        let summary = ManifestValidationSummary(manifestPath: "Fixtures/manifests/invalid-unknown-capability.json", report: report)
        let data = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(ManifestValidationSummary.self, from: data)

        XCTAssertEqual(decoded.schemaVersion, "pitboss.manifest-validation.v1")
        XCTAssertEqual(decoded.bundleId, "org.pitboss.invalid.unknown-capability")
        XCTAssertEqual(decoded.modelFamily, "sdxl")
        XCTAssertEqual(decoded.moduleCount, 1)
        XCTAssertTrue(decoded.hasErrors)
    }

    func testPolicyScannerIgnoresDocumentationButChecksRuntimeSource() throws {
        let scanner = ZeroPythonPolicyScanner()
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let findings = scanner.scan(root: root)

        XCTAssertTrue(findings.isEmpty, "Expected no runtime policy findings, got \(findings)")
    }

    func testValidationSummaryIsAgentReadable() throws {
        let graph = Graph(
            nodes: [
                GraphNode(
                    id: "1",
                    type: "conditioning.clip.text",
                    displayName: "CLIPTextEncode",
                    requiredCapabilities: [.parse("model.family.sdxl")],
                    pluginProvider: "pitboss.model.sdxl.stub",
                    source: SourceNodeMetadata(format: "comfy.api", nodeID: "1", nodeType: "CLIPTextEncode")
                )
            ],
            edges: [],
            requiredCapabilities: [.parse("model.family.sdxl")],
            workflowProvenance: WorkflowProvenance(sourceFormat: "comfy.api", sourceVersion: nil)
        )
        let report = ValidationReport(
            graph: graph,
            diagnostics: [
                Diagnostic(severity: .warning, code: "PITBOSS_TEST_WARNING", message: "Fixture warning.")
            ]
        )

        let summary = ValidationSummary(workflowPath: "Fixtures/comfy/basic-api-workflow.json", report: report)
        let data = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(ValidationSummary.self, from: data)

        XCTAssertEqual(decoded.schemaVersion, "pitboss.validation.v1")
        XCTAssertEqual(decoded.sourceFormat, "comfy.api")
        XCTAssertEqual(decoded.graph?.nodeCount, 1)
        XCTAssertEqual(decoded.graph?.nodes.first?.sourceNodeType, "CLIPTextEncode")
        XCTAssertEqual(decoded.graph?.requiredCapabilities, ["model.family.sdxl"])
        XCTAssertFalse(decoded.hasErrors)
    }

    private func fixtureURL(_ relativePath: String) throws -> URL {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return root.appendingPathComponent(relativePath)
    }

    private func decodeManifest(_ relativePath: String) throws -> PitbossModelManifest {
        let data = try Data(contentsOf: try fixtureURL(relativePath))
        return try JSONDecoder().decode(PitbossModelManifest.self, from: data)
    }
}
