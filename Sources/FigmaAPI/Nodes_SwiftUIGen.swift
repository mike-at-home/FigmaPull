#if false
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

extension FigmaV1.Nodes.ComponentSet {
    public func generateIcons() -> SourceFile {
        let components = children.map { $0 as! FigmaV1.Nodes.Component }

        return SourceFile {
            ImportDecl(path: "SwiftUI")
            for c in components {
                c.generateIconSwift()
            }

            generatePreview(components)
        }
    }

    func generatePreview(_ components: [FigmaV1.Nodes.Component]) -> StructDecl {
//        struct TestIcon_Previews: PreviewProvider {
//            static var previews: some View {
//                HStack {
//                    InReviewIcon()
//                }
//            }
//        }

        return StructDecl(
            structKeyword: .struct,
            identifier: "MediumIcon_Previews",

            inheritanceClause:
            TypeInheritanceClause {
                InheritedType(typeName: "PreviewProvider")
            },
            attributesBuilder: {
                AccessLevelModifier(name: .public)
            },
            membersBuilder: {
                VariableDecl(
                    letOrVarKeyword: .var,
                    attributesBuilder: {
                        DeclModifier(name: .static)
                        AccessLevelModifier(name: .public)
                    },
                    bindingsBuilder: {
                        PatternBinding(
                            pattern: "previews",
                            typeAnnotation: "some View",
                            initializer: nil,
                            accessor: CodeBlock {
                                FunctionCallExpr(
                                    calledExpression: IdentifierExpr("List"),
                                    leftParen: .leftParen,
                                    rightParen: .rightParen,
                                    trailingClosure: ClosureExpr(leftBrace: .leftBrace, rightBrace: .rightBrace) {
                                        for component in components {
                                            FunctionCallExpr(
                                                calledExpression: IdentifierExpr("\(component.safeName)Icon"),
                                                leftParen: .leftParen,
                                                rightParen: .rightParen
                                            )
                                        }
                                    }
                                )
                            }
                        )
                    }
                )
            }
        )
    }
}

extension FigmaV1.Nodes.Node {
    public var safeName: String {
        self.name.split(separator: "=")[1].replacingOccurrences(of: "&", with: "And")
            .replacingOccurrences(of: " ", with: "_")
    }
}

extension FigmaV1.Nodes.Component {
    func generateIconSwift() -> StructDecl {
        let name = self.safeName

        let body = self.generateExpression(.init(bounds: .init(x: 0, y: 0, width: 0, height: 0), isMask: false))!

        let decl = StructDecl(
            structKeyword: .struct,
            identifier: "\(name)Icon",

            inheritanceClause:
            TypeInheritanceClause {
                InheritedType(typeName: "View")
            },
            attributesBuilder: {
                AccessLevelModifier(name: .public)
            },
            membersBuilder: {
                VariableDecl(
                    letOrVarKeyword: .var,
                    attributesBuilder: {
                        AccessLevelModifier(name: .public)
                    },
                    bindingsBuilder: {
                        PatternBinding(
                            pattern: "body",
                            typeAnnotation: "some View",
                            initializer: nil,
                            accessor: CodeBlock {
                                body
                            }
                        )
                    }
                )
            }
        )
        return decl
    }
}

extension FigmaV1.Nodes.Frame {
//    public func createSourceFile() -> SourceFile {
//        SourceFile {
//            ImportDecl(path: "SwiftUI")
//
//            StructDecl(
//                structKeyword: .public,
//                identifier: "Name",
//                inheritanceClause:
//                TypeInheritanceClause {
//                    InheritedType(typeName: "View")
//                },
//                membersBuilder: {
//                    VariableDecl(letOrVarKeyword: .var, attributesBuilder: {
//                        AccessLevelModifier(name: .public)
//                    }, bindingsBuilder: {
//                        PatternBinding(
//                            pattern: "size",
//                            typeAnnotation: "Size"
//                        )
//
//                    })
//
//                    VariableDecl(
//                        letOrVarKeyword: .var,
//                        attributesBuilder: {
//                            AccessLevelModifier(name: .public)
//                        },
//                        bindingsBuilder: {
//                            PatternBinding(
//                                pattern: "body",
//                                typeAnnotation: "some View",
//                                initializer: nil,
//                                accessor: CodeBlock {
//                                    FunctionCallExpr(
//                                        "SyntaxFactory.make\(keyword)Keyword",
//                                        leftParen: .leftParen,
//                                        rightParen: .rightParen
//                                    )
//                                }
//                            )
//                        }
//                    )
//                }
//            )
//        }
//    }
}

// MARK: - SwiftSyntaxGenerator

