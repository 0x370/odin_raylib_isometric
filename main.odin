package isometric

import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"

import rl "vendor:raylib"

i_x :: 1
i_y :: 0.5
j_x :: -1
j_y :: 0.5

w :: 32
h :: 32

WIDTH :: 1280
HEIGHT :: 720

CENTER_X :: WIDTH / 2
CENTER_Y :: HEIGHT / 2

to_screen_coordinate :: proc(tile: rl.Vector2) -> rl.Vector2 {
    return {
        tile.x * i_x * 0.5 * w + tile.y * j_x * 0.5 * w,
        tile.x * i_y * 0.5 * h + tile.y * j_y * 0.5 * h,
    }
}

invert_matrix :: proc(a, b, c, d: f32) -> (inv: rl.Vector4) {
    det := 1.0 / (a * d - b * c)
    return rl.Vector4{
        det * d,
        det * -b,
        det * -c,
        det * a,
    }
}

to_grid_coordinate :: proc(screen: rl.Vector2) -> rl.Vector2 {
    adjusted : rl.Vector2 = {
        screen.x - CENTER_X,
        screen.y - CENTER_Y
    }

    a : f32 = i_x * 0.5 * w
    b : f32 = j_x * 0.5 * w
    c : f32 = i_y * 0.5 * h
    d : f32 = j_y * 0.5 * h
    
    inv := invert_matrix(a, b, c, d)
    
    return rl.Vector2{
        adjusted.x * inv.x + adjusted.y * inv.y,
        adjusted.x * inv.z + adjusted.y * inv.w,
    }
}

main :: proc() {
    data, result := os.read_entire_file("resources/map.txt")
    defer delete(data)

    if !result {
        fmt.eprintf("failed to read file.")
        return
    }

    data_stringified := string(data)
    defer delete(data_stringified)

    lines := strings.split(data_stringified, "\n")
    defer delete(lines)

    rl.InitWindow(WIDTH, HEIGHT, "Isometric text")
    defer rl.CloseWindow()

    rl.SetTargetFPS(144)

    image := rl.LoadImage("resources/grass.png")
    hl := rl.LoadImage("resources/highlight.png")

    texture := rl.LoadTextureFromImage(image)
    defer rl.UnloadTexture(texture)
    
    hl_texture := rl.LoadTextureFromImage(hl)
    defer rl.UnloadTexture(hl_texture)

    //no need to keep the images in memory if they're loaded onto the gpu.
    rl.UnloadImage(image)
    rl.UnloadImage(hl)

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl.ClearBackground(rl.BLACK)

        mouse := rl.GetMousePosition()
        grid_pos := to_grid_coordinate(mouse)

        rl.DrawText(rl.TextFormat("%f %f", grid_pos.x, grid_pos.y), 5, 5, 14, rl.WHITE)
        
        for row, y in lines {
            for tile, x in row {
                iso_pos := to_screen_coordinate({f32(x), f32(y)})
                iso_pos.x -= w * 0.5
                iso_pos.x += CENTER_X
                iso_pos.y += CENTER_Y

                if tile == '1' {
                    rl.DrawTexture(texture, i32(iso_pos.x), i32(iso_pos.y), rl.WHITE)

                    if int(grid_pos.x) == x && int(grid_pos.y) == y {
                        rl.DrawTexture(hl_texture, i32(iso_pos.x), i32(iso_pos.y), rl.WHITE)
                    }
                }
            }
        }
        rl.DrawRectangle(i32(mouse.x), i32(mouse.y), 5, 5, rl.RED)
    }
}
