#!/usr/bin/env swift

import Foundation

guard let packagePath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : nil else {
    print("Usage: swift fix_package.swift Package.swift")
    exit(1)
}

do {
    let packageContent = try String(contentsOfFile: packagePath)
    var lines = packageContent.components(separatedBy: .newlines)
    
    // Find the test target section
    var testTargetIdx = -1
    var testTargetNameIdx = -1
    var testTargetPathIdx = -1
    var testTargetEndIdx = -1
    var targetListEndIdx = -1
    
    for (idx, line) in lines.enumerated() {
        if line.contains(".testTarget(") {
            testTargetIdx = idx
        } else if testTargetIdx != -1 && line.contains("name: \"MiddlewareConnectTests\"") {
            testTargetNameIdx = idx
        } else if testTargetNameIdx != -1 && line.contains("path:") {
            testTargetPathIdx = idx
        } else if testTargetPathIdx != -1 && line.contains("),") {
            testTargetEndIdx = idx
            break
        }
    }
    
    // Find end of targets list
    for (idx, line) in lines.enumerated() {
        if line.contains("])") && idx > testTargetEndIdx {
            targetListEndIdx = idx
            break
        }
    }
    
    guard testTargetIdx != -1 && testTargetNameIdx != -1 && testTargetPathIdx != -1 && 
          testTargetEndIdx != -1 && targetListEndIdx != -1 else {
        print("Could not find all required sections in Package.swift")
        exit(1)
    }
    
    // Modify the path to be specific to MiddlewareConnectTests
    if let pathLine = lines[testTargetPathIdx].range(of: "path:") {
        lines[testTargetPathIdx] = lines[testTargetPathIdx].replacingCharacters(
            in: pathLine.upperBound..<lines[testTargetPathIdx].endIndex,
            with: " \"Tests/MiddlewareConnectTests\","
        )
    }
    
    // Insert the new LLMServiceProviderTests target
    let newTestTarget = [
        "        .testTarget(",
        "            name: \"LLMServiceProviderTests\",",
        "            dependencies: [\"MiddlewareConnect\"],",
        "            path: \"Tests/LLMServiceProviderTests\",",
        "        ),"
    ]
    
    // Insert the new target before the end of the targets list
    lines.insert(contentsOf: newTestTarget, at: targetListEndIdx)
    
    // Write the modified content back to the file
    try lines.joined(separator: "\n").write(to: URL(fileURLWithPath: packagePath), atomically: true, encoding: .utf8)
    print("✅ Successfully updated \(packagePath) to separate test targets")
    
} catch {
    print("❌ Error: \(error)")
    exit(1)
}
