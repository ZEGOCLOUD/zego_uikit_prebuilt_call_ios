//
//  NibBundleResolutionTests.swift
//  ZegoUIKitPrebuiltCallTests
//
//  Coverage for BUG-20260604-001 (NIB loading bundle path issue, fix 54fc915).
//
//  These tests exercise `Bundle.resolveNibBundle(nibName:classBundle:mainBundle:)`,
//  the pure resolution core behind `Bundle.nibBundle(forClass:)`, by synthesizing
//  on-disk bundles that mimic each CocoaPods integration mode. No Xcode project,
//  no simulator and no device are required beyond a Swift toolchain.
//
//  Integration modes covered:
//    A. framework mode           - nib sits directly in the class bundle
//    B. resource_bundle mode     - nib sits in the nested ZegoUIKitPrebuiltCall.bundle
//                                  (this is what the podspec fix in 54fc915 produces)
//    C. source files mode        - nib ends up in the host app's main bundle
//    D. not-found                - nib is nowhere; documents the known last-resort path
//

import XCTest
@testable import ZegoUIKitPrebuiltCall

final class NibBundleResolutionTests: XCTestCase {

    /// Name of the nested resource bundle created by `spec.resource_bundle` in the podspec.
    private let resourceBundleName = "ZegoUIKitPrebuiltCall"