extension FigmaV1.Path {
    func generateFunctionCall() -> FunctionCallExpr {
        FunctionCallExpr(
            "Path",
            trailingClosure: ClosureExpr(statements: CodeBlockItemList(operations.map { $0.generateFunctionCall() }))
        )
    }
}

extension FigmaV1.Vector {
    func generatePointExpr() -> FunctionCallExpr {
        FunctionCallExpr(
            calledExpression: IdentifierExpr("CGPoint"),
            leftParen: .leftParen,
            rightParen: .rightParen,
            argumentListBuilder: {
                TupleExprElement("x", value: x)
                TupleExprElement("y", value: y, isEnd: true)
            }
        )
    }
}

extension FigmaV1.Paint {
    func generateFunctionCall() -> FunctionCallExpr? {
        guard opacity > 0, visible else { return nil }

        if self.type == .solid, let color {
            return color.generateExpression().withOpacity(opacity)
        }
        preconditionFailure()
    }
}

extension FigmaV1.Color {
    func generateExpression() -> FunctionCallExpr {
        FunctionCallExpr(
            calledExpression: IdentifierExpr("Color"),
            leftParen: .leftParen,
            rightParen: .rightParen,
            argumentListBuilder: {
                TupleExprElement("red", value: r)
                TupleExprElement("green", value: g)
                TupleExprElement("blue", value: b, isEnd: true)
            }
        )
    }
}

extension FigmaV1.Path.Operation {
    func generateFunctionCall() -> FunctionCallExpr {
        let arg = IdentifierExpr(identifier: .dollarIdentifier("$0"))
        switch self {
        case .move(to: let pt):
            return .init(
                calledExpression: MemberAccessExpr(base: arg, dot: .period, name: .identifier("move")),
                leftParen: .leftParen,
                rightParen: .rightParen,
                argumentListBuilder: {
                    TupleExprElement(label: .identifier("to"), colon: .colon, expression: pt.generatePointExpr())
                }
            )

        case .line(to: let pt):
            return .init(
                calledExpression: MemberAccessExpr(base: arg, dot: .period, name: .identifier("addLine")),
                leftParen: .leftParen,
                rightParen: .rightParen,
                argumentListBuilder: {
                    TupleExprElement(label: .identifier("to"), colon: .colon, expression: pt.generatePointExpr())
                }
            )

        case .curve(to: let pt, controlPoint1: let c1, controlPoint2: let c2):
            return .init(
                calledExpression: MemberAccessExpr(base: arg, dot: .period, name: .identifier("addCurve")),
                leftParen: .leftParen,
                rightParen: .rightParen,
                argumentListBuilder: {
                    TupleExprElement("to", value: pt.generatePointExpr())
                    TupleExprElement("control1", value: c1.generatePointExpr())
                    TupleExprElement("control2", value: c2.generatePointExpr(), isEnd: true)
                }
            )

        case .close:
            return .init(
                calledExpression: MemberAccessExpr(base: arg, dot: .period, name: .identifier("closeSubpath")),
                leftParen: .leftParen,
                rightParen: .rightParen
            )
        }
    }
}

// MARK: - SwiftUIContext

public struct SwiftUIContext {
    public var bounds: FigmaV1.Rectangle
    public var isMask: Bool
}

// MARK: - SwiftSyntaxGenerator

internal protocol SwiftSyntaxGenerator {
    func generateExpression(_ context: SwiftUIContext) -> FunctionCallExpr?
}

// MARK: - FigmaV1.Nodes.FrameBase + SwiftSyntaxGenerator

extension FigmaV1.Nodes.FrameBase: SwiftSyntaxGenerator {
    func generateExpression(_ context: SwiftUIContext) -> FunctionCallExpr? {
        if !visible || opacity == 0 {
            return nil
        }

        var result: FunctionCallExpr?
        if
            let background = FunctionCallExpr("Rectangle", leftParen: .leftParen, rightParen: .rightParen)
                .withFills(context, fills, strokes: strokes) {
            result = background
        }

        let layerContext = SwiftUIContext(bounds: absoluteRenderBounds, isMask: false)
        let maskContext = SwiftUIContext(bounds: absoluteRenderBounds, isMask: true)

        func addLayer(_ expr: FunctionCallExpr) {
            var layer: FunctionCallExpr = expr
            if let m = mask {
                layer = expr.withMask(m)
                mask = nil
            }

            result = result?.withOverlay(layer) ?? layer
        }

        var mask: FunctionCallExpr?

        func setMask(_ expr: FunctionCallExpr) {
            mask = expr
        }

        for child in children {
            let isMask = (child as? FigmaV1.Nodes.FrameBase)?.isMask ?? (child as? FigmaV1.Nodes.VectorBase)?
                .isMask ?? false
            if let gen = child as? SwiftSyntaxGenerator {
                if isMask {
                    if let s = gen.generateExpression(maskContext) {
                        setMask(s)
                    }
                } else {
                    if let s = gen.generateExpression(layerContext) {
                        addLayer(s)
                    }
                }
            } else {
                print(child)
            }
        }

        return result?.withBoundsIfDifferent(absoluteRenderBounds, inherited: context.bounds)
            .withOpacity(opacity)
    }
}

