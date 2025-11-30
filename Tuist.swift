//
//  Tuist.swift
//  realtornoteManifests
//
//  Created by 영준 이 on 3/9/25.
//

import ProjectDescription

let tuist = Tuist(
    fullHandle: "gamehelper/realtornote",
    project: .tuist(compatibleXcodeVersions: .upToNextMajor("26.0"),
                    generationOptions: .options(
                        enableCaching: true
                    )
//                    swiftVersion: "",
//                    plugins: <#T##[PluginLocation]#>,
//                    generationOptions: <#T##Tuist.GenerationOptions#>,
//                    installOptions: <#T##Tuist.InstallOptions#>)
    )
)
