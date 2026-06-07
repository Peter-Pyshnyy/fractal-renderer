# fractal-renderer

A real-time 3D fractal viewer built in Godot 4 with compute shaders. 

Core features:
  - Auto-Relaxed Sphere Tracing (https://doi.org/10.2312/egs.20231014)
  - Screen-Space LOD (https://doi.org/10.2312/stag.20141233)
  - Motion Adaptive Shading
  - Progressive Frame Accumulation on static camera & scene

Shading:
  - Metallic-Roughness PBR
  - Iteration Count and Orbit Traps coloring
  - Extensive Orbit Traps parametrization

Fractals:
  - Custom GLSL slot
  - Mandelbulb 
  - Dynamic Mandelbulb (https://doi.org/10.1016/j.chaos.2025.116829)
  - Quaternion Julia
  - Dual Quaternion Julia (10.48550/arXiv.2303.14827)
  - Sierpinski Kaleidoscope
  - Menger Kaleidoscope
  - Mandelbox

## Controls

The renderer supports two camera modes: proximity-aware orbital camera that revolves around the scene center and a free-flying one modelled after Godot's in-engine camera.

```
General
  C            switch camera mode (orbit / free flight)
  Ctrl+Scroll  zoom FOV

Orbit camera
  LMB     rotate
  Scroll  zoom

Free flight
  RMB           hold to move
  W A S D E Q   fly around
  Scroll        change speed
```
