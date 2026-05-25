import Foundation

public struct A1111GenerationParameters: Codable, Equatable, Sendable {
    public var prompt: String
    public var negativePrompt: String?
    public var parameters: [String: String]

    public init(prompt: String, negativePrompt: String? = nil, parameters: [String: String] = [:]) {
        self.prompt = prompt
        self.negativePrompt = negativePrompt
        self.parameters = parameters
    }
}
