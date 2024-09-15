# 
# Search Methods

<!-- .search -->
## .search
`.search(graphicsearch_query [, options])`

finds GraphicSearch queries on the screen

##### Arguments
| Argument               | Type     | Description |
|------------------------|----------|-------------|
| `graphicsearch_query`  | string   | The GraphicSearch query(s) to search. Must be concatenated with `\|` if searching multiple graphics. |
| `options`              | object   | The options object. |
| `options.x1`, `options.y1`     | number   | The search scope's upper left corner coordinates. Default: `0, 0`. |
| `options.x2`, `options.y2`     | number   | The search scope's lower right corner coordinates. Default: `A_ScreenWidth, A_ScreenHeight`. |
| `options.err1`, `options.err0` | number   | A number between 0 and 1 (0.1 = 10%) for fault tolerance of foreground (`err1`) and background (`err0`). Default: `0, 0`. |
| `options.screenshot`    | number  | Whether or not to capture a new screenshot. If `0`, the last captured screenshot will be used. Default: `1`. |
| `options.findall`       | number  | Whether or not to find all instances or just one. Default: `1`. |
| `options.joinqueries`   | number  | Join all GraphicSearch queries for combination lookup. Default: `1`. |
| `options.offsetx`, `options.offsety` | number  | The maximum offset for combination lookup. Default: `0, 0`. |



##### Return
| Type   | Description |
|--------|-------------|
| array  | Returns an array of objects containing all lookup results, or `false` if no matches are found. |


##### Example
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

##### Example
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

##### Arguments
| Argument             | Type     | Description |
|----------------------|----------|-------------|
| `graphicsearch_query`| string   | GraphicsSearch queries as strings. Can be multiple queries separated by `\|`. |
| `x1`, `y1`           | number   | The search scope's upper left corner coordinates. Default: `0, 0`. |
| `x2`, `y2`           | number   | The search scope's lower right corner coordinates. Default: `A_ScreenWidth, A_ScreenHeight`. |
| `err1`, `err0`       | number   | A number between 0 and 1 (0.1 = 10%) for fault tolerance of foreground (`err1`) and background (`err0`). Default: `0, 0`. |
| `screenshot`         | boolean  | If the value is `1`, a new capture of the screen will be used; otherwise, the last capture will be used. Default: `1`. |
| `findall`            | boolean  | If the value is `1`, GraphicSearch will find all matches. For `0`, only one match is returned. Default: `1`. |
| `joinqueries`        | boolean  | If the value is `1`, join all GraphicsSearch queries for combination lookup. Default: `1`. |
| `offsetx`, `offsety` | number   | The maximum offset for combination lookup. Default: `0, 0`. |



#### Return
| Type   | Description                                                                                                                                            |
|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| array  | Returns an array of objects containing all lookup results, or `false` if no matches are found. Each result is an associative array: `{1:X, 2:Y, 3:W, 4:H, x:X+W//2, y:Y+H//2, id:tag}`. Coordinates are relative to the screen, colors are in RGB format, and combination lookup requires uniform color mode. |



#### Example
```autohotkey
oGraphicSearch.scan("|<tag>*165$22.03z", 1, 1, 1028, 720, .1, .1, 1, 1, 1, 0, 0)
; => [{1: 1215, 2: 400, 3:22, 4: 10, id: "tag", x:1226, y:412}]
```
<!-- End of .scan -->



<!-- .scanAgain -->
## .scanAgain
`.scanAgain([graphicsearch_query, y1, x2, y2, err1, err0, screenshot, findall, joinqueries, offsetx, offsety])`

performs the last .search with the last arguments supplied

#### Example
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

#### Arguments
| Argument             | Type     | Description |
|----------------------|----------|-------------|
| `x1`, `y1`           | number   | The search scope's upper left corner coordinates. |
| `x2`, `y2`           | number   | The search scope's lower right corner coordinates. |
| `err1`, `err0`       | number   | A number between 0 and 1 (0.1 = 10%) for fault tolerance of foreground (`err1`) and background (`err0`). |
| `graphicsearch_query`| string   | GraphicsSearch queries as strings. Can be multiple queries separated by `\|`. |
| `screenshot`         | boolean  | If the value is `1`, a new capture of the screen will be used; otherwise, the last capture will be used. Default: `1`. |
| `findall`            | boolean  | If the value is `1`, GraphicSearch will find all matches. For `0`, only one match is returned. Default: `1`. |
| `joinqueries`        | boolean  | If the value is `1`, join all GraphicsSearch queries for combination lookup. Default: `1`. |
| `offsetx`, `offsety` | number   | Set the maximum offset for combination lookup. Default: `20, 10`. |
| `direction`          | number   | Set the direction search is conducted in. Values: <br> 1 (Left to Right / Top to Bottom) <br> 2 (Right to Left / Top to Bottom) <br> 3 (Left to Right / Bottom to Top) <br> 4 (Right to Left / Bottom to Top) <br> 5 (Top to Bottom / Left to Right) <br> 6 (Bottom to Top / Left to Right) <br> 7 (Top to Bottom / Right to Left) <br> 8 (Bottom to Top / Right to Left) <br> 9 (Center to Four Sides). |
| `zoomW`, `zoomH`     | number   | Zoom percentage of image width and height (0.1 = 10%). Default: `1, 1`. |



