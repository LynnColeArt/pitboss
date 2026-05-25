import Foundation
import PitbossCompat
import PitbossCore
import XCTest

final class ComfyWorkflowParserTests: XCTestCase {
    func testAPIWorkflowMapsKnownNodesAndEdges() throws {
        let data = try Data(contentsOf: fixtureURL("Fixtures/comfy/basic-api-workflow.json"))
        let report = ComfyWorkflowParser().parse(data: data)

        XCTAssertFalse(report.hasErrors, "Unexpected diagnostics: \(report.diagnostics)")
        let graph = try XCTUnwrap(report.graph)
        XCTAssertEqual(graph.nodes.count, 6)
        XCTAssertEqual(graph.edges.count, 7)
        XCTAssertTrue(graph.requiredCapabilities.contains(.parse("workflow.import.comfy")) == false)
        XCTAssertTrue(graph.requiredCapabilities.contains(.parse("model.family.sdxl")))
        XCTAssertTrue(graph.requiredCapabilities.contains(.parse("pipeline.text2image")))
    }

    func testUnsupportedNodeProducesClearDiagnostic() throws {
        let data = try Data(contentsOf: fixtureURL("Fixtures/comfy/unsupported-api-workflow.json"))
        let report = ComfyWorkflowParser().parse(data: data)

        XCTAssertTrue(report.hasErrors)
        XCTAssertEqual(report.diagnostics.first?.code, "PITBOSS_COMFY_UNSUPPORTED_NODE")
        XCTAssertEqual(report.diagnostics.first?.nodeID, "2")
    }

    private func fixtureURL(_ relativePath: String) -> URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(relativePath)
    }
}
