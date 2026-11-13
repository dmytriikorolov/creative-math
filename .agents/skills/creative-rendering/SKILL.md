---
name: creative-rendering
description: Use for Metal shaders, GPU compute, particles, trails, geometry, cameras, render targets, or art-direction changes.
---
# Creative Rendering
1. Identify the mathematical source and desired visual representation. Keep visual effects separate from model evolution.
2. Write down resource ownership, buffer formats, coordinate spaces, camera conventions, color space and frame lifecycle before adding a new pass.
3. Prefer persistent GPU buffers, bounded resource counts, and explicit pipeline states. Avoid per-frame CPU readbacks and allocations.
4. Validate resize, retina scale, device loss/error paths, background/resume and offscreen export dimensions.
5. Render a real reference scene; inspect sharpness, clipping, aliasing, exposure, composition, color banding, and trail persistence. No fake screenshots or stock imagery as output.
6. Benchmark representative particle counts and document actual device, resolution, GPU/CPU timings, memory and sustained FPS. No unsupported speed claims.
7. Prefer one polished effect over a framework of speculative rendering abstractions.
