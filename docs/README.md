## GraphicSearch

A fast, super powerful, and flexible alternative to AutoHotkey's ImageSearch

## What is it?

> Can be thought of as an alternative to native [AHK Imagesearch](https://autohotkey.com/docs/commands/ImageSearch.htm) function. The native function requires saved graphic files, identical image matching, is hard to troubleshoot, and performs in a relatively slow manner. GraphicSearch approaches searching differently. Think of ASCII art. GraphicSearch abstracts the screen's image into representative 0's and _'s. Because this is an abstraction, not and bit for bit comparison, it allows for faster matching and easier adjustments of fault tolerance. It can also check for several different graphics without recapturing the screen's image every time. In addition, it finds **all** instances of the graphic unlike AHK ImageSearch which only returns the first match. 

See [quickstart](/quickstart) for installation, inclusion, and initializiation.


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

The method returns an array of objects containing all lookup results, Any result is an associative array {1:X, 2:Y, 3:W, 4:H, x:X+W//2, y:Y+H//2, id:Comment}, 
If no graphic is found, the method returns an empty array.
All coordinates are relative to Screen, colors are in RGB format, and combination lookup must use uniform color mode
