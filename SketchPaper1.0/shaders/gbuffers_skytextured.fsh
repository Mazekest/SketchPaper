#version 120

// 해와 달.
//
// v2b에서 해가 원본보다 훨씬 컸던 이유:
// 바닐라 해 텍스처는 [중심의 선명한 사각형] + [주변의 옅은 후광]으로 되어 있고
// 후광은 알파가 낮다. v2b는 알파 0.15만 넘으면 전부 그렸기 때문에
// 후광 영역까지 진한 회색으로 칠해져서 몇 배 커 보였다.
//
// 이제 알파와 밝기를 곱한 값으로 자른다. 후광은 탈락하고 중심만 남는다.
#define SUN_CUTOFF 0.55 // [0.2 0.35 0.45 0.55 0.7 0.85]
#define SUN_TONE 0.72   // [0.45 0.58 0.72 0.82 0.9]

uniform sampler2D gtexture;

varying vec2 texcoord;
varying vec4 vcolor;


// colortex1 = 반투명 마스크.
// 초기값에 의존하지 않기 위해 모든 프로그램이 자기 픽셀 값을 명시적으로 쓴다.
// 여기서는 0 (반투명 아님). 알파는 1로 둬야 블렌딩 시 확실히 덮어쓴다.
/* DRAWBUFFERS:01 */
void main() {
    vec4 tex = texture2D(gtexture, texcoord);

    float brightness = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
    if (tex.a * brightness < SUN_CUTOFF) discard;

    gl_FragData[0] = vec4(vec3(SUN_TONE), 1.0);
    gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
}
