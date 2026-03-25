package game

import "core:math"

// An enum listing 8 angles, aligning with the 8 cardinal directions.
Angle :: enum {
  V0 = 0,
  SI45 = 45,
  H90 = 90,
  DX135 = 135,
  V180 = 180,
  SI225 = 225,
  H270 = 270,
  DX315 = 315,
}

/*
   An enum listing all 4 axes (including both diagonals, which in this case are
   named SI and DX, after Sinister (top-right -> bottom-left) and Dexter
   (bottom-left -> top-right)
*/
Axis :: enum {
  V = 0,
  SI,
  H,
  DX,
}

Vector2_i32 :: struct {
  x: i32,
  y: i32
}

Vector3_i32 :: struct {
  x: i32,
  y: i32,
  z: i32
}

/*
   This ellusive little thing returns a value which cannot be set as a
   compile-time constant. The 'base component' is that of the tile_size, when
   tilted 45 degrees.
*/
get_diagonal_base_component :: proc() -> i32
{
  base_comp :=
    i32(f32(conf.tile_size) * math.cos(math.to_radians(f32(Angle.SI45))))
  base_comp = base_comp + 1 if (base_comp % 2) != 0 else base_comp
  return base_comp
}
