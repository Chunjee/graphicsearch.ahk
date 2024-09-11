# graphicsearch.ahk

A fast, super powerful, and flexible screen searching library for AHK


## Alternative to Native AHK Imagesearch

The native [AHK Imagesearch](https://www.autohotkey.com/docs/v1/lib/ImageSearch.htm) command has several limitations:
- Requires image files
- Needs nearly identical image matching
- Performs slowly
- Difficult to troubleshoot
- Doesn't fit in flow statements
- Uses OutputVars

graphicsearch.ahk provides a different approach to image searching. Instead of performing a bit-for-bit comparison, it abstracts the screen's image into representative 0's and _'s, similar to ASCII art. 

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
* [.scan](/en/docs?id=scan)
* [.scanAgain](/en/docs?id=scanagain)
* [.find](/en/docs?id=find)

## Sort Methods
* [.resultSort](/en/docs?id=resultSort)
* [.resultSortDistance](/en/docs?id=resultSortDistance)
