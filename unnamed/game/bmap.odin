package game

import "core:math"
import "core:log"

import rl "vendor:raylib"

// A one-dimensional dynamic array of Blocks, acting as a 3D array
BlockMap :: struct {
  width: i32,
  height: i32,
  depth: i32,
  blocks: [dynamic]^Block
}

BMAPinit :: proc(width: i32, height: i32, depth: i32) -> BlockMap
{
  return BlockMap {
    width = width,
    height = height,
    depth = depth,
    blocks = make([dynamic]^Block, depth * height * width)
  }
}

// Makes it easy to access an (x,y,z) point in the array
BMAPindex :: proc(this: BlockMap, x: i32, y: i32, z: i32) -> ^Block
{
  index := x + (y * this.width) + (z * this.width * this.height)
  return nil if index < 0 || i32(len(this.blocks)) < index else this.blocks[index]
}

// An enum which defines the two rotation directions: CW and CCW
@(private="file")
RotationDirection :: enum {
  CW,
  CCW
}

// CW oR CCW rotation of an (x,y) point, based on width, height and angle
@(private="file")
rotate_xy :: proc(x: i32, y: i32, w: i32, h: i32, angle:Angle,
  direction: RotationDirection) -> Vector2_i32
{
  rotated: Vector2_i32
  switch direction {
  case .CW:
    #partial switch angle {
    case .V0:
      rotated = { x, y }
    case .H90:
      rotated.x = h - 1 - y
      rotated.y = x
    case .V180:
      rotated.x = w - 1 - x
      rotated.y = h - 1 - y
    case .H270:
      rotated.x = y
      rotated.y = w - 1 - x
    }
  case .CCW:
    #partial switch angle {
    case .V0:
      rotated.x = x
      rotated.y = y
    case .H90:
      rotated.x = y
      rotated.y = w - 1 - x
    case .V180:
      rotated.x = w - 1 - x
      rotated.y = h - 1 - y
    case .H270:
      rotated.x = h - 1 - y
      rotated.y = x
    }
  }
  return rotated
}

// Set which faces of a cube to render, based on a REAL (x,z,z) location
@(private="file")
get_rendered_faces :: proc(bmap: BlockMap, x: i32, y: i32, z: i32) ->
  CubeFaceSet
{
  rendered_faces: CubeFaceSet = nil
  if y == 0 || nil == BMAPindex(bmap, x, y-1, z) {
    rendered_faces += CubeFaceSet{ .N }
  }
  if x == 0 || nil == BMAPindex(bmap, x-1, y, z) {
    rendered_faces += CubeFaceSet{ .W }
  }
  if (z+1) == bmap.depth || nil == BMAPindex(bmap, x, y, z+1){
    rendered_faces += CubeFaceSet{ .TOP }
  }
  if (x+1) == bmap.width || nil == BMAPindex(bmap, x+1, y, z){
    rendered_faces += CubeFaceSet{ .E }
  }
  if (y+1) == bmap.height || nil == BMAPindex(bmap, x, y+1, z){
    rendered_faces += CubeFaceSet{ .S }
  }
  return rendered_faces
}

