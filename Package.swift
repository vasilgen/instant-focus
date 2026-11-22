// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "InstantFocus",
    platforms: [.macOS(.v13)],
    targets: [
        // Vendored, unmodified, from jurplel/InstantSpaceSwitcher (MIT).
        // See Sources/ISS/VERSION and scripts/vendor-iss.sh.
        .target(
            name: "ISS",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("CoreFoundation"),
                .linkedFramework("IOKit"),
            ]
        ),
        .executableTarget(name: "InstantFocus", dependencies: ["ISS"]),
    ]
)
