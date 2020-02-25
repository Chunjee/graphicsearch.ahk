    
#Include %A_ScriptDir%\..\export.ahk
#Include %A_ScriptDir%\..\node_modules
#Include unit-testing.ahk\export.ahk
; #Include biga.ahk\export.ahk
#NoTrayIcon
#NoEnv
#SingleInstance, force
SetBatchLines, -1

oGraphicSearch := new graphicsearch()
assert := new unittesting()
; A := new biga()

; this testing should be performed with image.png open

; variables
pizzaGraphic := "|<pizza>*165$22.03zw0Dzk0w707k00T007w70zUw3s7kDUT0wDy"
spaggGraphic := "|<spagg>*125$26.zzzUTzzw3zzzwzzzzDzzzXzzk0zzU0Dzs03zy00zzs0Dzy03zzU0zs000s0000000000000000000000008"
drinkGraphic := "|<drink>"

centerPoint :=  "|<center>*193$17.zzzzzzzzzzzzzzzzzzzzzzzzzzzzjzzTzwzztzzXzy3zU1s0E"
centerObj := {"x": 1328, "y": 752}

; Perform the searches
sleep, 1000
result1 := oGraphicSearch.search(pizzaGraphic)
result2 := oGraphicSearch.find(0, 0, A_ScreenWidth, A_ScreenHeight, 0, 0, spaggGraphic)
if (result1) {
    ; test number of results
    assert.label("search")
    assert.test(result1.Count(), 5)
    assert.test(result2.Count(), 2)


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



    assert.fullreport()
} else {
    msgbox, "There was no graphic found, testing could not take place"
}
ExitApp
