#version 120

// =====================================================================
//  SketchPaper 2.4 / composite
//
//  v3b에서 바뀐 것:
//   - 플레이어 투과 버그 수정.
//     원인: depthtex1(반투명 제외 깊이)로 물 아래 윤곽을 뽑았는데,
//     마인크래프트는 플레이어 모델 전체를 반투명 렌더 타입으로 그린다.
//     그래서 플레이어 자리의 depthtex1에는 뒷배경 지형의 깊이가 들어있고,
//     그 외곽선이 플레이어 몸 위에 그려지고 있었다.
//     이제 colortex1의 반투명 마스크가 있는 곳(=실제 물/유리)에서만
//     depthtex1을 참고한다. 일반 몹은 불투명 렌더 타입이라 원래 멀쩡했다.
//   - DEBUG_VIEW 추가. 중간 단계를 날것으로 확인할 수 있다.
//   - 기본값을 사용자 튜닝값으로 교체.
// =====================================================================

// ---------- 디버그 ----------
//  0 정상 / 1 원본 색 / 2 depthtex0 / 3 depthtex1 / 4 선만 / 5 해칭만 / 6 반투명 마스크
#define DEBUG_VIEW 0               // [0 1 2 3 4 5 6]

// ---------- 워블 ----------
#define SKETCH_FPS 4.0             // [1.5 2.0 3.0 4.0 6.0 8.0 12.0 15.0 24.0]
#define WOBBLE_AMOUNT 0.0030       // [0.0 0.0005 0.0010 0.0020 0.0030 0.0045 0.0060 0.0090]
#define WOBBLE_SCALE 7.0           // [3.0 5.0 7.0 10.0 14.0]

// ---------- 라인 ----------
//  EDGE_MODE 1 = 2차 차분. 스치듯 보는 지면(수평선)에서 생기는 가짜 선을 없앤다.
//  EDGE_MODE 0 = 1차 차분 (v5까지의 방식).
#define EDGE_MODE 1                // [0 1]
#define LINE_CURVE_THRESHOLD 0.02  // [0.008 0.014 0.02 0.03 0.05]  EDGE_MODE 1일 때 쓰임
#define LINE_DEPTH_STRENGTH 1.0    // [0.0 0.5 1.0 1.5 2.0]
#define LINE_DEPTH_THRESHOLD 0.035 // [0.015 0.025 0.035 0.05 0.08]  EDGE_MODE 0일 때 쓰임
#define LINE_LUMA_STRENGTH 1.0     // [0.0 0.25 0.5 0.75 1.0 1.5]
#define LINE_LUMA_THRESHOLD 0.14   // [0.06 0.10 0.14 0.20 0.28]
#define LINE_DARKNESS 0.85         // [0.4 0.6 0.85 1.0]
//  물 아래 지형의 윤곽선. 끄면 depthtex1을 아예 안 쓴다.
#define WATER_LINES 1              // [0 1]
//  공기원근법. 멀수록 디테일선(루미넌스 엣지)을 옅게 만든다.
//  먼 나뭇잎이 새까맣게 뭉개지는 걸 막는다.
//  실루엣(depth 엣지)은 건드리지 않으므로 먼 산의 윤곽은 그대로 남는다.
//  0이면 감쇠 없음(예전 동작).
#define LINE_FADE_DIST 48.0        // [0.0 24.0 48.0 96.0 192.0]
#define LINE_FADE_FLOOR 0.15       // [0.0 0.15 0.3 0.5]  가장 멀 때 남는 비율
//  거리 감쇠를 깊이 엣지에도 얼마나 적용할지. 0이면 실루엣은 절대 안 옅어진다.
#define LINE_FADE_DEPTH 0.35       // [0.0 0.2 0.35 0.5 0.75]
//  거리 감쇠를 어떻게 나눌지.
//   1 = 블록 단위 계단. 한 블록 안의 모든 픽셀이 같은 회색을 쓴다.
//       블록이 평평한 덩어리로 읽히고, 거리는 단계로 구분된다.
//       같은 블록 안에서 진하기가 미세하게 흔들리는 것도 사라진다.
//   0 = 픽셀 단위 연속. 부드럽지만 그라데이션이 생긴다.
#define LINE_FADE_MODE 1           // [0 1]
//  몇 단계로 나눌지. 적을수록 계단이 뚜렷하다.
#define LINE_FADE_STEPS 5.0        // [3.0 4.0 5.0 7.0 10.0]
//  단계를 어디에 몰아줄지. 1.0이면 균등, 낮을수록 가까운 쪽에 촘촘해진다.
//  균등하게 나누면 한 단계가 10블록쯤 되어서, 5블록 차이로 겹친 나무들이
//  같은 단계에 들어가 구분이 안 된다.
#define LINE_FADE_CURVE 0.6        // [0.4 0.6 0.8 1.0 1.5]

