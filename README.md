# SketchPaper

Minecraft as a pencil sketch on paper.
마인크래프트를 종이에 그린 연필 스케치로 바꾸는 쉐이더팩입니다.

Outlines, quantized tone with parallel hatching, hand-drawn wobble on a
stepped frame rate, and paper grain. No shadow maps, no lightmap — the
whole look is post-processing, so it costs almost nothing to run.

외곽선, 단계별 톤과 평행선 해칭, 계단식 프레임의 손떨림 왜곡, 종이 질감.
그림자맵도 라이트맵도 쓰지 않고 전부 후처리로 처리하기 때문에
GPU 부담이 거의 없습니다.

---

## Requirements / 요구 사항

- **Iris** (Sodium recommended)
- Tested on Minecraft **26.2** with Iris **1.11.1**

Other versions are untested. It may well work, but no promises.
다른 버전은 테스트하지 않았습니다. 동작할 가능성은 높지만 보장은 못 합니다.

## Install / 설치

Put the `.zip` in your `shaderpacks` folder. **Do not unzip it.**
Then select it in Options → Video Settings → Shader Packs.

압축을 풀지 말고 `.zip` 그대로 `shaderpacks` 폴더에 넣은 뒤,
옵션 → 비디오 설정 → 쉐이더팩에서 선택하세요.

---

## Settings / 설정

The button at the top of the settings screen switches between six presets.
Each one pushes a different axis rather than being a general quality level:

| Preset | |
|---|---|
| `DEFAULT` | Shipped settings. Use this to get back if you lose track of what you changed. |
| `EYECARE` | The least visually noisy setting available. High-frequency detail turned down or off, distance separation at maximum so overlapping masses stay readable as separate layers. Loses the finest leaf texture. |
| `CALM` | Motion, not detail. Keeps the drawing's detail but stops it moving around — slowest redraw, smallest wobble, no hatch jitter. |
| `CRISP` | Sharp, clean linework, for screenshots and wallpapers. Crisp means the marks are crisp, not that the image shakes faster. |
| `COLOR` | Original block colours partly restored. |
| `CHAOS` | Every restraint removed. The setting the other five exist to avoid. |

설정 화면 맨 위 버튼으로 프리셋 여섯 개를 전환할 수 있습니다.
품질 단계가 아니라 각각 **다른 축**을 극단으로 민 것입니다.
`DEFAULT`(기본값, 값을 만지다 꼬였을 때 되돌리는 용도),
`EYECARE`(시각적 노이즈 최소 — 눈 보호),
`CALM`(디테일은 유지하고 움직임만 줄임),
`CRISP`(선이 또렷한 스크린샷용),
`COLOR`(색을 살린 버전),
`CHAOS`(모든 제한 해제 — 정신 혼란).

All options are in the in-game shader settings screen.
Defaults are tuned; you can ignore all of this and it will look fine.

모든 옵션은 게임 내 쉐이더 설정 화면에 있습니다.
기본값은 이미 조정된 상태라 아무것도 안 만져도 됩니다.

### WOBBLE — hand-drawn shake / 손떨림

| Option | Default | |
|---|---|---|
| `SKETCH_FPS` | 4.0 | How many times per second the wobble redraws. Lower = choppier, more hand-drawn. The camera itself stays smooth. |
| `WOBBLE_AMOUNT` | 0.0030 | Distortion strength. |
| `WOBBLE_SCALE` | 7.0 | Distortion pattern size. |

### LINES — outlines / 선

| Option | Default | |
|---|---|---|
| `EDGE_MODE` | 1 | 1 = curvature based. Avoids false lines on ground seen at a grazing angle. 0 = older simple difference. |
| `LINE_CURVE_THRESHOLD` | 0.02 | Sensitivity for `EDGE_MODE 1`. Lower = more lines. |
| `LINE_DEPTH_THRESHOLD` | 0.035 | Sensitivity for `EDGE_MODE 0`. |
| `LINE_LUMA_STRENGTH` | 1.0 | Detail lines from texture brightness. Catches boundaries between blocks on the same flat plane, but also picks up texture noise. Lower it if things look dirty. |
| `LINE_DARKNESS` | 0.85 | |
| `LINE_FADE_DIST` | 48.0 | Aerial perspective. Lines fade with distance so far-off foliage doesn't turn into a black smear. 0 disables. |
| `LINE_FADE_DEPTH` | 0.35 | How much of that fade also applies to silhouettes. 0 keeps silhouettes at full strength forever. |
| `LINE_FADE_MODE` | 1 | 1 steps the fade **per block**, so every pixel of a block shares one grey and blocks read as flat masses. 0 fades smoothly per pixel, which produces a gradient and makes a single block shimmer slightly across its own face. |
| `LINE_FADE_STEPS` | 5.0 | How many grey levels the distance is cut into. Fewer means a more obvious staircase. |
| `LINE_FADE_CURVE` | 0.6 | Where the distance steps are concentrated. 1.0 spreads them evenly; lower packs more of them into the near range. Even spacing puts roughly ten blocks between steps, so two trees five blocks apart land on the same step and merge. |
| `TONE_FADE` | 0.5 | How much the block-stepped distance also lightens the **fill**, not just the lines. Without this, a near tree and the tree behind it are shaded the same grey and read as one blob where they overlap. 0 disables. |
| `LINE_DETAIL_MIN` | 24.0 | Detail lines are dropped once a block is smaller than this many pixels on screen. Block textures are 16×16 texels, so at mid distance a texel falls below one pixel and its edges become pure noise — fading them grey isn't enough, they have to go. Raise it to clear mid-range foliage harder; silhouettes are unaffected. 0 disables. |

