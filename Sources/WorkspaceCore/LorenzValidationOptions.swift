import Foundation

public struct LorenzValidationOptions: Sendable {
    public static let usage = """
    Usage: validate-lorenz.sh [--preset classic|filament|sculpture]
      [--representation line|ribbon] [--seconds 0...7200]
      [--width 64...4096] [--height 64...4096] [--output report.json]
    Without --seconds: parity only. With positive --seconds: parity, then a timed
    offscreen benchmark. JSON is written only after completion. --output requires
    a positive duration and an existing parent directory. No separate tool needed.
    """
    public var preset: LorenzPreset = .classic
    public var representation: LorenzRepresentation
    public var seconds: Double = 0
    public var width = 2880
    public var height = 1800
    public var output: String?

    public init(arguments: [String]) throws {
        let supported: Set<String> = ["--preset", "--representation", "--seconds", "--width", "--height", "--output"]
        var values: [String: String] = [:]
        var i = 0
        while i < arguments.count {
            let flag = arguments[i]
            guard supported.contains(flag), values[flag] == nil, i+1 < arguments.count,
                  !arguments[i+1].hasPrefix("--") else { throw OptionsError.invalid("Unknown, duplicate, or missing-value option: \(flag)") }
            values[flag] = arguments[i+1]; i += 2
        }
        guard let preset = LorenzPreset(rawValue: values["--preset"] ?? "classic"),
              let mode = LorenzRepresentation(rawValue: values["--representation"] ?? preset.appearance.representation.rawValue),
              let seconds = Double(values["--seconds"] ?? "0"), seconds.isFinite, (0...7200).contains(seconds),
              let width = Int(values["--width"] ?? "2880"), (64...4096).contains(width),
              let height = Int(values["--height"] ?? "1800"), (64...4096).contains(height) else {
            throw OptionsError.invalid("Invalid preset, representation, duration or dimensions.")
        }
        if let path = values["--output"], seconds <= 0 || path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw OptionsError.invalid("--output requires a nonempty path and --seconds greater than zero.")
        }
        self.preset = preset; representation = mode; self.seconds = seconds
        self.width = width; self.height = height; output = values["--output"]
    }
    public enum OptionsError: LocalizedError {
        case invalid(String)
        public var errorDescription: String? { if case let .invalid(message) = self { return message }; return nil }
    }
}
