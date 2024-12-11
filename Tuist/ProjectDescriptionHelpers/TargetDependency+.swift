//
//  TargetDependency+.swift
//  AppManifests
//
//  Created by 영준 이 on 11/29/24.
//

import Foundation
import ProjectDescription

// MARK: Store Projects
public extension TargetDependency {
    private static func targetProject(_ name: String) -> TargetDependency {
        return .project(target: name, path: .projects(name))
    }
    
    class Projects {
        public static let ThirdParty: TargetDependency = .targetProject("ThirdParty")
        public static let DynamicThirdParty: TargetDependency = .targetProject("DynamicThirdParty")
    }
}
