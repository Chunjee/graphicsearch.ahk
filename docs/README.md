# Getting Started

See [quickstart](/quickstart) for installation, inclusion, and initializiation.


## What is it?

Can be thought of as an alternative to native [AHK Imagesearch](https://autohotkey.com/docs/commands/ImageSearch.htm) function. The native function requires saved graphic files, identical image matching, is hard to troubleshoot and performs in a relatively slow manner. AHK Imagesearch can commonly fail for many different reasons. GraphicSearch approaches searching differently. Think 1980's ASCII art. This function abstracts the screen's image into representative 0's and _'s. Because this is an abstraction, not and bit for bit comparison, it allows for faster matching and easier adjustments of fault tolerance. It can also check for several different graphics without recapturing the screen's image every time.


# Methods

## .search

#### Arguments

X1, Y1                  the search scope's upper left corner coordinates

X2, Y2                  the search scope's lower right corner coordinates

err1, err0              Fault tolerance percentage of text and background (0.1=10%)

Text                    can be a lot of text parsed into images, separated by "|"

ScreenShot              if the value is 0, the last ScreenShot will be used

FindAll                 if the value is 0, Just find one result and return

JoinText                if the value is 1, Join all Text for combination lookup

offsetX, offsetY        Set the Max text offset for combination lookup


#### Return

The method returns a second-order array containing all lookup results, Any result is an associative array {1:X, 2:Y, 3:W, 4:H, x:X+W//2, y:Y+H//2, id:Comment}, if no image is found, the function returns 0.
All coordinates are relative to Screen, colors are in RGB format, and combination lookup must use uniform color mode
