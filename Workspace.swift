import ProjectDescription

fileprivate let projects: [Path] = ["App", "ThirdParty"]
    .map{ "Projects/\($0)" }

let workspace = Workspace(name: "realtornote", projects: projects)
