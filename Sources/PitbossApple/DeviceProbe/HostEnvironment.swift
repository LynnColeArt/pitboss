import Foundation
import PitbossCore

public struct HostEnvironment: Codable, Equatable, Sendable {
    public var platform: String
    public var osVersion: String
    public var architecture: String
    public var isAppleSilicon: Bool
    public var coreMLStatus: String
    public var mlxStatus: String

    public init(
        platform: String,
        osVersion: String,
        architecture: String,
        isAppleSilicon: Bool,
        coreMLStatus: String,
        mlxStatus: String
    ) {
        self.platform = platform
        self.osVersion = osVersion
        self.architecture = architecture
        self.isAppleSilicon = isAppleSilicon
        self.coreMLStatus = coreMLStatus
        self.mlxStatus = mlxStatus
    }
}

public enum DeviceProbe {
    public static func current() -> HostEnvironment {
        HostEnvironment(
            platform: platformName,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            architecture: architectureName,
            isAppleSilicon: isAppleSilicon,
            coreMLStatus: coreMLStatus,
            mlxStatus: "not-linked: MLX backend is a contract stub in this spike"
        )
    }

    public static func backendDescriptors() -> [BackendDescriptor] {
        let host = current()
        return [
            BackendDescriptor(
                id: "pitboss.backend.coreml",
                platform: host.platform,
                deviceType: host.isAppleSilicon ? "apple-silicon" : "unavailable",
                capabilities: [.parse("backend.coreml")],
                supportsMemoryEstimates: false,
                executionStatus: host.coreMLStatus,
                diagnosticStatus: Diagnostic(
                    severity: host.isAppleSilicon ? .info : .warning,
                    code: host.isAppleSilicon ? "PITBOSS_COREML_AVAILABLE" : "PITBOSS_COREML_UNAVAILABLE",
                    message: host.coreMLStatus
                )
            ),
            BackendDescriptor(
                id: "pitboss.backend.mlx",
                platform: host.platform,
                deviceType: host.isAppleSilicon ? "apple-silicon" : "unavailable",
                capabilities: [.parse("backend.mlx")],
                supportsMemoryEstimates: false,
                executionStatus: host.mlxStatus,
                diagnosticStatus: Diagnostic(
                    severity: .warning,
                    code: "PITBOSS_MLX_STUB",
                    message: host.mlxStatus
                )
            )
        ]
    }

    private static var platformName: String {
        #if os(macOS)
        return "macOS"
        #elseif os(Linux)
        return "Linux"
        #else
        return "unknown"
        #endif
    }

    private static var architectureName: String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }

    private static var isAppleSilicon: Bool {
        #if os(macOS) && arch(arm64)
        return true
        #else
        return false
        #endif
    }

    private static var coreMLStatus: String {
        #if canImport(CoreML)
        return "available: Core ML framework can be imported"
        #else
        return "unavailable on this build host: Core ML requires Apple platforms"
        #endif
    }
}
