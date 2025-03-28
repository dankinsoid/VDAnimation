#if canImport(SwiftCompilerPlugin)
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

extension TokenSyntax {

    /// Determines whether the token is a `didSet` or `willSet` keyword.
    var isWillSetOrDidSet: Bool {
        tokenKind == .keyword(.didSet) || tokenKind == .keyword(.willSet)
    }

    /// Determines whether the token is a `lazy` keyword.
    var isLazy: Bool {
        tokenKind == .keyword(.lazy)
    }

    /// Determines whether the token is a `let` keyword.
    var isLet: Bool {
        tokenKind == .keyword(.let)
    }

    /// Determines whether the token is a `static` keyword.
    var isStatic: Bool {
        tokenKind == .keyword(.static)
    }

    /// Trims the token description. Removes leading and trailing whitespaces and "`"
    var trimmedName: String {
        trimmed.text.trimmingCharacters(in: ["`"])
    }
}

extension ExprSyntax {

    /// Name of the expression.
    var baseName: String? {
        self.as(FunctionCallExprSyntax.self)?.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.trimmed.text ??
            self.as(FunctionCallExprSyntax.self)?.calledExpression.as(GenericSpecializationExprSyntax.self)?.trimmed.description
    }
}

extension SyntaxProtocol {

    /// Comments of the syntax element.
    ///
    /// - Parameter onlyDocComment: Whether to include only doc comments. Default is `true`.
    func documentation(onlyDocComment: Bool = true) -> String? {
        leadingTrivia.documentation(onlyDocComment: onlyDocComment)
    }
}

extension Trivia {

    /// Comments of the trivia.
    ///
    /// - Parameter onlyDocComment: Whether to include only doc comments. Default is `true`.
    func documentation(onlyDocComment: Bool = true) -> String? {
        let lines = compactMap { $0.documentation(onlyDocComment: onlyDocComment) }
        guard lines.count > 1 else { return lines.first?.trimmingCharacters(in: .whitespaces) }

        let indentation = lines.compactMap { $0.firstIndex(where: { !$0.isWhitespace })?.utf16Offset(in: $0) }
            .min() ?? 0

        return lines.map {
            guard $0.count > indentation else { return String($0) }
            return String($0.suffix($0.count - indentation))
        }.joined(separator: "\\n")
    }
}

extension TriviaPiece {

    /// Comments of the trivia piece.
    ///
    /// - Parameter onlyDocComment: Whether to include only doc comments. Default is `true`.
    func documentation(onlyDocComment: Bool = true) -> String? {
        switch self {
        case let .docLineComment(comment):
            let startIndex = comment.index(comment.startIndex, offsetBy: 3)
            return String(comment.suffix(from: startIndex))
        case let .lineComment(comment):
            guard !onlyDocComment else { return nil }
            let startIndex = comment.index(comment.startIndex, offsetBy: 2)
            return String(comment.suffix(from: startIndex))
        case let .docBlockComment(comment):
            let startIndex = comment.index(comment.startIndex, offsetBy: 3)
            let endIndex = comment.index(comment.endIndex, offsetBy: -2)
            return String(comment[startIndex..<endIndex])
        case let .blockComment(comment):
            guard !onlyDocComment else { return nil }
            let startIndex = comment.index(comment.startIndex, offsetBy: 2)
            let endIndex = comment.index(comment.endIndex, offsetBy: -2)
            return String(comment[startIndex..<endIndex])
        default:
            return nil
        }
    }
}

extension LabeledExprListSyntax {

    /// Boolean literal value for the given label.
    func bool(_ name: String) -> Bool? {
        first { $0.label?.text == name }?.bool
    }
}

extension LabeledExprListSyntax.Element {

    /// Boolean value of the syntax element if it is a boolean literal.
    var bool: Bool? {
        (expression.as(BooleanLiteralExprSyntax.self)?.literal.text).map {
            $0 == "true"
        }
    }
}

extension AttributeSyntax.Arguments {

    /// Boolean literal value for the given label.
    func bool(_ name: String) -> Bool? {
        self.as(LabeledExprListSyntax.self)?.bool(name)
    }
}

/// Creates an extension declaration syntax for the given type.
func extended(type: some TypeSyntaxProtocol, with name: String) -> ExtensionDeclSyntax {
    ExtensionDeclSyntax(
        extendedType: type,
        inheritanceClause: InheritanceClauseSyntax(
            inheritedTypes: InheritedTypeListSyntax {
                InheritedTypeSyntax(
                    type: TypeSyntax(stringLiteral: name)
                )
            }
        ),
        memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax())
    )
}

extension TypeSyntax {

    /// Determines whether the type is optional.
    var isOptional: Bool {
        self.is(OptionalTypeSyntax.self)
            || self.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
            || description.hasPrefix("Optional<")
    }

    /// Determines whether the type is Void.
    var isVoid: Bool {
        ["Void", "()"].contains(trimmed.description)
    }
}
#endif
