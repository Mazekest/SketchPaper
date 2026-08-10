#version 120

// 물/유리/얼음 등 반투명 블록.
//
// 알파를 깎아서 아래 지오메트리가 비치게 하고,
// 동시에 colortex1에 "여기 반투명 표면이 있다"는 표시를 남긴다.
//
// 이 표시가 필요한 이유:
// composite는 물 아래 지형의 윤곽을 그리려고 depthtex1(반투명 제외 깊이)을 쓰는데,
// 마인크래프트는 플레이어 모델도 반투명 렌더 타입으로 그린다.
// 표시가 없으면 플레이어 자리에서도 depthtex1을 참고해버려서
// 플레이어 몸 위에 뒷배경의 외곽선이 그려진다 (= 투과되어 보임).
// 플레이어는 gbuffers_entities_translucent가 따로 처리하므로 표시를 남기지 않는다.

#define WATER_OPACITY 0.22 // [0.05 0.12 0.22 0.35 0.5 0.75]

uniform sampler2D gtexture;

varying vec2 texcoord;
varying vec4 vcolor;

/* DRAWBUFFERS:01 */
void main() {
    vec4 col = texture2D(gtexture, texcoord) * vcolor;
    if (col.a < 0.01) discard;

    gl_FragData[0] = vec4(col.rgb, col.a * WATER_OPACITY);
    gl_FragData[1] = vec4(1.0, 0.0, 0.0, 1.0);   // 반투명 마스크
}
