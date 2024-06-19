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
	static lastSearchQuery    := ""
	static lastSearchOptions   := {}
	; .scan
	static lastScanQuery    := ""
	static lastScanOptions   := {}

	;; Convience methods
	main_search(param_query, param_options := "")
	{
		; create default if needed
		if (!IsObject(param_options)) {
			param_options := this.defaultOptionsObj.Clone()
		}
		; merge with default for any blank parameters
		for Key, Value in this.defaultOptionsObj {
			if (param_options.HasKey(Key) == false) { ; if the key is existing in param_options
				param_options[Key] := Value
			}
		}

		; pass the parameters to .find and return
		return this.find(param_options.x1, param_options.y1, param_options.x2, param_options.y2, param_options.err1, param_options.err0, param_query
			, param_options.screenshot, param_options.findall, param_options.joinqueries, param_options.offsetx, param_options.offsety)
	}

	search(param_query, param_options := "") {
		; create default if needed
		if (!IsObject(param_options)) {
			param_options := this.defaultOptionsObj.Clone()
		}
		; save parameters for use in future
		this.lastSearchQuery := param_query
		this.lastSearchOptions := param_options

		; pass the parameters to .find and return
		return this.main_search(param_query, param_options)
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
		return this.main_search(this.lastSearchQuery, this.lastSearchOptions)
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
		return this.main_search(param_query, this.lastScanOptions)
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
		return this.main_search(this.lastScanQuery, this.lastScanOptions)
	}

	;; sorting methods
	; Sort the results from left to right and top to bottom, ignore slight height difference
	resultSort(param_resultsObj, param_dy := 10)
	{
		local
		if !IsObject(param_resultsObj)
		return param_resultsObj
		ypos := []
		For k,v in param_resultsObj
		{
		x := v.x, y := v.y, add := 1
		For k2,v2 in ypos
			if Abs(y-v2)<=param_dy
			{
			y := v2, add := 0
			break
			}
		if (add)
			ypos.Push(y)
		n := (y*150000+x) "." k, s := A_Index=1 ? n : s "-" n
		}
		sort, s, N D-
		param_resultsObj2 := []
		loop, Parse, s, -
		param_resultsObj2.Push( param_resultsObj[(StrSplit(A_LoopField,".")[2])] )
		return param_resultsObj2
	}

	; Re-order resultObj according to the nearest distance
	resultSortDistance(param_resultObj, param_x := "", param_y := "")
	{
		if (param_x == "") {
			param_x := A_ScreenWidth / 2
		}
		if (param_y == "") {
			param_y := A_ScreenWidth / 2
		}
		resultObj := param_resultObj.clone()
		for k, v in resultObj {
			x := v.1 + v.3 // 2
			y := v.2 + v.4 // 2
			n := ((x - param_x)**2 + (y - param_y)**2) "###" k
			; save the square root to the result object pre-sorting
			resultObj[A_Index].distance := round(sqrt(StrSplit(n, "###")[1]), 0)
			s := A_Index = 1 ? n : s "-" n
		}
		Sort, s, N D-
		resultObj2 := []
		loop, Parse, s, -
		{
			resultObj2.push(resultObj[(StrSplit(A_LoopField, "###")[2])])
		}
		return resultObj2
	}

	addZero(i)
	{
		if i is number
		return i+0
		else return 0
	}
	
	__New()
	{
		this.bits:={ Scan0: 0, hBM: 0, oldzw: 0, oldzh: 0 }
		this.bind:={ id: 0, mode: 0, oldStyle: 0 }
		this.Lib:=[]
		this.Cursor:=0
	}

	__Delete()
	{
		if (this.bits.hBM)
			Try DllCall("DeleteObject", "Ptr",this.bits.hBM)
	}

	New()
	{
		return new graphicsearch()
	}

	find(x1:=0, y1:=0, x2:=0, y2:=0, err1:=0, err0:=0, text:=""
		, ScreenShot:=1, FindAll:=1, JoinText:=0, offsetX:=20, offsetY:=10
		, dir:=1, zoomW:=1, zoomH:=1)
		{
		local
		SetBatchLines % (bch:=A_BatchLines)?"-1":"-1"
		x1:=this.addZero(x1), y1:=this.addZero(y1), x2:=this.addZero(x2), y2:=this.addZero(y2)
		if (x1=0 && y1=0 && x2=0 && y2=0)
			n:=150000, x:=y:=-n, w:=h:=2*n
		else
			x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
		bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy), x-=zx, y-=zy
		, this.ok:=0, info:=[]
		Loop Parse, text, |
			if IsObject(j:=this.PicInfo(A_LoopField))
			info.Push(j)
		if (w<1 || h<1 || !(num:=info.Length()) || !bits.Scan0)
		{
			SetBatchLines % bch
			return this.noMatchVal
		}
		arr:=[], info2:=[], k:=0, s:=""
		, mode:=(IsObject(JoinText) ? 2 : JoinText ? 1 : 0)
		For i,j in info
		{
			k:=Max(k, (j[7]=5 && j[8]=0 ? j[9] : j[2]*j[3]))
			if (mode)
			v:=(mode=1 ? i : j[10]) . "", (mode=1 && s.="|" v)
			, (!info2.HasKey(v) && info2[v]:=[]), (v!="" && info2[v].Push(j))
		}
		sx:=x, sy:=y, sw:=w, sh:=h
		, (mode=1 && JoinText:=[s])
		, VarSetCapacity(s1,k*4), VarSetCapacity(s0,k*4), VarSetCapacity(ss,sw*(sh+3))
		, allpos_max:=(FindAll || JoinText ? 10240 : 1)
		, ini:={ sx:sx, sy:sy, sw:sw, sh:sh, zx:zx, zy:zy
		, mode:mode, bits:bits, ss:&ss, s1:&s1, s0:&s0
		, err1:err1, err0:err0, allpos_max:allpos_max
		, zoomW:zoomW, zoomH:zoomH }
		Loop 2
		{
			if (err1=0 && err0=0) && (num>1 || A_Index>1)
			ini.err1:=err1:=0.05, ini.err0:=err0:=0.05
			if (!JoinText)
			{
			VarSetCapacity(allpos, allpos_max*4), allpos_ptr:=&allpos
			For i,j in info
			Loop % this.PicFind(ini, j, dir, sx, sy, sw, sh, allpos_ptr)
			{
				pos:=NumGet(allpos, 4*(A_Index-1), "uint")
				, x:=(pos&0xFFFF)+zx, y:=(pos>>16)+zy
				, w:=Floor(j[2]*zoomW), h:=Floor(j[3]*zoomH), comment:=j[10]
				, arr.Push({1:x, 2:y, 3:w, 4:h, x:x+w//2, y:y+h//2, id:comment})
				if (!FindAll)
				Break 3
			}
			}
			else
			For k,v in JoinText
			{
			v:=StrSplit(Trim(RegExReplace(v, "\s*\|[|\s]*", "|"), "|")
			, (InStr(v,"|")?"|":""), " `t")
			, this.JoinText(arr, ini, info2, v, 1, offsetX, offsetY
			, FindAll, dir, 0, 0, 0, sx, sy, sw, sh)
			if (!FindAll && arr.Length())
				Break 2
			}
			if (err1!=0 || err0!=0 || arr.Length() || info[1][4] || info[1][7]=5)
			Break
		}
		SetBatchLines % bch
		if (arr.Length())
		{
			OutputX:=arr[1].x, OutputY:=arr[1].y, this.ok:=arr
			return arr
		}
		return this.noMatchVal
	}

	JoinText(arr, ini, info2, text, index, offsetX, offsetY
	, FindAll, dir, minX, minY, maxY, sx, sy, sw, sh)
	{
		local
		if !(Len:=text.Length()) || !info2.HasKey(key:=text[index])
			return 0
		VarSetCapacity(allpos, ini.allpos_max*4), allpos_ptr:=&allpos
		, zoomW:=ini.zoomW, zoomH:=ini.zoomH, mode:=ini.mode
		For i,j in info2[key]
		if (mode!=2 || key==j[10])
		Loop % this.PicFind(ini, j, dir, sx, sy, (index=1 ? sw
		: Min(sx+offsetX+Floor(j[2]*zoomW),ini.sx+ini.sw)-sx), sh, allpos_ptr)
		{
			pos:=NumGet(allpos, 4*(A_Index-1), "uint")
			, x:=pos&0xFFFF, y:=pos>>16
			, w:=Floor(j[2]*zoomW), h:=Floor(j[3]*zoomH)
			, (index=1 && (minX:=x, minY:=y, maxY:=y+h))
			, minY1:=Min(y, minY), maxY1:=Max(y+h, maxY), sx1:=x+w
			if (index<Len)
			{
			sy1:=Max(minY1-offsetY, ini.sy)
			, sh1:=Min(maxY1+offsetY, ini.sy+ini.sh)-sy1
			if this.JoinText(arr, ini, info2, text, index+1, offsetX, offsetY
			, FindAll, 5, minX, minY1, maxY1, sx1, sy1, 0, sh1)
			&& (index>1 || !FindAll)
				return 1
			}
			else
			{
			comment:=""
			For k,v in text
				comment.=(mode=2 ? v : info2[v][1][10])
			x:=minX+ini.zx, y:=minY1+ini.zy, w:=sx1-minX, h:=maxY1-minY1
			, arr.Push({1:x, 2:y, 3:w, 4:h, x:x+w//2, y:y+h//2, id:comment})
			if (index>1 || !FindAll)
				return 1
			}
		}
		return 0
	}

	PicFind(ini, j, dir, sx, sy, sw, sh, allpos_ptr)
	{
		local
		static init, MyFunc
		if !VarSetCapacity(init) && (init:="1")
		{
			x32:="VVdWU4HskAAAAIuEJKQAAACLvCSoAAAAi6wk3AAAAMcEJAAAAACD6AGD+AQPh1gF"
			. "AACDvCSkAAAABQ+EWgUAAIuEJOAAAACFwA+OLw8AADHAibwkqAAAAMcEJAAAAADH"
			. "RCQUAAAAAMdEJAwAAAAAicfHRCQYAAAAAI20JgAAAACLhCTYAAAAi0wkGDH2MdsB"
			. "yIXtiUQkCH896ZAAAABmkA+vhCTEAAAAicGJ8Jn3@QHBi0QkCIA8GDF0TIuEJNQA"
			. "AACDwwEDtCT0AAAAiQy4g8cBOd10VIsEJJn3vCTgAAAAg7wkpAAAAAR1tQ+vhCS4"
			. "AAAAicGJ8Jn3@Y0MgYtEJAiAPBgxdbSLRCQMi5Qk0AAAAIPDAQO0JPQAAACJDIKD"
			. "wAE53YlEJAx1rAFsJBiDRCQUAYuMJPgAAACLRCQUAQwkOYQk4AAAAA+FMv@@@4tM"
			. "JAy7rYvbaIn+D6+MJOQAAACJfCQ0i7wkqAAAAInIwfkf9+vB+gwpyouMJOgAAACJ"
			. "VCRMD6@OicjB+R@368H6DCnKiVQkUIO8JKQAAAAED4R@CQAAi4QkzAAAAAOEJMQA"
			. "AACLtCS8AAAAi4wkuAAAAIlEJCiLhCS4AAAAD6+EJMAAAACNNLCLhCTEAAAA99iD"
			. "vCSkAAAAAY0EgYlEJDgPhHQJAACDvCSkAAAAAg+EDgcAAIuUJMgAAACF0g+O2wIA"
			. "AIuMJMQAAACLRCQoifXHBCQAAAAAx0QkCAAAAACJvCSoAAAAjQRIiUQkHInIweAC"
			. "iUQkFIuEJMQAAACFwH5ai4wktAAAAItcJByLvCS0AAAAA1wkCAHpA2wkFAHvjXYA"
			. "D7ZRAoPBBIPDAWvyJg+2Uf1rwkuNFAYPtnH8ifDB4AQp8AHQwfgHiEP@Ofl10ou0"
			. "JMQAAAABdCQIgwQkAQNsJDiLBCQ5hCTIAAAAdYeLhCTEAAAAi5QkrAAAADHtMfaD"
			. "6AGJRCQUi4QkyAAAAIPoAYlEJBiLhCTEAAAAhcAPjuIAAACLvCTEAAAAi0QkHAH3"
			. "jQwwifuJfCQgiccB2InzK5wkxAAAAIkEJDHAAfuLfCQoAfeLNCSJHCSJfCQIjXYA"
			. "hcAPhBwQAAA5RCQUD4QSEAAAhe0PhAoQAAA5bCQYD4QAEAAAD7YRD7Z5@7sBAAAA"
			. "A5QkqAAAADn6ckUPtnkBOfpyPYs8JA+2Pzn6cjMPtj45+nIsizwkD7Z@@zn6ciGL"
			. "PCQPtn8BOfpyFg+2fv85+nIOD7ZeATnaD5LDkI10JgCLfCQIiBwHg8ABg8EBg8YB"
			. "gwQkATmEJMQAAAAPhV@@@@+LdCQgg8UBOawkyAAAAA+F@@7@@4u8JKgAAACJlCSs"
			. "AAAAi4QkxAAAAMdEJBQAAAAAx0QkGAAAAACJvCSoAAAAg+gBiUQkCJCNtCYAAAAA"
			. "i4QkxAAAAIXAD46gAAAAi0QkGItcJCgxyYuUJMwAAAC@AwAAAAHDAdAPtjOJBCTr"
			. "EoXJD7ZzAQ+EBA8AAA+2O4PDATtMJAgPhP4OAAAPtmsBjVb@uAIAAACD+gF2E4P@"
			. "AQ+UwoP9AQ+UwAnQD7bAAcCB5v0AAAC6AQAAAHQShf8PlMKF7YnXD5TCidYJ94n6"
			. "izwkCdCIBA+DwQE5jCTEAAAAdY2LtCTEAAAAAXQkGINEJBQBi0QkFDmEJMgAAAAP"
			. "jzv@@@+LvCSoAAAAi0QkTIlEJAiLRCRQiUQkIOnAAgAAi4wkzAAAADHbi7Qk9AAA"
			. "AAHpi6wk+AAAAIXtfiaF9n4PjRQOicjGAACDwAE50HX2g8MBA4wkxAAAADmcJPgA"
			. "AAB12ouEJOwAAACDBCQBizQkhcAPhM0JAACLVCQsA5QkwAAAAItEJEADRCQoi4wk"
			. "7AAAAMHiEAnQO7Qk8AAAAIlEsfwPjJ0JAACLBCSBxJAAAABbXl9dwlgAMcCF@w+V"
			. "wIlEJFwPhKwHAACLhCTgAAAAi7Qk2AAAAIn5wekQifsPtskPttMPr8WNBIaJzg+v"
			. "8YlEJCSJ+A+2xIl0JDCJxg+v8InQD6@CiXQkBIlEJBCLhCTgAAAAhcAPjosNAACL"
			. "dCQkjQStAAAAAIn7iawk3AAAAIu8JKwAAACLbCQwiUQkPDHAx0QkLAAAAADHRCQ0"
			. "AAAAAMdEJAwAAAAAiTQki7Qk3AAAAIX2D44fAQAAi4wk2AAAAIs0JMdEJBgAAAAA"
			. "iVwkIAHBA0QkPIlMJBSJRCQ4A4Qk2AAAAIlEJCiNdgCLRCQUhf8PtlABD7ZIAg+2"
			. "AIkUJIlEJAh0SDHSjXQmAIsclonYwegQD7bAKcgPr8A5xXwjD7bHKwQkD6@AOUQk"
			. "BHwUD7bDK0QkCA+vwDlEJBAPje0CAACDwgE5+nXCiVwkIItEJAzB4RDB4AKJRCQc"
			. "i0QkLJn3vCTgAAAAD6+EJLgAAACJw4tEJBiZ97wk3AAAAItUJAyNBIOLnCTQAAAA"
			. "iQSTiwQkg8IBi5wk1AAAAIlUJAzB4AgJwQtMJAiLRCQciQwDg0QkFASLlCT0AAAA"
			. "i0QkFAFUJBg7RCQoD4Ue@@@@i1wkIItEJDiJNCSDRCQ0AYu0JPgAAACLTCQ0AXQk"
			. "LDmMJOAAAAAPhbH+@@+LTCQMuq2L22iJ3w+vjCTkAAAAx0QkIAAAAADHRCQ0AAAA"
			. "AInIwfkf9+rB+gwpyolUJAiLdCQMi0wkCDHAOc6LTCQgD07wiXQkDIt0JDQ5zg9P"
			. "xolEJDSLhCSkAAAAg+gEg@gBD4YIAwAAi4QkvAAAAMdEJBwAAAAAx4QkvAAAAAAA"
			. "AACDwAGJRCRAi4QkvAAAAAOEJMQAAAArhCT0AAAAiUQkGItEJBwDhCTIAAAAK4Qk"
			. "+AAAAIO8JLAAAAAJiUQkFA+ErgEAAIuEJLAAAACD6AGD+AcPh2QBAACD+AOJRCQ8"
			. "D45fAQAAi4QkvAAAAIt0JBzHBCQAAAAAiUQkVIl0JESJRCQci3QkVDl0JBiLRCRE"
			. "iYQkvAAAAA+M3fz@@4t0JEQ5dCQUD4y6CgAA9kQkPAKLdCRUifJ0DItEJBwDRCQY"
			. "KfCJwvZEJDwBi3QkRInwdA2LRCQUA4QkvAAAACnwi3QkPInRg@4DD0@ID0@CiUwk"
			. "LIlEJCjpgAUAAI22AAAAAI1HAccEJAAAAADHRCQIAAAAAMHgB4nHi4QkxAAAAMHg"
			. "AolEJBiLhCTIAAAAhcAPjqj7@@+LhCTEAAAAhcB+XIuMJLQAAACLXCQoi6wktAAA"
			. "AANcJAgB8QN0JBiJdCQUAfUPtlECD7ZBAQ+2MWvAS2vSJgHCifDB4AQp8AHQOccP"
			. "lwODwQSDwwE56XXVi4wkxAAAAAFMJAiLdCQUgwQkAQN0JDiLBCQ5hCTIAAAAdYXp"
			. "L@r@@4lcJCDpd@3@@8dEJDwAAAAAi0QkHIt0JBjHBCQAAAAAiUQkVItEJBSJdCQU"
			. "iUQkGIuEJLwAAACJRCRE6ZD+@@+LdCQYi4QkvAAAAItsJBzHRCRsAAAAAMdEJGgB"
			. "AAAAx0QkSAAAAAAB8MdEJGAAAAAAxwQkAAAAAInCweofAdDR+IlEJCiLRCQUAeiJ"
			. "wsHqHwHQ0fiJRCQsifArhCS8AAAAi3QkFI1YASnuicGNVgGJ8IPBCYneg8AJD6@y"
			. "OdMPT8GJdCR8icYPr@CJtCSAAAAAi3QkfDl0JGwPjef6@@+LtCSAAAAAOXQkYMdE"
			. "JGQAAAAAD43O+v@@i0wkaDlMJGQPjHIDAACLdCRIg0QkYAGJ8IPgAQHBifCLdCR8"
			. "g8ABiUwkaIPgAzl0JGyJRCRIfK@pkfr@@420JgAAAACLhCTAAAAAx0QkQAAAAADH"
			. "hCTAAAAAAAAAAIlEJBzp9vz@@4n4wegQD6+EJPgAAACZ97wk4AAAAA+vhCS4AAAA"
			. "icEPt8cPr4Qk9AAAAJn3@Y08gYtEJEyJRCQIi0QkUIlEJCDpWfz@@4uEJOAAAACL"
			. "nCTIAAAA0aQkrAAAAMdEJCwAAAAAx0QkPAAAAAAPr8UDhCTYAAAAiUQkJIuEJMQA"
			. "AADB4AKF24lEJFgPjjv5@@+JvCSoAAAAi3wkXIuMJMQAAACFyQ+O@wAAAItEJCgD"
			. "RCQ8i5wktAAAAInHi0QkWAHzid0B8In+iUQkQAOEJLQAAACJRCQg6xqNtCYAAAAA"
			. "xgYAg8UEg8YBO2wkIA+EqAAAAA+2RQIx@4kEJA+2RQGJRCQUD7ZFAIlEJBg7vCSs"
			. "AAAAc8uLRCQkixS4g8cCi0y4@A+23itcJBSJ0MHoEA+2wCsEJIlcJAgPttorXCQY"
			. "gfr@@@8AiVwkHA+GhAAAAIsUJI0cUI2TAAQAAA+v0A+vwotUJAgPr9LB4gsB0Lr+"
			. "BQAAKdqJ04tUJBwPr9oPr9qNFBg50XKExgYBg8UEg8YBO2wkIA+FWP@@@4uMJMQA"
			. "AAABTCQ8i3QkQINEJCwBA3QkOItEJCw5hCTIAAAAD4XY@v@@iXwkXIu8JKgAAADp"
			. "@@b@@4nKweoQD7baD7bVD7bJiVQkBInaiVwkMA+vwIlMJBAPr9M50A+PDv@@@4tc"
			. "JAiLTCQEidiJyg+vww+v0TnQD4@0@v@@i1QkHItMJBCJ04nID6@aD6@BOcMPj9r+"
			. "@@@pUf@@@4uEJKwAAACFwA+ERAIAAIuMJKwAAACLtCTQAAAAi4Qk1AAAAIucJNgA"
			. "AACJrCTcAAAAjTyOMcmJxYl8JAiLO4PGBIPDWIPFBIn4wegQD6+EJPgAAACZ97wk"
			. "4AAAAA+vhCS4AAAAiQQkD7fHD6+EJPQAAACZ97wk3AAAAIsUJI0EgolG@ItDrI0E"
			. "QYPBFolF@Dt0JAh1p4uEJKwAAACLjCTkAAAAuq2L22gPr8iJRCQMicjB+R@36onQ"
			. "wfgMKciLtCTYAAAAiUQkCMdEJCAAAAAAx0QkNAAAAACDxgiJdCQk6YX5@@+LRCQo"
			. "O4QkvAAAAA+M+wAAAIt0JBg58A+P7wAAAItEJCyLTCQcOcgPjN8AAACLTCQUOcgP"
			. "j9MAAACDRCRsAYl0JBSJTCQYx0QkPAkAAACLdCQ0i0QkDDnGD03Gg7wkpAAAAAOJ"
			. "xolEJDiLRCQsD48KAQAAD6+EJMQAAACLTCQohfaNLAgPhDv2@@+LXCQgi4wkzAAA"
			. "ADHSi3QkCAHpiVwkTOsskDlUJDR+GIucJNQAAACLBJMByPYAAXUHg2wkTAF4KYPC"
			. "ATlUJDgPhPb1@@85VCQMfs+LnCTQAAAAiwSTAciAOAF3voPuAXm5g3wkPAl0CoNE"
			. "JEQB6XX5@@+LRCQYi3QkFIlEJBSJdCQYi0QkSIXAdFODfCRIAQ+EXgQAAIN8JEgC"
			. "D4RJBAAAMcCDfCRIAw+UwClEJCiDRCRkAek++@@@x0QkUAAAAADHRCRMAAAAAMdE"
			. "JDQAAAAAx0QkDAAAAADp8@H@@4NsJCwB68oxwMdEJAwAAAAA6Vz+@@8Pr4QkuAAA"
			. "AIt0JCiDvCSkAAAABY0EsIlEJEwPhEkBAACLtCS0AAAAAfiLVCQ4D7Z0BgKF0ol0"
			. "JFCLtCS0AAAAD7Z0BgGJdCRYi7QktAAAAA+2BAaJRCRwD4Qt9f@@i0QkIIm8JKgA"
			. "AAAx7Yn3iUQkeItEJAiJRCR063Q5bCQ0fmGLhCTUAAAAi1QkTItcJFADFKgPtkwX"
			. "Ag+2RBcBK0QkWA+2FBcrVCRwic4B2SnejZkABAAAD6@AD6@eweALD6@eAcO4@gUA"
			. "ACnID6@CD6@CAcM5nCSsAAAAcgeDbCR4AXh8g8UBOWwkOA+E4wEAADlsJAx+houE"
			. "JNAAAACLVCRMi1wkUAMUqA+2TBcCD7ZEFwErRCRYD7YUFytUJHCJzgHZKd6NmQAE"
			. "AAAPr8APr97B4AsPr94Bw7j+BQAAKcgPr8IPr8IBwzmcJKwAAAAPgyj@@@+DbCR0"
			. "AQ+JHf@@@4u8JKgAAADpBP7@@4t0JFyF9g+FaAEAAItcJDiF2w+ECfT@@4uEJNAA"
			. "AACLXCQkMfaJvCSoAAAAiUQkUIuEJNQAAACJRCRYa0QkOBaJRCR4i0QkCIlEJHSL"
			. "fCRQi0QkTIn1idmJXCRwAweLO4l8JDiLfCRYiz+JvCSsAAAAi7wktAAAAA+2fAcC"
			. "ibwkhAAAAIu8JLQAAAAPtnwHAYm8JIgAAACLvCS0AAAAD7YEB4mEJIwAAADpegAA"
			. "AIsBi3kEg8UCwe8QicLB6hCJ+w+2+w+20otZBCuUJIQAAACJfCQwD6@@D7bfiVwk"
			. "BA+2WQQPr9I5+olcJBB@OItcJAQPttQrlCSIAAAAid8Pr9IPr@s5+n8ei1wkEA+2"
			. "wCuEJIwAAACJ2g+vwA+v0znQD471AAAAg8EIO6wkrAAAAA+Cef@@@4F8JDj@@@8A"
			. "i1wkcHcLg2wkdAEPiKb+@@+DRCRQBIPDWINEJFgEg8YWOXQkeA+F5P7@@4u8JKgA"
			. "AADprfL@@4tMJDiFyQ+EofL@@4t0JAgx2+sOkI10JgCDwwE5XCQ4dH2LvCTQAAAA"
			. "i0QkTAMEn4u8JNQAAACLFJ+LvCS0AAAAD7ZsBwKJ18HvEIn5D7b5i4wktAAAACn9"
			. "i7wktAAAAA+v7TlsJDAPtnwHAQ+2BAF8IYn5D7buD7b5Ke8Pr@85fCQEfA4Ptvop"
			. "+A+vwDlEJBB9hoPuAXmBidfp8fv@@4nX6Qfy@@+BfCQ4@@@@AItcJHAPhxf@@@@p"
			. "Hf@@@4t8JAjGBAcC6Vbw@@+@AwAAAOn18P@@vQMAAADp@PD@@4uEJLwAAACDRCRU"
			. "AYlEJETpCvX@@8dEJCAAAAAAx0QkCAAAAADHRCQMAAAAAMdEJDQAAAAA6Tb0@@+D"
			. "RCQsAem7+@@@g0QkKAHpsfv@@5CQkJCQkJCQkJCQkJA="
			x64:="QVdBVkFVQVRVV1ZTSIHsqAAAAESLvCQwAQAARIucJGABAACJjCTwAAAAi4Qk8AAA"
			. "AInRRImEJAABAABEiYwkCAEAAIu0JGgBAADHRCQQAAAAAIPoAYP4BA+HSQQAAIO8"
			. "JPAAAAAFD4RTBAAAhfYPjrQOAAAx7USJbCQgi7wk8AAAAIlsJBBMi6wkUAEAADHA"
			. "i6wkkAEAAESJZCQwMdtFMfbHRCQcAAAAAEGJxImUJPgAAABMY1QkHEUxyUUxwEwD"
			. "lCRYAQAARYXbfzPreQ8fAEEPr8eJwUSJyJlB9@sBwUOAPAIxdD1Jg8ABSWPGQQHp"
			. "QYPGAUU5w0GJTIUAfkOJ2Jn3@oP@BHXID6+EJBgBAACJwUSJyJlB9@tDgDwCMY0M"
			. "gXXDSIuUJEgBAABJg8ABSWPEQQHpQYPEAUU5w4kMgn+9RAFcJByDRCQQAQOcJJgB"
			. "AACLRCQQOcYPhVX@@@9FieBBua2L22hEiWQkLEQPr4QkcAEAAESLbCQgRItkJDCL"
			. "jCT4AAAARInAQcH4H0H36YnQwfgMRCnARIuEJHgBAACJRCRIRQ+vxkSJwEHB+B9B"
			. "9+nB+gxEKcKJVCRMg7wk8AAAAAQPhPkIAACLhCQYAQAAi5wkIAEAAElj@w+vhCQo"
			. "AQAASYn5TAOMJEABAACNBJiLnCQYAQAAiUQkIESJ+PfYg7wk8AAAAAGNBIOJRCQ4"
			. "D4TsCAAAg7wk8AAAAAIPhMwFAABEi5wkOAEAAEWF2w+OPAcAAEONBH9EiXQkMESL"
			. "dCQgMfYx7UiYSAOEJEABAABIiUQkEEKNBL0AAAAAiUQkHEWF@35bSIucJBABAABJ"
			. "Y8ZFMdJMjUQDAkhj3UgDXCQQQQ+2EEmDwAREa9omQQ+2UPtrwktBjRQDRQ+2WPpE"
			. "idjB4AREKdgB0MH4B0KIBBNJg8IBRTnXf8hEA3QkHEQB@YPGAUQDdCQ4ObQkOAEA"
			. "AHWPSI1HAUSLdCQwi5QkAAEAAEGNb@8x28dEJBwAAAAASIlEJCC4AQAAAESJbCQ8"
			. "SCn4RIl0JDhIiUQkMIuEJDgBAACD6AFBicZFhf8PjsUAAABIY3QkHEiLfCQgSItE"
			. "JBBMjRw3SIt8JDBNjSwxTI1EMAFJAcNMjRQ3SQHCMcBIhcAPhEAQAAA5xQ+EOBAA"
			. "AIXbD4QwEAAAQTneD4QnEAAAQQ+2UP9BD7Zw@r8BAAAAAco58nI+QQ+2MDnycjZB"
			. "D7Zy@znyci1BD7Zz@znyciRBD7Zy@jnychtBD7YyOfJyE0EPtnP+OfJyCkEPtjM5"
			. "8kAPksdBiHwFAEiDwAFJg8ABSYPDAUmDwgFBOccPj23@@@9EAXwkHIPDATmcJDgB"
			. "AAAPhSL@@@9Ei3QkOESLbCQ8iZQkAAEAAOmDBAAAi5QkmAEAAIXSfkFJY8FIA4Qk"
			. "QAEAAESLjCSQAQAATWPXRTHASInCMcBFhcl+DcYEAgBIg8ABQTnBf@NBg8ABTAHS"
			. "RDmEJJgBAAB124NEJBABSIO8JIABAAAAi3wkEA+EZQoAAItUJDADlCQoAQAATGPH"
			. "i0QkPANEJCDB4hAJ0Du8JIgBAABIi5QkgAEAAEKJRIL8D4wwCgAAi0QkEEiBxKgA"
			. "AABbXl9dQVxBXUFeQV@DMcCF0g+VwIlEJGwPhEMIAACJ8EQPtsHB6hBBD6@DD7bS"
			. "QYnUweACSJhIA4QkWAEAAEQPr+JIiUQkCA+2xUGJxUQPr+hEicBBD6@AhfaJRCQo"
			. "D463DgAAi7wkAAEAAEGNQ@+JtCRoAQAAi3QkKMdEJBwAAAAARTH2SI0EhQYAAADH"
			. "RCQgAAAAAMdEJCwAAAAAjVf@SIt8JAhEibwkMAEAAEiJRCQwQo0EnQAAAABEiZwk"
			. "YAEAAEiNXJcEiUQkOIu8JGABAACF@w+O7AAAAEhjRCQsSIu8JFgBAABMjVwHAkgD"
			. "RCQwSAH4Mf9IiUQkEA8fAIusJAABAABFD7YDRQ+2S@9FD7ZT@oXtdEBIi1QkCGaQ"
			. "iwqJyMHoEA+2wEQpwA+vwEE5xHwbD7bFRCnID6@AQTnFfA0PtsFEKdAPr8A5xn1a"
			. "SIPCBEg503XHi0QkHE1j@kHB4BBBweEIQYPGAUUJyJlFCdD3vCRoAQAAD6+EJBgB"
			. "AACJxYn4mfe8JGABAABIi5QkSAEAAI1EhQBCiQS6SIuEJFABAABGiQS4SYPDBAO8"
			. "JJABAABMO1wkEA+FQP@@@4t8JDgBfCQsg0QkIAGLlCSYAQAAi0QkIAFUJBw5hCRo"
			. "AQAAD4Xk@v@@RIuEJHABAAC6rYvbaESLvCQwAQAARIl0JCwx7UUPr8ZFMfZEicBB"
			. "wfgf9+rB+gxEKcKJVCQci3wkLIt0JBwxwDn3D074QTnuiXwkLEQPTvCLhCTwAAAA"
			. "g+gEg@gBD4aoAwAAi4QkIAEAADH2x4QkIAEAAAAAAACDwAGJRCQ8i4QkIAEAAEQB"
			. "+CuEJJABAABBicOLhCQ4AQAAAfArhCSYAQAAg7wkCAEAAAmJww+EYwIAAIuEJAgB"
			. "AACD6AGD+AcPhyQCAACD+AOJRCQ4D44fAgAAi4QkIAEAAIl0JEDHRCQQAAAAAIlE"
			. "JGiJxkQ7XCRoi0QkQImEJCABAAAPjA39@@87XCRAD4wUDAAA9kQkOAKLfCRoifp0"
			. "CEKNBB4p+InC9kQkOAGLfCRAifh0C4uEJCABAAAB2Cn4i3wkOEGJ0oP@A0QPT9AP"
			. "T8JEiVQkMIlEJCDpPAYAAESLlCQ4AQAAg8EBMfbB4Qcx@0KNLL0AAAAARYXSD45e"
			. "AQAARIl0JBBEi3QkIEWF@35ZSIucJBABAABJY8ZFMdJMjUQDAkhj30wByw8fRAAA"
			. "QQ+2EEEPtkD@RQ+2WP5rwEtr0iYBwkSJ2MHgBEQp2AHQOcFCD5cEE0mDwgFJg8AE"
			. "RTnXf8tBAe5EAf+DxgFEA3QkODm0JDgBAAB1kUSLdCQQRIl0JBBEiWQkIDHARIu0"
			. "JDgBAABMi6QkQAEAAEGNf@9EiWwkHDHtQYnFDx9EAABFhf8Pjo0AAABNY8VFMdK7"
			. "AwAAAEcPthwB6x0PH0QAAEWF0kcPtlwBAQ+EtQoAAEMPthwBSYPAAUE5+g+ErQoA"
			. "AEMPtnQBAUGNU@+4AgAAAIP6AXYTg@sBD5TCg@4BD5TACdAPtsABwEGB4@0AAAC6"
			. "AQAAAHQOhdtBD5TDhfYPlMJECdpBg8IBCdBFOddDiAQEdY1FAf2DxQFBOe4Pj17@"
			. "@@9Ei3QkEESLbCQcRItkJCCLRCRIi2wkTIlEJBzpTf3@@8dEJDgAAAAAidhEiduJ"
			. "dCRoQYnDi4QkIAEAAMdEJBAAAAAAiUQkQOnW@f@@i4QkIAEAAEWJ2EQrhCQgAQAA"
			. "x0QkfAAAAADHRCR4AQAAAMdEJEQAAAAAx0QkcAAAAABEAdjHRCQQAAAAAInCRY1I"
			. "AUGDwAnB6h8B0ESJz9H4iUQkII0EHonCweofAdDR+IlEJDCJ2CnwjVABg8AJD6@6"
			. "QTnRQQ9PwIm8JIwAAACJxw+v+Im8JJAAAACLvCSMAAAAOXwkfA+NXPr@@4u8JJAA"
			. "AAA5fCRwx0QkdAAAAAAPjUP6@@+LVCR4OVQkdA+MdwMAAIt8JESDRCRwAYn4g+AB"
			. "AcKJ+Iu8JIwAAACDwAGJVCR4g+ADOXwkfIlEJER8rOkD+v@@i7QkKAEAAMdEJDwA"
			. "AAAAx4QkKAEAAAAAAADpVPz@@4nIi2wkTMHoEA+vhCSYAQAAmff+D6+EJBgBAABB"
			. "icAPt8EPr4QkkAEAAJlB9@tBjQyAi0QkSIlEJBzpzfv@@4nwi7QkOAEAANGkJAAB"
			. "AABBD6@DSJhIA4QkWAEAAIX2SIlEJAgPjkT+@@9BjUf@RItUJGyLrCQAAQAAx0Qk"
			. "MAAAAADHRCQ8AAAAAEiNBIUGAAAARIm0JIgAAABEiWwkHEyJTCRQiYwk+AAAAEiJ"
			. "RCRYQo0EvQAAAABEibwkMAEAAIlEJGCLnCQwAQAAhdsPjjQBAABIY0QkIEiLvCQQ"
			. "AQAASGNcJDxIA1wkUEyNTAcCSANEJFhIAfhIiUQkEOsWxgMASYPBBEiDwwFMOUwk"
			. "EA+E4AAAAEEPtjlFD7Zx@0Ux0kUPtmn+TItcJAhBOepzz0GLE0GDwgJBi0sEidAP"
			. "tvZED7bCwegQRCn2RSnoD7bAKfiB+v@@@wB2OY0UeA+v9kSNugAEAABED6@4weYL"
			. "QQ+vxwHGuP4FAAAp0InCQQ+v0InQQQ+vwAHwOcFzUkmDwwjrmEGJzA+21Q+2yUHB"
			. "7BBBic+JTCQoRQ+25IlUJBxEieEPr8BBD6@MOch@0ItUJBwPr@aJ0A+vwjnGf8BE"
			. "icBEifpBD6@AQQ+v1znQf67GAwFJg8EESIPDAUw5TCQQD4Ug@@@@i3wkYAF8JCCL"
			. "vCQwAQAAAXwkPINEJDABi3QkOItEJDABdCQgOYQkOAEAAA+Fn@7@@0SLtCSIAAAA"
			. "RIlUJGxEi2wkHEyLTCRQi4wk+AAAAESLvCQwAQAA6X77@@9Ei7QkAAEAAEUxyTHb"
			. "TIuUJFgBAABFhfYPhB4CAABIi7wkSAEAAEiLrCRQAQAARIu0JJgBAABBiwpJg8JY"
			. "icjB6BBBD6@Gmff+D6+EJBgBAABBicAPt8EPr4QkkAEAAJlB9@tBjQSAQokEj0GL"
			. "QqyNBEODwxZCiUSNAEmDwQFEOYwkAAEAAHeui4QkAAEAAESLhCRwAQAAuq2L22hE"
			. "D6@AiUQkLESJwEHB+B@36sH6DEGJ1kUpxkiLhCRYAQAARIl0JBwx7UUx9kiDwAhI"
			. "iUQkCOnm+P@@i0QkIDuEJCABAAAPjPYAAABEOdgPj+0AAACLRCQwOfAPjOEAAAA5"
			. "2A+P2QAAAINEJHwBidjHRCQ4CQAAAESJ20GJw4tEJCxBOcZBD03Gg7wk8AAAAAOJ"
			. "x4tEJDAPjxQBAABBD6@Hi1QkIIX@RI0MEA+Er@X@@4tUJBxBiepFMcCJVCRM6ziQ"
			. "RDt0JEh+I0iLlCRQAQAARInIQgMEgkiLlCRAAQAA9gQCAXUGQYPqAXg9SYPAAUQ5"
			. "xw+OZ@X@@0Q5RCQsRIlEJEh+vUiLlCRIAQAARInIQgMEgkiLlCRAAQAAgDwCAXeg"
			. "g2wkTAF5mYN8JDgJdAqDRCRAAemy+P@@RInYQYnbicNEi0QkREWFwHROg3wkRAEP"
			. "hOwEAACDfCREAg+E1wQAADHAg3wkRAMPlMApRCQgg0QkdAHpPPv@@8dEJEwAAAAA"
			. "x0QkSAAAAABFMfbHRCQsAAAAAOl08v@@g2wkMAHrz0Ux9sdEJCwAAAAA6Wr+@@8P"
			. "r4QkGAEAAItUJCCDvCTwAAAABY0EkIlEJEwPhLMBAAAByEyLlCQQAQAAhf+NUAJI"
			. "Y9JBD7YUEolUJFCNUAFImEEPtgQCSGPSQQ+2FBKJRCRgiVQkWA+En@T@@4tEJBxE"
			. "iVwkSE2J04mMJPgAAACJrCSAAAAAiYQkiAAAADHASInB6aUAAABmLg8fhAAAAAAA"
			. "RDu0JJQAAAAPjoEAAABIi4QkUAEAAItUJExEi0wkUAMUiI1CAkiYRQ+2BAONQgFI"
			. "Y9JBD7YUE0iYK1QkYEEPtgQDRYnCRQHIK0QkWEUpykWNiAAEAABFD6@KD6@ARQ+v"
			. "ysHgC0EBwbj+BQAARCnAD6@CD6@CRAHIOYQkAAEAAHIOg6wkgAAAAAEPiKMAAABI"
			. "g8EBOc8PjgQDAAA7TCQsiYwklAAAAA+NVP@@@0iLlCRIAQAAi0QkTESLTCRQAwSK"
			. "jVACSGPSRQ+2BBONUAFImEEPtgQDSGPSK0QkYEEPthQTRYnCRQHIK1QkWEUpykWN"
			. "iAAEAABFD6@KD6@SRQ+vysHiC0EB0br+BQAARCnCD6@QD6@CRAHIOYQkAAEAAA+D"
			. "3P7@@4OsJIgAAAABD4nO@v@@RItcJEiLjCT4AAAA6aT9@@+LRCRshcAPhZcBAACF"
			. "@w+EE@P@@0iLhCRQAQAATIuMJEgBAABMi1QkCMdEJEgAAAAAiYwk+AAAAEiJRCRY"
			. "jUf@SY1EgQRIiYQkgAAAAItEJByJhCSIAAAAi3wkTEEDOUWLAotMJEiNVwGNRwJE"
			. "iUQkUEyLRCRYSGP@SGPSSJhIiVQkYEiLlCQQAQAARYsAD7YEAkSJhCQAAQAATYnQ"
			. "iYQklAAAAEiJ0EiLVCRgiUwkYA+2BBCJhCSYAAAASIuEJBABAAAPtgQ4iYQknAAA"
			. "AOt9QYsAQYt4BINEJGACicJBifxIifnB6hBBwewQQA+2@w+20iuUJJQAAABFD7bk"
			. "D7bNiXwkKEGJzYn5RInnQQ+v@A+v0jn6fzIPttQrlCSYAAAARInvQQ+v@Q+v0jn6"
			. "fxoPtsArhCScAAAAicoPr9EPr8A50A+OAAEAAEmDwAiLRCRgO4QkAAEAAA+Ccv@@"
			. "@4F8JFD@@@8Adw6DrCSIAAAAAQ+Ifv7@@0mDwQRJg8JYSINEJFgEg0QkSBZMOYwk"
			. "gAAAAA+Fwf7@@4uMJPgAAADphPH@@4X@D4R88f@@RItUJBxFMcmJfCRI6xMPH0AA"
			. "SYPBAUQ5TCRID45b8f@@SIu8JEgBAACLRCRMQgMEj0iLvCRQAQAAQosMj0iLvCQQ"
			. "AQAAjVACSGPSRA+2BBeJysHqEA+20kEp0I1QAUiYRQ+vwA+2BAdIY9IPthQXRTnE"
			. "fBsPtv0p+g+v0kE51XwOD7bRKdAPr8A5RCQofYNBg+oBD4l5@@@@6Vv7@@+BfCRQ"
			. "@@@@AA+HEf@@@+ka@@@@RItcJEjpMf@@@0HGRAUAAukm8P@@uwMAAADpRvX@@74D"
			. "AAAA6U@1@@+LhCQgAQAAg0QkaAGJRCRA6bfz@@8x7cdEJCwAAAAAx0QkHAAAAABF"
			. "MfbpAvP@@4NEJDAB6S37@@+DRCQgAekj+@@@kJCQkJA="
			MyFunc:=this.MCode(StrReplace((A_PtrSize=8?x64:x32),"@","/"))
		}
		text:=j[1], w:=j[2], h:=j[3]
		, err1:=this.addZero(j[4] ? j[5] : ini.err1)
		, err0:=this.addZero(j[4] ? j[6] : ini.err0)
		, mode:=j[7], color:=j[8], n:=j[9]
		return (!ini.bits.Scan0) ? 0 : DllCall(MyFunc.Ptr
			, "int",mode, "uint",color, "uint",n, "int",dir
			, "Ptr",ini.bits.Scan0, "int",ini.bits.Stride
			, "int",sx, "int",sy, "int",sw, "int",sh
			, "Ptr",ini.ss, "Ptr",ini.s1, "Ptr",ini.s0
			, "Ptr",text, "int",w, "int",h
			, "int",Floor(err1*10000), "int",Floor(err0*10000)
			, "Ptr",allpos_ptr, "int",ini.allpos_max
			, "int",Floor(w*ini.zoomW), "int",Floor(h*ini.zoomH))
	}

	PicInfo(text)
	{
		local
		if !InStr(text, "$")
			return
		static init, info, bmp
		if !VarSetCapacity(init) && (init:="1")
			info:=[], bmp:=[]
		key:=(r:=StrLen(v:=Trim(text,"|")))<10000 ? v
			: DllCall("ntdll\RtlComputeCrc32", "uint",0
			, "Ptr",&v, "uint",r*(1+!!A_IsUnicode), "uint")
		if info.HasKey(key)
			return info[key]
		comment:="", seterr:=err1:=err0:=0
		if RegExMatch(v, "O)<([^>\n]*)>", r)
			v:=StrReplace(v,r[0]), comment:=Trim(r[1])
		if RegExMatch(v, "O)\[([^\]\n]*)]", r)
		{
			v:=StrReplace(v,r[0]), r:=StrSplit(r[1] ",", ",")
			, seterr:=1, err1:=r[1], err0:=r[2]
		}
		color:=SubStr(v,1,InStr(v,"$")-1), v:=Trim(SubStr(v,InStr(v,"$")+1))
		mode:=InStr(color,"##") ? 5 : InStr(color,"#") ? 4
			: InStr(color,"**") ? 3 : InStr(color,"*") ? 2 : 1
		color:=RegExReplace(color, "[*#\s]")
		(mode=1 || mode=5) && color:=StrReplace(color,"0x")
		if (mode=5)
		{
			if !(v~="/[\s\-\w]+/[\s\-\w,/]+$")
			{
			if !(hBM:=LoadPicture(v))
				return
			this.GetBitmapWH(hBM, w, h)
			if (w<1 || h<1)
				return
			hBM2:=this.CreateDIBSection(w, h, 32, Scan0)
			this.CopyHBM(hBM2, 0, 0, hBM, 0, 0, w, h)
			DllCall("DeleteObject", "Ptr",hBM)
			if (!Scan0)
				return
			StrReplace(color, "-",, n)
			bmp.Push(buf:=this.Buffer(w*h*4 + n*4)), v:=buf.Ptr, p:=v+w*h*4-4
			DllCall("RtlMoveMemory", "Ptr",v, "Ptr",Scan0, "Ptr",w*h*4)
			DllCall("DeleteObject", "Ptr",hBM2)
			For k1,v1 in StrSplit(color, "-")
			if (k1>1)
				NumPut(this.ToRGB(v1), 0|p+=4, "uint")
			color:=this.addZero("0x" StrSplit(color "-", "-")[1])|0x1000000
			}
			else
			{
			arr:=StrSplit(Trim(RegExReplace(v, "i)\s|0x"), ","), ",")
			if !(n:=arr.Length())
				return
			bmp.Push(buf:=this.Buffer(n*22*4)), v:=buf.Ptr
			, color:=StrSplit(color "-", "-")[1]
			For k1,v1 in arr
			{
				r:=StrSplit(v1 "/", "/")
				, x:=this.addZero(r[1]), y:=this.addZero(r[2])
				, (A_Index=1) ? (x1:=x2:=x, y1:=y2:=y)
				: (x1:=Min(x1,x), x2:=Max(x2,x), y1:=Min(y1,y), y2:=Max(y2,y))
			}
			For k1,v1 in arr
			{
				r:=StrSplit(v1 "/", "/")
				, x:=this.addZero(r[1])-x1, y:=this.addZero(r[2])-y1
				, n1:=Min(Max(r.Length()-3, 0), 10)
				, NumPut(y<<16|x, 0|p:=v+(A_Index-1)*22*4, "uint")
				, NumPut(n1, 0|p+=4, "uint")
				Loop % n1
				k1:=(InStr(v1:=r[2+A_Index], "-")=1 ? 0x1000000:0)
				, c:=StrSplit(Trim(v1,"-") "-" color, "-")
				, NumPut(this.ToRGB(c[1])&0xFFFFFF|k1, 0|p+=4, "uint")
				, NumPut(this.addZero("0x" c[2]), 0|p+=4, "uint")
			}
			color:=0, w:=x2-x1+1, h:=y2-y1+1
			}
		}
		else
		{
			r:=StrSplit(v ".", "."), w:=this.addZero(r[1])
			, v:=this.base64tobit(r[2]), h:=StrLen(v)//w
			if (w<1 || h<1 || StrLen(v)!=w*h)
			return
			arr:=StrSplit(Trim(color, "/"), "/")
			if !(n:=arr.Length())
			return
			bmp.Push(buf:=this.Buffer(StrPut(v, "CP0") + n*2*4))
			, StrPut(v, buf.Ptr, "CP0"), v:=buf.Ptr, p:=v+w*h-4
			, color:=this.addZero(arr[1])
			if (mode=1)
			{
			For k1,v1 in arr
			{
				k1:=(InStr(v1, "@") ? 0x1000000:0)
				, r:=StrSplit(v1 "@1", "@"), x:=this.addZero(r[2])
				, x:=(x<=0||x>1?1:x), x:=Floor(4606*255*255*(1-x)*(1-x))
				, c:=StrSplit(Trim(r[1],"-") "-" Format("{:X}",x), "-")
				, NumPut(this.ToRGB(c[1])&0xFFFFFF|k1, 0|p+=4, "uint")
				, NumPut(this.addZero("0x" c[2]), 0|p+=4, "uint")
			}
			}
			else if (mode=4)
			{
			r:=StrSplit(arr[1] "@1", "@"), n:=this.addZero(r[2])
			, n:=(n<=0||n>1?1:n), n:=Floor(4606*255*255*(1-n)*(1-n))
			, c:=this.addZero(r[1]), color:=((c-1)//w)<<16|Mod(c-1,w)
			}
		}
		return info[key]:=[v, w, h, seterr, err1, err0, mode, color, n, comment]
	}

	ToRGB(color)
	{
		static init, tab
		if !VarSetCapacity(init) && (init:="1")
			tab:=Object("Black", "000000", "White", "FFFFFF"
			, "Red", "FF0000", "Green", "008000", "Blue", "0000FF"
			, "Yellow", "FFFF00", "Silver", "C0C0C0", "Gray", "808080"
			, "Teal", "008080", "Navy", "000080", "Aqua", "00FFFF"
			, "Olive", "808000", "Lime", "00FF00", "Fuchsia", "FF00FF"
			, "Purple", "800080", "Maroon", "800000")
		return this.addZero("0x" (tab.HasKey(color)?tab[color]:color))
	}

	Buffer(size, FillByte:="")
	{
		local
		buf:={}, buf.SetCapacity("_key", size), p:=buf.GetAddress("_key")
		, (FillByte!="" && DllCall("RtlFillMemory","Ptr",p,"Ptr",size,"uchar",FillByte))
		, buf.Ptr:=p, buf.Size:=size
		return buf
	}

	GetBitsFromScreen(ByRef x:=0, ByRef y:=0, ByRef w:=0, ByRef h:=0
	, ScreenShot:=1, ByRef zx:=0, ByRef zy:=0, ByRef zw:=0, ByRef zh:=0)
	{
		local
		static init, CAPTUREBLT
		if !VarSetCapacity(init) && (init:="1")
		{
			DllCall("Dwmapi\DwmIsCompositionEnabled", "Int*",i:=0)
			CAPTUREBLT:=i ? 0 : 0x40000000
		}
		(!IsObject(this.bits) && this.bits:={Scan0:0, hBM:0, oldzw:0, oldzh:0})
		, bits:=this.bits
		if (!ScreenShot && bits.Scan0)
		{
			zx:=bits.zx, zy:=bits.zy, zw:=bits.zw, zh:=bits.zh
			, w:=Min(x+w,zx+zw), x:=Max(x,zx), w-=x
			, h:=Min(y+h,zy+zh), y:=Max(y,zy), h-=y
			return bits
		}
		bch:=A_BatchLines, cri:=A_IsCritical
		Critical
		bits.BindWindow:=id:=this.BindWindow(0,0,1)
		if (id)
		{
			WinGet, id, ID, ahk_id %id%
			WinGetPos, zx, zy, zw, zh, ahk_id %id%
		}
		if (!id)
		{
			SysGet, zx, 76
			SysGet, zy, 77
			SysGet, zw, 78
			SysGet, zh, 79
		}
		this.UpdateBits(bits, zx, zy, zw, zh)
		, w:=Min(x+w,zx+zw), x:=Max(x,zx), w-=x
		, h:=Min(y+h,zy+zh), y:=Max(y,zy), h-=y
		if (!ScreenShot || w<1 || h<1 || !bits.hBM)
		{
			Critical % cri
			SetBatchLines % bch
			return bits
		}
		if IsFunc(k:="GetBitsFromScreen2")
			&& %k%(bits, x-zx, y-zy, w, h)
		{
			zx:=bits.zx, zy:=bits.zy, zw:=bits.zw, zh:=bits.zh
			Critical % cri
			SetBatchLines % bch
			return bits
		}
		mDC:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
		oBM:=DllCall("SelectObject", "Ptr",mDC, "Ptr",bits.hBM, "Ptr")
		if (id)
		{
			if (mode:=this.BindWindow(0,0,0,1))<2
			{
			hDC:=DllCall("GetDCEx", "Ptr",id, "Ptr",0, "int",3, "Ptr")
			DllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
				, "Ptr",hDC, "int",x-zx, "int",y-zy, "uint",0xCC0020|CAPTUREBLT)
			DllCall("ReleaseDC", "Ptr",id, "Ptr",hDC)
			}
			else
			{
			hBM2:=this.CreateDIBSection(zw, zh)
			mDC2:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
			oBM2:=DllCall("SelectObject", "Ptr",mDC2, "Ptr",hBM2, "Ptr")
			DllCall("PrintWindow", "Ptr",id, "Ptr",mDC2, "uint",(mode>3)*3)
			DllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
				, "Ptr",mDC2, "int",x-zx, "int",y-zy, "uint",0xCC0020)
			DllCall("SelectObject", "Ptr",mDC2, "Ptr",oBM2)
			DllCall("DeleteDC", "Ptr",mDC2)
			DllCall("DeleteObject", "Ptr",hBM2)
			}
		}
		else
		{
			hDC:=DllCall("GetWindowDC","Ptr",id:=DllCall("GetDesktopWindow","Ptr"),"Ptr")
			DllCall("BitBlt","Ptr",mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
			, "Ptr",hDC, "int",x, "int",y, "uint",0xCC0020|CAPTUREBLT)
			DllCall("ReleaseDC", "Ptr",id, "Ptr",hDC)
		}
		if this.CaptureCursor(0,0,0,0,0,1)
			this.CaptureCursor(mDC, zx, zy, zw, zh)
		DllCall("SelectObject", "Ptr",mDC, "Ptr",oBM)
		DllCall("DeleteDC", "Ptr",mDC)
		Critical % cri
		SetBatchLines % bch
		return bits
	}

	UpdateBits(bits, zx, zy, zw, zh)
	{
		local
		if (zw>bits.oldzw || zh>bits.oldzh || !bits.hBM)
		{
			Try DllCall("DeleteObject", "Ptr",bits.hBM)
			bits.hBM:=this.CreateDIBSection(zw, zh, bpp:=32, ppvBits)
			, bits.Scan0:=(!bits.hBM ? 0:ppvBits)
			, bits.Stride:=((zw*bpp+31)//32)*4
			, bits.oldzw:=zw, bits.oldzh:=zh
		}
		bits.zx:=zx, bits.zy:=zy, bits.zw:=zw, bits.zh:=zh
	}

	CreateDIBSection(w, h, bpp:=32, ByRef ppvBits:=0)
	{
		local
		VarSetCapacity(bi, 40, 0), NumPut(40, bi, 0, "int")
		, NumPut(w, bi, 4, "int"), NumPut(-h, bi, 8, "int")
		, NumPut(1, bi, 12, "short"), NumPut(bpp, bi, 14, "short")
		return DllCall("CreateDIBSection", "Ptr",0, "Ptr",&bi, "int",0, "Ptr*",ppvBits:=0, "Ptr",0, "int",0, "Ptr")
	}

	GetBitmapWH(hBM, ByRef w, ByRef h)
	{
		local
		VarSetCapacity(bm, size:=(A_PtrSize=8 ? 32:24))
		, DllCall("GetObject", "Ptr",hBM, "int",size, "Ptr",&bm)
		, w:=NumGet(bm,4,"int"), h:=Abs(NumGet(bm,8,"int"))
	}

	CopyHBM(hBM1, x1, y1, hBM2, x2, y2, w, h, Clear:=0)
	{
		local
		if (w<1 || h<1 || !hBM1 || !hBM2)
			return
		mDC1:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
		oBM1:=DllCall("SelectObject", "Ptr",mDC1, "Ptr",hBM1, "Ptr")
		mDC2:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
		oBM2:=DllCall("SelectObject", "Ptr",mDC2, "Ptr",hBM2, "Ptr")
		DllCall("BitBlt", "Ptr",mDC1, "int",x1, "int",y1, "int",w, "int",h
		, "Ptr",mDC2, "int",x2, "int",y2, "uint",0xCC0020)
		if (Clear)
			DllCall("BitBlt", "Ptr",mDC1, "int",x1, "int",y1, "int",w, "int",h
			, "Ptr",mDC1, "int",x1, "int",y1, "uint",MERGECOPY:=0xC000CA)
		DllCall("SelectObject", "Ptr",mDC1, "Ptr",oBM1)
		DllCall("DeleteDC", "Ptr",mDC1)
		DllCall("SelectObject", "Ptr",mDC2, "Ptr",oBM2)
		DllCall("DeleteDC", "Ptr",mDC2)
	}

	CopyBits(Scan01,Stride1,x1,y1,Scan02,Stride2,x2,y2,w,h,Reverse:=0)
	{
		local
		if (w<1 || h<1 || !Scan01 || !Scan02)
			return
		static init, MFCopyImage
		if !VarSetCapacity(init) && (init:="1")
		{
			MFCopyImage:=DllCall("GetProcAddress", "Ptr"
			, DllCall("LoadLibrary", "Str","Mfplat.dll", "Ptr")
			, "AStr","MFCopyImage", "Ptr")
		}
		if (MFCopyImage && !Reverse)
		{
			return DllCall(MFCopyImage
			, "Ptr",Scan01+y1*Stride1+x1*4, "int",Stride1
			, "Ptr",Scan02+y2*Stride2+x2*4, "int",Stride2
			, "uint",w*4, "uint",h)
		}
		ListLines % (lls:=A_ListLines)?0:0
		SetBatchLines % (bch:=A_BatchLines)?"-1":"-1"
		p1:=Scan01+(y1-1)*Stride1+x1*4
		, p2:=Scan02+(y2-1)*Stride2+x2*4, w*=4
		if (Reverse)
			p2+=(h+1)*Stride2, Stride2:=-Stride2
		Loop % h
			DllCall("RtlMoveMemory","Ptr",p1+=Stride1,"Ptr",p2+=Stride2,"Ptr",w)
		SetBatchLines % bch
		ListLines % lls
	}

	DrawHBM(hBM, lines)
	{
		local
		mDC:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
		oBM:=DllCall("SelectObject", "Ptr",mDC, "Ptr",hBM, "Ptr")
		oldc:="", brush:=0, VarSetCapacity(rect, 16)
		For k,v in lines
		if IsObject(v)
		{
			if (oldc!=v[5])
			{
			oldc:=v[5], BGR:=(oldc&0xFF)<<16|oldc&0xFF00|(oldc>>16)&0xFF
			DllCall("DeleteObject", "Ptr",brush)
			brush:=DllCall("CreateSolidBrush", "uint",BGR, "Ptr")
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
	; at the front desk. Unbind Window using graphicsearch().BindWindow(0)

	BindWindow(bind_id:=0, bind_mode:=0, get_id:=0, get_mode:=0)
	{
	local
	(!IsObject(this.bind) && this.bind:={id:0, mode:0, oldStyle:0})
	, bind:=this.bind
	if (get_id)
		return bind.id
	if (get_mode)
		return bind.mode
	if (bind_id)
	{
		bind.id:=bind_id:=this.addZero(bind_id)
		, bind.mode:=bind_mode, bind.oldStyle:=0
		if (bind_mode & 1)
		{
		WinGet, i, ExStyle, ahk_id %bind_id%
		bind.oldStyle:=i
		WinSet, Transparent, 255, ahk_id %bind_id%
		Loop 30
		{
			Sleep 100
			WinGet, i, Transparent, ahk_id %bind_id%
		}
		Until (i=255)
		}
	}
	else
	{
		bind_id:=bind.id
		if (bind.mode & 1)
		WinSet, ExStyle, % bind.oldStyle, ahk_id %bind_id%
		bind.id:=0, bind.mode:=0, bind.oldStyle:=0
	}
	}
	; Use graphicsearch().CaptureCursor(0) to Cancel Capture Cursor

	CaptureCursor(hDC:=0, zx:=0, zy:=0, zw:=0, zh:=0, get_cursor:=0)
	{
	local
	if (get_cursor)
		return this.Cursor
	if (hDC=1 || hDC=0) && (zw=0)
	{
		this.Cursor:=hDC
		return
	}
	VarSetCapacity(mi, 40, 0), NumPut(16+A_PtrSize, mi, "int")
	DllCall("GetCursorInfo", "Ptr",&mi)
	bShow:=NumGet(mi, 4, "int")
	hCursor:=NumGet(mi, 8, "Ptr")
	x:=NumGet(mi, 8+A_PtrSize, "int")
	y:=NumGet(mi, 12+A_PtrSize, "int")
	if (!bShow) || (x<zx || y<zy || x>=zx+zw || y>=zy+zh)
		return
	VarSetCapacity(ni, 40, 0)
	DllCall("GetIconInfo", "Ptr",hCursor, "Ptr",&ni)
	xCenter:=NumGet(ni, 4, "int")
	yCenter:=NumGet(ni, 8, "int")
	hBMMask:=NumGet(ni, (A_PtrSize=8?16:12), "Ptr")
	hBMColor:=NumGet(ni, (A_PtrSize=8?24:16), "Ptr")
	DllCall("DrawIconEx", "Ptr",hDC
		, "int",x-xCenter-zx, "int",y-yCenter-zy, "Ptr",hCursor
		, "int",0, "int",0, "int",0, "int",0, "int",3)
	DllCall("DeleteObject", "Ptr",hBMMask)
	DllCall("DeleteObject", "Ptr",hBMColor)
	}

	MCode(hex)
	{
	local
	flag:=((hex~="[^\s\da-fA-F]")?1:4), hex:=RegExReplace(hex, "[\s=]")
	code:=this.Buffer(len:=(flag=1 ? StrLen(hex)//4*3+3 : StrLen(hex)//2))
	DllCall("crypt32\CryptStringToBinary", "Str",hex, "uint",0
		, "uint",flag, "Ptr",code.Ptr, "uint*",len, "Ptr",0, "Ptr",0)
	DllCall("VirtualProtect", "Ptr",code.Ptr, "Ptr",len, "uint",0x40, "Ptr*",0)
	return code
	}

	bin2hex(addr, size, base64:=1)
	{
	local
	flag:=(base64 ? 1:4)|0x40000000, len:=0
	Loop 2
		DllCall("Crypt32\CryptBinaryToString", "Ptr",addr, "uint",size
		, "uint",flag, "Ptr",(A_Index=1?0:(p:=this.Buffer(len*2)).Ptr), "uint*",len)
	return RegExReplace(StrGet(p.Ptr, len), "\s+")
	}

	base64tobit(s)
	{
	local
	ListLines % (lls:=A_ListLines)?0:0
	Chars:="0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	SetFormat, IntegerFast, d
	Loop Parse, Chars
		if InStr(s, A_LoopField, 1)
		s:=RegExReplace(s, "[" A_LoopField "]", ((i:=A_Index-1)>>5&1)
		. (i>>4&1) . (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1))
	s:=RegExReplace(RegExReplace(s,"[^01]+"),"10*$")
	ListLines % lls
	return s
	}

	bit2base64(s)
	{
	local
	ListLines % (lls:=A_ListLines)?0:0
	s:=RegExReplace(s,"[^01]+")
	s.=SubStr("100000",1,6-Mod(StrLen(s),6))
	s:=RegExReplace(s,".{6}","|$0")
	Chars:="0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	SetFormat, IntegerFast, d
	Loop Parse, Chars
		s:=StrReplace(s, "|" . ((i:=A_Index-1)>>5&1)
		. (i>>4&1) . (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1), A_LoopField)
	ListLines % lls
	return s
	}

	ASCII(s)
	{
	local
	if RegExMatch(s, "O)\$(\d+)\.([\w+/]+)", r)
	{
		s:=RegExReplace(this.base64tobit(r[2]),".{" r[1] "}","$0`n")
		s:=StrReplace(StrReplace(s,"0","_"),"1","0")
	}
	else s:=""
	return s
	}
	; and Use graphicsearch().PicLib(Text,1) to add the text library to PicLib()'s Lib,
	; Use graphicsearch().PicLib("comment1|comment2|...") to get text images from Lib

	PicLib(comments, add_to_Lib:=0, index:=1)
	{
	local
	(!IsObject(this.Lib) && this.Lib:=[]), Lib:=this.Lib
	, (!Lib.HasKey(index) && Lib[index]:=[]), Lib:=Lib[index]
	if (add_to_Lib)
	{
		re:="O)<([^>\n]*)>[^$\n]+\$[^""\r\n]+"
		Loop Parse, comments, |
		if RegExMatch(A_LoopField, re, r)
		{
			s1:=Trim(r[1]), s2:=""
			Loop Parse, s1
			s2.=Format("_{:d}", Ord(A_LoopField))
			Lib[s2]:=r[0]
		}
		Lib[""]:=""
	}
	else
	{
		Text:=""
		Loop Parse, comments, |
		{
		s1:=Trim(A_LoopField), s2:=""
		Loop Parse, s1
			s2.=Format("_{:d}", Ord(A_LoopField))
		if Lib.HasKey(s2)
			Text.="|" . Lib[s2]
		}
		return Text
	}
	}

	PicN(Number, index:=1)
	{
	return this.PicLib(RegExReplace(Number,".","|$0"), 0, index)
	}
	; Can't be used in ColorPos mode, because it can cause position errors

	PicX(Text)
	{
	local
	if !RegExMatch(Text, "O)(<[^$\n]+)\$(\d+)\.([\w+/]+)", r)
		return Text
	v:=this.base64tobit(r[3]), Text:=""
	c:=StrLen(StrReplace(v,"0"))<=StrLen(v)//2 ? "1":"0"
	txt:=RegExReplace(v,".{" r[2] "}","$0`n")
	While InStr(txt,c)
	{
		While !(txt~="m`n)^" c)
		txt:=RegExReplace(txt,"m`n)^.")
		i:=0
		While (txt~="m`n)^.{" i "}" c)
		i:=Format("{:d}",i+1)
		v:=RegExReplace(txt,"m`n)^(.{" i "}).*","$1")
		txt:=RegExReplace(txt,"m`n)^.{" i "}")
		if (v!="")
		Text.="|" r[1] "$" i "." this.bit2base64(v)
	}
	return Text
	}

	ScreenShot(x1:=0, y1:=0, x2:=0, y2:=0)
	{
	this.graphicsearch(,, x1, y1, x2, y2)
	}
	; If the point to get the color is beyond the range of
	; Screen, it will return White color (0xFFFFFF).

	GetColor(x, y, fmt:=1)
	{
	local
	bits:=this.GetBitsFromScreen(,,,,0,zx,zy,zw,zh), x-=zx, y-=zy
	, c:=(x>=0 && x<zw && y>=0 && y<zh && bits.Scan0)
	? NumGet(bits.Scan0+y*bits.Stride+x*4,"uint") : 0xFFFFFF
	return (fmt ? Format("0x{:06X}",c&0xFFFFFF) : c)
	}

	SetColor(x, y, color:=0x000000)
	{
	local
	bits:=this.GetBitsFromScreen(,,,,0,zx,zy,zw,zh), x-=zx, y-=zy
	if (x>=0 && x<zw && y>=0 && y<zh && bits.Scan0)
		NumPut(color, bits.Scan0+y*bits.Stride+x*4, "uint")
	}
	; based on the result returned by graphicsearch().
	; offsetX is the maximum interval between two texts,
	; if it exceeds, a "*" sign will be inserted.
	; offsetY is the maximum height difference between two texts.
	; overlapW is used to set the width of the overlap.
	; Return Association array {text:Text, x:X, y:Y, w:W, h:H}

	Ocr(ok, offsetX:=20, offsetY:=20, overlapW:=0)
	{
	local
	ocr_Text:=ocr_X:=ocr_Y:=min_X:=dx:=""
	For k,v in ok
		x:=v.1
		, min_X:=(A_Index=1 || x<min_X ? x : min_X)
		, max_X:=(A_Index=1 || x>max_X ? x : max_X)
	While (min_X!="" && min_X<=max_X)
	{
		LeftX:=""
		For k,v in ok
		{
		x:=v.1, y:=v.2
		if (x<min_X) || (ocr_Y!="" && Abs(y-ocr_Y)>offsetY)
			Continue
		if (LeftX="" || x<LeftX)
			LeftX:=x, LeftY:=y, LeftW:=v.3, LeftH:=v.4, LeftOCR:=v.id
		}
		if (LeftX="")
		Break
		if (ocr_X="")
		ocr_X:=LeftX, min_Y:=LeftY, max_Y:=LeftY+LeftH
		ocr_Text.=(ocr_Text!="" && LeftX>dx ? "*":"") . LeftOCR
		min_X:=LeftX+LeftW-(overlapW>LeftW//2 ? LeftW//2:overlapW)
		, dx:=LeftX+LeftW+offsetX, ocr_Y:=LeftY
		, (LeftY<min_Y && min_Y:=LeftY)
		, (LeftY+LeftH>max_Y && max_Y:=LeftY+LeftH)
	}
	if (ocr_X="")
		ocr_X:=0, min_Y:=0, min_X:=0, max_Y:=0
	return {text:ocr_Text, x:ocr_X, y:min_Y
		, w: min_X-ocr_X, h: max_Y-min_Y}
	}
	; and top to bottom, ignore slight height difference

	Sort(ok, dy:=10)
	{
	local
	if !IsObject(ok)
		return ok
	s:="", n:=150000, ypos:=[]
	For k,v in ok
	{
		x:=v.x, y:=v.y, add:=1
		For k1,v1 in ypos
		if Abs(y-v1)<=dy
		{
		y:=v1, add:=0
		Break
		}
		if (add)
		ypos.Push(y)
		s.=(y*n+x) "." k "|"
	}
	s:=Trim(s,"|")
	Sort, s, N D|
	ok2:=[]
	Loop Parse, s, |
		ok2.Push( ok[StrSplit(A_LoopField,".")[2]] )
	return ok2
	}

	Sort2(ok, px, py)
	{
	local
	if !IsObject(ok)
		return ok
	s:=""
	For k,v in ok
		s.=((v.x-px)**2+(v.y-py)**2) "." k "|"
	s:=Trim(s,"|")
	Sort, s, N D|
	ok2:=[]
	Loop Parse, s, |
		ok2.Push( ok[StrSplit(A_LoopField,".")[2]] )
	return ok2
	}

	Sort3(ok, dir:=1)
	{
	local
	if !IsObject(ok)
		return ok
	s:="", n:=150000
	For k,v in ok
		x:=v.1, y:=v.2
		, s.=(dir=1 ? y*n+x
		: dir=2 ? y*n-x
		: dir=3 ? -y*n+x
		: dir=4 ? -y*n-x
		: dir=5 ? x*n+y
		: dir=6 ? x*n-y
		: dir=7 ? -x*n+y
		: dir=8 ? -x*n-y : y*n+x) "." k "|"
	s:=Trim(s,"|")
	Sort, s, N D|
	ok2:=[]
	Loop Parse, s, |
		ok2.Push( ok[StrSplit(A_LoopField,".")[2]] )
	return ok2
	}

	MouseTip(x:="", y:="", w:=10, h:=10, d:=3)
	{
	local
	if (x="")
	{
		VarSetCapacity(pt,16,0), DllCall("GetCursorPos","Ptr",&pt)
		x:=NumGet(pt,0,"uint"), y:=NumGet(pt,4,"uint")
	}
	Loop 4
	{
		this.RangeTip(x-w, y-h, 2*w+1, 2*h+1, (A_Index & 1 ? "Red":"Blue"), d)
		Sleep 500
	}
	this.RangeTip()
	}

	BitmapFromScreen(ByRef x:=0, ByRef y:=0, ByRef w:=0, ByRef h:=0
	, ScreenShot:=1, ByRef zx:=0, ByRef zy:=0, ByRef zw:=0, ByRef zh:=0)
	{
	local
	bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy,zw,zh)
	if (w<1 || h<1 || !bits.hBM)
		return
	hBM:=this.CreateDIBSection(w, h)
	this.CopyHBM(hBM, 0, 0, bits.hBM, x-zx, y-zy, w, h, 1)
	return hBM
	}
	; if file = 0 or "", save to Clipboard

	SavePic(file:=0, x1:=0, y1:=0, x2:=0, y2:=0, ScreenShot:=1)
	{
	local
	x1:=this.addZero(x1), y1:=this.addZero(y1), x2:=this.addZero(x2), y2:=this.addZero(y2)
	if (x1=0 && y1=0 && x2=0 && y2=0)
		n:=150000, x:=y:=-n, w:=h:=2*n
	else
		x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
	hBM:=this.BitmapFromScreen(x, y, w, h, ScreenShot)
	this.SaveBitmapToFile(file, hBM)
	DllCall("DeleteObject", "Ptr",hBM)
	}
	; hBM_or_file can be a bitmap handle or file path, eg: "c:\1.bmp"

	SaveBitmapToFile(file, hBM_or_file, x:=0, y:=0, w:=0, h:=0)
	{
	local
	if hBM_or_file is number
		hBM_or_file:="HBITMAP:*" hBM_or_file
	if !hBM:=DllCall("CopyImage", "Ptr",LoadPicture(hBM_or_file)
	, "int",0, "int",0, "int",0, "uint",0x2008)
		return
	if (file) || (w!=0 && h!=0)
	{
		(w=0 || h=0) && this.GetBitmapWH(hBM, w, h)
		hBM2:=this.CreateDIBSection(w, -h, bpp:=(file ? 24 : 32))
		this.CopyHBM(hBM2, 0, 0, hBM, x, y, w, h)
		DllCall("DeleteObject", "Ptr",hBM), hBM:=hBM2
	}
	VarSetCapacity(dib, dib_size:=(A_PtrSize=8 ? 104:84), 0)
	, DllCall("GetObject", "Ptr",hBM, "int",dib_size, "Ptr",&dib)
	, pbi:=&dib+(bitmap_size:=A_PtrSize=8 ? 32:24)
	, size:=NumGet(pbi+20, "uint"), pBits:=NumGet(pbi-A_PtrSize, "Ptr")
	if (!file)
	{
		hdib:=DllCall("GlobalAlloc", "uint",2, "Ptr",40+size, "Ptr")
		pdib:=DllCall("GlobalLock", "Ptr",hdib, "Ptr")
		DllCall("RtlMoveMemory", "Ptr",pdib, "Ptr",pbi, "Ptr",40)
		DllCall("RtlMoveMemory", "Ptr",pdib+40, "Ptr",pBits, "Ptr",size)
		DllCall("GlobalUnlock", "Ptr",hdib)
		DllCall("OpenClipboard", "Ptr",0)
		DllCall("EmptyClipboard")
		if !DllCall("SetClipboardData", "uint",8, "Ptr",hdib)
		DllCall("GlobalFree", "Ptr",hdib)
		DllCall("CloseClipboard")
	}
	else
	{
		if InStr(file,"\") && !FileExist(dir:=RegExReplace(file,"[^\\]*$"))
		Try FileCreateDir, % dir
		VarSetCapacity(bf, 14, 0), NumPut(0x4D42, bf, "short")
		NumPut(54+size, bf, 2, "uint"), NumPut(54, bf, 10, "uint")
		f:=FileOpen(file, "w"), f.RawWrite(bf, 14)
		, f.RawWrite(pbi+0, 40), f.RawWrite(pBits+0, size), f.Close()
	}
	DllCall("DeleteObject", "Ptr",hBM)
	}

	ShowPic(file:="", show:=1, ByRef x:="", ByRef y:="", ByRef w:="", ByRef h:="")
	{
	local
	if (file="")
	{
		this.ShowScreenShot()
		return
	}
	if !(hBM:=LoadPicture(file))
		return
	this.GetBitmapWH(hBM, w, h)
	bits:=this.GetBitsFromScreen(,,,,0,x,y,zw,zh)
	this.UpdateBits(bits, x, y, Max(w,zw), Max(h,zh))
	this.CopyHBM(bits.hBM, 0, 0, hBM, 0, 0, w, h)
	DllCall("DeleteObject", "Ptr",hBM)
	if (show)
		this.ShowScreenShot(x, y, x+w-1, y+h-1, 0)
	}

	BitmapToWindow(hwnd, x1, y1, hBM, x2, y2, w, h)
	{
	local
	mDC:=DllCall("CreateCompatibleDC", "Ptr",0, "Ptr")
	oBM:=DllCall("SelectObject", "Ptr",mDC, "Ptr",hBM, "Ptr")
	hDC:=DllCall("GetDC", "Ptr",hwnd, "Ptr")
	DllCall("BitBlt", "Ptr",hDC, "int",x1, "int",y1, "int",w, "int",h
		, "Ptr",mDC, "int",x2, "int",y2, "uint",0xCC0020)
	DllCall("ReleaseDC", "Ptr",hwnd, "Ptr",hDC)
	DllCall("SelectObject", "Ptr",mDC, "Ptr",oBM)
	DllCall("DeleteDC", "Ptr",mDC)
	}

	GetTextFromScreen(x1:=0, y1:=0, x2:=0, y2:=0, Threshold:=""
	, ScreenShot:=1, ByRef rx:="", ByRef ry:="", cut:=1)
	{
	local
	x1:=this.addZero(x1), y1:=this.addZero(y1), x2:=this.addZero(x2), y2:=this.addZero(y2)
	if (x1=0 && y1=0 && x2=0 && y2=0)
		return this.Gui("CaptureS", ScreenShot)
	SetBatchLines % (bch:=A_BatchLines)?"-1":"-1"
	x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
	bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy)
	if (w<1 || h<1 || !bits.Scan0)
	{
		SetBatchLines % bch
		return
	}
	ListLines % (lls:=A_ListLines)?0:0
	gs:=[]
	j:=bits.Stride-w*4, p:=bits.Scan0+(y-zy)*bits.Stride+(x-zx)*4-j-4
	Loop % h + 0*(k:=0)
	Loop % w + 0*(p+=j)
		c:=NumGet(0|p+=4,"uint")
		, gs[++k]:=(((c>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
	if InStr(Threshold,"**")
	{
		Threshold:=StrReplace(Threshold,"*")
		if (Threshold="")
		Threshold:=50
		s:="", sw:=w, w-=2, h-=2, x++, y++
		Loop % h + 0*(y1:=0)
		Loop % w + 0*(y1++)
		i:=y1*sw+A_Index+1, j:=gs[i]+Threshold
		, s.=( gs[i-1]>j || gs[i+1]>j
		|| gs[i-sw]>j || gs[i+sw]>j
		|| gs[i-sw-1]>j || gs[i-sw+1]>j
		|| gs[i+sw-1]>j || gs[i+sw+1]>j ) ? "1":"0"
		Threshold:="**" Threshold
	}
	else
	{
		Threshold:=StrReplace(Threshold,"*")
		if (Threshold="")
		{
		pp:=[]
		Loop 256
			pp[A_Index-1]:=0
		Loop % w*h
			pp[gs[A_Index]]++
		IP0:=IS0:=0
		Loop 256
			k:=A_Index-1, IP0+=k*pp[k], IS0+=pp[k]
		Threshold:=Floor(IP0/IS0)
		Loop 20
		{
			LastThreshold:=Threshold
			IP1:=IS1:=0
			Loop % LastThreshold+1
			k:=A_Index-1, IP1+=k*pp[k], IS1+=pp[k]
			IP2:=IP0-IP1, IS2:=IS0-IS1
			if (IS1!=0 && IS2!=0)
			Threshold:=Floor((IP1/IS1+IP2/IS2)/2)
			if (Threshold=LastThreshold)
			Break
		}
		}
		s:=""
		Loop % w*h
		s.=gs[A_Index]<=Threshold ? "1":"0"
		Threshold:="*" Threshold
	}
	ListLines % lls
	w:=Format("{:d}",w), CutUp:=CutDown:=0
	if (cut=1)
	{
		re1:="(^0{" w "}|^1{" w "})"
		re2:="(0{" w "}$|1{" w "}$)"
		While (s~=re1)
		s:=RegExReplace(s,re1), CutUp++
		While (s~=re2)
		s:=RegExReplace(s,re2), CutDown++
	}
	rx:=x+w//2, ry:=y+CutUp+(h-CutUp-CutDown)//2
	s:="|<>" Threshold "$" w "." this.bit2base64(s)
	SetBatchLines % bch
	return s
	}
	; Take a Screenshot before using it: graphicsearch().ScreenShot()

	WaitChange(time:=-1, x1:=0, y1:=0, x2:=0, y2:=0)
	{
	local
	hash:=this.GetPicHash(x1, y1, x2, y2, 0)
	time:=this.addZero(time), timeout:=A_TickCount+Round(time*1000)
	Loop
	{
		if (hash!=this.GetPicHash(x1, y1, x2, y2, 1))
		return 1
		if (time>=0 && A_TickCount>=timeout)
		Break
		Sleep 10
	}
	return 0
	}

	WaitNotChange(time:=1, timeout:=30, x1:=0, y1:=0, x2:=0, y2:=0)
	{
	local
	oldhash:="", time:=this.addZero(time)
	, timeout:=A_TickCount+Round(this.addZero(timeout)*1000)
	Loop
	{
		hash:=this.GetPicHash(x1, y1, x2, y2, 1), t:=A_TickCount
		if (hash!=oldhash)
		oldhash:=hash, timeout2:=t+Round(time*1000)
		if (t>=timeout2)
		return 1
		if (t>=timeout)
		return 0
		Sleep 100
	}
	}

	GetPicHash(x1:=0, y1:=0, x2:=0, y2:=0, ScreenShot:=1)
	{
	local
	static init:=DllCall("LoadLibrary", "Str","ntdll", "Ptr")
	x1:=this.addZero(x1), y1:=this.addZero(y1), x2:=this.addZero(x2), y2:=this.addZero(y2)
	if (x1=0 && y1=0 && x2=0 && y2=0)
		n:=150000, x:=y:=-n, w:=h:=2*n
	else
		x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
	bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy), x-=zx, y-=zy
	if (w<1 || h<1 || !bits.Scan0)
		return 0
	hash:=0, Stride:=bits.Stride, p:=bits.Scan0+(y-1)*Stride+x*4, w*=4
	ListLines % (lls:=A_ListLines)?0:0
	Loop % h
		hash:=(hash*31+DllCall("ntdll\RtlComputeCrc32", "uint",0
		, "Ptr",p+=Stride, "uint",w, "uint"))&0xFFFFFFFF
	ListLines % lls
	return hash
	}

	WindowToScreen(ByRef x, ByRef y, x1, y1, id:="")
	{
	local
	if (!id)
		WinGet, id, ID, A
	VarSetCapacity(rect, 16, 0)
	, DllCall("GetWindowRect", "Ptr",id, "Ptr",&rect)
	, x:=x1+NumGet(rect,"int"), y:=y1+NumGet(rect,4,"int")
	}

	ScreenToWindow(ByRef x, ByRef y, x1, y1, id:="")
	{
	local
	this.WindowToScreen(dx, dy, 0, 0, id), x:=x1-dx, y:=y1-dy
	}

	ClientToScreen(ByRef x, ByRef y, x1, y1, id:="")
	{
	local
	if (!id)
		WinGet, id, ID, A
	VarSetCapacity(pt, 8, 0), NumPut(0, pt, "int64")
	, DllCall("ClientToScreen", "Ptr",id, "Ptr",&pt)
	, x:=x1+NumGet(pt,"int"), y:=y1+NumGet(pt,4,"int")
	}

	ScreenToClient(ByRef x, ByRef y, x1, y1, id:="")
	{
	local
	this.ClientToScreen(dx, dy, 0, 0, id), x:=x1-dx, y:=y1-dy
	}
	; But like built-in command ImageSearch using CoordMode Settings
	; ImageFile can use "*n *TransBlack-White-RRGGBB... d:\a.bmp"
	ImageSearch(ByRef rx:="", ByRef ry:="", x1:=0, y1:=0, x2:=0, y2:=0
	, ImageFile:="", ScreenShot:=1, FindAll:=0, dir:=1)
	{
	local
	dx:=dy:=0
	if (A_CoordModePixel="Window")
		this.WindowToScreen(dx, dy, 0, 0)
	else if (A_CoordModePixel="Client")
		this.ClientToScreen(dx, dy, 0, 0)
	text:=""
	Loop Parse, ImageFile, |
	if (v:=Trim(A_LoopField))!=""
	{
		text.=InStr(v,"$") ? "|" v : "|##"
		. (RegExMatch(v, "O)(^|\s)\*(\d+)\s", r)
		? Format("{:06X}", r[2]<<16|r[2]<<8|r[2]) : "000000")
		. (RegExMatch(v, "Oi)(^|\s)\*Trans([\-\w]+)\s", r)
		? "-" . Trim(r[2],"-") : "") . "$"
		. Trim(RegExReplace(v, "(^|\s)\*\S+"))
	}
	x1:=this.addZero(x1), y1:=this.addZero(y1), x2:=this.addZero(x2), y2:=this.addZero(y2)
	if (x1=0 && y1=0 && x2=0 && y2=0)
		n:=150000, x1:=y1:=-n, x2:=y2:=n
	if (ok:=this.graphicsearch(,, x1+dx, y1+dy, x2+dx, y2+dy
		, 0, 0, text, ScreenShot, FindAll,,,, dir))
	{
		For k,v in ok
		v.1-=dx, v.2-=dy, v.x-=dx, v.y-=dy
		rx:=ok[1].1, ry:=ok[1].2, ErrorLevel:=0
		return ok
	}
	else
	{
		rx:=ry:="", ErrorLevel:=1
		return 0
	}
	}
	; But like built-in command PixelSearch using CoordMode Settings
	; ColorID can use "RRGGBB-DRDGDB|RRGGBB-DRDGDB", Variation in 0-255

	PixelSearch(ByRef rx:="", ByRef ry:="", x1:=0, y1:=0, x2:=0, y2:=0
	, ColorID:="", Variation:=0, ScreenShot:=1, FindAll:=0, dir:=1)
	{
	local
	n:=this.addZero(Variation), text:=Format("##{:06X}$0/0/", n<<16|n<<8|n)
	. Trim(StrReplace(ColorID, "|", "/"), "/")
	return this.ImageSearch(rx, ry, x1, y1, x2, y2, text, ScreenShot, FindAll, dir)
	}
	; ColorID can use "RRGGBB-DRDGDB|RRGGBB-DRDGDB", Variation in 0-255

	PixelCount(x1:=0, y1:=0, x2:=0, y2:=0, ColorID:="", Variation:=0, ScreenShot:=1)
	{
	local
	x1:=this.addZero(x1), y1:=this.addZero(y1), x2:=this.addZero(x2), y2:=this.addZero(y2)
	if (x1=0 && y1=0 && x2=0 && y2=0)
		n:=150000, x:=y:=-n, w:=h:=2*n
	else
		x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
	bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy), x-=zx, y-=zy
	sum:=0, VarSetCapacity(s1,4), VarSetCapacity(s0,4)
	ini:={ bits:bits, ss:0, s1:&s1, s0:&s0
		, err1:0, err0:0, allpos_max:0, zoomW:1, zoomH:1 }
	n:=this.addZero(Variation), text:=Format("##{:06X}$0/0/", n<<16|n<<8|n)
	. Trim(StrReplace(ColorID, "|", "/"), "/")
	if (w>0 && h>0 && bits.Scan0) && IsObject(j:=this.PicInfo(text))
		sum:=this.PicFind(ini, j, 1, x, y, w, h, 0)
	return sum
	}
	; ColorID can use "RRGGBB1@0.8|RRGGBB2-DRDGDB2"
	; Count is the quantity within the range that must meet the criteria
	ColorBlock(ColorID, w, h, Count)
	{
	local
	Text:="|<>[" (1-Count/(w*h)) ",1]"
	. Trim(StrReplace(ColorID, "|", "/"), "/") . Format("${:d}.",w)
	. this.bit2base64(StrReplace(Format(Format("{{}:0{:d}d{}}",w*h),0),"0","1"))
	return Text
	}

	Click(x:="", y:="", other1:="", other2:="", GoBack:=0)
	{
	local
	CoordMode, Mouse, % (bak:=A_CoordModeMouse)?"Screen":"Screen"
	if GoBack
		MouseGetPos, oldx, oldy
	MouseMove, x, y, 0
	Click % x "," y "," other1 "," other2
	if GoBack
		MouseMove, oldx, oldy, 0
	CoordMode, Mouse, %bak%
	return 1
	}
	; If you want to click on the background window, please provide hwnd
	ControlClick(x, y, WhichButton:="", ClickCount:=1, Opt:="", hwnd:="")
	{
	local
	if !hwnd
		hwnd:=DllCall("WindowFromPoint", "int64",y<<32|x&0xFFFFFFFF, "Ptr")
	VarSetCapacity(pt,8,0), ScreenX:=x, ScreenY:=y
	Loop
	{
		NumPut(0,pt,"int64"), DllCall("ClientToScreen", "Ptr",hwnd, "Ptr",&pt)
		, x:=ScreenX-NumGet(pt,"int"), y:=ScreenY-NumGet(pt,4,"int")
		, id:=DllCall("ChildWindowFromPoint", "Ptr",hwnd, "int64",y<<32|x, "Ptr")
		if (!id || id=hwnd)
		Break
		else hwnd:=id
	}
	DetectHiddenWindows % (bak:=A_DetectHiddenWindows)?1:1
	PostMessage, 0x200, 0, y<<16|x,, ahk_id %hwnd%
	SetControlDelay -1
	ControlClick, x%x% y%y%, ahk_id %hwnd%,, %WhichButton%, %ClickCount%, NA Pos %Opt%
	DetectHiddenWindows % bak
	return 1
	}
}