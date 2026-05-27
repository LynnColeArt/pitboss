import Foundation

public struct ManifestValidationReport: Codable, Equatable, Sendable {
    public var manifest: PitbossModelManifest?
    public var diagnostics: [Diagnostic]

    public init(manifest: PitbossModelManifest?, diagnostics: [Diagnostic] = []) {
        self.manifest = manifest
        self.diagnostics = diagnostics
    }

    public var hasErrors: Bool {
        diagnostics.contains { $0.severity == .error }
    }
}

public struct ManifestValidationSummary: Codable, Equatable, Sendable {
    public var schemaVersion: String
    public var manifestPath: String
    public var bundleId: String?
    public var modelFamily: String?
    public var pipelineTypes: [String]
    public var assetCount: Int
    public var moduleCount: Int
    public var tokenizerCount: Int
    public var backendArtifactCount: Int
    public var hasErrors: Bool
    public var diagnostics: [Diagnostic]

    public init(
        manifestPath: String,
        report: ManifestValidationReport,
        schemaVersion: String = "pitboss.manifest-validation.v1"
    ) {
        self.schemaVersion = schemaVersion
        self.manifestPath = manifestPath
        self.bundleId = report.manifest?.bundleId
        self.modelFamily = report.manifest?.modelFamily.rawValue
        self.pipelineTypes = report.manifest?.pipelineTypes.map(\.rawValue).sorted() ?? []
        self.assetCount = report.manifest?.assets.count ?? 0
        self.moduleCount = report.manifest?.modules.count ?? 0
        self.tokenizerCount = report.manifest?.tokenizerRequirements.count ?? 0
        self.backendArtifactCount = report.manifest?.backendArtifacts.count ?? 0
        self.hasErrors = report.hasErrors
        self.diagnostics = report.diagnostics
    }
}

public struct PitbossModelManifestValidator: Sendable {
    private let knownCapabilities: Set<Capability>

    public init(knownCapabilities: Set<Capability> = PitbossModelManifestValidator.defaultKnownCapabilities) {
        self.knownCapabilities = knownCapabilities
    }

    public func validate(_ manifest: PitbossModelManifest) -> ManifestValidationReport {
        var diagnostics: [Diagnostic] = []

        diagnostics.append(contentsOf: validateRequiredText(manifest))
        diagnostics.append(contentsOf: validateCollections(manifest))
        diagnostics.append(contentsOf: validateAssets(manifest.assets))
        diagnostics.append(contentsOf: validateModules(manifest.modules))
        diagnostics.append(contentsOf: validateTokenizers(manifest.tokenizerRequirements))
        diagnostics.append(contentsOf: validateBackendArtifacts(manifest.backendArtifacts, modules: manifest.modules))
        diagnostics.append(contentsOf: validateScheduler(manifest.schedulerDefaults))
        diagnostics.append(contentsOf: validateAdapterSupport(manifest.adapterSupport))
        diagnostics.append(contentsOf: validateControlSupport(manifest.controlSupport))

        return ManifestValidationReport(manifest: manifest, diagnostics: diagnostics)
    }

    public static let defaultKnownCapabilities: Set<Capability> = Set(
        PluginRegistry.builtIns.flatMap(\.capabilitiesProvided) + [
            .parse("backend.coreml"),
            .parse("backend.mlx"),
            .parse("backend.safetensors"),
            .parse("backend.gguf"),
            .parse("backend.onnx"),
            .parse("backend.native")
        ]
    )

