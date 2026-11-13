import SwiftUI
import Observation
import simd
import WorkspaceCore

@MainActor
protocol PlanarTransportSession: AnyObject {
    var isRunning: Bool { get set }
    var canStep: Bool { get }
    func step()
    func restart()
}
extension OptimizationSession: PlanarTransportSession {
    var canStep: Bool { run?.canStep == true }
}

struct VectorDirectionSample {
    let point: SIMD2<Double>
    let vector: SIMD2<Double>
}

@MainActor @Observable
final class VectorFieldSession: PlanarTransportSession {
    var field = PlanarVectorField()
    var settings = VectorIntegrationSettings()
    var start = SIMD2<Double>(2,0)
    var isRunning = false
    private(set) var run: VectorTrajectory<PlanarVectorField>?
    private(set) var directions: [VectorDirectionSample] = []
    private(set) var failure: String?
    var canStep: Bool { run?.canStep == true }
    init() { restart() }
    func select(_ preset: VectorFieldPreset) {
        field = PlanarVectorField(preset: preset,parameter: preset.defaultParameter); restart()
    }
    func restart() {
        isRunning = false
        do {
            guard field.isValid else { throw VectorIntegrationError.invalidConfiguration }
            run = try VectorTrajectory(field: field,start: start,settings: settings)
            directions = []
            for y in 0...20 { for x in 0...20 {
                let p = field.domain.minimum+field.domain.span*SIMD2(Double(x),Double(y))/20
                directions.append(VectorDirectionSample(point: p,vector: field.vector(at: p)))
            } }
            failure = nil
        } catch { failure = "Invalid vector field, start or integration settings."; run = nil }
    }
    func step() { run?.step(); if !canStep { isRunning = false } }
    func advance(elapsed: Double) { run?.advance(elapsed: elapsed); if !canStep { isRunning = false } }
}

struct VectorFieldInspector: View {
    var session: VectorFieldSession
    var body: some View {
        VStack(alignment: .leading,spacing: 16) {
            Text("Vector Fields / Phase plane").font(Design.section)
            Picker("Field",selection: Binding(get: { session.field.preset },set: { session.select($0) })) {
                ForEach(VectorFieldPreset.allCases) { Text($0.rawValue).tag($0) }
            }.accessibilityIdentifier("vectorFieldPreset")
            Text(session.field.preset.formula).font(Design.numeric).fixedSize(horizontal: false,vertical: true)
            Picker("Integrator",selection: Binding(get: { session.settings.method },set: { session.settings.method = $0; session.restart() })) {
                ForEach(PlanarIntegrator.allCases) { Text($0.rawValue).tag($0) }
            }.accessibilityIdentifier("vectorIntegrator")
            HStack {
                Button(session.isRunning ? "Pause" : "Run") { session.isRunning.toggle() }.disabled(!session.canStep).accessibilityIdentifier("vectorRun")
                Button("Step") { session.step() }.disabled(session.isRunning || !session.canStep).accessibilityIdentifier("vectorStep")
                Button("Restart") { session.restart() }.accessibilityIdentifier("vectorRestart")
            }
            NumericControl(title: "Parameter μ",value: Binding(get: { session.field.parameter },set: { session.field.parameter = $0; session.restart() }),range: 0...4,step: 0.05)
            NumericControl(title: "Initial X",value: Binding(get: { session.start.x },set: { session.start.x = $0; session.restart() }),range: -6...6,step: 0.1)
            NumericControl(title: "Initial Y",value: Binding(get: { session.start.y },set: { session.start.y = $0; session.restart() }),range: -6...6,step: 0.1)
            NumericControl(title: "Fixed Δt",value: Binding(get: { session.settings.timestep },set: { session.settings.timestep = $0; session.restart() }),range: 0.0001...0.05,step: 0.0001)
            NumericControl(title: "Maximum steps",value: Binding(get: { Double(session.settings.maximumSteps) },set: { session.settings.maximumSteps = Int($0); session.restart() }),range: 100...20000,step: 100,deferred: true)
            if let run = session.run {
                let vector = session.field.vector(at: run.current.point)
                Text(run.status.rawValue).font(Design.section).accessibilityIdentifier("vectorStatus")
                Text(String(format: "t = %.4f · n = %d\nx = %.6g\ny = %.6g\n‖F(x,y)‖ = %.5g\ndropped time = %.4g",run.current.time,run.steps,run.current.point.x,run.current.point.y,simd_length(vector),run.clock.discardedTime))
                    .font(Design.numeric).textSelection(.enabled).accessibilityIdentifier("vectorDiagnostics")
            }
            if let failure = session.failure { Text(failure).foregroundStyle(Design.error) }
            Text("Arrows show direction only (normalized lengths). Trajectories solve the full vector field. Δt is fixed; Euler is less accurate and may grow spuriously. Reduce Δt to check sensitivity. Edits restart; Step advances one Δt. Click the phase plane to choose a start.")
                .font(Design.metadata).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
        }.buttonStyle(.bordered).controlSize(.large)
    }
}

