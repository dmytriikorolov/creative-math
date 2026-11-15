import SwiftUI
import Observation
import WorkspaceCore

@MainActor @Observable
final class OptimizationSession {
    var objective: ObjectivePreset = .quadratic
    var settings = OptimizationSettings()
    var start = ObjectivePreset.quadratic.start
    var isRunning = false
    private(set) var run: OptimizationRun<ObjectivePreset>?
    private(set) var grid: ObjectiveGrid?
    private(set) var failure: String?
    init() { restart() }
    func select(_ value: ObjectivePreset) {
        objective = value; start = value.start; grid = nil; restart()
    }
    func restart() {
        isRunning = false
        do {
            run = try OptimizationRun(objective: objective,start: start,settings: settings)
            if grid == nil { grid = try ObjectiveGrid(objective: objective,domain: objective.domain) }
            failure = nil
        } catch { failure = "Invalid objective, start or solver settings."; run = nil }
    }
    func step() {
        run?.step()
        if run?.canStep != true { isRunning = false }
    }
}

struct OptimizationInspector: View {
    var session: OptimizationSession
    var body: some View {
        VStack(alignment: .leading,spacing: 16) {
            Text("Optimization / Local methods").font(Design.section)
            Picker("Objective",selection: Binding(get: { session.objective },set: { session.select($0) })) {
                ForEach(ObjectivePreset.allCases) { Text($0.rawValue).tag($0) }
            }.accessibilityIdentifier("optimizationObjective")
            Text(session.objective.formula).font(Design.numeric).fixedSize(horizontal: false,vertical: true)
            Picker("Method",selection: Binding(get: { session.settings.method },set: { session.settings.method = $0; session.restart() })) {
                ForEach(OptimizationMethod.allCases) { Text($0.rawValue).tag($0) }
            }.accessibilityIdentifier("optimizationMethod")
            HStack {
                Button(session.isRunning ? "Pause" : "Run") { session.isRunning.toggle() }
                    .disabled(session.run?.canStep != true).accessibilityIdentifier("optimizationRun")
                Button("Step") { session.step() }.disabled(session.isRunning || session.run?.canStep != true)
                    .accessibilityIdentifier("optimizationStep")
                Button("Restart") { session.restart() }.accessibilityIdentifier("optimizationRestart")
            }
            NumericControl(title: "Initial X",value: Binding(get: { session.start.x },set: { session.start.x = $0; session.restart() }),range: -5...5,step: 0.1)
            NumericControl(title: "Initial Y",value: Binding(get: { session.start.y },set: { session.start.y = $0; session.restart() }),range: -5...5,step: 0.1)
            NumericControl(title: "Initial step size",value: Binding(get: { session.settings.stepSize },set: { session.settings.stepSize = $0; session.restart() }),range: 0.000001...2,step: 0.01)
            if session.settings.method == .momentum {
                NumericControl(title: "Momentum β",value: Binding(get: { session.settings.momentum },set: { session.settings.momentum = $0; session.restart() }),range: 0...0.99,step: 0.01)
            }
            NumericControl(title: "Gradient tolerance",value: Binding(get: { session.settings.tolerance },set: { session.settings.tolerance = $0; session.restart() }),range: 0.000001...0.01,step: 0.000001)
            NumericControl(title: "Iteration limit",value: Binding(get: { Double(session.settings.maximumIterations) },set: { session.settings.maximumIterations = Int($0); session.restart() }),range: 100...20000,step: 100,deferred: true)
            if let run = session.run {
                let r = run.current
                Text(run.status.rawValue).font(Design.section).accessibilityIdentifier("optimizationStatus")
                Text(String(format: "k = %d\nf = %.7g\n‖∇f‖ = %.4g\nα = %.4g\nHessian shift = %.4g",r.iteration,r.value,r.gradientNorm,r.stepSize,r.hessianShift))
                    .font(Design.numeric).textSelection(.enabled).accessibilityIdentifier("optimizationDiagnostics")
            }
            if let failure = session.failure { Text(failure).foregroundStyle(Design.error) }
            Text("All methods use Armijo backtracking. Momentum restarts non-descent steps. Newton shifts indefinite Hessians. Edits restart the trace. Click the plot to set a starting point.")
                .font(Design.metadata).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
        }
        .buttonStyle(.bordered).controlSize(.large)
    }
}

