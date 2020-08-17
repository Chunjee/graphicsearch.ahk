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
> The search scope's upper left corner coordinates

#### [options.x2:=A_ScreenWidth] (number), [options.y2:=A_ScreenHeight] (number)
> The search scope's lower right corner coordinates

#### [options.err1:=0] (number), [options.err0:=0] (number)
> A number between 0 and 1 (0.1=10%) for fault tolerance of foreground (err1) and background (err0)

#### [options.screenshot:=1] (boolean)
> Whether or not to capture a new screenshot. When the value is 0, the last captured screenshot will be used

#### [options.findall:=1] (boolean)
> Whether or not to find all instances or just one. The default is to find all

#### [options.joinqueries:=0] (boolean)
> Whether or not to search each query in succession. Queries must be in close proximity (characters in a string)

#### [options.offsetx:=1] (number), [options.offsety:=0] (number)
> The max offset for joinqueries search


### Return
(Array) Returns an array of objects containing all found graphics, else `false` if no matches were found.
Any result is an associative array `{1:X, 2:Y, 3:W, 4:H, x:X+W\2, y:Y+H\2, id:tag}`. All coordinates are relative to Screen, colors are in RGB format, and combination lookup must use uniform color mode


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
                , joinqueries: 0
                , offsetx: 1
                , offsety: 1 }

oGraphicSearch.search("|<tag>*165$22.03z", optionsObj)
oGraphicSearch.search("|<tag>*165$22.03z", {x2: 100, y2: 100})
```
<!-- End of .search -->



<!-- .searchAgain -->
## .searchAgain
### .searchAgain([graphicsearch_query, options]) :id=definition {docsify-ignore}
performs the last `.search` with the last arguments supplied


### Return
(Array) Returns an array of objects containing all found graphics, else `false` if no matches were found.
Any result is an associative array `{1:X, 2:Y, 3:W, 4:H, x:X+W\2, y:Y+H\2, id:tag}`. All coordinates are relative to Screen, colors are in RGB format, and combination lookup must use uniform color mode


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
> The search scope's upper left corner coordinates

#### [x2:=0, y2:=0] (number)
> The search scope's lower right corner coordinates

#### [err1:=0, err0:=0] (number)
> A number between 0 and 1 (0.1=10%) for fault tolerance of foreground (err1) and background (err0)

#### [screenshot:=1] (boolean)
> Whether or not to capture a new screenshot. When the value is 0, the last captured screenshot will be used

#### [findall:=1] (boolean)
> Whether or not to find all instances or just one. The default is to find all

#### [joinqueries:=0] (boolean)
> Whether or not to search each query in succession. Queries must be in close proximity (characters in a string)

#### [offsetx:=0, offsety:=0] (number)
> The max offset for joinqueries search


### Return
(Array) Returns an array of objects containing all found graphics, else `false` if no matches were found.
Any result is an associative array `{1:X, 2:Y, 3:W, 4:H, x:X+W\2, y:Y+H\2, id:tag}`. All coordinates are relative to Screen, colors are in RGB format, and combination lookup must use uniform color mode


### Example
```autohotkey
oGraphicSearch.scan("|<tag>*165$22.03z", 1, 1, 1028, 720, .1, .1, 1, 1, 1, 0, 0)
; => [{1: 1215, 2: 400, 3:22, 4: 10, id: "tag", x:1226, y:412}]
```
<!-- End of .scan -->



<!-- .scanAgain -->
## .scanAgain
### .scanAgain([graphicsearch_query, y1, x2, y2, err1, err0, screenshot, findall, joinqueries, offsetx, offsety]) :id=definition {docsify-ignore}
performs the last .search with the last arguments supplied


### Return
(Array) Returns an array of objects containing all found graphics, else `false` if no matches were found.
Any result is an associative array `{1:X, 2:Y, 3:W, 4:H, x:X+W\2, y:Y+H\2, id:tag}`. All coordinates are relative to Screen, colors are in RGB format, and combination lookup must use uniform color mode


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
> The search scope's upper left corner coordinates

#### x2, y2 (number)
> The search scope's lower right corner coordinates

#### err1, err0 (number)
> A number between 0 and 1 (0.1=10%) for fault tolerance of foreground (err1) and background (err0)

#### graphicsearch_query (string)
> GraphicsSearch queries as strings. Can be multiple queries separated by `|`

#### [screenshot:=1] (boolean)
> Whether or not to capture a new screenshot. When the value is 0, the last captured screenshot will be used

#### [findall:=1] (boolean)
> Whether or not to find all instances or just one. The default is to find all

#### [joinqueries:=0] (boolean)
> Whether or not to search each query in succession. Queries must be in close proximity (characters in a string)

#### [offsetx:=20, offsety:=10] (number)
> The max offset for joinqueries search


### Return
(Array) Returns an array of objects containing all found graphics, else `false` if no matches were found.
Any result is an associative array `{1:X, 2:Y, 3:W, 4:H, x:X+W\2, y:Y+H\2, id:tag}`. All coordinates are relative to Screen, colors are in RGB format, and combination lookup must use uniform color mode


### Example
```autohotkey
oGraphicSearch.find(x1, y1, x2, y2, err1, err0, "|<tag>*165$22.03z", 1, 1, 0, 20, 10)
; => [{1: 1215, 2: 400, 3: 22, 4: 10, id: "tag", x: 1226, y: 412}]
```
<!-- end of .find -->



# Sorting Methods
The searching methods return a "ResultsObject" array that contains one or more instances of found graphics. The methods below deal with reorganizing the order of that array and do not perform any new screen capture.

## .resultSort
## .resultSort(resultsObject], ydistance) :id=definition {docsify-ignore}
Sort the results object from left to right and top to bottom, ignoring slight height difference

### Arguments
#### [resultsobject] (Object)
> The GraphicSearch results object to sort
#### [ydistance:=10] (number)
> The ammount of height difference to ingnore in pixels

### Return
(Array) Returns a new array of lookup objects sorted in order

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
(Array) Returns a new array of lookup objects sorted in order

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