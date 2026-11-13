import XCTest

@MainActor
final class WorkspaceUITests: XCTestCase {
    func testLibrarySearchRecoveryAndWorkspaceNavigation() {
        let app = XCUIApplication(); app.launch()
        let search = app.textFields["experimentSearch"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.click(); search.typeText("torus")
        XCTAssertTrue(app.buttons["library.torusGeodesics"].exists)
        XCTAssertTrue(app.buttons["library.torus"].exists)
        XCTAssertFalse(app.buttons["library.lorenz"].exists)
        app.buttons["library.torusGeodesics"].click()
        XCTAssertTrue(app.buttons["geodesicPause"].waitForExistence(timeout: 5))
        app.buttons["geodesicPause"].click()
        app.buttons["libraryToggle"].click()
        XCTAssertFalse(search.exists)
        XCTAssertTrue(app.buttons["geodesicStep"].isEnabled)
        app.buttons["librarySearchButton"].click()
        XCTAssertTrue(search.exists)
        search.click(); app.typeKey("a", modifierFlags: .command)
        search.typeText("no-such-experiment")
        XCTAssertTrue(app.buttons["clearLibraryFilters"].exists)
        app.buttons["clearLibraryFilters"].click()
        XCTAssertTrue(app.buttons["library.lorenz"].exists)
        XCTAssertTrue(app.buttons["geodesicStep"].isEnabled)
        capture("Library beside paused workspace", app: app)
    }

    func testGalleryBlankAndInspector() {
        let app = XCUIApplication()
        app.launch()
        let blank = app.buttons["blankScene"]
        XCTAssertTrue(blank.waitForExistence(timeout: 5))
        capture("Gallery", app: app)
        blank.click()
        XCTAssertTrue(app.buttons["restorePlacement"].waitForExistence(timeout: 5))
        capture("Blank workspace", app: app)
        app.buttons["inspectorToggle"].click()
        XCTAssertFalse(app.buttons["restorePlacement"].exists)
        app.buttons["inspectorToggle"].click()
        XCTAssertTrue(app.buttons["restorePlacement"].exists)
        app.buttons["galleryButton"].click()
        XCTAssertTrue(app.buttons["trianglePreset"].waitForExistence(timeout: 5))
        for _ in 0..<16 {
            if app.buttons["trianglePreset"].isHittable { break }
            app.scrollViews.firstMatch.scroll(byDeltaX: 0, deltaY: -180)
        }
        app.buttons["trianglePreset"].click()
        XCTAssertTrue(app.staticTexts["3 vertices / 1 triangle"].exists)
        XCTAssertFalse(app.staticTexts["renderFailure"].exists)
        capture("Triangle workspace", app: app)
    }

    func testInspectorDragAndRestore() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["blankScene"].click()
        let handle = app.descendants(matching: .any)["inspectorHandle"].firstMatch
        XCTAssertTrue(handle.waitForExistence(timeout: 5))
        app.buttons["restorePlacement"].click()
        let original = handle.frame.origin
        let start = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: -180, dy: 100)))
        XCTAssertLessThan(handle.frame.minX, original.x - 100)
        app.buttons["restorePlacement"].click()
        XCTAssertEqual(handle.frame.minX, original.x, accuracy: 2)
        XCTAssertEqual(handle.frame.minY, original.y, accuracy: 2)
        handle.click()
        app.typeKey(.leftArrow, modifierFlags: [])
        XCTAssertLessThan(handle.frame.minX, original.x)
        capture("Inspector keyboard focus", app: app)
        let moved = handle.frame.origin
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["blankScene"].waitForExistence(timeout: 5))
        app.buttons["blankScene"].click()
        XCTAssertTrue(handle.waitForExistence(timeout: 5))
        XCTAssertEqual(handle.frame.minX, moved.x, accuracy: 2)
        XCTAssertEqual(handle.frame.minY, moved.y, accuracy: 2)
        app.buttons["restorePlacement"].click()
    }

    func testInspectorResizePersistsAndDoubleClickRestoresSize() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["blankScene"].waitForExistence(timeout: 5))
        app.buttons["blankScene"].click()
        let panel = app.descendants(matching: .any)["sceneInspector"].firstMatch
        let header = app.descendants(matching: .any)["inspectorHandle"].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        header.doubleClick()
        app.buttons["restorePlacement"].click()
        let original = panel.frame
        let corner = panel.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 1))
            .withOffset(CGVector(dx: 4, dy: -4))
        corner.press(forDuration: 0.1, thenDragTo: corner.withOffset(CGVector(dx: -80, dy: 80)))
        let resized = panel.frame
        XCTAssertEqual(resized.width, original.width + 80, accuracy: 2)
        XCTAssertEqual(resized.height, original.height + 80, accuracy: 2)
        XCTAssertEqual(resized.maxX, original.maxX, accuracy: 2)
        XCTAssertEqual(resized.minY, original.minY, accuracy: 2)
        panel.scroll(byDeltaX: 0, deltaY: -80)
        XCTAssertEqual(panel.frame, resized)
        capture("Resized inspector", app: app)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["blankScene"].waitForExistence(timeout: 5))
        app.buttons["blankScene"].click()
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertEqual(panel.frame.width, resized.width, accuracy: 2)
        XCTAssertEqual(panel.frame.height, resized.height, accuracy: 2)
        XCTAssertEqual(panel.frame.minX, resized.minX, accuracy: 2)
        XCTAssertEqual(panel.frame.minY, resized.minY, accuracy: 2)
        header.doubleClick()
        XCTAssertEqual(panel.frame.width, 304, accuracy: 2)
        XCTAssertEqual(panel.frame.height, 224, accuracy: 2)
        app.buttons["restorePlacement"].click()
        app.buttons["Close Inspector"].click()
        XCTAssertFalse(panel.exists)
    }

    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testLorenzPresetsCameraTransportAndInvalidInput() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["openLorenz"].waitForExistence(timeout: 5))
        app.buttons["openLorenz"].click()
        XCTAssertTrue(app.buttons["lorenzPause"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["renderFailure"].firstMatch.exists)
        app.buttons["lorenzPause"].click()
        XCTAssertTrue(app.buttons["lorenzStep"].isEnabled)
        app.buttons["lorenzStep"].click()
        capture("Lorenz Classic", app: app)
        XCTAssertTrue(app.textFields["Fade Delay"].exists)
        XCTAssertTrue(app.textFields["Fade Duration"].exists)
        XCTAssertFalse(app.textFields["Ribbon Width"].exists)
        app.buttons["inspectorToggle"].click()
        app.typeKey(" ", modifierFlags: [])
        app.buttons["inspectorToggle"].click()
        XCTAssertFalse(app.buttons["lorenzStep"].isEnabled)
        app.typeKey(" ", modifierFlags: [])
        app.buttons["inspectorToggle"].click()
        app.typeKey("]", modifierFlags: .command)
        app.typeKey("0", modifierFlags: .command)
        app.typeKey("r", modifierFlags: .command)
        capture("Lorenz Classic clean canvas", app: app)
        app.buttons["inspectorToggle"].click()
        XCTAssertTrue(app.buttons["lorenzStep"].isEnabled)
        for preset in ["Filament", "Sculpture"] {
            app.popUpButtons["lorenzPreset"].click()
            app.menuItems[preset].click()
            XCTAssertEqual(app.textFields["Ribbon Width"].exists, preset == "Sculpture")
            capture("Lorenz \(preset)", app: app)
        }
        let footer = app.staticTexts["inspectorCameraHelp"]
        for _ in 0..<10 {
            if footer.isHittable { break }
            app.scrollViews.firstMatch.scroll(byDeltaX: 0, deltaY: -200)
        }
        XCTAssertTrue(footer.isHittable)
        let panel = app.descendants(matching: .any)["sceneInspector"].firstMatch
        XCTAssertLessThanOrEqual(footer.frame.maxY, panel.frame.maxY - 8)
        capture("Lorenz inspector footer unclipped", app: app)
        app.scrollViews.firstMatch.scroll(byDeltaX: 0, deltaY: 2400)
        let viewport = app.descendants(matching: .any)["lorenzViewport"].firstMatch
        let start = viewport.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 80, dy: 30)))
        capture("Lorenz orbit camera", app: app)
        app.buttons["cameraReset"].click()
        app.buttons["lorenzReset"].click()
        app.scrollViews.firstMatch.scroll(byDeltaX: 0, deltaY: -120)
        let sigma = app.textFields["σ"]
        sigma.click()
        app.typeKey("a", modifierFlags: .command)
        sigma.typeText("nan\r")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Enter ")).firstMatch.exists)
        capture("Lorenz invalid parameter", app: app)
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertEqual(sigma.value as? String, "10")
        sigma.click()
        app.typeKey("a", modifierFlags: .command)
        sigma.typeText("12\r")
        app.scrollViews.firstMatch.scroll(byDeltaX: 0, deltaY: 2400)
        app.buttons["lorenzReset"].click()
        XCTAssertEqual(sigma.value as? String, "12")
        XCTAssertTrue(app.buttons["lorenzStep"].isEnabled)
        app.buttons["restorePresetDefaults"].click()
        XCTAssertEqual(sigma.value as? String, "10")
        XCTAssertTrue(app.buttons["lorenzStep"].isEnabled)
        app.popUpButtons["lorenzPreset"].click()
        app.menuItems["Classic"].click()
        XCTAssertEqual(sigma.value as? String, "10")
        XCTAssertFalse(app.textFields["Ribbon Width"].exists)
        XCTAssertTrue(app.buttons["lorenzStep"].isEnabled)
    }

    func testSurfacePresetsControlsAndInspector() {
        let app = XCUIApplication()
        app.launch()
        let openSurface = app.buttons["openSurface"]
        func reveal(_ element: XCUIElement, downward: Bool = true) {
            for _ in 0..<16 {
                if element.isHittable { break }
                app.scrollViews.firstMatch.scroll(byDeltaX: 0, deltaY: downward ? -180 : 180)
            }
            XCTAssertTrue(element.isHittable)
        }
        XCTAssertTrue(openSurface.waitForExistence(timeout: 10))
        reveal(openSurface)
        XCTAssertFalse(app.buttons["openAlternateSurface"].exists)
        XCTAssertEqual(openSurface.label,"Open Wormhole")
        let preview = app.segmentedControls["gallerySurfacePreset"]
        preview.buttons["Torus"].click()
        XCTAssertEqual(openSurface.label,"Open Torus")
        preview.buttons["Wormhole"].click()
        XCTAssertEqual(openSurface.label,"Open Wormhole")
        openSurface.click()
        let preset = app.popUpButtons["surfacePreset"]
        XCTAssertTrue(preset.waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["renderFailure"].firstMatch.exists)
        let header = app.descendants(matching: .any)["inspectorHandle"].firstMatch
        header.doubleClick()
        let panel = app.descendants(matching: .any)["sceneInspector"].firstMatch
        let corner = panel.coordinate(withNormalizedOffset: CGVector(dx: 0,dy: 1)).withOffset(CGVector(dx: 4,dy: -4))
        corner.press(forDuration: 0.1,thenDragTo: corner.withOffset(CGVector(dx: -96,dy: 400)))
        let depth = app.textFields["Depth d"]
        reveal(depth)
        depth.click(); app.typeKey("a",modifierFlags: .command)
        depth.typeText("0"); app.typeKey(.return,modifierFlags: [])
        XCTAssertEqual(depth.value as? String,"0")
        capture("Wormhole flat annulus",app: app)
        let restore = app.buttons["surfaceRestoreDefaults"]
        reveal(restore,downward: false); restore.click()
        XCTAssertEqual(depth.value as? String,"7")
        let grid = app.checkBoxes["coordinateGrid"]
        reveal(grid); grid.click()
        XCTAssertTrue(app.textFields["Grid divisions"].exists)
        capture("Wormhole coordinate grid",app: app)
        reveal(preset,downward: false)
        preset.click(); app.menuItems["Torus"].click()
        XCTAssertTrue(app.textFields["Major radius R"].exists)
        XCTAssertFalse(app.textFields["Depth d"].exists)
        capture("Torus wireframe",app: app)
        app.buttons["surfaceCameraReset"].click()
        app.typeKey("0",modifierFlags: .command)
        header.doubleClick()
        app.buttons["inspectorToggle"].click()
        capture("Torus clean canvas",app: app)
        app.buttons["galleryButton"].click()
        let openLorenz = app.buttons["openLorenz"]
        reveal(openLorenz,downward: false); openLorenz.click()
        XCTAssertTrue(app.buttons["lorenzPause"].waitForExistence(timeout: 10))
    }


    func testTorusGeodesicsTransportAndInitialConditions() {
        let app = XCUIApplication()
        app.launch()
        let open = app.buttons["openTorusGeodesics"]
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        for _ in 0..<20 {
            if open.isHittable { break }
            app.scrollViews.firstMatch.scroll(byDeltaX: 0,deltaY: -180)
        }
        XCTAssertTrue(open.isHittable); open.click()
        let pause = app.buttons["geodesicPause"], step = app.buttons["geodesicStep"]
        XCTAssertTrue(pause.waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["renderFailure"].firstMatch.exists)
        XCTAssertFalse(step.isEnabled)
        pause.click(); XCTAssertTrue(step.isEnabled)
        app.buttons["geodesicRestart"].click()
        for _ in 0..<8 { step.click() }
        capture("Torus geodesic paused and stepped",app: app)
        let header = app.descendants(matching: .any)["inspectorHandle"].firstMatch
        header.doubleClick()
        let panel = app.descendants(matching: .any)["sceneInspector"].firstMatch
        let corner = panel.coordinate(withNormalizedOffset: CGVector(dx: 0,dy: 1)).withOffset(CGVector(dx: 4,dy: -4))
        corner.press(forDuration: 0.1,thenDragTo: corner.withOffset(CGVector(dx: -96,dy: 400)))
        XCTAssertTrue(app.textFields["Playback (×)"].exists)
        XCTAssertTrue(app.textFields["Particle size (pt)"].exists)
        let follow = app.checkBoxes["followGeodesicParticle"]
        XCTAssertTrue(follow.exists)
        follow.click()
        XCTAssertEqual(String(describing: follow.value ?? ""),"1")
        XCTAssertTrue(step.isEnabled)
        for _ in 0..<8 { step.click() }
        capture("Torus geodesic following paused particle",app: app)
        app.buttons["geodesicCameraReset"].click()
        XCTAssertEqual(String(describing: follow.value ?? ""),"0")
        follow.click()
        app.typeKey("0",modifierFlags: .command)
        XCTAssertEqual(String(describing: follow.value ?? ""),"0")
        let angle = app.textFields["Launch angle (°)"]
        for _ in 0..<10 {
            if angle.isHittable { break }
            app.scrollViews.firstMatch.scroll(byDeltaX: 0,deltaY: -120)
        }
        XCTAssertTrue(angle.isHittable)
        angle.click(); app.typeKey("a",modifierFlags: .command)
        angle.typeText("90"); app.typeKey(.return,modifierFlags: [])
        XCTAssertEqual(angle.value as? String,"90")
        app.typeKey(.escape,modifierFlags: [])
        app.typeKey("r",modifierFlags: .command)
        XCTAssertTrue(step.isEnabled)
        app.typeKey("]",modifierFlags: .command)
        capture("Torus geodesic meridian launch",app: app)
        app.buttons["inspectorToggle"].click()
        app.typeKey("0",modifierFlags: .command)
        app.typeKey(" ",modifierFlags: [])
        capture("Torus geodesic running clean canvas",app: app)
        app.buttons["inspectorToggle"].click()
        XCTAssertFalse(step.isEnabled)
        header.doubleClick()
    }


    func testWormholeComparisonModesAndFollowing() {
        let app = XCUIApplication(); app.launch()
        let open = app.buttons["openWormholeGeodesics"]
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        for _ in 0..<24 {
            if open.isHittable { break }
            app.scrollViews.firstMatch.scroll(byDeltaX: 0,deltaY: -160)
        }
        XCTAssertTrue(open.isHittable)
        capture("Wormhole comparison gallery preview",app: app)
        open.click()
        let pause = app.buttons["wormholePause"], step = app.buttons["wormholeStep"]
        XCTAssertTrue(pause.waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["renderFailure"].firstMatch.exists)
        let header = app.descendants(matching: .any)["inspectorHandle"].firstMatch
        header.doubleClick()
        let panel = app.descendants(matching: .any)["sceneInspector"].firstMatch
        let corner = panel.coordinate(withNormalizedOffset: CGVector(dx: 0,dy: 1)).withOffset(CGVector(dx: 4,dy: -4))
        corner.press(forDuration: 0.1,thenDragTo: corner.withOffset(CGVector(dx: -96,dy: 400)))
        func reveal(_ element: XCUIElement, downward: Bool = true) {
            for _ in 0..<24 {
                if element.isHittable { break }
                app.scrollViews.firstMatch.scroll(byDeltaX: 0,deltaY: downward ? -140 : 140)
            }
            XCTAssertTrue(element.isHittable)
        }
        reveal(pause); pause.click(); XCTAssertTrue(step.isEnabled)
        let continuous = app.checkBoxes["wormholeContinuousLaunches"]
        reveal(continuous)
        XCTAssertEqual(String(describing: continuous.value ?? ""),"1")
        let together = app.checkBoxes["wormholeStartTogether"]
        reveal(together)
        XCTAssertEqual(String(describing: together.value ?? ""),"1")
        together.click(); XCTAssertEqual(String(describing: together.value ?? ""),"0")
        together.click(); XCTAssertEqual(String(describing: together.value ?? ""),"1")
        let variation = app.textFields["Launch variation"]
        reveal(variation); XCTAssertTrue(variation.exists)
        reveal(continuous,downward: false); continuous.click()
        XCTAssertEqual(String(describing: continuous.value ?? ""),"0")
        let starts = app.disclosureTriangles["Starting positions"]
        reveal(starts); starts.click()
        let place = app.buttons["placeWormholeRow"]
        reveal(place); place.click()
        let selected = app.popUpButtons["selectedWormholeBall"]
        reveal(selected); selected.click(); app.menuItems["Ball 7"].click()
        let individual = app.disclosureTriangles["Selected ball position"]
        reveal(individual); individual.click()
        let start = app.textFields["Start Z"]
        reveal(start); start.click(); app.typeKey("a",modifierFlags: .command)
        start.typeText("4"); app.typeKey(.return,modifierFlags: [])
        XCTAssertEqual(start.value as? String,"4")
        let otherRegion = app.checkBoxes["showWormholeOtherRegion"]
        reveal(otherRegion)
        XCTAssertEqual(String(describing: otherRegion.value ?? ""),"1")
        otherRegion.click()
        XCTAssertEqual(String(describing: otherRegion.value ?? ""),"0")
        let returnEdge = app.checkBoxes["roundedWormholeEdge"]
        reveal(returnEdge,downward: false); returnEdge.click()
        XCTAssertEqual(String(describing: returnEdge.value ?? ""),"1")
        XCTAssertFalse(otherRegion.isEnabled)
        XCTAssertEqual(String(describing: otherRegion.value ?? ""),"1")
        app.typeKey("]",modifierFlags: .command)
        XCTAssertFalse(app.descendants(matching: .any)["renderFailure"].firstMatch.exists)
        capture("Wormhole rounded return edge",app: app)
        returnEdge.click()
        XCTAssertTrue(otherRegion.isEnabled)
        let mode = app.popUpButtons["wormholePresentation"]
        reveal(mode); mode.click(); app.menuItems["Trajectories"].click()
        XCTAssertFalse(app.textFields["Surface opacity"].exists)
        capture("Wormhole comparison trajectories",app: app)
        mode.click(); app.menuItems["Wireframe"].click()
        XCTAssertTrue(app.textFields["Surface opacity"].exists)
        let follow = app.checkBoxes["followWormholeParticle"]
        reveal(follow,downward: false); follow.click()
        XCTAssertEqual(String(describing: follow.value ?? ""),"1")
        let followStatus = app.staticTexts["wormholeFollowStatus"]
        XCTAssertTrue(followStatus.waitForExistence(timeout: 3))
        XCTAssertEqual(followStatus.label,"Following selected ball")
        app.typeKey("]",modifierFlags: .command)
        app.typeKey("0",modifierFlags: .command)
        XCTAssertEqual(String(describing: follow.value ?? ""),"0")
        let footer = app.staticTexts["wormholeCameraHelp"]
        reveal(footer)
        XCTAssertLessThanOrEqual(footer.frame.maxY,panel.frame.maxY-8)
        capture("Wormhole comparison inspector footer",app: app)
        header.doubleClick()
        app.buttons["galleryButton"].click()
        let torus = app.buttons["openTorusGeodesics"]
        reveal(torus,downward: false); torus.click()
        XCTAssertTrue(app.buttons["geodesicPause"].waitForExistence(timeout: 10))
    }

}
