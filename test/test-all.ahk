
#Include %A_ScriptDir%\..\export.ahk
#Include %A_ScriptDir%\..\node_modules
#Include unit-testing.ahk\export.ahk

#NoTrayIcon
#NoEnv
#SingleInstance, force
SetBatchLines, -1

oGraphicSearch := new graphicsearch()
assert := new unittesting()
; A := new biga()

; this testing should be performed with image.png open in mspaint. 1920x1080 if it matters

; variables
pizzaGraphic := "|<pizza>*150$32.3wAnkAzAnw3DnAz0DknwDnwAz3w3zzkz0zzwDkzk0z0Dw0Dk033k08"
spaggGraphic := "|<spagg>*164$30.zzzzwznzzzznzzzzzzzzzzzzzzzwzkzzwzk3z3A03z3A0kkzA3kkzA3A03AAA03AAnkAnAnkAnAA3kn0U"
drinkGraphic := "|<drink>*150$18.0070070Tz0Tz1s71s7Ts1Ts1VzVVzV01V01V07V07V0M60M60MM0MMU"
unfindableGraphic := "|<unfindable>*96$48.zzztzzzzzzztzzzzzzztzzzzUsQ94C3XaP9dRYnBjT/sTZuRjM/sw5u0jH/sNZuTaH9d9YnDUsA9Y63Vjzzzzzvzjzzzzznzjzzzzw7zU"

centerPoint :=  "|<center>*199$10.DlzbyzzzzzzxzXw32"
centerObj := {"x": 1328, "y": 752}

; Perform the searches
sleep, 400
result1 := oGraphicSearch.search(pizzaGraphic)
result2 := oGraphicSearch.scan(spaggGraphic, 0, 0, A_ScreenWidth, A_ScreenHeight, 0, 0)
resultlegacyfind := oGraphicSearch.find(0, 0, A_ScreenWidth, A_ScreenHeight, 0, 0, spaggGraphic)


searchAgainResults := oGraphicSearch.searchAgain()
scanAgainResults := oGraphicSearch.scanAgain()
scanAgainResults2 := oGraphicSearch.scanAgain(,,, 10000000000000, 100000000000)

threeResults := oGraphicSearch.search(pizzaGraphic spaggGraphic drinkGraphic)

assert.label("library loaded")
assert.true(isObject(oGraphicSearch.defaultOptionsObj))

assert.label("search results match")
assert.test(searchAgainResults, result1)
assert.test(scanAgainResults, result2)
assert.test(scanAgainResults2, result2)
if (result1) {
	; test number of results
	assert.label("search")
	assert.test(result1.Count(), 5)
	assert.test(result2.Count(), 2)

	; test three searches combined
	assert.label("multiple searches combined count")
	assert.test(threeResults.Count(), 8)
	assert.label("multiple searches combined order")
	assert.test(threeResults[1].id, "pizza")
	assert.test(threeResults[2].id, "pizza")
	assert.test(threeResults[3].id, "pizza")
	assert.test(threeResults[4].id, "pizza")
	assert.test(threeResults[5].id, "pizza")
	assert.test(threeResults[6].id, "spagg")
	assert.test(threeResults[7].id, "spagg")
	assert.test(threeResults[8].id, "drink")

	assert.label("find")
	assert.test(result2, resultlegacyfind)

	; test resultSort
	assert.label("resultSort")
	sortedCoords := oGraphicSearch.resultSort(result1)
	assert.test(sortedCoords.Count(), 5)
	assert.test(sortedCoords[5].id, "pizza")
	; assert.test(sortedCoords, [{1:1215,2:407,3:22,4:10,"id":"pizza","x":1226,"y":412},{1:1457,2:815,3:22,4:10,"id":"pizza","x":1468,"y":820},{1:852,2:891,3:22,4:10,"id":"pizza","x":863,"y":896},{1:1565,2:949,3:22,4:10,"id":"pizza","x":1576,"y":954},{1:1847,2:1261,3:22,4:10,"id":"pizza","x":1858,"y":1266}])


	; test resultSortDistance
	assert.label("resultSortDistance")
	resultsObj := [ {1: 2000, 2: 2000, 3: 22, 4: 10, "id": "HumanReadableTag", "x" :2000, "y" :2000}
				  , {1: 1215, 2: 407, 3: 22, 4: 10, "id": "HumanReadableTag", "x" :1226, "y" :412}]
	resultsObj := oGraphicSearch.resultSortDistance(resultsObj)
	assert.test(resultsObj[1].distance, "1292.11")
	assert.test(resultsObj[2].distance, "2838.33")


	distanceCoords := oGraphicSearch.resultSortDistance(result1, A_ScreenWidth, A_ScreenHeight)
	assert.test(sortedCoords.Count(), 5)
	assert.test(sortedCoords[5].id, "pizza")
	; assert.test(distanceCoords, [{1:1847,2:1261,3:22,4:10,"distance":"723.24","id":"pizza","x":1858,"y":1266},{1:1565,2:949,3:22,4:10,"distance":"1097.48","id":"pizza","x":1576,"y":954},{1:1457,2:815,3:22,4:10,"distance":"1255.73","id":"pizza","x":1468,"y":820},{1:1215,2:407,3:22,4:10,"distance":"1684.14","id":"pizza","x":1226,"y":412},{1:852,2:891,3:22,4:10,"distance":"1782.06","id":"pizza","x":863,"y":896}])


	; test some partial argument objects
	assert.label("Argument objects")
	result3 := oGraphicSearch.search(spaggGraphic, {"x2": 100, "y2": 100})
	assert.test(result3, 0)


	; test resultSortDistance with static data
	assert.label("resultSortDistance")
	resultsObj := [ {1: 2000, 2: 2000, 3: 22, 4: 10, id: "HumanReadableTag", x: 2000, y: 2000}
				, {1: 1215, 2: 407, 3: 22, 4: 10, id: "HumanReadableTag", x: 1226, y: 412}]
	resultsObj0 := oGraphicSearch.resultSortDistance(resultsObj)
	assert.test(resultsObj0[1].distance, "1292.11")
	assert.test(resultsObj0[2].distance, "2838.33")

	resultsObj1 := oGraphicSearch.resultSortDistance(resultsObj, 2000, 2000)
	assert.test(resultsObj1[1].distance, "12.08")
	assert.test(resultsObj1[2].distance, "1766.58")



	assert.group("Unsuccessful searches")
	assert.label("return object")
	assert.false(oGraphicSearch.scan(unfindableGraphic, 0, 0, A_ScreenWidth, A_ScreenHeight, 0, 0))

	assert.label("change noMatchVal")
	oGraphicSearch.noMatchVal := "foobar"
	assert.test(oGraphicSearch.scan(unfindableGraphic, 0, 0, A_ScreenWidth, A_ScreenHeight, 0, 0), "foobar")

	assert.fullreport()
} else {
	msgbox, "There was no graphic found, testing could not take place"
}
ExitApp
