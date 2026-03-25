package unnamed

import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import "core:os"

import rl "vendor:raylib"

import "game"

main :: proc()
{
  context.logger = log.create_console_logger()
  context.logger.options = { .Level, .Short_File_Path, .Line, .Procedure,
    .Terminal_Color }

  when ODIN_DEBUG {
    tracking_allocator: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)

    defer {
      for _, entry in tracking_allocator.allocation_map {
        log.warnf("%v BYTES LEAKED AT %v\n", entry.size, entry.location)
      }
      mem.tracking_allocator_destroy(&tracking_allocator)
    }
  }

  game.conf.scr_w = 640
  game.conf.scr_h = 480
  game.conf.tile_size = 64

  rl.InitWindow(game.conf.scr_w, game.conf.scr_h, "UNNAMED")
  rl.SetTargetFPS(10)

  forest := game.TILEinit("./data/forest.png")

  cube: game.Block
  cube = game.Cube { 
    faces = { forest, forest, forest, forest, forest }
  }

  tmp_map: []^game.Block = {
    &cube, &cube, &cube, &cube, &cube,
    &cube, &cube, &cube, &cube, &cube,
    &cube, &cube, &cube, &cube, &cube,
    &cube, &cube, &cube, &cube, &cube,
    &cube, &cube, &cube, &cube, &cube,

    nil, nil, nil, nil, nil,
    nil, nil, &cube, &cube, nil,
    nil, &cube, &cube, &cube, nil,
    nil, &cube, &cube, &cube, nil,
    nil, nil, nil, nil, nil,

    nil, nil, nil, nil, nil,
    nil, nil, nil, &cube, nil,
    nil, &cube, &cube, &cube, nil,
    nil, nil, nil, nil, nil,
    nil, nil, nil, nil, nil
  }
  bmap := game.BMAPinit(5, 5, 3)
  for block, i in tmp_map {
    bmap.blocks[i] = block
  }

  angle: game.Angle = .V0

  for !rl.WindowShouldClose() {

    if rl.IsKeyDown(.LEFT) {
      angle = game.Angle.DX315 if game.Angle.V0 == angle else
        angle - game.Angle.SI45
    } else if rl.IsKeyDown(.RIGHT) {
      angle = game.Angle.V0 if game.Angle.DX315 == angle else
        angle + game.Angle.SI45
    }

    rl.BeginDrawing()

      rl.ClearBackground(rl.BLUE)

      game.BMAPrender(bmap, angle)

    rl.EndDrawing()
  }

  game.BMAPfree(&bmap)
  game.TILEfree(forest)

  rl.CloseWindow()
}
