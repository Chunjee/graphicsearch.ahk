
#Include %A_ScriptDir%\..\export.ahk
#Include %A_ScriptDir%\..\node_modules
#Include expect.ahk\export.ahk

#Requires autohotkey v1.1
#NoTrayIcon
#NoEnv
#SingleInstance, force
; CoordMode, Mouse, Screen
SetBatchLines, -1

oGraphicSearch := new graphicsearch()
assert := new expect()



; this testing should be performed with image.png open in mspaint. 1920x1080 if it matters


; variables
pizzaGraphic := "|<pizza>*150$32.3wAnkAzAnw3DnAz0DknwDnwAz3w3zzkz0zzwDkzk0z0Dw0Dk033k08"
spaggGraphic := "|<spagg>*164$30.zzzzwznzzzznzzzzzzzzzzzzzzzwzkzzwzk3z3A03z3A0kkzA3kkzA3A03AAA03AAnkAnAnkAnAA3kn0U"
drinkGraphic := "|<drink>*150$18.0070070Tz0Tz1s71s7Ts1Ts1VzVVzV01V01V07V07V0M60M60MM0MMU"
unfindableGraphic := "|<unfindable>*96$48.zzztzzzzzzztzzzvzjzzzzznzjzzzzw7zU"
screenSizeX := 1920
screenSizeY := 1080
; currently not used
centerPoint :=  "|<center>*199$10.DlzbyzzzzzzxzXw32"


; Perform the searches
sleep, 400
result1 := oGraphicSearch.search(pizzaGraphic)
result2 := oGraphicSearch.scan(spaggGraphic, 0, 0, screenSizeX, screenSizeY, 0, 0)
resultlegacyfind := oGraphicSearch.find(0, 0, screenSizeX, screenSizeY, 0, 0, spaggGraphic)


searchAgainResults := oGraphicSearch.searchAgain()
scanAgainResults := oGraphicSearch.scanAgain()
scanAgainResults2 := oGraphicSearch.scanAgain(,,, screenSizeX, screenSizeY)

threeResults := oGraphicSearch.search(pizzaGraphic spaggGraphic drinkGraphic)

assert.label("library loaded")
assert.true(isObject(oGraphicSearch.defaultOptionsObj))

assert.group(".scanAgain")
assert.label("search results match")
assert.test(searchAgainResults, result1)
assert.test(scanAgainResults, result2)
assert.test(scanAgainResults2, result2)
if (result1) {
	; test number of results
	assert.group(".search")
	assert.label("resultObject")
	assert.test(result1.count(), 5)
	assert.test(result2.count(), 1)

	; endure findall setting considered when disabled
	assert.label("find only one")
	assert.test(oGraphicSearch.search(pizzaGraphic, {findall: false}).count(), 1)

	; test three searches combined
	assert.label("multiple searches combined count")
	assert.test(threeResults.count(), 7)
	assert.label("multiple searches combined order")
	assert.test(threeResults[1].id, "pizza")
	assert.test(threeResults[2].id, "pizza")
	assert.test(threeResults[3].id, "pizza")
	assert.test(threeResults[4].id, "pizza")
	assert.test(threeResults[5].id, "pizza")
	assert.test(threeResults[6].id, "spagg")
	assert.test(threeResults[7].id, "drink")
	oGraphicSearch.showMatches(threeResults, {showBox: false, showLabel: true})
	oGraphicSearch.showMatches(threeResults[4], {showBox: true, showLabel: true})


	assert.group(".find")
	assert.label("exact output match with other methods")
	assert.test(result2, resultlegacyfind)
	assert.test(result2, resultlegacyfind)

	; test resultSort
	assert.group(".resultSort")
	assert.label("resultSort")
	sortedCoords := oGraphicSearch.resultSort(result1)
	assert.test(sortedCoords.count(), 5)
	assert.test(sortedCoords[5].id, "pizza")


	; test resultSortDistance
	assert.group(".resultSortDistance")
	assert.label("sorting")
	resultsObj := [ {1: 2000, 2: 2000, 3: 22, 4: 10, "id": "HumanReadableTag", "x" :2000, "y" :2000}
				  , {1: 1215, 2: 407, 3: 22, 4: 10, "id": "HumanReadableTag", "x" :1226, "y" :412}]
	resultsObj := oGraphicSearch.resultSortDistance(resultsObj, screenSizeX, screenSizeY)
	assert.test(resultsObj[1].distance, 923)
	assert.test(resultsObj[2].distance, 963)
	assert.notEqual(resultsObj[resultsObj.count()], "")

	; check that drink is closest to a spaggetti
	assert.label("drink is closest to spagg")
	resultsObj := oGraphicSearch.resultSortDistance(threeResults, threeResults[7].x, threeResults[7].y)
	assert.test(resultsObj[2].id, "spagg")


	distanceCoords := oGraphicSearch.resultSortDistance(result1, screenSizeX, screenSizeY)
	assert.test(sortedCoords.count(), 5)
	assert.test(sortedCoords[5].id, "pizza")
	

	; test resultSortDistance with static data
	assert.label("with static data")
	resultsObj := [ {1: 2000, 2: 2000, 3: 22, 4: 10, id: "HumanReadableTag", x: 2000, y: 2000}
				, {1: 1215, 2: 407, 3: 22, 4: 10, id: "HumanReadableTag", x: 1226, y: 412}]
	resultsObj0 := oGraphicSearch.resultSortDistance(resultsObj, screenSizeX, screenSizeY)
	assert.test(resultsObj0[1].distance, 923)
	assert.test(resultsObj0[2].distance, 963)

	resultsObj1 := oGraphicSearch.resultSortDistance(resultsObj, screenSizeX, screenSizeY)
	assert.test(resultsObj1[1].distance, 923)
	assert.test(resultsObj1[2].distance, 963)


	assert.group("Unsuccessful searches")
	; test some partial argument objects
	assert.label("Argument objects")
	result3 := oGraphicSearch.search(unfindableGraphic, {"x2": 100, "y2": 100})
	assert.test(result3, false, "the resulting search should fail, returning false")

	assert.label("return object")
	assert.false(oGraphicSearch.scan(unfindableGraphic, 1, 1, screenSizeX, screenSizeY))

	assert.label("change noMatchVal")
	oGraphicSearch.noMatchVal := "foobar"
	assert.test(oGraphicSearch.searchAgain(), "foobar")

	assert.label(".resultMerge")
	resultObj := [{1:300, 2:200, 3:50, 4:30, id:"Hello"}
		, {1:360, 2:200, 3:60, 4:30, id:"World"}
		, {1:900, 2:250, 3:80, 4:40, id:"OCR?"}]

	; with custom offsets
	results := oGraphicSearch.resultMerge(resultObj, 30, 20, 10)
	assert.test(results, {"x":300, "y":200, "h":30, "w":110, "text":"HelloWorld"})


	assert.fullReport()
} else {
	msgbox, % "There was no graphic found, testing could not take place"
}
exitApp
