package game

import "core:log"

import rl "vendor:raylib"

/*
   Contains all pre-processed variations of a single tile, needed for projected
   rendering.

   Originally, the idea was to not have this many textures for a single tile.
   Raylib's 2D texture drawing functions, however, did not do what was needed to
   convert a plain texture into the shape expected. So, H, V and WALL_V are,
   regretably necessary. Here's to hoping this does not affect performance much.
*/
Tile :: struct {

  // txr is the original texture; used by angles which don't require skewing
  txr: rl.Texture,

  top_si: rl.Texture,
  top_dx: rl.Texture,

  // TODO: top array should be replaced by top_si & top_dx
  top: [len(Axis)]rl.Texture,
  // TODO: wall_v should be replaced by txr

  wall_v: rl.Texture,
  wall_si: rl.Texture,
  wall_dx: rl.Texture
}

/*
   Currently, loads an image and generates all variations of it as textures
   TODO: rather than load an image, the image should be passed onto it as a
   parameter.
*/
TILEinit :: proc(path: cstring) -> ^Tile
{
  when ODIN_DEBUG {
    log.debug("=== START OF TILEINIT PROC ===")
  }

  this := new(Tile)
  if nil == this {
    log.error("TILE POINTER IS NULL AFTER ALLOCATING")
  }
  image := rl.LoadImage(path)
  if false == rl.IsImageValid(image) {
    log.errorf("COULD NOT LOAD IMAGE WITH PATH %v", path)
    TILEfree(this)
    return nil
  }
  base_comp := get_diagonal_base_component()

  //TODO: put this in a decent place
  this.txr = rl.LoadTextureFromImage(image)

  // TOP TEXTURES ============================================================

  when ODIN_DEBUG {
    log.debug("GENERATING TOP TEXTURES")
  }
  // initial step for further manipulation
  // v and h only need this step
  img_resize_dx: rl.Image
  img_resize_si: rl.Image
  // TODO: replace img_resize array with img_resize_dx & img_resize_si
  img_resize: [len(Axis)]rl.Image
  for &img in img_resize {
    img = rl.ImageCopy(image)
  }
  // h & dx are rotated 90 degrees before resizing
  rl.ImageRotateCW(&img_resize_dx)
  // TODO: eliminate Axis.H and replace Axis.DX by img_resize_dx
  rl.ImageRotateCW(&img_resize[Axis.H])
  rl.ImageRotateCW(&img_resize[Axis.DX])
  // v & h
  //TODO: get rid of these
  rl.ImageResizeNN(&img_resize[Axis.V], conf.tile_size, conf.tile_size / 2)
  rl.ImageResizeNN(&img_resize[Axis.H], conf.tile_size, conf.tile_size / 2)
  // si & dx
  rl.ImageResizeNN(&img_resize_si, base_comp * 2, base_comp / 2)
  rl.ImageResizeNN(&img_resize_dx, base_comp * 2, base_comp / 2)
  //TODO: replace these by img_resize_dx & img_resize_si
  rl.ImageResizeNN(&img_resize[Axis.SI], base_comp * 2, base_comp / 2)
  rl.ImageResizeNN(&img_resize[Axis.DX], base_comp * 2, base_comp / 2)

  //TODO: get rid of v and h (this will be taken care of at render-time
  // v and h are ready; just load them
  // v
  this.top[Axis.V] = rl.LoadTextureFromImage(img_resize[Axis.V])
  rl.UnloadImage(img_resize[Axis.V])

  // h
  this.top[Axis.H] = rl.LoadTextureFromImage(img_resize[Axis.H])
  rl.UnloadImage(img_resize[Axis.H])

  /*
     by 'skew', I mean turning this:
      ___
     |   |
     |___|

     into this:
     |\
     | \
     \ |
      \|
  */
  // a blank canvas is needed as the 'destination'
  img_skew_si := rl.GenImageColor(
    img_resize[Axis.SI].width,
    img_resize[Axis.SI].height * 2 - 1,
    rl.BLANK)
  img_skew_dx := rl.ImageCopy(img_skew_si)
  {
    x: f32 = 0
    y: f32 = 0
    // si.width and dx.width are the same
    for x < f32(img_resize[Axis.SI].width) {
      rl.ImageDraw(
        &img_skew_si,
        img_resize[Axis.SI],
        { x, 0, 4, f32(img_resize[Axis.SI].height) },
        { x, y, 4, f32(img_resize[Axis.SI].height) },
        rl.WHITE)
      rl.ImageDraw(
        &img_skew_dx,
        img_resize[Axis.DX],
        { x, 0, 4, f32(img_resize[Axis.DX].height) },
        { x, y, 4, f32(img_resize[Axis.DX].height) },
        rl.WHITE)
      x += 4
      y += 1
    }
  }
  // not needed anymore
  rl.UnloadImage(img_resize[Axis.SI])
  rl.UnloadImage(img_resize[Axis.DX])

  /*
     'diamond' is then turning this:
     |\
     | \
     \ |
      \|

     into this:
      /\
     /  \
     \  /
      \/
     (but squished, like an isometric surface)
  */
  // yet another blank canvas is needed
  img_diamond_si := rl.GenImageColor(
    img_skew_si.width,
    img_skew_si.height,
    rl.BLANK)
  img_diamond_dx := rl.ImageCopy(img_diamond_si)
  {
    // middle - 2 (so that we get a nice, centered top)
    x := f32((img_skew_si.width / 2) - 2)
    y: f32 = 0
    w: f32 = 4
    for w <= f32(img_skew_si.width) {
      // si and dx's width/height are the same
      src_bottom_width := f32(img_skew_si.width) - w
      src_bottom_height := f32(img_skew_si.height) - y
      dst_bottom_y := src_bottom_height
      // si
      rl.ImageDraw(
        &img_diamond_si,
        img_skew_si,
        { 0, y, w, 1 },
        { x, y, w, 1} ,
        rl.WHITE)
      rl.ImageDraw(
        &img_diamond_si,
        img_skew_si,
        { src_bottom_width, src_bottom_height, w,1},
        { x - 2, dst_bottom_y, w, 1 },
        rl.WHITE)
      // dx
      rl.ImageDraw(
        &img_diamond_dx,
        img_skew_dx,
        { 0, y, w, 1 },
        { x, y, w, 1} ,
        rl.WHITE)
      rl.ImageDraw(
        &img_diamond_dx,
        img_skew_dx,
        { src_bottom_width, src_bottom_height, w,1},
        { x - 2, dst_bottom_y, w, 1 },
        rl.WHITE)
      // progress in a pyramid-like fashion
      x -= 2
      y += 1
      w += 4
    }
  }
  // not needed anymore
  rl.UnloadImage(img_skew_si)
  rl.UnloadImage(img_skew_dx)

  // finally, these are ready, so do the same as with v and h earlier
  this.top[Axis.SI] = rl.LoadTextureFromImage(img_diamond_si)
  this.top[Axis.DX] = rl.LoadTextureFromImage(img_diamond_dx)
  rl.UnloadImage(img_diamond_si)
  rl.UnloadImage(img_diamond_dx)


  // WALL TEXTURES ===========================================================
  when ODIN_DEBUG {
    log.debug("GENERATING WALL TEXTURES")
  }

  img_src := rl.ImageCopy(image)
  img_wall := rl.ImageCopy(image)
  rl.UnloadImage(image)
  // all v needs is be resized once
  rl.ImageResizeNN(&img_wall, this.top[Axis.V].width, base_comp)
  // so, after this, it's already good to go
  this.wall_v = rl.LoadTextureFromImage(img_wall)
  rl.UnloadImage(img_wall)

  // ... but si & dx need an extra step
  rl.ImageResizeNN(&img_src, base_comp, base_comp)
  // and for that, a blank canvas needs to be created
  img_si := rl.GenImageColor(
    img_src.width,
    ((img_src.height / 2) * 3) - 1,
    rl.BLANK)
  img_dx := rl.ImageCopy(img_si)
  {
    x: f32 = 0
    y: f32 = 0
    for x < f32(img_src.width) {
      rl.ImageDraw(
        &img_si, img_src,
        { x, 0, 2, f32(img_src.height) },
        { x, y, 2, f32(img_src.height) },
        rl.WHITE)
      rl.ImageDraw(
        &img_dx, img_src,
        { f32(img_src.width) - x - 2, 0, 2, f32(img_src.height) },
        { f32(img_dx.width) - x - 2, y, 2, f32(img_src.height) },
        rl.WHITE)
      x += 2
      y += 1
    }
  }
  rl.UnloadImage(img_src)
  // now they're ready, so load their textures
  this.wall_si = rl.LoadTextureFromImage(img_si)
  this.wall_dx = rl.LoadTextureFromImage(img_dx)
  rl.UnloadImage(img_si)
  rl.UnloadImage(img_dx)

  return this
}

TILEfree:: proc(this: ^Tile)
{
  if nil == this {
    when ODIN_DEBUG {
      log.debug("TILE IS NULL, NOT FREEING")
    }
    return
  }
  when ODIN_DEBUG {
    log.debug("UNLOADING TEXTURES AND FREEING TILE")
  }
  rl.UnloadTexture(this.top[Axis.V])
  rl.UnloadTexture(this.top[Axis.H])
  rl.UnloadTexture(this.top[Axis.SI])
  rl.UnloadTexture(this.top[Axis.DX])
  rl.UnloadTexture(this.wall_v)
  rl.UnloadTexture(this.wall_si)
  rl.UnloadTexture(this.wall_dx)
  free(this)
}