//  거리 단계를 채우기(해칭)에도 적용한다.
//
//  선에만 적용하면 앞 나무와 뒤 나무의 어두운 면이 똑같은 회색이 되어,
//  겹쳤을 때 한 덩어리로 뭉쳐 보인다. 경계가 없으니 형태가 안 잡히고
//  눈이 계속 훑게 된다. 면의 밝기를 거리로 나눠야 층이 분리된다.
//  0이면 끔(전부 같은 톤).
#define TONE_FADE 0.5              // [0.0 0.25 0.5 0.7 0.9]

//  해상할 수 없는 디테일은 그리지 않는다.
//
//  블록 텍스처는 16x16 텍셀이다. 화면에서 블록 하나가
//   - 아주 가까움(150px+) : 텍셀 하나가 10px 가까이 되어 무늬가 또렷하게 읽힌다
//   - 중간(10~40px)       : 텍셀 하나가 1px 미만. 읽히지도 않는 무늬가
//                           전부 선으로 그려져 순수 노이즈가 된다. 여기가 최악
//   - 아주 멂             : 블록 자체가 작아 선이 몇 개 안 남는다
//
//  거리 감쇠는 선을 옅게 만들 뿐 개수를 줄이지 않아서, 중간 거리에서는
//  회색이어도 여전히 빽빽하다. 밝기가 아니라 밀도가 문제였다.
//  그래서 블록이 화면에서 이 픽셀 수보다 작아지면 디테일선을 접는다.
//  실루엣(깊이 엣지)은 건드리지 않으므로 형태는 그대로 남는다.
//  0이면 끔.
#define LINE_DETAIL_MIN 24.0       // [0.0 12.0 18.0 24.0 32.0 48.0 72.0]

// ---------- 수풀 ----------
//  빽빽한 수풀에서 선을 덜어낸다.
//  주변 픽셀 중 선으로 판정된 비율을 세서, 너무 높으면 억제한다.
//  진짜 외곽선은 희소하고 텍스처 노이즈는 빽빽하다는 차이를 이용한 것.
//  "전부 선이면 아무것도 선이 아니다".
#define FOLIAGE_CALM 0.75          // [0.0 0.35 0.55 0.75 0.9 1.0]
#define FOLIAGE_RADIUS 4.0         // [2.0 3.0 4.0 6.0 9.0]  밀도를 재는 반경(px)

// ---------- 해칭 ----------
#define HATCH_ANCHOR 0             // [0 1]  0=화면 고정, 1=월드 고정
#define TONE_LEVELS 4.0            // [2.0 3.0 4.0 5.0 6.0]
#define HATCH_STRENGTH 0.5         // [0.0 0.2 0.35 0.5 0.65 0.8]
#define HATCH_SPACING 4.0          // [4.0 5.0 7.0 9.0 12.0 16.0]
#define HATCH_WIDTH 0.16           // [0.10 0.16 0.22 0.30 0.40]
#define HATCH_ANGLE 45.0           // [0.0 15.0 30.0 45.0 60.0 75.0]
#define HATCH_ROUGH 0.6            // [0.0 0.2 0.35 0.6 1.0]
//  스텝마다 해칭이 흔들리는 폭 (획 간격 대비 비율).
//  예전에는 4픽셀 고정이었는데, HATCH_SPACING이 4일 때는 한 주기의 절반이라
//  무늬가 통째로 뒤집히며 심하게 깜빡였다.
#define HATCH_JITTER 0.25          // [0.0 0.15 0.25 0.4 0.7]

// ---------- 종이 ----------
#define PAPER_GRAIN 0.16           // [0.0 0.03 0.06 0.10 0.16]
#define COLOR_MIX 0.0              // [0.0 0.15 0.3 0.5]

uniform sampler2D colortex0;
uniform sampler2D colortex1;   // 반투명 마스크
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
uniform float aspectRatio;

varying vec2 texcoord;