struct VectorFieldWorkspace: View {
    var session: VectorFieldSession
    var inspectorVisible: Bool
    var body: some View {
        VStack(alignment: .leading,spacing: 12) {
            Text(session.field.preset.rawValue).font(Design.title)
            Text(session.field.preset.formula).font(Design.numeric).foregroundStyle(Design.secondary)
            GeometryReader { geometry in
                Canvas { context,size in
                    let plot = PlanarPlot(domain: session.field.domain,size: size)
                    var clipped = context; clipped.clip(to: Path(plot.frame))
                    var arrows = Path(), equilibria = Path()
                    for sample in session.directions {
                        let origin = plot.point(sample.point), length = simd_length(sample.vector)
                        if length < 1e-12 {
                            equilibria.addEllipse(in: CGRect(x: origin.x-2,y: origin.y-2,width: 4,height: 4)); continue
                        }
                        let direction = sample.vector/length
                        let unit = CGPoint(x: direction.x,y: -direction.y)
                        let end = CGPoint(x: origin.x+unit.x*10,y: origin.y+unit.y*10)
                        arrows.move(to: origin); arrows.addLine(to: end)
                        arrows.move(to: CGPoint(x: end.x-unit.x*4-unit.y*2.5,y: end.y-unit.y*4+unit.x*2.5))
                        arrows.addLine(to: end)
                        arrows.addLine(to: CGPoint(x: end.x-unit.x*4+unit.y*2.5,y: end.y-unit.y*4-unit.x*2.5))
                    }
                    clipped.stroke(arrows,with: .color(Design.secondary.opacity(0.6)),lineWidth: 0.8)
                    clipped.stroke(equilibria,with: .color(Design.accent),lineWidth: 1)
                    if let history = session.run?.history, let first = history.first {
                        var path = Path(); path.move(to: plot.point(first.point))
                        for record in history.dropFirst() { path.addLine(to: plot.point(record.point)) }
                        clipped.stroke(path,with: .color(.orange),lineWidth: 1.7)
                        let a = plot.point(first.point), b = plot.point(history.last!.point)
                        clipped.stroke(Path(ellipseIn: CGRect(x: a.x-4,y: a.y-4,width: 8,height: 8)),with: .color(Design.primary),lineWidth: 1)
                        clipped.fill(Path(ellipseIn: CGRect(x: b.x-4,y: b.y-4,width: 8,height: 8)),with: .color(.orange))
                    }
                    plot.drawAxes(context: &context)
                }
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { value in
                    let plot = PlanarPlot(domain: session.field.domain,size: geometry.size)
                    if plot.frame.contains(value.location) { session.start = plot.world(value.location); session.restart() }
                })
            }.accessibilityLabel("Phase plane with direction arrows and integrated trajectory. Initial X and Y provide keyboard starting-point controls.")
            Text("Direction only · equal axis scales · open circle = initial point · filled circle = current point")
                .font(Design.metadata).foregroundStyle(Design.secondary)
            if let point = session.run?.current.point, !session.field.domain.contains(point) {
                Text("Trajectory is outside the displayed domain; simulation continues without clamping.")
                    .font(Design.metadata).foregroundStyle(Design.error)
            }
        }
        .padding(24).padding(.trailing,inspectorVisible ? 328 : 0).padding(.bottom,56)
        .task(id: session.isRunning) {
            var last = ProcessInfo.processInfo.systemUptime
            while session.isRunning && !Task.isCancelled {
                let now = ProcessInfo.processInfo.systemUptime
                session.advance(elapsed: now-last); last = now
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }
}
