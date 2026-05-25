import Foundation

public struct PitbossModelManifest: Codable, Equatable, Sendable {
    public var manifestVersion: String
    public var bundleId: String
    public var displayName: String
    public var modelFamily: ModelFamily
    public var pipelineTypes: [PipelineType]
    public var assets: [ManifestAsset]
    public var modules: [ManifestModule]
    public var tokenizerRequirements: [TokenizerRequirement]
    public var schedulerDefaults: SchedulerDefaults
    public var adapterSupport: AdapterSupport
    public var controlSupport: ControlSupport
    public var backendArtifacts: [BackendArtifact]
    public var minimumRuntimeVersion: String
    public var provenance: ManifestProvenance

    public init(
        manifestVersion: String,
        bundleId: String,
        displayName: String,
        modelFamily: ModelFamily,
        pipelineTypes: [PipelineType],
        assets: [ManifestAsset],
        modules: [ManifestModule],
        tokenizerRequirements: [TokenizerRequirement],
        schedulerDefaults: SchedulerDefaults,
        adapterSupport: AdapterSupport,
        controlSupport: ControlSupport,
        backendArtifacts: [BackendArtifact],
        minimumRuntimeVersion: String,
        provenance: ManifestProvenance
    ) {
        self.manifestVersion = manifestVersion
        self.bundleId = bundleId
        self.displayName = displayName
        self.modelFamily = modelFamily
        self.pipelineTypes = pipelineTypes
        self.assets = assets
        self.modules = modules
        self.tokenizerRequirements = tokenizerRequirements
        self.schedulerDefaults = schedulerDefaults
        self.adapterSupport = adapterSupport
        self.controlSupport = controlSupport
        self.backendArtifacts = backendArtifacts
        self.minimumRuntimeVersion = minimumRuntimeVersion
        self.provenance = provenance
    }
}

public enum ModelFamily: String, Codable, Sendable {
    case sd15
    case sdxl
    case flux
    case stableAudio = "stable-audio"
    case videoTemporal = "video-temporal"
}

public enum PipelineType: String, Codable, Sendable {
    case textToImage = "text-to-image"
    case imageToImage = "image-to-image"
    case inpainting
    case audio
    case video
}

public struct ManifestAsset: Codable, Equatable, Sendable {
    public var id: String
    public var type: String
    public var path: String
    public var format: String
    public var sha256: String?
}

public struct ManifestModule: Codable, Equatable, Sendable {
    public var id: String
    public var role: String
    public var requiredCapabilities: [Capability]
}

public struct TokenizerRequirement: Codable, Equatable, Sendable {
    public var id: String
    public var kind: String
    public var vocabularyPath: String?
    public var mergesPath: String?
    public var requiredFor: [String]
}

public struct SchedulerDefaults: Codable, Equatable, Sendable {
    public var scheduler: String
    public var steps: Int
    public var guidanceScale: Double?
}

public struct AdapterSupport: Codable, Equatable, Sendable {
    public var supportsLoRA: Bool
    public var composition: String?
    public var maxAdapters: Int?
}

public struct ControlSupport: Codable, Equatable, Sendable {
    public var supportsControlNet: Bool
    public var supportedControlTypes: [String]
}

public struct BackendArtifact: Codable, Equatable, Sendable {
    public var kind: BackendArtifactKind
    public var moduleId: String
    public var path: String
    public var precision: String?
}

public enum BackendArtifactKind: String, Codable, Sendable {
    case coreml
    case mlx
    case safetensors
    case gguf
    case onnx
    case native
}

public struct ManifestProvenance: Codable, Equatable, Sendable {
    public var source: String
    public var license: String?
    public var conversionTool: String?
    public var notes: String?
}
