# 
# Search Methods

<!-- .search -->
## .search
`.search(graphicsearch_query [, options])`

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
`.searchAgain([graphicsearch_query])`

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
`.scan(graphicsearch_query [, y1, x2, y2, err1, err0, screenshot, findall, joinqueries, offsetx, offsety])`

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
`.scanAgain([graphicsearch_query, y1, x2, y2, err1, err0, screenshot, findall, joinqueries, offsetx, offsety])`

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
`.find(x1, y1, x2, y2, err1, err0, graphicsearch_query [, screenshot, findall, joinqueries, offsetx, offsety])`

Identicle to `.scan` but uses legacy argument order as a convience for old scripts

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

#### [direction:=1] (number)
> Set the direction search is conducted in

> 1( Left to Right / Top to Bottom )  
2( Right to Left / Top to Bottom )  
3( Left to Right / Bottom to Top )  
4( Right to Left / Bottom to Top )  
5( Top to Bottom / Left to Right )  
6( Bottom to Top / Left to Right )  
7( Top to Bottom / Right to Left )  
8( Bottom to Top / Right to Left )  
9( Center to Four Sides )

#### [zoomW:=1, zoomH:=1] (number)
> Zoom percentage of image width and height (0.1=10%)


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
`.resultSort(resultsObject[, ydistance])`

Sort the results object from left to right and top to bottom, ignoring slight height difference

### Arguments
#### [resultsobject] (Object)
> The GraphicSearch results object to sort

#### [ydistance:=10] (number)
> The ammount of height difference to ignore in pixels

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
`.resultSortDistance(resultsObject [, x, y])`

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

# Display Methods

## .showMatches
`.showMatches(resultsObject [, optionsObject])`

Visually display the locations of search results on the screen. It takes in a `resultsObject`, and optionally an `optionsObject` to customize how the results are displayed.

### Arguments
#### resultsObject (Object)
> The GraphicSearch results object

#### [options := {showlabels: true, timeout: 4000}] (Object)
> The options object results object

### Returns
No values are returned

### Example
```autohotkey
resultsObj := [ {1: 2000, 2: 2000, 3: 22, 4: 10, id: "HumanReadableTag", x: 2000, y: 2000}
              , {1: 1215, 2: 400, 3: 22, 4: 10, id: "HumanReadableTag", x: 1226, y: 412}]

oGraphicSearch.showMatches(resultsObj, {showlabels: false, timeout: 60000}}]
```
