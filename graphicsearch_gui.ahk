#Requires autohotkey v1.1
#SingleInstance, force
if (!A_IsCompiled && A_LineFile=A_ScriptFullPath)
	graphicsearch().Gui("Show")

graphicsearch(ByRef x:="graphicsearch", ByRef y:="", args*)
{
	static init, obj
	if !VarSetCapacity(init) && (init:="1")
		obj:=new graphicsearch()
	return (x=="graphicsearch" && !args.Length()) ? obj : obj.graphicsearch(x, y, args*)
}

Class graphicsearch {

	Floor(i)
	{
		if i is number
			return i+0
		else return 0
	}

__New() {
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

graphicsearch(ByRef OutputX:="", ByRef OutputY:=""
	, x1:=0, y1:=0, x2:=0, y2:=0, err1:=0, err0:=0, text:=""
	, ScreenShot:=1, FindAll:=1, JoinText:=0, offsetX:=20, offsetY:=10
	, dir:=1, zoomW:=1, zoomH:=1)
{
	local
	if (OutputX ~= "i)^\s*wait[10]?\s*$")
	{
		found:=!InStr(OutputX,"0"), time:=this.Floor(OutputY)
			, timeout:=A_TickCount+Round(time*1000), OutputX:=""
		Loop
		{
			ok:=this.graphicsearch(,, x1, y1, x2, y2, err1, err0, text, ScreenShot
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
	x1:=this.Floor(x1), y1:=this.Floor(y1), x2:=this.Floor(x2), y2:=this.Floor(y2)
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
	return 0
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
		, err1:=this.Floor(j[4] ? j[5] : ini.err1)
		, err0:=this.Floor(j[4] ? j[6] : ini.err0)
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

code()
{
	return "
	(

	//***** C source code of machine code *****

	int __attribute__((__stdcall__)) PicFind(
	int mode, unsigned int c, unsigned int n, int dir
	, unsigned char * Bmp, int Stride
	, int sx, int sy, int sw, int sh
	, unsigned char * ss, unsigned int * s1, unsigned int * s0
	, unsigned char * text, int w, int h, int err1, int err0
	, unsigned int * allpos, int allpos_max
	, int new_w, int new_h )
	{
	int ok, o, i, j, k, v, e1, e0, len1, len0, max;
	int x, y, x1, y1, x2, y2, x3, y3;
	int r, g, b, rr, gg, bb, dR, dG, dB;
	int ii, jj, RunDir, DirCount, RunCount, AllCount1, AllCount2;
	unsigned int c1, c2;
	unsigned char * ts, * gs;
	unsigned int * cors;
	ok=0; o=0; len1=0; len0=0; ts=ss+sw; gs=ss+sw*3;
	if (mode<1 || mode>5) goto Return1;
	//----------------------
	if (mode==5)
	{
		if (k=(c!=0))  // FindPic
		{
		cors=(unsigned int *)(text+w*h*4);
		r=(c>>16)&0xFF; g=(c>>8)&0xFF; b=c&0xFF; dR=r*r; dG=g*g; dB=b*b;
		for (y=0; y<h; y++)
		{
			for (x=0; x<w; x++, o+=4)
			{
			rr=text[2+o]; gg=text[1+o]; bb=text[o];
			for (i=0; i<n; i++)
			{
				c=cors[i];
				r=((c>>16)&0xFF)-rr; g=((c>>8)&0xFF)-gg; b=(c&0xFF)-bb;
				if (r*r<=dR && g*g<=dG && b*b<=dB) goto NoMatch1;
			}
			s1[len1]=(y*new_h/h)*Stride+(x*new_w/w)*4;
			s0[len1++]=(rr<<16)|(gg<<8)|bb;
			NoMatch1:;
			}
		}
		}
		else  // FindMultiColor or FindColor
		{
		cors=(unsigned int *)text;
		for (; len1<n; len1++, o+=22)
		{
			c=cors[o]; y=c>>16; x=c&0xFFFF;
			s1[len1]=(y*new_h/h)*Stride+(x*new_w/w)*4;
			s0[len1]=o+cors[o+1]*2;
		}
		cors+=2;
		}
		goto StartLookUp;
	}
	//----------------------
	// Generate Lookup Table
	for (y=0; y<h; y++)
	{
		for (x=0; x<w; x++)
		{
		if (mode==4)
			i=(y*new_h/h)*Stride+(x*new_w/w)*4;
		else
			i=(y*new_h/h)*sw+(x*new_w/w);
		if (text[o++]=='1')
			s1[len1++]=i;
		else
			s0[len0++]=i;
		}
	}
	//----------------------
	// Color Position Mode
	// only used to recognize multicolored Verification Code
	if (mode==4)
	{
		y=c>>16; x=c&0xFFFF;
		c=(y*new_h/h)*Stride+(x*new_w/w)*4;
		goto StartLookUp;
	}
	//----------------------
	// Generate Two Value Image
	o=sy*Stride+sx*4; j=Stride-sw*4; i=0;
	if (mode==1)  // Color Mode
	{
		cors=(unsigned int *)(text+w*h); n=n*2;
		for (y=0; y<sh; y++, o+=j)
		{
		for (x=0; x<sw; x++, o+=4, i++)
		{
			rr=Bmp[2+o]; gg=Bmp[1+o]; bb=Bmp[o];
			for (k=0; k<n;)
			{
			c1=cors[k++]; c2=cors[k++];
			r=((c1>>16)&0xFF)-rr; g=((c1>>8)&0xFF)-gg; b=(c1&0xFF)-bb;
			if (c1>0xFFFFFF)
			{
				v=r+rr+rr;
				if ((1024+v)*r*r+2048*g*g+(1534-v)*b*b<=c2) goto MatchOK1;
			}
			else
			{
				dR=(c2>>16)&0xFF; dG=(c2>>8)&0xFF; dB=c2&0xFF;
				if (r*r<=dR*dR && g*g<=dG*dG && b*b<=dB*dB) goto MatchOK1;
			}
			}
			ts[i]=0;
			continue;
			MatchOK1:
			ts[i]=1;
		}
		}
	}
	else if (mode==2)  // Gray Threshold Mode
	{
		c=(c+1)<<7;
		for (y=0; y<sh; y++, o+=j)
		for (x=0; x<sw; x++, o+=4, i++)
			ts[i]=(Bmp[2+o]*38+Bmp[1+o]*75+Bmp[o]*15<c) ? 1:0;
	}
	else if (mode==3)  // Gray Difference Mode
	{
		for (y=0; y<sh; y++, o+=j)
		{
		for (x=0; x<sw; x++, o+=4, i++)
			gs[i]=(Bmp[2+o]*38+Bmp[1+o]*75+Bmp[o]*15)>>7;
		}
		for (i=0, y=0; y<sh; y++)
		{
		for (x=0; x<sw; x++, i++)
		{
			if (x==0 || x==sw-1 || y==0 || y==sh-1)
			ts[i]=2;
			else
			{
			n=gs[i]+c;
			ts[i]=(gs[i-1]>n || gs[i+1]>n
			|| gs[i-sw]>n   || gs[i+sw]>n
			|| gs[i-sw-1]>n || gs[i-sw+1]>n
			|| gs[i+sw-1]>n || gs[i+sw+1]>n) ? 1:0;
			}
		}
		}
	}
	for (i=0, y=0; y<sh; y++)
	{
		for (x=0; x<sw; x++, i++)
		{
		r=ts[i];
		g=(x==0) ? 3 : ts[i-1];
		b=(x==sw-1) ? 3 : ts[i+1];
		ss[i]=(r==2||r==1||g==1||b==1)<<1|(r==2||r==0||g==0||b==0);
		}
	}
	//----------------------
	StartLookUp:
	err1=len1*err1/10000;
	err0=len0*err0/10000;
	if (err1>=len1) len1=0;
	if (err0>=len0) len0=0;
	max=(len1>len0) ? len1 : len0;
	if (mode==5 || mode==4)
	{
		x1=sx; y1=sy; sx=0; sy=0;
	}
	else
	{
		x1=0; y1=0; sx++;
	}
	x2=x1+sw-new_w; y2=y1+sh-new_h;
	// 1 ==> ( Left to Right ) Top to Bottom
	// 2 ==> ( Right to Left ) Top to Bottom
	// 3 ==> ( Left to Right ) Bottom to Top
	// 4 ==> ( Right to Left ) Bottom to Top
	// 5 ==> ( Top to Bottom ) Left to Right
	// 6 ==> ( Bottom to Top ) Left to Right
	// 7 ==> ( Top to Bottom ) Right to Left
	// 8 ==> ( Bottom to Top ) Right to Left
	// 9 ==> Center to Four Sides
	if (dir==9)
	{
		x=(x1+x2)/2; y=(y1+y2)/2; i=x2-x1+1; j=y2-y1+1;
		AllCount1=i*j; i=(i>j) ? i+8 : j+8;
		AllCount2=i*i; RunCount=0; DirCount=1; RunDir=0;
		for (ii=0; RunCount<AllCount1 && ii<AllCount2; ii++)
		{
		for(jj=0; jj<DirCount; jj++)
		{
			if(x>=x1 && x<=x2 && y>=y1 && y<=y2)
			{
			RunCount++;
			goto FindPos;
			FindPos_GoBak:;
			}
			if (RunDir==0) y--;
			else if (RunDir==1) x++;
			else if (RunDir==2) y++;
			else if (RunDir==3) x--;
		}
		if (RunDir & 1) DirCount++;
		RunDir = (++RunDir) & 3;
		}
		goto Return1;
	}
	if (dir<1 || dir>8) dir=1;
	if (--dir>3) { r=y1; y1=x1; x1=r; r=y2; y2=x2; x2=r; }
	for (y3=y1; y3<=y2; y3++)
	{
		for (x3=x1; x3<=x2; x3++)
		{
		y=(dir & 2) ? y1+y2-y3 : y3;
		x=(dir & 1) ? x1+x2-x3 : x3;
		if (dir>3) { r=y; y=x; x=r; }
		//----------------------
		FindPos:
		e1=err1; e0=err0;
		if (mode<4)
		{
			o=y*sw+x;
			for (i=0; i<max; i++)
			{
			if (i<len1 && ss[o+s1[i]]<2 && (--e1)<0) goto NoMatch;
			if (i<len0 && (ss[o+s0[i]]&1)==0 && (--e0)<0) goto NoMatch;
			}
			// Clear the image that has been found
			for (i=0; i<new_h; i++)
			for (j=0; j<new_w; j++)
				ss[o+i*sw+j]=0;
		}
		else if (mode==5)
		{
			o=y*Stride+x*4;
			if (k)
			{
			for (i=0; i<max; i++)
			{
				j=o+s1[i]; c=s0[i]; r=Bmp[2+j]-((c>>16)&0xFF);
				g=Bmp[1+j]-((c>>8)&0xFF); b=Bmp[j]-(c&0xFF);
				if ((r*r>dR || g*g>dG || b*b>dB) && (--e1)<0) goto NoMatch;
			}
			}
			else
			{
			for (i=0; i<max; i++)
			{
				j=o+s1[i]; rr=Bmp[2+j]; gg=Bmp[1+j]; bb=Bmp[j];
				for (j=i*22, v=cors[j]>0xFFFFFF, n=s0[i]; j<n;)
				{
				c1=cors[j++]; c2=cors[j++];
				r=((c1>>16)&0xFF)-rr; g=((c1>>8)&0xFF)-gg; b=(c1&0xFF)-bb;
				dR=(c2>>16)&0xFF; dG=(c2>>8)&0xFF; dB=c2&0xFF;
				if (r*r<=dR*dR && g*g<=dG*dG && b*b<=dB*dB)
				{
					if (v) goto NoMatch2;
					goto MatchOK;
				}
				}
				if (v) continue;
				NoMatch2:
				if ((--e1)<0) goto NoMatch;
				MatchOK:;
			}
			}
		}
		else  // mode==4
		{
			o=y*Stride+x*4;
			j=o+c; rr=Bmp[2+j]; gg=Bmp[1+j]; bb=Bmp[j];
			for (i=0; i<max; i++)
			{
			if (i<len1)
			{
				j=o+s1[i]; r=Bmp[2+j]-rr; g=Bmp[1+j]-gg; b=Bmp[j]-bb; v=r+rr+rr;
				if ((1024+v)*r*r+2048*g*g+(1534-v)*b*b>n && (--e1)<0) goto NoMatch;
			}
			if (i<len0)
			{
				j=o+s0[i]; r=Bmp[2+j]-rr; g=Bmp[1+j]-gg; b=Bmp[j]-bb; v=r+rr+rr;
				if ((1024+v)*r*r+2048*g*g+(1534-v)*b*b<=n && (--e0)<0) goto NoMatch;
			}
			}
		}
		ok++;
		if (allpos!=0)
		{
			allpos[ok-1]=(sy+y)<<16|(sx+x);
			if (ok>=allpos_max) goto Return1;
		}
		NoMatch:
		if (dir==9) goto FindPos_GoBak;
		}
	}
	//----------------------
	Return1:
	return ok;
	}

	)"
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
		color:=this.Floor("0x" StrSplit(color "-", "-")[1])|0x1000000
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
			, x:=this.Floor(r[1]), y:=this.Floor(r[2])
			, (A_Index=1) ? (x1:=x2:=x, y1:=y2:=y)
			: (x1:=Min(x1,x), x2:=Max(x2,x), y1:=Min(y1,y), y2:=Max(y2,y))
		}
		For k1,v1 in arr
		{
			r:=StrSplit(v1 "/", "/")
			, x:=this.Floor(r[1])-x1, y:=this.Floor(r[2])-y1
			, n1:=Min(Max(r.Length()-3, 0), 10)
			, NumPut(y<<16|x, 0|p:=v+(A_Index-1)*22*4, "uint")
			, NumPut(n1, 0|p+=4, "uint")
			Loop % n1
			k1:=(InStr(v1:=r[2+A_Index], "-")=1 ? 0x1000000:0)
			, c:=StrSplit(Trim(v1,"-") "-" color, "-")
			, NumPut(this.ToRGB(c[1])&0xFFFFFF|k1, 0|p+=4, "uint")
			, NumPut(this.Floor("0x" c[2]), 0|p+=4, "uint")
		}
		color:=0, w:=x2-x1+1, h:=y2-y1+1
		}
	}
	else
	{
		r:=StrSplit(v ".", "."), w:=this.Floor(r[1])
		, v:=this.base64tobit(r[2]), h:=StrLen(v)//w
		if (w<1 || h<1 || StrLen(v)!=w*h)
		return
		arr:=StrSplit(Trim(color, "/"), "/")
		if !(n:=arr.Length())
		return
		bmp.Push(buf:=this.Buffer(StrPut(v, "CP0") + n*2*4))
		, StrPut(v, buf.Ptr, "CP0"), v:=buf.Ptr, p:=v+w*h-4
		, color:=this.Floor(arr[1])
		if (mode=1)
		{
		For k1,v1 in arr
		{
			k1:=(InStr(v1, "@") ? 0x1000000:0)
			, r:=StrSplit(v1 "@1", "@"), x:=this.Floor(r[2])
			, x:=(x<=0||x>1?1:x), x:=Floor(4606*255*255*(1-x)*(1-x))
			, c:=StrSplit(Trim(r[1],"-") "-" Format("{:X}",x), "-")
			, NumPut(this.ToRGB(c[1])&0xFFFFFF|k1, 0|p+=4, "uint")
			, NumPut(this.Floor("0x" c[2]), 0|p+=4, "uint")
		}
		}
		else if (mode=4)
		{
		r:=StrSplit(arr[1] "@1", "@"), n:=this.Floor(r[2])
		, n:=(n<=0||n>1?1:n), n:=Floor(4606*255*255*(1-n)*(1-n))
		, c:=this.Floor(r[1]), color:=((c-1)//w)<<16|Mod(c-1,w)
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
	return this.Floor("0x" (tab.HasKey(color)?tab[color]:color))
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
		bind.id:=bind_id:=this.Floor(bind_id)
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

	RangeTip(x:="", y:="", w:="", h:="", color:="Red", d:=3)
	{
	local
	ListLines % (lls:=A_ListLines)?0:0
	static init, Range
	if !VarSetCapacity(init) && (init:="1")
		Range:=[0,0,0,0]
	if (x="")
	{
		Loop 4
		if (Range[i:=A_Index])
			Range[i].Destroy(), Range[i]:=""
		ListLines % lls
		return
	}
	if (!Range[1])
	{
		Loop 4
		Range[A_Index]:=Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000")
	}
	x:=this.Floor(x), y:=this.Floor(y), w:=this.Floor(w), h:=this.Floor(h)
	, d:=this.Floor(d)
	Loop 4
	{
		i:=A_Index
		, x1:=(i=2 ? x+w : x-d)
		, y1:=(i=3 ? y+h : y-d)
		, w1:=(i=1 || i=3 ? w+2*d : d)
		, h1:=(i=2 || i=4 ? h+2*d : d)
		Range[i].BackColor:=color
		Range[i].Show("NA x" x1 " y" y1 " w" w1 " h" h1)
	}
	ListLines % lls
	}

	State(key)
	{
	return GetKeyState(key,"P") || GetKeyState(key)
	}

	GetRange(ww:=25, hh:=8, key:="RButton")
	{
	local
	static init, KeyOff, hk
	if !VarSetCapacity(init) && (init:="1")
		KeyOff:=this.GetRange.Bind(this, "Off")
	if (ww=="Off")
		return hk:=Trim(A_ThisHotkey, "*")
	GetRange_HotkeyIf:=_Gui:=Gui()
	_Gui.Opt("-Caption +ToolWindow +E0x80000")
	_Gui.Title:="GetRange_HotkeyIf"
	_Gui.Show("NA x0 y0 w0 h0")
	if GetKeyState("Ctrl")
		Send {Ctrl Up}
	Hotkey, IfWinExist, GetRange_HotkeyIf
	keys:=key "|Up|Down|Left|Right"
	For k,v in StrSplit(keys, "|")
	{
		if GetKeyState(v)
		Send {%v% Up}
		Hotkey, *%v%, %KeyOff%, On UseErrorLevel
	}
	Hotkey, IfWinExist
	Critical % (cri:=A_IsCritical)?"Off":"Off"
	CoordMode, Mouse
	tip:=this.Lang("s5")
	hk:="", oldx:=oldy:="", keydown:=0
	Loop
	{
		Sleep 50
		MouseGetPos, x2, y2
		if (hk=key) || this.State(key) || this.State("Ctrl")
		{
		keydown++
		if (keydown=1)
			MouseGetPos, x1, y1, Bind_ID
		timeout:=A_TickCount+3000
		While (A_TickCount<timeout) && (this.State(key) || this.State("Ctrl"))
			Sleep 50
		hk:=""
		if (keydown>=2)
			Break
		}
		else if (hk="Up") || this.State("Up")
		(hh>1 && hh--), hk:=""
		else if (hk="Down") || this.State("Down")
		hh++, hk:=""
		else if (hk="Left") || this.State("Left")
		(ww>1 && ww--), hk:=""
		else if (hk="Right") || this.State("Right")
		ww++, hk:=""
		x:=(keydown?x1:x2), y:=(keydown?y1:y2)
		this.RangeTip(x-ww, y-hh, 2*ww+1, 2*hh+1, (A_MSec<500?"Red":"Blue"))
		if (oldx=x2 && oldy=y2)
		Continue
		oldx:=x2, oldy:=y2
		ToolTip % "x: " x " y: " y "`n" tip
	}
	ToolTip
	this.RangeTip()
	Hotkey, IfWinExist, GetRange_HotkeyIf
	For k,v in StrSplit(keys, "|")
		Hotkey, *%v%, %KeyOff%, Off UseErrorLevel
	Hotkey, IfWinExist
	GetRange_HotkeyIf.Destroy()
	Critical % cri
	return [x-ww, y-hh, x+ww, y+hh, Bind_ID]
	}

	GetRange2(key:="LButton")
	{
	local
	graphicsearch_GetRange:=_Gui:=Gui()
	_Gui.Opt("+LastFound +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000")
	_Gui.BackColor:="White"
	WinSet, Transparent, 10
	this.BitmapFromScreen(,,,,0,x,y,w,h)
	_Gui.Title:="graphicsearch_GetRange"
	_Gui.Show("NA x" x " y" y " w" w " h" h)
	CoordMode, Mouse
	tip:=this.Lang("s7"), oldx:=oldy:=""
	Loop
	{
		Sleep 50
		MouseGetPos, x1, y1
		if (oldx=x1 && oldy=y1)
		Continue
		oldx:=x1, oldy:=y1
		ToolTip % "x: " x1 " y: " y1 " w: 0 h: 0`n" tip
	}
	Until this.State(key) || this.State("Ctrl")
	Loop
	{
		Sleep 50
		MouseGetPos, x2, y2
		x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
		this.RangeTip(x, y, w, h, (A_MSec<500 ? "Red":"Blue"))
		if (oldx=x2 && oldy=y2)
		Continue
		oldx:=x2, oldy:=y2
		ToolTip % "x: " x " y: " y " w: " w " h: " h "`n" tip
	}
	Until !(this.State(key) || this.State("Ctrl"))
	ToolTip
	this.RangeTip()
	graphicsearch_GetRange.Destroy()
	Clipboard:=x ", " y ", " (x+w-1) ", " (y+h-1)
	return [x, y, x+w-1, y+h-1]
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
	x1:=this.Floor(x1), y1:=this.Floor(y1), x2:=this.Floor(x2), y2:=this.Floor(y2)
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

	ShowScreenShot(x1:=0, y1:=0, x2:=0, y2:=0, ScreenShot:=1)
	{
	local
	static init, hPic, oldx, oldy, oldw, oldh, graphicsearch_Screen
	if !VarSetCapacity(init) && (init:="1")
		graphicsearch_Screen:=""
	x1:=this.Floor(x1), y1:=this.Floor(y1), x2:=this.Floor(x2), y2:=this.Floor(y2)
	if (x1=0 && y1=0 && x2=0 && y2=0)
	{
		if (graphicsearch_Screen)
		graphicsearch_Screen.Destroy(), graphicsearch_Screen:=""
		return
	}
	x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
	if !hBM:=this.BitmapFromScreen(x,y,w,h,ScreenShot)
		return
	if (!graphicsearch_Screen)
	{
		graphicsearch_Screen:=_Gui:=Gui()
		_Gui.Opt("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000")
		_Gui.MarginX:=0, _Gui.MarginY:=0
		id:=_Gui.Add("Pic", "w" w " h" h), hPic:=id.Hwnd
		_Gui.Title:="Show Pic"
		_Gui.Show("NA x" x " y" y " w" w " h" h)
		oldx:=x, oldy:=y, oldw:=w, oldh:=h
	}
	else if (oldx!=x || oldy!=y || oldw!=w || oldh!=h)
	{
		if (oldw!=w || oldh!=h)
		graphicsearch_Screen[hPic].Move(,, w, h)
		graphicsearch_Screen.Show("NA x" x " y" y " w" w " h" h)
		oldx:=x, oldy:=y, oldw:=w, oldh:=h
	}
	this.BitmapToWindow(hPic, 0, 0, hBM, 0, 0, w, h)
	DllCall("DeleteObject", "Ptr",hBM)
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
	x1:=this.Floor(x1), y1:=this.Floor(y1), x2:=this.Floor(x2), y2:=this.Floor(y2)
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
	time:=this.Floor(time), timeout:=A_TickCount+Round(time*1000)
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
	oldhash:="", time:=this.Floor(time)
	, timeout:=A_TickCount+Round(this.Floor(timeout)*1000)
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
	x1:=this.Floor(x1), y1:=this.Floor(y1), x2:=this.Floor(x2), y2:=this.Floor(y2)
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
	x1:=this.Floor(x1), y1:=this.Floor(y1), x2:=this.Floor(x2), y2:=this.Floor(y2)
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
	n:=this.Floor(Variation), text:=Format("##{:06X}$0/0/", n<<16|n<<8|n)
	. Trim(StrReplace(ColorID, "|", "/"), "/")
	return this.ImageSearch(rx, ry, x1, y1, x2, y2, text, ScreenShot, FindAll, dir)
	}
	; ColorID can use "RRGGBB-DRDGDB|RRGGBB-DRDGDB", Variation in 0-255

	PixelCount(x1:=0, y1:=0, x2:=0, y2:=0, ColorID:="", Variation:=0, ScreenShot:=1)
	{
	local
	x1:=this.Floor(x1), y1:=this.Floor(y1), x2:=this.Floor(x2), y2:=this.Floor(y2)
	if (x1=0 && y1=0 && x2=0 && y2=0)
		n:=150000, x:=y:=-n, w:=h:=2*n
	else
		x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
	bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy), x-=zx, y-=zy
	sum:=0, VarSetCapacity(s1,4), VarSetCapacity(s0,4)
	ini:={ bits:bits, ss:0, s1:&s1, s0:&s0
		, err1:0, err0:0, allpos_max:0, zoomW:1, zoomH:1 }
	n:=this.Floor(Variation), text:=Format("##{:06X}$0/0/", n<<16|n<<8|n)
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

	Class Thread
	{
	__New(args*)
	{
		this.pid:=this.Exec(args*)
	}
	__Delete()
	{
		Process, Close, % this.pid
	}
	Exec(s, Ahk:="", args:="")
	{
		local
		Ahk:=Ahk ? Ahk : A_IsCompiled ? A_ScriptFullPath : A_AhkPath
		s:="`nDllCall(""SetWindowText"",""Ptr"",A_ScriptHwnd,""Str"",""<AHK>"")`n"
		. "`nSetBatchLines,-1`n" . s, s:=RegExReplace(s, "\R", "`r`n")
		Try
		{
		shell:=ComObjCreate("WScript.Shell")
		oExec:=shell.Exec("""" Ahk """ /script /force /CP0 * " args)
		oExec.StdIn.Write(s)
		oExec.StdIn.Close(), pid:=oExec.ProcessID
		}
		Catch
		{
		f:=A_Temp "\~ahk.tmp"
		s:="`r`nTry FileDelete " f "`r`n" s
		Try FileDelete %f%
		FileAppend %s%, %f%
		r:=this.Clear.Bind(this)
		SetTimer %r%, -3000
		Run "%Ahk%" /script /force /CP0 "%f%" %args%,, UseErrorLevel, pid
		}
		return pid
	}
	Clear()
	{
		Try FileDelete % A_Temp "\~ahk.tmp"
		SetTimer,, Off
	}
	}

	QPC()
	{
	static init, f, c
	if !VarSetCapacity(init) && (init:="1")
		f:=0, c:=DllCall("QueryPerformanceFrequency", "Int64*",f)+(f/=1000)
	return (!DllCall("QueryPerformanceCounter","Int64*",c))*0+(c/f)
	}

	ToolTip(s:="", x:="", y:="", num:=1, arg:="")
	{
	local
	static init, ini, tip, timer
	if !VarSetCapacity(init) && (init:="1")
		ini:=[], tip:=[], timer:=[]
	f:="ToolTip_" . this.Floor(num)
	if (s="")
	{
		Try tip[f].Destroy()
		ini[f]:="", tip[f]:=""
		return
	}
	r1:=A_CoordModeToolTip
	r2:=A_CoordModeMouse
	CoordMode Mouse, Screen
	MouseGetPos x1, y1
	CoordMode Mouse, %r1%
	MouseGetPos x2, y2
	CoordMode Mouse, %r2%
	(x!="" && x:="x" (this.Floor(x)+x1-x2))
	, (y!="" && y:="y" (this.Floor(y)+y1-y2))
	, (x="" && y="" && x:="x" (x1+16) " y" (y1+16))
	bgcolor:=arg.bgcolor!="" ? arg.bgcolor : "FAFBFC"
	color:=arg.color!="" ? arg.color : "Black"
	font:=arg.font ? arg.font : "Consolas"
	size:=arg.size ? arg.size : "10"
	bold:=arg.bold ? arg.bold : ""
	trans:=arg.trans!="" ? arg.trans & 255 : 255
	timeout:=arg.timeout!="" ? arg.timeout : ""
	r:=bgcolor "|" color "|" font "|" size "|" bold "|" trans "|" s
	if (!ini.HasKey(f) || ini[f]!=r)
	{
		ini[f]:=r
		Try tip[f].Destroy()
		tip[f]:=_Gui:=Gui()
		_Gui.Opt("+LastFound +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x80020")
		_Gui.MarginX:=2, _Gui.MarginY:=2
		_Gui.BackColor:=bgcolor
		_Gui.SetFont("c" color " s" size " " bold, font)
		_Gui.Add("Text",, s)
		_Gui.Title:=f
		_Gui.Show("Hide")
		WinSet, Transparent, % trans
	}
	tip[f].Opt("+AlwaysOnTop")
	tip[f].Show("NA " x " " y)
	if (timeout)
	{
		(!timer.HasKey(f) && timer[f]:=this.ToolTip.Bind(this,"","","",num))
		, r:=timer[f]
		SetTimer, %r%, % -Round(Abs(this.Floor(timeout)*1000))-1
	}
	}

	ObjView(obj, keyname:="")
	{
	local
	if IsObject(obj)
	{
		s:=""
		For k,v in obj
		s.=this.ObjView(v, keyname "[" (StrLen(k)>1000
		|| [k].GetCapacity(1) ? """" k """":k) "]")
	}
	else
		s:=keyname ": " (StrLen(obj)>1000
		|| [obj].GetCapacity(1) ? """" obj """":obj) "`n"
	if (keyname!="")
		return s
	_Gui:=Gui("+AlwaysOnTop")
	_Gui.Add("Button", "y270 w350 gCancel Default", "OK")
	_Gui.Add("Edit", "xp y10 w350 h250 -Wrap -WantReturn")
	_Gui["Edit1"].Value:=s
	_Gui.Title:="Debug view object values"
	_Gui.Show()
	DetectHiddenWindows 0
	WinWaitClose % "ahk_id " _Gui.Hwnd
	_Gui.Destroy()
	}

	EditScroll(hEdit, regex:="", line:=0, pos:=0)
	{
	local
	ControlGetText, s,, ahk_id %hEdit%
	pos:=(regex!="") ? InStr(SubStr(s,1,s~=regex),"`n",0,0)
		: (line>1) ? InStr(s,"`n",0,1,line-1) : pos
	SendMessage, 0xB1, pos, pos,, ahk_id %hEdit%
	SendMessage, 0xB7,,,, ahk_id %hEdit%
	}

	LastCtrl()
	{
	local
	return (G:=GuiFromHwnd(WinExist()))[G.LastHwnd]
	}

	Hide(args*)
	{
	WinMinimize
	WinHide
	ToolTip
	DetectHiddenWindows 0
	WinWaitClose % "ahk_id " WinExist()
	}

	Gui(cmd, arg1:="", args*)
	{
	local
	static
	local bch, cri, lls, _Gui
	ListLines, % InStr("MouseMove|ToolTipOff",cmd)?0:A_ListLines
	static init
	if !VarSetCapacity(init) && (init:="1")
	{
		SavePicDir:=A_Temp "\Ahk_ScreenShot\"
		G_ := this.Gui.Bind(this)
		G_G := this.Gui.Bind(this, "G")
		G_Run := this.Gui.Bind(this, "Run")
		G_Show := this.Gui.Bind(this, "Show")
		G_KeyDown := this.Gui.Bind(this, "KeyDown")
		G_LButtonDown := this.Gui.Bind(this, "LButtonDown")
		G_RButtonDown := this.Gui.Bind(this, "RButtonDown")
		G_MouseMove := this.Gui.Bind(this, "MouseMove")
		G_ScreenShot := this.Gui.Bind(this, "ScreenShot")
		G_ShowPic := this.Gui.Bind(this, "ShowPic")
		G_Slider := this.Gui.Bind(this, "Slider")
		G_ToolTip := this.Gui.Bind(this, "ToolTip")
		G_ToolTipOff := this.Gui.Bind(this, "ToolTipOff")
		G_SaveScr := this.Gui.Bind(this, "SaveScr")
		graphicsearch_Capture:=graphicsearch_Main:=graphicsearch_SubPic:=""
		bch:=A_BatchLines, cri:=A_IsCritical
		Critical
		#NoEnv
		Lang:=this.Lang(,1), Tip_Text:=this.Lang(,2)
		G_.Call("MakeCaptureWindow")
		G_.Call("MakeMainWindow")
		OnMessage(0x100, G_KeyDown)
		OnMessage(0x201, G_LButtonDown)
		OnMessage(0x204, G_RButtonDown)
		OnMessage(0x200, G_MouseMove)
		Menu, Tray, Add
		Menu, Tray, Add, % Lang["s1"], % G_Show
		if (!A_IsCompiled && A_LineFile=A_ScriptFullPath)
		{
		Menu, Tray, Default, % Lang["s1"]
		Menu, Tray, Click, 1
		Menu, Tray, Icon, Shell32.dll, 23
		}
		Critical % cri
		SetBatchLines % bch
		Gui("+LastFound").Destroy()
		Pics:=PrevControl:=x:=y:=oldx:=oldy:="", dx:=dy:=oldt:=0
	}
	Switch cmd
	{
	Case "G":
		id:=this.LastCtrl()
		Try id.OnEvent("Click", G_Run)
		Catch
		Try id.OnEvent("Change", G_Run)
		return
	Case "Run":
		Critical
		G_.Call(arg1.Name)
		return
	Case "Show":
		graphicsearch_Main.Show(arg1 ? "Center" : "")
		ControlFocus,, % "ahk_id " hscr
		return
	Case "Cancel", "Cancel2":
		WinHide
		return
	Case "MakeCaptureWindow":
		WindowColor:="0xDDEEFF"
		Try graphicsearch_Capture.Destroy()
		graphicsearch_Capture:=_Gui:=Gui()
		_Gui.Opt("+LastFound +AlwaysOnTop -DPIScale")
		_Gui.MarginX:=15, _Gui.MarginY:=10
		_Gui.BackColor:=WindowColor
		_Gui.SetFont("s12", "Verdana")
		Tab:=_Gui.Add("Tab3", "vMyTab1 -Wrap", StrSplit(Lang["s18"],"|"))
		Tab.UseTab(1)
		C_:=[], nW:=71, nH:=25, w:=h:=12, pW:=nW*(w+1)-1, pH:=(nH+1)*(h+1)-1
		_Gui.Opt("-Theme")
		ListLines % (lls:=A_ListLines)?0:0
		Loop % nW*(nH+1)
		{
		i:=A_Index, j:=i=1 ? "Section" : Mod(i,nW)=1 ? "xs y+1":"x+1"
		id:=_Gui.Add("Progress", j " w" w " h" h " -E0x20000 Smooth")
		C_[i]:=id.Hwnd
		}
		ListLines % lls
		_Gui.Opt("+Theme")
		_Gui.Add("Slider", "xs w" pW " vMySlider1 +Center Page20 Line10 NoTicks AltSubmit")
		G_G.Call()
		_Gui.Add("Slider", "ys h" pH " vMySlider2 +Center Page20 Line10 NoTicks AltSubmit +Vertical")
		G_G.Call()
		Tab.UseTab(2)
		id:=_Gui.Add("Text", "w" (pW-135) " h" pH " +Border Section"), parent_id:=id.Hwnd
		_Gui.Add("Slider", "xs wp vMySlider3 +Center Page20 Line10 NoTicks AltSubmit")
		G_G.Call()
		_Gui.Add("Slider", "ys h" pH " vMySlider4 +Center Page20 Line10 NoTicks AltSubmit +Vertical")
		G_G.Call()
		_Gui.Add("ListBox", "ys w120 h200 vSelectBox AltSubmit 0x100")
		G_G.Call()
		_Gui.Add("Button", "y+0 wp vClearAll", Lang["ClearAll"])
		G_G.Call()
		_Gui.Add("Button", "y+0 wp vOpenDir", Lang["OpenDir"])
		G_G.Call()
		_Gui.Add("Button", "y+0 wp vLoadPic", Lang["LoadPic"])
		G_G.Call()
		_Gui.Add("Button", "y+0 wp vSavePic", Lang["SavePic"])
		G_G.Call()
		Tab.UseTab()
		_Gui.Add("Text", "xm Section", Lang["SelGray"])
		_Gui.Add("Edit", "x+5 yp-3 w80 vSelGray ReadOnly")
		_Gui.Add("Text", "x+15 ys", Lang["SelColor"])
		_Gui.Add("Edit", "x+5 yp-3 w150 vSelColor ReadOnly")
		_Gui.Add("Text", "x+15 ys", Lang["SelR"])
		_Gui.Add("Edit", "x+5 yp-3 w80 vSelR ReadOnly")
		_Gui.Add("Text", "x+5 ys", Lang["SelG"])
		_Gui.Add("Edit", "x+5 yp-3 w80 vSelG ReadOnly")
		_Gui.Add("Text", "x+5 ys", Lang["SelB"])
		_Gui.Add("Edit", "x+5 yp-3 w80 vSelB ReadOnly")
		id:=_Gui.Add("Button", "xm Hidden Section", Lang["Auto"])
		id.GetPos(pX, pY, pW, pH)
		w:=Round(pW*0.75), i:=Round(w*3+15+pW*0.5-w*1.5)
		_Gui.Add("Button", "xm+" i " yp w" w " hp -Wrap vRepU", Lang["RepU"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp hp -Wrap vCutU", Lang["CutU"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp hp -Wrap vCutU3", Lang["CutU3"])
		G_G.Call()
		_Gui.Add("Button", "xm wp hp -Wrap vRepL", Lang["RepL"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp hp -Wrap vCutL", Lang["CutL"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp hp -Wrap vCutL3", Lang["CutL3"])
		G_G.Call()
		_Gui.Add("Button", "x+15 w" pW " hp -Wrap vAuto", Lang["Auto"])
		G_G.Call()
		_Gui.Add("Button", "x+15 w" w " hp -Wrap vRepR", Lang["RepR"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp hp -Wrap vCutR", Lang["CutR"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp hp -Wrap vCutR3", Lang["CutR3"])
		G_G.Call()
		_Gui.Add("Button", "xm+" i " wp hp -Wrap vRepD", Lang["RepD"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp hp -Wrap vCutD", Lang["CutD"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp hp -Wrap vCutD3", Lang["CutD3"])
		G_G.Call()
		Tab:=_Gui.Add("Tab3", "ys -Wrap", StrSplit(Lang["s2"],"|"))
		Tab.UseTab(1)
		_Gui.Add("Text", "x+30 y+35", Lang["Threshold"])
		_Gui.Add("Edit", "x+15 w100 vThreshold")
		_Gui.Add("Button", "x+15 yp-3 vGray2Two", Lang["Gray2Two"])
		G_G.Call()
		Tab.UseTab(2)
		_Gui.Add("Text", "x+30 y+35", Lang["GrayDiff"])
		_Gui.Add("Edit", "x+15 w100 vGrayDiff", "50")
		_Gui.Add("Button", "x+15 yp-3 vGrayDiff2Two", Lang["GrayDiff2Two"])
		G_G.Call()
		Tab.UseTab(3)
		_Gui.Add("Text", "x+10 y+15 Section", Lang["Similar1"])
		_Gui.Add("Edit", "x+5 w80 vSimilar1 Limit3")
		_Gui.Add("UpDown", "vSim Range0-100", 90)
		_Gui.Add("Button", "x+10 ys-2 vAddColorSim", Lang["AddColorSim"])
		G_G.Call()
		_Gui.Add("Text", "x+20 ys+4", Lang["DiffRGB2"])
		_Gui.Add("Edit", "x+5 ys w80 vDiffRGB2 Limit3")
		_Gui.Add("UpDown", "vdRGB2 Range0-255 Wrap", 16)
		_Gui.Add("Button", "x+10 ys-2 vAddColorDiff", Lang["AddColorDiff"])
		G_G.Call()
		_Gui.Add("Button", "xs vUndo2", Lang["Undo2"])
		G_G.Call()
		_Gui.Add("Edit", "x+10 yp+2 w340 vColorList")
		_Gui.Add("Button", "x+10 yp-2 vColor2Two", Lang["Color2Two"])
		G_G.Call()
		Tab.UseTab(4)
		_Gui.Add("Text", "x+30 y+35", Lang["Similar2"] " 0")
		_Gui.Add("Slider", "x+0 w120 vSimilar2 +Center Page1 NoTicks ToolTip", 90)
		_Gui.Add("Text", "x+0", "100")
		_Gui.Add("Button", "x+15 yp-3 vColorPos2Two", Lang["ColorPos2Two"])
		G_G.Call()
		Tab.UseTab(5)
		_Gui.Add("Text", "x+30 y+35", Lang["DiffRGB"])
		_Gui.Add("Edit", "x+5 w80 vDiffRGB Limit3")
		_Gui.Add("UpDown", "vdRGB Range0-255 Wrap", 16)
		_Gui.Add("Checkbox", "x+15 yp+5 vMultiColor", Lang["MultiColor"])
		G_G.Call()
		_Gui.Add("Button", "x+15 yp-5 vUndo", Lang["Undo"])
		G_G.Call()
		Tab.UseTab()
		_Gui.Add("Button", "xm vReset", Lang["Reset"])
		G_G.Call()
		_Gui.Add("Checkbox", "x+15 yp+5 vModify", Lang["Modify"])
		G_G.Call()
		_Gui.Add("Text", "x+30", Lang["Comment"])
		_Gui.Add("Edit", "x+5 yp-2 w250 vComment")
		_Gui.Add("Button", "x+10 yp-3 vSplitAdd", Lang["SplitAdd"])
		G_G.Call()
		_Gui.Add("Button", "x+10 vAllAdd", Lang["AllAdd"])
		G_G.Call()
		_Gui.Add("Button", "x+30 wp vOK", Lang["OK"])
		G_G.Call()
		_Gui.Add("Button", "x+15 wp vCancel", Lang["Cancel"])
		G_G.Call()
		_Gui.Add("Button", "xm vBind0", Lang["Bind0"])
		G_G.Call()
		_Gui.Add("Button", "x+10 vBind1", Lang["Bind1"])
		G_G.Call()
		_Gui.Add("Button", "x+10 vBind2", Lang["Bind2"])
		G_G.Call()
		_Gui.Add("Button", "x+10 vBind3", Lang["Bind3"])
		G_G.Call()
		_Gui.Add("Button", "x+10 vBind4", Lang["Bind4"])
		G_G.Call()
		_Gui.Add("Button", "x+30 vSavePic2", Lang["SavePic2"])
		G_G.Call()
		_Gui.Title:=Lang["s3"]
		_Gui.Show("Hide")
		Try graphicsearch_SubPic.Destroy()
		graphicsearch_SubPic:=_Gui:=Gui()
		_Gui.Opt("+Parent" parent_id " -Caption +ToolWindow -DPIScale")
		_Gui.MarginX:=0, _Gui.MarginY:=0
		_Gui.BackColor:="White"
		id:=_Gui.Add("Pic", "x0 y0 w100 h100"), sub_hpic:=id.Hwnd
		_Gui.Title:="SubPic"
		_Gui.Show("Hide")
		return
	Case "MakeMainWindow":
		Try graphicsearch_Main.Destroy()
		graphicsearch_Main:=_Gui:=Gui()
		_Gui.Opt("+LastFound -DPIScale")
		_Gui.MarginX:=15, _Gui.MarginY:=10
		_Gui.BackColor:=WindowColor
		_Gui.SetFont("s12", "Verdana")
		_Gui.Add("Text", "xm", Lang["NowHotkey"])
		_Gui.Add("Edit", "x+5 w160 vNowHotkey ReadOnly")
		_Gui.Add("Hotkey", "x+5 w160 vSetHotkey1")
		s:="F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|LWin|Ctrl|Shift|Space|MButton"
		. "|ScrollLock|CapsLock|Ins|Esc|BS|Del|Tab|Home|End|PgUp|PgDn"
		. "|NumpadDot|NumpadSub|NumpadAdd|NumpadDiv|NumpadMult"
		_Gui.Add("DDL", "x+5 w160 vSetHotkey2", StrSplit(s,"|"))
		_Gui.Add("Button", "x+15 vApply", Lang["Apply"])
		G_G.Call()
		_Gui.Add("GroupBox", "xm y+0 w280 h55 vMyGroup cBlack")
		_Gui.Add("Text", "xp+15 yp+20 Section", Lang["Myww"] ": ")
		_Gui.Add("Text", "x+0 w80", nW//2)
		_Gui.Add("UpDown", "vMyww Range1-100", nW//2)
		_Gui.Add("Text", "x+15 ys", Lang["Myhh"] ": ")
		_Gui.Add("Text", "x+0 w80", nH//2)
		id:=_Gui.Add("UpDown", "vMyhh Range1-100", nH//2)
		id.GetPos(pX, pY, pW, pH)
		_Gui["MyGroup"].Move(,, pX+pW, pH+30)
		id:=_Gui.Add("Checkbox", "x+100 ys vAddFunc", Lang["AddFunc"] " graphicsearch()")
		id.GetPos(pX, pY, pW, pH)
		pW:=pX+pW-15, pW:=(pW<720?720:pW), w:=pW//5
		_Gui.Add("Button", "xm y+18 w" w " vCutL2", Lang["CutL2"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp vCutR2", Lang["CutR2"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp vCutU2", Lang["CutU2"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp vCutD2", Lang["CutD2"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp vUpdate", Lang["Update"])
		G_G.Call()
		_Gui.SetFont("s6 bold", "Verdana")
		_Gui.Add("Edit", "xm y+10 w" pW " h260 vMyPic -Wrap HScroll")
		_Gui.SetFont("s12 norm", "Verdana")
		w:=pW//3
		_Gui.Add("Button", "xm w" w " vCapture", Lang["Capture"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp vTest", Lang["Test"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp vCopy", Lang["Copy"])
		G_G.Call()
		_Gui.Add("Button", "xm y+0 wp vCaptureS", Lang["CaptureS"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp vGetRange", Lang["GetRange"])
		G_G.Call()
		_Gui.Add("Button", "x+0 wp vGetOffset", Lang["GetOffset"])
		G_G.Call()
		_Gui.Add("Edit", "xm y+10 w130 hp vClipText")
		_Gui.Add("Button", "x+0 vPaste", Lang["Paste"])
		G_G.Call()
		_Gui.Add("Button", "x+0 vTestClip", Lang["TestClip"])
		G_G.Call()
		id:=_Gui.Add("Button", "x+0 vGetClipOffset", Lang["GetClipOffset"])
		G_G.Call()
		id.GetPos(x,, w)
		w:=((pW+15)-(x+w))//2
		_Gui.Add("Edit", "x+0 w" w " hp vOffset")
		_Gui.Add("Button", "x+0 wp vCopyOffset", Lang["CopyOffset"])
		G_G.Call()
		_Gui.SetFont("cBlue")
		id:=_Gui.Add("Edit", "xm w" pW " h250 vscr -Wrap HScroll"), hscr:=id.Hwnd
		_Gui.Title:=Lang["s4"]
		_Gui.Show("Hide")
		G_.Call("LoadScr")
		OnExit(G_SaveScr)
		return
	Case "LoadScr":
		f:=A_Temp "\~scr1.tmp"
		FileRead, s, %f%
		graphicsearch_Main["scr"].Value:=s
		return
	Case "SaveScr":
		f:=A_Temp "\~scr1.tmp"
		s:=graphicsearch_Main["scr"].Value
		Try FileDelete, %f%
		FileAppend, %s%, %f%
		return
	Case "Capture", "CaptureS":
		_Gui:=graphicsearch_Main
		if show_gui:=(WinExist("ahk_id" _Gui.Hwnd))
		this.Hide()
		if (cmd="Capture")
		{
		w:=_Gui["Myww"].Value
		h:=_Gui["Myhh"].Value
		p:=this.GetRange(w, h)
		sx:=p[1], sy:=p[2], sw:=p[3]-p[1]+1, sh:=p[4]-p[2]+1
		, Bind_ID:=p[5], bind_mode:=""
		_Gui:=graphicsearch_Capture
		_Gui["MyTab1"].Choose(1)
		}
		else
		{
		sx:=0, sy:=0, sw:=1, sh:=1, Bind_ID:=WinExist("A"), bind_mode:=""
		_Gui:=graphicsearch_Capture
		_Gui["MyTab1"].Choose(2)
		}
		n:=150000, x:=y:=-n, w:=h:=2*n
		hBM:=this.BitmapFromScreen(x,y,w,h,(arg1=0?0:1))
		G_.Call("CaptureUpdate")
		G_.Call("PicUpdate")
		graphicsearch_SubPic.Show()
		Names:=[], s:=""
		Loop Files, % SavePicDir "*.bmp"
		Names.Push(v:=A_LoopFileFullPath), s.="|" RegExReplace(v,"i)^.*\\|\.bmp$")
		_Gui["SelectBox"].Delete()
		_Gui["SelectBox"].Add(StrSplit(Trim(s,"|"),"|"))
		s:="SelGray|SelColor|SelR|SelG|SelB|Threshold|Comment|ColorList"
		Loop Parse, s, |
		_Gui[A_LoopField].Value:=""
		_Gui["Modify"].Value:=Modify:=0
		_Gui["MultiColor"].Value:=MultiColor:=0
		_Gui["GrayDiff"].Value:=50
		_Gui["Gray2Two"].Focus()
		_Gui["Gray2Two"].Opt("+Default")
		_Gui.Show("Center")
		Event:=Result:=""
		DetectHiddenWindows 0
		Critical, Off
		WinWaitClose % "ahk_id " _Gui.Hwnd
		Critical
		ToolTip
		graphicsearch_SubPic.Hide()
		_Gui:=graphicsearch_Main
		Clipboard:=Text:=RegExMatch(Result,"O)\|<[^>\n]*>[^$\n]+\$[^""\r\n]+",r)?r[0]:""
		if (bind_mode!="")
		{
		WinGetTitle, tt, ahk_id %Bind_ID%
		WinGetClass, tc, ahk_id %Bind_ID%
		tt:=Trim(SubStr(tt,1,30) (tc ? " ahk_class " tc:""))
		tt:=StrReplace(RegExReplace(tt,"[;``]","``$0"),"""","""""")
		Result:="`nSetTitleMatchMode 2`nid:=WinExist(""" tt """)"
			. "`ngraphicsearch().BindWindow(id" (bind_mode=0 ? "":"," bind_mode)
			. ")  `; " Lang["s6"] " graphicsearch().BindWindow(0)`n`n" Result
		}
		if (Event="OK")
		{
		s:=""
		if (!A_IsCompiled)
			Try FileRead, s, %A_LineFile%
		re:="Oi)\n\s*graphicsearch[^\n]+args\*[\s\S]*"
		s:=RegExMatch(s, re, r) ? "`n;==========`n" r[0] "`n" : ""
		_Gui["scr"].Value:=Result "`n" s
		_Gui["MyPic"].Value:=Trim(this.ASCII(Result),"`n")
		}
		else if (Event="SplitAdd") || (Event="AllAdd")
		{
		s:=_Gui["scr"].Value
		r:=SubStr(s, 1, InStr(s,"=graphicsearch("))
		i:=j:=0, re:="<[^>\n]*>[^$\n]+\$[^""\r\n]+"
		While j:=RegExMatch(r, re,, j+1)
			i:=InStr(r, "`n", 0, j)
		_Gui["scr"].Value:=SubStr(s,1,i) . Result . SubStr(s,i+1)
		_Gui["MyPic"].Value:=Trim(this.ASCII(Result),"`n")
		}
		if (Event) && RegExMatch(Result, "O)\$\d+\.[\w+/]{1,100}", r)
		this.EditScroll(hscr, "\Q" r[0] "\E")
		Event:=Result:=s:=""
		if (show_gui && arg1="")
		G_Show.Call()
		return Text
	Case "CaptureUpdate":
		nX:=sx, nY:=sy, nW:=sw, nH:=sh
		bits:=this.GetBitsFromScreen(nX,nY,nW,nH,0,zx,zy)
		cors:=[], show:=[], ascii:=[]
		, SelPos:=bg:=color:=""
		, dx:=dy:=CutLeft:=CutRight:=CutUp:=CutDown:=0
		ListLines % (lls:=A_ListLines)?0:0
		if (nW>0 && nH>0 && bits.Scan0)
		{
		j:=bits.Stride-nW*4, p:=bits.Scan0+(nY-zy)*bits.Stride+(nX-zx)*4-j-4
		Loop % nH + 0*(k:=0)
		Loop % nW + 0*(p+=j)
			show[++k]:=1, cors[k]:=NumGet(0|p+=4,"uint")
		}
		Loop % 25 + 0*(ty:=dy-1)*(k:=0)
		Loop % 71 + 0*(tx:=dx-1)*(ty++)
		{
		c:=(++tx)<nW && ty<nH ? cors[ty*nW+tx+1] : WindowColor
		SendMessage,0x2001,0,(c&0xFF)<<16|c&0xFF00|(c>>16)&0xFF,,% "ahk_id " C_[++k]
		}
		Loop % 71 + 0*(k:=71*25)
		SendMessage,0x2001,0,0xAAFFFF,,% "ahk_id " C_[++k]
		ListLines % lls
		_Gui:=graphicsearch_Capture
		_Gui["MySlider1"].Enabled:=nW>71
		_Gui["MySlider2"].Enabled:=nH>25
		_Gui["MySlider1"].Value:=0
		_Gui["MySlider2"].Value:=0
		return
	Case "PicUpdate":
		graphicsearch_SubPic[sub_hpic].Value:="*w0 *h0 HBITMAP:" hBM
		_Gui:=graphicsearch_Capture
		_Gui["MySlider3"].Value:=0
		_Gui["MySlider4"].Value:=0
		G_.Call("MySlider3")
		return
	Case "MySlider3", "MySlider4":
		_Gui:=graphicsearch_Capture
		_Gui[parent_id].GetPos(,, w, h)
		MySlider3:=_Gui["MySlider3"].Value
		MySlider4:=_Gui["MySlider4"].Value
		graphicsearch_SubPic[sub_hpic].GetPos(,, pW, pH)
		x:=pW>w ? -Round((pW-w)*MySlider3/100) : 0
		y:=pH>h ? -Round((pH-h)*MySlider4/100) : 0
		graphicsearch_SubPic.Show("NA x" x " y" y " w" pW " h" pH)
		return
	Case "Reset":
		G_.Call("CaptureUpdate")
		return
	Case "LoadPic":
		graphicsearch_Capture.Opt("+OwnDialogs")
		f:=arg1
		if (f="")
		{
		if !FileExist(SavePicDir)
			FileCreateDir, % SavePicDir
		f:=SavePicDir "*.bmp"
		Loop Files, % f
			f:=A_LoopFileFullPath
		FileSelectFile, f,, %f%, Select Picture
		}
		if !FileExist(f)
		{
		MsgBox, 4096, Tip, % Lang["s17"] " !", 1
		return
		}
		this.ShowPic(f, 0, sx, sy, sw, sh)
		hBM:=this.BitmapFromScreen(sx, sy, sw, sh, 0)
		sw:=Min(sw,200), sh:=Min(sh,200)
		G_.Call("CaptureUpdate")
		G_.Call("PicUpdate")
		return
	Case "SavePic":
		_Gui:=graphicsearch_Capture
		SelectBox:=_Gui["SelectBox"].Value
		Try f:="", f:=Names[SelectBox]
		_Gui.Hide()
		this.ShowPic(f)
		Try GuiFromHwnd(WinExist("Show Pic")).Opt("+OwnDialogs")
		Loop
		{
		p:=this.GetRange2()
		MsgBox, 4100, Tip, % Lang["s15"] " !"
		IfMsgBox, Yes
			Break
		}
		G_.Call("ScreenShot", p[1] "|" p[2] "|" p[3] "|" p[4] "|0")
		this.ShowPic()
		return
	Case "SelectBox":
		SelectBox:=graphicsearch_Capture["SelectBox"].Value
		Try f:="", f:=Names[SelectBox]
		if (f!="")
		G_.Call("LoadPic", f)
		return
	Case "ClearAll":
		graphicsearch_Capture.Hide()
		FileDelete, % SavePicDir "*.bmp"
		return
	Case "OpenDir":
		graphicsearch_Capture.Minimize()
		if !FileExist(SavePicDir)
		FileCreateDir, % SavePicDir
		Run, % SavePicDir
		return
	Case "GetRange":
		_Gui:=graphicsearch_Main
		_Gui.Opt("+LastFound")
		this.Hide()
		p:=this.GetRange2(), v:=p[1] ", " p[2] ", " p[3] ", " p[4]
		s:=_Gui["scr"].Value
		re:="i)(=graphicsearch\([^\n]*?)([^(,\n]*,){4}([^,\n]*,[^,\n]*,[^,\n]*Text)"
		if SubStr(s,1,s~="i)\n\s*graphicsearch[^\n]+args\*")~=re
		{
		s:=RegExReplace(s, re, "$1 " v ",$3",, 1)
		_Gui["scr"].Value:=s
		}
		_Gui["Offset"].Value:=v
		G_Show.Call()
		return
	Case "Test", "TestClip":
		_Gui:=graphicsearch_Main
		_Gui.Opt("+LastFound")
		this.Hide()
		if (cmd="Test")
		s:=_Gui["scr"].Value
		else
		s:=_Gui["ClipText"].Value
		if (cmd="Test") && InStr(s, "MCode(")
		{
		s:="`n#NoEnv`nMenu, Tray, Click, 1`n" s "`nExitApp`n"
		Thread1:=new this.Thread(s)
		DetectHiddenWindows, 1
		WinWait, % "ahk_class AutoHotkey ahk_pid " Thread1.pid,, 3
		if (!ErrorLevel)
			WinWaitClose,,, 30
		}
		else
		{
		t:=A_TickCount, v:=X:=Y:=""
		if RegExMatch(s, "O)<[^>\n]*>[^$\n]+\$[^""\r\n]+", r)
			v:=this.graphicsearch(X, Y, 0,0,0,0, 0,0, r[0])
		r:=StrSplit(Lang["s8"] "||||", "|")
		MsgBox, 4096, Tip, % r[1] ":`t" (IsObject(v)?v.Length():v) "`n`n"
			. r[2] ":`t" (A_TickCount-t) " " r[3] "`n`n"
			. r[4] ":`t" X ", " Y "`n`n"
			. r[5] ":`t<" (IsObject(v)?v[1].id:"") ">", 3
		Try For i,j in v
			if (i<=2)
			this.MouseTip(j.x, j.y)
		v:="", Clipboard:=X "," Y
		}
		G_Show.Call()
		return
	Case "GetOffset", "GetClipOffset":
		graphicsearch_Main.Hide()
		p:=this.GetRange()
		_Gui:=graphicsearch_Main
		if (cmd="GetOffset")
		s:=_Gui["scr"].Value
		else
		s:=_Gui["ClipText"].Value
		if RegExMatch(s, "O)<[^>\n]*>[^$\n]+\$[^""\r\n]+", r)
		&& this.graphicsearch(X, Y, 0,0,0,0, 0,0, r[0])
		{
		r:=StrReplace("X+" ((p[1]+p[3])//2-X)
			. ", Y+" ((p[2]+p[4])//2-Y), "+-", "-")
		if (cmd="GetOffset")
		{
			re:="i)(\(\)\.\w*Click\w*\()[^,\n]*,[^,)\n]*"
			if SubStr(s,1,s~="i)\n\s*graphicsearch[^\n]+args\*")~=re
			s:=RegExReplace(s, re, "$1" r,, 1)
			_Gui["scr"].Value:=s
		}
		_Gui["Offset"].Value:=r
		}
		s:="", G_Show.Call()
		return
	Case "Paste":
		if RegExMatch(Clipboard, "O)\|?<[^>\n]*>[^$\n]+\$[^""\r\n]+", r)
		{
		graphicsearch_Main["ClipText"].Value:=r[0]
		graphicsearch_Main["MyPic"].Value:=Trim(this.ASCII(r[0]),"`n")
		}
		return
	Case "CopyOffset":
		Clipboard:=graphicsearch_Main["Offset"].Value
		return
	Case "Copy":
		ControlGet, s, Selected,,, ahk_id %hscr%
		if (s="")
		{
		s:=graphicsearch_Main["scr"].Value
		r:=graphicsearch_Main["AddFunc"].Value
		if (r != 1)
			s:=RegExReplace(s, "i)\n\s*graphicsearch[^\n]+args\*[\s\S]*")
			, s:=RegExReplace(s, "i)\n; ok:=graphicsearch[\s\S]*")
			, s:=SubStr(s, (s~="i)\n[ \t]*Text"))
		}
		Clipboard:=RegExReplace(s, "\R", "`r`n")
		ControlFocus,, % "ahk_id " hscr
		return
	Case "Apply":
		_Gui:=graphicsearch_Main
		NowHotkey:=_Gui["NowHotkey"].Value
		SetHotkey1:=_Gui["SetHotkey1"].Value
		SetHotkey2:=_Gui["SetHotkey2"].Text
		if (NowHotkey!="")
		Hotkey, *%NowHotkey%,, Off UseErrorLevel
		k:=SetHotkey1!="" ? SetHotkey1 : SetHotkey2
		if (k!="")
		Hotkey, *%k%, %G_ScreenShot%, On UseErrorLevel
		_Gui["NowHotkey"].Value:=k
		_Gui["SetHotkey1"].Value:=""
		_Gui["SetHotkey2"].Choose(0)
		return
	Case "ScreenShot":
		Critical
		if !FileExist(SavePicDir)
		FileCreateDir, % SavePicDir
		Loop
		f:=SavePicDir . Format("{:03d}.bmp",A_Index)
		Until !FileExist(f)
		this.SavePic(f, StrSplit(arg1,"|")*)
		CoordMode, ToolTip
		this.ToolTip(Lang["s9"],, 0,, { bgcolor:"Yellow", color:"Red"
		, size:48, bold:"bold", trans:200, timeout:0.2 })
		return
	Case "Bind0", "Bind1", "Bind2", "Bind3", "Bind4":
		this.BindWindow(Bind_ID, bind_mode:=SubStr(cmd,5))
		n:=150000, x:=y:=-n, w:=h:=2*n
		hBM:=this.BitmapFromScreen(x,y,w,h,1)
		G_.Call("PicUpdate")
		graphicsearch_Capture["MyTab1"].Choose(2)
		this.BindWindow(0)
		return
	Case "MySlider1", "MySlider2":
		SetTimer, %G_Slider%, -10
		return
	Case "Slider":
		Critical
		_Gui:=graphicsearch_Capture
		MySlider1:=_Gui["MySlider1"].Value
		MySlider2:=_Gui["MySlider2"].Value
		dx:=nW>71 ? Round((nW-71)*MySlider1/100) : 0
		dy:=nH>25 ? Round((nH-25)*MySlider2/100) : 0
		if (oldx=dx && oldy=dy)
		return
		ListLines % (lls:=A_ListLines)?0:0
		Loop % 25 + 0*(ty:=dy-1)*(k:=0)
		Loop % 71 + 0*(tx:=dx-1)*(ty++)
		{
		c:=((++tx)>=nW || ty>=nH || !show[i:=ty*nW+tx+1]
		? WindowColor : bg="" ? cors[i] : ascii[i] ? 0 : 0xFFFFFF)
		SendMessage,0x2001,0,(c&0xFF)<<16|c&0xFF00|(c>>16)&0xFF,,% "ahk_id " C_[++k]
		}
		Loop % 71*(oldx!=dx) + 0*(i:=nW*nH+dx)*(k:=71*25)
		SendMessage,0x2001,0,(show[++i]?0x0000FF:0xAAFFFF),,% "ahk_id " C_[++k]
		ListLines % lls
		oldx:=dx, oldy:=dy
		return
	Case "RepColor", "CutColor":
		if (cmd="RepColor")
		show[k]:=1, c:=(bg="" ? cors[k] : ascii[k] ? 0 : 0xFFFFFF)
		else
		show[k]:=0, c:=WindowColor
		if (tx:=Mod(k-1,nW)-dx)>=0 && tx<71 && (ty:=(k-1)//nW-dy)>=0 && ty<25
		SendMessage,0x2001,0,(c&0xFF)<<16|c&0xFF00|(c>>16)&0xFF,,% "ahk_id " C_[ty*71+tx+1]
		return
	Case "RepL":
		if (CutLeft<=0) || (bg!="" && InStr(color,"**") && CutLeft=1)
		return
		k:=CutLeft-nW, CutLeft--
		Loop % nH
		k+=nW, (A_Index>CutUp && A_Index<nH+1-CutDown && G_.Call("RepColor"))
		return
	Case "CutL":
		if (CutLeft+CutRight>=nW)
		return
		CutLeft++, k:=CutLeft-nW
		Loop % nH
		k+=nW, (A_Index>CutUp && A_Index<nH+1-CutDown && G_.Call("CutColor"))
		return
	Case "CutL3":
		Loop 3
		G_.Call("CutL")
		return
	Case "RepR":
		if (CutRight<=0) || (bg!="" && InStr(color,"**") && CutRight=1)
		return
		k:=1-CutRight, CutRight--
		Loop % nH
		k+=nW, (A_Index>CutUp && A_Index<nH+1-CutDown && G_.Call("RepColor"))
		return
	Case "CutR":
		if (CutLeft+CutRight>=nW)
		return
		CutRight++, k:=1-CutRight
		Loop % nH
		k+=nW, (A_Index>CutUp && A_Index<nH+1-CutDown && G_.Call("CutColor"))
		return
	Case "CutR3":
		Loop 3
		G_.Call("CutR")
		return
	Case "RepU":
		if (CutUp<=0) || (bg!="" && InStr(color,"**") && CutUp=1)
		return
		k:=(CutUp-1)*nW, CutUp--
		Loop % nW
		k++, (A_Index>CutLeft && A_Index<nW+1-CutRight && G_.Call("RepColor"))
		return
	Case "CutU":
		if (CutUp+CutDown>=nH)
		return
		CutUp++, k:=(CutUp-1)*nW
		Loop % nW
		k++, (A_Index>CutLeft && A_Index<nW+1-CutRight && G_.Call("CutColor"))
		return
	Case "CutU3":
		Loop 3
		G_.Call("CutU")
		return
	Case "RepD":
		if (CutDown<=0) || (bg!="" && InStr(color,"**") && CutDown=1)
		return
		k:=(nH-CutDown)*nW, CutDown--
		Loop % nW
		k++, (A_Index>CutLeft && A_Index<nW+1-CutRight && G_.Call("RepColor"))
		return
	Case "CutD":
		if (CutUp+CutDown>=nH)
		return
		CutDown++, k:=(nH-CutDown)*nW
		Loop % nW
		k++, (A_Index>CutLeft && A_Index<nW+1-CutRight && G_.Call("CutColor"))
		return
	Case "CutD3":
		Loop 3
		G_.Call("CutD")
		return
	Case "Gray2Two":
		ListLines % (lls:=A_ListLines)?0:0
		gs:=[], k:=0
		Loop % nW*nH
		gs[++k]:=((((c:=cors[k])>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
		_Gui:=graphicsearch_Capture
		_Gui["Threshold"].Focus()
		Threshold:=_Gui["Threshold"].Value
		if (Threshold="")
		{
		pp:=[]
		Loop 256
			pp[A_Index-1]:=0
		Loop % nW*nH
			if (show[A_Index])
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
		_Gui["Threshold"].Value:=Threshold
		}
		Threshold:=Round(Threshold)
		color:="*" Threshold, k:=i:=0
		Loop % nW*nH
		ascii[++k]:=v:=(gs[k]<=Threshold)
		, (show[k] && i:=(v?i+1:i-1))
		bg:=(i>0 ? "1":"0"), G_.Call("BlackWhite")
		ListLines % lls
		return
	Case "GrayDiff2Two":
		_Gui:=graphicsearch_Capture
		GrayDiff:=_Gui["GrayDiff"].Value
		if (GrayDiff="")
		{
		_Gui.Opt("+OwnDialogs")
		MsgBox, 4096, Tip, % Lang["s11"] " !", 1
		return
		}
		ListLines % (lls:=A_ListLines)?0:0
		gs:=[], k:=0
		Loop % nW*nH
		gs[++k]:=((((c:=cors[k])>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
		if (CutLeft=0)
		G_.Call("CutL")
		if (CutRight=0)
		G_.Call("CutR")
		if (CutUp=0)
		G_.Call("CutU")
		if (CutDown=0)
		G_.Call("CutD")
		GrayDiff:=Round(GrayDiff)
		color:="**" GrayDiff, k:=i:=0
		Loop % nW*nH
		j:=gs[++k]+GrayDiff
		, ascii[k]:=v:=( gs[k-1]>j || gs[k+1]>j
		|| gs[k-nW]>j || gs[k+nW]>j
		|| gs[k-nW-1]>j || gs[k-nW+1]>j
		|| gs[k+nW-1]>j || gs[k+nW+1]>j )
		, (show[k] && i:=(v?i+1:i-1))
		bg:=(i>0 ? "1":"0"), G_.Call("BlackWhite")
		ListLines % lls
		return
	Case "AddColorSim", "AddColorDiff":
		_Gui:=graphicsearch_Capture
		c:=_Gui["SelColor"].Value
		if (c="")
		{
		_Gui.Opt("+OwnDialogs")
		MsgBox, 4096, Tip, % Lang["s12"] " !", 1
		return
		}
		s:=_Gui["ColorList"].Value, c:=StrReplace(c,"0x")
		if InStr(cmd, "Sim")
		v:=_Gui["Sim"].Value, v:=c "@" Round(v/100,2)
		, s:=RegExReplace("/" s, "/" c "@[^/]*") . "/" v
		else
		v:=_Gui["dRGB2"].Value, v:=c "-" Format("{:06X}",v<<16|v<<8|v)
		, s:=RegExReplace("/" s, "/" c "-[^/]*") . "/" v
		_Gui["ColorList"].Value:=Trim(s, "/")
		ControlSend,, {End}, % "ahk_id " _Gui["ColorList"].Hwnd
		G_.Call("Color2Two")
		return
	Case "Undo2":
		_Gui:=graphicsearch_Capture
		s:=_Gui["ColorList"].Value
		s:=RegExReplace("/" s, "/[^/]+$")
		_Gui["ColorList"].Value:=Trim(s, "/")
		ControlSend,, {End}, % "ahk_id " _Gui["ColorList"].Hwnd
		return
	Case "Color2Two":
		_Gui:=graphicsearch_Capture
		color:=Trim(_Gui["ColorList"].Value, "/")
		if (color="")
		{
		_Gui.Opt("+OwnDialogs")
		MsgBox, 4096, Tip, % Lang["s16"] " !", 1
		return
		}
		ListLines % (lls:=A_ListLines)?0:0
		k:=i:=v:=0, arr:=StrSplit(color, "/")
		Loop % nW*nH
		{
		c:=cors[++k], rr:=(c>>16)&0xFF, gg:=(c>>8)&0xFF, bb:=c&0xFF
		For k1,v1 in arr
		{
			c:=this.ToRGB(StrSplit(StrReplace(v1,"@","-") "-","-")[1])
			, r:=((c>>16)&0xFF)-rr, g:=((c>>8)&0xFF)-gg, b:=(c&0xFF)-bb
			if j:=InStr(v1, "@")
			{
			n:=this.Floor(SubStr(v1,j+1))
			, n:=Floor(4606*255*255*(1-n)*(1-n)), j:=r+rr+rr
			if v:=((1024+j)*r*r+2048*g*g+(1534-j)*b*b<=n)
				Break
			}
			else
			{
			c:=this.Floor("0x" StrSplit(v1 "-","-")[2])
			, dR:=(c>>16)&0xFF, dG:=(c>>8)&0xFF, dB:=c&0xFF
			if v:=(Abs(r)<=dR && Abs(g)<=dG && Abs(b)<=dB)
				Break
			}
		}
		ascii[k]:=v, (show[k] && i:=(v?i+1:i-1))
		}
		bg:=(i>0 ? "1":"0"), G_.Call("BlackWhite")
		ListLines % lls
		return
	Case "ColorPos2Two":
		_Gui:=graphicsearch_Capture
		c:=_Gui["SelColor"].Value
		if (c="")
		{
		_Gui.Opt("+OwnDialogs")
		MsgBox, 4096, Tip, % Lang["s12"] " !", 1
		return
		}
		n:=this.Floor(_Gui["Similar2"].Value), n:=Round(n/100,2)
		, color:="#" c "@" n
		, n:=Floor(4606*255*255*(1-n)*(1-n)), k:=i:=0
		, rr:=(c>>16)&0xFF, gg:=(c>>8)&0xFF, bb:=c&0xFF
		ListLines % (lls:=A_ListLines)?0:0
		Loop % nW*nH
		c:=cors[++k], r:=((c>>16)&0xFF)-rr
		, g:=((c>>8)&0xFF)-gg, b:=(c&0xFF)-bb, j:=r+rr+rr
		, ascii[k]:=v:=((1024+j)*r*r+2048*g*g+(1534-j)*b*b<=n)
		, (show[k] && i:=(v?i+1:i-1))
		bg:=(i>0 ? "1":"0"), G_.Call("BlackWhite")
		ListLines % lls
		return
	Case "BlackWhite":
		Loop % 25 + 0*(ty:=dy-1)*(k:=0)
		Loop % 71 + 0*(tx:=dx-1)*(ty++)
		if (k++)*0 + (++tx)<nW && ty<nH && show[i:=ty*nW+tx+1]
		SendMessage,0x2001,0,(ascii[i] ? 0 : 0xFFFFFF),,% "ahk_id " C_[k]
		return
	Case "Modify":
		Modify:=graphicsearch_Capture["Modify"].Value
		return
	Case "MultiColor":
		MultiColor:=graphicsearch_Capture["MultiColor"].Value
		Result:=""
		ToolTip
		return
	Case "Undo":
		Result:=RegExReplace(Result, ",[^/]+/[^/]+/[^/]+$")
		ToolTip % Trim(Result,"/,")
		return
	Case "GetTxt":
		txt:=""
		if (bg="")
		return
		k:=0
		ListLines % (lls:=A_ListLines)?0:0
		Loop % nH
		{
		v:=""
		Loop % nW
			v.=!show[++k] ? "" : ascii[k] ? "1":"0"
		txt.=v="" ? "" : v "`n"
		}
		ListLines % lls
		return
	Case "Auto":
		G_.Call("GetTxt")
		if (txt="")
		{
		graphicsearch_Capture.Opt("+OwnDialogs")
		MsgBox, 4096, Tip, % Lang["s13"] " !", 1
		return
		}
		While InStr(txt,bg)
		{
		if (txt~="^" bg "+\n")
			txt:=RegExReplace(txt, "^" bg "+\n"), G_.Call("CutU")
		else if !(txt~="m`n)[^\n" bg "]$")
			txt:=RegExReplace(txt, "m`n)" bg "$"), G_.Call("CutR")
		else if (txt~="\n" bg "+\n$")
			txt:=RegExReplace(txt, "\n\K" bg "+\n$"), G_.Call("CutD")
		else if !(txt~="m`n)^[^\n" bg "]")
			txt:=RegExReplace(txt, "m`n)^" bg), G_.Call("CutL")
		else Break
		}
		txt:=""
		return
	Case "OK", "SplitAdd", "AllAdd":
		_Gui:=graphicsearch_Capture
		_Gui.Opt("+OwnDialogs")
		G_.Call("GetTxt")
		if (txt="") && (!MultiColor)
		{
		MsgBox, 4096, Tip, % Lang["s13"] " !", 1
		return
		}
		if InStr(color,"#") && (!MultiColor)
		{
		r:=StrSplit(color,"@","#")
		k:=i:=j:=0
		ListLines % (lls:=A_ListLines)?0:0
		Loop % nW*nH
		{
			if (!show[++k])
			Continue
			i++
			if (k=SelPos)
			{
			j:=i
			Break
			}
		}
		ListLines % lls
		if (j=0)
		{
			MsgBox, 4096, Tip, % Lang["s12"] " !", 1
			return
		}
		color:="#" j "@" r[2]
		}
		Comment:=_Gui["Comment"].Value
		if (cmd="SplitAdd") && (!MultiColor)
		{
		if InStr(color,"#")
		{
			MsgBox, 4096, Tip, % Lang["s14"], 3
			return
		}
		bg:=StrLen(StrReplace(txt,"0"))
			> StrLen(StrReplace(txt,"1")) ? "1":"0"
		s:="", i:=0, k:=nW*nH+1+CutLeft
		Loop % w:=nW-CutLeft-CutRight
		{
			i++
			if (!show[k++] && A_Index<w)
			Continue
			i:=Format("{:d}",i)
			v:=RegExReplace(txt,"m`n)^(.{" i "}).*","$1")
			txt:=RegExReplace(txt,"m`n)^.{" i "}"), i:=0
			While InStr(v,bg)
			{
			if (v~="^" bg "+\n")
				v:=RegExReplace(v,"^" bg "+\n")
			else if !(v~="m`n)[^\n" bg "]$")
				v:=RegExReplace(v,"m`n)" bg "$")
			else if (v~="\n" bg "+\n$")
				v:=RegExReplace(v,"\n\K" bg "+\n$")
			else if !(v~="m`n)^[^\n" bg "]")
				v:=RegExReplace(v,"m`n)^" bg)
			else Break
			}
			if (v!="")
			{
			v:=Format("{:d}",InStr(v,"`n")-1) "." this.bit2base64(v)
			s.="`nText.=""|<" SubStr(Comment,1,1) ">" color "$" v """`n"
			Comment:=SubStr(Comment, 2)
			}
		}
		Event:=cmd, Result:=s
		_Gui.Hide()
		return
		}
		if (!MultiColor)
		txt:=Format("{:d}",InStr(txt,"`n")-1) "." this.bit2base64(txt)
		else
		{
		n:=_Gui["dRGB"].Value
		color:=Format("##{:06X}", n<<16|n<<8|n)
		r:=StrSplit(Trim(StrReplace(Result, ",", "/"), "/"), "/")
		, x:=r[1], y:=r[2], s:="", i:=1
		SetFormat, IntegerFast, d
		Loop % r.Length()//3
			s.="," (r[i++]-x) "/" (r[i++]-y) "/" r[i++]
		txt:=SubStr(s,2)
		}
		s:="`nText.=""|<" Comment ">" color "$" txt """`n"
		if (cmd="AllAdd")
		{
		Event:=cmd, Result:=s
		_Gui.Hide()
		return
		}
		x:=nX+CutLeft+(nW-CutLeft-CutRight)//2
		y:=nY+CutUp+(nH-CutUp-CutDown)//2
		s:=StrReplace(s, "Text.=", "query := "), r:=StrSplit(Lang["s8"] "|||||||", "|")
		s:="`; #include %A_ScriptDir%\node_modules"
		. "`n; #include graphicsearch.ahk\export.ahk"
		. "`n" s
		. "`noGraphicSearch := new graphicsearch"
		. "`nresultObj := oGraphicSearch.search(query)`n`n"
		Event:=cmd, Result:=s
		_Gui.Hide()
		return
	Case "SavePic2":
		x:=nX+CutLeft, w:=nW-CutLeft-CutRight
		y:=nY+CutUp, h:=nH-CutUp-CutDown
		G_.Call("ScreenShot", x "|" y "|" (x+w-1) "|" (y+h-1) "|0")
		return
	Case "ShowPic":
		ControlGet, i, CurrentLine,,, ahk_id %hscr%
		ControlGet, s, Line, %i%,, ahk_id %hscr%
		graphicsearch_Main["MyPic"].Value:=Trim(this.ASCII(s),"`n")
		return
	Case "KeyDown":
		Critical
		_Gui:=graphicsearch_Main
		if (WinExist()!=_Gui.Hwnd)
		return
		Try ctrl:="", ctrl:=args[3]
		if (ctrl=hscr)
		SetTimer, %G_ShowPic%, -150
		else if (ctrl=_Gui["ClipText"].Hwnd)
		{
		s:=_Gui["ClipText"].Value
		_Gui["MyPic"].Value:=Trim(this.ASCII(s),"`n")
		}
		return
	Case "LButtonDown":
		Critical
		Try k1:="", k1:=GuiFromHwnd(args[3],1).Hwnd
		if (k1=graphicsearch_SubPic.Hwnd)
		{
		if (A_TickCount-oldt)<100 || !this.State("LButton")
			return
		CoordMode, Mouse
		MouseGetPos, k1, k2
		ListLines % (lls:=A_ListLines)?0:0
		Loop
		{
			Sleep 50
			MouseGetPos, k3, k4
			this.RangeTip(Min(k1,k3), Min(k2,k4)
			, Abs(k1-k3)+1, Abs(k2-k4)+1, (A_MSec<500 ? "Red":"Blue"))
		}
		Until !this.State("LButton")
		ListLines % lls
		this.RangeTip()
		this.GetBitsFromScreen(,,,,0,zx,zy)
		this.ClientToScreen(sx, sy, 0, 0, sub_hpic)
		if Abs(k1-k3)+Abs(k2-k4)>4
			sx:=zx+Min(k1,k3)-sx, sy:=zy+Min(k2,k4)-sy
			, sw:=Abs(k1-k3)+1, sh:=Abs(k2-k4)+1
		else
			sx:=zx+k1-sx-71//2, sy:=zy+k2-sy-25//2, sw:=71, sh:=25
		G_.Call("CaptureUpdate")
		graphicsearch_Capture["MyTab1"].Choose(1)
		oldt:=A_TickCount
		return
		}
		else if (k1!=graphicsearch_Capture.Hwnd)
		return G_.Call("KeyDown", arg1, args*)
		MouseGetPos,,,, k2, 2
		k1:=0
		ListLines % (lls:=A_ListLines)?0:0
		For k_,v_ in C_
		if (v_=k2) && (k1:=k_)
			Break
		ListLines % lls
		if (k1<1)
		return
		else if (k1>71*25)
		{
		k3:=nW*nH+dx+(k1-71*25)
		SendMessage,0x2001,0,((show[k3]:=!show[k3])?0x0000FF:0xAAFFFF),,% "ahk_id " k2
		return
		}
		k3:=Mod(k1-1,71)+dx, k4:=(k1-1)//71+dy
		if (k3>=nW || k4>=nH)
		return
		k1:=k, k:=k4*nW+k3+1, k5:=c
		if (MultiColor && show[k])
		{
		c:="," (nX+k3) "/" (nY+k4) "/" Format("{:06X}",cors[k]&0xFFFFFF)
		, Result.=InStr(Result,c) ? "":c
		ToolTip % Trim(Result,"/,")
		}
		if (Modify && bg!="" && show[k])
		{
		c:=((ascii[k]:=!ascii[k]) ? 0 : 0xFFFFFF)
		SendMessage,0x2001,0,c,,% "ahk_id " k2
		}
		else
		{
		c:=cors[k], SelPos:=k
		_Gui:=graphicsearch_Capture
		_Gui["SelGray"].Value:=(((c>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
		_Gui["SelColor"].Value:=Format("0x{:06X}",c&0xFFFFFF)
		_Gui["SelR"].Value:=(c>>16)&0xFF
		_Gui["SelG"].Value:=(c>>8)&0xFF
		_Gui["SelB"].Value:=c&0xFF
		}
		k:=k1, c:=k5
		return
	Case "RButtonDown":
		Critical
		Try k1:="", k1:=GuiFromHwnd(args[3],1).Hwnd
		if (k1!=graphicsearch_SubPic.Hwnd)
		return
		if (A_TickCount-oldt)<100 || !this.State("RButton")
		return
		r:=[x, y, w, h, pX, pY, pW, pH]
		CoordMode, Mouse
		MouseGetPos, k1, k2
		WinGetPos, x, y, w, h, ahk_id %parent_id%
		WinGetPos, pX, pY, pW, pH, ahk_id %sub_hpic%
		pX-=x, pY-=y, pW-=w, pH-=h
		ListLines % (lls:=A_ListLines)?0:0
		Loop
		{
		Sleep 10
		MouseGetPos, k3, k4
		x:=Min(Max(pX+k3-k1,-pW),0), y:=Min(Max(pY+k4-k2,-pH),0)
		graphicsearch_SubPic.Show("NA x" x " y" y)
		graphicsearch_Capture["MySlider3"].Value:=Round(-x/pW*100)
		graphicsearch_Capture["MySlider4"].Value:=Round(-y/pH*100)
		}
		Until !this.State("RButton")
		ListLines % lls
		x:=r[1], y:=r[2], w:=r[3], h:=r[4], pX:=r[5], pY:=r[6], pW:=r[7], pH:=r[8]
		oldt:=A_TickCount
		return
	Case "MouseMove":
		Try ctrl_name:="", ctrl_name:=GuiCtrlFromHwnd(args[3]).Name
		if (PrevControl != ctrl_name)
		{
		ToolTip
		PrevControl:=ctrl_name
		if (G_ToolTip)
		{
			SetTimer, %G_ToolTip%, % PrevControl ? -500 : "Off"
			SetTimer, %G_ToolTipOff%, % PrevControl ? -5500 : "Off"
		}
		}
		return
	Case "ToolTip":
		MouseGetPos,,, _TT
		if WinExist("ahk_id " _TT " ahk_class AutoHotkeyGUI")
		ToolTip % Tip_Text[PrevControl]
		return
	Case "ToolTipOff":
		ToolTip
		return
	Case "CutL2", "CutR2", "CutU2", "CutD2":
		s:=graphicsearch_Main["MyPic"].Value
		s:=Trim(s,"`n") . "`n", v:=SubStr(cmd,4,1)
		if (v="U")
		s:=RegExReplace(s,"^[^\n]+\n")
		else if (v="D")
		s:=RegExReplace(s,"[^\n]+\n$")
		else if (v="L")
		s:=RegExReplace(s,"m`n)^[^\n]")
		else if (v="R")
		s:=RegExReplace(s,"m`n)[^\n]$")
		graphicsearch_Main["MyPic"].Value:=Trim(s,"`n")
		return
	Case "Update":
		ControlFocus,, % "ahk_id " hscr
		ControlGet, i, CurrentLine,,, ahk_id %hscr%
		ControlGet, s, Line, %i%,, ahk_id %hscr%
		if !RegExMatch(s, "O)(<[^>\n]*>[^$\n]+\$)\d+\.[\w+/]+", r)
		return
		v:=graphicsearch_Main["MyPic"].Value
		v:=Trim(v,"`n") . "`n", w:=Format("{:d}",InStr(v,"`n")-1)
		v:=StrReplace(StrReplace(v,"0","1"),"_","0")
		s:=StrReplace(s, r[0], r[1] . w "." this.bit2base64(v))
		v:="{End}{Shift Down}{Home}{Shift Up}{Del}"
		ControlSend,, %v%, ahk_id %hscr%
		Control, EditPaste, %s%,, ahk_id %hscr%
		ControlSend,, {Home}, ahk_id %hscr%
		return
	}
	}

	Lang(text:="", getLang:=0)
	{
	local
	static init, Lang1, Lang2
	if !VarSetCapacity(init) && (init:="1")
	{
		s:="
		(
	Myww       = Width = Adjust the width of the capture range
	Myhh       = Height = Adjust the height of the capture range
	AddFunc    = Add = Additional graphicsearch() in Copy
	NowHotkey  = Hotkey = Current screenshot hotkey
	SetHotkey1 = = First sequence Screenshot hotkey
	SetHotkey2 = = Second sequence Screenshot hotkey
	Apply      = Apply = Apply new screenshot hotkey
	CutU2      = CutU = Cut the Upper Edge of the text in the edit box below
	CutL2      = CutL = Cut the Left Edge of the text in the edit box below
	CutR2      = CutR = Cut the Right Edge of the text in the edit box below
	CutD2      = CutD = Cut the Lower Edge of the text in the edit box below
	Update     = Update = Update the text in the edit box below to the line of Code
	GetRange   = GetRange = Get screen range to Clipboard and update the search range of the Code
	GetOffset  = GetOffset = Get position offset relative to the Text from the Code and update graphicsearch().Click()
	GetClipOffset  = GetOffset2 = Get position offset relative to the Text from the Left Box
	Capture    = Capture = Initiate Image Capture Sequence
	CaptureS   = CaptureS = Restore the Saved ScreenShot by Hotkey and then start capturing
	Test       = Test = Test the Text from the Code to see if it can be found on the screen
	TestClip   = Test2 = Test the Text from the Left Box and copy the result to Clipboard
	Paste      = Paste = Paste the Text from Clipboard to the Left Box
	CopyOffset = Copy2 = Copy the Offset to Clipboard
	Copy       = Copy = Copy the selected or all of the code to the clipboard
	Reset      = Reset = Reset to Original Captured Image
	SplitAdd   = SplitAdd = Using Markup Segmentation to Generate Text Library
	AllAdd     = AllAdd = Append Another graphicsearch Search Text into Previously Generated Code
	Gray2Two      = Gray2Two = Converts Image Pixels from Gray Threshold to Black or White
	GrayDiff2Two  = GrayDiff2Two = Converts Image Pixels from Gray Difference to Black or White
	Color2Two     = Color2Two = Converts Image Pixels from Color List to Black or White
	ColorPos2Two  = ColorPos2Two = Converts Image Pixels from Color Position to Black or White
	SelGray    = Gray = Gray value of the selected color
	SelColor   = Color = The selected color
	SelR       = R = Red component of the selected color
	SelG       = G = Green component of the selected color
	SelB       = B = Blue component of the selected color
	RepU       = -U = Undo Cut the Upper Edge by 1
	CutU       = U = Cut the Upper Edge by 1
	CutU3      = U3 = Cut the Upper Edge by 3
	RepL       = -L = Undo Cut the Left Edge by 1
	CutL       = L = Cut the Left Edge by 1
	CutL3      = L3 = Cut the Left Edge by 3
	Auto       = Auto = Automatic Cut Edge after image has been converted to black and white
	RepR       = -R = Undo Cut the Right Edge by 1
	CutR       = R = Cut the Right Edge by 1
	CutR3      = R3 = Cut the Right Edge by 3
	RepD       = -D = Undo Cut the Lower Edge by 1
	CutD       = D = Cut the Lower Edge by 1
	CutD3      = D3 = Cut the Lower Edge by 3
	Modify     = Modify = Allows Modify the Black and White Image
	MultiColor = FindMultiColor = Click multiple colors with the mouse, then Click OK button
	Undo       = Undo = Undo the last selected color
	Undo2      = Undo = Undo the last added color in Color List
	Comment    = Comment = Optional Comment used to Label Code ( Within <> )
	Threshold  = Gray Threshold = Gray Threshold which Determines Black or White Pixel Conversion (0-255)
	GrayDiff   = Gray Difference = Gray Difference which Determines Black or White Pixel Conversion (0-255)
	Similar1   = Similarity = Adjust color similarity as Equivalent to The Selected Color
	Similar2   = Similarity = Adjust color similarity as Equivalent to The Selected Color
	AddColorSim  = AddList = Add Color to Color List and Run Color2Two
	AddColorDiff = AddList = Add Color to Color List and Run Color2Two
	ColorList  = = Color list for converting black and white images
	DiffRGB    = R/G/B = Determine the allowed R/G/B Error (0-255) when Find MultiColor
	DiffRGB2   = R/G/B = Determine the allowed R/G/B Error (0-255)
	Bind0      = BindWin1 = Bind the window and Use GetDCEx() to get the image of background window
	Bind1      = BindWin1+ = Bind the window Use GetDCEx() and Modify the window to support transparency
	Bind2      = BindWin2 = Bind the window and Use PrintWindow() to get the image of background window
	Bind3      = BindWin2+ = Bind the window Use PrintWindow() and Modify the window to support transparency
	Bind4      = BindWin3 = Bind the window and Use PrintWindow(,,3) to get the image of background window
	OK         = OK = Create New graphicsearch Code for Testing
	OK2        = OK = Restore this ScreenShot then Capturing
	Cancel     = Cancel = Close the Window Don't Do Anything
	Cancel2    = Cancel = Close the Window Don't Do Anything
	ClearAll   = ClearAll = Clean up all saved ScreenShots
	OpenDir    = OpenDir = Open the saved screenshots directory
	SavePic    = SavePic = Select a range and save as a picture
	SavePic2   = SavePic = Save the trimmed original image as a picture
	LoadPic    = LoadPic = Load a picture as Capture image
	ClipText   = = Displays the Text data from clipboard
	Offset     = = Displays the results of GetOffset2 or GetRange
	SelectBox  = = Select a screenshot to display in the upper left corner of the screen
	s1  = graphicsearch
	s2  = Gray|GrayDiff|Color|ColorPos|MultiColor
	s3  = Capture Image To Text
	s4  = Capture Image To Text and Find Text Tool
	s5  = Direction keys to fine tune\nFirst click RButton(or Ctrl)\nMove the mouse away\nSecond click RButton(or Ctrl)
	s6  = Unbind Window using
	s7  = Drag a range with LButton(or Ctrl)\nCoordinates are copied to clipboard
	s8  = Found|Time|ms|Pos|Result|value can be get from|Wait 3 seconds for appear|Wait indefinitely for disappear
	s9  = Success
	s10 = The Capture Position|Perspective binding window\nRight click to finish capture
	s11 = Please Set Gray Difference First
	s12 = Please select the core color first
	s13 = Please convert the image to black or white first
	s14 = Can't be used in ColorPos mode, because it can cause position errors
	s15 = Are you sure about the scope of your choice?\n\nIf not, you can choose again
	s16 = Please add colors to the color list first
	s17 = Please Save Picture First
	s18 = Capture|ScreenShot
		)"
	Lang1:=[], Lang2:=[]
	Loop Parse, s, `n, `r
		if InStr(v:=A_LoopField, "=")
			r:=StrSplit(StrReplace(v "==","\n","`n"), "=", "`t ")
				, Lang1[r[1]]:=r[2], Lang2[r[1]]:=r[3]
}
return getLang=1 ? Lang1 : getLang=2 ? Lang2 : Lang1[text]
}
}
; Gui-V1-V2 Compatibility Library  By FeiYue
;---------------------------------

Gui(args*) {
	return new GuiCreate(args*)
}

GuiFromHwnd(hwnd:="AllGuiObj", RecurseParent:=0) {
	static init, AllGuiObj
	if !VarSetCapacity(init) && (init:="1")
		AllGuiObj:=[]
	if (hwnd=="AllGuiObj")
		return AllGuiObj
	if (RecurseParent)
		While hwnd && !AllGuiObj.HasKey(hwnd)
			hwnd:=DllCall("GetParent", "Ptr",hwnd, "Ptr")
	return AllGuiObj[hwnd]
}

GuiCtrlFromHwnd(hwnd) {
	return GuiFromHwnd(hwnd,1)[hwnd]
}

GuiCreate_Close(args*) {
	return GuiCreate_G("Close", args*)
}

GuiCreate_ContextMenu(args*) {
	return GuiCreate_G("ContextMenu", args*)
}

GuiCreate_DropFiles(args*) {
	return GuiCreate_G("DropFiles", args*)
}

GuiCreate_Escape(args*) {
	return GuiCreate_G("Escape", args*)
}

GuiCreate_Size(args*) {
	return GuiCreate_G("Size", args*)
}

GuiCreate_G(EventName, args*) {
	local
	return (G:=GuiFromHwnd(WinExist()))["_" EventName].Call(G, args*)
}

Class GuiCreate {

	__New(opts:="", title:="", args*) {
		local
		Gui, New, % opts " +Hwndhwnd +LabelGuiCreate_", % title
		this.Hwnd:=hwnd, this.ClassNN:=[]
		GuiFromHwnd()[hwnd]:=this
	}

	__Delete() {
		this.Destroy()
	}

	Destroy() {
		local
		if !(hwnd:=this.Hwnd)
			return
		this.Hwnd:="", GuiFromHwnd().Delete(hwnd)
		Try Gui, % hwnd ":Destroy"
		For k,v in this
		(v.Hwnd && v.Hwnd:=""), this[k]:=""
	}

	OnEvent(EventName, Callback, AddRemove:=1) {
		if IsObject(Callback)
		this["_" EventName]:=Callback
	}

	Opt(opts) {
		Gui, % this.Hwnd ":" RegExReplace(opts,"i)[+\-\s]Label\S*")
	}

	Add(type, opts:="", text:="") {
		local
		static init, type2class
		if !VarSetCapacity(init) && (init:="1")
		type2class:=[]
		type:=(type="DropDownList"?"DDL":type="Picture"?"Pic":type)
		name:=RegExMatch(opts, "i)(^|[+\-\s])V(?!Scroll\b|ertical\b)\K\S*", r)?r:""
		opts:=RegExReplace(opts, "i)(^|[+\-\s])V(?!Scroll\b|ertical\b)\S*")
		if IsObject(text)
		{
		s:=""
		For k,v in text
			s.="|" v
		text:=Trim(s, "|")
		}
		Gui, % this.Hwnd ":Add", % type, % opts " +Hwndhwnd", % text
		this.LastHwnd:=hwnd
		if type2class.HasKey(type)
		s:=type2class[type]
		else
		{
		WinGetClass, s, ahk_id %hwnd%
		type2class[type]:=s
		}
		this.ClassNN[s]:=n:=Floor(this.ClassNN[s])+1, classnn:=s . n
		obj:= new this.Control(this.Hwnd, hwnd, type, classnn, name)
		this[hwnd]:=obj, this[classnn]:=obj
		if (name) && !(name~="i)^(Destroy|OnEvent|Opt|Add"
		. "|SetFont|Show|Hide|Move|GetClientPos|GetPos|Maximize"
		. "|Minimize|Restore|Flash|Submit|Hwnd|Name|Title"
		. "|BackColor|MarginX|MarginY|MenuBar|FocusedCtrl)$")
		this[name]:=obj
		return obj
	}

	SetFont(opts:="", FontName:="") {
		Gui, % this.Hwnd ":Font", % opts, % FontName
	}

	Show(opts:="", args*) {
		Gui, % this.Hwnd ":Show", % opts
	}

	Hide() {
		Gui, % this.Hwnd ":Hide"
	}

	Move(x:="", y:="", w:="", h:="") {
		local
		this.GetPos(pX, pY, pW, pH)
		x:=(x=""?pX:x), y:=(y=""?pY:y), w:=(w=""?pW:w), h:=(h=""?pH:h)
		DllCall("MoveWindow", "Ptr",this.Hwnd, "int",x, "int",y, "int",w, "int",h, "int",1)
	}

	GetClientPos(ByRef x:="", ByRef y:="", ByRef w:="", ByRef h:="") {
		local
		VarSetCapacity(rect, 16, 0)
		, DllCall("GetClientRect",  "Ptr",this.Hwnd, "Ptr",&rect)
		, DllCall("ClientToScreen", "Ptr",this.Hwnd, "Ptr",&rect)
		, x:=NumGet(rect, 0, "int"), y:=NumGet(rect, 4, "int")
		, w:=NumGet(rect, 8, "int")-x, h:=NumGet(rect, 12, "int")-y
	}

	GetPos(ByRef x:="", ByRef y:="", ByRef w:="", ByRef h:="") {
		local
		VarSetCapacity(rect, 16, 0)
		, DllCall("GetWindowRect",  "Ptr",this.Hwnd, "Ptr",&rect)
		, x:=NumGet(rect, 0, "int"), y:=NumGet(rect, 4, "int")
		, w:=NumGet(rect, 8, "int")-x, h:=NumGet(rect, 12, "int")-y
	}

	Maximize() {
		Gui, % this.Hwnd ":Maximize"
	}

	Minimize() {
		Gui, % this.Hwnd ":Minimize"
	}

	Restore() {
		Gui, % this.Hwnd ":Restore"
	}

	Flash(k:=1) {
		Gui, % this.Hwnd ":Flash", % k ? "":"Off"
	}

	Submit(hide:=1) {
		local
		(hide && this.Hide()), arr:=[]
		For k,v in this
		if k is number
			if (v.Name!="")
			arr[v.Name]:=v.Value
		return arr
	}

	BackColor {
		get {
		return this._BackColor
		}
		set {
		this._BackColor:=value
		Gui, % this.Hwnd ":Color", % value
		return value
		}
	}

	MarginX {
		get {
		return this._MarginX
		}
		set {
		this._MarginX:=value
		Gui, % this.Hwnd ":Margin", % value
		return value
		}
	}

	MarginY {
		get {
		return this._MarginY
		}
		set {
		this._MarginY:=value
		Gui, % this.Hwnd ":Margin",, % value
		return value
		}
	}

	MenuBar {
		get {
		return this._MenuBar
		}
		set {
		this._MenuBar:=value
		Gui, % this.Hwnd ":Menu", % value
		return value
		}
	}

	Title {
		get {
		local
		VarSetCapacity(v, 260*2)
		DllCall("GetWindowText", "Ptr",this.Hwnd, "Str",v, "Int",260)
		return v
		}
		set {
		DllCall("SetWindowText", "Ptr",this.Hwnd, "Str",value)
		return value
		}
	}

	FocusedCtrl {
		get {
		local
		GuiControlGet, v, % this.Hwnd ":Focus"
		return this[v]
		}
	}

	Class Control {

		__New(GuiHwnd, hwnd, type, classnn, name) {
			this.GuiHwnd:=GuiHwnd, this.Hwnd:=hwnd
			this.Type:=type, this.ClassNN:=classnn, this.Name:=name
		}

		Opt(opts) {
			GuiControl, % opts, % this.Hwnd
		}

		OnEvent(EventName, Callback, AddRemove:=1) {
			local
			r:=this.OnEvent_G.Bind(this, Callback)
			GuiControl, +g, % this.Hwnd, % r
		}

		OnEvent_G(Callback, args*) {
			if IsObject(Callback)
			return %Callback%(this, args*)
		}

		GetPos(ByRef x:="", ByRef y:="", ByRef w:="", ByRef h:="") {
			local
			GuiControlGet, p, Pos, % this.Hwnd
			x:=Floor(pX), y:=Floor(pY), w:=Floor(pW), h:=Floor(pH)
		}

		Move(x:="", y:="", w:="", h:="") {
			local
			s:=(x=""?"":" x" x) (y=""?"":" y" y) (w=""?"":" w" w) (h=""?"":" h" h)
			GuiControl, Move, % this.Hwnd, % s
		}

		Redraw() {
			GuiControl, MoveDraw, % this.Hwnd
		}

		Focus() {
			GuiControl, Focus, % this.Hwnd
		}

		UseTab(Name:="", Exact:="", index:="") {
			Gui, % this.GuiHwnd ":Tab", % Name, % index, % Exact?"Exact":""
		}

		SetFont(opts:="", FontName:="") {
			Gui, % this.GuiHwnd ":Font", % opts, % FontName
			GuiControl, Font, % this.Hwnd
		}

		Add(text) {
			local
			if IsObject(text)
			{
			s:=""
			For k,v in text
				s.="|" v
			text:=Trim(s, "|")
			}
			GuiControl,, % this.Hwnd, % text
		}

		Delete(N:="") {
			if (N="")
			GuiControl,, % this.Hwnd, |
			else
			this.Choose(N), this.Choose(0)
		}

		Choose(N) {
			if N is number
			GuiControl, Choose, % this.Hwnd, % N
			else
			GuiControl, ChooseString, % this.Hwnd, % N
		}

		Gui {
			get {
			return GuiFromHwnd(this.GuiHwnd)
			}
		}

		Enabled {
			get {
			local
			GuiControlGet, v, Enabled, % this.Hwnd
			return v
			}
			set {
			GuiControl, % "Enable" (!!value), % this.Hwnd
			return value
			}
		}

		Visible {
			get {
			local
			GuiControlGet, v, Visible, % this.Hwnd
			return v
			}
			set {
			GuiControl, % "Show" (!!value), % this.Hwnd
			return value
			}
		}

		Focused {
			get {
			local
			GuiControlGet, v, % this.GuiHwnd ":Focus"
			return (v=this.ClassNN)
			}
		}

		Value {
			get {
			local
			if (this.Type~="i)^(ListBox|DDL|ComboBox|Tab)$")
				this.Opt("+AltSubmit")
			GuiControlGet, v,, % this.Hwnd
			return v
			}
			set {
			if (this.Type~="i)^(ListBox|DDL|ComboBox|Tab)$")
				GuiControl, Choose, % this.Hwnd, % value
			else
				GuiControl,, % this.Hwnd, % value
			return value
			}
		}

		Text {
			get {
			local
			if (this.Type~="i)^(ListBox|DDL|ComboBox|Tab)$")
				this.Opt("-AltSubmit")
			GuiControlGet, v,, % this.Hwnd
			return v
			}
			set {
			if (this.Type~="i)^(ListBox|DDL|ComboBox|Tab)$")
				GuiControl, ChooseString, % this.Hwnd, % value
			else
				GuiControl,, % this.Hwnd, % value
			return value
			}
		}
	}
}
