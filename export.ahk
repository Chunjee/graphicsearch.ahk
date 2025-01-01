class graphicsearch {
	; #region Additionals
	static bind := [], bits := [], Lib := []
	static noMatchVal := false ;the value to return when no matches were found
	static defaultOptionsObj := { "x1": 0
								, "y1": 0
								, "x2": A_ScreenWidth
								, "y2": A_ScreenHeight
								, "err1": 0 ;foreground
								, "err0": 0 ;background
								, "screenshot": 1
								, "findall": 1
								, "joinqueries": 0
								, "offsetx": 0
								, "offsety": 0 }

	; .search
	static lastSearchQuery := ""
	static lastSearchOptions := {}
	; .scan
	static lastScanQuery := ""
	static lastScanOptions := {}

	;; Convience Methods
	search(param_query, param_options := "") {
		; create default if needed
		if (!isObject(param_options)) {
			param_options := this.defaultOptionsObj.clone()
		}
		; save parameters for use in future
		this.lastSearchQuery := param_query
		this.lastSearchOptions := param_options

		; pass the parameters to .find and return
		return this._mainSearch(param_query, param_options)
	}


	searchAgain(param_query := "", param_options := "")	{
		; save new query if entered
		if (param_query != "") {
			this.lastSearchQuery := param_query
		}
		if (param_options != "") {
			this.lastSearchOptions := param_options
		}
		; pass saved arguments to .search and return
		return this._mainSearch(this.lastSearchQuery, this.lastSearchOptions)
	}


	scan(param_query, x1 := 0, y1 := 0, x2 := "", y2 := "", err1 := 0, err0 := 0, screenshot := 1
		, findall := 1, joinqueries := 1, offsetx := 20, offsety := 10)	{

		if (x2 == "") {
			x2 := A_ScreenWidth
		}
		if (y2 == "") {
			y2 := A_ScreenHeight
		}

		; save parameters for use in future and build search object
		this.lastScanQuery := param_query
		this.lastScanOptions := { "x1": x1
								, "y1": y1
								, "x2": x2
								, "y2": y2
								, "err1": err1
								, "err0": err0
								, "screenshot": screenshot
								, "findall": findall
								, "joinqueries": joinqueries
								, "offsetx": offsetx
								, "offsety": offsety }
		; pass the parameters to .find and return
		return this._mainSearch(param_query, this.lastScanOptions)
	}


	scanAgain(param_query := "", x1 := "", y1 := "", x2 := "", y2 := "", err1 := "", err0 := "", screenshot := ""
		, findall := "", joinqueries := "", offsetx := "", offsety := "") {
		; save new query if entered
		if (param_query != "") {
			this.lastScanQuery := param_query
		}
		if (x1 != "") {
			this.lastScanOptions.x1 := x1
		}
		if (y1 != "") {
			this.lastScanOptions.y1 := y1
		}
		if (x2 != "") {
			this.lastScanOptions.x2 := x2
		}
		if (err1 != "") {
			this.lastScanOptions.err1 := err1
		}
		if (err0 != "") {
			this.lastScanOptions.err0 := err0
		}
		if (screenshot != "") {
			this.lastScanOptions.screenshot := screenshot
		}
		if (findall != "") {
			this.lastScanOptions.findall := findall
		}
		if (joinqueries != "") {
			this.lastScanOptions.joinqueries := joinqueries
		}
		if (offsetx != "") {
			this.lastScanOptions.offsetx := offsetx
		}
		if (offsety != "") {
			this.lastScanOptions.offsety := offsety
		}
		; pass saved arguments to .search and return
		return this._mainSearch(this.lastScanQuery, this.lastScanOptions)
	}

	;; Sort Methods
	; Sort the results from left to right and top to bottom, ignore slight height difference
	resultsort(param_resultsObj, param_dy := 10) {
		local
		if (!isObject(param_resultsObj)) {
			return param_resultsObj
		}
	
		ypos := []
		sortStr := ""
	
		for k, v in param_resultsObj {
			x := v.x
			y := v.y
			add := true
	
			; Check if y can be adjusted based on proximity to existing y positions
			for k2, v2 in ypos {
				if (abs(y - v2) <= param_dy) {
					y := v2
					add := false
					break
				}
			}
			; if this is a new y position, add it to ypos
			if (add) {
				ypos.push(y)
			}
	
			; Build the sorting string
			sortStr .= (y * 150000 + x) "###" k "`n"
		}
	
		; Sort the string by the combined value
		sort, sortStr, N D`n
	
		; Build the sorted results object
		param_resultsObj2 := []
		loop, parse, sortStr, `n
		{
			; Ensure proper split and retrieve key
			splitResult := strSplit(A_LoopField, "###")
			if (splitResult.count() >= 2) {
				key := splitResult[2]
				param_resultsObj2.push(param_resultsObj[key])
			}
		}
	
		return param_resultsObj2
	}

	; Re-order resultObj according to the nearest distance
	resultSortDistance(param_resultObj, param_x := "", param_y := "") {
		local
		if (param_x == "") {
			param_x := A_ScreenWidth / 2
		}
		if (param_y == "") {
			param_y := A_ScreenHeight / 2
		}

		resultObj := param_resultObj.clone()
		sortStr := ""

		for key, value in resultObj {
			resultObj[key].distance := round(sqrt((value.x - param_x)**2 + (value.y - param_y)**2), 0)
			sortStr .= value.distance "#/#/#" key "`n"
		}

		; Sort the string by distance in ascending order
		sort, sortStr, N D`n
		resultObj2 := []
		loop, parse, sortStr, `n
		{
			if (A_LoopField != "") {
				k := strSplit(A_LoopField, "#/#/#")[2]
				resultObj2.push(resultObj[k])
			}
		}
		return resultObj2
	}

	;; Display Methods
	showMatches(param_resultObj, param_options := "") {
		setBatchLines, % (bch := A_BatchLines) ? "-1" : "-1"
		; apply defaults
		param_options := this._merge({showBox:true, showLabel:true, timeout:4000, color:"0b87da"}, param_options)
		; convert if width/height object
		param_resultObj := this._nonStandardConvert(param_resultObj)
		; Check if param_resultObj is a single object, cast it to an array if necessary
		if !isObject(param_resultObj[1]) {
			; Cast single result to an array
			param_resultObj := [param_resultObj]
		}

		for key, value in param_resultObj {
			if (param_options.showBox == false) {
				this._drawTextOnScreen(key, {x: value.x - 76, y: value.y - 76, color: param_options.color, size: 33})
				if (value.id != "" && param_options.showLabel) {
					this._drawTextOnScreen(value.id, {x: value.x + (20 * strLen(key)), y: value.y - 48, color: param_options.color, size: 16})
				}
				continue
			}
			this._drawBoxOnScreen(key, {x: value.1 + 2, y: value.2 + 2, width: value.3, height: value.4, color: "black", thickness: 6, timeout: param_options.timeout})
			this._drawBoxOnScreen(key, {x: value.1, y: value.2, width: value.3, height: value.4, color: param_options.color, thickness: 6, timeout: param_options.timeout})
			if (value.id != "" && param_options.showLabel) {
				this._drawTextOnScreen("[" key "] " value.id, {x: (value.1 - value.3), y: (value.2 - value.4 + 2), color: param_options.color, size: 16, timeout: param_options.timeout})
			}
		}
		setBatchLines, % bch
	}

	;; Internal Methods
	_mainSearch(param_query, param_options := "") {
		local

		; create default if needed
		if (!isObject(param_options)) {
			param_options := this.defaultOptionsObj.clone()
		}
		; merge with default for any blank parameters
		for Key, Value in this.defaultOptionsObj {
			; if the key is existing in param_options
			if (param_options.hasKey(Key) == false) {
				param_options[Key] := Value
			}
		}

		; pass the parameters to .find and return
		return this.find(param_options.x1, param_options.y1, param_options.x2, param_options.y2, param_options.err1, param_options.err0, param_query
			, param_options.screenshot, param_options.findall, param_options.joinqueries, param_options.offsetx, param_options.offsety)
	}

	_drawTextOnScreen(para_text, para_options) {
		try {
			; apply defaults
			para_options := this._merge({x: 100, y: 100, timeout: 4000, size: 33}, para_options)
	
			; create unique name and start timeout timer
			l_name := this._hash([para_text, para_options])
			timeRef := objBindMethod(this, "_timeoutTextGui", l_name)
			setTimer % timeRef, % "-" para_options.timeout
			
			gui, text%l_name%:new, % "+lastFound +alwaysOnTop +toolWindow -caption"
			gui, color, % "195f8e"
			gui, font, % "S" para_options.size , Arial Black
			gui, add, text, % "backgroundTrans", % para_text
			gui, add, text, % "backgroundTrans xp-2 yp-2 c" para_options.color, % para_text

			winSet, transColor, % "195f8e"
			gui, show, % "NoActivate x" para_options.x " y" para_options.y, OSD
			return true
		}
		return false
	}

	_drawBoxOnScreen(para_text, para_options) {
		try {
			; apply defaults
			para_options := this._merge({x: 100, y: 100, timeout: 4000}, para_options)

			; create unique name and start timeout timer
			l_name := this._hash([para_text, para_options])
			timeRef := objBindMethod(this, "_timeoutBoxGui", l_name)
			setTimer % timeRef, % "-" para_options.timeout
	
			; create gui
			; box takes 4 solid color guis to form a square
			x := floor(para_options.x)
			y := floor(para_options.y)
			w := floor(para_options.width)
			h := floor(para_options.height)
			d := floor(para_options.thickness)
			loop, 4	{
				gui, box%l_name%%A_Index%: +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000
				; set dimensions
				x1 := (A_Index == 2 ? x + w : x - d)
				y1 := (A_Index == 3 ? y + h : y - d)
				w1 := (A_Index == 1 || A_Index == 3 ? w + 2 * d : d)
				h1 := (A_Index == 2 || A_Index == 4 ? h + 2 * d : d)
				gui, box%l_name%%A_Index%:color, % para_options.color
				gui, box%l_name%%A_Index%:show, NA x%x1% y%y1% w%w1% h%h1%
			}
			return true
		}
		return false
	}

	_timeoutBoxGui(l_name) {
		; hide
		loop, 4 {
			gui, box%l_name%%A_Index%:destroy
		}
	}

	_timeoutTextGui(l_name) {
		; hide 
		gui, text%l_name%:destroy
	}

	_hash(dataArray) {
		data := ""
		
		; Process each element in the array
		for index, value in dataArray {
			if isObject(value) {
				; Append object key-value pairs to the data string
				for key, val in value
					data .= key . val
			 } else { 
				; Append non-object values directly
				data .= value
			}
		}
		
		; Simple hash calculation using bitwise operations
		hash := 0
		for index, char in strSplit(data) {
			hash := (hash * 31) ^ asc(char)
		}
		
		; return hash in hexadecimal format
		return format("{:08X}", hash & 0xFFFFFFFF)
	}

	_merge(defaultObj, targetObj) {
		local
		; Create a copy of defaultObj
		mergedObj := defaultObj.clone()
		
		; Override with targetObj values
		for key, value in targetObj {
			mergedObj[key] := value
		}
		
		return mergedObj
	}

	_nonStandardConvert(inputObj) {
		local
		if (inputObj.hasKey("h")) {
			; Calculate top-left coordinates
			topLeftX := inputObj.x
			topLeftY := inputObj.y
			return [{1: topLeftX, 2: topLeftY, 3: inputObj.w, 4: inputObj.h, "id": inputObj.text}]
		}
		return inputObj
	}

	__Delete() {
		if (this.bits.hBM) {
			try dllCall("DeleteObject", "Ptr",this.bits.hBM)
		}
	}
	; #endregion


	find(x1 := 0, y1 := 0, x2 := 0, y2 := 0, err1 := 0, err0 := 0, text := ""
		, ScreenShot := 1, FindAll := 1, joinText := 0, offsetX := 20, offsetY := 10
		, dir := 0, zoomW := 1, zoomH := 1) {
		local
		
		setBatchLines, % (bch := A_BatchLines)?"-1":"-1"
		x1 := floor(x1), y1 := floor(y1), x2 := floor(x2), y2 := floor(y2)
		if (x1=0 && y1=0 && x2=0 && y2=0)
			n := 150000, x := y := -n, w := h := 2*n
		else
			x := min(x1,x2), y := min(y1,y2), w := abs(x2-x1)+1, h := abs(y2-y1)+1
		bits := this.getBitsFromScreen(x,y,w,h,ScreenShot,zx,zy), x -= zx, y -= zy
		, this.resultObj := 0, info := []
		loop parse, text, |
		if isObject(j := this.picInfo(A_LoopField))
				info.push(j)
		if (w<1 || h<1 || !(num := info.length()) || !bits.Scan0)
		{
			setBatchLines, % bch
			return this.noMatchVal
		}arr := [], info2 := [], k := 0, s := ""
		, mode := (isObject(joinText) ? 2 : joinText ? 1 : 0)
		for i,j in info
		{
		k := max(k, (j[7]=5 && j[8] != 2 ? j[9] : j[2]*j[3]))
			if (mode)
			v := (mode=1 ? i : j[10]) . "", s .= "|" v
			, (v != "") && ((!info2.hasKey(v) && info2[v] := []), info2[v].push(j))
		}
		sx := x, sy := y, sw := w, sh := h, (mode=1 && joinText := [s])
		, allpos_max := (FindAll || joinText ? 10000:1)
		, varSetCapacity(s1,k*4), varSetCapacity(s0,k*4)
		, varSetCapacity(ss,sw*(sh+3)), varSetCapacity(allpos,allpos_max*8)
		, ini := { sx:sx, sy:sy, sw:sw, sh:sh, zx:zx, zy:zy
		, mode:mode, bits:bits, ss:&ss, s1:&s1, s0:&s0
		, allpos:&allpos, allpos_max:allpos_max
		, err1:err1, err0:err0, zoomW:zoomW, zoomH:zoomH }
		loop 2 {
			if (err1=0 && err0=0) && (num>1 || A_Index>1)
				ini.err1 := err1 := 0.05, ini.err0 := err0 := 0.05
				if (!joinText) {
					for i,j in info
						loop % this.picFind(ini, j, dir, sx, sy, sw, sh) {
							v := numGet(allpos,4*A_Index-4,"uint"), x := (v&0xFFFF)+zx, y := (v>>16)+zy
							, w := floor(j[2]*zoomW), h := floor(j[3]*zoomH)
							, arr.push({1:x, 2:y, 3:w, 4:h, x:x+w//2, y:y+h//2, id:j[10]})
								if (!FindAll) {
									break 3
								}
							}
				}
				else
			for k,v in joinText {
				v := strSplit(trim(regExReplace(v, "\s*\|[|\s]*", "|"), "|")
				, (inStr(v,"|")?"|":""), " `t")
				, this.joinText(arr, ini, info2, v, 1, offsetX, offsetY
				, FindAll, dir, 0, 0, 0, sx, sy, sw, sh)
				if (!FindAll && arr.length())
					break 2
			}
			if (err1 != 0 || err0 != 0 || arr.length() || info[1][4] || info[1][7]=5)
				break
		}
		if (arr.length()) {
			outputX := arr[1].x, OutputY := arr[1].y, this.resultObj := arr
			setBatchLines, % bch
			return arr
		}
		setBatchLines, % bch
		return this.noMatchVal
	}
	
	; the join text object use [ "abc", "xyz", "a1|a2|a3" ]

	joinText(arr, ini, info2, text, index, offsetX, offsetY
	, FindAll, dir, minX, minY, maxY, sx, sy, sw, sh) {
		local
		if !(Len := text.length()) || !info2.hasKey(key := text[index])
			return 0
		zoomW := ini.zoomW, zoomH := ini.zoomH, mode := ini.mode
		for i,j in info2[key]
		if (mode != 2 || key==j[10])
		loop % resultObj := this.picFind(ini, j, dir, sx, sy, (index=1 ? sw
		: min(sx+offsetX+floor(j[2]*zoomW),ini.sx+ini.sw)-sx), sh)
		{
		if (A_Index = 1) {
			pos := [], p := ini.allpos-4
			loop % resultObj
			pos.push(numGet(0|p += 4,"uint"))
		}
		v := pos[A_Index], x := v&0xFFFF, y := v>>16
		, w := floor(j[2]*zoomW), h := floor(j[3]*zoomH)
				, (index=1 && (minX := x, minY := y, maxY := y+h))
				, minY1 := min(y, minY), maxY1 := max(y+h, maxY), sx1 := x+w
				if (index<Len) {
					sy1 := max(minY1-offsetY, ini.sy), sh1 := min(maxY1+offsetY, ini.sy+ini.sh)-sy1
					if this.joinText(arr, ini, info2, text, index+1, offsetX, offsetY
					, FindAll, 5, minX, minY1, maxY1, sx1, sy1, 0, sh1)
					&& (index > 1 || !FindAll) {
						return 1
					}
				 } else { 
					comment := ""
					for k,v in text {
						comment .= (mode=2 ? v : info2[v][1][10])
					}
					x := minX+ini.zx, y := minY1+ini.zy, w := sx1-minX, h := maxY1-minY1
					, arr.push({1:x, 2:y, 3:w, 4:h, x:x+w//2, y:y+h//2, id:comment})
					if (index>1 || !FindAll) {
						return 1
					}
				}
			}
		return 0
	}

	picFind(ini, j, dir, sx, sy, sw, sh) {
		local
		static init, MyFunc
		if !varSetCapacity(init) && (init := "1")
		{
		x32 := "VVdWU4HsmAAAAIuEJNQAAAADhCTMAAAAi5wk@AAAAIO8JKwAAAAFiUQkIIuEJPgA"
		. "AACNBJiJRCQ0D4RKBgAAi4Qk6AAAAIXAD45ADwAAiXwkEIu8JOQAAAAx7ccEJAAA"
		. "AADHRCQIAAAAAMdEJBQAAAAAx0QkDAAAAACNtgAAAACLhCTgAAAAi0wkDDH2MdsB"
		. "yIX@iUQkBH896ZAAAABmkA+vhCTMAAAAicGJ8Jn3@wHBi0QkBIA8GDF0TIuEJNwA"
		. "AACDwwEDtCQAAQAAiQyog8UBOd90VIsEJJn3vCToAAAAg7wkrAAAAAR1tQ+vhCTA"
		. "AAAAicGJ8Jn3@40MgYtEJASAPBgxdbSLRCQUi5Qk2AAAAIPDAQO0JAABAACJDIKD"
		. "wAE534lEJBR1rAF8JAyDRCQIAYu0JAQBAACLRCQIATQkOYQk6AAAAA+FMv@@@4tE"
		. "JBSLfCQQD6+EJOwAAACJbCQwwfgKiUQkKIuEJPAAAAAPr8XB+AqJRCRAg7wkrAAA"
		. "AAQPhCIGAACLhCTAAAAAi5wkxAAAAA+vhCTIAAAAjSyYi4QkzAAAAIucJMAAAAD3"
		. "2IO8JKwAAAABjQSDiUQkLA+ELwYAAIO8JKwAAAACD4Q4CAAAg7wkrAAAAAMPhLkL"
		. "AACLjCTQAAAAhckPjicBAACLhCTMAAAAi6wkzAAAAMdEJAwAAAAAx0QkEAAAAACJ"
		. "fCQYg+gBiUQkCI22AAAAAIt8JBCLtCTUAAAAMcCLXCQgAfsB94Xtif6J738X6bwA"
		. "AADGBAYEg8ABg8MBOccPhKQAAACDvCSsAAAAA3@khcAPtgsPhLoPAAAPtlP@iVQk"
		. "BDlEJAgPhMIPAAAPtlMBiRQki5Qk9AAAAIXSD4SfAQAAD7bpugYAAACD7QGD@QF2"
		. "G4N8JAQBD5TCgzwkAYnVD5TCCeoPttIB0oPKBIHh@QAAAL0BAAAAdByLTCQEiywk"
		. "hckPlEQkBIXtD5TBic0PtkwkBAnNCeqDwwGIFAaDwAE5xw+FXP@@@wF8JBCJ@YNE"
		. "JAwBi0QkDDmEJNAAAAAPjwz@@@+LfCQYg7wkrAAAAAN@FouEJPQAAACFwA+VwDwB"
		. "g5wkxAAAAP+LXCQUi3QkKDHAOfOLdCRAD07YiVwkFItcJDA58w9Pw4lEJDCLhCTM"
		. "AAAAK4QkAAEAAIlEJASLhCTQAAAAK4QkBAEAAIO8JLgAAAAJiUQkCA+ExgAAAIuE"
		. "JLgAAACD6AGD+AcPh7wCAACD+AOJRCQkD463AgAAi0QkBMdEJEQAAAAAx0QkDAAA"
		. "AACJBCSLRCQIiUQkHItcJEQ5HCTHRCRMAAAAAA+MCwEAAItcJEw5XCQcD4zCDQAA"
		. "i3QkRItcJCSLBCQp8PbDAg9Exot0JEyJwotEJBwp8PbDAQ9ExoP7A4nWD0@wD0@C"
		. "iXQkGIlEJBDp3gsAAI12AA+20YPqAYP6AhnSg+ICg8IEgeH9AAAAD5TBCcqIFAbp"
		. "8v3@@4tcJASLdCQIx0QkZAAAAADHRCRgAQAAAMdEJFQAAAAAx0QkWAAAAACJ2I1W"
		. "AYk0JMHoH4lcJBzHRCQMAAAAAAHY0fiJRCQQifDB6B8B8NH4iUQkGInYg8ABicEP"
		. "r8o50A9MwoPACIlMJHyJwQ+vyImMJIAAAACLXCR8OVwkZH0Zi5wkgAAAADlcJFjH"
		. "RCRcAAAAAA+M9QQAAIuMJLgAAACFyQ+FnQIAAIuUJPgAAACF0g+EjgIAAIuEJAQB"
		. "AAAPr4QkAAEAAIP4AQ+EdgIAAIN8JAwBD46lCgAAi0QkNIucJPgAAAAx7cdEJAQA"
		. "AAAAiSwkjXgEi0QkDIPoAYlEJBCLRCQEiwwkizeLRAMEhcmJRCQIich4NotP@DnO"
		. "D4N1BQAAifqNa@zrDY12AIPqBItK@DnOcxeJCotMhQSJTIMEg+gBg@j@deS4@@@@"
		. "@4tMJDSDwAGDBCQBg8cEg0QkBASJNIGLdCQIiTSDiwQkO0QkEHWNi4QkBAEAAIus"
		. "JAABAAAPr8APr+2JRCQEi7Qk+AAAAMdEJAgAAAAAMduLRCQIiwSGiUQkEA+3+MHo"
		. "EIXbiQQkdC0xyY22AAAAAIsUjg+3win4D6@AOeh9D8HqECsUJA+v0jtUJAR8EYPB"
		. "ATnZdduLRCQQiQSeg8MBg0QkCAGLRCQIOUQkDHWiidiBxJgAAABbXl9dwlwAx0Qk"
		. "JAAAAACLRCQIx0QkRAAAAADHRCQMAAAAAIkEJItEJASJRCQc6UT9@@8xwIO8JLAA"
		. "AAACD5TAiYQkhAAAAA+EUAQAADHAg7wksAAAAAGLrCS0AAAAD5TAhe2JRCR4D4SG"
		. "CwAAi7Qk2AAAAIuUJLQAAAAx7YucJOAAAACLjCTcAAAAiXwkCI0ElolEJASNdCYA"
		. "izuDxgSDw1iDwQSJ+MHoEA+vhCQEAQAAmfe8JOgAAAAPr4QkwAAAAIkEJA+3xw+v"
		. "hCQAAQAAmfe8JOQAAACLFCSNBIKJRvyLQ6yNREUAg8UWiUH8O3QkBHWmi4QktAAA"
		. "AIm8JLAAAACLfCQIiUQkFIuEJOwAAAAPr4QktAAAAMH4ColEJCiLhCTgAAAAx0Qk"
		. "QAAAAADHRCQwAAAAAIPACIlEJFDpSfr@@4tEJAyBxJgAAABbXl9dwlwAi4QksAAA"
		. "AMHoEA+vhCQEAQAAmfe8JOgAAAAPr4QkwAAAAInBD7eEJLAAAAAPr4QkAAEAAJn3"
		. "vCTkAAAAjQSBiYQksAAAAOnt+f@@i4Qk6AAAAIu0JNAAAAAPr4Qk5AAAANGkJLQA"
		. "AAADhCTgAAAAhfaJRCRQD47z+v@@i4QkzAAAAInqi2wkUMdEJCQAAAAAx0QkOAAA"
		. "AADB4AKJRCRIMcCLnCTMAAAAhdsPjisBAACLnCS8AAAAAdMDVCRIiVwkEItcJCAD"
		. "XCQ4iVQkPAOUJLwAAACJXCQYiVQkHI12AI28JwAAAACLdCQQMds5nCS0AAAAD7ZO"
		. "AolMJAQPtk4BD7Y2iUwkCIl0JAx2W412AI28JwAAAACLRJ0Ag8MCi3yd@InCD7bM"
		. "D7bAK0QkDMHqECtMJAgPttIrVCQEgf@@@@8AiQQkdyUPr9IPr8mNFFIPr8CNFIqN"
		. "BEI5x3NGMcA5nCS0AAAAd6+JwutBif7B7hCJ8A+28A+v0g+v9jnyd92J+A+21A+v"
		. "yQ+v0jnRd86LNCSJ+A+20A+v0onwD6@GOdB3uroBAAAAuAEAAACLXCQYg0QkEASL"
		. "TCQQiBODwwE7TCQciVwkGA+FGv@@@4u0JMwAAAABdCQ4i1QkPINEJCQBA1QkLItc"
		. "JCQ5nCTQAAAAD4Ws@v@@6U34@@+LRCQQhcB4G4tcJBw52H8Ti0QkGIXAeAuLHCQ5"
		. "2A+ONwYAAItsJFSF7Q+F4AUAAINsJBgBg0QkXAGDRCRYAYt0JGA5dCRcfLiLXCRU"
		. "idiD4AEBxonYg8ABiXQkYIPgA4lEJFTpvvr@@4uEJLAAAACLjCTQAAAAxwQkAAAA"
		. "AMdEJAQAAAAAg8ABweAHiYQksAAAAIuEJMwAAADB4AKFyYlEJAwPjsz4@@+J6Ius"
		. "JLAAAACJfCQQi5QkzAAAAIXSfmaLjCS8AAAAi1wkIIu8JLwAAAADXCQEAcEDRCQM"
		. "iUQkCAHHjXYAjbwnAAAAAA+2UQIPtkEBD7Yxa8BLa9ImAcKJ8MHgBCnwAdA5xQ+X"
		. "A4PBBIPDATn5ddWLnCTMAAAAAVwkBItEJAiDBCQBA0QkLIs8JDm8JNAAAAAPhXf@"
		. "@@+LfCQQ6Qb3@@+LBCTprvr@@4uEJOgAAACLvCTgAAAAD6+EJOQAAADRpCS0AAAA"
		. "jQSHiUQkUIuEJPAAAADB+AqDwAGJRCQki4Qk6AAAAIXAD45ECgAAi3wkJIuEJAQB"
		. "AACLdCRQx0QkMAAAAADHRCQUAAAAAA+vx4lEJECLhCTkAAAAD6@HweACiUQkSIuE"
		. "JOAAAACDwAKJRCQ4ifiNPL0AAAAAiXwkLInHD6+EJAABAACJfCQ8iUQkKIuEJOQA"
		. "AACFwA+OaQEAAItEJDjHRCQcAAAAAIlEJBCLRCQkiUQkGItEJBC7AgAAAA+2OIk8"
		. "JA+2eP8PtkD+iXwkBIlEJAg5nCS0AAAAD4bCAAAAiwSeg8MCi3ye@InCD7bMD7bA"
		. "K0QkCMHqECtMJAQPttIrFCSB@@@@@wCJRCQMd0YPr9IPr8mNFFIPr8CNFIqNBEI5"
		. "x3Kui3wkGItEJCSLTCQsAUwkEItMJCgBTCQcAfg5vCTkAAAAD465AAAAiUQkGOlf"
		. "@@@@if3B7RCJ6A+26A+v0g+v7TnqD4dm@@@@ifgPttQPr8kPr9I50Q+HU@@@@4tM"
		. "JAyJ+A+2+A+v@4nID6@BOfh2kDmcJLQAAAAPhz7@@@+LRCQwi3wkFJmNHL0AAAAA"
		. "97wk6AAAAA+vhCTAAAAAicGLRCQcmfe8JOQAAACLFCTB4hCNBIGLjCTYAAAAiQS5"
		. "i0QkBIPHAYl8JBSLvCTcAAAAweAICdALRCQIiQQf6SD@@@+LfCQ8i0QkJItMJEAB"
		. "TCQwi0wkSAFMJDgB+Dm8JOgAAAB+CYlEJDzpXP7@@4tEJBQPr4Qk7AAAAMH4ColE"
		. "JCiLRCRQx0QkQAAAAADHRCQwAAAAAIt4BIn4ifvB6BAPtteJ+w+2wA+2y4nDD6@Y"
		. "idAPr8KJXCRwiUQkdInID6@BiUQkbOlH9P@@i4Qk0AAAAIXAD45u9f@@i5wkzAAA"
		. "AItEJCDHBCQAAAAAx0QkBAAAAACJfCQMjQRYiUQkGInYweACiUQkCIu0JMwAAACF"
		. "9n5Xi4wkvAAAAItcJBiLvCS8AAAAA1wkBAHpA2wkCAHvD7ZRAoPBBIPDAWvyJg+2"
		. "Uf1rwkuNFAYPtnH8ifDB4AQp8AHQwfgHiEP@Ofl10ou8JMwAAAABfCQEgwQkAQNs"
		. "JCyLBCQ5hCTQAAAAdYqLhCTMAAAAi3wkDDHti5QktAAAADH2g+gBiXwkJIlEJAyL"
		. "hCTQAAAAg+gBiUQkEIucJMwAAACF2w+O4gAAAIu8JMwAAACLRCQYAfeNDDCJ+4l8"
		. "JByJxwHfifMrnCTMAAAAiXwkBIt8JCABwwH3McCJfCQIiRwkhcAPhGQDAAA5RCQM"
		. "D4RaAwAAhe0PhFIDAAA5bCQQD4RIAwAAD7YRD7Z5@74BAAAAA5QksAAAADn6ckYP"
		. "tnkBOfpyPos8JA+2Pzn6cjSLXCQED7Y7OfpyKYs8JA+2f@85+nIeizwkD7Z@ATn6"
		. "chMPtnv@OfpyCw+2cwE58g+Sw4nei3wkCInziBwHg8ABg8EBg0QkBAGDBCQBOYQk"
		. "zAAAAA+FWv@@@4t0JByDxQE5rCTQAAAAD4X@@v@@i3wkJImUJLQAAADpY@L@@8dE"
		. "JEAAAAAAx0QkKAAAAADHRCQwAAAAAMdEJBQAAAAA6cfx@@+DfCRUAQ+E6gEAAIN8"
		. "JFQCD4SVAgAAg2wkEAHpBfr@@4uEJAQBAACLrCQAAQAAD6@AD6@tiUQkBItEJAyF"
		. "wA+P6PX@@zHA6VL2@@+DRCRkAcdEJCQJAAAAi0QkGIucJNQAAAAPr4QkzAAAAANE"
		. "JBCAPAMDD4ZnAQAAi3QkFItcJDA53g9N3oO8JKwAAAADiVwkIA+OdQEAAItEJBgD"
		. "hCTIAAAAD6+EJMAAAACLVCQQA5QkxAAAAIO8JKwAAAAFD4RsAgAAjTSQi4QksAAA"
		. "AIucJLwAAAAB8A+2XAMCiVwkOIucJLwAAAAPtlwDAYlcJDyLnCS8AAAAD7YEA4lE"
		. "JEiLRCQghcAPhKoBAACLRCRAiXwkLDHbi2wkKIu8JLwAAACJRCRo62KNtCYAAAAA"
		. "OVwkMH5Ii4Qk3AAAAIsUmAHyD7ZEFwIPtkwXAStEJDgrTCQ8D7YUFytUJEgPr8AP"
		. "r8mNBEAPr9KNBIiNBFA5hCS0AAAAcgeDbCRoAXhhg8MBOVwkIA+EogEAADlcJBR+"
		. "n4uEJNgAAACLFJgB8g+2RBcCD7ZMFwErRCQ4K0wkPA+2FBcrVCRID6@AD6@JjQRA"
		. "D6@SjQSIjQRQOYQktAAAAA+DWv@@@4PtAQ+JUf@@@4t8JCyDfCQkCQ+EKfj@@4NE"
		. "JEwB6Try@@+DRCQQAekm+P@@g0QkRAHpEfL@@410JgCF2w+EoAAAAAOEJNQAAACL"
		. "XCRAMdKLbCQoicHrJTlUJDB+Fou0JNwAAACLBJYByPYAAXUFg+sBeJqDwgE5VCQg"
		. "dGo5VCQUftWLtCTYAAAAiwSWAcj2AAJ1xIPtAXm@6XD@@@@HRCQEAwAAAOlB8P@@"
		. "i3wkCMYEBwLpEf3@@8cEJAMAAADpOfD@@8dEJCgAAAAAx0QkFAAAAADpGPX@@4NE"
		. "JBgB6XD3@@+LbCQoi4Qk+AAAAINEJAwBhcAPhMoDAACLVCQYA5QkyAAAAItcJAyL"
		. "RCQQA4QkxAAAAIu0JPgAAADB4hCNi@@@@z8J0IkEjou0JLgAAACF9g+F0gIAAItE"
		. "JCiLdCQ0Keg5nCT8AAAAiQSOD44z8v@@6bb+@@+LfCQs64mLtCSEAAAAjQSQiUQk"
		. "PIX2D4WuAQAAi1wkIItEJFAx9otsJCiF24lEJGgPhFn@@@+LhCTYAAAAi1wkaItU"
		. "JDwDFLCJXCRIa8YWgTv@@@8AiUQkOA+XwA+2wIlEJCyLhCTcAAAAiwSwiYQktAAA"
		. "AIuEJLwAAAAPtkQQAomEJIwAAADB4BCJwYuEJLwAAAAPtkQQAYmEJJAAAADB4AgJ"
		. "yIuMJLwAAAAPtgwRCciJjCSUAAAAiYQkiAAAAOsfD6@SD6@JjRRSD6@AjRSKjQRC"
		. "OccPg70AAACDRCRICItEJDg7hCS0AAAAD4PPAAAAi1QkeIt8JEiDRCQ4AoXSiweL"
		. "fwR0JoX2i5wkiAAAAA9FnCSwAAAAhcAPlMAPtsCJRCQsiZwksAAAAInYicIPtswP"
		. "tsDB6hArjCSQAAAAK4QklAAAAA+20iuUJIwAAACB@@@@@wAPhmX@@@+J+8HrEA+2"
		. "2w+v0g+v2znaD4dp@@@@ifsPttcPr8kPr9I50Q+HVv@@@4n7D7bTD6@AD6@SOdAP"
		. "h0P@@@+LRCQshcB0CYPtAQ+IDf3@@4PGAYNEJGhYOXQkIA+Fe@7@@+nP@f@@i0Qk"
		. "LIXAdeHr1otMJCCLbCQohckPhLX9@@8x9usuOUQkcHwSD6@JOUwkdHwJD6@SOVQk"
		. "bH0Jg+0BD4i3@P@@g8YBOXQkIA+Eg@3@@4uEJNgAAACLVCQ8i5wkvAAAAAMUsIuE"
		. "JNwAAACLBLCJhCSwAAAAi4QkvAAAAIuMJLAAAAAPtkQQAsHpEA+2ySnID7ZMEwGL"
		. "nCSwAAAAD6@AD7bfKdmLnCS8AAAAD7YUEw+2nCSwAAAAKdqB@@@@@wAPh1z@@@8P"
		. "r8mNBEAPr9KNBIiNBFA5xw+CXf@@@+lh@@@@x0QkKAAAAADHRCQUAAAAAOnC9@@@"
		. "i1wkDDmcJPwAAACJ2A+OrfD@@4tcJBgxyYnOidgrhCQEAQAAg8ABD0jBicKJ2Iuc"
		. "JAQBAACNRBj@i1wkCDnDD07Di1wkEInFidgrhCQAAQAAg8ABD0nwidiLnCQAAQAA"
		. "jUQY@4tcJAQ5ww9OwznVicMPjIz7@@+LhCTMAAAAg8UBD6@CA4Qk1AAAAInBjUMB"
		. "iUQkIDnefw+J8IAkAQODwAE7RCQgdfODwgEDjCTMAAAAOep13+lJ+@@@i6wkuAAA"
		. "AIXtD4VK@@@@6TX7@@+QkA=="
		x64 := "QVdBVkFVQVRVV1ZTSIHsyAAAAEhjhCRQAQAASIu8JKgBAACJjCQQAQAAiVQkMESJ"
		. "jCQoAQAAi7QkgAEAAIusJIgBAABJicRIiUQkWEgDhCRgAQAAg@kFSIlEJChIY4Qk"
		. "sAEAAEiNBIdIiUQkYA+E3AUAAIXtD44BDAAARTH2iVwkEIu8JLgBAABEiXQkCIuc"
		. "JBABAABFMe1Mi7QkcAEAAEUx20Ux@0SJbCQYRImEJCABAABMY1QkCEUxyUUxwEwD"
		. "lCR4AQAAhfZ@Mut3Dx9AAEEPr8SJwUSJyJn3@gHBQ4A8AjF0PEmDwAFJY8dBAflB"
		. "g8cBRDnGQYkMhn5DRInYmff9g@sEdckPr4QkOAEAAInBRInImff+Q4A8AjGNDIF1"
		. "xEiLlCRoAQAASYPAAUljxUEB+UGDxQFEOcaJDIJ@vQF0JAiDRCQYAUQDnCTAAQAA"
		. "i0QkGDnFD4VX@@@@RInoi1wkEESLhCQgAQAAD6+EJJABAABEiWwkGMH4ColEJByL"
		. "hCSYAQAAQQ+vx8H4ColEJECDvCQQAQAABA+EtwUAAIuEJDgBAACLvCRAAQAAD6+E"
		. "JEgBAACNBLiLvCQ4AQAAiUQkCESJ4PfYg7wkEAEAAAGNBIeJRCQgD4SxBQAAg7wk"
		. "EAEAAAIPhIQHAACDvCQQAQAAAw+EowoAAIuEJFgBAACFwA+OHwEAAESJfCQQRIuc"
		. "JBABAABBjWwk@0yLfCQoi7wkoAEAAEUx9kUx7YlcJAhEiYQkIAEAAA8fhAAAAAAA"
		. "RYXkD467AAAASWPFMclJicFNjUQHAUwDjCRgAQAA6xhBxgEEg8EBSYPBAUmDwAFB"
		. "OcwPhIkAAABBg@sDf+KFyUEPtlD@D4S1DgAAQQ+2WP45zQ+Euw4AAEUPthCF@w+E"
		. "fAEAAA+28rgGAAAAg+4Bg@4BdhiD+wFAD5TGQYP6AQ+UwAnwD7bAAcCDyASB4v0A"
		. "AAC+AQAAAHQOhdtAD5TGRYXSD5TCCdYJ8IPBAUmDwQFBiEH@SYPAAUE5zA+Fd@@@"
		. "@0UB5UGDxgFEObQkWAEAAA+PKv@@@4tcJAhEi3wkEESLhCQgAQAAg7wkEAEAAAN@"
		. "FouEJKABAACFwA+VwDwBg5wkQAEAAP+LfCQYi3QkHDHARInlRIucJFgBAAA59w9O"
		. "+EQ7fCRAiXwkGEQPTvgrrCS4AQAARCucJMABAACDvCQoAQAACQ+EuQAAAIuEJCgB"
		. "AACD6AGD+AcPh5ACAACD+AOJRCRID46LAgAAiWwkCESJXCQQRTH2x0QkTAAAAACL"
		. "fCRMOXwkCMdEJGgAAAAAD4wNAQAAi3wkaDl8JBAPjNIMAACLfCRIi3QkTItEJAgp"
		. "8ED2xwIPRMaLdCRoicKLRCQQKfBA9scBD0TGg@8DidcPT@gPT8JBicXptgoAAGaQ"
		. "D7bCg+gBg@gCGcCD4AKDwASB4v0AAAAPlMIJ0EGIAekg@v@@iehBjVMBRIlcJAjB"
		. "6B+JbCQQx4QkiAAAAAAAAAAB6MeEJIQAAAABAAAAx0QkbAAAAADR+MdEJHwAAAAA"
		. "QYnFRInYwegfRAHY0fiJx41FAYnGD6@yOdAPTMJFMfaDwAiJtCSkAAAAicYPr@CJ"
		. "tCSoAAAAi7QkpAAAADm0JIgAAAB9HIu0JKgAAAA5dCR8x4QkgAAAAAAAAAAPjEYE"
		. "AACLhCQoAQAAhcAPhV0CAABIg7wkqAEAAAAPhE4CAACLhCTAAQAAD6+EJLgBAACD"
		. "+AEPhDYCAABBg@4BD45dCQAAQY1G@kyLRCRgTIucJKgBAABFMclFMdJIjRyFBAAA"
		. "AEOLdAgEQ4sUCESJ0UOLfAsETInQOdZyE+kJBAAAZpBIg+gBQYsUgDnWcx1BiVSA"
		. "BEGLFIOD6QGD+f9BiVSDBHXeSMfA@@@@@0mDwQRIg8ABSYPCAUk52UGJNIBBiTyD"
		. "dZ9Ei5QkuAEAAIucJMABAABFD6@SD6@bTIuMJKgBAAAx9jHAQYsssYnvRA+33cHv"
		. "EIXAdDJFMcAPH4QAAAAAAEOLDIEPt9FEKdoPr9JEOdJ9DMHpECn5D6@JOdl8E0mD"
		. "wAFEOcB@2Uhj0IPAAUGJLJFIg8YBQTn2f6pIgcTIAAAAW15fXUFcQV1BXkFfw8dE"
		. "JEgAAAAARIlcJAiJbCQQRTH2x0QkTAAAAADpcP3@@4tEJDAx@4P4AkAPlMeJvCSs"
		. "AAAAD4SpAwAAMcCDfCQwAQ+UwEWFwImEJKAAAAAPhNsKAABEiaQkUAEAAEyLlCR4"
		. "AQAARTHJi7wkOAEAAEyLpCRoAQAARTHbTIusJHABAABEi7QkuAEAAESLvCTAAQAA"
		. "iVwkGEGLGkmDwliJ2MHoEEEPr8eZ9@0Pr8eJwQ+3w0EPr8aZ9@6NBIFDiQSMQYtC"
		. "rEGNBENBg8MWQ4lEjQBJg8EBRTnId72LhCSQAQAARIukJFABAACJXCQwi1wkGESJ"
		. "RCQYQQ+vwMH4ColEJBxIi4QkeAEAAMdEJEAAAAAARTH@SIPACEiJBCTpq@r@@0SJ"
		. "8OnE@v@@i3wkMIn4wegQD6+EJMABAACZ9@0Pr4QkOAEAAInBD7fHD6+EJLgBAACZ"
		. "9@6NBIGJRCQw6Wv6@@+J6ESLjCRYAQAARQHAD6@GSJhIA4QkeAEAAEWFyUiJBCQP"
		. "jnL7@@9CjTylAAAAAMdEJBAAAAAAMcDHRCRIAAAAAESJfCR4iXwkUEWF5A+O6QAA"
		. "AEhjVCQISIu8JDABAABFMe1MY3QkSEwDdCQoSI1sFwJMiwwkRTHSD7Z9AA+2df9E"
		. "D7Zd@usmZi4PH4QAAAAAAA+vyQ+v0o0MSQ+vwI0UkY0EQjnDc2hJg8EIMcBFOcIP"
		. "gxsBAABBiwFBi1kEQYPCAonBD7bUD7bAwekQKfJEKdgPtskp+YH7@@@@AHazQYnf"
		. "QcHvEEUPtv8Pr8lFD6@@RDn5d7IPts8Pr9IPr8k5ynelD7bTD6@AD6@SOdB3mLoB"
		. "AAAAuAEAAABDiBQuSYPFAUiDxQRFOewPj0P@@@+LdCRQRAFkJEgBdCQIg0QkEAGL"
		. "VCQgi3wkEAFUJAg5vCRYAQAAD4Xw@v@@RIt8JHjpFvn@@0WF7XgVRDtsJBB@DoX@"
		. "eAo7fCQID464BQAAi0QkbIXAD4WNBQAAg+8Bg4QkgAAAAAGDRCR8AYuUJIQAAAA5"
		. "lCSAAAAAfLqLdCRsifCD4AEBwonwg8ABiZQkhAAAAIPgA4lEJGzpW@v@@w8fRAAA"
		. "icLpQf@@@0yJ0Oka@P@@i0QkMIuMJFgBAAAx9jH@Qo0spQAAAACDwAHB4AeFyYlE"
		. "JDAPjo@5@@9Ei3QkCESLbCQwRYXkflVIi5QkMAEAAExj30wDXCQoSWPGRTHJSI1M"
		. "AgIPthEPtkH@RA+2Uf5rwEtr0iYBwkSJ0MHgBEQp0AHQQTnFQw+XBAtJg8EBSIPB"
		. "BEU5zH@MQQHuRAHng8YBRAN0JCA5tCRYAQAAdZXp9vf@@4noRQHAD6@GweACSJhI"
		. "A4QkeAEAAEiJBCSLhCSYAQAAwfgKg8ABhe2JRCQID46VCgAAi3wkCIuEJMABAADH"
		. "RCRIAAAAAMdEJBgAAAAARImkJFABAACJrCSIAQAAD6@HiXwkUIlEJHiJ+A+vxsHg"
		. "AkiYSIlEJHBIi4QkeAEAAEiJRCRAifjB4AJImEiJRCQQi4QkuAEAAA+vx4lEJBxI"
		. "iwQkSIPACEiJRCQghfYPjiYBAABIi3wkQESLZCQIMe0Ptl8CTItMJCBBvgIAAABE"
		. "D7ZXAUQPth9Bid3rHQ8fAA+v2w+v0o0cWw+vwI0Uk40EQjnBc2pJg8EIRTnwD4Z9"
		. "AAAAQYsBQYtJBEGDxgKJww+21A+2wMHrEEQp0kQp2A+220Qp64H5@@@@AHazQYnP"
		. "QcHvEEUPtv8Pr9tFD6@@RDn7d7IPtt0Pr9IPr9s52nelD7bJD6@AD6@JOch3mGaQ"
		. "i0QkCEgDfCQQA2wkHEQB4EQ55n5lQYnE6UP@@@8PHwCLRCRIRIt0JBhEievB4xBB"
		. "weIIQQnamU1jzkUJ2ve8JIgBAAAPr4QkOAEAAInBieiZ9@5Ii5QkaAEAAI0EgUKJ"
		. "BIpEifCDwAGJRCQYSIuEJHABAABGiRSI64aLfCRQi0QkCItUJHgBVCRISItUJHBI"
		. "AVQkQAH4ObwkiAEAAH4JiUQkUOmk@v@@i0QkGESLpCRQAQAAD6+EJJABAADB+AqJ"
		. "RCQcSIsEJMdEJEAAAAAARTH@i1gEidgPts8PttPB6BAPtsCJxw+v+InID6@Bibwk"
		. "mAAAAImEJJwAAACJ0A+vwomEJJQAAADpffX@@8dEJEAAAAAAx0QkHAAAAABFMf@H"
		. "RCQYAAAAAOn19P@@i5QkWAEAAIXSD4589v@@Q40EZESLdCQIQo0spQAAAAAx9jH@"
		. "SJhIA4QkYAEAAEmJxUWF5H5aSIuUJDABAABJY8ZMY99FMclNAetIjUwCAg8fRAAA"
		. "D7YRSIPBBERr0iYPtlH7a8JLQY0UAkQPtlH6RInQweAERCnQAdDB+AdDiAQLSYPB"
		. "AUU5zH@KQQHuRAHng8YBRAN0JCA5tCRYAQAAdZBIi3wkWDHSQY1sJP9EiXwkSEUx"
		. "0olcJCBBiddIifhIg8ABSIlEJAi4AQAAAEiJxouEJFgBAABIKf6LfCQwSIl0JBBE"
		. "jXD@RYXkD47TAAAASItEJAhNY99Ii3QkKEuNVB0BTo0MGEiLRCQQTAHeTQHpSo0M"
		. "GDHATAHpZi4PH4QAAAAAAEiFwA+EgQMAADnFD4R5AwAARYXSD4RwAwAARTnWD4Rn"
		. "AwAARA+2Qv9ED7Za@rsBAAAAQQH4RTnYckZED7YaRTnYcj1ED7ZZ@0U52HIzRQ+2"
		. "Wf9FOdhyKUQPtln+RTnYch9ED7YZRTnYchZFD7ZZ@kU52HIMRQ+2GUU52A+Sw2aQ"
		. "iBwGSIPAAUiDwgFJg8EBSIPBAUE5xA+PZP@@@0UB50GDwgFEOZQkWAEAAA+FEv@@"
		. "@4tcJCBEi3wkSOmJ8@@@RIuUJLgBAACLnCTAAQAAMcBFD6@SD6@bRYX2D4569@@@"
		. "6RP3@@+DfCRsAQ+E@AEAAIN8JGwCD4S4AgAAQYPtAelX+v@@g4QkiAAAAAHHRCRI"
		. "CQAAAIn4SIu0JGABAABBD6@ERo0MKEljwYA8BgMPhqQBAACLRCQYRDn4QQ9Mx4O8"
		. "JBABAAADiUQkIA+OsAEAAIuEJEgBAACLlCRAAQAAAfhEAeoPr4QkOAEAAIO8JBAB"
		. "AAAFD4TAAgAARI0MkItEJDBIi7QkMAEAAESLVCQgRAHIjVACRYXSSGPSD7Y0Fo1Q"
		. "AUiYSGPSiXQkUEiLtCQwAQAAD7Y0Fol0JHhIi7QkMAEAAA+2BAaJRCRwD4TrAQAA"
		. "i0QkQESJXCQoRTHSi3QkHEyLnCQwAQAAiYQkjAAAAOtyRDu8JJAAAAB+WUiLhCRw"
		. "AQAAQosUkEQByo1CAo1KAUhj0kEPthQTSJhIY8krVCRwQQ+2BANBD7YMCytEJFAr"
		. "TCR4D6@SD6@AD6@JjQRAjQSIjQRQQTnAcgqDrCSMAAAAAXh+SYPCAUQ5VCQgD47P"
		. "AQAARDlUJBhEiZQkkAAAAA+Oe@@@@0iLhCRoAQAAQosUkEQByo1CAo1KAUhj0kEP"
		. "thQTSJhIY8krVCRwQQ+2BANBD7YMCytEJFArTCR4D6@SD6@AD6@JjQRAjQSIjQRQ"
		. "QTnAD4Mo@@@@g+4BD4kf@@@@RItcJCiDfCRICQ+Eavj@@4NEJGgB6Snz@@9Bg8UB"
		. "6Wb4@@+DRCRMAekA8@@@kIXAD4SzAAAARItUJECLdCQcMcnrM0Q7fCQofiJIi5Qk"
		. "cAEAAESJyAMEikiLlCRgAQAA9gQCAXUGQYPqAXiZSIPBATlMJCB+dzlMJBiJTCQo"
		. "fsNIi4QkaAEAAESJygMUiEiLhCRgAQAA9gQQAnWng+4BeaLpX@@@@w8fhAAAAAAA"
		. "uwMAAADpRvH@@8YEBgLp8Pz@@0G6AwAAAOk+8f@@x0QkHAAAAADHRCQYAAAAAOm7"
		. "9f@@g8cB6aD3@@+LdCQcQYPGAUiDvCSoAQAAAA+EHQQAAEljxouUJEgBAABIjQyF"
		. "AAAAAIuEJEABAAAB+sHiEEQB6AnQSIuUJKgBAACJRAr8i5QkKAEAAIXSD4UeAwAA"
		. "i0QkHCnwRDm0JLABAABIi3QkYIlEDvwPjhPz@@@ppf7@@0SLXCQo64aNBJCJRCQo"
		. "i4QkrAAAAIXAD4XjAQAAi0QkIIXAD4Rg@@@@SIsEJIt0JBxFMcnHRCR4AAAAAESJ"
		. "dCRwRIm8JIwAAABEiZwkkAAAAEiJRCRQSIuEJGgBAACLTCQoTIu8JDABAABMi1Qk"
		. "UEyLhCRwAQAARItcJHhCAwyIQYE6@@@@AEeLBIiNUQKNQQFIY8lBD5fGSGPSSJhF"
		. "D7b2QQ+2FBdBD7YEB4mUJLQAAACJhCS4AAAAweIQweAICdBBD7YUDwnQiZQkvAAA"
		. "AImEJLAAAADrHg+v0g+vyY0UUg+vwI0Uio0EQjnDD4OvAAAASYPCCEU5ww+D4AAA"
		. "AESLvCSgAAAAQYPDAkGLAkGLWgRFhf90Hk2FyYtUJDAPRJQksAAAAEUx9oXAQQ+U"
		. "xolUJDCJ0InCD7bMD7bAweoQK4wkuAAAACuEJLwAAAAPttIrlCS0AAAAgfv@@@8A"
		. "D4Z0@@@@QYnfQcHvEEUPtv8Pr9JFD6@@RDn6D4dz@@@@D7bXD6@JD6@SOdEPh2L@"
		. "@@8PttMPr8APr9I50A+HUf@@@0WF9nQFg+4BeDtJg8EBSINEJFBYg0QkeBZEOUwk"
		. "IA+Pkf7@@0SLdCRwRIu8JIwAAABEi5wkkAAAAOmu@f@@RYX2dcfrwESLdCRwRIu8"
		. "JIwAAABEi5wkkAAAAOml@P@@i0QkIIt0JByFwA+Eff3@@0Ux0us5OYQkmAAAAHwY"
		. "D6@JOYwknAAAAHwMD6@SOZQklAAAAH0Jg+4BD4hm@P@@SYPCAUQ5VCQgD44@@f@@"
		. "SIuEJGgBAACLVCQoTIuMJDABAABCAxSQSIuEJHABAABCiwSQicGNQgKJTCQwwekQ"
		. "SJgPtslBD7YEASnIjUoBSGPSD6@ASGPJRQ+2DAlIi0wkMA+2zUEpyUSJyUyLjCQw"
		. "AQAAQQ+2FBFED7ZMJDBEKcqB+@@@@wAPh0r@@@8Pr8mNBEAPr9KNBIiNBFA5ww+C"
		. "VP@@@+lY@@@@x0QkHAAAAADHRCQYAAAAAOlF9@@@RDm0JLABAABEifAPjhvx@@+J"
		. "+CuEJMABAABFMdKDwAFBD0jCicGLhCTAAQAAjUQH@0E5w0EPTsOJxkSJ6CuEJLgB"
		. "AACDwAFED0nQi4QkuAEAAEGNRAX@OcUPTsU5zolEJCAPjEH7@@9EieJJY8IPr9FI"
		. "Y9JIAdBIA4QkYAEAAEmJwY1GAYlEJCiLRCQgRCnQSI1wAUQ7VCQgfxNKjRQOTInI"
		. "gCADSIPAAUg50HX0g8EBTANMJFg7TCQoddjp6Pr@@4uMJCgBAACFyQ+FQf@@@+nU"
		. "+v@@kJCQkJCQkJCQkJCQkA=="
		MyFunc := this.mCode(strReplace((A_PtrSize=8?x64:x32),"@","/"))
		}
		text := j[1], w := j[2], h := j[3]
		, err1 := floor(j[4] ? j[5] : ini.err1)
		, err0 := floor(j[4] ? j[6] : ini.err0)
		, mode := j[7], color := j[8], n := j[9]
		resultObj := (!ini.bits.scan0 || mode<1 || mode>5) ? 0
			: dllCall(MyFunc.ptr, "int",mode, "uint",color, "uint",n, "int",dir
			, "Ptr",ini.bits.scan0, "int",ini.bits.stride
			, "int",sx, "int",sy, "int",sw, "int",sh
			, "Ptr",ini.ss, "Ptr",ini.s1, "Ptr",ini.s0
			, "Ptr",text, "int",w, "int",h
		, "int",floor(abs(err1)*1024), "int",floor(abs(err0)*1024)
		, "int",(err1<0||err0<0), "Ptr",ini.allpos, "int",ini.allpos_max
		, "int",floor(w*ini.zoomW), "int",floor(h*ini.zoomH))
		return resultObj
	}


	picInfo(text) {
		local
		if !inStr(text, "$")
			return
		static init, info, bmp
		if !varSetCapacity(init) && (init := "1")
			info := [], bmp := []
		key := (r := strLen(v := trim(text,"|")))<10000 ? v
			: dllCall("ntdll\RtlComputeCrc32", "uint",0
			, "Ptr",&v, "uint",r*(1+!!A_IsUnicode), "uint")
		if info.hasKey(key)
			return info[key]
		comment := "", seterr := err1 := err0 := 0
		; You Can Add Comment Text within The <>
		if regExMatch(v, "O)<([^>\n]*)>", r)
		v := strReplace(v,r[0]), comment := trim(r[1])
		; You can Add two fault-tolerant in the [], separated by commas
		if regExMatch(v, "O)\[([^\]\n]*)]", r)
		{
		v := strReplace(v,r[0]), r := strSplit(r[1] ",", ",")
		, seterr := 1, err1 := r[1], err0 := r[2]
		}
		color := subStr(v,1,inStr(v,"$")-1), v := trim(subStr(v,inStr(v,"$")+1))
		mode := inStr(color,"##") ? 5 : inStr(color,"#") ? 4
			: inStr(color,"**") ? 3 : inStr(color,"*") ? 2 : 1
		color := regExReplace(strReplace(color,"@","-"), "[*#\s]")
		(mode=1 || mode=5) && color := strReplace(color,"0x")
		if (mode=5) {
			if !(v~="^[\s\-\w.]+/[\s\-\w.]+/[\s\-\w./,]+$")  ; <FindPic>
			{
				if !(hBM := LoadPicture(v))
				{
				msgBox, 4096, Tip, Can't Load Picture ! %v%
					return
				}
				this.getBitmapWH(hBM, w, h)
				if (w<1 || h<1)
					return
				hBM2 := this.createDIBSection(w, h, 32, Scan0)
				this.copyHBM(hBM2, 0, 0, hBM, 0, 0, w, h)
				dllCall("DeleteObject", "Ptr",hBM)
				if (!Scan0)
					return
				arr := strSplit(color "/", "/"), arr.pop(), n := arr.length()
				bmp.push(buf := this.buffer(w*h*4 + n*2*4)), v := buf.ptr, p := v+w*h*4-4
				dllCall("RtlMoveMemory", "Ptr",v, "Ptr",Scan0, "Ptr",w*h*4)
				dllCall("DeleteObject", "Ptr",hBM2), color := trim(arr[1],"-")
				for k1,v1 in arr
				c := strSplit(trim(v1,"-") "-" color, "-")
				, x := floor(c[2]), x := (x <= 0||x>1?0:floor(9*255*255*(1-x)*(1-x)))
				, numPut(this.toRGB(c[1]), 0|p += 4, "uint")
				, numPut((inStr(c[2],".")?x:floor("0x" c[2])|0x1000000), 0|p += 4, "uint")
				color := 2
			} else {
				; <FindMultiColor> or <FindColor> or <FindShape>
				color := trim(strSplit(color "/", "/")[1], "-")
				arr := strSplit(trim(regExReplace(v, "i)\s|0x"), ","), ",")
				if !(n := arr.length())
					return
				bmp.push(buf := this.buffer(n*22*4)), v := buf.ptr
				shape := (n>1 && strLen(strSplit(arr[1] "//","/")[3])=1 ? 1:0)
				for k1,v1 in arr {
					r := strSplit(v1 "/","/"), x := floor(r[1]), y := floor(r[2])
						, (A_Index=1) ? (x1 := x2 := x, y1 := y2 := y)
						: (x1 := min(x1,x), x2 := max(x2,x), y1 := min(y1,y), y2 := max(y2,y))
				}
				for k1,v1 in arr {
					r := strSplit(v1 "/","/"), x := floor(r[1])-x1, y := floor(r[2])-y1
					, numPut(y<<16|x, 0|p := v+(A_Index-1)*22*4, "uint")
					, numPut(n1 := min(max(r.length()-3,0),(shape?1:10)), 0|p += 4, "uint")
					loop % n1
						c := strSplit(trim(v1 := r[2+A_Index],"-") "-" color, "-")
						, x := floor(c[2]), x := (x <= 0||x>1?0:floor(9*255*255*(1-x)*(1-x)))
						, numPut(this.toRGB(c[1])&0xFFFFFF|(!shape&&inStr(v1,"-")=1?0x1000000:0), 0|p += 4, "uint")
						, numPut((inStr(c[2],".")?x:floor("0x" c[2])|0x1000000), 0|p += 4, "uint")
				}
				color := shape, w := x2-x1+1, h := y2-y1+1
			}
		} else { 
			r := strSplit(v ".", "."), w := floor(r[1])
			, v := this.base64tobit(r[2]), h := strLen(v)//w
			if (w<1 || h<1 || strLen(v) != w*h)
				return
			arr := strSplit(color "/", "/"), arr.pop(), n := arr.length()
				, bmp.push(buf := this.buffer(StrPut(v, "CP0") + n*2*4))
				, StrPut(v, buf.ptr, "CP0"), v := buf.ptr, p := v+w*h-4
			, color := floor(color)
				if (mode=1) {
				for k1,v1 in arr
				c := strSplit(trim(v1,"-") "-", "-")
				, x := floor(c[2]), x := (x <= 0||x>1?0:floor(9*255*255*(1-x)*(1-x)))
				, numPut(this.toRGB(c[1]), 0|p += 4, "uint")
				, numPut((inStr(c[2],".")?x:floor("0x" c[2])|0x1000000), 0|p += 4, "uint")
				}
				else if (mode=4) {
					r := strSplit(trim(arr[1],"-") "-", "-")
					, n := floor(r[2]), n := (n <= 0||n>1?0:floor(9*255*255*(1-n)*(1-n)))
					, c := floor(r[1]), color := (c<1||c>w*h?0:((c-1)//w)<<16|mod(c-1,w))
				}
		}
		return info[key] := [v, w, h, seterr, err1, err0, mode, color, n, comment]
	}
	
	; color can use: RRGGBB, Red, Yellow, Black, White
	toRGB(color) {
		static init, tab
		if !varSetCapacity(init) && (init := "1")
		tab := Object("Black", "000000", "White", "FFFFFF"
		, "Red", "FF0000", "Green", "008000", "Blue", "0000FF"
		, "Yellow", "FFFF00", "Silver", "C0C0C0", "Gray", "808080"
		, "Teal", "008080", "Navy", "000080", "Aqua", "00FFFF"
		, "Olive", "808000", "Lime", "00FF00", "Fuchsia", "FF00FF"
		, "Purple", "800080", "Maroon", "800000")
		return floor("0x" (tab.hasKey(color)?tab[color]:color))
	}

	buffer(size, FillByte := "") {
		local
		buf := {}, buf.setCapacity("_key", size), p := buf.getAddress("_key")
		, (FillByte != "" && dllCall("RtlFillMemory","Ptr",p,"Ptr",size,"uchar",FillByte))
		, buf.ptr := p, buf.size := size
		return buf
	}

	getBitsFromScreen(ByRef x := 0, ByRef y := 0, ByRef w := 0, ByRef h := 0
	, ScreenShot := 1, ByRef zx := 0, ByRef zy := 0, ByRef zw := 0, ByRef zh := 0) {
		local
		static init, CAPTUREBLT
		if !varSetCapacity(init) && (init := "1") {
			dllCall("Dwmapi\DwmIsCompositionEnabled", "Int*",i := 0)
		CAPTUREBLT := i ? 0 : 0x40000000
		}
		if inStr(A_OSVersion, ".")
		try dllCall("SetThreadDpiAwarenessContext", "Ptr",-3, "Ptr")
		(!isObject(this.bits) && this.bits := {Scan0:0, hBM:0, oldzw:0, oldzh:0})
		, bits := this.bits
		if (!ScreenShot && bits.Scan0) {
			zx := bits.zx, zy := bits.zy, zw := bits.zw, zh := bits.zh
		, w := min(x+w,zx+zw), x := max(x,zx), w -= x
		, h := min(y+h,zy+zh), y := max(y,zy), h -= y
			return bits
		}
		bch := A_BatchLines, cri := A_Iscritical
		critical
		bits.bindWindow := id := this.bindWindow(0,0,1)
		if (id) {
		winGet, id, ID, ahk_id %id%
		winGetPos, zx, zy, zw, zh, ahk_id %id%
		}
		if (!id) {
		sysGet, zx, 76
		sysGet, zy, 77
		sysGet, zw, 78
		sysGet, zh, 79
		}
		this.updateBits(bits, zx, zy, zw, zh)
		, w := min(x+w,zx+zw), x := max(x,zx), w -= x
		, h := min(y+h,zy+zh), y := max(y,zy), h -= y
		if (!ScreenShot || w<1 || h<1 || !bits.hBM) {
			critical % cri
			setBatchLines, % bch
			return bits
		}
		if isFunc(k := "getBitsFromScreen2")
		&& %k%(bits, x-zx, y-zy, w, h)
		{
		; Get the bind window use bits.bindWindow
		; Each small range of data obtained from DXGI must be
		; copied to the screenshot cache using find().copyBits()
			zx := bits.zx, zy := bits.zy, zw := bits.zw, zh := bits.zh
			critical % cri
			setBatchLines, % bch
			return bits
		}
		mDC := dllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
		oBM := dllCall("SelectObject", "Ptr",mDC, "Ptr",bits.hBM, "Ptr")
		if (id) {
			if (mode := this.bindWindow(0,0,0,1))<2
			{
			hDC := dllCall("GetDCEx", "Ptr",id, "Ptr",0, "int",3, "Ptr")
			dllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
				, "Ptr",hDC, "int",x-zx, "int",y-zy, "uint",0xCC0020|CAPTUREBLT)
			dllCall("ReleaseDC", "Ptr",id, "Ptr",hDC)
			 } else { 
			hBM2 := this.createDIBSection(zw, zh)
			mDC2 := dllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
			oBM2 := dllCall("SelectObject", "Ptr",mDC2, "Ptr",hBM2, "Ptr")
			dllCall("UpdateWindow", "Ptr",id)
			; RDW_INVALIDATE=0x1|RDW_ERASE=0x4|RDW_ALLCHILDREN=0x80|RDW_FRAME=0x400
			; dllCall("RedrawWindow", "Ptr",id, "Ptr",0, "Ptr",0, "uint", 0x485)
			dllCall("PrintWindow", "Ptr",id, "Ptr",mDC2, "uint",(mode>3)*3)
			dllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
				, "Ptr",mDC2, "int",x-zx, "int",y-zy, "uint",0xCC0020)
			dllCall("SelectObject", "Ptr",mDC2, "Ptr",oBM2)
			dllCall("DeleteDC", "Ptr",mDC2)
			dllCall("DeleteObject", "Ptr",hBM2)
			}
		 } else { 
			hDC := dllCall("GetWindowDC","Ptr",id := dllCall("GetDesktopWindow","Ptr"),"Ptr")
			dllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
			, "Ptr",hDC, "int",x, "int",y, "uint",0xCC0020|CAPTUREBLT)
			dllCall("ReleaseDC", "Ptr",id, "Ptr",hDC)
		}
		dllCall("SelectObject", "Ptr",mDC, "Ptr",oBM)
		dllCall("DeleteDC", "Ptr",mDC)
		critical % cri
		setBatchLines, % bch
		return bits
	}

	updateBits(bits, zx, zy, zw, zh) {
		local
		if (zw>bits.oldzw || zh>bits.oldzh || !bits.hBM) {
			try dllCall("DeleteObject", "Ptr",bits.hBM)
			bits.hBM := this.createDIBSection(zw, zh, bpp := 32, ppvBits)
			, bits.scan0 := (!bits.hBM ? 0:ppvBits)
			, bits.stride := ((zw*bpp+31)//32)*4
			, bits.oldzw := zw, bits.oldzh := zh
		}
		bits.zx := zx, bits.zy := zy, bits.zw := zw, bits.zh := zh
	}

	createDIBSection(w, h, bpp := 32, ByRef ppvBits := 0) {
		local
		varSetCapacity(bi, 40, 0), numPut(40, bi, 0, "int")
		, numPut(w, bi, 4, "int"), numPut(-h, bi, 8, "int")
		, numPut(1, bi, 12, "short"), numPut(bpp, bi, 14, "short")
		return dllCall("CreateDIBSection", "Ptr",0, "Ptr",&bi
		, "int",0, "Ptr*",ppvBits := 0, "Ptr",0, "int",0, "Ptr")
	}
	
	getBitmapWH(hBM, ByRef w, ByRef h) {
		local
		varSetCapacity(bm, size := (A_PtrSize=8 ? 32:24), 0)
		, dllCall("GetObject", "Ptr",hBM, "int",size, "Ptr",&bm)
		, w := numGet(bm,4,"int"), h := abs(numGet(bm,8,"int"))
	}

	copyHBM(hBM1, x1, y1, hBM2, x2, y2, w, h, Clear := 0) {
		local
		if (w<1 || h<1 || !hBM1 || !hBM2)
			return
		mDC1 := dllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
		oBM1 := dllCall("SelectObject", "Ptr",mDC1, "Ptr",hBM1, "Ptr")
		mDC2 := dllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
		oBM2 := dllCall("SelectObject", "Ptr",mDC2, "Ptr",hBM2, "Ptr")
			dllCall("BitBlt", "Ptr",mDC1, "int",x1, "int",y1, "int",w, "int",h
			, "Ptr",mDC2, "int",x2, "int",y2, "uint",0xCC0020)
		if (Clear)
			dllCall("BitBlt", "Ptr",mDC1, "int",x1, "int",y1, "int",w, "int",h
			, "Ptr",mDC1, "int",x1, "int",y1, "uint",MERGECOPY := 0xC000CA)
		dllCall("SelectObject", "Ptr",mDC1, "Ptr",oBM1)
		dllCall("DeleteDC", "Ptr",mDC1)
		dllCall("SelectObject", "Ptr",mDC2, "Ptr",oBM2)
		dllCall("DeleteDC", "Ptr",mDC2)
	}

	copyBits(Scan01,Stride1,x1,y1,Scan02,Stride2,x2,y2,w,h,Reverse := 0) {
		local
		if (w<1 || h<1 || !Scan01 || !Scan02)
			return
		static init, MFCopyImage
		if (!varSetCapacity(init) && (init := "1")) {
			MFCopyImage := dllCall("GetProcAddress", "Ptr"
			, dllCall("LoadLibrary", "Str","Mfplat.dll", "Ptr")
			, "AStr","MFCopyImage", "Ptr")
		}
		if (MFCopyImage && !Reverse) {
			return dllCall(MFCopyImage
			, "Ptr",Scan01+y1*Stride1+x1*4, "int",Stride1
			, "Ptr",Scan02+y2*Stride2+x2*4, "int",Stride2
			, "uint",w*4, "uint",h)
		}
		listLines % (lls := A_listLines)?0:0
		setBatchLines, % (bch := A_BatchLines)?"-1":"-1"
		p1 := Scan01+(y1-1)*Stride1+x1*4
		, p2 := Scan02+(y2-1)*Stride2+x2*4, w *= 4
		, (Reverse) && (p2 += (h+1)*Stride2, Stride2 := -Stride2)
		loop % h
		dllCall("RtlMoveMemory","Ptr",p1 += Stride1,"Ptr",p2 += Stride2,"Ptr",w)
		setBatchLines, % bch
		listLines % lls
	}
	
	; Bind the window so that it can find images when obscured
	; by other windows, it's equivalent to always being
	; at the front desk. Unbind Window using find().bindWindow(0)
	bindWindow(bind_id := 0, bind_mode := 0, get_id := 0, get_mode := 0) {
		local
		(!isObject(this.bind) && this.bind := {id:0, mode:0, oldStyle:0})
		, bind := this.bind
		if (get_id)
			return bind.id
		if (get_mode)
			return bind.mode
		if (bind_id) {
		bind.id := bind_id := floor(bind_id)
			, bind.mode := bind_mode, bind.oldStyle := 0
			if (bind_mode & 1) {
			winGet, i, ExStyle, ahk_id %bind_id%
			bind.oldStyle := i
			winSet, Transparent, 255, ahk_id %bind_id%
			loop 30
			{
			sleep 100
			winGet, i, Transparent, ahk_id %bind_id%
			}
			Until (i=255)
			}
		 } else { 
			bind_id := bind.id
			if (bind.mode & 1)
			winSet, ExStyle, % bind.oldStyle, ahk_id %bind_id%
			bind.id := 0, bind.mode := 0, bind.oldStyle := 0
		}
	}
	
	mCode(hex) {
		local
		flag := ((hex~="[^A-Fa-f\d\s]") ? 1:4), len := 0
		loop 2
			if !dllCall("crypt32\CryptStringToBinary", "Str",hex, "uint",0, "uint",flag
			, "Ptr",(A_Index=1?0:(p := this.buffer(len)).Ptr), "uint*",len, "Ptr",0, "Ptr",0)
			return
		if dllCall("VirtualProtect", "Ptr",p.ptr, "Ptr",len, "uint",0x40, "uint*",0)
			return p
	}

	bin2hex(addr, size, base64 := 0) {
		local
		flag := (base64 ? 1:4)|0x40000000, len := 0
		loop 2
			dllCall("crypt32\CryptBinaryToString", "Ptr",addr, "uint",size, "uint",flag
			, "Ptr",(A_Index=1?0:(p := this.buffer(len*2)).Ptr), "uint*",len)
		return regExReplace(StrGet(p.ptr, len), "\s+")
	}

	base64tobit(s) {
		local
		listLines % (lls := A_listLines)?0:0
		Chars := "0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
		setFormat, IntegerFast, d
		loop parse, Chars
			if inStr(s, A_LoopField, 1)
			s := regExReplace(s, "[" A_LoopField "]", ((i := A_Index-1)>>5&1)
			. (i>>4&1) . (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1))
		s := regExReplace(regExReplace(s,"[^01]+"),"10*$")
		listLines % lls
		return s
	}

	bit2base64(s) {
		local
		listLines % (lls := A_listLines)?0:0
		s := regExReplace(s,"[^01]+")
		s .= subStr("100000",1,6-mod(strLen(s),6))
		s := regExReplace(s,".{6}","|$0")
		Chars := "0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
		setFormat, IntegerFast, d
		loop parse, Chars
			s := strReplace(s, "|" . ((i := A_Index-1)>>5&1)
			. (i>>4&1) . (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1), A_LoopField)
		listLines % lls
		return s
	}

	ASCII(s) {
		local
		if regExMatch(s, "O)\$(\d+)\.([\w+/]+)", r)
		{
		s := regExReplace(this.base64tobit(r[2]),".{" r[1] "}","$0`n")
			s := strReplace(strReplace(s,"0","_"),"1","0")
		}
		else s := ""
		return s
	}

	; Screenshot and retained as the last screenshot.
	screenShot(x1 := 0, y1 := 0, x2 := 0, y2 := 0) {
		this.find(x1, y1, x2, y2)
	}
	
	; Get the RGB color of a point from the last screenshot.
	; if the point to get the color is beyond the range of
	; Screen, it will return White color (0xFFFFFF).
	getColor(x, y, fmt := 1) {
		local
		bits := this.getBitsFromScreen(,,,,0,zx,zy,zw,zh), x -= zx, y -= zy
		, c := (x >= 0 && x<zw && y >= 0 && y<zh && bits.Scan0)
		? numGet(bits.Scan0+y*bits.Stride+x*4,"uint") : 0xFFFFFF
		return (fmt ? format("0x{:06X}",c&0xFFFFFF) : c)
	}

	; Identify a line of text or verification code
	; based on the result returned by find().
	; offsetX is the maximum interval between two texts,
	; if it exceeds, a "*" sign will be inserted.
	; offsetY is the maximum height difference between two texts.
	; overlapW is used to set the width of the overlap.
	; return Association array {text:Text, x:X, y:Y, w:W, h:H}
	
	resultMerge(resultObj, offsetX := 20, offsetY := 20, overlapW := 0) {
		local
		ocr_Text := ocr_X := ocr_Y := min_X := dx := ""
		for k,v in resultObj
			x := v.1
			, min_X := (A_Index=1 || x<min_X ? x : min_X)
			, max_X := (A_Index=1 || x>max_X ? x : max_X)
		while (min_X != "" && min_X <= max_X) {
			LeftX := ""
			for k,v in resultObj {
				x := v.1, y := v.2
				if (x<min_X) || (ocr_Y != "" && abs(y-ocr_Y)>offsetY) {
					continue
				}
				; Get the leftmost X coordinates
				if (LeftX="" || x<LeftX) {
					LeftX := x, LeftY := y, LeftW := v.3, LeftH := v.4, LeftOCR := v.id
				}
			}
			if (LeftX="")
				break
			if (ocr_X="")
				ocr_X := LeftX, min_Y := LeftY, max_Y := LeftY+LeftH
			; if the interval exceeds the set value, add "*" to the result
			ocr_Text .= (ocr_Text != "" && LeftX>dx ? "*":"") . LeftOCR
			; Update for next search
			min_X := LeftX+LeftW-(overlapW>LeftW//2 ? LeftW//2:overlapW)
			, dx := LeftX+LeftW+offsetX, ocr_Y := LeftY
			, (LeftY<min_Y && min_Y := LeftY)
			, (LeftY+LeftH>max_Y && max_Y := LeftY+LeftH)
		}
		(ocr_X="") && ocr_X := min_Y := min_X := max_Y := 0
		return {text:ocr_Text, x:ocr_X, y:min_Y, w:min_X-ocr_X, h:max_Y-min_Y}
	}

	; Sort the results of find() from left to right
	; and top to bottom, ignore slight height difference

	sort(resultObj, dy := 10) {
		local
		if !isObject(resultObj)
			return resultObj
		s := "", n := 150000, ypos := []
		for k,v in resultObj
		{
			x := v.x, y := v.y, add := 1
			for k1,v1 in ypos
		if abs(y-v1) <= dy
		{
				y := v1, add := 0
				break
			}
			if (add)
			ypos.push(y)
		s .= (y*n+x) "." k "|"
		}
		s := trim(s,"|")
		sort, s, N D|
		resultObj2 := []
		for k,v in strSplit(s,"|")
		resultObj2.push(resultObj[subStr(v,inStr(v,".")+1)])
		return resultObj2
	}

	; Sort the results of find() according to the nearest distance
	
	sort2(resultObj, px, py) {
		local
		if !isObject(resultObj)
			return resultObj
		s := ""
		for k,v in resultObj
		s .= ((v.x-px)**2+(v.y-py)**2) "." k "|"
		s := trim(s,"|")
		sort, s, N D|
		resultObj2 := []
		for k,v in strSplit(s,"|")
		resultObj2.push(resultObj[subStr(v,inStr(v,".")+1)])
		return resultObj2
	}

	; Sort the results of find() according to the search direction
	
	sort3(resultObj, dir := 1) {
		local
		if !isObject(resultObj)
			return resultObj
		s := "", n := 150000
		for k,v in resultObj
			x := v.1, y := v.2
		, s .= (dir=1 ? y*n+x
			: dir=2 ? y*n-x
			: dir=3 ? -y*n+x
			: dir=4 ? -y*n-x
			: dir=5 ? x*n+y
			: dir=6 ? x*n-y
			: dir=7 ? -x*n+y
			: dir=8 ? -x*n-y : y*n+x) "." k "|"
		s := trim(s,"|")
		sort, s, N D|
		resultObj2 := []
		for k,v in strSplit(s,"|")
		resultObj2.push(resultObj[subStr(v,inStr(v,".")+1)])
		return resultObj2
	}

	; Wait for the screen image to change within a few seconds
	; Take a Screenshot before using it: find().screenShot()

	waitChange(time := -1, x1 := 0, y1 := 0, x2 := 0, y2 := 0) {
		local
		hash := this.getPicHash(x1, y1, x2, y2, 0)
		time := floor(time), timeout := A_TickCount+round(time*1000)
		loop
		{
		if (hash != this.getPicHash(x1, y1, x2, y2, 1))
				return 1
		if (time >= 0 && A_TickCount >= timeout)
				break
		sleep 10
		}
		return 0
	}

	waitNotChange(time := 1, timeout := 30, x1 := 0, y1 := 0, x2 := 0, y2 := 0) {
		local
		oldhash := "", time := floor(time)
		, timeout := A_TickCount+round(floor(timeout)*1000)
		loop
		{
			hash := this.getPicHash(x1, y1, x2, y2, 1), t := A_TickCount
			if (hash != oldhash)
				oldhash := hash, timeout2 := t+round(time*1000)
			if (t >= timeout2)
			return 1
		if (t >= timeout)
			return 0
		sleep 100
		}
	}

	
	; It is not like graphicsearch always use Screen Coordinates,
	; But like built-in command imageSearch using CoordMode Settings
	; ImageFile can use "*n *TransBlack/White/RRGGBB-DRDGDB... d:\a.bmp"

	imageSearch(x1 := 0, y1 := 0, x2 := 0, y2 := 0
	, ImageFile := "", ScreenShot := 1, FindAll := 0, dir := 1) {
		local
		dx := dy := 0
		if (A_CoordModePixel="Window")
		this.windowToScreen(dx, dy, 0, 0)
		else if (A_CoordModePixel="Client")
		this.clientToScreen(dx, dy, 0, 0)
		text := ""
		loop parse, ImageFile, |
		if (v := trim(A_LoopField)) != ""
		{
		text .= inStr(v,"$") ? "|" v : "|##"
			. (regExMatch(v, "O)(^|\s)\*(\d+)\s", r)
			? format("{:06X}", r[2]<<16|r[2]<<8|r[2]) : "000000")
		. (regExMatch(v, "Oi)(^|\s)\*Trans(\S+)\s", r) ? "/" trim(r[2],"/"):"")
		. "$" trim(regExReplace(v,"(^|\s)\*\S+"))
		}
		x1 := floor(x1), y1 := floor(y1), x2 := floor(x2), y2 := floor(y2)
		if (x1=0 && y1=0 && x2=0 && y2=0)
			n := 150000, x1 := y1 := -n, x2 := y2 := n
		if (resultObj := this.find(,, x1+dx, y1+dy, x2+dx, y2+dy
		, 0, 0, text, ScreenShot, FindAll,,,, dir))
		{
		for k,v in resultObj  ; you can use resultObj := find().resultObj
			v.1 -= dx, v.2 -= dy, v.x -= dx, v.y -= dy
			rx := resultObj[1].1, ry := resultObj[1].2, ErrorLevel := 0
			return resultObj
		 } else { 
			rx := ry := "", ErrorLevel := 1
			return 0
		}
	}
	
	; It is not like graphicsearch always use Screen Coordinates,
	; But like built-in command pixelSearch using CoordMode Settings
	; ColorID can use "RRGGBB-DRDGDB|RRGGBB-DRDGDB", Variation in 0-255

	pixelSearch(x1 := 0, y1 := 0, x2 := 0, y2 := 0
		, ColorID := "", Variation := 0, ScreenShot := 1, FindAll := 0, dir := 1) {
		local
		n := floor(Variation), text := format("##{:06X}$0/0/", n<<16|n<<8|n)
		. trim(strReplace(ColorID, "|", "/"), "- /")
		return this.imageSearch(rx, ry, x1, y1, x2, y2, text, ScreenShot, FindAll, dir)
	}
	
	; Pixel count of certain colors within the range indicated by Screen Coordinates
	; ColorID can use "RRGGBB-DRDGDB|RRGGBB-DRDGDB", Variation in 0-255

	pixelCount(x1 := 0, y1 := 0, x2 := 0, y2 := 0, ColorID := "", Variation := 0, ScreenShot := 1) {
		local
		x1 := floor(x1), y1 := floor(y1), x2 := floor(x2), y2 := floor(y2)
		if (x1=0 && y1=0 && x2=0 && y2=0)
			n := 150000, x := y := -n, w := h := 2*n
		else
			x := min(x1,x2), y := min(y1,y2), w := abs(x2-x1)+1, h := abs(y2-y1)+1
		bits := this.getBitsFromScreen(x,y,w,h,ScreenShot,zx,zy), x -= zx, y -= zy
		sum := 0, varSetCapacity(s1,4), varSetCapacity(s0,4), varSetCapacity(ss,w*(h+3))
		ini := { bits:bits, ss:&ss, s1:&s1, s0:&s0, allpos:0, allpos_max:0
		, err1:0, err0:0, zoomW:1, zoomH:1 }
		n := floor(Variation), text := format("##{:06X}$0/0/", n<<16|n<<8|n)
		. trim(strReplace(ColorID, "|", "/"), "- /")
		if isObject(j := this.picInfo(text))
		sum := this.picFind(ini, j, 1, x, y, w, h)
		return sum
	}
}
