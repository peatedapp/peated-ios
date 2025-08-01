import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct PeatedCoreMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = []
}