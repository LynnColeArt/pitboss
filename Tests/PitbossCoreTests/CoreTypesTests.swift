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

    func testPolicyScannerIgnoresDocumentationButChecksRuntimeSource() throws {
        let scanner = ZeroPythonPolicyScanner()
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let findings = scanner.scan(root: root)

        XCTAssertTrue(findings.isEmpty, "Expected no runtime policy findings, got \(findings)")
    }

    private func fixtureURL(_ relativePath: String) throws -> URL {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return root.appendingPathComponent(relativePath)
    }
}
