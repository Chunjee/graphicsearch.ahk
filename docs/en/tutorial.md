Assume the following is a snapshot of game and we want to use GraphicSearch to translate to parse where things are on screen.

![Main stage tutorial image](https://chunjee.github.io/graphicsearch.ahk/docs/assets/tutorial-1.png)


<br>

We'll use the followng capture regions. It's very important to capture the smallest region possible, while also being unique to the graphic so it doesn't match other similar things. For distance calculations it might be useful to search for the center of each graphic. Since GraphicSearch really cares about differences in color, it is highly benifitial to grab an area that is not all the same color.

![GraphicSearch capture](https://chunjee.github.io/graphicsearch.ahk/docs/assets/tutorial-2.png)

These GraphicSearch queries should match many, but probably not all 16:9 ratio screens

```autohotkey
spaghettiGraphic :=	"|<Spaghetti>*164$30.zzzzwznzzzznzzzzzzzzzzzzzzzwzkzzwzk3z3A03z3A0kkzA3kkzA3A03AAA03AAnkAnAnkAnAA3kn0U"
pizzaGraphic :=		"|<Pizza>#150$32.3wAnkAzAnw3DnAz0DknwDnwAz3w3zzkz0zzwDkzk0z0Dw0Dk033k08"
drinkGraphic :=		"|<Drink>#150$18.0070070Tz0Tz1s71s7Ts1Ts1VzVVzV01V01V07V07V0M60M60MM0MMU"
```


<br>

## Performing Searches

GraphicSearch's most verbose method is `.find`. It requires **seven** arguments and has **five** more optional arguments.
To simplify use, `.search` only takes two arguments, a GraphicSearch Query and an optional object with all the same options as properties. This is the preffered way to use the package.

The following are all functionally identical, They search a region of the screen (0,0 -> 600,600) and only return one found match (the first match)


```autohotkey
oGraphicSearch := new graphicsearch()
oGraphicSearch.search(pizzaGraphic, {x2: 600, y2: 600, findall: false})
oGraphicSearch.scan(pizzaGraphic, 0, 0, 600, 600, false)
oGraphicSearch.find(0, 0, 600, 600, 0, 0, pizzaGraphic, 1, false)
```

See [Documentation](/en/documentation) for more details on all methods.


<br>

## ResultsObject

All searching methods return a ResultsObject, which is an array of all found graphics. If only one was found, it is still contained in an array.

Each match is an object with the following properties:
- 1: the X position on screen
- 2: the Y position on screen
- 3: the width of the graphic
- 4: the height of the graphic
- x: the center of the graphic's X axis. The width of the graphic divided by 2 plus the X position on screen
- y: the center of the graphic's Y axis. The height of the graphic divided by 2 plus the Y position on screen
- id: a string of the corrisponding GraphicSearch queries or human readable tag if one was present (the text between `<` and `>`), else `""`

An example ResultsObject might look like this:
```autohotkey
[{1:113, 2:50, 3:10, 4:10, x:118, y:55, id:"Pizza"}]
```
Or this if more than one was found:
```autohotkey
[{1:113, 2:50, 3:10, 4:10, x:118, y:55, id:"Pizza"}, {1:233, 2:440, 3:10, 4:10, x:238, y:445, id:"Pizza"}]
```


<br>

## Example Scripts

If we want to search for all the pizzas we can perform the following to msgbox the x,y location of each match

```autohotkey
oGraphicSearch := new graphicsearch()
resultObj := oGraphicSearch.search(pizzaGraphic)

if (resultObj) {
	loop, % resultObj.Count() {
		msgbox, % "x: " resultObj[A_Index].x ", y: " resultObj[A_Index].y
	}
}
```

<br>

If we wanted to search for two (or more) items in one search that can be accomplished by joining both queries into one long string and performing the same search

```autohotkey
oGraphicSearch := new graphicsearch()
allQueries := pizzaGraphic drinkGraphic
resultObj := oGraphicSearch.search(allQueries)

if (resultObj) {
	loop, % resultObj.Count() {
		msgbox, % "x: " resultObj[A_Index].x ", y: " resultObj[A_Index].y
	}
}
```


<br>

There may be things we want to search for repeatedly but don't want to juggle arguments constantly, you can create instances of GraphicSearch that are responsible for finding individual graphics.

`.searchAgain` is a method that performs the same search with the arguments supplied the last time `.search` was used. Lets create a pizza GraphicSearch and a drink GraphicSearch. Our script will loop and search till they are both found simultaneously.

```autohotkey
oPizzaSearch := new graphicsearch()
oDrinkSearch := new graphicsearch()
oPizzaSearch.search(pizzaGraphic)
oDrinkSearch.search(oDrinkSearch)

foundBothGate := false
while (foundBothGate != true) {
	resultPizzaObj := oPizzaSearch.searchAgain()
	resultDrinkObj := oDrinkSearch.searchAgain()
	if (resultPizzaObj && resultDrinkObj) {
		msgbox, % "Found both Pizza and Drink! Let's Eat!"
		foundBothGate := true
	}
}
```

Since we're not doing anything with the ResultsObject we can simplify the code even further. GraphicSearch can fit comfortably in logic code because it doesn't require many arguments

```autohotkey
foundBothGate := false
while (foundBothGate != true) {
	if (oPizzaSearch.searchAgain() && oDrinkSearch.searchAgain()) {
		msgbox, % "Found both Pizza and Drink! Let's Eat!"
		foundBothGate := true
	}
}
```

<br>

Let's imagine we want to click the pizza closet to the center, `.resultSortDistance` will sort a ResultsObject by proximity to an x,y coord. A real smart app might even use GraphicSearch to find the center <img src = 'assets/emojii/smart.png'>

For example simplicity we'll say we already know the center is at 300,300

> [!Note]
> Graphicsearch doesn't mutate arguments it's given, notice that the sorted and unsorted ResultObjects are different variables in this example.

```autohotkey
oGraphicSearch := new graphicsearch()

resultObj := oGraphicSearch.search(pizzaGraphic)
if (resultObj) {
	sortedResults := oGraphicSearch.resultSortDistance(resultObj, 300, 300)
	loop, % sortedResults.Count() {
		msgbox, % "x: " sortedResults[A_Index].x ", y: " sortedResults[A_Index].y
	}
	Click, % sortedResults[1].x " " sortedResults[1].y
}
```

`.resultSortDistance` returns a ResultsObject with an additional a property "distance" for each match. That may be useful for calculating how close things are to each other. Let's msgbox on any pizza's found outside the circle. We'll perform the check `if (sortedResults[A_Index].distance > 350)` which will return true for anything greater than the radius of the circle (about 350 pixels)

```autohotkey
oGraphicSearch := new graphicsearch()

resultObj := oGraphicSearch.search(pizzaGraphic)
if (resultObj) {
	sortedResults := oGraphicSearch.resultSortDistance(resultObj)
	loop, % sortedResults.Count() {
		if (sortedResults[A_Index].distance > 350) {
			msgbox, % "x: " sortedResults[A_Index].x ", y: " sortedResults[A_Index].y " is outside the circle"
		}
	}
}
```
