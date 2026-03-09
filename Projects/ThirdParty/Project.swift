import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "ThirdParty",
    packages: [
        .package(id: "coreoffice.CoreXLSX", from: "0.14.2"),
        .package(id: "alamofire.Alamofire", from: "5.11.1"),
        .remote(url: "https://github.com/AssistoLab/DropDown",
                requirement: .branch("master")),
        .remote(url: "https://github.com/2sem/LProgressWebViewController",
                requirement: .upToNextMajor(from: "3.1.0")),
        .remote(url: "https://github.com/2sem/LSCountDownLabel",
                requirement: .upToNextMajor(from: "0.0.5")),
        .package(id: "scalessec.Toast-Swift", from: "5.1.1"),
        .package(id: "alexiscreuzot.SwiftyGif", from: "5.4.5"),
        .remote(url: "https://github.com/2sem/LSExtensions",
                requirement: .upToNextMajor(from: "0.1.23")),
        .package(id: "reactivex.RxSwift", from: "5.1.3"),
        .remote(url: "https://github.com/2sem/StringLogger",
                requirement: .upToNextMajor(from: "0.7.0"))
    ],
    targets: [
        .target(
            name: "ThirdParty",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: .appBundleId.appending(".thirdparty"),
            dependencies: [.package(product: "CoreXLSX", type: .runtime),
                           .package(product: "Alamofire", type: .runtime),
                           .package(product: "DropDown", type: .runtime),
                           .package(product: "ProgressWebViewController", type: .runtime),
                           .package(product: "LSCountDownLabel", type: .runtime),
                           .package(product: "Toast", type: .runtime),
                           .package(product: "LSExtensions", type: .runtime),
                           .package(product: "SwiftyGif", type: .runtime),
                           .package(product: "RxSwift", type: .runtime),
                           .package(product: "RxCocoa", type: .runtime),
                           .package(product: "StringLogger", type: .runtime),
            ]
        ),
    ]
)
