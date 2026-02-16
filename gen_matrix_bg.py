#!/usr/bin/env python3
# gen_matrix_bg.py  –  render one Matrix-rain frame as a PNG.
#
# hyprlock background { reload_cmd } calls this every second.
# stdout = path to the written PNG (hyprlock may use it to update path).
# Algorithm mirrors matrix.frag: same hash, same stream math, same colours.

import math, os, struct, time, zlib

# ── tunables ─────────────────────────────────────────────────────
W, H    = 120, 68          # 1 px = 1 character cell; GL bilinear scales up
LAYERS  = 3                # stream layers per column (same as shader)
OUT_DIR = os.path.expanduser("~/.cache/hyprlock")
OUT     = os.path.join(OUT_DIR, "matrix.png")

# ── helpers ──────────────────────────────────────────────────────

def _h(n):
    """fract(sin(n)*43758.5453) – identical to the GLSL hash."""
    v = math.sin(float(n)) * 43758.5453123
    return v - math.floor(v)

def _hsv(h, s, v):
    """HSV → (R, G, B) each 0-255.  h in [0,1)."""
    h %= 1.0
    i = int(h * 6.0)
    f = h * 6.0 - i
    p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    c = [(v,t,p),(q,v,p),(p,v,t),(p,q,v),(t,p,v),(v,p,q)][i % 6]
    return (int(c[0] * 255), int(c[1] * 255), int(c[2] * 255))

# ── main ─────────────────────────────────────────────────────────

def main():
    T = time.time()
    os.makedirs(OUT_DIR, exist_ok=True)

    # --- pre-compute stream head positions & hue components --------
    # heads[col] = [(head, tail), …]  one per layer
    heads = []
    for col in range(W):
        ch = []
        for layer in range(LAYERS):
            seed  = col + layer * 7919
            speed = 3.5  + _h(seed)     * 7.0
            phase = _h(seed + 1)        * H * 3.0
            tail  = 12.0 + _h(seed + 2) * 20.0
            head  = math.fmod(speed * T + phase, H + tail)
            ch.append((head, tail))
        heads.append(ch)

    # hue = hue_base[col] + layer*0.33 + hue_wave[col]  (mod 1)
    hue_base = [col / W * 1.5 + T * 0.07            for col in range(W)]
    hue_wave = [math.sin(T * 0.4 + col / W * 6.283185) * 0.18  for col in range(W)]

    # --- raster scan ------------------------------------------------
    raw = bytearray()                       # PNG pre-compression buffer

    for row in range(H):
        raw.append(0)                       # PNG row-filter: None

        for col in range(W):
            bright     = 0.0
            head_prox  = 0.0
            best_layer = 0

            for layer in range(LAYERS):
                head, tail = heads[col][layer]
                d = head - row              # 0 at head, + = up the tail

                if 0.0 < d < tail:
                    b = (1.0 - d / tail) ** 1.4
                    if b > bright:
                        bright     = b
                        best_layer = layer

                if 0.0 < d < 2.0:
                    hp = 1.0 - d * 0.5
                    if hp > head_prox:
                        head_prox = hp

            # --- colour --------------------------------------------
            if bright < 0.01:
                raw.extend((0, 0, 0))
            else:
                hue  = math.fmod(hue_base[col] + best_layer * 0.33 + hue_wave[col], 1.0)
                sat  = 1.0 - head_prox * 0.55          # head → white
                r, g, b = _hsv(hue, sat, min(bright * 1.5, 1.0))
                glow = int(head_prox * bright * 0.45 * 255)  # additive head bloom
                raw.extend((min(r + glow, 255),
                            min(g + glow, 255),
                            min(b + glow, 255)))

    # --- PNG encode -------------------------------------------------
    def _chunk(ct, data):
        c   = ct + data
        crc = zlib.crc32(c) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + c + struct.pack(">I", crc)

    png = (b'\x89PNG\r\n\x1a\n'
         + _chunk(b'IHDR', struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
         + _chunk(b'IDAT', zlib.compress(bytes(raw)))
         + _chunk(b'IEND', b''))

    with open(OUT, 'wb') as fh:
        fh.write(png)

    print(OUT)                              # hyprlock may use stdout as new path

if __name__ == '__main__':
    main()
