import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "ThirdParty",
    packages: [
        .remote(url: "https://github.com/CoreOffice/CoreXLSX",
                               requirement: .exact("0.14.1")),
        .remote(url: "https://github.com/AssistoLab/DropDown",
                requirement: .branch("master")),
        .remote(url: "https://github.com/kakao/kakao-ios-sdk",
                requirement: .upToNextMajor(from: "2.22.2")),
        .remote(url: "https://github.com/2sem/LProgressWebViewController",
                requirement: .upToNextMajor(from: "3.1.0")),
        .remote(url: "https://github.com/2sem/LSCountDownLabel",
                requirement: .upToNextMajor(from: "0.0.5")),
//        .local(path: "../../../../../pods/LSCountDownLabel/src/LSCountDownLabel"),
        .remote(url: "https://github.com/scalessec/Toast-Swift",
                requirement: .upToNextMajor(from: "5.1.0")),
        .remote(url: "https://github.com/alexiscreuzot/SwiftyGif",
                requirement: .upToNextMajor(from: "5.4.5")),
        .remote(url: "https://github.com/2sem/LSExtensions",
                requirement: .exact("0.1.22")),
        .remote(url: "https://github.com/ReactiveX/RxSwift",
                requirement: .upToNextMajor(from: "5.1.0")),
        .remote(url: "https://github.com/2sem/LProgressWebViewController",
                requirement: .upToNextMajor(from: "3.1.0")),
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
                           .package(product: "DropDown", type: .runtime),
                           .package(product: "KakaoSDK", type: .runtime),
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
