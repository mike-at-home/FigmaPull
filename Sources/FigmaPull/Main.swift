import ArgumentParser
import Foundation

// MARK: - Generator

@main
struct FigmaPull: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A utility for grabbing things from Figma.",
        version: "1.0.0",
        subcommands:[Images.self]
    )
}