// ---------------------------------------------------------------------
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float luma(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

float linDepth(float d) {
    return (2.0 * near * far) / (far + near - (d * 2.0 - 1.0) * (far - near));
}

float depthEdgeFrom(sampler2D tex, vec2 uv, vec2 px) {
    float dC = linDepth(texture2D(tex, uv).r);
    float dL = linDepth(texture2D(tex, uv - vec2(px.x, 0.0)).r);
    float dR = linDepth(texture2D(tex, uv + vec2(px.x, 0.0)).r);
    float dD = linDepth(texture2D(tex, uv - vec2(0.0, px.y)).r);
    float dU = linDepth(texture2D(tex, uv + vec2(0.0, px.y)).r);

#if EDGE_MODE == 1
    // 2차 차분 (깊이 변화의 "꺾임"을 본다).
    //
    // 지면을 스치듯 보는 수평선 부근에서는 평평한 땅인데도
    // 픽셀당 깊이가 급격히 변한다. 1차 차분은 그걸 전부 선으로 판정해서
    // 수평선에 검은 띠를 만든다.
    //
    // 기울어진 평면에서는 왼쪽과 오른쪽이 중앙을 사이에 두고 일정하게
    // 변하므로 이 값이 상쇄되어 0에 가깝다. 진짜 단차에서만 크게 튄다.
    float e = (abs(dL + dR - 2.0 * dC) + abs(dD + dU - 2.0 * dC))
            / max(dC, 0.001);
    return smoothstep(LINE_CURVE_THRESHOLD, LINE_CURVE_THRESHOLD * 2.5, e);
#else
    // 1차 차분 (v5까지의 방식)
    float e = (abs(dL - dC) + abs(dR - dC) + abs(dD - dC) + abs(dU - dC))
            / max(dC, 0.001);
    return smoothstep(LINE_DEPTH_THRESHOLD, LINE_DEPTH_THRESHOLD * 2.5, e);
#endif
}

vec3 viewPosFromDepth(vec2 uv, float d) {
    vec4 ndc = vec4(uv * 2.0 - 1.0, d * 2.0 - 1.0, 1.0);
    vec4 v = gbufferProjectionInverse * ndc;
    return v.xyz / v.w;
}

// 한 지점의 루미넌스 엣지 강도
float lumaEdgeAt(vec2 uv, vec2 px) {
    float l = luma(texture2D(colortex0, uv - vec2(px.x, 0.0)).rgb);
    float r = luma(texture2D(colortex0, uv + vec2(px.x, 0.0)).rgb);
    float d = luma(texture2D(colortex0, uv - vec2(0.0, px.y)).rgb);
    float u = luma(texture2D(colortex0, uv + vec2(0.0, px.y)).rgb);
    float gx = r - l;
    float gy = u - d;
    return smoothstep(LINE_LUMA_THRESHOLD, LINE_LUMA_THRESHOLD * 2.0,
                      sqrt(gx * gx + gy * gy));
}

float stripe(float across, float along, float spacing, float width, float sd) {
    across += (vnoise(vec2(along * 0.7, sd)) - 0.5) * spacing * 0.55 * HATCH_ROUGH;

    float f = fract(across / spacing);
    float t = abs(f - 0.5) * 2.0;
    float line = 1.0 - smoothstep(width, width + 0.30, t);

    line *= 1.0 - HATCH_ROUGH * 0.45 * vnoise(vec2(along * 1.6, sd + 17.0));

    return clamp(line, 0.0, 1.0);
}

// ---------------------------------------------------------------------
void main() {
    vec2 px = 1.0 / vec2(viewWidth, viewHeight);

    // ---- 1) 워블 ----
    float stepT = floor(frameTimeCounter * SKETCH_FPS);
    float seed  = stepT * 7.13;

    vec2 nUV = texcoord * vec2(aspectRatio, 1.0) * WOBBLE_SCALE;
    float w1 = vnoise(nUV + vec2(seed,              seed * 1.7));
    float w2 = vnoise(nUV + vec2(seed * 2.3 + 31.0, seed * 0.9 + 17.0));

    vec2 uv = clamp(texcoord + (vec2(w1, w2) - 0.5) * WOBBLE_AMOUNT,
                    vec2(0.0), vec2(1.0));

    // ---- 2) 라인 ----
    // 반투명 마스크가 있는 곳에서만 depthtex1을 쓴다.
    // 이게 없으면 플레이어(반투명 렌더 타입) 위에 뒷배경 선이 그려진다.
    float tmask = texture2D(colortex1, uv).r;
    float useD1 = step(0.02, tmask) * float(WATER_LINES);

    // 공기원근법용 거리 감쇠. 하늘은 제외한다.
    // 하늘은 깊이가 최댓값이라 감쇠에 걸리면 해와 달 테두리가 유령처럼 흐려진다.
    float depthHere = texture2D(depthtex0, uv).r;
    float notSky = step(depthHere, 0.9999);

    float fade = 1.0;
    float distT = 0.0;          // 0 = 가까움, 1 = 가장 멂 (블록 단위 계단)
    if (LINE_FADE_DIST > 0.0) {
        float t;

#if LINE_FADE_MODE == 1
        // 이 픽셀이 속한 "블록 칸"까지의 거리를 쓴다.
        // 같은 블록이면 어느 픽셀이든 같은 값이 나오므로
        // 블록 하나가 통째로 같은 회색이 된다.
        vec3 vp  = viewPosFromDepth(uv, depthHere);
        vec3 rel = (gbufferModelViewInverse * vec4(vp, 1.0)).xyz;

        // 표면은 블록 경계에 정확히 걸쳐 있어서 floor가 이웃 블록으로
        // 튈 수 있다. 시선 방향으로 살짝 밀어 안쪽 블록을 고르게 한다.
        vec3 wpos = rel + cameraPosition + normalize(rel) * 0.02;
        vec3 cellCenter = floor(wpos) + 0.5;

        float blockDist = length(cellCenter - cameraPosition);
        t = clamp(blockDist / LINE_FADE_DIST, 0.0, 1.0);

        // 가까운 쪽에 단계를 촘촘하게 배분한다.
        t = pow(t, LINE_FADE_CURVE);

        // 연속값을 계단으로 자른다. 그라데이션이 아니라 단계가 되어야
        // 판화나 펜화처럼 읽힌다.
        t = clamp(floor(t * LINE_FADE_STEPS) / max(LINE_FADE_STEPS - 1.0, 1.0),
                  0.0, 1.0);
#else
        t = smoothstep(0.0, 1.0, clamp(linDepth(depthHere) / LINE_FADE_DIST, 0.0, 1.0));
#endif

        distT = t * notSky;
        fade = mix(1.0, LINE_FADE_FLOOR, distT);
    }

    // 블록 하나가 화면에서 몇 픽셀인가.
    float pxPerBlock = 1e6;
    if (notSky > 0.5) {
        vec3 vpDet = viewPosFromDepth(uv, depthHere);
        pxPerBlock = 0.5 * viewHeight * gbufferProjection[1][1]
                   / max(length(vpDet), 0.1);
    }

    float e0 = depthEdgeFrom(depthtex0, uv, px);
    float e1 = depthEdgeFrom(depthtex1, uv, px) * useD1;
    float dEdge = max(e0, e1) * LINE_DEPTH_STRENGTH;

    // 먼 나무 수관은 실제 단차가 빽빽해서 깊이 엣지만으로도 검게 뭉친다.
    // 실루엣을 잃지 않도록 감쇠를 부분만 적용한다.
    dEdge *= mix(1.0, fade, LINE_FADE_DEPTH);

    vec3  cC = texture2D(colortex0, uv).rgb;
    float lC = luma(cC);

    float lEdge = lumaEdgeAt(uv, px) * LINE_LUMA_STRENGTH;
    lEdge *= fade;

    // 해상할 수 없는 디테일은 접는다.
    if (LINE_DETAIL_MIN > 0.0) {
        lEdge *= smoothstep(LINE_DETAIL_MIN * 0.5, LINE_DETAIL_MIN * 1.5, pxPerBlock);
    }

    // ---- 수풀 정리: 엣지 밀도 기반 억제 ----
    if (FOLIAGE_CALM > 0.0) {
        vec2 rr = px * FOLIAGE_RADIUS;
        float dens = lumaEdgeAt(uv, px);
        dens += lumaEdgeAt(uv + vec2( rr.x,  rr.y), px);
        dens += lumaEdgeAt(uv + vec2(-rr.x,  rr.y), px);
        dens += lumaEdgeAt(uv + vec2( rr.x, -rr.y), px);
        dens += lumaEdgeAt(uv + vec2(-rr.x, -rr.y), px);
        dens /= 5.0;

        float keep = 1.0 - smoothstep(0.30, 0.75, dens) * FOLIAGE_CALM;
        lEdge *= keep;
        // 숲은 실제 깊이 단차도 빽빽하므로 깊이 엣지에도 적용한다.
        // 다만 실루엣을 완전히 잃지 않도록 약하게.
        dEdge *= mix(1.0, keep, 0.7);
    }

    float line = clamp(max(dEdge, lEdge), 0.0, 1.0) * LINE_DARKNESS;

    // ---- 3) 해칭 ----
    float rawDepth = texture2D(depthtex0, uv).r;
    float skyMask  = step(rawDepth, 0.9999);

    float tone   = clamp(floor(lC * TONE_LEVELS) / (TONE_LEVELS - 1.0), 0.0, 1.0);
    float demand = 1.0 - tone;

    float a = radians(HATCH_ANGLE);
    float across, along, spacing;

#if HATCH_ANCHOR == 1
    vec3 vpos  = viewPosFromDepth(uv, rawDepth);
    vec3 wpos  = (gbufferModelViewInverse * vec4(vpos, 1.0)).xyz + cameraPosition;
    float vdist = max(length(vpos), 0.1);

    vec3 dirA = normalize(vec3(sin(a) * 0.8, 0.75, cos(a) * 0.8));
    vec3 dirB = normalize(cross(dirA, vec3(0.13, 0.99, 0.05)));

    float pxPerBlock = 0.5 * viewHeight * gbufferProjection[1][1] / vdist;
    float sWorld = HATCH_SPACING / max(pxPerBlock, 1e-4);
    sWorld = exp2(floor(log2(max(sWorld, 1e-4)) + 0.5));

    across  = dot(wpos, dirA);
    along   = dot(wpos, dirB);
    spacing = sWorld;
#else
    // 흔드는 폭을 획 간격에 비례시킨다. 고정값이면 간격이 좁을 때 심하게 깜빡인다.
    float jit = HATCH_SPACING * HATCH_JITTER;
    vec2 hp = gl_FragCoord.xy
            + (vec2(hash12(vec2(stepT, 1.0)), hash12(vec2(stepT, 2.0))) - 0.5) * jit;
    vec2 dir  = vec2(cos(a), sin(a));
    vec2 perp = vec2(-dir.y, dir.x);

    across  = dot(hp, perp);
    along   = dot(hp, dir) * 0.02;
    spacing = HATCH_SPACING;
#endif

    float w = HATCH_WIDTH * (0.55 + 1.5 * smoothstep(0.10, 0.95, demand));

    float s1 = stripe(across,                 along, spacing, w,        1.0);
    float s2 = stripe(across + spacing * 0.5, along, spacing, w * 0.75, 6.0)
             * smoothstep(0.58, 0.82, demand);

    float shade = max(s1, s2)
                * smoothstep(0.12, 0.30, demand)
                * HATCH_STRENGTH * skyMask;

    // 채우기에도 같은 거리 단계를 적용한다.
    // 이게 있어야 겹친 나무들이 서로 다른 회색이 되어 층으로 분리된다.
    shade *= mix(1.0, 1.0 - TONE_FADE, distT);

    // ---- 4) 종이 ----
    float grain = (vnoise(gl_FragCoord.xy * 0.9) - 0.5) * PAPER_GRAIN
                + (hash12(gl_FragCoord.xy)      - 0.5) * PAPER_GRAIN * 0.5;

    float v = clamp(1.0 + grain - shade - line, 0.0, 1.0);

    vec3 ink   = vec3(0.13, 0.12, 0.14);
    vec3 sheet = vec3(0.97, 0.96, 0.93);
    vec3 outc  = mix(ink, sheet, v);

    vec3 chroma = cC / max(lC, 0.001);
    outc = mix(outc, outc * chroma, COLOR_MIX);

    // ---- 디버그 뷰 ----
#if DEBUG_VIEW == 1
    outc = cC;                                                  // 후처리 전 원본 색
#elif DEBUG_VIEW == 2
    outc = vec3(clamp(linDepth(rawDepth) / 64.0, 0.0, 1.0));     // depthtex0
#elif DEBUG_VIEW == 3
    outc = vec3(clamp(linDepth(texture2D(depthtex1, uv).r) / 64.0, 0.0, 1.0)); // depthtex1
#elif DEBUG_VIEW == 4
    outc = vec3(1.0 - line);                                     // 선만
#elif DEBUG_VIEW == 5
    outc = vec3(1.0 - shade);                                    // 해칭만
#elif DEBUG_VIEW == 6
    outc = vec3(tmask, 0.0, 0.0);                                // 반투명 마스크
#endif

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(outc, 1.0);
}
