package dgn_tile

import      "core:fmt"
import      "core:os"
import path "core:path/filepath"
import str  "core:strings"
import rl   "vendor:raylib"

skew :: proc(ref: rl.Image, p_offset_end: i32, new_height: i32) -> rl.Image
{
  width_end : i32= ref.width / 2

  img : rl.Image
  {
    width: i32
    if p_offset_end < 0
    {
      width = abs(p_offset_end) + ref.width
    }
    else if ref.width < p_offset_end + width_end
    {
      width = p_offset_end + width_end
    }
    else
    {
      width = ref.width
    }
    img = rl.GenImageColor(width, new_height, rl.BLANK)
  }

  resized := rl.ImageCopy(ref)
  rl.ImageResizeNN(&resized, img.width, img.height)
  defer rl.UnloadImage(resized)

  width_cur  := ref.width
  width_diff := abs(width_end - width_cur)
  width_step :  i32 = -1

  offset_cur  :  i32 = (p_offset_end < 0) ? abs(p_offset_end) : 0
  offset_end  :  i32 = (p_offset_end < 0) ? 0 : p_offset_end
  offset_diff := abs(p_offset_end)
  offset_step :  i32 = (offset_cur < offset_end) ? 1 : -1

  y_cur  := resized.height - 1
  y_step :  i32 = -1
  y_diff := y_cur

  max_diff := max(width_diff, offset_diff, y_diff)
  i := max_diff

  width_end  =  i/2
  offset_end =  i/2
  y_end      := i/2
  for ; 0 <= i; i -= 1
  {
    rl.ImageDraw(&img, resized,
               rl.Rectangle{0, f32(y_cur), f32(resized.width), 1 },
               rl.Rectangle{f32(offset_cur),f32(y_cur),f32(width_cur),1},
               rl.WHITE)
    width_end -= width_diff
    if width_end < 0
    {
      width_end += max_diff
      width_cur += width_step
    }
    offset_end -= offset_diff
    if offset_end < 0
    {
      offset_end += max_diff
      offset_cur += offset_step
    }
    y_end -= y_diff
    if y_end < 0
    {
      y_end += max_diff
      y_cur += y_step
    }
  }
  return img
}

main :: proc()
{
  if len(os.args) < 2 || 3 < len(os.args)
  {
    fmt.println("Usage: dgn_tile [img file path] [opt: output path]")
    os.exit(1)
  }

  ref: rl.Image
  {
    img_path := str.clone_to_cstring(os.args[1])
    ref = rl.LoadImage(img_path)
    if !rl.IsImageValid(ref)
    {
      fmt.printfln("Loaded image at path '%s' is invalid", img_path)
      os.exit(1)
    }
    delete_cstring(img_path)
  }
  defer rl.UnloadImage(ref)

  if ref.width != ref.height
  {
    fmt.println("Image must be square")
    os.exit(1)
  }

  tileset := rl.GenImageColor(ref.width*5, ref.height*3, rl.MAGENTA)
  defer rl.UnloadImage(tileset)

  // OG image at top-left
  {
    ref_rect := rl.Rectangle{0,0,f32(ref.width),f32(ref.height)}
    rl.ImageDraw(&tileset, ref, ref_rect, ref_rect, rl.WHITE)
  }

  draw_row :: proc(
    dst        : ^rl.Image,
    ref        : rl.Image,
    x, y       : f32,
    offset     : i32,
    new_height : i32)
  {
    img := rl.ImageCopy(ref); defer rl.UnloadImage(img)
    for i in 0..=3
    {
      skw := skew(img, offset, new_height)
      rl.ImageDraw(dst, skw,
        rl.Rectangle{0,0,f32(skw.width),f32(skw.height)},
        rl.Rectangle{x+f32(skw.width*i32(i)),y,f32(skw.width), f32(skw.height)},
        rl.WHITE)
      rl.UnloadImage(skw)
      rl.ImageRotateCW(&img)
    }
  }

  w_1_4 := ref.width  / 4
  w_3_4 := (ref.width / 4) * 3
  h_1_4 := ref.height / 4
  h_3_4 := (ref.height / 4) * 3

  draw_row(&tileset, ref, f32(ref.width), 0, w_1_4, h_1_4)          //x: 0, z: 0
  draw_row(&tileset, ref, f32(ref.width), f32(h_1_4), w_1_4, h_3_4) //x: 0, y:-1
  y := f32(ref.height); draw_row(&tileset, ref, 0, y, w_3_4, h_1_4) //x:-1, z: 0
  y += f32(h_1_4);      draw_row(&tileset, ref, 0, y,-w_1_4, h_1_4) //x:+1, z: 0
  y += f32(h_1_4);      draw_row(&tileset, ref, 0, y, w_3_4, h_3_4) //x:-1, z:-1
  y += f32(h_3_4);      draw_row(&tileset, ref, 0, y,-w_1_4, h_3_4) //x:+1, z:-1

  out_path := (len(os.args) == 3) ? os.args[2] : path.base(os.args[1])
  out_base_cstring := str.clone_to_cstring(out_path)
  ok := rl.ExportImage(tileset, out_base_cstring)
  if !ok
  {
    fmt.printfln("Could not save file at '%s'", out_base_cstring)
  }
  delete_cstring(out_base_cstring)
}