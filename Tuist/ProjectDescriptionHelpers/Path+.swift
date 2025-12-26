//
//  Path+.swift
//  AppManifests
//
//  Created by 영준 이 on 11/29/24.
//

import Foundation
import ProjectDescription

public extension Path {
    static func projects(_ path: String) -> Path { .relativeToRoot("Projects/\(path)") }
    
    static var extensions: Extensions { Extensions() }
    
    struct Extensions {
        public var widget: Path { .relativeToCurrentFile("Extensions/Widget") }
    }
}

// For sources
public func + (lhs: Path, rhs: String) -> SourceFileGlob {
    .init(stringLiteral: "\(lhs.pathString)\(rhs)")
}

public func + (lhs: Path, rhs: String) -> SourceFilesList {
    .init(stringLiteral: "\(lhs.pathString)\(rhs)")
}

// For resources
public func + (lhs: Path, rhs: String) -> ResourceFileElement {
    .init(stringLiteral: "\(lhs.pathString)\(rhs)")
}

public func + (lhs: Path, rhs: String) -> ResourceFileElements {
    .init(stringLiteral: "\(lhs.pathString)\(rhs)")
}

// For xcconfig paths
public func + (lhs: Path, rhs: Path) -> Path {
    .path("\(lhs.pathString)\(rhs.pathString)")
}
