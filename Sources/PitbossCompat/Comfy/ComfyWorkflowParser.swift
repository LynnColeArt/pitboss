import Foundation
import PitbossCore

public struct ComfyWorkflowParser: Sendable {
    public init() {}

    public func parse(data: Data) -> ValidationReport {
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            if let object = json as? [String: Any], let nodes = object["nodes"] as? [[String: Any]] {
                return parseVisualWorkflow(object: object, nodes: nodes)
            }
            if let object = json as? [String: Any] {
                return parseAPIPrompt(object)
            }
            return ValidationReport(
                graph: nil,
                diagnostics: [Diagnostic(severity: .error, code: "PITBOSS_COMFY_INVALID_JSON", message: "Expected a Comfy workflow object.")]
            )
        } catch {
            return ValidationReport(
                graph: nil,
                diagnostics: [Diagnostic(severity: .error, code: "PITBOSS_COMFY_PARSE_FAILED", message: error.localizedDescription)]
            )
        }
    }

    private func parseVisualWorkflow(object: [String: Any], nodes rawNodes: [[String: Any]]) -> ValidationReport {
        var diagnostics: [Diagnostic] = []
        var graphNodes: [GraphNode] = []
        var graphEdges: [GraphEdge] = []

        for rawNode in rawNodes {
            let sourceID = String(describing: rawNode["id"] ?? UUID().uuidString)
            let sourceType = (rawNode["type"] as? String) ?? "Unknown"
            let mapping = mapComfyType(sourceType)
            if mapping.isSupported == false {
                diagnostics.append(unsupportedNodeDiagnostic(nodeID: sourceID, nodeType: sourceType))
            }

            graphNodes.append(GraphNode(
                id: sourceID,
                type: mapping.internalType,
                displayName: sourceType,
                inputs: parseVisualInputs(rawNode["inputs"] as? [[String: Any]]),
                outputs: parseVisualOutputs(rawNode["outputs"] as? [[String: Any]]),
                parameters: parseWidgetValues(rawNode["widgets_values"]),
                requiredCapabilities: mapping.capabilities,
                pluginProvider: mapping.pluginProvider,
                source: SourceNodeMetadata(format: "comfy.workflow", nodeID: sourceID, nodeType: sourceType)
            ))
        }

        if let links = object["links"] as? [[Any]] {
            graphEdges = parseVisualLinks(links, nodes: rawNodes)
        }

        let graph = Graph(
            nodes: graphNodes,
            edges: graphEdges,
            requiredCapabilities: uniqueCapabilities(graphNodes.flatMap(\.requiredCapabilities)),
            workflowProvenance: WorkflowProvenance(sourceFormat: "comfy.workflow", sourceVersion: object["version"].map { String(describing: $0) })
        )
        return ValidationReport(graph: graph, diagnostics: diagnostics)
    }

    private func parseAPIPrompt(_ object: [String: Any]) -> ValidationReport {
        var diagnostics: [Diagnostic] = []
        var graphNodes: [GraphNode] = []
        var graphEdges: [GraphEdge] = []

        for key in object.keys.sorted(by: numericStringSort) {
            guard let nodeObject = object[key] as? [String: Any] else { continue }
            let sourceType = (nodeObject["class_type"] as? String) ?? "Unknown"
            let mapping = mapComfyType(sourceType)
            if mapping.isSupported == false {
                diagnostics.append(unsupportedNodeDiagnostic(nodeID: key, nodeType: sourceType))
            }

            let parsedInputs = parseAPIInputs(nodeObject["inputs"] as? [String: Any], nodeID: key, edges: &graphEdges)
            graphNodes.append(GraphNode(
                id: key,
                type: mapping.internalType,
                displayName: sourceType,
                inputs: parsedInputs.inputs,
                outputs: [],
                parameters: parsedInputs.parameters,
                requiredCapabilities: mapping.capabilities,
                pluginProvider: mapping.pluginProvider,
                source: SourceNodeMetadata(format: "comfy.api", nodeID: key, nodeType: sourceType)
            ))
        }

        let graph = Graph(
            nodes: graphNodes,
            edges: graphEdges,
            requiredCapabilities: uniqueCapabilities(graphNodes.flatMap(\.requiredCapabilities)),
            workflowProvenance: WorkflowProvenance(sourceFormat: "comfy.api", sourceVersion: nil)
        )
        return ValidationReport(graph: graph, diagnostics: diagnostics)
    }

    private func parseVisualInputs(_ inputs: [[String: Any]]?) -> [String: GraphValue] {
        var values: [String: GraphValue] = [:]
        for input in inputs ?? [] {
            guard let name = input["name"] as? String else { continue }
            if let link = input["link"] as? Int {
                values[name] = .int(link)
            } else {
                values[name] = .null
            }
        }
        return values
    }

    private func parseVisualOutputs(_ outputs: [[String: Any]]?) -> [String] {
        (outputs ?? []).compactMap { $0["name"] as? String }
    }

    private func parseWidgetValues(_ raw: Any?) -> [String: GraphValue] {
        guard let values = raw as? [Any] else { return [:] }
        var parameters: [String: GraphValue] = [:]
        for (index, value) in values.enumerated() {
            parameters["widget_\(index)"] = graphValue(value)
        }
        return parameters
    }

    private func parseVisualLinks(_ links: [[Any]], nodes: [[String: Any]]) -> [GraphEdge] {
        var inputNamesByNodeAndSlot: [String: [Int: String]] = [:]
        for rawNode in nodes {
            let nodeID = String(describing: rawNode["id"] ?? "")
            let inputs = rawNode["inputs"] as? [[String: Any]] ?? []
            inputNamesByNodeAndSlot[nodeID] = Dictionary(uniqueKeysWithValues: inputs.enumerated().map { ($0.offset, ($0.element["name"] as? String) ?? "input_\($0.offset)") })
        }

        return links.compactMap { link in
            guard link.count >= 6 else { return nil }
            let fromNode = String(describing: link[1])
            let fromOutput = "output_\(String(describing: link[2]))"
            let toNode = String(describing: link[3])
            let toSlot = Int(String(describing: link[4])) ?? 0
            let toInput = inputNamesByNodeAndSlot[toNode]?[toSlot] ?? "input_\(toSlot)"
            return GraphEdge(fromNode: fromNode, fromOutput: fromOutput, toNode: toNode, toInput: toInput)
        }
    }

    private func parseAPIInputs(
        _ inputs: [String: Any]?,
        nodeID: String,
        edges: inout [GraphEdge]
    ) -> (inputs: [String: GraphValue], parameters: [String: GraphValue]) {
        var graphInputs: [String: GraphValue] = [:]
        var parameters: [String: GraphValue] = [:]

        for (name, value) in inputs ?? [:] {
            if let edge = apiConnection(value) {
                graphInputs[name] = .connection(nodeID: edge.nodeID, outputIndex: edge.outputIndex)
                edges.append(GraphEdge(fromNode: edge.nodeID, fromOutput: "output_\(edge.outputIndex)", toNode: nodeID, toInput: name))
            } else {
                parameters[name] = graphValue(value)
            }
        }

        return (graphInputs, parameters)
    }

    private func apiConnection(_ value: Any) -> (nodeID: String, outputIndex: Int)? {
        guard let array = value as? [Any], array.count == 2 else { return nil }
        if let nodeID = array[0] as? String, let outputIndex = array[1] as? Int {
            return (nodeID, outputIndex)
        }
        return nil
    }

    private func graphValue(_ value: Any?) -> GraphValue {
        switch value {
        case let value as String: return .string(value)
        case let value as Int: return .int(value)
        case let value as Double: return .double(value)
        case let value as Bool: return .bool(value)
        case let value as [String]: return .stringArray(value)
        case let value as [String: Any]:
            return .object(value.mapValues { graphValue($0) })
        case nil: return .null
        default: return .string(String(describing: value ?? "null"))
        }
    }

    private struct Mapping {
        var internalType: String
        var capabilities: [Capability]
        var pluginProvider: String?
        var isSupported: Bool
    }

    private func mapComfyType(_ type: String) -> Mapping {
        let normalized = type.lowercased()
        let sdxl = Capability.parse("model.family.sdxl")
        let textToImage = Capability.parse("pipeline.text2image")

        if normalized.contains("checkpoint") {
            return Mapping(internalType: "model.checkpoint.load", capabilities: [sdxl], pluginProvider: "pitboss.model.sdxl.stub", isSupported: true)
        }
        if normalized.contains("cliptextencode") || normalized.contains("clip text encode") {
            return Mapping(internalType: "conditioning.clip.text", capabilities: [sdxl], pluginProvider: "pitboss.model.sdxl.stub", isSupported: true)
        }
        if normalized.contains("emptylatent") || normalized.contains("empty latent") {
            return Mapping(internalType: "latent.empty-image", capabilities: [textToImage], pluginProvider: "pitboss.model.sdxl.stub", isSupported: true)
        }
        if normalized.contains("ksampler") {
            return Mapping(internalType: "sampler.k-diffusion", capabilities: [textToImage], pluginProvider: "pitboss.model.sdxl.stub", isSupported: true)
        }
        if normalized.contains("vaedecode") || normalized.contains("vae decode") {
            return Mapping(internalType: "vae.decode", capabilities: [sdxl], pluginProvider: "pitboss.model.sdxl.stub", isSupported: true)
        }
        if normalized.contains("saveimage") || normalized.contains("save image") {
            return Mapping(internalType: "image.save", capabilities: [], pluginProvider: "pitboss.model.sdxl.stub", isSupported: true)
        }
        if normalized.contains("loraloader") || normalized.contains("lora loader") {
            return Mapping(internalType: "adapter.lora.load", capabilities: [.parse("adapter.lora")], pluginProvider: "pitboss.adapter.lora.stub", isSupported: true)
        }
        if normalized.contains("controlnetloader") || normalized.contains("controlnet loader") {
            return Mapping(internalType: "conditioning.controlnet.load", capabilities: [.parse("conditioning.controlnet")], pluginProvider: "pitboss.conditioning.controlnet.stub", isSupported: true)
        }
        if normalized.contains("controlnetapply") || normalized.contains("apply controlnet") {
            return Mapping(internalType: "conditioning.controlnet.apply", capabilities: [.parse("conditioning.controlnet")], pluginProvider: "pitboss.conditioning.controlnet.stub", isSupported: true)
        }
        if normalized.contains("loadimage") || normalized.contains("load image") {
            return Mapping(internalType: "image.load", capabilities: [], pluginProvider: nil, isSupported: true)
        }
        if normalized.contains("vaeencode") || normalized.contains("vae encode") {
            return Mapping(internalType: "vae.encode", capabilities: [sdxl], pluginProvider: "pitboss.model.sdxl.stub", isSupported: true)
        }
        if normalized.contains("inpaint") {
            return Mapping(internalType: "conditioning.inpaint", capabilities: [textToImage], pluginProvider: "pitboss.model.sdxl.stub", isSupported: true)
        }

        return Mapping(internalType: "compat.comfy.unsupported", capabilities: [], pluginProvider: nil, isSupported: false)
    }

    private func unsupportedNodeDiagnostic(nodeID: String, nodeType: String) -> Diagnostic {
        Diagnostic(
            severity: .error,
            code: "PITBOSS_COMFY_UNSUPPORTED_NODE",
            message: "Unsupported Comfy node '\(nodeType)'.",
            nodeID: nodeID,
            suggestedFix: "Replace the node with a supported core concept or add a plugin that declares this node type."
        )
    }

    private func uniqueCapabilities(_ capabilities: [Capability]) -> [Capability] {
        Array(Set(capabilities)).sorted { $0.description < $1.description }
    }

    private func numericStringSort(_ lhs: String, _ rhs: String) -> Bool {
        if let left = Int(lhs), let right = Int(rhs) {
            return left < right
        }
        return lhs < rhs
    }
}
