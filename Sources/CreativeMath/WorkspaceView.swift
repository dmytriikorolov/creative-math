import SwiftUI
import WorkspaceCore

struct WorkspaceView: View {
    @State private var scene: WorkspaceScene?
    @State private var libraryVisible = true
    @State private var librarySearch = ""
    @State private var libraryCategory = LibraryCategory.all
    @FocusState private var librarySearchFocused: Bool
    @State private var inspectorVisible = true
    @State private var renderFailure: String?
    @State private var lorenz = LorenzSession()
    @State private var surface = SurfaceSession()
    @State private var geodesic = GeodesicSession()
    @State private var wormhole = WormholeSession()
    @State private var optimization = OptimizationSession()
    @State private var savedPanelFrame: CGRect?
    @State private var livePanelFrame: CGRect?
    @State private var interactionStart: CGRect?
    @FocusState private var panelFocused: Bool

    private var activeMotion: (any SurfaceMotionSession)? {
        if scene == .torusGeodesics { return geodesic }
        if scene == .wormholeGeodesics { return wormhole }
        return nil
    }
    var body: some View {
        HStack(spacing: 0) {
            if libraryVisible {
                experimentLibrary
                Rectangle().fill(Design.border).frame(width: 1)
            }
            VStack(spacing: 0) {
            if let failure = renderFailure ?? activeMotion?.surface.failure ?? (scene == .lorenz ? lorenz.failure : (scene == .surface ? surface.failure : nil)) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text(failure)
                    Spacer()
                }
                .font(Design.body)
                .padding(16)
                .foregroundStyle(Design.primary)
                .background(Design.surface)
                .accessibilityIdentifier("renderFailure")
            }
            if let scene {
                workspace(scene)
            } else {
                gallery
            }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(Design.canvas)
        .foregroundStyle(Design.primary)
        .focusedSceneValue(\.optimizationSession, scene == .optimization ? optimization : nil)
        .focusedSceneValue(\.lorenzSession, scene == .lorenz ? lorenz : nil)
        .focusedSceneValue(\.surfaceSession, scene == .surface ? surface : activeMotion?.surface)
        .focusedSceneValue(\.geodesicSession, activeMotion)
        .onChange(of: inspectorVisible) { _, visible in
            if !visible { finishInteraction() }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    libraryVisible.toggle()
                } label: {
                    Label(libraryVisible ? "Hide Library" : "Show Library", systemImage: "sidebar.left")
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                .accessibilityIdentifier("libraryToggle")
                Button {
                    libraryVisible = true
                    librarySearchFocused = true
                } label: {
                    Label("Search Experiments", systemImage: "magnifyingglass")
                }
                .keyboardShortcut("l", modifiers: .command)
                .accessibilityIdentifier("librarySearchButton")
            }
            ToolbarItemGroup(placement: .primaryAction) {
                if scene != nil {
                    Button {
                        self.scene = nil
                    } label: {
                        Label("Browse Previews", systemImage: "square.grid.2x2")
                    }
                    .keyboardShortcut("g", modifiers: .command)
                    .accessibilityIdentifier("galleryButton")
                    Button {
                        inspectorVisible.toggle()
                    } label: {
                        Label(inspectorVisible ? "Hide Inspector" : "Show Inspector", systemImage: "sidebar.right")
                    }
                    .keyboardShortcut("i", modifiers: .command)
                    .accessibilityIdentifier("inspectorToggle")
                }
            }
        }
    }


    private var experimentLibrary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Library").font(Design.title).accessibilityAddTraits(.isHeader)
            TextField("Search experiments", text: $librarySearch)
                .textFieldStyle(.roundedBorder)
                .focused($librarySearchFocused)
                .accessibilityLabel("Search experiments")
                .accessibilityIdentifier("experimentSearch")
            Picker("Category", selection: $libraryCategory) {
                ForEach(LibraryCategory.allCases) { Text($0.rawValue).tag($0) }
            }
            .labelsHidden().accessibilityLabel("Experiment category")
            .accessibilityIdentifier("experimentCategory")
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(LibraryCategory.allCases.filter { $0 != .all }) { category in
                        let entries = LibraryExperiment.entries.filter {
                            $0.category == category && (libraryCategory == .all || libraryCategory == category) && $0.matches(librarySearch)
                        }
                        if !entries.isEmpty {
                            Text(category.rawValue.uppercased()).font(Design.metadata)
                                .foregroundStyle(Design.secondary).padding(.top, 16).padding(.bottom, 4)
                            ForEach(entries) { entry in
                                Button {
                                    if let preset = entry.surface, surface.preset != preset { surface.select(preset) }
                                    open(entry.scene)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.title).font(Design.section)
                                        Text(entry.detail).font(Design.metadata).foregroundStyle(Design.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .background(isSelected(entry) ? Design.elevated : Color.clear)
                                    .overlay(alignment: .leading) {
                                        if isSelected(entry) { Rectangle().fill(Design.accent).frame(width: 2) }
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("library."+entry.id)
                                .accessibilityAddTraits(isSelected(entry) ? .isSelected : [])
                            }
                        }
                    }
                    if !LibraryExperiment.entries.contains(where: {
                        (libraryCategory == .all || $0.category == libraryCategory) && $0.matches(librarySearch)
                    }) {
                        Text("No matching experiments").font(Design.section).padding(.top, 16)
                        Text("Try another name, model or category.").font(Design.body).foregroundStyle(Design.secondary)
                        Button("Clear filters") { librarySearch = ""; libraryCategory = .all }
                            .padding(.top, 8).accessibilityIdentifier("clearLibraryFilters")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer(minLength: 0)
            Rectangle().fill(Design.border).frame(height: 1)
            Button("Blank Scene", systemImage: "plus") { open(.blank) }
                .accessibilityIdentifier("library.blank")
            Button("Browse live previews", systemImage: "square.grid.2x2") { scene = nil }
                .accessibilityIdentifier("libraryPreviews")
            Text("⌘L Search · ⇧⌘L Hide library").font(Design.metadata).foregroundStyle(Design.secondary)
        }
        .padding(16)
        .frame(width: 216)
        .frame(maxHeight: .infinity)
        .background(Design.surface)
        .accessibilityElement(children: .contain)
    }

    private func isSelected(_ entry: LibraryExperiment) -> Bool {
        scene == entry.scene && (entry.surface == nil || surface.preset == entry.surface)
    }

    private var gallery: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    HStack(alignment: .center, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Studies").font(Design.title)
                                .accessibilityAddTraits(.isHeader)
                            Text("Explore a study or begin with an empty canvas.")
                                .font(Design.body).foregroundStyle(Design.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 16)
                        Button("Blank Scene", systemImage: "plus") { open(.blank) }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .keyboardShortcut("n", modifiers: .command)
                            .accessibilityIdentifier("blankScene")
                    }
                    Rectangle().fill(Design.border).frame(height: 1)
                    LorenzGalleryStudy { preset in
                        lorenz.select(preset)
                        open(.lorenz)
                    }
                    Rectangle().fill(Design.border).frame(height: 1)
                    SurfaceGalleryStudy { preset in
                        surface.select(preset)
                        open(.surface)
                    }
                    Rectangle().fill(Design.border).frame(height: 1)
                    GeodesicGalleryStudy {
                        geodesic.restart()
                        open(.torusGeodesics)
                    }
                    Rectangle().fill(Design.border).frame(height: 1)
                    WormholeGalleryStudy {
                        wormhole.restart()
                        open(.wormholeGeodesics)
                    }
                    Rectangle().fill(Design.border).frame(height: 1)
                    if geometry.size.width >= 1040 {
                        HStack(alignment: .center, spacing: 32) {
                            studyPreview
                            studyDetails.frame(width: 256, alignment: .leading)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 24) {
                            studyPreview
                            studyDetails
                        }
                    }
                }
                .frame(maxWidth: 1040, alignment: .leading)
                .padding(geometry.size.width >= 1040 ? 48 : 24)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .accessibilityIdentifier("gallery")
    }

    private var studyPreview: some View {
        Button { open(.triangle) } label: {
            MetalViewport(scene: .triangle, onFailure: reportFailure)
                .aspectRatio(8 / 5, contentMode: .fit)
                .overlay(Rectangle().strokeBorder(Design.border))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Triangle Study")
        .accessibilityIdentifier("trianglePreview")
    }

    private var studyDetails: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("01 / GEOMETRY").font(Design.numeric).foregroundStyle(Design.secondary)
                Text("Triangle Study").font(Design.title)
                    .accessibilityAddTraits(.isHeader)
                Text("A single triangle, defined by three vertices. A study in shape and proportion.")
                    .font(Design.body).foregroundStyle(Design.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("3 vertices · 1 triangle").font(Design.numeric).foregroundStyle(Design.secondary)
            Button("Open Study", systemImage: "arrow.right") { open(.triangle) }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Open Triangle Study")
                .accessibilityIdentifier("trianglePreset")
        }
    }

    private func workspace(_ scene: WorkspaceScene) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                if scene == .optimization {
                    OptimizationWorkspace(session: optimization, inspectorVisible: inspectorVisible)
                } else if scene == .lorenz {
                    LorenzViewport(session: lorenz, revision: lorenz.revision)
                } else if scene == .torusGeodesics {
                    SurfaceViewport(session: geodesic.surface, revision: geodesic.revision &+ geodesic.surface.revision, geodesic: geodesic)
                        .overlay { if geodesic.surface.grid.visible { GeodesicAxisLabels(session: geodesic) } }
                } else if scene == .wormholeGeodesics {
                    SurfaceViewport(session: wormhole.surface,revision: wormhole.revision &+ wormhole.surface.revision,geodesic: wormhole)
                        .overlay { if wormhole.surface.grid.visible { GeodesicAxisLabels(session: wormhole) } }
                } else if scene == .surface {
                    SurfaceViewport(session: surface, revision: surface.revision)
                        .overlay { if surface.grid.visible { SurfaceAxisLabels(camera: surface.camera) } }
                } else {
                    MetalViewport(scene: scene, onFailure: reportFailure)
                }
                VStack {
                    Spacer()
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(caption(scene).0).font(Design.metadata)
                            Text(caption(scene).1).font(Design.body).foregroundStyle(Design.secondary)
                        }
                        Spacer()
                    }
                }
                .padding(24)
                .allowsHitTesting(false)
                if inspectorVisible {
                    let frame = panelFrame(in: geometry.size)
                    inspector(scene, size: geometry.size)
                        .offset(x: frame.minX, y: frame.minY)
                }
            }
            .clipped()
            .onAppear {
                savedPanelFrame = PanelPreferences.load(from: .standard, in: geometry.size)
            }
            .onDisappear { finishInteraction() }
            .onChange(of: geometry.size) { _, size in
                // End any in-flight interaction before adopting the new workspace bounds.
                store(PanelPlacement.constrained(panelFrame(in: size), in: size))
                interactionStart = nil
                livePanelFrame = nil
            }
        }
        .accessibilityIdentifier("workspace")
    }

    private func caption(_ scene: WorkspaceScene) -> (String,String) {
        switch scene {
        case .optimization: ("OPTIMIZATION / LOCAL METHODS", "Discrete iterations · Double precision · safeguarded steps")
        case .wormholeGeodesics:
            ("WORMHOLE / STARTING-POSITION COMPARISON",wormhole.summary)
        case .torusGeodesics: ("TORUS / GEODESICS","Metric-driven motion · RK4 · Δt = 1/240 s")
        case .surface: ("SURFACE / \(surface.preset.title.uppercased())","\(surface.style.title) · u × v parameter grid")
        case .lorenz: ("LORENZ / \(lorenz.preset.title.uppercased())","σ = \(lorenz.configuration.parameters.sigma.formatted()) · ρ = \(lorenz.configuration.parameters.rho.formatted()) · β = \(lorenz.configuration.parameters.beta.formatted())")
        case .triangle: ("01 / TRIANGLE STUDY","Three vertices. One surface.")
        case .blank: ("00 / BLANK SCENE","An empty canvas.")
        }
    }

    private func inspector(_ scene: WorkspaceScene, size: CGSize) -> some View {
        let frame = panelFrame(in: size)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal").foregroundStyle(Design.secondary)
                Text("Scene").font(Design.section)
                Spacer()
                Button { inspectorVisible = false } label: {
                    Image(systemName: "xmark").frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close Inspector")
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .overlay(alignment: .leading) {
                mouseRegion(in: size)
            }
            .contentShape(Rectangle())
            .focusable()
            .focused($panelFocused)
            .focusEffectDisabled()
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(panelFocused ? Design.accent : .clear, lineWidth: 2).allowsHitTesting(false))
            .onKeyPress(.leftArrow) { movePanel(dx: -16, dy: 0, in: size); return .handled }
            .onKeyPress(.rightArrow) { movePanel(dx: 16, dy: 0, in: size); return .handled }
            .onKeyPress(.upArrow) { movePanel(dx: 0, dy: -16, in: size); return .handled }
            .onKeyPress(.downArrow) { movePanel(dx: 0, dy: 16, in: size); return .handled }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Move scene inspector")
            .accessibilityHint("Arrow keys move. Double-click the header to restore default size.")
            .accessibilityIdentifier("inspectorHandle")
            .accessibilityAction(named: "Move left") { movePanel(dx: -16, dy: 0, in: size) }
            .accessibilityAction(named: "Move right") { movePanel(dx: 16, dy: 0, in: size) }
            .accessibilityAction(named: "Move up") { movePanel(dx: 0, dy: -16, in: size) }
            .accessibilityAction(named: "Move down") { movePanel(dx: 0, dy: 16, in: size) }
            .accessibilityAction(named: "Restore default size") { restoreSize(in: size) }
            .accessibilityAction(named: "Increase width") { resizeBy(width: 16, height: 0, in: size) }
            .accessibilityAction(named: "Decrease width") { resizeBy(width: -16, height: 0, in: size) }
            .accessibilityAction(named: "Increase height") { resizeBy(width: 0, height: 16, in: size) }
            .accessibilityAction(named: "Decrease height") { resizeBy(width: 0, height: -16, in: size) }
            Rectangle().fill(Design.border).frame(height: 1)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if scene == .optimization {
                        OptimizationInspector(session: optimization)
                    } else if scene == .lorenz {
                        LorenzInspector(session: lorenz)
                    } else if scene == .torusGeodesics {
                        GeodesicInspector(session: geodesic)
                    } else if scene == .wormholeGeodesics {
                        WormholeInspector(session: wormhole)
                    } else if scene == .surface {
                        SurfaceInspector(session: surface)
                    } else {
                        HStack {
                            Text("Study").foregroundStyle(Design.secondary)
                            Spacer()
                            Text(scene.title)
                        }
                        HStack {
                            Text("Geometry").foregroundStyle(Design.secondary)
                            Spacer()
                            Text(scene == .triangle ? "3 vertices / 1 triangle" : "Empty").font(Design.numeric)
                        }
                        Text("Drag the header to move. Drag an edge to resize.")
                            .font(Design.metadata).foregroundStyle(Design.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Button("Restore Placement") {
                        let origin = CGPoint(x: size.width - frame.width - PanelPlacement.margin, y: PanelPlacement.margin)
                        store(PanelPlacement.constrained(CGRect(origin: origin, size: frame.size), in: size))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityIdentifier("restorePlacement")
                }
                .font(Design.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: .infinity)
            .scrollIndicators(.visible)
            .padding([.trailing, .bottom], 8)
        }
        .frame(width: frame.width, height: frame.height)
        .background(Design.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(interactionStart == nil ? Design.border : Design.accent).allowsHitTesting(false))
        .overlay {
            ZStack(alignment: .topLeading) {
                ForEach(Array(PanelPlacement.Edges.handles.enumerated()), id: \.offset) { _, edges in
                    let corner = edges.intersection([.left, .right]).isEmpty == false && edges.intersection([.top, .bottom]).isEmpty == false
                    let horizontal = edges == .top || edges == .bottom
                    let width: CGFloat = corner ? 12 : (horizontal ? max(0, frame.width - 24) : 6)
                    let height: CGFloat = corner ? 12 : (horizontal ? 6 : max(0, frame.height - 24))
                    mouseRegion(edges: edges, in: size)
                        .frame(width: width, height: height)
                        .position(x: edges.contains(.left) ? width / 2 : (edges.contains(.right) ? frame.width - width / 2 : frame.width / 2),
                                  y: edges.contains(.top) ? height / 2 : (edges.contains(.bottom) ? frame.height - height / 2 : frame.height / 2))
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Scene inspector")
        .accessibilityIdentifier("sceneInspector")
    }

    private func mouseRegion(edges: PanelPlacement.Edges = [], in size: CGSize) -> some View {
        PanelMouseRegion(edges: edges, onBegin: {
            interactionStart = panelFrame(in: size)
            if edges.isEmpty { panelFocused = true }
        }, onChange: { translation in
            guard let start = interactionStart else { return }
            livePanelFrame = edges.isEmpty
                ? PanelPlacement.moved(start, by: translation, in: size)
                : PanelPlacement.resized(start, by: translation, edges: edges, in: size)
        }, onEnd: {
            finishInteraction()
        }, onDoubleClick: edges.isEmpty ? { restoreSize(in: size) } : nil,
                         excludesCloseButton: edges.isEmpty)
    }

    private func panelFrame(in size: CGSize) -> CGRect {
        PanelPlacement.constrained(livePanelFrame ?? savedPanelFrame ?? PanelPreferences.load(from: .standard, in: size), in: size)
    }

    private func store(_ frame: CGRect) {
        savedPanelFrame = frame
        PanelPreferences.save(frame, to: .standard)
    }

    private func finishInteraction() {
        if let frame = livePanelFrame { store(frame) }
        interactionStart = nil
        livePanelFrame = nil
    }

    private func restoreSize(in size: CGSize) {
        store(PanelPlacement.constrained(CGRect(origin: panelFrame(in: size).origin, size: PanelPlacement.panelSize), in: size))
    }

    private func resizeBy(width: CGFloat, height: CGFloat, in size: CGSize) {
        var frame = panelFrame(in: size)
        frame.size.width += width
        frame.size.height += height
        store(PanelPlacement.constrained(frame, in: size))
    }

    private func movePanel(dx: CGFloat, dy: CGFloat, in size: CGSize) {
        store(PanelPlacement.moved(panelFrame(in: size), by: CGSize(width: dx, height: dy), in: size))
    }

    private func open(_ scene: WorkspaceScene) {
        librarySearchFocused = false
        renderFailure = nil
        self.scene = scene
        inspectorVisible = true
    }

    private func reportFailure(_ message: String) { renderFailure = message }
}


private enum LibraryCategory: String, CaseIterable, Identifiable {
    case all = "All experiments", dynamics = "Dynamical systems", geometry = "Geometry", optimization = "Optimization"
    var id: String { rawValue }
}

private struct LibraryExperiment: Identifiable {
    let id: String
    let title: String
    let detail: String
    let category: LibraryCategory
    let scene: WorkspaceScene
    var surface: SurfacePreset? = nil
    func matches(_ query: String) -> Bool {
        let text = title+" "+detail+" "+category.rawValue
        return query.split(whereSeparator: { $0.isWhitespace }).allSatisfy { text.localizedStandardContains(String($0)) }
    }
    static let entries: [Self] = [
        Self(id: "optimization", title: "Optimization Lab", detail: "Level sets · gradient, momentum, Newton", category: .optimization, scene: .optimization),
        Self(id: "lorenz", title: "Lorenz Attractor", detail: "Chaos · Classic, Filament, Sculpture", category: .dynamics, scene: .lorenz),
        Self(id: "torusGeodesics", title: "Torus Geodesics", detail: "Motion on a curved surface · RK4", category: .dynamics, scene: .torusGeodesics),
        Self(id: "wormholeGeodesics", title: "Wormhole Geodesics", detail: "Parallel launches · rounded return", category: .dynamics, scene: .wormholeGeodesics),
        Self(id: "wormhole", title: "Wormhole Surface", detail: "Funnel · wireframe and coordinates", category: .geometry, scene: .surface, surface: .wormhole),
        Self(id: "torus", title: "Torus Surface", detail: "Parametric ring · coordinates", category: .geometry, scene: .surface, surface: .torus),
        Self(id: "triangle", title: "Triangle Study", detail: "Three vertices · one surface", category: .geometry, scene: .triangle)
    ]
}
