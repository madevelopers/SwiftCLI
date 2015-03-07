//
//  Command.swift
//  SwiftCLI
//
//  Created by Jake Heiser on 7/11/14.
//  Copyright (c) 2014 jakeheis. All rights reserved.
//

import Foundation

enum CommandResult {
    case Success
    case Failure(String)
}

class Command: NSObject {
    
    var arguments: CommandArguments = CommandArguments(keyedArguments: [:])
    var options: Options = Options()
    
    var usageStatements: [String] = []
    var showingHelp = false
    
    // MARK: - Command info
    
    /**
    *  The name this command can be invoked with
    *
    *  @return the command name
    */
    func commandName() -> String {
        assert(false, "Subclasses of Command must override this method")
        return ""
    }
    
    /**
    *  The signature for this command
    *
    *  @return the command signature
    */
    func commandSignature() -> String {
        return ""
    }
    
    /**
    *  A short description for this command printed by the HelpCommand
    *
    *  @return the short description
    */
    func commandShortDescription() -> String {
        return ""
    }
    
    /**
    *  A shortcut for this command prefixed with "-"; e.g. "-h" for help, "-v" for version
    *
    *  @return the shortcut
    */
    func commandShortcut() -> String? {
        return nil
    }
    
    /**
    *  The usage statement for this command, including the signature and available options
    *
    *  @param commandName the name used to invoke this command
    *
    *  @return the usage statement
    */
    func commandUsageStatement(commandName givenCommandName: String? = nil) -> String {
        var message = "Usage: \(CLI.appName())"
        
        let name = givenCommandName ?? commandName()
        if !name.isEmpty {
            message += " \(name)"
        }

        if !commandSignature().isEmpty {
            message += " \(commandSignature())"
        }
        
        if usageStatements.count > 0 {
            message += " [options]\n"
            
            for usage in usageStatements {
                message += "\n\(usage)"
            }
            
            message += "\n"
        } else {
            message += "     (no options)\n"
        }
        
        return message
    }
    
    // MARK: - Options
    
    final func setupExpectedOptions() {
        handleOptions()
        
        if showHelpOnHFlag() {
            onFlags(["-h", "--help"], usage: "Show help information for this command") {(flag) in
                self.showingHelp = true
                
                println(self.commandUsageStatement())
            }
        }
    }
    
    final func separateCommandArgumentsAndOptions(arguments: RawArguments) -> [String]? {
        let commandArguments = options.separateCommandArgumentsAndOptions(rawArguments: arguments)
        
        if options.misusedOptionsPresent() {
            if let message = misusedOptionsMessage(arguments: arguments) {
                printlnError(message)
            }
            if failOnUnrecognizedOptions() {
                return nil
            }
        }

        return commandArguments
    }
    
    func misusedOptionsMessage(#arguments: RawArguments) -> String? {
        if unrecognizedOptionsPrintingBehavior() == UnrecognizedOptionsPrintingBehavior.PrintNone {
            return nil
        }
        
        var message = ""
        
        if unrecognizedOptionsPrintingBehavior() != .PrintOnlyUsage {
            message += options.misusedOptionsMessage()
            
            if unrecognizedOptionsPrintingBehavior() == .PrintAll {
               message += "\n"
            }
        }
        
        if unrecognizedOptionsPrintingBehavior() != .PrintOnlyUnrecognizedOptions {
            message += commandUsageStatement(commandName: arguments.commandName)
        }
        
        return message
    }
    
    // MARK: On options
    
    final func onFlag(flag: String, usage: String = "", block: OptionsFlagBlock?) {
        onFlags([flag], usage: usage, block: block)
    }
    
    final func onFlags(flags: [String], usage: String = "", block: OptionsFlagBlock?) {
        let comps = ", ".join(flags)
        let padded = padString(usage, toLength: 40, firstComponent: comps)
        usageStatements.append("\(comps)\(padded)")
        
        options.onFlags(flags, block: block)
    }
    
    final func onKey(key: String, usage: String = "", valueSignature: String = "value", block: OptionsKeyBlock?) {
        onKeys([key], usage: usage, valueSignature: valueSignature, block: block)
    }
    
    final func onKeys(keys: [String], usage: String = "", valueSignature: String = "value", block: OptionsKeyBlock?) {
        let comps = ", ".join(keys)
        let firstPart = "\(comps) <\(valueSignature)>"
        let padded = padString(usage, toLength: 40, firstComponent: firstPart)
        usageStatements.append("\(firstPart)\(padded)")
        
        options.onKeys(keys, block: block)
    }
    
    // MARK: Sublcass option config
    
    /**
    *  Method where all onFlag(s) and onKey(s) calls should be made
    */
    func handleOptions() {
        
    }
    
    /**
    *  Describes if this command should print its usage statement when passed the "-h" flag
    *
    *  @return if usage statement should be printed
    */
    func showHelpOnHFlag() -> Bool {
        return true
    }
    
    enum UnrecognizedOptionsPrintingBehavior {
        case PrintNone
        case PrintOnlyUnrecognizedOptions
        case PrintOnlyUsage
        case PrintAll
    }

    /**
    *  The printing behavior of this command when it is passed an unrecognized option
    *
    *  @return the printing behavior
    */
    func unrecognizedOptionsPrintingBehavior() -> UnrecognizedOptionsPrintingBehavior {
        return .PrintAll
    }
    
    /**
    *  Describes if this command should fail on unrecognized options
    *
    *  @return if command should fail on unrecognized options
    */
    func failOnUnrecognizedOptions() -> Bool {
        return true
    }
    
    // MARK: - Execution
    
    func execute() -> CommandResult {
        return .Success
    }
    
    // MARK - Helper
    
    final func padString(string: String, toLength: Int, firstComponent: String) -> String {
        var spacing = ""
        for _ in count(firstComponent)...toLength {
            spacing += " "
        }
        
        return "\(spacing)\(string)"
    }
    
}
