# AR Greeks Lab (iOS + ARKit)

An iOS app that turns option prices and Greeks into interactive 3D surfaces in augmented reality.

## Demo: SCREENSHOTS & SCREENRECORDING COMING SOON

If you would like a TestFlight build or a deeper dive into the ML/Quant/AR design feel free to reach out to: 815-616-7848 or rheats2@illinois.edu 

---
## Concept

**AR Greeks Lab** visualizes the Black–Scholes world as something you can walk around.

Given user‑selected option parameters, the app:

1. Computes option **price** and **Greeks** across a grid of underlying prices and expiries.
2. Normalizes those values into heights and builds a 3D mesh.
3. Anchors that mesh onto a detected real‑world surface via ARKit.
4. Lets the user explore the surface spatially and inspect exact numbers by tapping.

The goal is an educational, intuition‑building tool that feels like an internal prototype from a quant / risk team, not a retail trading product.

---

## Feature Highlights

### Quant & Surfaces

- European call/put pricing using the **Black–Scholes** closed‑form solution.
- Analytic Greeks implemented in Swift:
  - **Price**
  - **Delta**
  - **Gamma**
  - (Theta, Vega, Rho implemented in the quant module for future use.)
- Dynamic surface generation over:
  - Spot price range, e.g. `0.5×S₀ … 1.5×S₀`
  - Time to expiry range, e.g. `0.01 … T_max` years
- Tunable resolution (default **40×40** grid) balancing smoothness and mobile performance.

### AR Visualization (ARKit + RealityKit)

- World tracking and horizontal **plane detection** (tables, floors).
- Realistic environment lighting via **environment texturing**.
- Custom **mesh generation** from height maps:
  - Converts a 2D grid of `Double` values into a dense triangle mesh.
  - Scales surfaces to ~0.6 m × 0.6 m for comfortable viewing in AR.
- Surfaces are anchored slightly above the detected plane to avoid z‑fighting/clipping.

### Interaction Model

- **Long‑press** on a detected plane  
  → Generates and places a surface at that location (or moves it).

- **Tap** on the existing surface  
  → Converts the 3D hit position back into grid indices, then displays:
  - Spot price \(S\)
  - Time to expiry \(T\)
  - Price
  - Delta
  - Gamma

- **Mode picker**  
  → Switch between visualizing:
  - Price surface  
  - Delta surface  
  - Gamma surface  

- **Baseline + comparison**:
  - **Save Baseline** captures the current surface (mode + parameters) as a reference grid.
  - **Compare** toggle enables a second, red surface representing `current − baseline`, placed beside the main one.
  - This reveals how regime changes (e.g., volatility spikes, time decay) deform the pricing / Greek landscape.

### UX & Debugging

- Instruction bar at the top:
  - “Long‑press to place a surface. Tap the surface to inspect a point.”
- Compact overlay card showing last inspected point:
  - `S`, `T`, `Price`, `Delta`, `Gamma`
- Bottom control panel:
  - Sliders for **Spot**, **Volatility (σ)**, and **Time horizon (T_max)**
  - Mode picker (Price / Delta / Gamma)
  - Buttons:
    - **Save Baseline**
    - **Compare** toggle
    - **Reset** (clears all anchors and selection)
- **About** screen:
  - Explains the quant engine and planned ML component.
  - Provides user‑facing debugging tips, e.g.:
    - Move the device over textured surfaces to help plane detection.
    - Use Reset if tracking feels off.
    - Distinguish long‑press (place) vs tap (inspect).

---

## Architecture

### Tech Stack

- **Language:** Swift
- **UI:** SwiftUI
- **AR / 3D:** ARKit + RealityKit
- **State / Data Flow:** MVVM style with `ObservableObject` and `@Published`

### Core Components

- `OptionModels.swift`
  - `OptionType` (`.call`, `.put`)
  - `OptionParameters` describing:
    - Spot `S`, Strike `K`, Time `T`
    - Volatility `σ`, Risk‑free rate `r`, Dividend yield `q`
  - `Quant` struct:
    - Standard normal PDF / CDF implementations
    - Black–Scholes pricing (`price(...)`) for calls/puts
    - Analytic Greeks:
      - `delta`, `gamma`, `theta`, `vega`, `rho`

- `SurfaceGrid.swift`
  - `SurfaceMode` enum: `.price`, `.delta`, `.gamma`
  - `SurfaceGrid.generate(...)`:
    - Builds evenly spaced axes for S and T.
    - Evaluates `Quant` at each grid node for the desired quantity.

- `SurfaceViewModel.swift`
  - Acts as the central state container:
    - Parameters: `spot`, `strike`, `timeMax`, `volatility`, `rate`, `dividend`, `optionType`
    - Visualization: `mode` (`SurfaceMode`), `comparisonEnabled`
    - Baseline: stored `SurfaceGrid` for comparison
    - Selection (overlay):
      - `selectedS`, `selectedT`
      - `selectedPrice`, `selectedDelta`, `selectedGamma`
  - Responsible for:
    - Generating `SurfaceData` (heights + axes) from model parameters
    - Normalizing surfaces for AR scale
    - Computing difference surfaces (`current − baseline`)
    - Updating selection from grid indices
    - Resetting selection & broadcasting reset events to AR

