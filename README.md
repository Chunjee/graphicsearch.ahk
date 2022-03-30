# GraphicSearch
A fast, super powerful, and flexible screen searching library for AHK


## What is it?
> Can be thought of as an alternative to native [AHK Imagesearch](https://autohotkey.com/docs/commands/ImageSearch.htm) command. The native command requires saved image files, nearly identical image matching, can be difficult to troubleshoot, and performs in a relatively slow manner. GraphicSearch approaches searching differently. Think of ASCII art; GraphicSearch abstracts the screen's image into representative 0's and _'s. Because this is an abstraction, not a bit-for-bit comparison, it allows for faster matching and easier adjustments of fault tolerance. It can also check for several different graphics without recapturing the screen's image every time. Perhaps most useful, it can return **all** matches unlike AHK ImageSearch which only returns the first match.

<br>

> GraphicSearch would not be possible without [FindText()](https://www.autohotkey.com/boards/viewtopic.php?f=6&t=17834) and it's associated functions by FeiYue. Documentation here will apply in general to those functions.


## Installation
In a terminal or command line:
```bash
npm install graphicsearch.ahk
```

In your code:
```autohotkey
#Include %A_ScriptDir%\node_modules
#Include graphicsearch.ahk\export.ahk

oGraphicSearch := new graphicsearch()
result := oGraphicSearch.search("|<HumanReadableTag>*165$22.03z")
; => [{1: 1215, 2: 407, 3: 22, 4: 10, id: "HumanReadableTag", x: 1226, y: 412}]
```
You may also review or copy the library from [GitHub](https://github.com/Chunjee/graphicsearch.ahk)


## GraphicSearch Queries

GraphicSearch queries are images that have been turned into strings. Unlike Imagesearch, there are only two colors taken into account; a foreground color, and a background color.

Launch the included graphicsearch_gui.ahk to capture and convert screen images into GraphicSearch queries.

See [Generating Queries](/generating-queries) for more guidance.


## Examples

### These examples get progressively more complex

In the first example, we search for an image and click on it.
```autohotkey
oGraphicSearch := new graphicsearch()

resultObj := oGraphicSearch.search("|<Pizza>*165$22.03z")
; check if any graphic was found
if (resultObj) {
	; click on the first graphic in the object
	Click, % resultObj[1].x " " resultObj[1].y
}
```

In the next example, we search for two graphics; if more than four or more found, sort them and mouseover all of them in order
```autohotkey
oGraphicSearch := new graphicsearch()

resultObj := oGraphicSearch.search("|<Pizza>*165$22.03z|<HumanReadableTag>*165$22.03z")
; check if more than one graphic was found
if (resultObj.Count() >= 4) {
	; re-sort the result object
	resultObj2 := oGraphicSearch.resultSort(resultObj)
	; Mouseover each of the graphics found
	for _, object in resultObj2 {
		MouseMove, % object.x, object.y, 50
		Sleep, 1000
	}
}
```

For the last example, search for two images in a specific area. If four or more found, sort them by the closest to the center of the monitor and click the third one.
```autohotkey
oGraphicSearch := new graphicsearch()

resultObj := oGraphicSearch.search("|<Pizza>*165$22.03z|<spaghetti>*125$26.z", [{x2:A_ScreenWidth},{y2:A_ScreenHeight}])
; check if more than one graphic was found
if (resultObj.Count() >= 4) {
	; find the center of the screen by dividing the width and height by 2
	centerX := A_ScreenWidth / 2
	centerY := A_ScreenHeight / 2

	; create a new result object sorted by distance to the center
	resultObj2 := oGraphicSearch.resultSortDistance(resultObj, centerX, centerY)

	; click the third closest to the center
	Click, % resultObj2[3].x " " resultObj2[3].y
}
```
