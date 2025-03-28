#if canImport(SwiftCompilerPlugin)
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public struct TweenableMacro: ExtensionMacro, MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try _expansion(of: node, providingMembersOf: declaration, in: context)
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        [extended(type: type, with: "Tweenable")]
    }
}

private func _expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
) throws -> [DeclSyntax] {
    guard declaration.is(StructDeclSyntax.self) else {
        throw StringError("Only structs are supported")
    }
    // check if already has mock, if so, skip
    guard
        !declaration.memberBlock.members.contains(where: {
            if let function = $0.decl.as(FunctionDeclSyntax.self) {
                function.name.text == "lerp" && function.modifiers.contains(where: \.name.isStatic)
            } else {
                false
            }
        })
    else {
        return []
    }
    var initValues: [(String, String)] = []
    for member in declaration.memberBlock.members {

        // check for stored properties

        // skip static and lazy vars
        guard
            let variable = member.decl.as(VariableDeclSyntax.self),
            !variable.modifiers.contains(where: {
                $0.name.isStatic || $0.name.isLazy
            }),
            !variable.bindings.contains(where: {
                $0.accessorBlock?.accessors.is(CodeBlockItemListSyntax.self) == true ||
                $0.accessorBlock?.accessors.as(AccessorDeclListSyntax.self)?
                    .contains(where: { $0.accessorSpecifier.text == "get" }) == true
            })
        else {
            continue
        }

        for binding in variable.bindings {
            // variables with default values or optionals can be skipped in the synthetic initializer
            guard
                let identifier = binding.pattern.as(IdentifierPatternSyntax.self)
            else {
                continue
            }
            
            if variable.bindingSpecifier.isLet {
                throw StringError("Tweenable macro doesn't support let, change it to 'var \(identifier.identifier.trimmedName)'")
            }

            // skip computed properties
            if let closure = binding.accessorBlock {
                guard
                    let list = closure.accessors.as(AccessorDeclListSyntax.self),
                    list.contains(where: \.accessorSpecifier.isWillSetOrDidSet)
                else {
                    continue
                }
            }
            try initValues.append((identifier.identifier.trimmedName, mockValue(for: identifier.identifier.trimmedName)))
        }
    }
    return lerpFunc(parameters: initValues)
}

func mockValue(for name: String) throws -> String {
    "_lerp(lhs.\(name), rhs.\(name), t)"
}

private func lerpFunc(parameters: [(String, String)]?) -> [DeclSyntax] {
    if let parameters {
        let initLines = parameters.map {
            "\n        result.\($0.0) = \($0.1)"
        }
        .joined()
        return lerpFunc(value: initLines)
    } else {
        return lerpFunc(value: "")
    }
}

private func lerpFunc(value: String) -> [DeclSyntax] {
    ["""
     
         public static func lerp(_ lhs: Self, _ rhs: Self, _ t: Double) -> Self {
             var result = lhs
             \(raw: value)
             return result
         }
     """]
}

private func mockParameters(for parameters: FunctionParameterListSyntax) throws -> [(String, String)] {
    try parameters.compactMap {
        guard $0.defaultValue == nil else { return nil }
        return try ($0.firstName.trimmedName.description, mockValue(for: $0.firstName.trimmedName.description))
    }
}

private func mockParameters(for parameters: EnumCaseParameterListSyntax) throws -> [(String, String)] {
    try parameters.compactMap {
        guard $0.defaultValue == nil else { return nil }
        return try ($0.firstName?.trimmed.description ?? "_", mockValue(for: $0.firstName?.trimmed.description ?? ""))
    }
}
#endif