- `ARViewContainer.swift`
  - `UIViewRepresentable` bridge from SwiftUI to RealityKit.
  - Configures AR session:
    - `ARWorldTrackingConfiguration` with horizontal plane detection
  - Handles gestures:
    - `UILongPressGestureRecognizer` → triggers `placeSurface(...)`
    - `UITapGestureRecognizer` → hit‑tests mesh for inspection
  - Manages:
    - AR anchors and their lifetime
    - Main surface `ModelEntity` (blue)
    - Optional difference surface `ModelEntity` (red)
  - Converts tap‑hit positions from local coordinates to grid indices based on:
    - Known mesh width/depth
    - Grid resolution
    - Stored axes (`sAxis`, `tAxis`)

- `ContentView.swift`
  - Layout:
    - Instruction + overlay at top
    - Full‑screen AR view behind
    - Control panel at bottom
  - Binds sliders, toggles, and buttons directly to `SurfaceViewModel` state.

- `AboutView.swift`
  - SwiftUI sheet describing:
    - High‑level Black–Scholes explanation
    - What Price / Delta / Gamma mean intuitively
    - Planned ML approximation extension
    - Troubleshooting steps for AR

---

## Quant Details

**Model:** Black–Scholes for European options.

Inputs:

- Spot price \(S\)
- Strike price \(K\)
- Time to expiry \(T\) (years)
- Volatility \(\sigma\)
- Risk‑free rate \(r\)
- Dividend yield \(q\)
- Option type: Call / Put

Key intermediate terms:

\[
d_1 = \frac{\ln(S / K) + (r - q + 0.5\sigma^2)T}{\sigma \sqrt{T}}, \quad
d_2 = d_1 - \sigma\sqrt{T}
\]

Call price:

\[
C = S e^{-qT} N(d_1) - K e^{-rT} N(d_2)
\]

Put price:

\[
P = K e^{-rT} N(-d_2) - S e^{-qT} N(-d_1)
\]

where \(N(\cdot)\) is the standard normal CDF.

Greeks implemented:

- **Delta:** sensitivity of price to spot changes.
- **Gamma:** sensitivity of delta to spot changes (curvature).
- **Theta, Vega, Rho:** implemented for completeness; currently not surfaced as separate AR modes.

All formulas are implemented directly in Swift for full control and interview‑friendly discussion.

---

## Planned ML Extension

The project is intentionally structured to support a **machine‑learning approximator**:

- Generate a synthetic dataset using the analytic Black–Scholes engine:
  - Inputs: \((S, K, T, \sigma, r, q, \text{type})\)
  - Targets: price or a Greek (e.g., delta).
- Train a small MLP (e.g., in Python) to approximate price / delta on this domain.
- Export the trained model’s weights and integrate an on‑device forward pass.
- Add a UI toggle:
  - **Analytic** vs **Neural Net** surface.
- Visualize approximation error via:
  - Difference surfaces
  - Error overlays
  - Error metrics displayed when tapping points.

This gives a strong story around:

- Using ML to approximate PDE solutions.  
- Speed vs accuracy and model risk.  
- Integrating ML into a mobile AR visualization pipeline.

---
## Usage Guide
1. Move your phone to let ARKit detect a horizontal plane
   - Note: textured surfaces help with tracking horizontal planes
2. Long-press on the plane to place the surface
   - A blue 3D surface will appear anchored to the plane
3. Adjust parameters via the bottom sliders
4. Switch mode (price/delta/gamma) to see different visualizations
5. Tap on surface to show grid position, price, delta, and gamma at specific grid position
6. Comparison mode:
   - Configure parameters and press save baseline
   - Change parameters
   - Toggle compare ON
   - Long press again to place red comparative surface

- Reset when:
  - Tracking feels off
  - Scene is cluttered
  - User desires a clean AR session

- Check out About section (top-right):
  - Provides a quick explanation of the math, ML usage/future plans, and debugging tips
---
## Limitations & Future Work: 

**Current Limitations:**
- Supports European options-pricing only (no America/early-logic)
- Surfaces are generated from a single volatility value (no full volatility surface)
- ML approximation is architected but not yet integrated in this public version
- No persistence layer; settings are reset between app launches
 
**Future Work:**
- Add on‑device ML approximator for price / delta and analytic vs neural comparison
- Add more surface modes (Theta, Vega, Rho)
- Export screenshots or simple PDF reports of surfaces and inspected points
- Add presets for common underlyings (e.g., SPX, AAPL) and maturities
- Explore more advanced models (local vol, stochastic vol) for richer surfaces.
 

