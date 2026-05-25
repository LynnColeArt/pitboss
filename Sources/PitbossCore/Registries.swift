import Foundation

public struct BackendDescriptor: Codable, Equatable, Sendable {
    public var id: String
    public var platform: String
    public var deviceType: String
    public var capabilities: [Capability]
    public var supportsMemoryEstimates: Bool
    public var executionStatus: String
    public var diagnosticStatus: Diagnostic

    public init(
        id: String,
        platform: String,
        deviceType: String,
        capabilities: [Capability],
        supportsMemoryEstimates: Bool,
        executionStatus: String,
        diagnosticStatus: Diagnostic
    ) {
        self.id = id
        self.platform = platform
        self.deviceType = deviceType
        self.capabilities = capabilities
        self.supportsMemoryEstimates = supportsMemoryEstimates
        self.executionStatus = executionStatus
        self.diagnosticStatus = diagnosticStatus
    }
}

public struct PluginRegistry: Sendable {
    public var plugins: [PluginDescriptor]

    public init(plugins: [PluginDescriptor] = PluginRegistry.builtIns) {
        self.plugins = plugins
    }

    public func pluginProviding(_ capability: Capability) -> PluginDescriptor? {
        plugins.first { plugin in
            plugin.capabilitiesProvided.contains { $0.namespace == capability.namespace && $0.name == capability.name }
        }
    }

    public func diagnostics(for requiredCapabilities: [Capability]) -> [Diagnostic] {
        requiredCapabilities.compactMap { capability in
            guard pluginProviding(capability) == nil else { return nil }
            return Diagnostic(
                severity: .error,
                code: "PITBOSS_CAPABILITY_MISSING",
                message: "No registered plugin provides capability \(capability.description).",
                suggestedFix: "Install or enable a plugin that provides \(capability.description)."
            )
        }
    }

    public static let builtIns: [PluginDescriptor] = [
        PluginDescriptor(
            id: "pitboss.compat.comfy",
            displayName: "Comfy Workflow Importer",
            version: "0.1.0",
            kind: .compatibility,
            capabilitiesProvided: [.parse("workflow.import.comfy")],
            nodesProvided: [
                NodeDescriptor(type: "compat.comfy.import", displayName: "Comfy Import")
            ],
            diagnosticsHooks: ["unsupported-node", "missing-capability"]
        ),
        PluginDescriptor(
            id: "pitboss.model.sdxl.stub",
            displayName: "SDXL Contract Stub",
            version: "0.1.0",
            kind: .modelFamily,
            capabilitiesProvided: [
                .parse("model.family.sdxl"),
                .parse("pipeline.text2image")
            ],
            nodesProvided: [
                NodeDescriptor(type: "model.checkpoint.load", displayName: "Checkpoint Loader"),
                NodeDescriptor(type: "conditioning.clip.text", displayName: "CLIP Text Encode"),
                NodeDescriptor(type: "latent.empty-image", displayName: "Empty Latent Image"),
                NodeDescriptor(type: "sampler.k-diffusion", displayName: "KSampler"),
                NodeDescriptor(type: "vae.decode", displayName: "VAE Decode"),
                NodeDescriptor(type: "image.save", displayName: "Save Image")
            ],
            assetTypesSupported: ["checkpoint", "vae", "clip-tokenizer"]
        ),
        PluginDescriptor(
            id: "pitboss.adapter.lora.stub",
            displayName: "LoRA Contract Stub",
            version: "0.1.0",
            kind: .feature,
            capabilitiesProvided: [.parse("adapter.lora")],
            nodesProvided: [
                NodeDescriptor(type: "adapter.lora.load", displayName: "LoRA Loader")
            ],
            assetTypesSupported: ["lora"]
        ),
        PluginDescriptor(
            id: "pitboss.conditioning.controlnet.stub",
            displayName: "ControlNet Contract Stub",
            version: "0.1.0",
            kind: .feature,
            capabilitiesProvided: [.parse("conditioning.controlnet")],
            nodesProvided: [
                NodeDescriptor(type: "conditioning.controlnet.load", displayName: "ControlNet Loader"),
                NodeDescriptor(type: "conditioning.controlnet.apply", displayName: "Apply ControlNet")
            ],
            assetTypesSupported: ["controlnet"]
        )
    ]
}

public struct BackendRegistry: Sendable {
    public var backends: [BackendDescriptor]

    public init(backends: [BackendDescriptor] = []) {
        self.backends = backends
    }

    public func backendProviding(_ capability: Capability) -> BackendDescriptor? {
        backends.first { backend in
            backend.capabilities.contains { $0.namespace == capability.namespace && $0.name == capability.name }
        }
    }
}
