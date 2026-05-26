import Foundation

public struct ValidationSummary: Codable, Equatable, Sendable {
    public var schemaVersion: String
    public var workflowPath: String
    public var sourceFormat: String?
    public var executable: Bool
    public var hasErrors: Bool
    public var graph: ValidationGraphSummary?
    public var diagnostics: [Diagnostic]

    public init(
        workflowPath: String,
        report: ValidationReport,
        executable: Bool = false,
        schemaVersion: String = "pitboss.validation.v1"
    ) {
        self.schemaVersion = schemaVersion
        self.workflowPath = workflowPath
        self.sourceFormat = report.graph?.workflowProvenance.sourceFormat
        self.executable = executable
        self.hasErrors = report.hasErrors
        self.graph = report.graph.map(ValidationGraphSummary.init(graph:))
        self.diagnostics = report.diagnostics
    }
}

public struct ValidationGraphSummary: Codable, Equatable, Sendable {
    public var nodeCount: Int
    public var edgeCount: Int
    public var requiredCapabilities: [String]
    public var nodes: [ValidationNodeSummary]

    public init(graph: Graph) {
        self.nodeCount = graph.nodes.count
        self.edgeCount = graph.edges.count
        self.requiredCapabilities = graph.requiredCapabilities.map(\.description).sorted()
        self.nodes = graph.nodes.map(ValidationNodeSummary.init(node:))
    }
}

public struct ValidationNodeSummary: Codable, Equatable, Sendable {
    public var id: String
    public var type: String
    public var displayName: String
    public var sourceFormat: String?
    public var sourceNodeType: String?
    public var pluginProvider: String?
    public var requiredCapabilities: [String]

    public init(node: GraphNode) {
        self.id = node.id
        self.type = node.type
        self.displayName = node.displayName
        self.sourceFormat = node.source?.format
        self.sourceNodeType = node.source?.nodeType
        self.pluginProvider = node.pluginProvider
        self.requiredCapabilities = node.requiredCapabilities.map(\.description).sorted()
    }
}
