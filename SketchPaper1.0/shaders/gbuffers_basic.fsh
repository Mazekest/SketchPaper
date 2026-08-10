#version 120

uniform sampler2D gtexture;

varying vec2 texcoord;
varying vec4 vcolor;


// colortex1 = 반투명 마스크.
// 초기값에 의존하지 않기 위해 모든 프로그램이 자기 픽셀 값을 명시적으로 쓴다.
// 여기서는 0 (반투명 아님). 알파는 1로 둬야 블렌딩 시 확실히 덮어쓴다.
/* DRAWBUFFERS:01 */
void main() {
    vec4 col = texture2D(gtexture, texcoord) * vcolor;

    // 컷아웃(잎, 풀, 사탕수수) 처리
    if (col.a < 0.1) discard;

    gl_FragData[0] = col;
    gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
}