// MARK: - FigmaV1.Nodes.Ellipse + SwiftSyntaxGenerator

extension FigmaV1.Nodes.Ellipse: SwiftSyntaxGenerator {
    func generateExpression(_ context: SwiftUIContext) -> FunctionCallExpr? {
        if visible == false || opacity == 0 {
            return nil
        }

        let result = FunctionCallExpr("Ellipse", leftParen: .leftParen, rightParen: .rightParen)
            .withFills(context, fills, strokes: strokes)?
            .withBoundsIfDifferent(absoluteRenderBounds, inherited: context.bounds)
            .withOpacity(opacity)

        return result
    }
}

// MARK: - FigmaV1.Nodes.Rectangle + SwiftSyntaxGenerator

extension FigmaV1.Nodes.Rectangle: SwiftSyntaxGenerator {
    func generateExpression(_ context: SwiftUIContext) -> FunctionCallExpr? {
        if visible == false || opacity == 0 {
            return nil
        }

        let result = FunctionCallExpr("Rectangle", leftParen: .leftParen, rightParen: .rightParen)
            .withFills(context, fills, strokes: strokes)?
            .withBoundsIfDifferent(absoluteRenderBounds, inherited: context.bounds)
            .withOpacity(opacity)

        return result
    }
}

// MARK: - FigmaV1.Nodes.Vector + SwiftSyntaxGenerator

extension FigmaV1.Nodes.Vector: SwiftSyntaxGenerator {
    func generateExpression(_ context: SwiftUIContext) -> FunctionCallExpr? {
        var result: FunctionCallExpr?

        for (geometry, paint) in zip(fillGeometry, fills) {
            guard let call = geometry.generateFunctionCall().filled(paint) else { continue }
            result = result?.withOverlay(call) ?? call
        }

        for (geometry, paint) in zip(strokeGeometry, strokes) {
            guard let call = geometry.generateFunctionCall().stroked(paint) else { continue }
            result = result?.withOverlay(call) ?? call
        }

        return result?
            .withBoundsIfDifferent(absoluteRenderBounds, inherited: context.bounds)
            .withOpacity(opacity)
    }
}

// MARK: - FigmaV1.Nodes.BooleanOperation + SwiftSyntaxGenerator

extension FigmaV1.Nodes.BooleanOperation: SwiftSyntaxGenerator {
    func generateExpression(_ context: SwiftUIContext) -> FunctionCallExpr? {
        var result: FunctionCallExpr?

        for (geometry, paint) in zip(fillGeometry, fills) {
            guard let call = geometry.generateFunctionCall().filled(paint) else { continue }
            result = result?.withOverlay(call) ?? call
        }

        for (geometry, paint) in zip(strokeGeometry, strokes) {
            guard let call = geometry.generateFunctionCall().stroked(paint) else { continue }
            result = result?.withOverlay(call) ?? call
        }

        return result?
            .withBoundsIfDifferent(absoluteRenderBounds, inherited: context.bounds)
            .withOpacity(opacity)
    }
}

// MARK: - Double + ExpressibleAsFloatLiteralExpr

extension Double: ExpressibleAsFloatLiteralExpr {
    public func createFloatLiteralExpr() -> FloatLiteralExpr {
        let roundedVal = Double(Int(Double(self) * 1000)) / 1000
        let str = String(roundedVal)
        var chars: String
        if let idx = str.firstIndex(of: ".") {
            let nextIdx = str.index(after: idx)
            let next = str[nextIdx...].prefix(3)

            if let zeroIdx = next.lastIndex(of: "0") {
                if zeroIdx == nextIdx {
                    chars = String(str[..<idx])
                } else {
                    chars = String(str[..<zeroIdx])
                }
            } else {
                chars = str
            }
        } else {
            chars = str
        }

        if chars == "-0" {
            chars = "0"
        }
        return .init(floatingDigits: chars)
    }
}

extension TupleExprElement {
    public init(_ name: String, value: ExpressibleAsExprBuildable, isEnd: Bool = false) {
        self.init(label: .identifier(name), colon: .colon, expression: value, trailingComma: isEnd ? nil : .comma)
    }
}

extension ClosureExpr {
    public init(_ stsms: [FunctionCallExpr]) {
        self.init(leftBrace: .leftBrace, statements: CodeBlockItemList(stsms.map { $0 }), rightBrace: .rightBrace)
    }
}

