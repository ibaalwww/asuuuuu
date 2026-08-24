import Foundation

enum CapabilitySupport: String, CaseIterable {
    case full
    case partial
    case unsupported

    var title: String {
        switch self {
        case .full:
            return "Full"
        case .partial:
            return "Partial"
        case .unsupported:
            return "Unsupported"
        }
    }

    var icon: String {
        switch self {
        case .full:
            return "checkmark.circle.fill"
        case .partial:
            return "circle.lefthalf.filled"
        case .unsupported:
            return "xmark.circle.fill"
        }
    }
}

enum DeviceCapability: String, CaseIterable, Identifiable {
    case deviceAccess
    case restore
    case posterBoard
    case mobileGestalt
    case featureFlags
    case systemFileWrite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .deviceAccess:
            return "Device Access"
        case .restore:
            return "Restore Engine"
        case .posterBoard:
            return "PosterBoard"
        case .mobileGestalt:
            return "MobileGestalt"
        case .featureFlags:
            return "Feature Flags"
        case .systemFileWrite:
            return "Direct System File Write"
        }
    }
}

struct DeviceCapabilities {
    let systemVersion: OperatingSystemVersion
    let systemVersionString: String

    let deviceAccess: CapabilitySupport
    let restore: CapabilitySupport
    let posterBoard: CapabilitySupport
    let mobileGestalt: CapabilitySupport
    let featureFlags: CapabilitySupport
    let systemFileWrite: CapabilitySupport

    static var current: DeviceCapabilities {
        let version = ProcessInfo.processInfo.operatingSystemVersion

        let versionString =
            "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        return DeviceCapabilities(
            systemVersion: version,
            systemVersionString: versionString,

            deviceAccess: supportForDeviceAccess(version),
            restore: supportForRestore(version),
            posterBoard: supportForPosterBoard(version),
            mobileGestalt: supportForMobileGestalt(version),
            featureFlags: supportForFeatureFlags(version),

            // This app does not treat restore capability as arbitrary
            // filesystem-write capability.
            systemFileWrite: .unsupported
        )
    }

    var overall: CapabilitySupport {
        let values = [
            deviceAccess,
            restore,
            posterBoard,
            mobileGestalt,
            featureFlags
        ]

        if values.allSatisfy({ $0 == .full }) {
            return .full
        }

        if values.contains(where: { $0 == .full || $0 == .partial }) {
            return .partial
        }

        return .unsupported
    }

    var capabilities: [(DeviceCapability, CapabilitySupport)] {
        [
            (.deviceAccess, deviceAccess),
            (.restore, restore),
            (.posterBoard, posterBoard),
            (.mobileGestalt, mobileGestalt),
            (.featureFlags, featureFlags),
            (.systemFileWrite, systemFileWrite)
        ]
    }

    private static func supportForDeviceAccess(
        _ version: OperatingSystemVersion
    ) -> CapabilitySupport {
        // Device Access here means that the app can expose the
        // capability-check/connection layer. It does not imply
        // privileged filesystem access.
        return .full
    }

    private static func supportForRestore(
        _ version: OperatingSystemVersion
    ) -> CapabilitySupport {
        if version.majorVersion < 17 {
            return .unsupported
        }

        if version.majorVersion == 26 &&
            version.minorVersion <= 1 {
            return .full
        }

        if version.majorVersion == 26 {
            return .partial
        }

        return .partial
    }

    private static func supportForPosterBoard(
        _ version: OperatingSystemVersion
    ) -> CapabilitySupport {
        if version.majorVersion >= 17 {
            return .partial
        }

        return .unsupported
    }

    private static func supportForMobileGestalt(
        _ version: OperatingSystemVersion
    ) -> CapabilitySupport {
        if version.majorVersion < 17 {
            return .unsupported
        }

        if version.majorVersion == 17 ||
            version.majorVersion == 18 ||
            version.majorVersion == 19 ||
            version.majorVersion == 20 ||
            version.majorVersion == 21 ||
            version.majorVersion == 22 ||
            version.majorVersion == 23 ||
            version.majorVersion == 24 ||
            version.majorVersion == 25 ||
            (version.majorVersion == 26 && version.minorVersion <= 1) {
            return .full
        }

        // 26.2+
        return .unsupported
    }

    private static func supportForFeatureFlags(
        _ version: OperatingSystemVersion
    ) -> CapabilitySupport {
        if version.majorVersion == 26 &&
            version.minorVersion >= 2 {
            return .partial
        }

        if version.majorVersion >= 17 {
            return .partial
        }

        return .unsupported
    }
}
