package dhumanyz

import "core:fmt"
import "core:time"

STR :: "DEHUMANIZE YOURSELF AND FACE TO BLOODSHED"
SLP :: time.Millisecond * 100
ROJ :: "\x1b[31m"

main :: proc()
{
  fmt.print(ROJ)
  for true
  {
    fmt.print("> ")
    for c in STR
    {
      flush := (c == ' ') ? false : true
      fmt.print(c, flush = flush)
      if flush
      {
        time.sleep(SLP)
      }
    }
    fmt.println()
  }
}
