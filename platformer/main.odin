package platformer

import "core:math"

import rl "vendor:raylib"

WINDOW_WIDTH :: 640

MOVE_SPEED :: 400
FALL_SPEED :: 2000
JUMP_SPEED :: 600

PLAYER_SIZE :: 64

main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, (WINDOW_WIDTH / 4) * 3, "PLATFORMER")
	rl.SetTargetFPS(30)

	player_pos := rl.Vector2 { WINDOW_WIDTH / 2,
		f32(rl.GetScreenHeight() / 2) }
	player_vel: rl.Vector2
	player_grounded: bool

	prev_window_pos := rl.GetWindowPosition()

	for false == rl.WindowShouldClose() {

		if rl.IsKeyDown(.LEFT) {
			player_vel.x = -MOVE_SPEED
		} else if  rl.IsKeyDown(.RIGHT) {
			player_vel.x = MOVE_SPEED
		} else {
			player_vel.x = 0
		}

		if false == player_grounded {
			player_vel.y += FALL_SPEED * rl.GetFrameTime()
		}
		if true == player_grounded && rl.IsKeyDown(.SPACE) {
			player_vel.y = -JUMP_SPEED
			player_grounded = false
		}

		cur_window_pos := rl.GetWindowPosition()
		window_pos_diff := prev_window_pos - cur_window_pos
		player_pos += window_pos_diff

		player_pos += player_vel * rl.GetFrameTime()

		if player_pos.y < 0 {
			player_pos.y = 0
		} else if f32(rl.GetScreenHeight())-PLAYER_SIZE < player_pos.y {
			player_pos.y = f32(rl.GetScreenHeight()) - PLAYER_SIZE
			player_grounded = true
		}
		if player_pos.x < 0 {
			player_pos.x = 0
		} else if f32(rl.GetScreenWidth())-PLAYER_SIZE < player_pos.x {
			player_pos.x = f32(rl.GetScreenWidth()) - PLAYER_SIZE
		}

		player_pos.x = math.trunc(player_pos.x)
		player_pos.y = math.trunc(player_pos.y)

		rl.BeginDrawing()
			rl.ClearBackground(rl.BLUE)
			rl.DrawRectangleV(player_pos,
				{ PLAYER_SIZE, PLAYER_SIZE }, rl.GREEN)
			rl.DrawText(rl.TextFormat("%.0f,%.0f", player_pos.x,
					player_pos.y), 6, 6, 14, rl.WHITE)
		rl.EndDrawing()

		prev_window_pos = cur_window_pos
	}

	rl.CloseWindow()
}