    private func validateRequiredText(_ manifest: PitbossModelManifest) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        diagnostics.append(contentsOf: requiredText(manifest.manifestVersion, field: "manifestVersion"))
        diagnostics.append(contentsOf: requiredText(manifest.bundleId, field: "bundleId"))
        diagnostics.append(contentsOf: requiredText(manifest.displayName, field: "displayName"))
        diagnostics.append(contentsOf: requiredText(manifest.minimumRuntimeVersion, field: "minimumRuntimeVersion"))
        diagnostics.append(contentsOf: requiredText(manifest.provenance.source, field: "provenance.source"))
        return diagnostics
    }

    private func validateCollections(_ manifest: PitbossModelManifest) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        if manifest.pipelineTypes.isEmpty {
            diagnostics.append(error(
                "PITBOSS_MANIFEST_PIPELINES_EMPTY",
                "Manifest must declare at least one pipeline type.",
                "Add a pipeline type such as text-to-image, image-to-image, audio, or video."
            ))
        }
        if manifest.assets.isEmpty {
            diagnostics.append(error(
                "PITBOSS_MANIFEST_ASSETS_EMPTY",
                "Manifest must declare at least one asset.",
                "Add assets for model files, tokenizers, adapters, or metadata used by the bundle."
            ))
        }
        if manifest.modules.isEmpty {
            diagnostics.append(error(
                "PITBOSS_MANIFEST_MODULES_EMPTY",
                "Manifest must declare at least one module.",
                "Add module declarations for components such as denoiser, VAE, or text encoder."
            ))
        }
        if manifest.backendArtifacts.isEmpty {
            diagnostics.append(error(
                "PITBOSS_MANIFEST_BACKEND_ARTIFACTS_EMPTY",
                "Manifest must declare at least one backend artifact.",
                "Add a Core ML, MLX, safetensors, ONNX, GGUF, or native artifact declaration."
            ))
        }
        diagnostics.append(contentsOf: duplicateDiagnostics(manifest.assets.map(\.id), kind: "asset", code: "PITBOSS_MANIFEST_DUPLICATE_ASSET_ID"))
        diagnostics.append(contentsOf: duplicateDiagnostics(manifest.modules.map(\.id), kind: "module", code: "PITBOSS_MANIFEST_DUPLICATE_MODULE_ID"))
        diagnostics.append(contentsOf: duplicateDiagnostics(manifest.tokenizerRequirements.map(\.id), kind: "tokenizer", code: "PITBOSS_MANIFEST_DUPLICATE_TOKENIZER_ID"))
        return diagnostics
    }

    private func validateAssets(_ assets: [ManifestAsset]) -> [Diagnostic] {
        assets.flatMap { asset in
            requiredText(asset.id, field: "asset.id") +
                requiredText(asset.type, field: "asset.type", subject: asset.id) +
                requiredText(asset.path, field: "asset.path", subject: asset.id) +
                requiredText(asset.format, field: "asset.format", subject: asset.id)
        }
    }

    private func validateModules(_ modules: [ManifestModule]) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        for module in modules {
            diagnostics.append(contentsOf: requiredText(module.id, field: "module.id"))
            diagnostics.append(contentsOf: requiredText(module.role, field: "module.role", subject: module.id))
            if module.requiredCapabilities.isEmpty {
                diagnostics.append(error(
                    "PITBOSS_MANIFEST_MODULE_CAPABILITIES_EMPTY",
                    "Module '\(module.id)' declares no required capabilities.",
                    "Add capabilities needed to load or execute this module."
                ))
            }
            for capability in module.requiredCapabilities where !knownCapabilities.contains(capability) {
                diagnostics.append(error(
                    "PITBOSS_MANIFEST_UNKNOWN_CAPABILITY",
                    "Module '\(module.id)' requires unknown capability '\(capability.description)'.",
                    "Use a known Pitboss capability or add the plugin/backend contract before referencing it."
                ))
            }
        }
        return diagnostics
    }

    private func validateTokenizers(_ tokenizers: [TokenizerRequirement]) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        for tokenizer in tokenizers {
            diagnostics.append(contentsOf: requiredText(tokenizer.id, field: "tokenizer.id"))
            diagnostics.append(contentsOf: requiredText(tokenizer.kind, field: "tokenizer.kind", subject: tokenizer.id))
            if tokenizer.requiredFor.isEmpty {
                diagnostics.append(error(
                    "PITBOSS_MANIFEST_TOKENIZER_USAGE_EMPTY",
                    "Tokenizer '\(tokenizer.id)' must declare what it is required for.",
                    "Add requiredFor entries such as positive-prompt or negative-prompt."
                ))
            }
            if tokenizer.kind.lowercased() == "clip-bpe" {
                if isBlank(tokenizer.vocabularyPath) {
                    diagnostics.append(error(
                        "PITBOSS_MANIFEST_CLIP_BPE_VOCAB_MISSING",
                        "CLIP BPE tokenizer '\(tokenizer.id)' is missing vocabularyPath.",
                        "Point vocabularyPath at the tokenizer vocab JSON."
                    ))
                }
                if isBlank(tokenizer.mergesPath) {
                    diagnostics.append(error(
                        "PITBOSS_MANIFEST_CLIP_BPE_MERGES_MISSING",
                        "CLIP BPE tokenizer '\(tokenizer.id)' is missing mergesPath.",
                        "Point mergesPath at the tokenizer merges file."
                    ))
                }
            }
        }
        return diagnostics
    }

    private func validateBackendArtifacts(_ artifacts: [BackendArtifact], modules: [ManifestModule]) -> [Diagnostic] {
        let moduleIDs = Set(modules.map(\.id))
        var diagnostics: [Diagnostic] = []
        for artifact in artifacts {
            diagnostics.append(contentsOf: requiredText(artifact.moduleId, field: "backendArtifact.moduleId"))
            diagnostics.append(contentsOf: requiredText(artifact.path, field: "backendArtifact.path", subject: artifact.moduleId))
            if !artifact.moduleId.isEmpty && !moduleIDs.contains(artifact.moduleId) {
                diagnostics.append(error(
                    "PITBOSS_MANIFEST_BACKEND_ARTIFACT_UNKNOWN_MODULE",
                    "Backend artifact '\(artifact.path)' references unknown module '\(artifact.moduleId)'.",
                    "Set moduleId to one of the manifest module ids."
                ))
            }
            if artifact.kind == .coreml && !(artifact.path.hasSuffix(".mlpackage") || artifact.path.hasSuffix(".mlmodelc") || artifact.path.hasSuffix(".mlmodel")) {
                diagnostics.append(warning(
                    "PITBOSS_MANIFEST_COREML_EXTENSION_UNUSUAL",
                    "Core ML artifact '\(artifact.path)' does not use .mlpackage, .mlmodelc, or .mlmodel.",
                    "Confirm this artifact can be loaded by the Core ML backend."
                ))
            }
        }
        return diagnostics
    }

    private func validateScheduler(_ scheduler: SchedulerDefaults) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        diagnostics.append(contentsOf: requiredText(scheduler.scheduler, field: "schedulerDefaults.scheduler"))
        if scheduler.steps <= 0 {
            diagnostics.append(error(
                "PITBOSS_MANIFEST_SCHEDULER_STEPS_INVALID",
                "schedulerDefaults.steps must be greater than zero.",
                "Use a positive step count."
            ))
        }
        if let guidanceScale = scheduler.guidanceScale, guidanceScale < 0 {
            diagnostics.append(error(
                "PITBOSS_MANIFEST_GUIDANCE_SCALE_INVALID",
                "schedulerDefaults.guidanceScale must not be negative.",
                "Use a non-negative guidance scale."
            ))
        }
        return diagnostics
    }

    private func validateAdapterSupport(_ adapterSupport: AdapterSupport) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        if adapterSupport.supportsLoRA {
            if isBlank(adapterSupport.composition) {
                diagnostics.append(error(
                    "PITBOSS_MANIFEST_LORA_COMPOSITION_MISSING",
                    "LoRA support is enabled but adapterSupport.composition is missing.",
                    "Declare how adapters compose, for example merge-at-load or runtime-injection."
                ))
            }
            if let maxAdapters = adapterSupport.maxAdapters, maxAdapters <= 0 {
                diagnostics.append(error(
                    "PITBOSS_MANIFEST_LORA_MAX_ADAPTERS_INVALID",
                    "adapterSupport.maxAdapters must be greater than zero when present.",
                    "Use a positive adapter limit or omit the field."
                ))
            }
        }
        return diagnostics
    }

    private func validateControlSupport(_ controlSupport: ControlSupport) -> [Diagnostic] {
        if controlSupport.supportsControlNet && controlSupport.supportedControlTypes.isEmpty {
            return [warning(
                "PITBOSS_MANIFEST_CONTROL_TYPES_EMPTY",
                "ControlNet support is enabled but supportedControlTypes is empty.",
                "List supported control types such as depth, canny, pose, or segmentation."
            )]
        }
        return []
    }

    private func duplicateDiagnostics(_ values: [String], kind: String, code: String) -> [Diagnostic] {
        var seen: Set<String> = []
        var duplicates: Set<String> = []
        for value in values where !value.isEmpty {
            if seen.contains(value) {
                duplicates.insert(value)
            } else {
                seen.insert(value)
            }
        }
        return duplicates.sorted().map { value in
            error(code, "Duplicate \(kind) id '\(value)'.", "Use stable unique ids within each manifest collection.")
        }
    }

    private func requiredText(_ value: String, field: String, subject: String? = nil) -> [Diagnostic] {
        guard isBlank(value) else { return [] }
        let subjectText = subject.flatMap { isBlank($0) ? nil : $0 }
        let message = subjectText.map { "\(field) is required for '\($0)'." } ?? "\(field) is required."
        return [error(
            "PITBOSS_MANIFEST_REQUIRED_FIELD_EMPTY",
            message,
            "Fill \(field) with a non-empty value."
        )]
    }

    private func isBlank(_ value: String?) -> Bool {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
    }

    private func error(_ code: String, _ message: String, _ fix: String) -> Diagnostic {
        Diagnostic(severity: .error, code: code, message: message, suggestedFix: fix)
    }

    private func warning(_ code: String, _ message: String, _ fix: String) -> Diagnostic {
        Diagnostic(severity: .warning, code: code, message: message, suggestedFix: fix)
    }
}
