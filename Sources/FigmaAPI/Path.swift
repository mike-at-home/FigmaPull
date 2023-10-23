//
//  Path.swift
//  HonorFigmaPull
//
//  Created by Michael Kasianowicz on 12/12/22.
//

import RegexBuilder

extension FigmaV1.Path {
    static func parse(_ input: String) -> [Operation] {
        var result: [Operation] = []

        var command: Character?
        var valueBuffer: [Double] = []

        func flush() {
            guard let cmd = command else { return }

            switch cmd {
            case "M":
                let toX = valueBuffer.removeFirst()
                let toY = valueBuffer.removeFirst()

                result.append(.move(to: .init(x: toX, y: toY)))

                while !valueBuffer.isEmpty {
                    let toX = valueBuffer.removeFirst()
                    let toY = valueBuffer.removeFirst()

                    result.append(.line(to: .init(x: toX, y: toY)))
                }

            case "L":
                repeat {
                    let toX = valueBuffer.removeFirst()
                    let toY = valueBuffer.removeFirst()

                    result.append(.line(to: .init(x: toX, y: toY)))
                } while !valueBuffer.isEmpty

            case "C":
                repeat {
                    let cp1X = valueBuffer.removeFirst()
                    let cp1Y = valueBuffer.removeFirst()
                    let cp2X = valueBuffer.removeFirst()
                    let cp2Y = valueBuffer.removeFirst()
                    let toX = valueBuffer.removeFirst()
                    let toY = valueBuffer.removeFirst()

                    result
                        .append(.curve(
                            to: .init(x: toX, y: toY),
                            controlPoint1: .init(x: cp1X, y: cp1Y),
                            controlPoint2: .init(x: cp2X, y: cp2Y)
                        ))
                } while !valueBuffer.isEmpty

            case "Z":
                result.append(.close)
                precondition(valueBuffer.isEmpty)

            default:
                preconditionFailure()
            }

            command = nil
        }

        var pieces: [String] = []
        var buffer = ""

        func flushBuffer() {
            if !buffer.isEmpty {
                pieces.append(buffer)
            }
            buffer.removeAll()
        }

        for c in input {
            switch c {
            case "M",
                 "C",
                 "L",
                 "Z":
                flushBuffer()
                pieces.append("\(c)")

            case " ":
                flushBuffer()

            default:
                buffer += "\(c)"
            }
        }
        flushBuffer()

        for p in pieces {
            if let value = Double(p) {
                valueBuffer.append(value)
            } else {
                flush()
                command = p[p.startIndex]
            }
        }

        flush()

        return result
    }
}
