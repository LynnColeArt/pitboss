import Foundation

public struct Capability: Codable, Hashable, Sendable, CustomStringConvertible {
    public var namespace: String
    public var name: String
    public var versionRequirement: String?
    public var metadata: [String: String]

    public init(namespace: String, name: String, versionRequirement: String? = nil, metadata: [String: String] = [:]) {
        self.namespace = namespace
        self.name = name
        self.versionRequirement = versionRequirement
        self.metadata = metadata
    }

    public static func parse(_ rawValue: String) -> Capability {
        let parts = rawValue.split(separator: ".").map(String.init)
        guard parts.count > 1 else {
            return Capability(namespace: "capability", name: rawValue)
        }
        return Capability(namespace: parts.dropLast().joined(separator: "."), name: parts.last ?? rawValue)
    }

    public var description: String {
        let base = "\(namespace).\(name)"
        guard let versionRequirement else { return base }
        return "\(base) \(versionRequirement)"
    }
}

public enum PluginKind: String, Codable, Sendable {
    case feature
    case backend
    case compatibility
    case modelFamily = "model-family"
    case preprocessor
}

public enum Permission: String, Codable, Sendable {
    case readAssets = "read-assets"
    case writeOutputs = "write-outputs"
    case network
    case hardwareAccelerator = "hardware-accelerator"
}

public struct NodeDescriptor: Codable, Hashable, Sendable {
    public var type: String
    public var displayName: String
    public var capabilitiesRequired: [Capability]
    public var inputs: [String]
    public var outputs: [String]

    public init(
        type: String,
        displayName: String,
        capabilitiesRequired: [Capability] = [],
        inputs: [String] = [],
        outputs: [String] = []
    ) {
        self.type = type
        self.displayName = displayName
        self.capabilitiesRequired = capabilitiesRequired
        self.inputs = inputs
        self.outputs = outputs
    }
}

public struct PluginDescriptor: Codable, Hashable, Sendable {
    public var id: String
    public var displayName: String
    public var version: String
    public var kind: PluginKind
    public var capabilitiesProvided: [Capability]
    public var permissionsRequested: [Permission]
    public var nodesProvided: [NodeDescriptor]
    public var assetTypesSupported: [String]
    public var diagnosticsHooks: [String]

    public init(
        id: String,
        displayName: String,
        version: String,
        kind: PluginKind,
        capabilitiesProvided: [Capability],
        permissionsRequested: [Permission] = [],
        nodesProvided: [NodeDescriptor] = [],
        assetTypesSupported: [String] = [],
        diagnosticsHooks: [String] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.version = version
        self.kind = kind
        self.capabilitiesProvided = capabilitiesProvided
        self.permissionsRequested = permissionsRequested
        self.nodesProvided = nodesProvided
        self.assetTypesSupported = assetTypesSupported
        self.diagnosticsHooks = diagnosticsHooks
    }
}

public struct Graph: Codable, Equatable, Sendable {
    public var nodes: [GraphNode]
    public var edges: [GraphEdge]
    public var inputs: [String]
    public var outputs: [String]
    public var requiredCapabilities: [Capability]
    public var assetReferences: [AssetRef]
    public var deterministicMetadata: DeterministicMetadata
    public var workflowProvenance: WorkflowProvenance

    public init(
        nodes: [GraphNode] = [],
        edges: [GraphEdge] = [],
        inputs: [String] = [],
        outputs: [String] = [],
        requiredCapabilities: [Capability] = [],
        assetReferences: [AssetRef] = [],
        deterministicMetadata: DeterministicMetadata = DeterministicMetadata(),
        workflowProvenance: WorkflowProvenance = WorkflowProvenance(sourceFormat: "native", sourceVersion: nil)
    ) {
        self.nodes = nodes
        self.edges = edges
        self.inputs = inputs
        self.outputs = outputs
        self.requiredCapabilities = requiredCapabilities
        self.assetReferences = assetReferences
        self.deterministicMetadata = deterministicMetadata
        self.workflowProvenance = workflowProvenance
    }
}

public struct GraphNode: Codable, Equatable, Sendable {
    public var id: String
    public var type: String
    public var displayName: String
    public var inputs: [String: GraphValue]
    public var outputs: [String]
    public var parameters: [String: GraphValue]
    public var requiredCapabilities: [Capability]
    public var pluginProvider: String?
    public var source: SourceNodeMetadata?

    public init(
        id: String,
        type: String,
        displayName: String,
        inputs: [String: GraphValue] = [:],
        outputs: [String] = [],
        parameters: [String: GraphValue] = [:],
        requiredCapabilities: [Capability] = [],
        pluginProvider: String? = nil,
        source: SourceNodeMetadata? = nil
    ) {
        self.id = id
        self.type = type
        self.displayName = displayName
        self.inputs = inputs
        self.outputs = outputs
        self.parameters = parameters
        self.requiredCapabilities = requiredCapabilities
        self.pluginProvider = pluginProvider
        self.source = source
    }
}

