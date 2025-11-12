# The processing pipeline in ART

  Module                               |  Color space          |   Notes
  ------------------------------------ | --------------------- | ---------------------------------------
  Flat field                           | RAW                   |
  Dark frame                           | RAW                   |
  RAW black points                     | RAW                   |
  Vignetting correction                | RAW                   |
  Hot/dead pixel filter                | RAW                   |
  Green equlibration/line noise filter | RAW                   |
  RAW CA correction                    | RAW                   |
  Film negative                        | RAW                   |
  Demosaic                             | RAW                   |
  Highlight recovery                   | Camera                |
  White balance/White point            | Camera                |
  Spot removal                         | Camera                |
  Input color profile                  | Camera                | from Camera to Linear RGB working space
  Denoise                              | Linear RGB            | Gamma controlled by the user
  Dehaze                               | Linear RGB            |
  Dynamic range compression            | Linear RGB            |
  Lens/geometry corrections            | Linear RGB            |
  Channel mixer                        | Linear RGB            |
  Exposure compensation                | Linear RGB            |
  HSL equalizer                        | Linear RGB            |
  Tone equalizer                       | Linear RGB            | Short description [here](https://discuss.pixls.us/t/ive-finally-tried-art-and-it-is-amazing/20482/14)
  DCP profile look modifiers (baseline exposure, DCP tone curve, look table) when "Early mode" is selected                      | Linear RGB            |
  Sharpening                           | Linear RGB            |
  Impulse denoise                      | Linear RGB            |
  Defringe                             | Linear RGB            |
  Color correction                     | Linear RGB            |
  Smoothing                            | Linear RGB            |
  Gradient/vignette filter             | Linear RGB            |
  Texture boost                        | Linear RGB            | Short description [here](https://discuss.pixls.us/t/ive-finally-tried-art-and-it-is-amazing/20482/14)
  Log encoding                         | Linear RGB            | Short description [here](https://discuss.pixls.us/t/ive-finally-tried-art-and-it-is-amazing/20482/14)
  Saturation/vibrance                  | Linear RGB            |
  Film simulation                      | RGB                   | Linear unbounded for [CLF LUTs and CTL scripts](Luts), Bounded with gamma depending on the LUT (typically 2.2) for HaldCLUTs
  Tone curve                           | Linear RGB            | Also DCP profile look modifiers (baseline exposure, DCP tone curve, look table) when "Later mode" is selected
  RGB curves                           | Linear RGB bounded    |
  LAB adjustments                      | LAB                   |
  Soft light                           | RGB gamma 2.2 bounded |
  Local contrast                       | LAB                   |
  Black and white                      | RGB gamma 2.2 bounded | Gamma 2.2 used for tint, otherwise user controllable
  Film grain                           | Linear RGB            |
  Crop                                 |                       |
  Resize                               |                       |
  Post-resize sharpening               | Linear RGB            |
  Output color profile                 | Linear RGB            | working to output RGB
