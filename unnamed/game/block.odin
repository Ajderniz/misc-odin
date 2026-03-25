package game

import "core:log"
import "core:math"

import rl "vendor:raylib"

/*
   There are only five faces, instead of six, because the bottom face of a cube,
   given the projection and graphical style, will never be seen by the camera.
*/
CubeFace :: enum {
  N = 0,
  W,
  TOP,
  E,
  S,
}

/*
   A bit set using the CubeFace enum as a basis, used for determining which
   faces of a cube should be rendered.
*/
CubeFaceSet :: bit_set[CubeFace]

// The basic Block type. Its faces coincide with the CubeFace enum.
Cube :: struct {
  faces: [len(CubeFace)]^Tile
}
Something :: struct {
  penis: int
}

/*
   A block *IS PLANNED* to have multiple shapes. Currently, it supports only the
   basic Cube struct.
*/
Block :: union {
  Cube, Something
}

@(private="file")
render_cube :: proc(cube: ^Cube, faces_to_render: CubeFaceSet, pos: rl.Vector2,
  angle: Angle)
{
  when ODIN_DEBUG {
    log.debug("BLOCK TYPE: CUBE")
    log.debugf("ANGLE: %v", angle)
  }
  for face_bit in faces_to_render {
    when ODIN_DEBUG {
      log.debugf("FACE TO RENDER: %v", face_bit)
    }

    face := cube.faces[face_bit]
    if nil == face {
      log.error("FACE IS NULL")
      continue
    }

    texture: ^rl.Texture
    offset: rl.Vector2 = { 0, 0 }
    rotation := Angle.V0
    color := rl.WHITE

    draw_pro := false
    dst_rect: rl.Rectangle
    origin: rl.Vector2

    if CubeFace.TOP == face_bit {
      // use the texture corresponding to the axis
      /*
      switch angle {
      case .V0, .H90, .V180, H270:

        texture = &face.txr
        half_tile_size := f32(conf.tile_size / 2)
        quarter_tile_size := f32(conf.tile_size / 4)
        offset = { -half_tile_size, -half_tile_size }
        draw_pro = true

        #partial switch angle {
        case .V0, .V180:
          dst_rect = { 
            pos.x + offset.x,
            pos.y + offset.y,
            f32(conf.tile_size),
            half_tile_size }
          origin = { half_tile_size, quarter_tile_size) }

        case .H90, .H270:
          dst_rect = { 
            pos.x + offset.x,
            pos.y + offset.y,
            half_tile_size,
            f32(conf.tile_size) }
          origin = { quarter_tile_size, half_tile_size }
        }

      case .SI45, .SI225:
        texture = &face.top_si

      case .DX135, .DX315:
        texture = &face.top_dx
      }
      */
      switch angle {
      case .V0, .V180:
        texture = &face.top[Axis.V]
      case .SI45, .SI225:
        texture = &face.top[Axis.SI]
      case .H90, .H270:
        texture = &face.top[Axis.H]
      case .DX135, .DX315:
        texture = &face.top[Axis.DX]
      }
      if nil == texture {
        when ODIN_DEBUG {
          log.debug("FACE TEXTURE IS NULL")
        }
        continue
      }
      /*
         set 180 rotation for the texture if needed
         (V0, SI45, H90 and DX135 are the original textures,
         so their axis pairs must be rotated)
      */
      if Angle.V180 == angle || Angle.SI225 == angle ||
        Angle.H270 == angle || Angle.DX315 == angle {
        rotation = Angle.V180
        offset = { f32(texture.width), f32(texture.height) }
      }
    } else {
      color = rl.GRAY
      // all other faces use WALL textures
      top_sidx_h_half := f32(face.top[Axis.SI].height) / 2 + 1
      top_vh_h := f32(face.top[Axis.V].height)
      wall_sidx_w := f32(face.wall_si.width)
      /*
      switch angle {
      case .V0, .H90, .V180:, .H270:
        texture = &face.txr
        //TODO
        offset = { 0, top_vh_h }
        draw_pro = true
        dst_rect = {
          
        }

      case: .SI45, .DX135, .SI225, .DX135:
        #partial switch face_bit {
        case .N:
          #partial switch angle {
          case .DX135:
            texture = &face.wall_dx
            offset = { wall_sidx_w, top_sidx_h_half }
          case .SI225:
            texture = &face.wall_si
            offset = { 0, top_sidx_h_half }
          }
        case .W:
          #partial switch angle {
          case .SI225:
            texture = &face.wall_dx
            offset = { wall_sidx_w, top_sidx_h_half }
          case .DX315:
            texture = &face.wall_si
            offset = { 0, top_sidx_h_half }
          }
        case .E:
          #partial switch angle {
          case .SI45:
            texture = &face.wall_dx
            offset = { wall_sidx_w, top_sidx_h_half }
          case .DX135:
            texture = &face.wall_si
            offset = { 0, top_sidx_h_half }
          }
        case .S:
          #partial switch angle {
          case .DX315:
            texture = &face.wall_dx
            offset = { wall_sidx_w, top_sidx_h_half }
          case .SI45:
            texture = &face.wall_si
            offset = { 0, top_sidx_h_half }
          }
        }
      }
      */

      // again, select the proper texture according to face & angle
      #partial switch face_bit {
      case .N:
        #partial switch angle {
        case .DX135:
          texture = &face.wall_dx
          offset = { wall_sidx_w, top_sidx_h_half }
        case .V180:
          texture = &face.wall_v
          offset = { 0, top_vh_h }
        case .SI225:
          texture = &face.wall_si
          offset = { 0, top_sidx_h_half }
        }
      case .W:
        #partial switch angle {
        case .SI225:
          texture = &face.wall_dx
          offset = { wall_sidx_w, top_sidx_h_half }
        case .H270:
          texture = &face.wall_v
          offset = { 0, top_vh_h }
        case .DX315:
          texture = &face.wall_si
          offset = { 0, top_sidx_h_half }
        }
      case .E:
        #partial switch angle {
        case .SI45:
          texture = &face.wall_dx
          offset = { wall_sidx_w, top_sidx_h_half }
        case .H90:
          texture = &face.wall_v
          offset = { 0, top_vh_h }
        case .DX135:
          texture = &face.wall_si
          offset = { 0, top_sidx_h_half }
        }
      case .S:
        #partial switch angle {
        case .DX315:
          texture = &face.wall_dx
          offset = { wall_sidx_w, top_sidx_h_half }
        case .V0:
          texture = &face.wall_v
          offset = { 0, top_vh_h }
        case .SI45:
          texture = &face.wall_si
          offset = { 0, top_sidx_h_half }
        }
      }
    }
    /*
       it is very likely that the face does not face the "camera", so a
       texture was not loaded, and whe MUST NOT try to render it
    */
    if nil == texture {
      when ODIN_DEBUG {
        log.debug("NO FACE SELECTED")
      }
      continue
    }
    when ODIN_DEBUG {
      log.debug("A FACE WAS SELECTED")
    }

    // offset must be truncated to avoid rendering weirdness
    offset = {
      math.trunc(offset.x), 
      math.trunc(offset.y)
    }

    rl.DrawTextureEx(
      texture^,
      pos + offset,
      f32(rotation),
      1,
      color)
  }
}

// Render a single block at a certain spot, at a certain angle
BLOCKrender :: proc(block: ^Block, faces_to_render: CubeFaceSet,
  pos: rl.Vector2, angle: Angle)
{
  when ODIN_DEBUG {
    log.debugf("=== START OF BLOCK RENDER PROC ===")
  }
  // first, find out what type of block we're dealing with
  switch b in block {
  case Cube:
    render_cube(cast(^Cube)block, faces_to_render, pos, angle)
  case Something:
  }
}