// Render the whole-ass map
BMAPrender :: proc(bmap: BlockMap, angle: Angle)
{
  when ODIN_DEBUG {
    log.debug("== START OF BMAP RENDER PROC ==")
  }
  // We will be using this a couple of times for both straights and diagonals
  base_comp := get_diagonal_base_component()

  /*
     By 'render_[whatever]', I mean to suggest a 'virtual' map which coincides
     with what is seen by the camera, in contrast with the original layout of
     the map. In other words, it stands for a rotated map, according to the
     angle.
  */
  /*
     So, these suggest the width and height of the map as it is rotated.
     In reality, these might not be necessary, as I don't think there ever would
     be a case where the camera is not square. But we'll see.
  */
  render_w: i32
  render_h: i32
  switch angle {
  case .V0, .SI45, .V180, .SI225:
    render_w = bmap.width
    render_h = bmap.height
  case .H90, .DX135, .H270, .DX315:
    render_w = bmap.height
    render_h = bmap.width
  }

  /*
     The straight and diagonal views use a different algorithm for rendering,
     but both do the same thing: iterate through every block in the map,
     following a top-left -> bottom-right order, according to the RENDER view,
     discussed earlier.
  */
  switch angle {
  // These are the so-called 'straight' angles
  case .V0, .H90, .V180, .H270:
    // Z doesn't rotate, so we treat it normally
    for z: i32 = 0; z < bmap.depth; z += 1 {

      // For the straight-angle iteration, we use the 'render' dimensions
      render_pos: Vector2_i32
      for render_pos.y = 0; render_pos.y < render_h; render_pos.y += 1 {
        for render_pos.x = 0; render_pos.x < render_w; render_pos.x += 1 {

          /*
             As for what 'real' means, it stands for the actual (x,y) position
             that, according to the rotation, the current 'render' position,
             should be rendered and processed for other considerations.
          */
          real_pos := rotate_xy(render_pos.x, render_pos.y, bmap.width,
                                   bmap.height, angle, RotationDirection.CCW)
          /*
             For the straight view, there are three controls that prevent it
             from rendering if unnecessary:
          */
          // 1. If it is NULL, don't even bother
          block := BMAPindex(bmap, real_pos.x, real_pos.y, z)
          if nil == block {
            continue
          }

          /*
             2. If both the blocks on top and in front of the current block
             (making an L-shape toward the viewer) are not NULL, they will make
             it invisible, so it's better to just not render it.
          */
          check_pos := rotate_xy(render_pos.x, render_pos.y+1, bmap.width,
                       bmap.height, angle, RotationDirection.CW)
          if nil != BMAPindex(bmap, check_pos.x, check_pos.y, z) && 
             nil != BMAPindex(bmap, real_pos.x, real_pos.y, z+1) {
               continue
          }

          /*
             3. If any block in the diagonal between it and the viewer is not
             NULL, the latter will eclipse the former, so, again, it's best to
             not bother.
          */
          check_y := render_pos.y+1
          check_z := z+1
          is_visible := true
          for check_y < render_h && check_z < bmap.depth {
            check_pos = rotate_xy(render_pos.x, check_y, bmap.width,
                         bmap.height, angle, RotationDirection.CCW)
            if nil != BMAPindex(bmap, check_pos.x, check_pos.y, check_z) {
              is_visible = false
              break
            }
            check_y += 1
            check_z += 1
          }
          if false == is_visible {
            continue
          }

          // If all of these controls don't skip, then we will render the block

          rendered_faces := get_rendered_faces(bmap, real_pos.x, real_pos.y, z)

          // The 'origin' is the top-left ON SCREEN position of the map itself
          origin: rl.Vector2 = {
            (math.trunc(f32(conf.scr_w / 2)) -
              math.trunc(f32((render_w * conf.tile_size) / 2))),
            (math.trunc(f32(conf.scr_h/ 2)) -
            math.trunc(f32((render_h * conf.tile_size) / 4)))
          }
          /*
            Then, the 'offset' is the space between the current block and the
            origin.
          */
          offset: rl.Vector3 = {
            f32(render_pos.x * conf.tile_size),
            f32(render_pos.y * (conf.tile_size / 2)),
            f32(z * base_comp),
          }
          // The resulting position on screen can be simplified this way:
          pos_on_screen: rl.Vector2 = {
            origin.x + offset.x,
            origin.y + offset.y - offset.z
          }
          // And, here we go!
          BLOCKrender(block, rendered_faces, pos_on_screen, angle)
        }
      }
    }
  // These are the so-called 'diagonal' angles
  case .SI45, .DX135, .SI225, .DX315:
    //Again, Z does not rotate
    for z: i32 = 0; z < bmap.depth; z += 1 {
      /*
         This iteration algorithm is slightly more complex, and I don't really
         understand it myself...

         The point is this: it so turns out to be, that the sum of W + H results
         in the exact amount of diagonals a matrix has, so we've effectively set
         up a 'virtual', diagonal dimension. I named it after the SI diagonal.
      */
      for si: i32 = 0; si < (render_w + render_h - 1); si += 1 {
        /*
           Then follows another bit of calculation. Essentially, we want to know
           where X should start iterating, and where it should end. I did not
           come up with this, of course.
        */
        x_start := 0 if si < render_h else (si - (render_h - 1))
        x_end := si if si < render_w else (render_w - 1)
        // Then, business as usual.
        render_pos: Vector2_i32
        for render_pos.x = x_start; render_pos.x <= x_end; render_pos.x += 1 {

          // The last coordinate left to calculate is Y:
          render_pos.y = si - render_pos.x

          real_pos := rotate_xy(render_pos.x, render_pos.y, render_w,render_h,
            angle - Angle.SI45, RotationDirection.CCW)
          //        ^ We substract 45 degrees from the current angle.

          /*
             For the diagonal view, there are only two checks that prevent the
             block from being rendered unnecessarily. These two are steps 1 and
             3 of the controls used for the straight view. Consult the
             straight-view case for more info on them.
          */
          // 1
          block := BMAPindex(bmap, real_pos.x, real_pos.y, z)
          if nil == block { 
            continue
          }
          // 2
          check_pos: Vector3_i32 = { render_pos.x+1, render_pos.y+1, z+1 }
          is_visible := true
          for check_pos.x < render_w && check_pos.y < render_h &&
              check_pos.z < bmap.depth {
            
                real_check_pos := rotate_xy(check_pos.x, check_pos.y,
                                  bmap.width, bmap.height, angle - Angle.SI45,
                                  RotationDirection.CCW)
                // Again, we substract 45 degrees from the current angle ^

            if nil != BMAPindex(bmap, real_check_pos.x, real_check_pos.y,
                                  check_pos.z) {
              is_visible = false
              break
            }
            check_pos.x += 1
            check_pos.y += 1
            check_pos.z += 1
          }
          if false == is_visible {
            continue
          }

          /*
            This process, as well, is very similar to the one used for the
            straight view. The main difference is that we use 'base_comp'
            instead of 'conf.tile_size'.
          */
          rendered_faces :=
            get_rendered_faces(bmap, real_pos.x, real_pos.y, z)

          origin: rl.Vector2 = {
            (math.trunc(f32(conf.scr_w / 2))),
            (math.trunc(f32(conf.scr_h / 2)) -
              math.trunc(f32(render_h * base_comp) / 2))
          }
          offset: rl.Vector3 = {
            f32(render_pos.x * base_comp),
            f32(render_pos.y * base_comp),
            f32(z * base_comp),
          }
          pos_on_screen: rl.Vector2 = {
            /*
               I still haven't figured out why I need to substract the size of
               base_comp in order to render the tiles fully centered on the
               origin
            */
            origin.x + offset.x - offset.y - f32(base_comp),
            origin.y + (offset.y / 2) + (offset.x / 2) - offset.z
          }
          rl.BeginDrawing()
          BLOCKrender(
            block,
            rendered_faces,
            pos_on_screen,
            angle)
        }
      }
    }
  }
}

BMAPfree :: proc(this: ^BlockMap)
{
  delete(this.blocks)
  this.blocks = nil
}
