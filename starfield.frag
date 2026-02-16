#version 300 es
precision highp float;

uniform vec2 iResolution;
uniform float iTime;

layout(location = 0) out vec4 fragColor;

// --- Pseudo-random hash ---
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// --- HSV to RGB (all channels [0,1]) ---
vec3 hsv2rgb(vec3 hsv) {
    vec3 c = clamp(abs(mod(hsv.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    return hsv.z * mix(vec3(1.0), c, hsv.y);
}

void main() {
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec2 center = vec2(0.5, 0.5);

    vec3 col = vec3(0.0);

    // --- 150 stars, each looping outward from center (warp speed) ---
    for (int i = 0; i < 150; i++) {
        float fi = float(i);
        vec2 seed = vec2(fi, fi * 2.39 + 1.0);

        // Fixed random outward direction per star
        float angle = hash(seed) * 6.2831853;
        vec2 dir = vec2(cos(angle), sin(angle));

        // Staggered time loop: t runs 0 -> 1, offset differs per star
        float phase = hash(seed + vec2(100.0));
        float t = fract(iTime * 0.55 + phase);

        // Radial distance: quadratic = slow near center, fast at edges
        float r     = t * t * 0.72;
        vec2  pos   = center + dir * r;

        // Streak trail: where the star was a short moment ago
        float tTrail = max(t - 0.035 - t * 0.02, 0.0);
        float rTrail = tTrail * tTrail * 0.72;
        vec2  posTrail = center + dir * rTrail;

        // Closest point on streak segment to current pixel
        vec2  seg      = pos - posTrail;
        float segLenSq = dot(seg, seg);
        float proj     = clamp(dot(uv - posTrail, seg) / (segLenSq + 1e-6), 0.0, 1.0);
        float d        = length(uv - (posTrail + seg * proj));

        // Gaussian glow falloff
        float bright = exp(-d * d * 18000.0);

        // Fade out before the loop resets (t near 1)
        bright *= smoothstep(1.0, 0.82, t);

        // Brighter as star accelerates away from center
        bright *= 0.5 + 0.8 * t;

        // --- Color: each star has a hue that slowly drifts over time ---
        float hue = fract(hash(seed + vec2(50.0)) + iTime * 0.1);
        float sat = 0.7 + 0.3 * hash(seed + vec2(200.0));

        col += hsv2rgb(vec3(hue, sat, bright));
    }

    // --- Soft vignette: darken edges ---
    float vig = length((uv - center) * 2.0);
    col *= 1.0 - 0.3 * vig * vig;

    // --- Tone mapping: additive blending can pile up, compress gently ---
    col = 1.0 - exp(-col * 2.0);

    fragColor = vec4(col, 1.0);
}