#### Return
| Type   | Description                                                                                                                                            |
|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| array  | Returns an array of objects containing all lookup results, or `false` if no matches are found. Each result is an associative array: `{1:X, 2:Y, 3:W, 4:H, x:X+W//2, y:Y+H//2, id:tag}`. All coordinates are relative to the screen, colors are in RGB format, and combination lookup must use uniform color mode. |



#### Example
```autohotkey
oGraphicSearch.find(x1, y1, x2, y2, err1, err0, "|<tag>*165$22.03z", 1, 1, 0, 20, 10)
; => [{1: 1215, 2: 400, 3: 22, 4: 10, id: "tag", x: 1226, y: 412}]
```
<!-- end of .find -->



# Sorting Methods

## .resultSort
`.resultSort(resultsObject[, ydistance])`

Sort the results object from left to right and top to bottom, ignoring slight height difference

#### Arguments
| Argument             | Type    | Description |
|----------------------|---------|-------------|
| `resultsobject`      | object  | The GraphicSearch results object to sort. |
| `ydistance`          | number  | The amount of height difference to ignore, in pixels. Default: `10`. |

#### Return
| Type   | Description                                               |
|--------|-----------------------------------------------------------|
| array  | Returns an array of objects containing all lookup results.|


#### Example
```autohotkey
resultsObj := [ {1: 2000, 2: 2000, 3: 22, 4: 10, id: "HumanReadableTag", x: 2000, y: 2000}
              , {1: 1215, 2: 400, 3: 22, 4: 10, id: "HumanReadableTag", x: 1226, y: 412}]

oGraphicSearch.resultSort(resultsObj)
; => [{1: 1215, 2: 400, 3: 22, 4: 10, id: "HumanReadableTag", x: 1226, y: 412}, {1: 2000, 2: 2000, 3: 22, 4: 10, id: "HumanReadableTag", x: 2000, y: 2000}]
```



## .resultSortDistance
`.resultSortDistance(resultsObject [, x, y])`

Sort the results objects by distance to a given x,y coordinate. A property "distance" is added to all elements in the returned result object

#### Arguments

| Argument       | Type    | Description |
|----------------|---------|-------------|
| `resultsObject`| object  | The GraphicSearch results object. |
| `x`            | number  | The x screen coordinate to measure from. Default: `A_ScreenWidth / 2`. |
| `y`            | number  | The y screen coordinate to measure from. Default: `A_ScreenHeight / 2`. |

#### Return
| Type   | Description |
|--------|-------------|
| array  | Returns an array of objects containing all lookup results. |


#### Example
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

#### Arguments
| Argument       | Type    | Description |
|----------------|---------|-------------|
| `resultsObject`| object  | The GraphicSearch results object. |
| `options`      | object  | The options object. Default: `{showlabels: true, timeout: 4000}`. |
| `options.showlabels` | number  | Whether or not to display labels. Default: `1` |
| `options.timeout`    | number  | The ammount of time in milliseconds to hide the search results on screen. Default: `4000` |


#### Returns
| Type   | Description |
|--------|-------------|
| none   | No value is returned. |


#### Example
```autohotkey
resultsObj := [ {1: 2000, 2: 2000, 3: 22, 4: 10, id: "HumanReadableTag", x: 2000, y: 2000}
              , {1: 1215, 2: 400, 3: 22, 4: 10, id: "HumanReadableTag", x: 1226, y: 412}]

oGraphicSearch.showMatches(resultsObj, {showlabels: false, timeout: 60000}}]
```

# Misc

## .ocr
> .ocr(resultObj, offsetX := 20, offsetY := 20, overlapW := 0)

#### Arguments
| Parameter | Type   | Default Value | Description |
|-----------|--------|---------------|-------------|
| resultObj | Object | N/A           | The GraphicSearch result object containing the search results to process.    |
| offsetX   | number | 20            | The horizontal offset in pixels between adjacent OCR results.                |
| offsetY   | number | 20            | The vertical offset in pixels between adjacent OCR results.                  |
| overlapW  | number | 0             | The overlap width in pixels. Sets the allowed horizontal overlap between OCR blocks. |

#### Returns
| Type   | Description |
|--------|-------------|
| Object | Returns an object containing the combined OCR text and bounding box dimensions of the text. The object includes: |
|        | `text`: The concatenated OCR text.                                        |
|        | `x`: The x-coordinate of the bounding box's upper-left corner.            |
|        | `y`: The y-coordinate of the bounding box's upper-left corner.            |
|        | `w`: The width of the bounding box.                                       |
|        | `h`: The height of the bounding box.                                      |


#### Example
```autohotkey
resultObj := [{1:300, 2:200, 3:50, 4:30, id:"Hello"}
	, {1:360, 2:200, 3:60, 4:30, id:"World"}
	, {1:900, 2:250, 3:80, 4:40, id:"OCR"}]

; Extract OCR text with custom offsets
ocrResults := oGraphicSearch.ocr(resultObj, 30, 20, 10)

; Output the OCR text and bounding box info
msgBox % "OCR Text: " ocrResults.text "`n" 
	. "Bounding Box - X: " ocrResults.x " Y: " ocrResults.y 
	. " Width: " ocrResults.w " Height: " ocrResults.h
```
