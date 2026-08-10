#version 120

// 모든 지오메트리(지형/엔티티/손/파티클)가 폴백으로 여기를 거침

varying vec2 texcoord;
varying vec4 vcolor;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vcolor = gl_Color;   // 바이옴 틴트 + 바닐라 AO가 여기 들어있음 (공짜 음영)
}
