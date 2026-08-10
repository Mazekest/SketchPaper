#version 120

// 작업은 전부 composite에서 끝났다. 여기는 화면에 옮기기만 함.

uniform sampler2D colortex0;

varying vec2 texcoord;

void main() {
    gl_FragColor = vec4(texture2D(colortex0, texcoord).rgb, 1.0);
}
