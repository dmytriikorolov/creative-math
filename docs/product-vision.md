# Product vision

A native macOS creative mathematics workstation, combining generative art with mathematical exploration. The work surface is a living mathematical scene; the interface stays quiet until needed.

## Users and jobs
- Curious creator: explore curated scenes, tune parameters, save variations, export art.
- Mathematics student: investigate dynamical systems and, later, continuous/nonlinear optimization with trajectories, gradients, contours, and algorithm steps.
- Advanced user: enter mathematical expressions, compare solvers, animate parameters (later milestones).

## UX commitments
- Launch into preset gallery with a clearly visible Blank Scene option.
- Explore (clean presentation), Create (inspectors/timeline), Analyze (axes, trajectories, metrics) are workspace views, not distinct document formats.
- Default to immediate visual feedback; provide precise numeric entry and keyboard-first interaction.
- Art and Analysis representations share underlying mathematical model and recorded state.

## Explicit non-goals for V0.1
Full MATLAB/Mathematica competitor, general node graph, arbitrary shader execution, 4D geometry editor, online accounts, social feed, cross-platform support, broad simulation catalogue.

## Initial hero scene
A polished Lorenz attractor using genuine numerical integration and GPU-side visual representation. First optimization scene (later): Rosenbrock surface/contours with gradient descent and Newton, independent solver traces.


## Accepted surface studies — M2

Accepted M2 extends the instrument with mathematical surface studies: an open Wormhole funnel
and Torus, shared wireframe/shaded rendering and optional coordinates. The Wormhole is a
geometric embedding-style study, not a simulation of spacetime. Native inspector and camera
interactions are shared in style with Lorenz; Lorenz remains intact. M2 visual acceptance was confirmed by the user on 2026-11-02.
Persistence, export, formula editing and optimization remain outside this slice.


## Implemented — M3.1 Torus Geodesics, review pending

M0–M2 are accepted and complete. Add one deterministic particle following the metric of the
accepted torus surface, with meaningful tangent-plane initial conditions, bounded trail and
fixed-step transport. Mathematical geometry generates the motion. Reuse the M2 surface,
camera and native inspector. M3.1 remains independent of the subsequent Ellis wormhole experiment.
M3.1 remains subject to user review of the actual animation.


## Active slice — M3.2 Ellis Wormhole Geodesics

Study unit-speed spatial geodesics on two smoothly connected regions using the Ellis metric
and its Euclidean equatorial embedding. Crossing, returning and near-critical launches expose
the angular-momentum threshold. Surface, Wireframe and Trajectories are views of this same
mathematical system. This is not a photon, lensing or full spacetime simulation. Native camera,
follow, transport and floating inspectors stay consistent with M3.1. Both new motion slices
await actual local animation review; M3.3 vector fields and later work remain unstarted.
