shader_type canvas_item;

// Uniforms（保持原样，可根据需要增加更多纹理）
uniform float angle;
uniform sampler2D texture_1;
uniform sampler2D texture_2;
// 若需要更多纹理，可继续添加 texture_3, texture_4, ... 并相应修改随机分支
uniform float line_distance;
uniform float texture_distance;
uniform float texture_width;
uniform float scroll_speed;
uniform vec4 solid_color : source_color;
uniform vec2 screen_size;

// 伪随机函数：输入一个浮点数，输出 [0,1) 的随机值
float rand(float seed) {
    return fract(sin(seed) * 43758.5453);
}

void fragment() {
    // 宽高比调整（与原逻辑一致）
    float aspect_condition = step(screen_size.x, screen_size.y);
    float multi_width_x = mix(screen_size.y / screen_size.x, 1.0, aspect_condition);
    float multi_width_y = mix(1.0, screen_size.x / screen_size.y, aspect_condition);
    float uv_x = UV.x / multi_width_x;
    float uv_y = UV.y / multi_width_y;

    // 旋转UV
    float real_uv_x = uv_x * cos(angle) + uv_y * sin(angle);
    float real_uv_y = -uv_x * sin(angle) + uv_y * cos(angle);
    vec2 real_uv = vec2(real_uv_x, real_uv_y);

    // 计算行索引
    float line_index = floor(real_uv.y / (texture_width + line_distance));
    float line_local_y = fract(real_uv.y / (texture_width + line_distance));

    // ========== 修改部分：随机决定纹理和滚动方向 ==========
    // 以行索引为基础生成随机种子（加入一个大的常数避免规律性）
    float seed = line_index * 1.0;
    float rnd = rand(seed);          // 0~1 随机值

    // 根据随机值选择纹理（目前支持两个纹理，若需更多可扩展分支）
    float texture_selector = rnd;
    float scroll_direction = (rnd < 0.5) ? 1.0 : -1.0;   // 方向也随机
    // =================================================

    // 水平滚动（使用随机方向）
    float horizontal_scroll = TIME * scroll_speed * scroll_direction;
    float local_x = fract(real_uv.x / (texture_width + texture_distance) + horizontal_scroll);

    vec2 processed_uv = vec2(local_x, line_local_y);
    vec2 texture_uv = processed_uv * vec2(
        (texture_distance + texture_width) / texture_width,
        (texture_width + line_distance) / texture_width
    );

    // 采样纹理（根据随机值选择）
    vec4 color;
    if(texture_uv.x > 1.0 || texture_uv.y > 1.0) {
        color = solid_color;
    } else if(texture_selector < 0.5) {
        color = texture(texture_1, texture_uv);
    } else {
        color = texture(texture_2, texture_uv);
    }

    COLOR = (color.a == 0.0) ? solid_color : color;
}