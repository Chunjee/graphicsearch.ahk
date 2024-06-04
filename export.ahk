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
		DllCall("DeleteObject", "Ptr",this.bits.hBM)
	}
	
	New()
	{
		return new graphicsearch()
	}
	
	find(x1:=0, y1:=0, x2:=0, y2:=0, err1:=0, err0:=0, text:=""
	, ScreenShot:=1, FindAll:=1, JoinText:=0, offsetX:=20, offsetY:=10
	, dir:=1, zoomW:=1, zoomH:=1) {
		local
		if (OutputX ~= "i)^\s*wait[10]?\s*$")
		{
		found:=!InStr(OutputX,"0"), time:=this.addZero(OutputY)
		, timeout:=A_TickCount+Round(time*1000), OutputX:=""
		Loop
		{
			ok:=this.find(x1, y1, x2, y2, err1, err0, text, ScreenShot
			, FindAll, JoinText, offsetX, offsetY, dir, zoomW, zoomH)
			if (found && ok)
			{
			OutputX:=ok[1].x, OutputY:=ok[1].y
			return ok
			}
			if (!found && !ok)
			return 1
			if (time>=0 && A_TickCount>=timeout)
			Break
			Sleep 50
		}
		return 0
		}
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
		return 0
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
		, VarSetCapacity(s1,k*4), VarSetCapacity(s0,k*4), VarSetCapacity(ss,sw*(sh+2))
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
		return 0
	}
	
	; the join text object <==> [ "abc", "xyz", "a1|a2|a3" ]
	
	JoinText(arr, ini, info2, text, index, offsetX, offsetY
		, FindAll, dir, minX, minY, maxY, sx, sy, sw, sh)
	{
		local
		if !(Len:=text.Length())
		return 0
		VarSetCapacity(allpos, ini.allpos_max*4), allpos_ptr:=&allpos
		, zoomW:=ini.zoomW, zoomH:=ini.zoomH, mode:=ini.mode
		For i,j in info2[text[index]]
		if (mode!=2 || text[index]==j[10])
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
		x32:="VVdWU4HslAAAAIO8JKgAAAAFi6wkrAAAAA+ERwMAAIu0JOQAAACF9g+OmAsAAIl8"
		. "JByLvCTgAAAAMcCJrCSsAAAAxwQkAAAAAInFx0QkFAAAAADHRCQMAAAAAMdEJBgA"
		. "AAAAi4Qk3AAAAItMJBgx9jHbAciF@4lEJAh@O+mOAAAAD6+EJMgAAACJwYnwmff@"
		. "AcGLRCQIgDwYMXRMi4Qk2AAAAIPDAQO0JPgAAACJDKiDxQE533RUiwQkmfe8JOQA"
		. "AACDvCSoAAAABHW1D6+EJLwAAACJwYnwmff@jQyBi0QkCIA8GDF1tItEJAyLlCTU"
		. "AAAAg8MBA7Qk+AAAAIkMgoPAATnfiUQkDHWsAXwkGINEJBQBi4wk@AAAAItEJBQB"
		. "DCQ5hCTkAAAAD4U0@@@@i0wkDLuti9toie4Pr4wk6AAAAIlsJDCLfCQci6wkrAAA"
		. "AInIwfkf9+vB+gwpyouMJOwAAACJVCQ8D6@OicjB+R@368H6DCnKiVQkQIO8JKgA"
		. "AAAED4T5BQAAi4QkvAAAAIu0JMAAAAAPr4QkxAAAAIuMJLwAAACNNLCLhCTIAAAA"
		. "99iDvCSoAAAAAY0EgYlEJDQPhNsGAACDvCSoAAAAAg+EBwkAAItEJDyDvCSoAAAA"
		. "A4kEJItEJECJRCQID4T5CQAAi3QkDIsMJDHAOc6LTCQID07wiXQkDIt0JDA5zg9P"
		. "xolEJDCLhCSoAAAAg+gEg@gBD4YpBQAAx0QkGAAAAADHRCQUAAAAAItEJBQDhCTI"
		. "AAAAK4Qk+AAAAIlEJCCLRCQYA4QkzAAAACuEJPwAAACDvCS0AAAACYlEJBwPhBUD"
		. "AACLhCS0AAAAg+gBg@gHD4esAAAAg@gDiUQkOA+OpwAAAItEJBSLdCQYx0QkPAAA"
		. "AACJRCRQiXQkSIlEJBiLdCRQOXQkIItEJEiJRCQUfGCLdCRIOXQkHA+MnQsAAPZE"
		. "JDgCi3QkUInydAyLRCQYA0QkICnwicL2RCQ4AYt0JEiJ8HQKi0QkFANEJBwp8It0"
		. "JDiJ0YP+Aw9PyA9PwolMJCiJRCQk6X8DAACNtgAAAACLRCQ8gcSUAAAAW15fXcJY"
		. "AMdEJDgAAAAAi0QkGIt0JCDHRCQ8AAAAAIlEJFCLRCQciXQkHIlEJCCLRCQUiUQk"
		. "SOlI@@@@McCF7Q+VwIlEJEQPhFQEAACLhCTkAAAAiemLvCTcAAAAD6+EJOAAAADB"
		. "6RCJ6w+2yQ+204nOD6@xi4wk5AAAAI08h4noD7bEiXQkLInGD6@widAPr8KFyYl0"
		. "JASJRCQQD457CgAAi4Qk4AAAAIn+i3wkLInri6wksAAAAMdEJCgAAAAAx0QkMAAA"
		. "AADHRCQMAAAAAMHgAok8JIlEJDgxwIuUJOAAAACF0g+OGAEAAIuMJNwAAACLPCTH"
		. "RCQYAAAAAIlcJCABwQNEJDiJTCQUiUQkNAOEJNwAAACJRCQki0QkFIXtD7ZQAQ+2"
		. "SAIPtgCJFCSJRCQIdEQx0osclonYwegQD7bAKcgPr8A5x3wjD7bHKwQkD6@AOUQk"
		. "BHwUD7bDK0QkCA+vwDlEJBAPjTwGAACDwgE56nXCiVwkIItEJAzB4RDB4AKJRCQc"
		. "i0QkKJn3vCTkAAAAD6+EJLwAAACJw4tEJBiZ97wk4AAAAItUJAyNBIOLnCTUAAAA"
		. "iQSTiwQkg8IBi5wk2AAAAIlUJAzB4AgJwQtMJAiLRCQciQwDg0QkFASLlCT4AAAA"
		. "i0QkFAFUJBg7RCQkD4Ui@@@@i1wkIItEJDSJPCSDRCQwAYu8JPwAAACLTCQwAXwk"
		. "KDmMJOQAAAAPhbj+@@+LTCQMuq2L22iJ9w+vjCToAAAAid3HRCQIAAAAAMdEJDAA"
		. "AAAAicjB+R@36sH6DCnKiRQk6Wv8@@+LdCQUi0wkIMdEJGQAAAAAx0QkYAEAAADH"
		. "RCRMAAAAAMdEJFgAAAAAifDHRCQ8AAAAAAHIKfGLdCQcicIrdCQYjVkBweofg8EJ"
		. "AdDR+IlEJCSLRCQYA0QkHInCweofAdCJwonw0fqDwAmJVCQojVYBid4Pr@I50w9P"
		. "wYm0JIAAAACJxg+v8Im0JIQAAACLtCSAAAAAOXQkZA+N+@z@@4u0JIQAAAA5dCRY"
		. "x0QkXAAAAAAPjeL8@@+LTCRgOUwkXA+N+wMAAItEJCSLdCQUOfAPjE8FAACLdCQg"
		. "OfAPj0MFAACLRCQoi0wkGDnID4wzBQAAi0wkHDnID48nBQAAg0QkZAGJdCQciUwk"
		. "IMdEJDgJAAAAi3QkMItEJAw5xg9NxoO8JKgAAAAFiUQkNItEJCgPhMkJAACDvCSo"
		. "AAAABA+EUQgAAA+vhCTIAAAAi1QkNIt0JCSF0o0cMA+EsAcAAIsEJIuMJNAAAAAx"
		. "0ot0JAiJXCRUiUQkQAHZ6w2DwgE5VCQ0D4SDBwAAO1QkDH0ci5wk1AAAAIsEkwHI"
		. "gDgAdQuDbCRAAQ+I1gcAADlUJDB+y4ucJNgAAACLBJMByIA4AXW6g+4BebXptQcA"
		. "AIuEJMQAAADHhCTEAAAAAAAAAIlEJBiLhCTAAAAAx4QkwAAAAAAAAACJRCQU6bb6"
		. "@@+J6MHoEA+vhCT8AAAAmfe8JOQAAAAPr4QkvAAAAInBD7fFD6+EJPgAAACZ97wk"
		. "4AAAAI0sgYtEJDyJBCSLRCRAiUQkCOkn+v@@i5wksAAAAIXbD4ReBgAAi4wksAAA"
		. "AIu0JNQAAACLnCTcAAAAi7wk2AAAAI0EjjHJiUQkCIsrg8YEg8NYg8cEiejB6BAP"
		. "r4Qk@AAAAJn3vCTkAAAAD6+EJLwAAACJBCQPt8UPr4Qk+AAAAJn3vCTgAAAAixQk"
		. "jQSCiUb8i0OsjQRBg8EWiUf8O3QkCHWni4QksAAAAIuMJOgAAAC6rYvbaA+vyIlE"
		. "JAyJyMH5H@fqidDB+AwpyIu8JNwAAACJBCTHRCQIAAAAAMdEJDAAAAAAg8cI6VD5"
		. "@@+LhCTkAAAA0aQksAAAAA+vhCTgAAAAx0QkKAAAAADHRCQ4AAAAAAOEJNwAAACJ"
		. "x4uEJMgAAADB4AKJRCRUi4QkzAAAAIXAD45FAQAAiXwkJIt8JESJrCSsAAAAi5wk"
		. "yAAAAIXbD47+AAAAi0QkOAOEJNAAAACLnCS4AAAAiceLRCRUAfOJ3QHwif6JRCRE"
		. "A4QkuAAAAIlEJCDrFo12AMYGAIPFBIPGATtsJCAPhKgAAAAPtkUCMf+JBCQPtkUB"
		. "iUQkFA+2RQCJRCQYO7wksAAAAHPLi0QkJIsUuIPHAotMuPwPtt4rXCQUidDB6BAP"
		. "tsArBCSJXCQID7baK1wkGIH6@@@@AIlcJBwPhsAAAACLFCSNHFCNkwAEAAAPr9AP"
		. "r8KLVCQID6@SweILAdC6@gUAACnaidOLVCQcD6@aD6@ajRQYOdFyhMYGAYPFBIPG"
		. "ATtsJCAPhVj@@@+LjCTIAAAAAUwkOIt0JESDRCQoAQN0JDSLRCQoOYQkzAAAAA+F"
		. "2f7@@4l8JESLrCSsAAAAi3wkJItEJDyJBCSLRCRAiUQkCOmr9@@@i3QkTINEJFgB"
		. "ifCD4AEBwYnwg8ABiUwkYIPgA4lEJEzpqPv@@410JgCJysHqEA+22g+21Q+2yYlU"
		. "JASJ2olcJCwPr8CJTCQQD6@TOdAPj9L+@@+LXCQIi0wkBInYicoPr8MPr9E50A+P"
		. "uP7@@4tUJByLTCQQidOJyA+v2g+vwTnDD4+e@v@@6RX@@@+JXCQg6Sj6@@+NRQGL"
		. "jCTMAAAAxwQkAAAAAMdEJAgAAAAAweAHicWLhCTIAAAAweAChcmJRCQYD44j@@@@"
		. "iXwkHIuUJMgAAACF0n5fi4wkuAAAAItcJAiLvCS4AAAAA5wk0AAAAAHxA3QkGIl0"
		. "JBQB9w+2UQIPtkEBD7Yxa8BLa9ImAcKJ8MHgBCnwAdA5xQ+XA4PBBIPDATn5ddWL"
		. "vCTIAAAAAXwkCIt0JBSDBCQBA3QkNIsEJDmEJMwAAAB1got8JBzpmP7@@4tEJCCL"
		. "dCQciUQkHIl0JCCLRCRMhcAPhWACAACDbCQoAYNEJFwB6Xj6@@@HRCRAAAAAAMdE"
		. "JDwAAAAAx0QkMAAAAADHRCQMAAAAAOmQ9f@@i4wkyAAAAIuEJNAAAADHRCQUAAAA"
		. "AMdEJBgAAAAAjQRIiUQkIInIweACiUQkHIuEJMwAAACFwA+OyvX@@4msJKwAAACJ"
		. "PCSJ9YuEJMgAAACFwH5ai4wkuAAAAItcJCCLvCS4AAAAA1wkGAHpA2wkHAHvjXYA"
		. "D7ZRAoPBBIPDAWvyJg+2Uf1rwkuNFAYPtnH8ifDB4AQp8AHQwfgHiEP@Ofl10ou8"
		. "JMgAAAABfCQYg0QkFAEDbCQ0i0QkFDmEJMwAAAB1hYuEJMgAAACLPCQx9sdEJAgA"
		. "AAAAg+gBiXwkKIu8JLAAAACJRCQYi4QkzAAAAIPoAYlEJByLhCTIAAAAhcAPjukA"
		. "AACLRCQIi4wkyAAAAIusJNAAAACFwItEJCAPlEQkFAHxiUwkJInDjRQwAcuJ8SuM"
		. "JMgAAAAB7okcJAHBMcDplgAAAIB8JBQAD4WTAAAAOUQkGA+EiQAAAItsJAg5bCQc"
		. "dH8PtjoPtmr@uwEAAAADvCSsAAAAOe9yRw+2agE573I@D7YpOe9yOIssJA+2bQA5"
		. "73ItD7Zp@znvciUPtmkBOe9yHYscJA+2a@+7AQAAADnvcg2LHCQPtmsBOe8PksOQ"
		. "iBwGg8ABg8IBgwQkAYPBATmEJMgAAAB0DoXAD4Vi@@@@xgQGAuvci3QkJINEJAgB"
		. "i0QkCDmEJMwAAAAPhfL+@@+LRCQ8ibwksAAAAIusJKwAAACLfCQoiQQki0QkQIlE"
		. "JAjp2@P@@4N8JEwBdGmDfCRMAnRYMcCDfCRMAw+UwClEJCTphP3@@zHAx0QkDAAA"
		. "AADpOfr@@8dEJAgAAAAAxwQkAAAAAMdEJAwAAAAAx0QkMAAAAADpqvP@@4tEJBSD"
		. "RCRQAYlEJEjpMfT@@4NEJCgB6TX9@@+DRCQkAekr@f@@i1wkVItEJAyFwHQii5Qk"
		. "1AAAAI00gouEJNAAAACNDBiLAoPCBAHIOdbGAAB18ouEJPAAAACDRCQ8AYt0JDyF"
		. "wHQzi1QkKAOUJMQAAACLRCQkA4QkwAAAAIuMJPAAAADB4hAJ0Du0JPQAAACJRLH8"
		. "D40a9P@@g3wkOAkPhIr8@@+DRCRIAeml8@@@D6+EJLwAAACLdCQki0wkNI0EsIu0"
		. "JLgAAACJRCRUAeiFyQ+2dAYCiXQkaIu0JLgAAAAPtnQGAYl0JGyLtCS4AAAAD7YE"
		. "BolEJHAPhFT@@@+LRCQIiXwkQImsJKwAAACJ9YlEJHiLBCSJRCR0McCJx+t4jXYA"
		. "OXwkMH5ii4Qk2AAAAItUJFSLXCRoAxS4D7ZMFQIPtkQVAStEJGwPtlQVACtUJHCJ"
		. "zgHZKd6NmQAEAAAPr8APr97B4AsPr94Bw7j+BQAAKcgPr8IPr8IB2DmEJLAAAABy"
		. "B4NsJHgBeH2DxwE5fCQ0D4TbAgAAO3wkDH2Fi4Qk1AAAAItUJFSLXCRoAxS4D7ZM"
		. "FQIPtkQVAStEJGwPtlQVACtUJHCJzgHZKd6NmQAEAAAPr8APr97B4AsPr94Bw7j+"
		. "BQAAKcgPr8IPr8IB2DmEJLAAAAAPgyb@@@+DbCR0AQ+JG@@@@4t8JECLrCSsAAAA"
		. "6YH+@@8Pr4QkvAAAAIt0JCSNBLCJRCRAi0QkRIXAD4V@AQAAi3QkNIX2D4QP@v@@"
		. "i4Qk1AAAAIl8JGyJfCR4i3wkLIlEJGiLhCTYAAAAiUQkcGtEJDQWx0QkNAAAAACJ"
		. "hCSIAAAAiwQkiUQkfIt0JGiLRCRAi1wkNAMGi3QkbIlcJCyLDolMJFSLTCRwiwmJ"
		. "jCSwAAAAifGLtCS4AAAAD7Z0BgKJdCR0i7QkuAAAAA+2dAYBibQkjAAAAIu0JLgA"
		. "AAAPtgQGiYQkkAAAAOl5AAAAi3EEixGDRCQsAon3idDB7xDB6BCJ+w+2wCtEJHQP"
		. "tvuJ8w+234lcJASJ8w+284l0JBCJ@g+vwA+v9znwfziLXCQED7bGK4QkjAAAAIne"
		. "D6@AD6@zOfB@Hg+2wot0JBArhCSQAAAAifIPr8APr9Y50A+OKAEAAIPBCItEJCw5"
		. "hCSwAAAAD4d2@@@@gXwkVP@@@wB3C4NsJHwBD4jbAAAAg0QkNBaDRCRoBItEJDSD"
		. "RCRsWINEJHAEOYQkiAAAAA+F1@7@@4l8JCyLfCR46Zz8@@+LXCQ0hdsPhJD8@@+L"
		. "HCQx9olcJFTrE422AAAAAIPGATl0JDQPhIwAAACLhCTUAAAAi0wkQAMMsIuEJNgA"
		. "AACLFLCLhCS4AAAAD7ZsCAKJ0A+23sHoEA+2wCnFi4QkuAAAAA+v7Q+2RAgBKdg5"
		. "bCQsi5wkuAAAAA+2DAt8Gg+vwDlEJAR8EQ+2wQ+2yinID6@AOUQkEH2Gg2wkVAEP"
		. "iXv@@@+J1ek6@P@@iXwkLIt8JHjpLfz@@4nV6d@7@@+LfCRAi6wkrAAAAOnP+@@@"
		. "gXwkVP@@@wAPh+j+@@@p7v7@@5CQkJCQkJCQkJCQkJA="
		x64:="QVdBVkFVQVRVV1ZTSIHsqAAAAIucJGABAACLvCRoAQAAiYwk8AAAAIO8JPAAAAAF"
		. "idFEiYQkAAEAAESJjCQIAQAAD4QbAwAAhf8PjiYLAABFMeREiXwkKESLnCTwAAAA"
		. "RIlkJBBMi7wkUAEAADH2RIukJDABAACLrCSQAQAARTHtRTH2x0QkGAAAAABEiVQk"
		. "IImUJPgAAAAPH4QAAAAAAExjVCQYRTHJRTHATAOUJFgBAACF238163oPH4AAAAAA"
		. "QQ+vxInBRInImff7AcFDgDwCMXQ8SYPAAUljxUEB6UGDxQFEOcNBiQyHfkOJ8Jn3"
		. "@0GD+wR1yQ+vhCQYAQAAicFEiciZ9@tDgDwCMY0MgXXESIuUJEgBAABJg8ABSWPG"
		. "QQHpQYPGAUQ5w4kMgn+9AVwkGINEJBABA7QkmAEAAItEJBA5xw+FVf@@@0SLjCRw"
		. "AQAAQbiti9toRItUJCBEi3wkKIuMJPgAAABFD6@ORInIQcH5H0H36MH6DEQpykSL"
		. "jCR4AQAAiVQkOEUPr81EichBwfkfQffowfoMRCnKiVQkRIO8JPAAAAAED4S9BQAA"
		. "i4QkGAEAAIu0JCABAAAPr4QkKAEAAI0EsIu0JBgBAACJRCQgi4QkMAEAAPfYg7wk"
		. "8AAAAAGNBIaJRCQwD4SNBgAAg7wk8AAAAAIPhLwIAACDvCTwAAAAA0SLZCQ4i1wk"
		. "RA+EegkAADHARTnmRA9O8EE53UQPTuiLhCTwAAAAg+gEg@gBD4YGBQAAMf@HRCQQ"
		. "AAAAAItEJBADhCQwAQAAK4QkkAEAAIlEJBiLhCQ4AQAAAfgrhCSYAQAAg7wkCAEA"
		. "AAmJxg+E7QIAAIuEJAgBAACD6AGD+AcPh6sAAACD+AOJRCQwD46mAAAAi0QkEIl8"
		. "JEjHRCRAAAAAAIlEJGCJx4tUJGA5VCQYi0QkSIlEJBB8Xjt0JEgPjFULAAD2RCQw"
		. "AkSLXCRgRInadAuLRCQYAfhEKdiJwvZEJDABRItcJEhEidh0CYtEJBAB8EQp2ESL"
		. "XCQwQYnRQYP7A0QPT8gPT8JEiUwkKIlEJCDpWQMAAJCLRCRASIHEqAAAAFteX11B"
		. "XEFdQV5BX8PHRCQwAAAAAInwi3QkGIl8JGCJRCQYi0QkEMdEJEAAAAAAiUQkSOlN"
		. "@@@@McCF0g+VwIlEJGQPhDQEAACJ+EGJ0g+20g+vw0HB6hBFD7bSweACSJhIA4Qk"
		. "WAEAAEUPr9JIiUQkCA+2xUGJx0QPr@iJ0A+vwoX@iUQkHA+OWQoAAIu0JAABAACN"
		. "Q@+JvCRoAQAAi3wkHMdEJBgAAAAARTH2SI0EhQYAAADHRCQgAAAAAMdEJCgAAAAA"
		. "jVb@SIt0JAiJnCRgAQAASIlEJDCNBJ0AAAAASI10lgSJRCRAi6wkYAEAAIXtD472"
		. "AAAASGNEJChIi5wkWAEAADHtSI1cAwJIA0QkMEgDhCRYAQAASIlEJBAPH4AAAAAA"
		. "RIukJAABAABED7YDRA+2S@9ED7Zb@kWF5HQ+SItUJAiLConIwegQD7bARCnAD6@A"
		. "QTnCfBsPtsVEKcgPr8BBOcd8DQ+2wUQp2A+vwDnHfVtIg8IESDnWdceLRCQYTWPu"
		. "QcHgEEHB4QhBg8YBRQnImUUJ2Pe8JGgBAAAPr4QkGAEAAEGJxInomfe8JGABAABI"
		. "i5QkSAEAAEGNBIRCiQSqSIuEJFABAABGiQSoSIPDBAOsJJABAABIO1wkEA+FP@@@"
		. "@4tcJEABXCQog0QkIAGLlCSYAQAAi0QkIAFUJBg5hCRoAQAAD4Xa@v@@RIuEJHAB"
		. "AAC6rYvbaDHbRTHtRQ+vxkSJwEHB+B@36sH6DEQpwkGJ1Omw@P@@RItcJBBEi0wk"
		. "GMdEJHQAAAAAx0QkcAEAAADHRCRMAAAAAMdEJGgAAAAARInYx0QkQAAAAABEAciJ"
		. "wsHqHwHQ0fiJRCQgjQQ3icLB6h8B0ESJytH4RCnaiUQkKInwRI1KASn4QYnQjVAB"
		. "RYnLQYPACYPACUQPr9pBOdFBD0@AicIPr9BEiZwkhAAAAImUJJgAAACLlCSEAAAA"
		. "OVQkdA+NFv3@@4uUJJgAAAA5VCRox0QkbAAAAAAPjf38@@9Ei1wkcEQ5XCRsD42j"
		. "AwAAi0QkIItUJBA50A+MmQcAAItUJBg50A+PjQcAAItEJCg5+A+MgQcAADnwD495"
		. "BwAAg0QkdAGJ8MdEJDAJAAAAidaJRCQYRTn1RIn1i0QkKEEPTe2DvCTwAAAABQ+E"
		. "+wkAAIO8JPAAAAAED4QzCAAAD6+EJDABAACLVCQghe1EjQwQD4SHBwAAQYnbRIlk"
		. "JDhFMcDrFmYPH4QAAAAAAEmDwAFEOcUPjmQHAABFOcZEiUQkRH4oSIuEJEgBAABE"
		. "icpCAxSASIuEJEABAACAPBAAdQuDbCQ4AQ+IsQcAAEQ7bCREfrpIi5QkUAEAAESJ"
		. "yEIDBIJIi5QkQAEAAIA8AgF1nUGD6wF5l+mCBwAAZpCLhCQgAQAAi7wkKAEAAMeE"
		. "JCABAAAAAAAAx4QkKAEAAAAAAACJRCQQ6df6@@+JyESLZCQ4wegQD6+EJJgBAACZ"
		. "9@8Pr4QkGAEAAEGJwA+3wQ+vhCSQAQAAmff7i1wkREGNDIDpb@r@@0SLrCQAAQAA"
		. "RTHJMfZFMeRFMfZMi5wkWAEAAEWF7Q+EmAAAAEiLrCRIAQAATIukJFABAABEi6wk"
		. "kAEAAESLtCSYAQAAQYsLSYPDWInIwegQQQ+vxpn3@w+vhCQYAQAAQYnAD7fBQQ+v"
		. "xZn3+0GNBIBCiUSNAEGLQ6yNBEaDxhZDiQSMSYPBAUQ5jCQAAQAAd7NEi7QkAAEA"
		. "AESLhCRwAQAAuq2L22hFD6@GRInAQcH4H@fqwfoMQYnURSnESIuEJFgBAAAx20Ux"
		. "7UiDwAhIiUQkCOmY+f@@ifiLtCQ4AQAA0aQkAAEAAA+vw0iYSAOEJFgBAACF9kiJ"
		. "RCQID44FAgAAi4QkMAEAAESLXCRkRIukJAABAADHRCQoAAAAAMdEJEAAAAAARIl0"
		. "JHiD6AFEiWwkfESJfCQYSI0EhQYAAACJjCT4AAAASIlEJFCLhCQwAQAAweACiUQk"
		. "WIucJDABAACF2w+OZQEAAEhjRCQgSIu8JBABAABIY3QkQEgDtCRAAQAATI1MBwJI"
		. "A0QkUEgB+EiJRCQQ6xhmkMYGAEmDwQRIg8YBTDtMJBAPhAwBAABBD7YpRQ+2cf9F"
		. "MdtFD7Zp@kiLXCQIRTnjc8+LE0GDwwKLSwSJ0A+2@kQPtsLB6BBEKfdFKegPtsAp"
		. "6IH6@@@@AHZnjRRoD6@@RI26AAQAAEQPr@jB5wtBD6@HAce4@gUAACnQicJBD6@Q"
		. "idBBD6@AAfg5wQ+DfAAAAEiDwwjrlotUJEyDRCRoAYnQg+ABQQHDidCDwAFEiVwk"
		. "cIPgA4lEJEzp@Pv@@w8fAEGJyg+21Q+2yUHB6hBBic+JTCQcRQ+20olUJBhEidEP"
		. "r8BBD6@KOch@potUJBgPr@+J0A+vwjnHf5ZEicBEifpBD6@AQQ+v1znQf4TGBgFJ"
		. "g8EESIPGAUw7TCQQD4X0@v@@i3wkWAF8JCCLvCQwAQAAAXwkQINEJCgBi1wkMItE"
		. "JCgBXCQgOYQkOAEAAA+Fbv7@@0SLdCR4RItsJHxEi3wkGIuMJPgAAABEiVwkZESL"
		. "ZCQ4i1wkROlb9@@@RIuMJDgBAACLhCQwAQAAg8EBweEHMfYx@0WFyY0shQAAAAB+"
		. "zUSJdCQQRIukJDABAABEi3QkIEWF5H5jSIucJBABAABJY8ZFMclMjUQDAkhj30gD"
		. "nCRAAQAAZi4PH4QAAAAAAEEPthBBD7ZA@0UPtlj+a8BLa9ImAcJEidjB4AREKdgB"
		. "0DnBQg+XBAtJg8EBSYPABEU5zH@LQQHuRAHng8YBRAN0JDA5tCQ4AQAAdYdEi3Qk"
		. "EOk4@@@@x0QkRAAAAADHRCQ4AAAAAEUx7UUx9ukR9v@@i4QkMAEAAESLhCQ4AQAA"
		. "MfYx@wHASJhIA4QkQAEAAEWFwEiJRCQQi4QkMAEAAI0shQAAAAAPjkv2@@9EiXQk"
		. "GESLpCQwAQAARIt0JCBFheR+W0iLnCQQAQAASWPGRTHJTI1EAwJIY99IA1wkEGaQ"
		. "QQ+2EEmDwAREa9omQQ+2UPtrwktBjRQDRQ+2WPpEidjB4AREKdgB0MH4B0KIBAtJ"
		. "g8EBRTnMf8hBAe5EAeeDxgFEA3QkMDm0JDgBAAB1j0hjhCQwAQAAugEAAABEi3Qk"
		. "GESLhCQAAQAARIucJDABAAAx7cdEJBgAAAAARIlsJEBEiXQkMESJVCRQSI14AUgp"
		. "wouEJDABAABIiVQkKEiJfCQgRI1g@4uEJDgBAACD6AFBicZFhdsPjuEAAABIY1wk"
		. "GEiLfCQghe1Ii0QkEEEPlMVMjRQfSIt8JChIjVQYAUkBwkyNDB9Ii7wkQAEAAEkB"
		. "wTHASAH76Y8AAAAPH0QAAEWE7Q+FiQAAAEE5xA+EgAAAAEE57nR7RA+2Qv8Ptnr+"
		. "vgEAAABBAchBOfhyRA+2OkE5+HI8QQ+2ef9BOfhyMkEPtnr@QTn4cihBD7Z5@kE5"
		. "+HIeQQ+2OUE5+HIVQQ+2ev5BOfhyC0EPtjJBOfBAD5LGQIg0A0iDwAFIg8IBSYPC"
		. "AUmDwQFBOcN+DoXAD4Vu@@@@xgQDAuvdRAFcJBiDxQE5rCQ4AQAAD4UG@@@@RIt0"
		. "JDBEi2wkQESLVCRQRImEJAABAABEi2QkOItcJETpRfT@@4tEJBiJdCQYicaLVCRM"
		. "hdJ1D4NsJCgBg0QkbAHpMPj@@4N8JEwBdECDfCRMAnQyMcCDfCRMAw+UwClEJCDr"
		. "2DHbRTHkRTH2RTHt6Qb0@@+LRCQQg0QkYAGJRCRI6X30@@+DRCQoAeuvg0QkIAHr"
		. "qEWF9nQsSIuUJEgBAABBjUb@TI1EggREicgDAkyLnCRAAQAASIPCBEk50EHGBAMA"
		. "deWDRCRAAUiDvCSAAQAAAESLXCRAdDmLVCQoA5QkKAEAAE1jw4tEJCADhCQgAQAA"
		. "weIQCdBEO5wkiAEAAEiLlCSAAQAAQolEgvwPjWD0@@+DfCQwCQ+EB@@@@4NEJEgB"
		. "6e3z@@8Pr4QkGAEAAItUJCBMi5wkEAEAAI0EkIlEJEQByIXtjVACSGPSQQ+2FBOJ"
		. "VCRQjVABSJhBD7YEA0hj0kEPthQTiUQkeIlUJFgPhE@@@@8xwESJVCQ4iYwk+AAA"
		. "AImcJIAAAABEiWQkfEiJwU2J2umjAAAADx+EAAAAAABEO6wkiAAAAA+OgQAAAEiL"
		. "hCRQAQAAi1QkRESLTCRQAxSIjUICSJhFD7YEAo1CAUhj0kEPthQSSJgrVCR4QQ+2"
		. "BAJFicNFAcgrRCRYRSnLRY2IAAQAAEUPr8sPr8BFD6@LweALQQHBuP4FAABEKcAP"
		. "r8IPr8JEAcg5hCQAAQAAcg6DrCSAAAAAAQ+InwAAAEiDwQE5zQ+ONwMAAEE5zomM"
		. "JIgAAAAPjlX@@@9Ii5QkSAEAAItEJEREi0wkUAMEio1QAkhj0kUPtgQSjVABSJhB"
		. "D7YEAkhj0itEJHhBD7YUEkWJw0UByCtUJFhFKctFjYgABAAARQ+vyw+v0kUPr8vB"
		. "4gtBAdG6@gUAAEQpwg+v0A+vwkQByDmEJAABAAAPg93+@@+DbCR8AQ+J0v7@@0SL"
		. "VCQ4i4wk+AAAAOkx@v@@D6+EJBgBAACLVCQgjQSQiUQkRItEJGSFwA+FqAEAAIXt"
		. "D4S8@f@@SIuEJEgBAABIi5QkSAEAAEyLXCQIRImkJIAAAADHRCR4AAAAAEiJRCQ4"
		. "SIuEJFABAABIiUQkWI1F@0iNRIIESImEJIgAAABIi0QkOItsJERFiwNEi0wkeImM"
		. "JPgAAAADKESJRCRQTItEJFiNRQGNVQJIY+1FiwBImEhj0kiJhCSQAAAASIuEJBAB"
		. "AABEiYQkAAEAAE2J2A+2BBBIi5QkkAAAAIlEJHxIi4QkEAEAAA+2BBCJhCSQAAAA"
		. "SIuEJBABAAAPtgQoiYQknAAAAOt3QYsQQYtoBEGDwQKJ0EGJ6kiJ6cHoEEHB6hAP"
		. "ts0PtsArRCR8RQ+20kGJz0APts1EidVBD6@qiUwkHA+vwDnofzIPtsYrhCSQAAAA"
		. "RIn9QQ+v7w+vwDnofxoPtsIrhCScAAAAicoPr9EPr8A50A+OEAEAAEmDwAhEOYwk"
		. "AAEAAA+He@@@@4F8JFD@@@8Ai4wk+AAAAHcOg6wkgAAAAAEPiJf8@@9Ig0QkOARJ"
		. "g8NYSINEJFgESItEJDiDRCR4Fkg7hCSIAAAAD4Ws@v@@6Rz8@@+F7Q+EFPz@@0WJ"
		. "40UxyYlsJDhIi4QkSAEAAItUJERMi4QkEAEAAEiLrCQQAQAAQgMUiEiLhCRQAQAA"
		. "QosMiI1CAkiYRQ+2BACJyMHoEA+2wEEpwI1CAUhj0kUPr8BImA+2RAUAD7btKehI"
		. "i6wkEAEAAEU5wg+2VBUAfBkPr8BBOcd8EQ+2wg+20SnQD6@AOUQkHH0KQYPrAQ+I"
		. "zPv@@0mDwQFEOUwkOA+PZf@@@+lq+@@@gXwkUP@@@wCLjCT4AAAAD4f+@v@@6Qf@"
		. "@@9Ei1QkOIuMJPgAAADpP@v@@5CQkJCQkJCQkJCQkJA="
		this.MCode(MyFunc, StrReplace((A_PtrSize=8?x64:x32),"@","/"))
		}
		text:=j[1], w:=j[2], h:=j[3]
		, err1:=this.addZero(j[4] ? j[5] : ini.err1)
		, err0:=this.addZero(j[4] ? j[6] : ini.err0)
		, mode:=j[7], color:=j[8], n:=j[9]
		return (!ini.bits.Scan0) ? 0 : DllCall(&MyFunc
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
		; You Can Add Comment Text within The <>
		if RegExMatch(v, "O)<([^>\n]*)>", r)
		v:=StrReplace(v,r[0]), comment:=Trim(r[1])
		; You can Add two fault-tolerant in the [], separated by commas
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
			; <FindPic> : Text parameter require manual input
			; Text:='|<>##DRDGDB-RRGGBB1-RRGGBB2... $ d:\a.bmp'
			; the 0xRRGGBB1(+/-0xDRDGDB)... all as transparent color
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
			; All images used for Search are cached
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
			; <FindMultiColor> or <FindColor> : FindColor is FindMultiColor with only one point
			; Text:='|<>##DRDGDB $ 0/0/RRGGBB1-DRDGDB1/RRGGBB2, xn/yn/-RRGGBB3/RRGGBB4, ...'
			; Color behind '##' (0xDRDGDB) is the default allowed variation for all colors
			; Initial point (0,0) match 0xRRGGBB1(+/-0xDRDGDB1) or 0xRRGGBB2(+/-0xDRDGDB),
			; point (xn,yn) match not 0xRRGGBB3(+/-0xDRDGDB) and not 0xRRGGBB4(+/-0xDRDGDB)
			; Starting with '-' after a point coordinate means excluding all subsequent colors
			; Each point can take up to 10 sets of colors (xn/yn/RRGGBB1/.../RRGGBB10)
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
			r:=StrSplit(v1 "@1", "@"), v1:=Trim(r[1],"-"), x:=this.addZero(r[2])
			, x:=(x<=0||x>1?1:x), x:=Floor(4606*255*255*(1-x)*(1-x))
			, k1:=(!InStr(v1, "-") ? 0x1000000:0)
			, c:=StrSplit(v1 "-" Format("{:X}",x), "-")
			, NumPut(this.ToRGB(c[1])&0xFFFFFF|k1, 0|p+=4, "uint")
			, NumPut(this.addZero("0x" c[2]), 0|p+=4, "uint")
			}
		}
		else if (mode=4)
		{
			r:=StrSplit(arr[1] "@1", "@"), c:=this.addZero(r[1]), n:=this.addZero(r[2])
			, n:=(n<=0||n>1?1:n), n:=Floor(4606*255*255*(1-n)*(1-n))
			, color:=((c-1)//w)<<16|Mod(c-1,w)
		}
		}
		return info[key]:=[v, w, h, seterr, err1, err0, mode, color, n, comment]
	}
	
	ToRGB(color)  ; color can use: RRGGBB, Red, Yellow, Black, White
	{
		local
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
		if !VarSetCapacity(init) && (init:="1")  ; thanks Descolada
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
		if (id:=this.BindWindow(0,0,1))
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
		; Each small range of data obtained from DXGI must be
		; copied to the screenshot cache using find().CopyBits()
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
		return DllCall("CreateDIBSection", "Ptr",0, "Ptr",&bi
		, "int",0, "Ptr*",ppvBits:=0, "Ptr",0, "int",0, "Ptr")
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
		if (MFCopyImage && !Reverse)  ; thanks QQ:RenXing
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
		For k,v in lines  ; [ [x, y, w, h, color] ]
		if IsObject(v)
		{
		if (oldc!=v[5])
		{
			oldc:=v[5], BGR:=(oldc&0xFF)<<16|oldc&0xFF00|(oldc>>16)&0xFF
			DllCall("DeleteObject", "Ptr",brush)
			brush:=DllCall("CreateSolidBrush", "UInt",BGR, "Ptr")
		}
		DllCall("SetRect", "Ptr",&rect, "int",v[1], "int",v[2]
			, "int",v[1]+v[3], "int",v[2]+v[4])
		DllCall("FillRect", "Ptr",mDC, "Ptr",&rect, "Ptr",brush)
		}
		DllCall("DeleteObject", "Ptr",brush)
		DllCall("SelectObject", "Ptr",mDC, "Ptr",oBM)
		DllCall("DeleteObject", "Ptr",mDC)
	}
	
	; Bind the window so that it can find images when obscured
	; by other windows, it's equivalent to always being
	; at the front desk. Unbind Window using find().BindWindow(0)
	
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
	
	; Use find().CaptureCursor(1) to Capture Cursor
	; Use find().CaptureCursor(0) to Cancel Capture Cursor
	
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
	
	MCode(ByRef code, hex)
	{
		local
		flag:=((hex~="[^\s\da-fA-F]")?1:4), hex:=RegExReplace(hex, "[\s=]")
		VarSetCapacity(code, len:=(flag=1 ? StrLen(hex)//4*3+3 : StrLen(hex)//2))
		DllCall("crypt32\CryptStringToBinary", "Str",hex, "uint",0
		, "uint",flag, "Ptr",&code, "uint*",len, "Ptr",0, "Ptr",0)
		DllCall("VirtualProtect", "Ptr",&code, "Ptr",len, "uint",0x40, "Ptr*",0)
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
	
	; You can put the text library at the beginning of the script,
	; and Use find().PicLib(Text,1) to add the text library to PicLib()'s Lib,
	; Use find().PicLib("comment1|comment2|...") to get text images from Lib
	
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
				s2.="_" . Format("{:d}",Ord(A_LoopField))
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
			s2.="_" . Format("{:d}",Ord(A_LoopField))
			if Lib.HasKey(s2)
			Text.="|" . Lib[s2]
		}
		return Text
		}
	}
	
	; Decompose a string into individual characters and get their data
	
	PicN(Number, index:=1)
	{
		return this.PicLib(RegExReplace(Number,".","|$0"), 0, index)
	}
	
	; Use find().PicX(Text) to automatically cut into multiple characters
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
	
	; Screenshot and retained as the last screenshot.
	
	ScreenShot(x1:=0, y1:=0, x2:=0, y2:=0)
	{
		this.find(x1, y1, x2, y2)
	}
	
	; Get the RGB color of a point from the last screenshot.
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
	
	; Set the RGB color of a point in the last screenshot
	
	SetColor(x, y, color:=0x000000)
	{
		local
		bits:=this.GetBitsFromScreen(,,,,0,zx,zy,zw,zh), x-=zx, y-=zy
		if (x>=0 && x<zw && y>=0 && y<zh && bits.Scan0)
		NumPut(color, bits.Scan0+y*bits.Stride+x*4, "uint")
	}
	
	; Identify a line of text or verification code
	; based on the result returned by find().
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
			; Get the leftmost X coordinates
			if (LeftX="" || x<LeftX)
			LeftX:=x, LeftY:=y, LeftW:=v.3, LeftH:=v.4, LeftOCR:=v.id
		}
		if (LeftX="")
			Break
		if (ocr_X="")
			ocr_X:=LeftX, min_Y:=LeftY, max_Y:=LeftY+LeftH
		; If the interval exceeds the set value, add "*" to the result
		ocr_Text.=(ocr_Text!="" && LeftX>dx ? "*":"") . LeftOCR
		; Update for next search
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
	
	; Sort the results of find() from left to right
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
	
	; Sort the results of find() according to the nearest distance
	
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
	
	; Sort the results of find() according to the search direction
	
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
	
	; Prompt mouse position in remote assistance
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
	
	; Quickly save screen image to BMP file for debugging
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
	
	; Save Bitmap To File, if file = 0 or "", save to Clipboard
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
		VarSetCapacity(dib, dib_size:=(A_PtrSize=8 ? 104:84))
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
	
	; Show the saved Picture file
	
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
	
	; Quickly get the search data of screen image
	
	GetTextFromScreen(x1, y1, x2, y2, Threshold:=""
		, ScreenShot:=1, ByRef rx:="", ByRef ry:="", cut:=1)
	{
		local
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
		j:=bits.Stride-w*4, p:=bits.Scan0+(y-zy)*bits.Stride+(x-zx)*4-4-j
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
		;--------------------
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
		;--------------------
		SetBatchLines % bch
		return s
	}
	
	; Wait for the screen image to change within a few seconds
	; Take a Screenshot before using it: find().ScreenShot()
	
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
	
	; Wait for the screen image to stabilize
	
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
	
	; It is not like FindText always use Screen Coordinates,
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
		. Trim(RegExReplace(v, "(?<=^|\s)\*\S+"))
		}
		x1:=this.addZero(x1), y1:=this.addZero(y1), x2:=this.addZero(x2), y2:=this.addZero(y2)
		if (x1=0 && y1=0 && x2=0 && y2=0)
		n:=150000, x1:=y1:=-n, x2:=y2:=n
		if (ok:=this.find(x1+dx, y1+dy, x2+dx, y2+dy
		, 0, 0, text, ScreenShot, FindAll,,,, dir))
		{
		For k,v in ok  ; you can use ok:=find().ok
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
	
	; It is not like FindText always use Screen Coordinates,
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
	
	; Pixel count of certain colors within the range indicated by Screen Coordinates
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
	
	; Create color blocks containing a specified number of specified colors
	; ColorID can use "RRGGBB1@0.8|RRGGBB2-DRDGDB2"
	; Count is the quantity within the range that must meet the criteria
	ColorBlock(ColorID, w, h, Count)
	{
		local
		Text:="|<>[" (1-Count/(w*h)) ",1]"
		. Trim(StrReplace(ColorID, "|", "/"), "/") . "$" w "."
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
	}
	
	; Using ControlClick instead of Click, Use Screen Coordinates,
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
		PostMessage, 0x200, 0, y<<16|x,, ahk_id %hwnd%  ; WM_MOUSEMOVE
		SetControlDelay -1
		ControlClick, x%x% y%y%, ahk_id %hwnd%,, %WhichButton%, %ClickCount%, NA Pos %Opt%
		DetectHiddenWindows % bak
	}
}