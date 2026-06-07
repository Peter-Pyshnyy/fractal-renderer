A real-time 3D fractal viewer built in Godot 4 with compute shaders. 

<img width="725" alt="Pipeline" src="https://github.com/user-attachments/assets/a6e6eda3-56da-46fd-b06b-307c089a3e3c" />

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
  - Dual Quaternion Julia (https://doi.org/10.48550/arXiv.2303.14827)
  - Sierpinski Kaleidoscope
  - Menger Kaleidoscope
  - Mandelbox

<img width="250" alt="SK_1" src="https://github.com/user-attachments/assets/39e5c4c8-2d94-4571-8460-961eb666736f" />
<img width="250" alt="MBX_0" src="https://github.com/user-attachments/assets/9fde1dae-cb33-43f9-a249-bce3953f428e" />
<img width="250" alt="MB_B_1" src="https://github.com/user-attachments/assets/4aca3234-f2ee-478b-ae0a-5dee1b127f41" />
<img width="250" alt="DQJ_0" src="https://github.com/user-attachments/assets/15a34774-8ba2-4f78-8aca-668525c9f597" />
<img width="250" alt="MB_B_2" src="https://github.com/user-attachments/assets/88ac8655-a5e5-4392-9762-816df8462455" />
<img width="250" alt="KM_2" src="https://github.com/user-attachments/assets/c0dcf3ac-9137-4d78-a6fd-e3908970b697" />





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
