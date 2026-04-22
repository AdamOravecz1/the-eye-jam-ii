shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform float intensity : hint_range(0.0, 3.0) = 1.2;

void fragment() {
    vec4 mask = texture(TEXTURE, UV);

    // Completely ignore transparent pixels
    if (mask.a <= 0.01) {
        discard;
    }

    vec4 screen_col = texture(screen_texture, SCREEN_UV);

    float m = mask.a;

    vec3 boosted = screen_col.rgb * (1.0 + m * intensity);

    COLOR = vec4(boosted, screen_col.a);
}