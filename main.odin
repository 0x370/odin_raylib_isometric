package isometric

import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"

import rl "vendor:raylib"

import "core:math/linalg"

TILE_SIZE :: 32
SCREEN_OFFSET :: 450

ISO_MATRIX :: linalg.Matrix2f32 {
    1 * 0.5 * TILE_SIZE, -1 * 0.5 * TILE_SIZE,
    0.5 * 0.5 * TILE_SIZE, 0.5 * 0.5 * TILE_SIZE
}

to_screen_coordinate :: proc(tile: rl.Vector2) -> rl.Vector2 {
    return ISO_MATRIX * tile
}

to_grid_coordinate :: proc(screen: rl.Vector2) -> rl.Vector2 {    
    inv := linalg.matrix2_inverse_f32(ISO_MATRIX)
    return screen * inv
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

    rl.InitWindow(1280, 720, "Isometric text")
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
        mouse.x -= SCREEN_OFFSET

        grid_pos := to_grid_coordinate(mouse)

        rl.DrawText(rl.TextFormat("%f %f", grid_pos.x, grid_pos.y), 5, 5, 14, rl.WHITE)
        
        for row, y in lines {
            for tile, x in row {
                iso_pos := to_screen_coordinate({f32(x), f32(y)})
                iso_pos.x -= TILE_SIZE * 0.5
                iso_pos.x += SCREEN_OFFSET

                if tile == '1' {
                    if int(grid_pos.x) == x && int(grid_pos.y) == y {
                        rl.DrawTexture(texture, i32(iso_pos.x), i32(iso_pos.y - 5), rl.WHITE)
                        rl.DrawTexture(hl_texture, i32(iso_pos.x), i32(iso_pos.y - 5), rl.WHITE)
                    } else {
                        rl.DrawTexture(texture, i32(iso_pos.x), i32(iso_pos.y), rl.WHITE)
                    }
                }
            }
        }
    }
}