    private var sandbox: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sandbox = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("nib-bundle-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: sandbox, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let sandbox = sandbox {
            try? FileManager.default.removeItem(at: sandbox)
        }
        sandbox = nil
        try super.tearDownWithError()
    }

    // MARK: - Helpers

    /// Creates an empty `<name>.bundle` directory inside `parent` and loads it.
    ///
    /// `Bundle(path:)` accepts any directory, and `path(forResource:ofType:)` resolves
    /// against the bundle's resource path, so a plain directory holding `<nib>.nib`
    /// files is enough to drive the resolution logic without invoking `ibtool`.
    private func makeBundle(named name: String, in parent: URL) throws -> Bundle {
        let url = parent.appendingPathComponent("\(name).bundle")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return try XCTUnwrap(Bundle(url: url), "failed to load synthesized bundle at \(url.path)")
    }

    /// Drops a placeholder `<nibName>.nib` into `bundle`'s resource directory.
    ///
    /// The resolution logic only probes for existence via `path(forResource:ofType:)`,
    /// so the payload is irrelevant here - a compiled nib would require macOS tooling.
    private func placeNib(_ nibName: String, in bundle: Bundle) throws {
        let resourceDirectory = URL(fileURLWithPath: try XCTUnwrap(bundle.resourcePath))
        try FileManager.default.createDirectory(at: resourceDirectory, withIntermediateDirectories: true)
        let nib = resourceDirectory.appendingPathComponent("\(nibName).nib")
        try Data().write(to: nib)
    }

    // MARK: - Mode A: framework integration

    func testResolvesToClassBundleWhenNibSitsDirectlyInIt() throws {
        let nibName = "ZegoUIKitPrebuiltCallWaitingVC"
        let classBundle = try makeBundle(named: "Framework", in: sandbox)
        let mainBundle = try makeBundle(named: "Main", in: sandbox)
        try placeNib(nibName, in: classBundle)

        let resolved = Bundle.resolveNibBundle(nibName: nibName,
                                               classBundle: classBundle,
                                               mainBundle: mainBundle)

        XCTAssertEqual(resolved.bundlePath, classBundle.bundlePath)
        XCTAssertNotNil(resolved.path(forResource: nibName, ofType: "nib"))
    }

    // MARK: - Mode B: resource_bundle integration (the 54fc915 podspec fix)

    func testResolvesToNestedResourceBundleWhenNibWasMovedThere() throws {
        let nibName = "ZegoCallInvitationDialog"
        let classBundle = try makeBundle(named: "Framework", in: sandbox)
        let mainBundle = try makeBundle(named: "Main", in: sandbox)

        // Mirrors `spec.resource_bundle = {'ZegoUIKitPrebuiltCall' => [... '**/*.{xib}']}`:
        // the nib no longer lives in the class bundle, only in the nested resource bundle.
        let resourceBundle = try makeBundle(named: resourceBundleName,
                                            in: URL(fileURLWithPath: try XCTUnwrap(classBundle.resourcePath)))
        try placeNib(nibName, in: resourceBundle)

        let resolved = Bundle.resolveNibBundle(nibName: nibName,
                                               classBundle: classBundle,
                                               mainBundle: mainBundle)

        XCTAssertEqual(resolved.bundlePath, resourceBundle.bundlePath)
        XCTAssertNotNil(resolved.path(forResource: nibName, ofType: "nib"))
    }

    // MARK: - Mode C: source files integration

    func testFallsBackToMainBundleWhenNibOnlyExistsThere() throws {
        let nibName = "ZegoUIKitPrebuiltCallWaitingVC"
        let classBundle = try makeBundle(named: "Framework", in: sandbox)
        let mainBundle = try makeBundle(named: "Main", in: sandbox)
        try placeNib(nibName, in: mainBundle)

        let resolved = Bundle.resolveNibBundle(nibName: nibName,
                                               classBundle: classBundle,
                                               mainBundle: mainBundle)

        XCTAssertEqual(resolved.bundlePath, mainBundle.bundlePath)
        XCTAssertNotNil(resolved.path(forResource: nibName, ofType: "nib"))
    }

    // MARK: - Precedence between modes

    func testClassBundleWinsOverNestedResourceBundle() throws {
        let nibName = "ZegoCallInvitationDialog"
        let classBundle = try makeBundle(named: "Framework", in: sandbox)
        let mainBundle = try makeBundle(named: "Main", in: sandbox)
        let resourceBundle = try makeBundle(named: resourceBundleName,
                                            in: URL(fileURLWithPath: try XCTUnwrap(classBundle.resourcePath)))
        try placeNib(nibName, in: classBundle)
        try placeNib(nibName, in: resourceBundle)

        let resolved = Bundle.resolveNibBundle(nibName: nibName,
                                               classBundle: classBundle,
                                               mainBundle: mainBundle)

        XCTAssertEqual(resolved.bundlePath, classBundle.bundlePath)
    }

    func testNestedResourceBundleWinsOverMainBundle() throws {
        let nibName = "ZegoCallInvitationDialog"
        let classBundle = try makeBundle(named: "Framework", in: sandbox)
        let mainBundle = try makeBundle(named: "Main", in: sandbox)
        let resourceBundle = try makeBundle(named: resourceBundleName,
                                            in: URL(fileURLWithPath: try XCTUnwrap(classBundle.resourcePath)))
        try placeNib(nibName, in: resourceBundle)
        try placeNib(nibName, in: mainBundle)

        let resolved = Bundle.resolveNibBundle(nibName: nibName,
                                               classBundle: classBundle,
                                               mainBundle: mainBundle)

        XCTAssertEqual(resolved.bundlePath, resourceBundle.bundlePath)
    }

    /// A nested resource bundle that exists but does not carry the nib must not
    /// short-circuit the search - the main bundle still has to be consulted.
    func testEmptyResourceBundleDoesNotShadowMainBundle() throws {
        let nibName = "ZegoUIKitPrebuiltCallWaitingVC"
        let classBundle = try makeBundle(named: "Framework", in: sandbox)
        let mainBundle = try makeBundle(named: "Main", in: sandbox)
        _ = try makeBundle(named: resourceBundleName,
                           in: URL(fileURLWithPath: try XCTUnwrap(classBundle.resourcePath)))
        try placeNib(nibName, in: mainBundle)

        let resolved = Bundle.resolveNibBundle(nibName: nibName,
                                               classBundle: classBundle,
                                               mainBundle: mainBundle)

        XCTAssertEqual(resolved.bundlePath, mainBundle.bundlePath)
    }

    // MARK: - Mode D: nib missing everywhere

    /// Documents the known residual risk flagged in DevReview on 2026-07-26: when the
    /// nib is genuinely absent, the helper returns the class bundle, which reproduces
    /// the original `Could not load NIB in bundle` crash at the call site.
    ///
    /// This is a characterization test. If a future change adds a `.bundle`/`.framework`
    /// path scan as an absolute last resort, this expectation is expected to change.
    func testReturnsClassBundleWhenNibIsMissingEverywhere() throws {
        let nibName = "ZegoUIKitPrebuiltCallWaitingVC"
        let classBundle = try makeBundle(named: "Framework", in: sandbox)
        let mainBundle = try makeBundle(named: "Main", in: sandbox)

        let resolved = Bundle.resolveNibBundle(nibName: nibName,
                                               classBundle: classBundle,
                                               mainBundle: mainBundle)

        XCTAssertEqual(resolved.bundlePath, classBundle.bundlePath)
        XCTAssertNil(resolved.path(forResource: nibName, ofType: "nib"),
                     "nib must stay unresolved - this test pins the known crash path, not a fix")
    }

    func testResolutionIsDeterministicAcrossRepeatedCalls() throws {
        let nibName = "ZegoCallInvitationDialog"
        let classBundle = try makeBundle(named: "Framework", in: sandbox)
        let mainBundle = try makeBundle(named: "Main", in: sandbox)
        let resourceBundle = try makeBundle(named: resourceBundleName,
                                            in: URL(fileURLWithPath: try XCTUnwrap(classBundle.resourcePath)))
        try placeNib(nibName, in: resourceBundle)

        let first = Bundle.resolveNibBundle(nibName: nibName, classBundle: classBundle, mainBundle: mainBundle)
        let second = Bundle.resolveNibBundle(nibName: nibName, classBundle: classBundle, mainBundle: mainBundle)

        XCTAssertEqual(first.bundlePath, second.bundlePath)
    }

    // MARK: - Public entry point

    /// `nibBundle(forClass:)` derives the nib name from the class itself; the two
    /// shipped view classes must keep matching their `.xib` file names, otherwise the
    /// lookup silently degrades to the crash path exercised above.
    func testNibNameIsDerivedFromClassName() {
        XCTAssertEqual(String(describing: ZegoUIKitPrebuiltCallWaitingVC.self),
                       "ZegoUIKitPrebuiltCallWaitingVC")
        XCTAssertEqual(String(describing: ZegoCallInvitationDialog.self),
                       "ZegoCallInvitationDialog")
    }

    func testNibBundleForClassNeverReturnsNilAndStaysStable() {
        let first = Bundle.nibBundle(forClass: ZegoUIKitPrebuiltCallWaitingVC.self)
        let second = Bundle.nibBundle(forClass: ZegoUIKitPrebuiltCallWaitingVC.self)

        XCTAssertEqual(first.bundlePath, second.bundlePath)
    }

    // MARK: - Source-vs-compiled nib suffix contract

    /// Pins the contract that the resolver only looks for the compiled `.nib`
    /// payload, not the source `.xib` placeholder that the podspec lists under
    /// `resource_bundle`. Pods ship the compiled `.nib` next to the `.xib`, but
    /// if a future change ever probed `.xib` it would mask real resolution
    /// failures - this test guards that regression.
    func testResolvesByNibOnlyAndIgnoresXibPlaceholder() throws {
        let nibName = "ZegoCallInvitationDialog"
        let classBundle = try makeBundle(named: "Framework", in: sandbox)
        let mainBundle = try makeBundle(named: "Main", in: sandbox)

        // Drop a `.xib` source placeholder in the resource bundle - this mimics
        // what the 54fc915 podspec lists under `resource_bundle`. The resolver
        // must NOT treat it as a hit.
        let resourceBundle = try makeBundle(named: resourceBundleName,
                                            in: URL(fileURLWithPath: try XCTUnwrap(classBundle.resourcePath)))
        let resourceResourceDir = URL(fileURLWithPath: try XCTUnwrap(resourceBundle.resourcePath))
        try FileManager.default.createDirectory(at: resourceResourceDir, withIntermediateDirectories: true)
        try Data().write(to: resourceResourceDir.appendingPathComponent("\(nibName).xib"))

        // Real `.nib` lives only in main bundle (source files integration).
        try placeNib(nibName, in: mainBundle)

        let resolved = Bundle.resolveNibBundle(nibName: nibName,
                                               classBundle: classBundle,
                                               mainBundle: mainBundle)

        XCTAssertEqual(resolved.bundlePath, mainBundle.bundlePath,
                       "resolver must skip .xib source and land on the compiled .nib in main bundle")
        XCTAssertNotNil(resolved.path(forResource: nibName, ofType: "nib"))
    }

    // MARK: - In-process / shared bundle edge case

    /// When the host app is itself the framework target (e.g. an example app
    /// that links the SDK as source files in the same module), `Bundle(for:)`
    /// and `Bundle.main` can resolve to the same bundle. The helper must not
    /// double-traverse or recurse in that scenario - it just returns whichever
    /// one actually holds the nib.
    func testClassBundleAndMainBundleAreSameInstance() throws {
        let nibName = "ZegoUIKitPrebuiltCallWaitingVC"
        let shared = try makeBundle(named: "Shared", in: sandbox)
        try placeNib(nibName, in: shared)

        let resolved = Bundle.resolveNibBundle(nibName: nibName,
                                               classBundle: shared,
                                               mainBundle: shared)

        XCTAssertEqual(resolved.bundlePath, shared.bundlePath)
        XCTAssertNotNil(resolved.path(forResource: nibName, ofType: "nib"))

        // And when the shared bundle also lacks the nib, the helper must still
        // hand back that single bundle (no loop, no nil, no crash).
        let empty = try makeBundle(named: "SharedEmpty", in: sandbox)
        let resolvedEmpty = Bundle.resolveNibBundle(nibName: nibName,
                                                    classBundle: empty,
                                                    mainBundle: empty)
        XCTAssertEqual(resolvedEmpty.bundlePath, empty.bundlePath)
        XCTAssertNil(resolvedEmpty.path(forResource: nibName, ofType: "nib"))
    }

    // MARK: - Empty nib name

    /// Characterization test: the helper does not special-case the empty
    /// nib name - it relies on `path(forResource:ofType:)` returning nil and
    /// falling through. This test pins that behavior so a future \"guard\"
    /// change would have to be a deliberate update, not an accidental one.
    func testEmptyNibNameFallsThroughToClassBundle() throws {
        let nibName = ""
        let classBundle = try makeBundle(named: "Framework", in: sandbox)
        let mainBundle = try makeBundle(named: "Main", in: sandbox)

        let resolved = Bundle.resolveNibBundle(nibName: nibName,
                                               classBundle: classBundle,
                                               mainBundle: mainBundle)

        XCTAssertEqual(resolved.bundlePath, classBundle.bundlePath,
                       "empty nib name must fall through every check and return class bundle")
        XCTAssertNil(resolved.path(forResource: nibName, ofType: "nib"))
    }

    // MARK: - Precedence: both bundles carry the same nib

    /// Re-asserts the framework-first ordering when BOTH the class bundle and
    /// the nested resource bundle carry a copy of the same nib. Pinned against
    /// a hypothetical future change that might reorder the chain for
    /// \"performance\" - framework integration is the supported happy path and
    /// must keep winning.
    func testPicksClassBundleWhenBothClassAndResourceBundleContainSameNib() throws {
        let nibName = "ZegoCallInvitationDialog"
        let classBundle = try makeBundle(named: "Framework", in: sandbox)
        let mainBundle = try makeBundle(named: "Main", in: sandbox)
        let resourceBundle = try makeBundle(named: resourceBundleName,
                                            in: URL(fileURLWithPath: try XCTUnwrap(classBundle.resourcePath)))
        try placeNib(nibName, in: classBundle)
        try placeNib(nibName, in: resourceBundle)

        let resolved = Bundle.resolveNibBundle(nibName: nibName,
                                               classBundle: classBundle,
                                               mainBundle: mainBundle)

        XCTAssertEqual(resolved.bundlePath, classBundle.bundlePath,
                       "class bundle must win over nested resource bundle when both carry the nib")
        XCTAssertNotNil(resolved.path(forResource: nibName, ofType: "nib"))
    }
}
