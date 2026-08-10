#version 120

// 플레이어 스킨의 바깥 레이어(모자/재킷/소매)와 엔티티의 반투명 부분.
//
// 이 파일이 없으면 Iris가 gbuffers_water로 폴백시킨다.
// 그러면 WATER_OPACITY가 스킨 바깥 레이어에까지 적용돼서
// 모자 레이어가 사라지고 밑의 본체가 비쳐 보인다.
//
// 여기서는 알파를 손대지 않는다. 물 처리와 완전히 분리.

uniform sampler2D gtexture;

varying vec2 texcoord;
varying vec4 vcolor;


// colortex1 = 반투명 마스크.
// 초기값에 의존하지 않기 위해 모든 프로그램이 자기 픽셀 값을 명시적으로 쓴다.
// 여기서는 0 (반투명 아님). 알파는 1로 둬야 블렌딩 시 확실히 덮어쓴다.
/* DRAWBUFFERS:01 */
void main() {
    vec4 col = texture2D(gtexture, texcoord) * vcolor;
    if (col.a < 0.05) discard;

    gl_FragData[0] = col;
    gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
}
