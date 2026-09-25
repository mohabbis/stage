import Foundation

enum CaptureFidelity: String, Codable, Equatable, Sendable {
    case full
    case partial
    case unsupported

    var label: String {
        switch self {
        case .full: "Full"
        case .partial: "Partial"
        case .unsupported: "Unsupported"
        }
    }

    static func aggregate(_ values: [CaptureFidelity]) -> CaptureFidelity {
        guard !values.isEmpty else { return .unsupported }
        if values.allSatisfy({ $0 == .full }) { return .full }
        if values.allSatisfy({ $0 == .unsupported }) { return .unsupported }
        return .partial
    }
}