### FOLIAGE — dense leaves / 수풀

Leaves are dense by nature, so drawing every edge inside them turns the canopy
into a black smear. This counts how many nearby pixels were judged to be lines
and suppresses them where that count is high — real outlines are sparse,
texture noise is dense.

잎은 원래 빽빽해서 안쪽 선을 전부 그리면 수관이 새까맣게 뭉칩니다.
주변에서 선으로 판정된 비율을 세어 그 값이 높은 곳의 선을 억제합니다.
진짜 외곽선은 희소하고 텍스처 노이즈는 빽빽하다는 차이를 이용한 것입니다.

| Option | Default | |
|---|---|---|
| `FOLIAGE_CALM` | 0.75 | How hard to suppress. 0 disables it. |
| `FOLIAGE_RADIUS` | 4.0 | How wide an area the count looks at, in pixels. |

### HATCH — shading / 해칭

| Option | Default | |
|---|---|---|
| `HATCH_ANCHOR` | 0 | 0 = locked to the screen, like marks on paper. 1 = locked to world surfaces, so the pattern moves with the blocks. |
| `HATCH_ANGLE` | 45.0 | A single angle is used throughout. Darkness comes from stroke thickness and infill, never from crossing angles. |
| `HATCH_SPACING` | 4.0 | Gap between strokes, in pixels. |
| `HATCH_WIDTH` | 0.16 | Stroke thickness. |
| `HATCH_ROUGH` | 0.6 | Waviness and pressure variation. 0 = perfectly straight ruled lines. |
| `HATCH_JITTER` | 0.25 | How far the hatch pattern shifts each redraw, relative to stroke spacing. Large values make the pattern flip back and forth and flicker. |
| `HATCH_STRENGTH` | 0.5 | |
| `TONE_LEVELS` | 4.0 | How many brightness steps. |

### PAPER / SKY / misc

| Option | Default | |
|---|---|---|
| `PAPER_GRAIN` | 0.16 | Paper texture. |
| `COLOR_MIX` | 0.0 | 0 = pure graphite. Raise it to bring the original block colors back. |
| `WATER_OPACITY` | 0.22 | Also affects glass and ice. |
| `SUN_CUTOFF` | 0.55 | Sun and moon size. Higher = smaller and sharper. |
| `SUN_TONE` | 0.72 | Closer to 1.0 makes them fade into the paper. |
| `HIDE_CLOUDS` | 0 | Set to 1 to remove clouds entirely. |
| `DEBUG_VIEW` | 0 | 1 raw color / 2 depth / 3 depth without translucents / 4 lines only / 5 hatching only / 6 translucent mask. |

---

## Known quirks / 알려진 특성

- **Everything is fullbright.** Tone comes from block texture brightness,
  not from lighting. Caves look the same as the surface. This is
  intentional — drawings on paper don't have physically correct shadows.
  풀브라이트입니다. 밝기는 조명이 아니라 블록 텍스처 자체에서 나옵니다.
  종이 그림에는 물리적으로 정확한 그림자가 없으니 의도된 동작입니다.

- **Night looks nearly identical to day.** Follows from the above.
  위와 같은 이유로 밤과 낮의 차이가 거의 없습니다.

- With `HATCH_ANCHOR 1`, the on-screen hatch angle shifts as you turn,
  and stroke spacing jumps in steps at certain distances.
  `HATCH_ANCHOR 1`에서는 화면상 해칭 각도가 시점에 따라 변하고,
  특정 거리에서 획 간격이 단계적으로 바뀝니다.

---

Made by **Mazekest**.
See `LICENSE.txt` for terms. / 이용 조건은 `LICENSE.txt`를 확인하세요.