struct OptimizationWorkspace: View {
    var session: OptimizationSession
    var inspectorVisible: Bool
    var body: some View {
        VStack(alignment: .leading,spacing: 12) {
            Text(session.objective.rawValue).font(Design.title)
            Text(session.objective.formula).font(Design.numeric).foregroundStyle(Design.secondary)
            GeometryReader { geometry in
                Canvas { context,size in
                    guard let grid = session.grid else { return }
                    let plot = PlanarPlot(domain: grid.domain,size: size)
                    var clipped = context
                    clipped.clip(to: Path(plot.frame))
                    let n = grid.resolution, span = max(1e-12,grid.range.upperBound-grid.range.lowerBound)
                    for y in 0..<n { for x in 0..<n {
                        let low = grid.domain.minimum+grid.domain.span*SIMD2(Double(x),Double(y))/Double(n)
                        let high = low+grid.domain.span/Double(n)
                        let a = plot.point(low), b = plot.point(high)
                        let t = (grid.values[y*(n+1)+x]-grid.range.lowerBound)/span
                        clipped.fill(Path(CGRect(x: a.x,y: b.y,width: b.x-a.x+0.5,height: a.y-b.y+0.5)),with: .color(Design.accent.opacity(0.03+0.18*t)))
                    } }
                    var contours = Path()
                    for line in grid.contours { contours.move(to: plot.point(line.a)); contours.addLine(to: plot.point(line.b)) }
                    clipped.stroke(contours,with: .color(Design.secondary.opacity(0.5)),lineWidth: 0.7)
                    if let records = session.run?.records, let first = records.first {
                        var path = Path(); path.move(to: plot.point(first.point))
                        for record in records.dropFirst() { path.addLine(to: plot.point(record.point)) }
                        clipped.stroke(path,with: .color(.orange.opacity(0.9)),lineWidth: 1.7)
                        let start = plot.point(first.point)
                        clipped.stroke(Path(ellipseIn: CGRect(x: start.x-4,y: start.y-4,width: 8,height: 8)),with: .color(Design.primary),lineWidth: 1)
                        if let last = records.last {
                            let head = plot.point(last.point)
                            clipped.fill(Path(ellipseIn: CGRect(x: head.x-4,y: head.y-4,width: 8,height: 8)),with: .color(.orange))
                        }
                    }
                    plot.drawAxes(context: &context)
                }
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { value in
                    let plot = PlanarPlot(domain: session.objective.domain,size: geometry.size)
                    if plot.frame.contains(value.location) {
                        session.start = plot.world(value.location); session.restart()
                    }
                })
            }
            .accessibilityLabel("Objective level sets and optimization trajectory. Use Initial X and Initial Y to choose a start with the keyboard.")
            if let grid = session.grid {
                Text(String(format: "Sampled f: %.3g … %.3g · 12 level sets · brighter = higher f",grid.range.lowerBound,grid.range.upperBound))
                    .font(Design.metadata).foregroundStyle(Design.secondary)
            }
            Text("Objective value / iteration (linear scale)").font(Design.metadata).foregroundStyle(Design.secondary)
            Canvas { context,size in
                guard let records = session.run?.records, records.count > 1 else { return }
                let values = records.map(\.value), low = values.min()!, high = values.max()!
                var path = Path()
                for (i,r) in records.enumerated() {
                    let point = CGPoint(x: Double(i)/Double(records.count-1)*size.width,y: (1-(r.value-low)/max(1e-15,high-low))*max(1,size.height-8)+4)
                    if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                context.stroke(path,with: .color(Design.accent),lineWidth: 1.5)
                context.draw(Text(String(format: "%.3g → %.3g",records.first!.value,records.last!.value)).font(Design.numeric).foregroundStyle(Design.secondary),at: CGPoint(x: size.width/2,y: 12))
            }.frame(height: 88).accessibilityLabel("Objective history; current value in diagnostics")
            if let current = session.run?.current, !session.objective.domain.contains(current.point) {
                Text("Current iterate lies outside the displayed domain. The trace is clipped; solver coordinates remain unchanged.")
                    .font(Design.metadata).foregroundStyle(Design.error)
            }
        }
        .padding(24).padding(.trailing,inspectorVisible ? 328 : 0).padding(.bottom,56)
        .task(id: session.isRunning) {
            while session.isRunning && !Task.isCancelled {
                session.step()
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
    }
}

// Shared 2D display mapping: equal units on both axes, no solver state here.
struct PlanarPlot {
    let domain: PlanarDomain
    let frame: CGRect
    init(domain: PlanarDomain,size: CGSize) {
        self.domain = domain
        let scale = max(1,min(max(1,size.width-56)/domain.span.x,max(1,size.height-48)/domain.span.y))
        let width = domain.span.x*scale, height = domain.span.y*scale
        frame = CGRect(x: (size.width-width)/2+12,y: (size.height-height)/2-8,width: width,height: height)
    }
    func point(_ p: SIMD2<Double>) -> CGPoint {
        CGPoint(x: frame.minX+(p.x-domain.minimum.x)/domain.span.x*frame.width,y: frame.maxY-(p.y-domain.minimum.y)/domain.span.y*frame.height)
    }
    func world(_ p: CGPoint) -> SIMD2<Double> {
        domain.minimum+domain.span*SIMD2((p.x-frame.minX)/frame.width,(frame.maxY-p.y)/frame.height)
    }
    func drawAxes(context: inout GraphicsContext) {
        context.stroke(Path(frame),with: .color(Design.border),lineWidth: 1)
        for i in 0...4 {
            let t = Double(i)/4, x = domain.minimum.x+domain.span.x*t, y = domain.minimum.y+domain.span.y*t
            context.draw(Text(x.formatted(.number.precision(.fractionLength(1)))).font(Design.metadata).foregroundStyle(Design.secondary),at: CGPoint(x: frame.minX+frame.width*t,y: frame.maxY+12))
            context.draw(Text(y.formatted(.number.precision(.fractionLength(1)))).font(Design.metadata).foregroundStyle(Design.secondary),at: CGPoint(x: frame.minX-20,y: frame.maxY-frame.height*t))
        }
        context.draw(Text("x").font(Design.numeric).foregroundStyle(Design.primary),at: CGPoint(x: frame.maxX+16,y: frame.maxY))
        context.draw(Text("y").font(Design.numeric).foregroundStyle(Design.primary),at: CGPoint(x: frame.minX,y: frame.minY-12))
    }
}
