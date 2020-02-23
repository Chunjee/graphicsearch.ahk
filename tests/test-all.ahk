    
#Include %A_ScriptDir%\..\export.ahk
#Include %A_ScriptDir%\..\node_modules
#Include unit-testing.ahk\export.ahk
#NoTrayIcon
#SingleInstance, force
SetBatchLines, -1

oGraphicSearch := new graphicsearch()
assert := new unittesting()

; this testing should be performed with image.png open

; variables
pizzaGraphic := "|<pizza>*165$22.03zw0Dzk0w707k00T007w70zUw3s7kDUT0wDy"
spaggGraphic := "|<spagg>*125$26.zzzUTzzw3zzzwzzzzDzzzXzzk0zzU0Dzs03zy00zzs0Dzy03zzU0zs000s0000000000000000000000008"
drinkGraphic := "|<drink>"

centerPoint :=  "|<center>*193$17.zzzzzzzzzzzzzzzzzzzzzzzzzzzzjzzTzwzztzzXzy3zU1s0E"
centerObj := {"x": 1328, "y": 752}

; Perform the searches
sleep, 1000
result := oGraphicSearch.search(pizzaGraphic)
spaghettiResult := oGraphicSearch.find(0, 0, A_ScreenWidth, A_ScreenHeight, 0, 0, spaggGraphic)

if (result) {
    ; test number of results
    assert.label("search")
    assert.test(result.Count(), 5)
    assert.test(spaghettiResult.Count(), 2)


    ; test resultSort
    assert.label("resultSort")
    sortedCoords := oGraphicSearch.resultSort(result)
    assert.test(sortedCoords.Count(), 5)
    assert.test(sortedCoords[5].id, "pizza")
    ; assert.test(sortedCoords, [{1:1215,2:407,3:22,4:10,"id":"pizza","x":1226,"y":412},{1:1457,2:815,3:22,4:10,"id":"pizza","x":1468,"y":820},{1:852,2:891,3:22,4:10,"id":"pizza","x":863,"y":896},{1:1565,2:949,3:22,4:10,"id":"pizza","x":1576,"y":954},{1:1847,2:1261,3:22,4:10,"id":"pizza","x":1858,"y":1266}])


    ; test resultSortDistance
    assert.label("resultSortDistance")
    distanceCoords := oGraphicSearch.resultSortDistance(result, A_ScreenWidth, A_ScreenHeight)
    assert.test(sortedCoords.Count(), 5)
    assert.test(sortedCoords[5].id, "pizza")
    ; assert.test(distanceCoords, [{1:1847,2:1261,3:22,4:10,"distance":"723.24","id":"pizza","x":1858,"y":1266},{1:1565,2:949,3:22,4:10,"distance":"1097.48","id":"pizza","x":1576,"y":954},{1:1457,2:815,3:22,4:10,"distance":"1255.73","id":"pizza","x":1468,"y":820},{1:1215,2:407,3:22,4:10,"distance":"1684.14","id":"pizza","x":1226,"y":412},{1:852,2:891,3:22,4:10,"distance":"1782.06","id":"pizza","x":863,"y":896}])

} else {
    msgbox, % "There was no graphic found, testing could not take place"
}
assert.fullreport()
ExitApp
