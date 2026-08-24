import Foundation

enum SystemPlistOverwriteError: LocalizedError {
    case invalidPlist
    case invalidStructure
    case targetNotFound
    case writeFailed
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .invalidPlist:
            return "The plist is not valid."
        case .invalidStructure:
            return "The plist root must be a dictionary."
        case .targetNotFound:
            return "System disable.plist target was not found."
        case .writeFailed:
            return "Failed to overwrite the system plist."
        case .verificationFailed:
            return "The overwritten plist failed verification."
        }
    }
}

enum SystemPlistOverwrite {

    private static let targetPaths = [
        "/var/db/com.apple.xpc.launchd/disable.plist",
        "/var/db/com.apple.xpc.launchd/disabled.plist"
    ]

    static func targetURL() throws -> URL {
        let fileManager = FileManager.default

        for path in targetPaths {
            let url = URL(fileURLWithPath: path)
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }

        throw SystemPlistOverwriteError.targetNotFound
    }

    static func readTarget() throws -> Data {
        let url = try targetURL()

        do {
            return try Data(contentsOf: url, options: .mappedIfSafe)
        } catch {
            throw SystemPlistOverwriteError.invalidPlist
        }
    }

    static func validate(_ data: Data) throws {
        guard !data.isEmpty else {
            throw SystemPlistOverwriteError.invalidPlist
        }

        let object: Any

        do {
            object = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            )
        } catch {
            throw SystemPlistOverwriteError.invalidPlist
        }

        guard object is [String: Any] else {
            throw SystemPlistOverwriteError.invalidStructure
        }

        guard PropertyListSerialization.propertyList(
            object,
            isValidFor: .binary
        ) else {
            throw SystemPlistOverwriteError.invalidPlist
        }
    }

    static func overwrite(data: Data) throws {
        try validate(data)

        let targetURL = try targetURL()
        let fileManager = FileManager.default
        let directory = targetURL.deletingLastPathComponent()

        let temporaryURL = directory.appendingPathComponent(
            ".ibaal3105-\(UUID().uuidString).plist"
        )

        defer {
            try? fileManager.removeItem(at: temporaryURL)
        }

        do {
            try data.write(to: temporaryURL, options: [.atomic])
        } catch {
            throw SystemPlistOverwriteError.writeFailed
        }

        let stagedData: Data

        do {
            stagedData = try Data(
                contentsOf: temporaryURL,
                options: .mappedIfSafe
            )
        } catch {
            throw SystemPlistOverwriteError.writeFailed
        }

        do {
            try validate(stagedData)
        } catch {
            throw SystemPlistOverwriteError.writeFailed
        }

        do {
            _ = try fileManager.replaceItemAt(
                targetURL,
                withItemAt: temporaryURL,
                backupItemName: nil,
                options: []
            )
        } catch {
            throw SystemPlistOverwriteError.writeFailed
        }

        let resultData: Data

        do {
            resultData = try Data(
                contentsOf: targetURL,
                options: .mappedIfSafe
            )
        } catch {
            throw SystemPlistOverwriteError.verificationFailed
        }

        do {
            try validate(resultData)
        } catch {
            throw SystemPlistOverwriteError.verificationFailed
        }

        guard resultData == data else {
            throw SystemPlistOverwriteError.verificationFailed
        }
    }
}
