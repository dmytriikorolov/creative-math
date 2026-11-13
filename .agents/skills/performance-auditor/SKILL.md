---
name: performance-auditor
description: Use when setting performance targets, benchmarking, profiling memory/GPU/CPU, or making performance-related claims.
---
# Performance Auditor
1. Record exact device, RAM, macOS, Xcode/build configuration, display resolution/render scale, power state, scene parameters and particle count.
2. Measure warm-up and sustained behavior (target 20 minutes on M2 Air), frame-time median/p95/p99, dropped frames, process memory and GPU/CPU time when instrumentation permits.
3. Start with Instruments (Time Profiler, Metal System Trace or appropriate Metal profiling), allocations and signposts. Distinguish bottlenecks by evidence.
4. Budget 16.7 ms for 60 FPS; measure before changing algorithms. Avoid trading mathematical correctness for FPS without explicit user-visible quality mode.
5. Test resize, high-DPI output, background/foreground, repeated scene loading and export for leaks or spikes.
6. Report measurements in a reproducible table. If profiling cannot be run, mark **NOT MEASURED** and do not claim 60 FPS or memory compliance.