extension FunctionCallExpr {
    func withOpacity(_ value: Double) -> FunctionCallExpr {
        if value == 1 { return self }

        return FunctionCallExpr(
            calledExpression: MemberAccessExpr(base: self, dot: .period, name: .identifier("opacity")),
            leftParen: .leftParen,
            rightParen: .rightParen,
            argumentListBuilder: {
                TupleExprElement(expression: value)
            }
        )
    }

    func withOverlay(_ value: FunctionCallExpr) -> FunctionCallExpr {
        return FunctionCallExpr(
            calledExpression: MemberAccessExpr(base: self, dot: .period, name: .identifier("overlay")),
            leftParen: .leftParen,
            rightParen: .rightParen,
            argumentListBuilder: {
                TupleExprElement(expression: value)
            }
        )
    }

    func withMask(_ value: FunctionCallExpr) -> FunctionCallExpr {
        return FunctionCallExpr(
            calledExpression: MemberAccessExpr(base: self, dot: .period, name: .identifier("mask")),
            leftParen: .leftParen,
            rightParen: .rightParen,
            argumentListBuilder: {
                TupleExprElement(expression: value)
            }
        )
    }

    func stroked(_ paint: FigmaV1.Paint) -> FunctionCallExpr? {
        guard let paintExpr = paint.generateFunctionCall() else { return nil }

        return FunctionCallExpr(
            calledExpression: MemberAccessExpr(base: self, dot: .period, name: .identifier("stroke")),
            leftParen: .leftParen,
            rightParen: .rightParen,
            argumentListBuilder: {
                TupleExprElement(expression: paintExpr)
            }
        )
    }

    func filled(_ paint: FigmaV1.Paint) -> FunctionCallExpr? {
        guard let paintExpr = paint.generateFunctionCall() else { return nil }

        return FunctionCallExpr(
            calledExpression: MemberAccessExpr(base: self, dot: .period, name: .identifier("fill")),
            leftParen: .leftParen,
            rightParen: .rightParen,
            argumentListBuilder: {
                TupleExprElement(expression: paintExpr)
            }
        )
    }

    func withSize(_ size: FigmaV1.Vector) -> FunctionCallExpr {
        FunctionCallExpr(
            calledExpression: MemberAccessExpr(base: self, dot: .period, name: .identifier("frame")),
            leftParen: .leftParen,
            rightParen: .rightParen,
            argumentListBuilder: {
                TupleExprElement("width", value: size.x)
                TupleExprElement("height", value: size.y, isEnd: true)
            }
        )
    }

    func withOffset(_ pt: FigmaV1.Vector) -> FunctionCallExpr {
        if pt.x == 0, pt.y == 0 { return self }
        return FunctionCallExpr(
            calledExpression: MemberAccessExpr(base: self, dot: .period, name: .identifier("offset")),
            leftParen: .leftParen,
            rightParen: .rightParen,
            argumentListBuilder: {
                TupleExprElement("x", value: pt.x)
                TupleExprElement("y", value: pt.y, isEnd: true)
            }
        )
    }

    func withBoundsIfDifferent(_ bounds: FigmaV1.Rectangle, inherited: FigmaV1.Rectangle) -> FunctionCallExpr {
        if bounds.x == 0, bounds.y == 0, bounds.width == 0, bounds.height == 0 {
            return self
        }

        var result = self

        if bounds.width != inherited.width || bounds.height != inherited.height {
            result = result.withSize(.init(x: bounds.width, y: bounds.height))
        }

        if inherited.x != 0, inherited.y != 0 {
            let halfWidth = bounds.width / 2
            let halfHeight = bounds.height / 2
            let dx = bounds.x - inherited.x
            let dy = bounds.y - inherited.y

            if dx != 0 || dy != 0 {
                result = result.withOffset(.init(x: dx - halfWidth, y: dy - halfHeight))
            }
        }

        return result
    }

    func withSizeIfDifferent(_ size: FigmaV1.Vector, inherited: FigmaV1.Vector) -> FunctionCallExpr {
        if size.x == inherited.x, size.y == inherited.y { return self }

        return self.withSize(size)
    }

    func withFills(_ context: SwiftUIContext, _ fills: [FigmaV1.Paint], strokes: [FigmaV1.Paint]) -> FunctionCallExpr? {
        guard !context.isMask else { return self }

        return withFills(fills, strokes: strokes)
    }

    func withFills(_ fills: [FigmaV1.Paint], strokes: [FigmaV1.Paint]) -> FunctionCallExpr? {
        var result: FunctionCallExpr?
        for fill in fills {
            if let expr = self.filled(fill) {
                result = result?.withOverlay(expr) ?? expr
            }
        }
        for stroke in strokes {
            if let expr = self.stroked(stroke) {
                result = result?.withOverlay(expr) ?? expr
            }
        }

        return result
    }
}

#endif
