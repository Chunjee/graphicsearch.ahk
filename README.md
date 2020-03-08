Long-form README: https://chunjee.github.io/graphicsearch.ahk/#/

## GraphicSearch

A fast, super powerful, and flexible screen searching library for AHK


## What is it?

> Can be thought of as an alternative to native [AHK Imagesearch](https://autohotkey.com/docs/commands/ImageSearch.htm) command. The native command requires saved image files, nearly identical image matching, can be difficult to troubleshoot, and performs in a relatively slow manner. GraphicSearch approaches searching differently. Think of ASCII art; GraphicSearch abstracts the screen's image into representative 0's and _'s. Because this is an abstraction, not a bit-for-bit comparison, it allows for faster matching and easier adjustments of fault tolerance. It can also check for several different graphics without recapturing the screen's image every time. Perhaps most useful, it can return **all** matches unlike AHK ImageSearch which only returns the first match.


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
You may also review or copy the library from [./export.ahk on GitHub](https://github.com/Chunjee/graphicsearch.ahk)


# Main Methods

<!-- .search -->
## .search
### .search(graphicsearch_query [, options]) :id=definition {docsify-ignore}
finds GraphicSearch queries on the screen

### Arguments
#### graphicsearch_query (string)
> The GraphicSearch query(s) to search. Must be concatinated with `|` if searching multiple graphics

#### [options:={}] (object)
> The options object

#### [options.x1:=0] (number), [options.y1:=0] (number)
> the search scope's upper left corner coordinates

#### [options.x2:=A_ScreenWidth] (number), [options.y2:=A_ScreenHeight] (number)
> the search scope's lower right corner coordinates

#### [options.err1:=1] (number), [options.err0:=0] (number)
> Fault tolerance of graphic and background (0.1=10%)

#### [options.screenshot:=1] (boolean)
> Wether or not to capture a new screenshot or not. If the value is 0, the last captured screenhhot will be used

#### [options.findall:=1] (boolean)
> Wether or not to find all instances or just one.

#### [options.joinqueries:=1] (boolean)
> Join all GraphicsSearch queries for combination lookup.

#### [options.offsetx:=1] (number), [options.offsety:=0] (number)
> Set the Max offset for combination lookup


### Return
(Array) Return an array of objects containing all lookup results, else `false` if no matches were found.

### Example
```autohotkey
optionsObj := {   x1: 0
                , y1: 0
                , x2: A_ScreenWidth
                , y2: A_ScreenHeight
                , err1: 0
                , err0: 0
                , screenshot: 1
                , findall: 1
                , joinqueries: 1
                , offsetx: 1
                , offsety: 1 }

oGraphicSearch.search("|<tag>*165$22.03z", optionsObj)
oGraphicSearch.search("|<tag>*165$22.03z", {x2: 100, y2: 100})
```
<!-- End of .search -->



<!-- .searchAgain -->
## .searchAgain
### .searchAgain([graphicsearch_query]) :id=definition {docsify-ignore}
performs the last .search with the last arguments supplied

### Example
```autohotkey
oGraphicSearch.search("|<tag>*165$22.03z", {x2: 1028, y2: 720})

oGraphicSearch.searchAgain()
oGraphicSearch.searchAgain("|<HumanReadableTag>*99$26.z7z")
```
<!-- End of .searchAgain -->



<!-- .scan -->
## .scan
### .scan(graphicsearch_query [, y1, x2, y2, err1, err0, screenshot, findall, joinqueries, offsetx, offsety]) :id=definition {docsify-ignore}
finds GraphicSearch queries on the screen

### Arguments
#### graphicsearch_query (string)
> GraphicsSearch queries as strings. Can be multiple queries separated by `|`

#### [x1:=0, y1:=0] (number)
> the search scope's upper left corner coordinates

#### [x2:=0, y2:=0] (number)
> the search scope's lower right corner coordinates

#### [err1:=0, err0:=0] (number)
> A number between 0 and 1 (0.1=10%) for fault tolerance of foreground (err1) and background (err0)

#### [screenshot:=1] (boolean)
> if the value is 1, a new capture of the screen will be used; else it will use the last capture

#### [findall:=1] (boolean)
> if the value is 1, graphicsearch will find all matches. for 0, only return one match

#### [joinqueries:=1] (boolean)
> if the value is 1, Join all GraphicsSearch queries for combination lookup

#### [offsetx:=0, offsety:=0] (number)
> Set the Max offset for combination lookup


### Return
(Array) Return an array of objects containing all lookup results, else `false` if no matches were found.
Any result is an associative array {1:X, 2:Y, 3:W, 4:H, x:X+W//2, y:Y+H//2, id:tag}. All coordinates are relative to Screen, colors are in RGB format, and combination lookup must use uniform color mode


### Example
```autohotkey
oGraphicSearch.scan("|<tag>*165$22.03z", 1, 1, 1028, 720, .1, .1, 1, 1, 1, 0, 0)
; => [{1: 1215, 2: 400, 3:22, 4: 10, id: "tag", x:1226, y:412}]
```
<!-- End of .scan -->



<!-- .scanAgain -->
## .scanAgain
### .scanAgain([graphicsearch_query]) :id=definition {docsify-ignore}
performs the last .search with the last arguments supplied

### Example
```autohotkey
oGraphicSearch.scan("|<tag>*165$22.03z", {x2: 1028, y2: 720})

oGraphicSearch.scanAgain()
oGraphicSearch.scanAgain("|<HumanReadableTag>*99$26.z7z")
```
<!-- End of .scanAgain -->



<!-- .find -->
## .find
### .find(x1, y1, x2, y2, err1, err0, graphicsearch_query [, screenshot, findall, joinqueries, offsetx, offsety]) :id=definition {docsify-ignore}
functionally identicle to `.scan` but uses legacy argument order as a convience for old scripts

### Arguments
#### x1, y1 (number)
> the search scope's upper left corner coordinates

#### x2, y2 (number)
> the search scope's lower right corner coordinates

#### err1, err0 (number)
> A number between 0 and 1 (0.1=10%) for fault tolerance of foreground (err1) and background (err0)

#### graphicsearch_query (string)
> GraphicsSearch queries as strings. Can be multiple queries separated by `|`

#### [screenshot:=1] (boolean)
> if the value is 1, a new capture of the screen will be used; else it will use the last capture

#### [findall:=1] (boolean)
> if the value is 1, graphicsearch will find all matches. for 0, only return one match

#### [joinqueries:=1] (boolean)
> if the value is 1, Join all GraphicsSearch queries for combination lookup

#### [offsetx:=20, offsety:=10] (number)
> Set the Max offset for combination lookup


### Return
(Array) Return an array of objects containing all lookup results, else `false` if no matches were found.
Any result is an associative array {1:X, 2:Y, 3:W, 4:H, x:X+W//2, y:Y+H//2, id:tag}. All coordinates are relative to Screen, colors are in RGB format, and combination lookup must use uniform color mode


### Example
```autohotkey
oGraphicSearch.find(x1, y1, x2, y2, err1, err0, "|<tag>*165$22.03z", 1, 1, 0, 20, 10)
; => [{1: 1215, 2: 400, 3: 22, 4: 10, id: "tag", x: 1226, y: 412}]
```
<!-- end of .find -->



# Sorting Methods

## .resultSort
## .resultSort(resultsObject], ydistance) :id=definition {docsify-ignore}
Sort the results object from left to right and top to bottom, ignoring slight height difference

### Arguments
#### [resultsobject] (Object)
> The GraphicSearch results object to sort
#### [ydistance:=10] (number)
> The ammount of height difference to ingnore in pixels

### Return
(Array) Return an array of objects containing all lookup results

### Example
```autohotkey
resultsObj := [ {1: 2000, 2: 2000, 3: 22, 4: 10, id: "HumanReadableTag", x: 2000, y: 2000}
              , {1: 1215, 2: 400, 3: 22, 4: 10, id: "HumanReadableTag", x: 1226, y: 412}]

oGraphicSearch.resultSort(resultsObj)
; => [{1: 1215, 2: 400, 3: 22, 4: 10, id: "HumanReadableTag", x: 1226, y: 412}, {1: 2000, 2: 2000, 3: 22, 4: 10, id: "HumanReadableTag", x: 2000, y: 2000}]
```



## .resultSortDistance
### .resultSortDistance(resultsObject [, x, y]) :id=definition {docsify-ignore}
Sort the results objects by distance to a given x,y coordinate. A property "distance" is added to all elements in the returned result object

### Arguments
#### resultsObject (Object)
> The GraphicSearch results object

#### [x:=1] (number)
> The x screen coordinate to measure from

#### [y:=1] (number)
> The y screen coordinate to measure from

### Return
(Array) Return an array of objects containing all lookup results

### Example
```autohotkey
resultsObj := [ {1: 2000, 2: 2000, 3: 22, 4: 10, id: "HumanReadableTag", x: 2000, y: 2000}
              , {1: 1215, 2: 400, 3: 22, 4: 10, id: "HumanReadableTag", x: 1226, y: 412}]

oGraphicSearch.resultSortDistance(resultsObj, 2000, 2000)
/* 
[ {1: 2000, 2: 2000, 3: 22, 4: 10, distance: "12.08", id: "HumanReadableTag", x: 2000, y: 2000}
, {1: 1215, 2: 400, 3: 22, 4: 10, distance: "1766.58", id: "HumanReadableTag", x: 1226, y: 412}]
*/
```