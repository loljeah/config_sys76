#version 300 es
precision highp float;

uniform vec2  iResolution;
uniform float iTime;

layout(location = 0) out vec4 fragColor;

// ── noise ─────────────────────────────────────────────────────────

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

// ── HSV → RGB   (all channels [0,1]) ─────────────────────────────

vec3 hsv2rgb(vec3 hsv) {
    vec3 c = clamp(abs(mod(hsv.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    return hsv.z * mix(vec3(1.0), c, hsv.y);
}

// ── main ─────────────────────────────────────────────────────────

void main() {
    vec2 px = gl_FragCoord.xy;
    vec2 uv = px / iResolution.xy;

    // ── character grid ───────────────────────────────────────────
    float cW   = 16.0;                                  // cell width  (px)
    float cH   = 24.0;                                  // cell height (px)
    float col  = floor(px.x / cW);                      // column index
    float nCol = ceil(iResolution.x / cW);              // total columns
    float rowT = (iResolution.y - px.y) / cH;           // row measured from the top
    float nRow = iResolution.y / cH;                    // total rows

    // sub-cell UV — origin at top-left of each cell
    vec2 cellUv = fract(px / vec2(cW, cH));
    cellUv.y    = 1.0 - cellUv.y;

    // ── rain streams ─────────────────────────────────────────────
    // Three independent layers per column produce dense, natural rain.
    // Each layer has its own speed, phase offset, and tail length —
    // all hashed from the column index so the pattern is deterministic.

    float bright   = 0.0;     // peak brightness at this pixel
    float headProx = 0.0;     // how close the nearest stream head is
    float hue      = 0.0;     // hue of the brightest stream here

    for (int i = 0; i < 3; i++) {
        float seed  = col + float(i) * 7919.0;
        float speed = 3.5  + hash(seed      ) * 7.0;   // rows / sec
        float phase = hash(seed + 1.0) * nRow * 3.0;   // start offset
        float tail  = 12.0 + hash(seed + 2.0) * 20.0;  // tail length (rows)

        // Head position in rows-from-top; wraps once it clears the screen
        float head = mod(speed * iTime + phase, nRow + tail);
        float d    = head - rowT;    // 0 at head, positive = further up the tail

        // Tail brightness — smooth power-curve falloff
        if (d > 0.0 && d < tail) {
            float b = pow(1.0 - d / tail, 1.4);
            if (b > bright) {
                bright = b;
                // Rainbow hue built from four sources:
                //   column gradient   – spreads colours left → right
                //   layer offset      – keeps overlapping streams distinct
                //   time drift        – whole palette slowly rotates
                //   sine wave         – a gentle "breathing" colour wave
                hue = fract(
                      col    / nCol  * 1.5
                    + float(i)      * 0.33
                    + iTime         * 0.07
                    + sin(iTime * 0.4 + col / nCol * 6.283185) * 0.18
                );
            }
        }

        // Glow zone: the first ~2 rows directly behind the head
        if (d > 0.0 && d < 2.0)
            headProx = max(headProx, 1.0 - d * 0.5);
    }

    // ── glyph mask ───────────────────────────────────────────────
    // Each cell renders a 5×7 pseudo-random pixel block that looks
    // like a katakana glyph.  The seed re-rolls ~8 times per second
    // giving the classic Matrix character-flicker.
    float cSeed = hash(col * 97.0 + floor(rowT) * 41.0 + floor(iTime * 8.0));
    vec2  gIdx  = floor(
        clamp((cellUv - 0.07) * 1.16, 0.0, 0.999) * vec2(5.0, 7.0)
    );
    float glyph = step(0.37, hash(cSeed * 1000.0 + gIdx.x + gIdx.y * 5.0));

    // ── colour assembly ──────────────────────────────────────────
    float finalB = bright * (0.50 + 0.50 * glyph);     // glyph on/off modulation
    float sat    = 1.0   - headProx * 0.55;            // head desaturates → white glow

    vec3 colour  = hsv2rgb(vec3(hue, sat, min(finalB * 1.5, 1.0)));
    colour      += vec3(headProx * bright * 0.45);     // additive bloom at each head

    // ── vignette – darken edges (matches starfield) ─────────────
    float vig = length((uv - 0.5) * 2.0);
    colour   *= 1.0 - 0.3 * vig * vig;

    // ── tone mapping – compress additive glow ────────────────────
    colour = 1.0 - exp(-colour * 2.0);

    fragColor = vec4(colour, 1.0);
}
