//
//  Path+.swift
//  AppManifests
//
//  Created by 영준 이 on 11/29/24.
//

import Foundation
import ProjectDescription

public extension SourceFileGlob {
    static var extensions: Extensions { Extensions() }
    
    struct Extensions {
        public var widget: Path { .relativeToCurrentFile("Extensions/Widget") }
    }
}
