class graphicsearch {

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
	resultSort(param_resultsObj, param_dy := 10) {
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
			; If this is a new y position, add it to ypos
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
		
		; Return hash in hexadecimal format
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
	

	addZero(i) {
		if i is number
			return i+0
		else return 0
	}

	__New() {
		this.bits := { Scan0: 0, hBM: 0, oldzw: 0, oldzh: 0 }
		this.bind := { id: 0, mode: 0, oldStyle: 0 }
		this.Lib := []
		this.Cursor := 0
	}

	__Delete() {
		if (this.bits.hBM)
			try DllCall("DeleteObject", "Ptr",this.bits.hBM)
	}


	find(x1 := 0, y1 := 0, x2 := 0, y2 := 0, err1 := 0, err0 := 0, text := ""
	, ScreenShot := 1, FindAll := 1, Joinquery := 0, offsetX := 20, offsetY := 10
	, dir := 1, zoomW := 1, zoomH := 1) {
		local
		
		setBatchLines, % (bch := A_BatchLines)?"-1":"-1"
		x1 := this.addZero(x1), y1 := this.addZero(y1), x2 := this.addZero(x2), y2 := this.addZero(y2)
		if (x1=0 && y1=0 && x2=0 && y2=0)
			n := 150000, x := y := -n, w := h := 2*n
		else
			x := min(x1,x2), y := min(y1,y2), w := abs(x2-x1)+1, h := abs(y2-y1)+1
		bits := this.getBitsFromScreen(x,y,w,h,ScreenShot,zx,zy), x-=zx, y-=zy
		, this.resultObj := 0, info := []
		loop, parse, text, |
			if (isObject(j := this.PicInfo(A_LoopField))) {
				info.push(j)
			}
		if ((w<1 || h<1 || !(num := info.length()) || !bits.Scan0)) {
			setBatchLines, % bch
			return this.noMatchVal
		}
		arr := [], info2 := [], k := 0, s := ""
		, mode := (isObject(JoinText) ? 2 : JoinText ? 1 : 0)
		for i,j in info {
			k := max(k, (j[7]=5 && j[8]=0 ? j[9] : j[2]*j[3]))
			if (mode)
			v := (mode=1 ? i : j[10]) . "", s.="|" v
			, (v!="") && ((!info2.hasKey(v) && info2[v]:=[]), info2[v].push(j))
		}
		sx := x, sy := y, sw := w, sh := h
		, (mode=1 && Joinquery := [s])
		, varSetCapacity(s1,k*4), varSetCapacity(s0,k*4), varSetCapacity(ss,sw*(sh+3))
		, allpos_max := (FindAll || JoinText ? 10240 : 1)
		, ini := { sx:sx, sy:sy, sw:sw, sh:sh, zx:zx, zy:zy
		, mode:mode, bits:bits, ss:&ss, s1:&s1, s0:&s0
		, err1:err1, err0:err0, allpos_max:allpos_max
		, zoomW:zoomW, zoomH:zoomH }
		loop, 2
		{
			if (err1=0 && err0=0) && (num>1 || A_Index>1)
			ini.err1 := err1 := 0.05, ini.err0 := err0 := 0.05
			if (!JoinText) {
			varSetCapacity(allpos, allpos_max*4), allpos_ptr := &allpos
			for i,j in info
			loop, % this.PicFind(ini, j, dir, sx, sy, sw, sh, allpos_ptr)
			{
				pos := numGet(allpos, 4*(A_Index-1), "uint")
				, x := (pos&0xFFFF)+zx, y := (pos>>16)+zy
				, w := floor(j[2]*zoomW), h := floor(j[3]*zoomH), comment := j[10]
				, arr.push({1:x, 2:y, 3:w, 4:h, x:x+w//2, y:y+h//2, id:comment})
				if (!FindAll)
				break 3
			}
			}
			else
			for k,v in JoinText {
			v := strSplit(trim(regExReplace(v, "\s*\|[|\s]*", "|"), "|")
			, (inStr(v,"|")?"|":""), " `t")
			, this.JoinText(arr, ini, info2, v, 1, offsetX, offsetY
			, FindAll, dir, 0, 0, 0, sx, sy, sw, sh)
			if (!FindAll && arr.length())
				break 2
			}
			if (err1!=0 || err0!=0 || arr.length() || info[1][4] || info[1][7]=5)
			break
		}
		setBatchLines, % bch
		if (arr.length()) {
			outputX := arr[1].x, OutputY := arr[1].y, this.resultObj := arr
			return arr
		}
		return this.noMatchVal
	}

	joinText(arr, ini, info2, text, index, offsetX, offsetY
	, FindAll, dir, minX, minY, maxY, sx, sy, sw, sh) {
		local
		if !(Len := text.length()) || !info2.hasKey(key := text[index])
			return 0
		varSetCapacity(allpos, ini.allpos_max*4), allpos_ptr := &allpos
		, zoomW := ini.zoomW, zoomH := ini.zoomH, mode := ini.mode
		for i,j in info2[key]
			if (mode!=2 || key==j[10])
			loop, % this.PicFind(ini, j, dir, sx, sy, (index=1 ? sw
			: min(sx+offsetX+floor(j[2]*zoomW),ini.sx+ini.sw)-sx), sh, allpos_ptr) {
				pos := numGet(allpos, 4*(A_Index-1), "uint")
				, x := pos&0xFFFF, y := pos>>16
				, w := floor(j[2]*zoomW), h := floor(j[3]*zoomH)
				, (index=1 && (minX := x, minY := y, maxY := y+h))
				, minY1 := min(y, minY), maxY1 := max(y+h, maxY), sx1 := x+w
				if (index<Len) {
				sy1 := max(minY1-offsetY, ini.sy)
				, sh1 := min(maxY1+offsetY, ini.sy+ini.sh)-sy1
				if this.joinText(arr, ini, info2, text, index+1, offsetX, offsetY
				, FindAll, 5, minX, minY1, maxY1, sx1, sy1, 0, sh1)
				&& (index>1 || !FindAll)
					return 1
				} else {
					comment := ""
					for k,v in text
						comment.=(mode=2 ? v : info2[v][1][10])
					x := minX+ini.zx, y := minY1+ini.zy, w := sx1-minX, h := maxY1-minY1
					, arr.push({1:x, 2:y, 3:w, 4:h, x:x+w//2, y:y+h//2, id:comment})
					if (index>1 || !FindAll)
						return 1
				}
			}
		return 0
	}

	picFind(ini, j, dir, sx, sy, sw, sh, allpos_ptr) {
		local
		static init, MyFunc
		if !varSetCapacity(init) && (init := "1") {
			x32 := "VVdWU4HskAAAAIuEJMwAAAADhCTEAAAAg7wkpAAAAAWJRCQkD4QYBwAAi4wk4AAA"
			. "AIXJD46CDQAAi7wk3AAAAMcEJAAAAAAx7cdEJAwAAAAAx0QkCAAAAADHRCQQAAAA"
			. "AIl0JBSLhCTYAAAAi0wkEDH2MdsByIX@iUQkBH876Y4AAAAPr4QkxAAAAInBifCZ"
			. "9@8BwYtEJASAPBgxdEyLhCTUAAAAg8MBA7Qk+AAAAIkMqIPFATnfdFSLBCSZ97wk"
			. "4AAAAIO8JKQAAAAEdbUPr4QkuAAAAInBifCZ9@+NDIGLRCQEgDwYMXW0i0QkCIuU"
			. "JNAAAACDwwEDtCT4AAAAiQyCg8ABOd+JRCQIdawBfCQQg0QkDAGLnCT8AAAAi0Qk"
			. "DAEcJDmEJOAAAAAPhTT@@@+LRCQIi3QkFA+vhCTkAAAAiWwkNMH4ColEJDyLhCTo"
			. "AAAAD6@FwfgKiUQkRIO8JKQAAAAED4RnBwAAi4QkuAAAAIucJLwAAAAPr4QkwAAA"
			. "AI0smIuEJMQAAACLnCS4AAAA99iDvCSkAAAAAY0Eg4lEJDgPhEkIAACDvCSkAAAA"
			. "Ag+EKAsAAIO8JKQAAAADD4QbDAAAi4QkyAAAAIXAD44kAQAAi4QkxAAAAIu8JMQA"
			. "AADHRCQQAAAAAMdEJBQAAAAAiXQkGIPoAYlEJAyNdgCLdCQUi1wkJDHAi4wkzAAA"
			. "AAHzhf+NLDEPjsAAAACJ@onv6xLGBAcEg8ABg8MBOcYPhKIAAACDvCSkAAAAA3@k"
			. "hcAPtgsPhKYNAAAPtlP@iRQkOUQkDA+EZhAAAA+2UwGJVCQEi6wk7AAAAIXtD4Sd"
			. "AQAAD7bpugYAAACD7QGD@QF2G4M8JAEPlMKDfCQEAYnVD5TCCeoPttIB0oPKBIHh"
			. "@QAAAL0BAAAAdBqLLCSLTCQEhe0PlAQkhckPlMGJzQ+2DCQJzQnqg8MBiBQHg8AB"
			. "OcYPhV7@@@8BdCQUifeDRCQQAYtEJBA5hCTIAAAAD48M@@@@i3QkGIO8JKQAAAAD"
			. "fxaLnCTsAAAAhdsPlcA8AYOcJLwAAAD@i1wkCIt8JDwxwDn7i3wkRA9O2IlcJAiL"
			. "XCQ0OfsPT8OJRCQ0i4QkxAAAACuEJPgAAACJRCQQi4QkyAAAACuEJPwAAACDvCSw"
			. "AAAACYlEJBQPhAQBAACLhCSwAAAAg+gBg@gHD4fEAAAAg@gDiUQkJA+OvwAAAItE"
			. "JBDHRCRQAAAAAMdEJBgAAAAAiUQkDItEJBSJRCQci1wkUDlcJAzHRCRYAAAAAHx0"
			. "i1wkWDlcJBwPjGEMAACLfCRQi1wkJItEJAwp+PbDAg9Ex4t8JFiJwotEJBwp+PbD"
			. "AQ9Ex4P7A4nXD0@4D0@CiXwkBIkEJOlPAQAAkI10JgAPttGD6gGD+gIZ0oPiAoPC"
			. "BIHh@QAAAA+UwQnKiBQH6fT9@@+LRCQYgcSQAAAAW15fXcJcAMdEJCQAAAAAi0Qk"
			. "FMdEJFAAAAAAx0QkGAAAAACJRCQMi0QkEIlEJBzpPP@@@4tcJBCLbCQUx0QkaAAA"
			. "AADHRCRkAQAAAMdEJEwAAAAAx0QkXAAAAACJ2I1VAYlsJAzB6B@HRCQYAAAAAAHY"
			. "0fiJBCSJ6MHoHwHo0fiJRCQEidiNWwGNSAmJ3w+v+ol8JHiJx4nog8AJOdOJfCQc"
			. "D0@BicMPr9iJXCR8i1wkeDlcJGgPjTr@@@+LXCR8OVwkXMdEJGAAAAAAD40k@@@@"
			. "i3wkZDl8JGAPjVMGAACLBCSFwA+IrAoAAItcJBw52A+PoAoAAItEJASFwA+IlAoA"
			. "AItcJAw52A+PiAoAAINEJGgBx0QkJAkAAACLRCQEi5wkzAAAAA+vhCTEAAAAAwQk"
			. "gDwDAw+GswEAAIt8JAiLXCQ0Od8PTd+DvCSkAAAAA4nfD444DQAAi0QkBAOEJMAA"
			. "AAAPr4QkuAAAAIsUJAOUJLwAAACDvCSkAAAABY0EkA+EjgoAAIlEJEADhCSoAAAA"
			. "hf+LnCS0AAAAD7ZcAwKJXCQwi5wktAAAAA+2XAMBiVwkVIucJLQAAAAPtgQDiUQk"
			. "bA+EugsAAItEJESJdCQ4Me2J3olEJHSLRCQ8iUQkcOmEAAAAOWwkNH5zi4Qk1AAA"
			. "AItMJEADDKgPtlQOAg+2RA4BD7YMDitEJFQrTCRsidMDVCQwK1wkMA+vwImMJIAA"
			. "AACNigAEAADB4AsPr8sPr8uLnCSAAAAAAcG4@gUAACnQD6@DD6@DAcg5hCSsAAAA"
			. "cguDbCR0AQ+IjAAAAIPFATnvD4SWDAAAOWwkCA+Ocv@@@4uEJNAAAACLTCRAAwyo"
			. "D7ZUDgIPtkQOAQ+2DA4rRCRUK0wkbInTA1QkMCtcJDAPr8CJjCSAAAAAjYoABAAA"
			. "weALD6@LD6@Li5wkgAAAAAHBuP4FAAAp0A+vww+vwwHIOYQkrAAAAA+DBv@@@4Ns"
			. "JHABD4n7@v@@i3QkOIN8JCQJD4SdCAAAg0QkWAHpfvz@@4uUJKgAAAAxwIXSD5XA"
			. "iUQkSA+EwwEAAIuEJOAAAACLtCTYAAAAD6+EJNwAAADRpCSsAAAAjTSGi4Qk6AAA"
			. "AMH4CoPAAYlEJBiLhCTgAAAAhcAPjhMLAACLXCQYi4Qk@AAAAMdEJCgAAAAAx0Qk"
			. "CAAAAAAPr8OJRCQ0i4Qk3AAAAA+vw8HgAolEJDiLhCTYAAAAg8ACiUQkLInYjRyd"
			. "AAAAAIlcJCCJww+vhCT4AAAAiVwkMIlEJByLrCTcAAAAhe0PjkgEAACLRCQsx0Qk"
			. "FAAAAACJRCQMi0QkGIlEJBCLRCQMMckPtnj@D7YYD7ZA@ok8JIlEJASNtCYAAAAA"
			. "OYwkrAAAAA+GRAMAAIs8joPBAotsjvyJ+MHoEInqweoQD7bAKdgPttIPr8APr9I5"
			. "0H@NifgPttQrFCSJ6A+2xA+vwA+v0jnCf7aJ+A+2+Ct8JASJ6A+26A+v7Q+v@znv"
			. "f56LXCQQi0QkGItMJCABTCQMi0wkHAFMJBQB2DmcJNwAAAAPjogDAACJRCQQ6U@@"
			. "@@+LhCSoAAAAwegQD6+EJPwAAACZ97wk4AAAAA+vhCS4AAAAicEPt4QkqAAAAA+v"
			. "hCT4AAAAmfe8JNwAAACNBIGJhCSoAAAA6aj4@@+LhCSsAAAAhcAPhNEGAACLtCTQ"
			. "AAAAi4wkrAAAADHti5wk2AAAAIu8JNQAAACNBI6JRCQEiwuDxgSDw1iDxwSJyMHo"
			. "EA+vhCT8AAAAmfe8JOAAAAAPr4QkuAAAAIkEJA+3wQ+vhCT4AAAAmfe8JNwAAACL"
			. "FCSNBIKJRvyLQ6yNREUAg8UWiUf8O3QkBHWmi4QkrAAAAImMJKgAAACJRCQIi4Qk"
			. "5AAAAA+vhCSsAAAAwfgKiUQkPIuEJNgAAADHRCREAAAAAMdEJDQAAAAAjXAI6dP3"
			. "@@+LhCTgAAAAi7wkyAAAAA+vhCTcAAAA0aQkrAAAAMdEJDAAAAAAx0QkQAAAAAAD"
			. "hCTYAAAAicaLhCTEAAAAweAChf+JRCRUD466+P@@i3wkSIl0JByLnCTEAAAAhdsP"
			. "jvUAAACLnCS0AAAAi3QkJAN0JEAB6wNsJFSJbCRIA6wktAAAAIlsJBiJ3esWjXYA"
			. "xgYAg8UEg8YBO2wkGA+EqAAAAA+2RQIx@4kEJA+2RQGJRCQMD7ZFAIlEJBA5vCSs"
			. "AAAAdsuLRCQcixS4g8cCi0y4@A+23itcJAyJ0MHoEA+2wCsEJIlcJAQPttorXCQQ"
			. "gfr@@@8AiVwkFA+GAgEAAIsUJI0cUI2TAAQAAA+v0A+vwotUJAQPr9LB4gsB0Lr+"
			. "BQAAKdqJ04tUJBQPr9oPr9qNFBg50XKExgYBg8UEg8YBO2wkGA+FWP@@@4u0JMQA"
			. "AAABdCRAi2wkSINEJDABA2wkOItEJDA5hCTIAAAAD4Xi@v@@iXwkSIt0JBzpY@b@"
			. "@4tcJEyJ2IPgAQHHidiDwAGJfCRkg+ADiUQkTOlb+f@@i0QkKItsJAjB4xCZjTyt"
			. "AAAAAPe8JOAAAAAPr4QkuAAAAInBi0QkFJn3vCTcAAAAi5Qk0AAAAI0EgYnpg8EB"
			. "iQSqiwQkiUwkCMHgCAnDC1wkBIuEJNQAAACJHDjpsPz@@4nKweoQD7baD7bVD7bJ"
			. "iVQkIInaiVwkLA+vwIlMJCgPr9M50A+PkP7@@4tcJASJ2A+vw4tcJCCJ2g+v0znQ"
			. "D492@v@@i0QkFInDD6@YicgPr8E5ww+PYP7@@+nX@v@@i1wkMItEJBiLTCQ0AUwk"
			. "KItMJDgBTCQsAdg5nCTgAAAAfgmJRCQw6X37@@+LRCQID6+EJOQAAADB+AqJRCQ8"
			. "i4wkqAAAAIuEJKgAAAAPtpQkqAAAAMdEJEQAAAAAx0QkNAAAAADB6RAPtsQPtsmJ"
			. "yw+v2YlcJCyJww+v2InQD6@CiVwkIIlEJCjp5vT@@4uEJKgAAACLjCTIAAAAxwQk"
			. "AAAAAMdEJAQAAAAAg8ABweAHiYQkqAAAAIuEJMQAAADB4AKFyYlEJBAPjtn1@@+J"
			. "6IusJKgAAACJdCQUi5QkxAAAAIXSfmOLjCS0AAAAi1wkJIu8JLQAAAADXCQEAcED"
			. "RCQQiUQkDAHHjbQmAAAAAA+2UQIPtkEBD7Yxa8BLa9ImAcKJ8MHgBCnwAdA5xQ+X"
			. "A4PBBIPDATn5ddWLnCTEAAAAAVwkBItEJAyDBCQBA0QkOIs0JDm0JMgAAAAPhXr@"
			. "@@+LdCQU6Rn0@@@HRCREAAAAAMdEJDwAAAAAx0QkNAAAAADHRCQIAAAAAOl98@@@"
			. "i4QkyAAAAIXAD44J9f@@i5wkxAAAAItEJCTHBCQAAAAAx0QkBAAAAACJdCQQjQRY"
			. "iUQkFInYweACiUQkDIuEJMQAAACFwH5hi4wktAAAAItcJBSLvCS0AAAAA1wkBAHp"
			. "A2wkDAHvjXYAjbwnAAAAAA+2UQKDwQSDwwFr8iYPtlH9a8JLjRQGD7Zx@InwweAE"
			. "KfAB0MH4B4hD@zn5ddKLtCTEAAAAAXQkBIMEJAEDbCQ4iwQkOYQkyAAAAHWAi4Qk"
			. "xAAAAIt0JBAx7YuUJKwAAAAx24PoAYl0JByJRCQMi4QkyAAAAIPoAYlEJBCLhCTE"
			. "AAAAhcAPjtoAAACLfCQUi7QkxAAAAIn4Ad6NDB8B8Il0JBiJ3iu0JMQAAACJBCQx"
			. "wAH+i3wkJAH7iVwkBI12AIXAD4QhAQAAOUQkDA+EFwEAAIXtD4QPAQAAOWwkEA+E"
			. "BQEAAA+2EQ+2ef+7AQAAAAOUJKgAAAA5+nJFD7Z5ATn6cj0Ptj45+nI2izwkD7Y@"
			. "OfpyLA+2fv85+nIkD7Z+ATn6chyLPCQPtn@@OfpyEYs8JA+2XwE52g+Sw5CNdCYA"
			. "i3wkBIgcB4PAAYPBAYMEJAGDxgE5hCTEAAAAD4Vf@@@@i1wkGIPFATmsJMgAAAAP"
			. "hQf@@@+LdCQciZQkrAAAAOn@8f@@i0wkTIXJdTWDbCQEAYNEJGABg0QkXAHpH@X@"
			. "@8cEJAMAAADpVfL@@8dEJDwAAAAAx0QkCAAAAADpwfn@@4N8JEwBdDSDfCRMAnQm"
			. "McCDfCRMAw+UwCkEJOuzg0QkUAHpdfP@@4tcJATGBAMC6VH@@@+DRCQEAeuVgwQk"
			. "AeuPi1QkSIlEJDCF0g+F+wIAAIXbD4RWAQAAi4Qk0AAAAInziXQkbIlEJECLhCTU"
			. "AAAAiUQkVGvHFjH@iYQkgAAAAItEJDyJRCR0i3QkQItEJDCJ@YnZiVwkcAMGizOJ"
			. "dCQ4i3QkVIs2ibQkrAAAAIu0JLQAAAAPtnQGAom0JIQAAACLtCS0AAAAD7Z0BgGJ"
			. "tCSIAAAAi7QktAAAAA+2BAaJhCSMAAAA6X0AAACNdgCLAYtxBIPFAsHuEInCweoQ"
			. "ifMPtvMPttKLWQQrlCSEAAAAiXQkLA+v9g+234lcJCAPtlkED6@SOfKJXCQofziL"
			. "XCQgD7bUK5QkiAAAAIneD6@SD6@zOfJ@HotcJCgPtsArhCSMAAAAidoPr8APr9M5"
			. "0A+O0AEAAIPBCDusJKwAAAAPgnn@@@+BfCQ4@@@@AItcJHB3C4NsJHQBD4hmAgAA"
			. "g0QkQASDw1iDRCRUBIPHFjm8JIAAAAAPhd7+@@+LdCRsi4Qk8AAAAINEJBgBhcB0"
			. "NotUJAQDlCTAAAAAiwQkA4QkvAAAAItcJBiLvCTwAAAAweIQCdA7nCT0AAAAiUSf"
			. "@A+NLfL@@4tcJAQxyYnYK4Qk@AAAAIPAAQ9IwYnCidiLnCT8AAAAjUQY@4tcJBQ5"
			. "ww9Ow4scJInHidgrhCT4AAAAg8ABD0nIidiLnCT4AAAAic2NRBj@i1wkEDnDD07D"
			. "OfqJww+Pw@T@@4uEJMQAAAAPr8IDhCTMAAAAicGNRwGNewGJRCQwOet8DYnogCQB"
			. "A4PAATn4dfWDwgEDjCTEAAAAO1QkMHXf6YD0@@@HRCQ8AAAAAMdEJAgAAAAA6c75"
			. "@@@HRCQEAwAAAOmV7@@@hdsPhOr+@@8DhCTMAAAAi1wkRDHSi2wkPIlcJDCJwest"
			. "OVQkNH4ci5wk1AAAAIsEkwHI9gABdQuDbCQwAQ+IG@T@@4PCATnXD4Sk@v@@OVQk"
			. "CH7Ni5wk0AAAAIsEkwHI9gACdbyD7QF5t+nv8@@@i3QkOOl6@v@@gXwkOP@@@wCL"
			. "XCRwD4c8@v@@6UL+@@+F2w+EW@7@@4tEJDwx7YlEJDiLnCTQAAAAi0QkMAMEq4uc"
			. "JNQAAACLHKuJnCSoAAAAi5wktAAAAIuUJKgAAAAPtkwDAsHqEA+20inRD7ZUAwGL"
			. "nCSoAAAAD6@JD7bfKdqLnCS0AAAAD7YEAw+2nCSoAAAAKdg5TCQsfBIPr9I5VCQg"
			. "fAkPr8A5RCQofQuDbCQ4AQ+IN@P@@4PFATnvD4Vv@@@@6bv9@@+LdCRs6R7z@@+Q"
			x64 := "QVdBVkFVQVRVV1ZTSIHsuAAAAEhjhCRAAQAAi5wkcAEAAInNiVQkQESJjCQYAQAA"
			. "i7QkeAEAAEmJxEiJRCRoSAOEJFABAACD+QVIiUQkKA+E+wYAAIX2D44TDQAARTH2"
			. "i7wkqAEAAEUx7USJdCQQTIu0JGABAABFMdtFMf9EiWwkCESJhCQQAQAAZg8fRAAA"
			. "TGNUJBBFMclFMcBMA5QkaAEAAIXbfzXreg8fgAAAAABBD6@EicFEiciZ9@sBwUOA"
			. "PAIxdDxJg8ABSWPHQQH5QYPHAUQ5w0GJDIZ+Q0SJ2Jn3@oP9BHXJD6+EJCgBAACJ"
			. "wUSJyJn3+0OAPAIxjQyBdcRIi5QkWAEAAEmDwAFJY8VBAflBg8UBRDnDiQyCf70B"
			. "XCQQg0QkCAFEA5wksAEAAItEJAg5xg+FVP@@@0SJ6ESLhCQQAQAARIlsJCQPr4Qk"
			. "gAEAAMH4ColEJESLhCSIAQAAQQ+vx8H4ColEJEyD@QQPhKsHAACLhCQoAQAAi7wk"
			. "MAEAAA+vhCQ4AQAAjQS4i7wkKAEAAIlEJBBEieD32IP9AY0Eh4lEJDgPhGAIAACD"
			. "@QIPhBELAACD@QMPhM8LAABEi4wkSAEAAEWFyQ+OEAEAAESJfCQIi7QkkAEAAEGN"
			. "fCT@TIt8JChFMfZFMe1EiYQkEAEAAGYuDx+EAAAAAABFheQPjroAAABJY8UxyUmJ"
			. "wU2NRAcBTAOMJFABAADrGEHGAQSDwQFJg8EBSYPAAUE5zA+EiAAAAIP9A3@jhclB"
			. "D7ZQ@w+EPQ0AAEUPtlj+Oc8PhDIQAABFD7YQhfYPhH0BAAAPttq4BgAAAIPrAYP7"
			. "AXYYQYP7AQ+Uw0GD+gEPlMAJ2A+2wAHAg8gEgeL9AAAAuwEAAAB0DkWF2w+Uw0WF"
			. "0g+UwgnTCdiDwQFJg8EBQYhB@0mDwAFBOcwPhXj@@@9FAeVBg8YBRDm0JEgBAAAP"
			. "jyv@@@9Ei3wkCESLhCQQAQAAg@0DfxaLjCSQAQAAhckPlcA8AYOcJDABAAD@i3wk"
			. "JIt0JEQxwESLtCRIAQAAOfcPTvhEO3wkTIl8JCRED074RIngRCu0JLABAAArhCSo"
			. "AQAAg7wkGAEAAAmJRCQQD4QBAQAAi4QkGAEAAIPoAYP4Bw+HxAAAAIP4A4lEJDgP"
			. "jr8AAACLRCQQRIl0JDDHRCRUAAAAAMdEJCgAAAAAiUQkCIt0JFQ5dCQIx0QkcAAA"
			. "AAB8cIt8JHA5fCQwD4wiDAAAi3wkOIt0JFSLRCQIRItsJDAp8ED2xwIPRMaLdCRw"
			. "QSn1QPbHAUQPRO6D@wOJx0EPT@1ED0@o6WIBAAAPHwAPtsKD6AGD+AIZwIPgAoPA"
			. "BIHi@QAAAA+UwgnQQYgB6SD+@@+LRCQoSIHEuAAAAFteX11BXEFdQV5BX8PHRCQ4"
			. "AAAAAItEJBBEiXQkCMdEJFQAAAAAx0QkKAAAAACJRCQw6Tz@@@9BicWJxkGNVgFB"
			. "we0fRI1OAUSJdCQIQQHFRInwx4QkhAAAAAAAAADB6B9B0f3HhCSAAAAAAQAAAEQB"
			. "8MdEJFAAAAAAx0QkeAAAAADR+MdEJCgAAAAAiceJ8ESJzg+v8o1ICUE50Ym0JJwA"
			. "AACJxkGNRgmJdCQwD0@BicMPr9iJnCSgAAAAi7QknAAAADm0JIQAAAAPjSX@@@+L"
			. "tCSgAAAAOXQkeMdEJHwAAAAAD40M@@@@i5wkgAAAADlcJHwPjUgGAABFhe0PiFsK"
			. "AABEO2wkMA+PUAoAAIX@D4hICgAAO3wkCA+PPgoAAIOEJIQAAAABx0QkOAkAAACJ"
			. "+EiLtCRQAQAAQQ+vxEaNDChJY8GAPAYDD4bcAQAAi0QkJEQ5+EEPTMeD@QOJxg+O"
			. "IA0AAIuEJDgBAACLlCQwAQAAAfhEAeoPr4QkKAEAAIP9BQ+ESgoAAESNHJCLRCRA"
			. "SIucJCABAABEAdiF9o1QAkhj0g+2HBONUAFImEhj0olcJFhIi5wkIAEAAA+2HBOJ"
			. "XCRkSIucJCABAAAPtgQDiYQkiAAAAA+ElgsAAItEJEyJfCRIMdtIi7wkIAEAAImE"
			. "JJAAAACLRCREiYQkmAAAAOmRAAAARDu8JKQAAAB+e0iLhCRgAQAARItMJFiLFJhE"
			. "AdqNQgJImA+2DAeNQgFIY9IPthQXSJgrlCSIAAAAD7YEB0GJykQByStEJGRFKcpE"
			. "jYkABAAARQ+vyg+vwEUPr8rB4AtBAcG4@gUAACnID6@CD6@CRAHIQTnAcg6DrCSQ"
			. "AAAAAQ+InAAAAEiDwwE53g+OZgwAADlcJCSJnCSkAAAAD45e@@@@SIuEJFgBAABE"
			. "i0wkWIsUmEQB2o1CAkiYD7YMB41CAUhj0g+2FBdImCuUJIgAAAAPtgQHQYnKRAHJ"
			. "K0QkZEUpykSNiQAEAABFD6@KD6@ARQ+vysHgC0EBwbj+BQAAKcgPr8IPr8JBAcFF"
			. "OcgPg+3+@@+DrCSYAAAAAQ+J3@7@@4t8JEiDfCQ4CQ+EKAgAAINEJHAB6UX8@@+Q"
			. "i0QkQDH@hcBAD5XHiXwkdA+E8wEAAInwRQHAD6@DweACSJhIA4QkaAEAAEiJBCSL"
			. "hCSIAQAAwfgKg8ABhfZBiccPjt0KAACLhCSwAQAARImkJEABAABEiXwkJMdEJCAA"
			. "AAAAiYwkAAEAAImcJHABAABBD6@HibQkeAEAAIlEJDBEifgPr8PB4AJImEiJRCQ4"
			. "SIuEJGgBAABIiUQkGESJ+MHgAkiYSIlEJAiLhCSoAQAAQQ+vx4lEJBAxwEGJxIu8"
			. "JHABAACF@w+OEwQAAEiLdCQYRIn9Mf9mDx+EAAAAAABED7ZOAkQPtlYBRTH2RA+2"
			. "HkiLDCTrY2YPH4QAAAAAAIsRi1kEQYPGAonQQYndwegQQcHtEA+2wEUPtu1EKcgP"
			. "r8BFD6@tRDnofysPtsZEKdBBicUPtsdFD6@tD6@AQTnFfxMPttIPtttEKdoPr9IP"
			. "r9s52n5ZSIPBCEU58Hehi0QkIEiLnCRYAQAATWPsQcHhEEHB4ghBg8QBRQnRmUUJ"
			. "2fe8JHgBAAAPr4QkKAEAAInBifiZ97wkcAEAAI0EgUKJBKtIi4QkYAEAAEaJDKhE"
			. "ifhIA3QkCAN8JBAB6DmsJHABAAAPjhYDAACJxekP@@@@i3wkQIn4wegQD6+EJLAB"
			. "AACZ9@4Pr4QkKAEAAInBD7fHD6+EJKgBAACZ9@uNBIGJRCRA6Wj4@@9FMclFMdtF"
			. "hcBMi5QkaAEAAA+EIgYAAEyLrCRYAQAATIu0JGABAABEi7wksAEAAEGLOkmDwliJ"
			. "+MHoEEEPr8eZ9@4Pr4QkKAEAAInBD7fHD6+EJKgBAACZ9@uNBIFDiUSNAEGLQqxB"
			. "jQRDQYPDFkOJBI5Jg8EBRTnId7SLhCSAAQAAiXwkQESJRCQkQQ+vwMH4ColEJERI"
			. "i4QkaAEAAMdEJEwAAAAARTH@SIPACEiJBCTpsvf@@4nwi7QkSAEAAEUBwA+vw0iY"
			. "SAOEJGgBAACF9kiJBCQPjq74@@9BjUQk@0SJpCRAAQAARItcJHTHRCQwAAAAAMdE"
			. "JEgAAAAASI0EhQYAAABEibwkiAAAAImsJAABAABIiUQkWEKNBKUAAAAARItkJGCJ"
			. "RCRki5wkQAEAAIXbD45XAQAASGNEJBBIi7wkIAEAAEhjdCRISAN0JChMjVQHAkgD"
			. "RCRYSAH4SIlEJAjrGQ8fAMYGAEmDwgRIg8YBTDtUJAgPhAABAABBD7YqRQ+2cv9F"
			. "MdtFD7Zq@kiLHCRFOcNz0IsTQYPDAotLBInQD7b+RA+2ysHoEEQp90Up6Q+2wCno"
			. "gfr@@@8AdlyNFGgPr@9EjboABAAARA+v+MHnC0EPr8cBx7j+BQAAKdCJwkEPr9GJ"
			. "0EEPr8EB+DnBc3VIg8MI65qLdCRQifCD4AEBw4nwg8ABiZwkgAAAAIPgA4lEJFDp"
			. "V@n@@0GJzA+21Q+2yUHB7BBBic+JTCQYRQ+25IlUJCBEieEPr8BBD6@MOch@rYtU"
			. "JCAPr@+J0A+vwjnHf51EichEifpBD6@BQQ+v1znQf4vGBgFJg8IESIPGAUw7VCQI"
			. "D4UA@@@@i3wkZAF8JBCLvCRAAQAAAXwkSINEJDABi3QkOItEJDABdCQQOYQkSAEA"
			. "AA+FfP7@@0SJZCRgRIu8JIgAAABEiVwkdIusJAABAABEi6QkQAEAAOml9f@@Dx8A"
			. "i3wkJESJ+ItcJDABXCQgSItcJDhIAVwkGAH4ObwkeAEAAH4JiUQkJOmx+@@@RIng"
			. "RIlkJCSLrCQAAQAAD6+EJIABAABEi6QkQAEAAMH4ColEJESLdCRAx0QkTAAAAABF"
			. "Mf9BifFIifBAD7bWD7bEQcHpEEUPtsmJxg+v8ESJz4nQQQ+v+Yl0JCAPr8KJfCRg"
			. "iUQkGOn49P@@i0QkQESLnCRIAQAAMdsx9kKNPKUAAAAAg8ABweAHRYXbiUQkQA+O"
			. "7vX@@0SLdCQQRItsJEBFheR+V0iLjCQgAQAATGPeTANcJChJY8ZFMclIjUwBAmaQ"
			. "D7YRD7ZB@0QPtlH+a8BLa9ImAcJEidDB4AREKdAB0EE5xUMPlwQLSYPBAUiDwQRF"
			. "Ocx@zEEB@kQB5oPDAUQDdCQ4OZwkSAEAAHWT6WL0@@@HRCRMAAAAAMdEJEQAAAAA"
			. "RTH@x0QkJAAAAADp3fP@@0SLlCRIAQAARYXSD45B9f@@Q40EZESLbCQQQo08pQAA"
			. "AAAx2zH2SJhIA4QkUAEAAEmJxkWF5H5VSIuMJCABAABJY8VMY95FMclNAfNIjUwB"
			. "Ag+2EUiDwQREa9ImD7ZR+2vCS0GNFAJED7ZR+kSJ0MHgBEQp0AHQwfgHQ4gEC0mD"
			. "wQFFOcx@ykEB@UQB5oPDAUQDbCQ4OZwkSAEAAHWVSIt8JGhEiXwkOEUx0kSLfCRA"
			. "x0QkCAAAAABIifhIg8ABSIlEJBC4AQAAAEiJxouEJEgBAABIKf5BjXwk@0iJdCQw"
			. "RI1o@0WF5A+O1AAAAExjXCQISItEJBBIi3QkKE6NDBhIi0QkMEuNVB4BTAHeTQHx"
			. "So0MGDHATAHxDx+AAAAAAEiFwA+EFQEAADnHD4QNAQAARYXSD4QEAQAARTnVD4T7"
			. "AAAARA+2Qv9ED7Za@rsBAAAARQH4RTnYckZED7YaRTnYcj1ED7ZZ@0U52HIzRQ+2"
			. "Wf9FOdhyKUQPtln+RTnYch9ED7YZRTnYchZFD7ZZ@kU52HIMRQ+2GUU52A+Sw2aQ"
			. "iBwGSIPAAUiDwgFJg8EBSIPBAUE5xA+PZP@@@0QBZCQIQYPCAUQ5lCRIAQAAD4UR"
			. "@@@@RIt8JDjpZfL@@4tUJFCF0nUyg+8Bg0QkfAGDRCR4Aelx9f@@QbsDAAAA6b3y"
			. "@@@HRCREAAAAAMdEJCQAAAAA6Uj6@@+DfCRQAXQug3wkUAJ0IjHAg3wkUAMPlMBB"
			. "KcXrtINEJFQB6bTz@@@GBAYC6Vz@@@+DxwHrnEGDxQHrlo0EkIlEJEiLRCR0hcAP"
			. "hToDAACF9g+EhQEAAEiLhCRgAQAATIuUJFgBAABMiwwki1wkGIl8JGRIiUQkWI1G"
			. "@zH2SY1EggRIiYQkkAAAAItEJESJhCSYAAAARItcJEhFAxqJ90GLCUGNQwFBjVMC"
			. "TWPbiUwkGEiLTCRYSJhIY9JIiYQkiAAAAEiLhCQgAQAARIsBTInJD7YEEEiLlCSI"
			. "AAAAibQkiAAAAImEJKQAAABIi4QkIAEAAA+2BBCJhCSoAAAASIuEJCABAABCD7YE"
			. "GImEJKwAAADpegAAAA8fAIsBi1kEg8cCicJBidvB6hBBwesQD7bSK5QkpAAAAEEP"
			. "tvNBifMPtvcPtttEiVwkYIl0JCBFD6@bD6@SRDnafzMPttQrlCSoAAAAQYnzRA+v"
			. "3g+v0kQ52n8aD7bAK4QkrAAAAInaD6@TD6@AOdAPjuIBAABIg8EIRDnHcoSBfCQY"
			. "@@@@AIu0JIgAAAB3DoOsJJgAAAABD4iOAgAASYPCBEmDwVhIg0QkWASDxhZMO5Qk"
			. "kAAAAA+Fwf7@@4t8JGSJXCQYg0QkKAFIg7wkmAEAAAB0OIuUJDgBAACLhCQwAQAA"
			. "i3QkKEiLnCSYAQAAAfpEAejB4hBIY84J0Du0JKABAACJRIv8D4068v@@ifgrhCSw"
			. "AQAARTHSi3QkEIPAAUEPSMKJwYuEJLABAACNRAf@QTnGQQ9OxonDRInoK4QkqAEA"
			. "AIPAAUQPSdCLhCSoAQAAQY1EBf85xg9OxjnZQYnDD48W9f@@RIniSWPCjXMBD6@R"
			. "SGPSSAHQSAOEJFABAABJicFEidhEKdBIjVgBRTnTfBNKjRQLTInIgCADSIPAAUg5"
			. "0HX0g8EBTANMJGg58XXc6cb0@@@HRCREAAAAAMdEJCQAAAAA6fr5@@9BugMAAADp"
			. "x+@@@4XAD4Tm@v@@RItUJExEi1wkRDHJSIuEJFABAADrMUQ7fCRIfh5Ii5wkYAEA"
			. "AESJygMUi@YEEAF1CkGD6gEPiGP0@@9Ig8EBOc4Pjp@+@@85TCQkiUwkSH7FSIuU"
			. "JFgBAABEicsDHIr2BBgCdbFBg+sBeavpLvT@@4t8JEjpbf7@@4F8JBj@@@8Ai7Qk"
			. "iAAAAA+HI@7@@+ks@v@@hfYPhEv+@@9Ei1wkREUx0kiLnCRYAQAAi0QkSEiLjCQg"
			. "AQAATIuMJCABAABCAwSTSIucJGABAABCixyTjVACSGPSD7YMEYnaweoQD7bSKdGN"
			. "UAFImA+vyUhj0kUPtgwRD7bXQSnRRInKTIuMJCABAABBD7YEAUQPtstEKcg5TCRg"
			. "fBIPr9I5VCQgfAkPr8A5RCQYfQZBg+sBeBZJg8IBRDnWD49o@@@@iVwkQOmi@f@@"
			. "iVwkQOlR8@@@i3wkZIlcJBjpRPP@@5CQkJCQkJCQkJA="
			myFunc := this.mCode(strReplace((A_PtrSize=8?x64:x32),"@","/"))
		}
		text := j[1], w := j[2], h := j[3]
		, err1 := this.addZero(j[4] ? j[5] : ini.err1)
		, err0 := this.addZero(j[4] ? j[6] : ini.err0)
		, mode := j[7], color := j[8], n := j[9]
		resultObj := (!ini.bits.Scan0 || mode<1 || mode>5 || sw<1) ? 0
			: DllCall(MyFunc.Ptr, "int",mode, "uint",color, "uint",n, "int",dir
			, "Ptr",ini.bits.Scan0, "int",ini.bits.Stride
			, "int",sx, "int",sy, "int",sw, "int",sh
			, "Ptr",ini.ss, "Ptr",ini.s1, "Ptr",ini.s0
			, "Ptr",text, "int",w, "int",h
			, "int",floor(abs(err1)*1024), "int",floor(abs(err0)*1024)
			, "int",(err1<0||err0<0), "Ptr",allpos_ptr, "int",ini.allpos_max
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
			: DllCall("ntdll\RtlComputeCrc32", "uint",0
			, "Ptr",&v, "uint",r*(1+!!A_IsUnicode), "uint")
		if info.hasKey(key)
			return info[key]
		comment := "", seterr := err1 := err0 := 0
		if regExMatch(v, "O)<([^>\n]*)>", r)
			v := strReplace(v,r[0]), comment := trim(r[1])
		if regExMatch(v, "O)\[([^\]\n]*)]", r) {
			v := strReplace(v,r[0]), r := strSplit(r[1] ",", ",")
			, seterr := 1, err1 := this.addZero(r[1]), err0 := this.addZero(r[2])
		}
		color := subStr(v,1,inStr(v,"$")-1), v := trim(subStr(v,inStr(v,"$")+1))
		mode := inStr(color,"##") ? 5 : inStr(color,"#") ? 4
			: inStr(color,"**") ? 3 : inStr(color,"*") ? 2 : 1
		color := regExReplace(color, "[*#\s]")
		(mode=1 || mode=5) && color := strReplace(color,"0x")
		if (mode=5) {
			if !(v~="/[\s\-\w]+/[\s\-\w,/]+$") {
			if !(hBM := LoadPicture(v))
				return
			this.GetBitmapWH(hBM, w, h)
			if (w<1 || h<1)
				return
			hBM2 := this.CreateDIBSection(w, h, 32, Scan0)
			this.CopyHBM(hBM2, 0, 0, hBM, 0, 0, w, h)
			DllCall("DeleteObject", "Ptr",hBM)
			if (!Scan0)
				return
			arr := strSplit(color "/", "/"), arr.Pop(), n := arr.length()-1
			bmp.push(buf := this.buffer(w*h*4 + n*2*4)), v := buf.Ptr, p := v+w*h*4-4
			DllCall("RtlMoveMemory", "Ptr",v, "Ptr",Scan0, "Ptr",w*h*4)
			DllCall("DeleteObject", "Ptr",hBM2)
			tab := Object("Black", "000000", "White", "FFFFFF"
			, "Red", "FF0000", "Green", "008000", "Blue", "0000FF"
			, "Yellow", "FFFF00", "Silver", "C0C0C0", "Gray", "808080"
			, "Teal", "008080", "Navy", "000080", "Aqua", "00FFFF"
			, "Olive", "808000", "Lime", "00FF00", "Fuchsia", "FF00FF"
			, "Purple", "800080", "Maroon", "800000")
			loop, % n
				c := strSplit(trim(arr[1+A_Index],"-") "-" arr[1], "-"), v1 := c[1]
				, numPut(this.addZero("0x" (tab.hasKey(v1)?tab[v1]:v1)), 0|p+=4, "uint")
				, numPut(this.addZero("0x" c[2]), 0|p+=4, "uint")
			color := this.addZero("0x" arr[1])|0x1000000
			} else {
			color := strSplit(color "/", "/")[1]
			arr := strSplit(trim(regExReplace(v, "i)\s|0x"), ","), ",")
			if !(n := arr.length())
				return
			bmp.push(buf := this.buffer(n*22*4)), v := buf.Ptr
			for k1,v1 in arr {
				r := strSplit(v1 "/", "/")
				, x := this.addZero(r[1]), y := this.addZero(r[2])
				, (A_Index=1) ? (x1 := x2 := x, y1 := y2 := y)
				: (x1 := min(x1,x), x2 := max(x2,x), y1 := min(y1,y), y2 := max(y2,y))
			}
			for k1,v1 in arr
			{
				r := strSplit(v1 "/", "/")
				, x := this.addZero(r[1])-x1, y := this.addZero(r[2])-y1
				, n1 := min(max(r.length()-3, 0), 10)
				, numPut(y<<16|x, 0|p := v+(A_Index-1)*22*4, "uint")
				, numPut(n1, 0|p+=4, "uint")
				loop, % n1
				k1 := (inStr(v1 := r[2+A_Index], "-")=1 ? 0x1000000:0)
				, c := strSplit(trim(v1,"-") "-" color, "-")
				, numPut(this.addZero("0x" c[1])&0xFFFFFF|k1, 0|p+=4, "uint")
				, numPut(this.addZero("0x" c[2]), 0|p+=4, "uint")
			}
			color := 0, w := x2-x1+1, h := y2-y1+1
			}
		} else {
			r := strSplit(v ".", "."), w := this.addZero(r[1])
			, v := this.base64tobit(r[2]), h := strLen(v)//w
			if (w<1 || h<1 || strLen(v)!=w*h)
			return
			arr := strSplit(color "/", "/"), arr.Pop(), n := arr.length()
			, bmp.push(buf := this.buffer(StrPut(v, "CP0") + n*2*4))
			, StrPut(v, buf.Ptr, "CP0"), v := buf.Ptr, p := v+w*h-4
			, color := this.addZero(arr[1])
			if (mode=1) {
			for k1,v1 in arr
				k1 := (inStr(v1, "@") ? 0x1000000:0)
				, r := strSplit(v1 "@", "@"), x := this.addZero(r[2])
				, x := (x<=0||x>1?1:x), x := floor(4606*255*255*(1-x)*(1-x))
				, c := strSplit(trim(r[1],"-") "-" format("{:X}",x), "-")
				, numPut(this.addZero("0x" c[1])&0xFFFFFF|k1, 0|p+=4, "uint")
				, numPut(this.addZero("0x" c[2]), 0|p+=4, "uint")
			}
			else if (mode=4) {
			r := strSplit(arr[1] "@", "@"), n := this.addZero(r[2])
			, n := (n<=0||n>1?1:n), n := floor(4606*255*255*(1-n)*(1-n))
			, c := this.addZero(r[1]), color := ((c-1)//w)<<16|Mod(c-1,w)
			}
		}
		return info[key]:=[v, w, h, seterr, err1, err0, mode, color, n, comment]
	}

	buffer(size, FillByte := "") {
		local
		buf := {}, buf.SetCapacity("_key", size), p := buf.GetAddress("_key")
		, (FillByte!="" && DllCall("RtlFillMemory","Ptr",p,"Ptr",size,"uchar",FillByte))
		, buf.Ptr := p, buf.Size := size
		return buf
	}

	getBitsFromScreen(ByRef x := 0, ByRef y := 0, ByRef w := 0, ByRef h := 0
	, ScreenShot := 1, ByRef zx := 0, ByRef zy := 0, ByRef zw := 0, ByRef zh := 0) {
		local
		static init, CAPTUREBLT
		if !varSetCapacity(init) && (init := "1") {
			DllCall("Dwmapi\DwmIsCompositionEnabled", "Int*",i := 0)
			cAPTUREBLT := i ? 0 : 0x40000000
		}
		(!isObject(this.bits) && this.bits := {Scan0:0, hBM:0, oldzw:0, oldzh:0})
		, bits := this.bits
		if (!ScreenShot && bits.Scan0) {
			zx := bits.zx, zy := bits.zy, zw := bits.zw, zh := bits.zh
			, w := min(x+w,zx+zw), x := max(x,zx), w-=x
			, h := min(y+h,zy+zh), y := max(y,zy), h-=y
			return bits
		}
		bch := A_BatchLines, cri := A_IsCritical
		critical
		bits.BindWindow := id := this.BindWindow(0,0,1)
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
		, w := min(x+w,zx+zw), x := max(x,zx), w-=x
		, h := min(y+h,zy+zh), y := max(y,zy), h-=y
		if (!ScreenShot || w<1 || h<1 || !bits.hBM) {
			critical % cri
			setBatchLines, % bch
			return bits
		}
		if IsFunc(k := "getBitsFromScreen2")
			&& %k%(bits, x-zx, y-zy, w, h) {
			zx := bits.zx, zy := bits.zy, zw := bits.zw, zh := bits.zh
			critical % cri
			setBatchLines, % bch
			return bits
		}
		mDC := DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
		oBM := DllCall("SelectObject", "Ptr",mDC, "Ptr",bits.hBM, "Ptr")
		if (id) {
			if (mode := this.BindWindow(0,0,0,1))<2 {
			hDC := DllCall("GetDCEx", "Ptr",id, "Ptr",0, "int",3, "Ptr")
			DllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
				, "Ptr",hDC, "int",x-zx, "int",y-zy, "uint",0xCC0020|CAPTUREBLT)
			DllCall("ReleaseDC", "Ptr",id, "Ptr",hDC)
			} else {
			hBM2 := this.CreateDIBSection(zw, zh)
			mDC2 := DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
			oBM2 := DllCall("SelectObject", "Ptr",mDC2, "Ptr",hBM2, "Ptr")
			DllCall("UpdateWindow", "Ptr",id)
			DllCall("PrintWindow", "Ptr",id, "Ptr",mDC2, "uint",(mode>3)*3)
			DllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
				, "Ptr",mDC2, "int",x-zx, "int",y-zy, "uint",0xCC0020)
			DllCall("SelectObject", "Ptr",mDC2, "Ptr",oBM2)
			DllCall("DeleteDC", "Ptr",mDC2)
			DllCall("DeleteObject", "Ptr",hBM2)
			}
		} else {
			hDC := DllCall("GetWindowDC","Ptr",id := DllCall("GetDesktopWindow","Ptr"),"Ptr")
			DllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
			, "Ptr",hDC, "int",x, "int",y, "uint",0xCC0020|CAPTUREBLT)
			DllCall("ReleaseDC", "Ptr",id, "Ptr",hDC)
		}
		if this.CaptureCursor(0,0,0,0,0,1)
			this.CaptureCursor(mDC, zx, zy, zw, zh)
		DllCall("SelectObject", "Ptr",mDC, "Ptr",oBM)
		DllCall("DeleteDC", "Ptr",mDC)
		critical % cri
		setBatchLines, % bch
		return bits
	}

	updateBits(bits, zx, zy, zw, zh) {
		local
		if (zw>bits.oldzw || zh>bits.oldzh || !bits.hBM) {
			try DllCall("DeleteObject", "Ptr",bits.hBM)
			bits.hBM := this.CreateDIBSection(zw, zh, bpp := 32, ppvBits)
			, bits.Scan0 := (!bits.hBM ? 0:ppvBits)
			, bits.Stride := ((zw*bpp+31)//32)*4
			, bits.oldzw := zw, bits.oldzh := zh
		}
		bits.zx := zx, bits.zy := zy, bits.zw := zw, bits.zh := zh
	}

	CreateDIBSection(w, h, bpp := 32, ByRef ppvBits := 0) {
		local
		varSetCapacity(bi, 40, 0), numPut(40, bi, 0, "int")
		, numPut(w, bi, 4, "int"), numPut(-h, bi, 8, "int")
		, numPut(1, bi, 12, "short"), numPut(bpp, bi, 14, "short")
		return DllCall("CreateDIBSection", "Ptr",0, "Ptr",&bi, "int",0, "Ptr*",ppvBits := 0, "Ptr",0, "int",0, "Ptr")
	}

	getBitmapWH(hBM, ByRef w, ByRef h) {
		local
		varSetCapacity(bm, size := (A_PtrSize=8 ? 32:24), 0)
		, DllCall("GetObject", "Ptr",hBM, "int",size, "Ptr",&bm)
		, w := numGet(bm,4,"int"), h := abs(numGet(bm,8,"int"))
	}

	copyHBM(hBM1, x1, y1, hBM2, x2, y2, w, h, Clear := 0, trans := 0, alpha := 255) {
		local
		if (w<1 || h<1 || !hBM1 || !hBM2)
			return
		mDC1 := DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
		oBM1 := DllCall("SelectObject", "Ptr",mDC1, "Ptr",hBM1, "Ptr")
		mDC2 := DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
		oBM2 := DllCall("SelectObject", "Ptr",mDC2, "Ptr",hBM2, "Ptr")
		if (trans)
			DllCall("GdiAlphaBlend", "Ptr",mDC1, "int",x1, "int",y1, "int",w, "int",h
			, "Ptr",mDC2, "int",x2, "int",y2, "int",w, "int",h, "uint",alpha<<16)
		else
			DllCall("BitBlt", "Ptr",mDC1, "int",x1, "int",y1, "int",w, "int",h
			, "Ptr",mDC2, "int",x2, "int",y2, "uint",0xCC0020)
		if (Clear)
			DllCall("BitBlt", "Ptr",mDC1, "int",x1, "int",y1, "int",w, "int",h
			, "Ptr",mDC1, "int",x1, "int",y1, "uint",MERGECOPY := 0xC000CA)
		DllCall("SelectObject", "Ptr",mDC1, "Ptr",oBM1)
		DllCall("DeleteDC", "Ptr",mDC1)
		DllCall("SelectObject", "Ptr",mDC2, "Ptr",oBM2)
		DllCall("DeleteDC", "Ptr",mDC2)
	}

	copyBits(Scan01,Stride1,x1,y1,Scan02,Stride2,x2,y2,w,h,Reverse := 0) {
		local
		if (w<1 || h<1 || !Scan01 || !Scan02)
			return
		static init, MFCopyImage
		if !varSetCapacity(init) && (init := "1") {
			mFCopyImage := DllCall("GetProcAddress", "Ptr"
			, DllCall("LoadLibrary", "Str","Mfplat.dll", "Ptr")
			, "AStr","MFCopyImage", "Ptr")
		}
		if (MFCopyImage && !Reverse) {
			return DllCall(MFCopyImage
			, "Ptr",Scan01+y1*Stride1+x1*4, "int",Stride1
			, "Ptr",Scan02+y2*Stride2+x2*4, "int",Stride2
			, "uint",w*4, "uint",h)
		}
		listLines % (lls := A_ListLines)?0:0
		setBatchLines, % (bch := A_BatchLines)?"-1":"-1"
		p1 := Scan01+(y1-1)*Stride1+x1*4
		, p2 := Scan02+(y2-1)*Stride2+x2*4, w*=4
		, (Reverse) && (p2+=(h+1)*Stride2, Stride2 := -Stride2)
		loop, % h
			DllCall("RtlMoveMemory","Ptr",p1+=Stride1,"Ptr",p2+=Stride2,"Ptr",w)
		setBatchLines, % bch
		listLines % lls
	}

	drawHBM(hBM, lines) {
		local
		mDC := DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
		oBM := DllCall("SelectObject", "Ptr",mDC, "Ptr",hBM, "Ptr")
		oldc := "", brush := 0, varSetCapacity(rect, 16)
		for k,v in lines
		if isObject(v) {
			if (oldc!=v[5]) {
			oldc := v[5], BGR := (oldc&0xFF)<<16|oldc&0xFF00|(oldc>>16)&0xFF
			DllCall("DeleteObject", "Ptr",brush)
			brush := DllCall("CreateSolidBrush", "uint",BGR, "Ptr")
			}
			DllCall("SetRect", "Ptr",&rect, "int",v[1], "int",v[2]
			, "int",v[1]+v[3], "int",v[2]+v[4])
			DllCall("FillRect", "Ptr",mDC, "Ptr",&rect, "Ptr",brush)
		}
		DllCall("DeleteObject", "Ptr",brush)
		DllCall("SelectObject", "Ptr",mDC, "Ptr",oBM)
		DllCall("DeleteObject", "Ptr",mDC)
	}
	; by other windows, it's equivalent to always being
	; at the front desk. Unbind Window using find().BindWindow(0)

	bindWindow(bind_id := 0, bind_mode := 0, get_id := 0, get_mode := 0) {
		local
		(!isObject(this.bind) && this.bind := {id:0, mode:0, oldStyle:0})
		, bind := this.bind
		if (get_id)
			return bind.id
		if (get_mode)
			return bind.mode
		if (bind_id) {
			bind.id := bind_id := this.addZero(bind_id)
			, bind.mode := bind_mode, bind.oldStyle := 0
			if (bind_mode & 1) {
			winGet, i, ExStyle, ahk_id %bind_id%
			bind.oldStyle := i
			winSet, Transparent, 255, ahk_id %bind_id%
			loop, 30
			{
				sleep 100
				winGet, i, Transparent, ahk_id %bind_id%
			}
			until (i=255)
			}
		} else {
			bind_id := bind.id
			if (bind.mode & 1)
			winSet, ExStyle, % bind.oldStyle, ahk_id %bind_id%
			bind.id := 0, bind.mode := 0, bind.oldStyle := 0
		}
	}
	; Use find().CaptureCursor(0) to Cancel Capture Cursor

	captureCursor(hDC := 0, zx := 0, zy := 0, zw := 0, zh := 0, get_cursor := 0) {
		local
		if (get_cursor)
			return this.Cursor
		if (hDC=1 || hDC=0) && (zw=0) {
			this.Cursor := hDC
			return
		}
		varSetCapacity(mi, 40, 0), numPut(16+A_PtrSize, mi, "int")
		DllCall("GetCursorInfo", "Ptr",&mi)
		bShow := numGet(mi, 4, "int")
		hCursor := numGet(mi, 8, "Ptr")
		x := numGet(mi, 8+A_PtrSize, "int")
		y := numGet(mi, 12+A_PtrSize, "int")
		if (!bShow) || (x<zx || y<zy || x>=zx+zw || y>=zy+zh)
			return
		varSetCapacity(ni, 40, 0)
		DllCall("GetIconInfo", "Ptr",hCursor, "Ptr",&ni)
		xCenter := numGet(ni, 4, "int")
		yCenter := numGet(ni, 8, "int")
		hBMMask := numGet(ni, (A_PtrSize=8?16:12), "Ptr")
		hBMColor := numGet(ni, (A_PtrSize=8?24:16), "Ptr")
		DllCall("DrawIconEx", "Ptr",hDC
			, "int",x-xCenter-zx, "int",y-yCenter-zy, "Ptr",hCursor
			, "int",0, "int",0, "int",0, "int",0, "int",3)
		DllCall("DeleteObject", "Ptr",hBMMask)
		DllCall("DeleteObject", "Ptr",hBMColor)
	}

	mCode(hex) {
		local
		flag := ((hex~="[^\s\da-fA-F]") ? 1:4), len := 0
		loop, 2
			if !DllCall("crypt32\CryptStringToBinary", "Str",hex, "uint",0, "uint",flag
			, "Ptr",(A_Index=1?0:(p := this.buffer(len)).Ptr), "uint*",len, "Ptr",0, "Ptr",0)
			return
		if DllCall("VirtualProtect", "Ptr",p.Ptr, "Ptr",len, "uint",0x40, "uint*",0)
			return p
	}

	bin2hex(addr, size, base64 := 1) {
		local
		flag := (base64 ? 1:4)|0x40000000, len := 0
		loop, 2
			DllCall("crypt32\CryptBinaryToString", "Ptr",addr, "uint",size, "uint",flag
			, "Ptr",(A_Index=1?0:(p := this.buffer(len*2)).Ptr), "uint*",len)
		return regExReplace(StrGet(p.Ptr, len), "\s+")
	}

	base64tobit(s) {
		local
		listLines % (lls := A_ListLines)?0:0
		chars := "0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
		setformat, IntegerFast, d
		loop, parse, Chars
			if inStr(s, A_LoopField, 1)
			s := regExReplace(s, "[" A_LoopField "]", ((i := A_Index-1)>>5&1)
			. (i>>4&1) . (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1))
		s := regExReplace(regExReplace(s,"[^01]+"),"10*$")
		listLines % lls
		return s
	}

	bit2base64(s) {
		local
		listLines % (lls := A_ListLines)?0:0
		s := regExReplace(s,"[^01]+")
		s.=subStr("100000",1,6-Mod(strLen(s),6))
		s := regExReplace(s,".{6}","|$0")
		chars := "0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
		setformat, IntegerFast, d
		loop, parse, Chars
			s := strReplace(s, "|" . ((i := A_Index-1)>>5&1)
			. (i>>4&1) . (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1), A_LoopField)
		listLines % lls
		return s
	}

	ASCII(s) {
		local
		if regExMatch(s, "O)\$(\d+)\.([\w+/]+)", r) {
			s := regExReplace(this.base64tobit(r[2]),".{" r[1] "}","$0`n")
			s := strReplace(strReplace(s,"0","_"),"1","0")
		}
		else s := ""
		return s
	}
	; and Use find().PicLib(Text,1) to add the text library to PicLib()'s Lib,
	; Use find().PicLib("comment1|comment2|...") to get text images from Lib

	picLib(comments, add_to_Lib := 0, index := 1) {
		local
		(!isObject(this.Lib) && this.Lib := []), Lib := this.Lib
		, (!Lib.hasKey(index) && Lib[index]:=[]), Lib := Lib[index]
		if (add_to_Lib) {
			re := "O)<([^>\n]*)>[^$\n]+\$[^""\r\n]+"
			loop, parse, comments, |
			if regExMatch(A_LoopField, re, r) {
				s1 := trim(r[1]), s2 := ""
				loop, parse, s1
				s2.=format("_{:d}", Ord(A_LoopField))
				(s2!="") && Lib[s2]:=r[0]
			}
		} else {
			query := ""
			loop, parse, comments, |
			{
			s1 := trim(A_LoopField), s2 := ""
			loop, parse, s1
				s2.=format("_{:d}", Ord(A_LoopField))
			(Lib.hasKey(s2)) && Text.="|" Lib[s2]
			}
			return Text
		}
	}

	picN(Number, index := 1) {
		return this.PicLib(regExReplace(Number,".","|$0"), 0, index)
	}
	; Can't be used in ColorPos mode, because it can cause position errors

	picX(Text) {
		local
		if !regExMatch(Text, "O)(<[^$\n]+)\$(\d+)\.([\w+/]+)", r)
			return Text
		v := this.base64tobit(r[3]), query := ""
		c := strLen(strReplace(v,"0"))<=strLen(v)//2 ? "1":"0"
		txt := regExReplace(v,".{" r[2] "}","$0`n")
		while inStr(txt,c)
		{
			while !(txt~="m`n)^" c)
			txt := regExReplace(txt,"m`n)^.")
			i := 0
			while (txt~="m`n)^.{" i "}" c)
			i := format("{:d}",i+1)
			v := regExReplace(txt,"m`n)^(.{" i "}).*","$1")
			txt := regExReplace(txt,"m`n)^.{" i "}")
			if (v!="")
			text.="|" r[1] "$" i "." this.bit2base64(v)
		}
		return Text
	}

	screenShot(x1 := 0, y1 := 0, x2 := 0, y2 := 0) {
		this.find(x1, y1, x2, y2)
	}
	; If the point to get the color is beyond the range of
	; Screen, it will return White color (0xFFFFFF).

	getColor(x, y, fmt := 1) {
		local
		bits := this.getBitsFromScreen(,,,,0,zx,zy,zw,zh), x-=zx, y-=zy
		, c := (x>=0 && x<zw && y>=0 && y<zh && bits.Scan0)
		? numGet(bits.Scan0+y*bits.Stride+x*4,"uint") : 0xFFFFFF
		return (fmt ? format("0x{:06X}",c&0xFFFFFF) : c)
	}

	setColor(x, y, color := 0x000000) {
		local
		bits := this.getBitsFromScreen(,,,,0,zx,zy,zw,zh), x-=zx, y-=zy
		if (x>=0 && x<zw && y>=0 && y<zh && bits.Scan0)
			numPut(color, bits.Scan0+y*bits.Stride+x*4, "uint")
	}
	; based on the result returned by this.find().
	; offsetX is the maximum interval between two texts,
	; if it exceeds, a "*" sign will be inserted.
	; offsetY is the maximum height difference between two texts.
	; overlapW is used to set the width of the overlap.
	; Return Association array {text:Text, x:X, y:Y, w:W, h:H}
	resultMerge(resultsArr, offsetX:=20, offsetY:=20, overlapW:=0) {
		local
		mergeStr := "", min_X := "", max_X := "", min_Y := "", max_Y := ""
		topLeftX := topLeftY := ""
		bottomRightX := bottomRightY := ""
		; To keep track of the last text segment's x position
		lastX := 0
	
		; Iterate through each result to find min/max coordinates
		For k, value in resultsArr {
			x := value.1
			y := value.2
			w := value.3
			h := value.4
	
			; Update bounding box coordinates
			if (topLeftX = "" || x < topLeftX)
				topLeftX := x
			if (topLeftY = "" || y < topLeftY)
				topLeftY := y
			if (bottomRightX = "" || x + w > bottomRightX)
				bottomRightX := x + w
			if (bottomRightY = "" || y + h > bottomRightY)
				bottomRightY := y + h
	
			; Build the merged text result
			if (mergeStr != "" && x - lastX > offsetX)
				mergeStr .= "*"  ; Add "*" if there's a gap larger than offsetX
			mergeStr .= value.id
	
			; Update lastX position for next check
			lastX := x + w
		}
	
		; Calculate final width and height
		finalWidth := bottomRightX - topLeftX
		finalHeight := bottomRightY - topLeftY
	
		return {text: mergeStr, x: topLeftX, y: topLeftY, w: finalWidth, h: finalHeight}
	}


	; and top to bottom, ignore slight height difference

	sort(resultObj, dy := 10) {
		local
		if !isObject(resultObj)
			return resultObj
		s := "", n := 150000, ypos := []
		for k,v in resultObj {
			x := v.x, y := v.y, add := 1
			for k1,v1 in ypos
			if abs(y-v1)<=dy {
				y := v1, add := 0
				break
			}
			if (add)
			ypos.push(y)
			s.=(y*n+x) "." k "|"
		}
		s := trim(s,"|")
		sort, s, N D|
		resultObj2 := []
		loop, parse, s, |
			resultObj2.push( resultObj[strSplit(A_LoopField,".")[2]] )
		return resultObj2
	}

	sort2(resultObj, px, py) {
		local
		if !isObject(resultObj)
			return resultObj
		s := ""
		for k,v in resultObj
			s.=((v.x-px)**2+(v.y-py)**2) "." k "|"
		s := trim(s,"|")
		sort, s, N D|
		resultObj2 := []
		loop, parse, s, |
			resultObj2.push( resultObj[strSplit(A_LoopField,".")[2]] )
		return resultObj2
	}

	sort3(resultObj, dir := 1) {
		local
		if !isObject(resultObj)
			return resultObj
		s := "", n := 150000
		for k,v in resultObj
			x := v.1, y := v.2
			, s.=(dir=1 ? y*n+x
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
		loop, parse, s, |
			resultObj2.push( resultObj[strSplit(A_LoopField,".")[2]] )
		return resultObj2
	}

	bitmapFromScreen(ByRef x := 0, ByRef y := 0, ByRef w := 0, ByRef h := 0
	, ScreenShot := 1, ByRef zx := 0, ByRef zy := 0, ByRef zw := 0, ByRef zh := 0) {
		local
		bits := this.getBitsFromScreen(x,y,w,h,ScreenShot,zx,zy,zw,zh)
		if (w<1 || h<1 || !bits.hBM)
			return
		hBM := this.CreateDIBSection(w, h)
		this.CopyHBM(hBM, 0, 0, bits.hBM, x-zx, y-zy, w, h, 1)
		return hBM
	}
	; if file = 0 or "", save to Clipboard

	savePic(file := 0, x1 := 0, y1 := 0, x2 := 0, y2 := 0, ScreenShot := 1) {
		local
		x1 := this.addZero(x1), y1 := this.addZero(y1), x2 := this.addZero(x2), y2 := this.addZero(y2)
		if (x1=0 && y1=0 && x2=0 && y2=0)
			n := 150000, x := y := -n, w := h := 2*n
		else
			x := min(x1,x2), y := min(y1,y2), w := abs(x2-x1)+1, h := abs(y2-y1)+1
		hBM := this.BitmapFromScreen(x, y, w, h, ScreenShot)
		this.SaveBitmapToFile(file, hBM)
		DllCall("DeleteObject", "Ptr",hBM)
		}
		; hBM_or_file can be a bitmap handle or file path, eg: "c:\1.bmp"

	saveBitmapToFile(file, hBM_or_file, x := 0, y := 0, w := 0, h := 0) {
		local
		if hBM_or_file is number
			hBM_or_file := "HBITMAP:*" hBM_or_file
		if !hBM := DllCall("CopyImage", "Ptr",LoadPicture(hBM_or_file)
		, "int",0, "int",0, "int",0, "uint",0x2008)
			return
		if (file) || (w!=0 && h!=0) {
			(w=0 || h=0) && this.GetBitmapWH(hBM, w, h)
			hBM2 := this.CreateDIBSection(w, -h, bpp := (file ? 24 : 32))
			this.CopyHBM(hBM2, 0, 0, hBM, x, y, w, h)
			DllCall("DeleteObject", "Ptr",hBM), hBM := hBM2
		}
		varSetCapacity(dib, dib_size := (A_PtrSize=8 ? 104:84), 0)
		, DllCall("GetObject", "Ptr",hBM, "int",dib_size, "Ptr",&dib)
		, pbi := &dib+(bitmap_size := A_PtrSize=8 ? 32:24)
		, size := numGet(pbi+20, "uint"), pBits := numGet(pbi-A_PtrSize, "Ptr")
		if (!file) {
			hdib := DllCall("GlobalAlloc", "uint",2, "Ptr",40+size, "Ptr")
			pdib := DllCall("GlobalLock", "Ptr",hdib, "Ptr")
			DllCall("RtlMoveMemory", "Ptr",pdib, "Ptr",pbi, "Ptr",40)
			DllCall("RtlMoveMemory", "Ptr",pdib+40, "Ptr",pBits, "Ptr",size)
			DllCall("GlobalUnlock", "Ptr",hdib)
			DllCall("OpenClipboard", "Ptr",0)
			DllCall("EmptyClipboard")
			DllCall("SetClipboardData", "uint",8, "Ptr",hdib)
			DllCall("CloseClipboard")
		} else {
			if inStr(file,"\") && !FileExist(dir := regExReplace(file,"[^\\]*$"))
			try FileCreateDir, % dir
			varSetCapacity(bf, 14, 0), numPut(0x4D42, bf, "short")
			numPut(54+size, bf, 2, "uint"), numPut(54, bf, 10, "uint")
			f := FileOpen(file, "w"), f.RawWrite(bf, 14)
			, f.RawWrite(pbi+0, 40), f.RawWrite(pBits+0, size), f.Close()
		}
		DllCall("DeleteObject", "Ptr",hBM)
	}

	bitmapToWindow(hwnd, x1, y1, hBM, x2, y2, w, h) {
		local
		mDC := DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
		oBM := DllCall("SelectObject", "Ptr",mDC, "Ptr",hBM, "Ptr")
		hDC := DllCall("GetDC", "Ptr",hwnd, "Ptr")
		DllCall("BitBlt", "Ptr",hDC, "int",x1, "int",y1, "int",w, "int",h
			, "Ptr",mDC, "int",x2, "int",y2, "uint",0xCC0020)
		DllCall("ReleaseDC", "Ptr",hwnd, "Ptr",hDC)
		DllCall("SelectObject", "Ptr",mDC, "Ptr",oBM)
		DllCall("DeleteDC", "Ptr",mDC)
	}

	getTextFromScreen(x1 := 0, y1 := 0, x2 := 0, y2 := 0, Threshold := ""
	, ScreenShot := 1, ByRef rx := "", ByRef ry := "", cut := 1)
	{
		local
		x1 := this.addZero(x1), y1 := this.addZero(y1), x2 := this.addZero(x2), y2 := this.addZero(y2)
		if (x1=0 && y1=0 && x2=0 && y2=0)
			try return this.Gui("CaptureS", ScreenShot)
		setBatchLines, % (bch := A_BatchLines)?"-1":"-1"
		x := min(x1,x2), y := min(y1,y2), w := abs(x2-x1)+1, h := abs(y2-y1)+1
		bits := this.getBitsFromScreen(x,y,w,h,ScreenShot,zx,zy)
		if (w<1 || h<1 || !bits.Scan0) {
			setBatchLines, % bch
			return
		}
		listLines % (lls := A_ListLines)?0:0
		gs := []
		j := bits.Stride-w*4, p := bits.Scan0+(y-zy)*bits.Stride+(x-zx)*4-j-4
		loop, % h + 0*(k := 0)
		loop, % w + 0*(p+=j)
			c := numGet(0|p+=4,"uint")
			, gs[++k]:=(((c>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
		if inStr(Threshold,"**") {
			threshold := strReplace(Threshold,"*")
			if (Threshold="")
			threshold := 50
			s := "", sw := w, w-=2, h-=2, x++, y++
			loop, % h + 0*(y1 := 0)
			loop, % w + 0*(y1++)
			i := y1*sw+A_Index+1, j := gs[i]+Threshold
			, s.=( gs[i-1]>j || gs[i+1]>j
			|| gs[i-sw]>j || gs[i+sw]>j
			|| gs[i-sw-1]>j || gs[i-sw+1]>j
			|| gs[i+sw-1]>j || gs[i+sw+1]>j ) ? "1":"0"
			threshold := "**" Threshold
		} else {
			threshold := strReplace(Threshold,"*")
			if (Threshold="") {
			pp := []
			loop, 256
				pp[A_Index-1]:=0
			loop, % w*h
				pp[gs[A_Index]]++
			iP0 := IS0 := 0
			loop, 256
				k := A_Index-1, IP0+=k*pp[k], IS0+=pp[k]
			threshold := floor(IP0/IS0)
			loop, 20
			{
				lastThreshold := Threshold
				iP1 := IS1 := 0
				loop, % LastThreshold+1
				k := A_Index-1, IP1+=k*pp[k], IS1+=pp[k]
				iP2 := IP0-IP1, IS2 := IS0-IS1
				if (IS1!=0 && IS2!=0)
				threshold := floor((IP1/IS1+IP2/IS2)/2)
				if (Threshold=LastThreshold)
				break
			}
			}
			s := ""
			loop, % w*h
			s.=gs[A_Index]<=Threshold ? "1":"0"
			threshold := "*" Threshold
		}
		listLines % lls
		w := format("{:d}",w), CutUp := CutDown := 0
		if (cut=1) {
			re1 := "(^0{" w "}|^1{" w "})"
			re2 := "(0{" w "}$|1{" w "}$)"
			while (s~=re1)
			s := regExReplace(s,re1), CutUp++
			while (s~=re2)
			s := regExReplace(s,re2), CutDown++
		}
		rx := x+w//2, ry := y+CutUp+(h-CutUp-CutDown)//2
		s := "|<>" Threshold "$" w "." this.bit2base64(s)
		setBatchLines, % bch
		return s
	}
	; Take a Screenshot before using it: find().ScreenShot()

	waitChange(time := -1, x1 := 0, y1 := 0, x2 := 0, y2 := 0) {
		local
		hash := this.getPicHash(x1, y1, x2, y2, 0)
		time := this.addZero(time), timeout := A_TickCount+round(time*1000)
		loop
		{
			if (hash!=this.getPicHash(x1, y1, x2, y2, 1))
				return 1
			if (time>=0 && A_TickCount>=timeout)
				break
			sleep 10
		}
		return 0
	}

	waitNotChange(time := 1, timeout := 30, x1 := 0, y1 := 0, x2 := 0, y2 := 0) {
		local
		oldhash := "", time := this.addZero(time)
		, timeout := A_TickCount+round(this.addZero(timeout)*1000)
		loop
		{
			hash := this.getPicHash(x1, y1, x2, y2, 1), t := A_TickCount
			if (hash!=oldhash)
			oldhash := hash, timeout2 := t+round(time*1000)
			if (t>=timeout2)
			return 1
			if (t>=timeout)
			return 0
			sleep 100
		}
	}

	getPicHash(x1 := 0, y1 := 0, x2 := 0, y2 := 0, ScreenShot := 1) {
		local
		static init := DllCall("LoadLibrary", "Str","ntdll", "Ptr")
		x1 := this.addZero(x1), y1 := this.addZero(y1), x2 := this.addZero(x2), y2 := this.addZero(y2)
		if (x1=0 && y1=0 && x2=0 && y2=0)
			n := 150000, x := y := -n, w := h := 2*n
		else
			x := min(x1,x2), y := min(y1,y2), w := abs(x2-x1)+1, h := abs(y2-y1)+1
		bits := this.getBitsFromScreen(x,y,w,h,ScreenShot,zx,zy), x-=zx, y-=zy
		if (w<1 || h<1 || !bits.Scan0)
			return 0
		hash := 0, Stride := bits.Stride, p := bits.Scan0+(y-1)*Stride+x*4, w*=4
		listLines % (lls := A_ListLines)?0:0
		loop, % h
			hash := (hash*31+DllCall("ntdll\RtlComputeCrc32", "uint",0
			, "Ptr",p+=Stride, "uint",w, "uint"))&0xFFFFFFFF
		listLines % lls
		return hash
	}

	windowToScreen(ByRef x, ByRef y, x1, y1, id := "") {
		local
		if (!id)
			winGet, id, ID, A
		varSetCapacity(rect, 16, 0)
		, DllCall("GetWindowRect", "Ptr",id, "Ptr",&rect)
		, x := x1+numGet(rect,"int"), y := y1+numGet(rect,4,"int")
	}

	screenToWindow(ByRef x, ByRef y, x1, y1, id := "") {
		local
		this.windowToScreen(dx, dy, 0, 0, id), x := x1-dx, y := y1-dy
	}

	clientToScreen(ByRef x, ByRef y, x1, y1, id := "") {
		local
		if (!id)
			winGet, id, ID, A
		varSetCapacity(pt, 8, 0), numPut(0, pt, "int64")
		, DllCall("clientToScreen", "Ptr",id, "Ptr",&pt)
		, x := x1+numGet(pt,"int"), y := y1+numGet(pt,4,"int")
	}

	screenToClient(ByRef x, ByRef y, x1, y1, id := "") {
		local
		this.clientToScreen(dx, dy, 0, 0, id), x := x1-dx, y := y1-dy
		}
		; But like built-in command PixelGetColor using CoordMode Settings

		pixelGetColor(x, y, ScreenShot := 1, id := "") {
		if (A_CoordModePixel="Window")
			this.windowToScreen(x, y, x, y, id)
		else if (A_CoordModePixel="Client")
			this.clientToScreen(x, y, x, y, id)
		if (ScreenShot)
			this.ScreenShot(x, y, x, y)
		return this.GetColor(x, y)
	}
	; But like built-in command imageSearch using CoordMode Settings
	; ImageFile can use "*n *TransBlack/White/RRGGBB-DRDGDB... d:\a.bmp"

	imageSearch(ByRef rx := "", ByRef ry := "", x1 := 0, y1 := 0, x2 := 0, y2 := 0
	, ImageFile := "", ScreenShot := 1, FindAll := 0, dir := 1) {
		local
		dx := dy := 0
		if (A_CoordModePixel="Window")
			this.windowToScreen(dx, dy, 0, 0)
		else if (A_CoordModePixel="Client")
			this.clientToScreen(dx, dy, 0, 0)
		text := ""
		loop, parse, ImageFile, |
		if (v := trim(A_LoopField))!="" {
			text.=inStr(v,"$") ? "|" v : "|##"
			. (regExMatch(v, "O)(^|\s)\*(\d+)\s", r)
			? format("{:06X}", r[2]<<16|r[2]<<8|r[2]) : "000000")
			. (regExMatch(v, "Oi)(^|\s)\*Trans(\S+)\s", r) ? "/" trim(r[2],"/"):"")
			. "$" trim(regExReplace(v,"(^|\s)\*\S+"))
		}
		x1 := this.addZero(x1), y1 := this.addZero(y1), x2 := this.addZero(x2), y2 := this.addZero(y2)
		if (x1=0 && y1=0 && x2=0 && y2=0)
			n := 150000, x1 := y1 := -n, x2 := y2 := n
		if (resultObj := this.find(x1+dx, y1+dy, x2+dx, y2+dy
			, 0, 0, text, ScreenShot, FindAll,,,, dir)) {
			for k,v in resultObj
			v.1-=dx, v.2-=dy, v.x-=dx, v.y-=dy
			rx := resultObj[1].1, ry := resultObj[1].2, ErrorLevel := 0
			return resultObj
		} else {
			rx := ry := "", ErrorLevel := 1
			return 0
		}
	}
	; But like built-in command pixelSearch using CoordMode Settings
	; ColorID can use "RRGGBB-DRDGDB|RRGGBB-DRDGDB", Variation in 0-255

	pixelSearch(ByRef rx := "", ByRef ry := "", x1 := 0, y1 := 0, x2 := 0, y2 := 0
	, ColorID := "", Variation := 0, ScreenShot := 1, FindAll := 0, dir := 1)
	{
		local
		n := this.addZero(Variation), text := format("##{:06X}$0/0/", n<<16|n<<8|n)
		. trim(strReplace(ColorID, "|", "/"), "- /")
		return this.imageSearch(rx, ry, x1, y1, x2, y2, text, ScreenShot, FindAll, dir)
	}
	; ColorID can use "RRGGBB-DRDGDB|RRGGBB-DRDGDB", Variation in 0-255

	pixelCount(x1 := 0, y1 := 0, x2 := 0, y2 := 0, ColorID := "", Variation := 0, ScreenShot := 1) {
		local
		x1 := this.addZero(x1), y1 := this.addZero(y1), x2 := this.addZero(x2), y2 := this.addZero(y2)
		if (x1=0 && y1=0 && x2=0 && y2=0)
			n := 150000, x := y := -n, w := h := 2*n
		else
			x := min(x1,x2), y := min(y1,y2), w := abs(x2-x1)+1, h := abs(y2-y1)+1
		bits := this.getBitsFromScreen(x,y,w,h,ScreenShot,zx,zy), x-=zx, y-=zy
		sum := 0, varSetCapacity(s1,4), varSetCapacity(s0,4), varSetCapacity(ss,w*h)
		ini := { bits:bits, ss:&ss, s1:&s1, s0:&s0
			, err1:0, err0:0, allpos_max:0, zoomW:1, zoomH:1 }
		n := this.addZero(Variation), text := format("##{:06X}$0/0/", n<<16|n<<8|n)
		. trim(strReplace(ColorID, "|", "/"), "- /")
		if isObject(j := this.PicInfo(text))
			sum := this.PicFind(ini, j, 1, x, y, w, h, 0)
		return sum
	}
	; ColorID can use "RRGGBB1@0.8|RRGGBB2-DRDGDB2"
	; Count is the quantity within the range that must meet the criteria

	colorBlock(ColorID, w, h, Count) {
		local
		query := "|<>[" (1-Count/(w*h)) ",1]"
		. trim(strReplace(ColorID,"|","/"),"- /") . format("${:d}.",w)
		. this.bit2base64(strReplace(format(format("{{}:0{:d}d{}}",w*h),0),"0","1"))
		return Text
	}
}
