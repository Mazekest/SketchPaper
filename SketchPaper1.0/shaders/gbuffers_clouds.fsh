#version 120

// 구름을 흰색으로 밀어버림. 구름도 지오메트리라 깊이를 쓰므로
// composite에서 외곽선이 붙어 "손으로 그린 뭉툭한 구름"이 됨.
//
// 만약 이 버전에서 구름이 깊이를 안 쓰거나 결과가 지저분하면
// 아래 값을 1로 바꿔서 구름을 통째로 지울 것.
#define HIDE_CLOUDS 0 // [0 1]

uniform sampler2D gtexture;

varying vec2 texcoord;
varying vec4 vcolor;


// colortex1 = 반투명 마스크.
// 초기값에 의존하지 않기 위해 모든 프로그램이 자기 픽셀 값을 명시적으로 쓴다.
// 여기서는 0 (반투명 아님). 알파는 1로 둬야 블렌딩 시 확실히 덮어쓴다.
/* DRAWBUFFERS:01 */
void main() {
#if HIDE_CLOUDS == 1
    discard;
#else
    vec4 col = texture2D(gtexture, texcoord) * vcolor;
    if (col.a < 0.1) discard;
    gl_FragData[0] = vec4(1.0, 1.0, 1.0, col.a);
#endif
    gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
}
