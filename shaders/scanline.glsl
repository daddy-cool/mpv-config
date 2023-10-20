//!HOOK SCALED
//!BIND HOOKED
//!DESC scanline

#define MAX_BRIGHTNESS_LOSS 0.05

vec4 hook() {
    float HEIGHT = target_size.y;
    int LINES = int(floor(HEIGHT/2));
    int SPACING = int(floor(HEIGHT/LINES));
    float THICKNESS = SPACING/2;
    float BRIGHTNESS = 1-max(0, min(((MAX_BRIGHTNESS_LOSS*HEIGHT)/(LINES*THICKNESS)),1));

    vec4 tex = HOOKED_texOff(HOOKED_pos);

    int line = int(floor(frame*THICKNESS)) % SPACING;

    int current_line = int(floor(HOOKED_pos.y * HEIGHT));

    int x = (current_line) % SPACING;

    if (x >= line && x < line+THICKNESS) {
        return tex*BRIGHTNESS;
    }

    return tex;
}