public struct GraphEdge: Codable, Equatable, Sendable {
    public var fromNode: String
    public var fromOutput: String
    public var toNode: String
    public var toInput: String

    public init(fromNode: String, fromOutput: String, toNode: String, toInput: String) {
        self.fromNode = fromNode
        self.fromOutput = fromOutput
        self.toNode = toNode
        self.toInput = toInput
    }
}

public enum GraphValue: Codable, Equatable, Sendable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case stringArray([String])
    case connection(nodeID: String, outputIndex: Int)
    case object([String: GraphValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String].self) {
            self = .stringArray(value)
        } else if let value = try? container.decode([String: GraphValue].self) {
            self = .object(value)
        } else {
            self = .string("<unsupported-json-value>")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .stringArray(let value): try container.encode(value)
        case .connection(let nodeID, let outputIndex): try container.encode(["nodeID": nodeID, "outputIndex": String(outputIndex)])
        case .object(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    public var description: String {
        switch self {
        case .string(let value): value
        case .int(let value): String(value)
        case .double(let value): String(value)
        case .bool(let value): String(value)
        case .stringArray(let value): value.joined(separator: ", ")
        case .connection(let nodeID, let outputIndex): "\(nodeID)[\(outputIndex)]"
        case .object: "<object>"
        case .null: "null"
        }
    }
}

public struct SourceNodeMetadata: Codable, Equatable, Sendable {
    public var format: String
    public var nodeID: String
    public var nodeType: String

    public init(format: String, nodeID: String, nodeType: String) {
        self.format = format
        self.nodeID = nodeID
        self.nodeType = nodeType
    }
}

public struct AssetRef: Codable, Equatable, Sendable {
    public var id: String
    public var type: String
    public var path: String
    public var checksum: String?
    public var format: String
    public var metadata: [String: String]
    public var provenance: String?
    public var requiredCapabilities: [Capability]

    public init(
        id: String,
        type: String,
        path: String,
        checksum: String? = nil,
        format: String,
        metadata: [String: String] = [:],
        provenance: String? = nil,
        requiredCapabilities: [Capability] = []
    ) {
        self.id = id
        self.type = type
        self.path = path
        self.checksum = checksum
        self.format = format
        self.metadata = metadata
        self.provenance = provenance
        self.requiredCapabilities = requiredCapabilities
    }
}

public struct DeterministicMetadata: Codable, Equatable, Sendable {
    public var seed: UInt64?
    public var scheduler: String?
    public var precision: String?

    public init(seed: UInt64? = nil, scheduler: String? = nil, precision: String? = nil) {
        self.seed = seed
        self.scheduler = scheduler
        self.precision = precision
    }
}

public struct WorkflowProvenance: Codable, Equatable, Sendable {
    public var sourceFormat: String
    public var sourceVersion: String?
    public var importedAt: Date

    public init(sourceFormat: String, sourceVersion: String?, importedAt: Date = Date()) {
        self.sourceFormat = sourceFormat
        self.sourceVersion = sourceVersion
        self.importedAt = importedAt
    }
}

public enum DiagnosticSeverity: String, Codable, Sendable {
    case info
    case warning
    case error
}

public struct Diagnostic: Codable, Equatable, Sendable, CustomStringConvertible {
    public var severity: DiagnosticSeverity
    public var code: String
    public var message: String
    public var nodeID: String?
    public var pluginID: String?
    public var suggestedFix: String?

    public init(
        severity: DiagnosticSeverity,
        code: String,
        message: String,
        nodeID: String? = nil,
        pluginID: String? = nil,
        suggestedFix: String? = nil
    ) {
        self.severity = severity
        self.code = code
        self.message = message
        self.nodeID = nodeID
        self.pluginID = pluginID
        self.suggestedFix = suggestedFix
    }

    public var description: String {
        var parts = ["[\(severity.rawValue.uppercased())]", code, message]
        if let nodeID { parts.append("node=\(nodeID)") }
        if let pluginID { parts.append("plugin=\(pluginID)") }
        if let suggestedFix { parts.append("fix=\(suggestedFix)") }
        return parts.joined(separator: " ")
    }
}

public struct ValidationReport: Codable, Equatable, Sendable {
    public var graph: Graph?
    public var diagnostics: [Diagnostic]

    public init(graph: Graph?, diagnostics: [Diagnostic] = []) {
        self.graph = graph
        self.diagnostics = diagnostics
    }

    public var hasErrors: Bool {
        diagnostics.contains { $0.severity == .error }
    }
}
