//
//  DeviceInfo.swift
//  Scaffold
//

import Foundation

/// Identifying details about the running app and device.
///
/// Built once and passed around rather than recomputed: every field here is fixed for
/// the lifetime of the process, and `uname` is a syscall.
nonisolated struct DeviceInfo: Sendable, Equatable {
    let appName: String
    let appVersion: String
    let buildNumber: String
    let systemName: String
    let systemVersion: String
    let hardwareIdentifier: String

    /// Formatted for a `User-Agent` header, e.g.
    /// `MyApp/1.0 (42; iOS/18.0; iPhone17,1)`.
    var userAgent: String {
        "\(appName)/\(appVersion) (\(buildNumber); \(systemName)/\(systemVersion); \(hardwareIdentifier))"
    }

    /// Reads `ProcessInfo` rather than `UIDevice` for the OS version: `UIDevice` is
    /// main-actor isolated, and this is wanted on whatever thread is building a request.
    static func current(bundle: Bundle = .main) -> DeviceInfo {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return DeviceInfo(
            appName: bundle.string(for: kCFBundleNameKey as String),
            appVersion: bundle.string(for: "CFBundleShortVersionString"),
            buildNumber: bundle.string(for: kCFBundleVersionKey as String),
            systemName: "iOS",
            systemVersion: "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)",
            hardwareIdentifier: hardwareIdentifier(),
        )
    }

    /// The machine identifier, e.g. `iPhone17,1`.
    ///
    /// `UIDevice.model` only reports "iPhone", so the specific hardware has to come from
    /// `uname`. `machine` is a fixed-size C char array imported as a tuple, so it has to be
    /// read as raw bytes and cut at the NUL terminator — the array is padded, not sized to
    /// the value. The `String` is built inside the closure because the buffer pointer is
    /// only valid for its duration.
    static func hardwareIdentifier() -> String {
        var info = utsname()
        uname(&info)

        return withUnsafeBytes(of: &info.machine) { bytes in
            String(bytes: bytes.prefix { $0 != 0 }, encoding: .utf8) ?? "unknown"
        }
    }
}

extension Bundle {
    /// Info.plist lookups are optional at every step; an app missing these keys is
    /// misconfigured rather than crashable, so callers get a marker instead of a trap.
    fileprivate nonisolated func string(for key: String) -> String {
        object(forInfoDictionaryKey: key) as? String ?? "unknown"
    }
}
