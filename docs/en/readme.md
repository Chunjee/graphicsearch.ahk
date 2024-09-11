# graphicsearch.ahk

A lightning-fast, highly versatile, and powerful screen searching library for AutoHotkey


## Alternative to Native AHK Imagesearch

> GraphicSearch offers a powerful alternative to the native AHK Imagesearch command. While the native command requires saved image files, nearly exact image matching, and can be slow and difficult to troubleshoot, GraphicSearch takes a different approach. It abstracts the screen into a simplified representation, similar to ASCII art, using characters like 0s and _s. This abstraction enables faster matching, easier adjustments to fault tolerance, and more flexibility. Unlike AHK ImageSearch, which returns only the first match, GraphicSearch can return all matches, making it more efficient for complex searches. Additionally, it avoids the need to recapture the screen image for each search, improving performance when checking multiple graphics.

### Advantages:
- **Faster Matching**: Due to abstraction rather than direct comparison.
- **Adjustable Fault Tolerance**: Easier to tweak for your needs.
- **Multiple Graphic Checks**: Can check for several different graphics without recapturing the screen's image every time.
- **Comprehensive Results**: Returns all matches, unlike AHK Imagesearch which only returns the first match.


## Installation

In a terminal or command line:
```bash
npm install graphicsearch.ahk
```
In your code only export.ahk needs to be included:
```autohotkey
#Include %A_ScriptDir%\node_modules
#Include graphicsearch.ahk\export.ahk

oGraphicSearch := new graphicsearch()
result := oGraphicSearch.search("|<HumanReadableTag>*165$22.03z")
; => [{1: 1215, 2: 407, 3: 22, 4: 10, id: "HumanReadableTag", x: 1226, y: 412}]
```
You may also review or copy the library from [./export.ahk on GitHub](https://github.com/Chunjee/graphicsearch.ahk) #Incude as you would normally when manually downloading.


## Search Methods
* [.search](/en/docs?id=concat)
* [.searchAgain](/en/docs?id=searchagain)

## Sort Methods
* [.resultSort](/en/docs?id=resultSort)
* [.resultSortDistance](/en/docs?id=resultSortDistance)

## Display Methods
* [.showMatches](/en/docs?id=resultSort)
