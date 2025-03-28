#if canImport(SwiftCompilerPlugin)
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

@main
struct VDAnimationMacrosPlugin: CompilerPlugin {

    let providingMacros: [Macro.Type] = [
        TweenableMacro.self
    ]
}
#endif
