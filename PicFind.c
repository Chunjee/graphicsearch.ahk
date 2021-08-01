int __attribute__((__stdcall__)) PicFind(
		int mode, unsigned int c, unsigned int n, int dir
		, unsigned char * Bmp, int Stride, int zw, int zh
		, int sx, int sy, int sw, int sh
		, char * ss, unsigned int * s1, unsigned int * s0
		, char * text, int w, int h, int err1, int err0
		, unsigned int * allpos, int allpos_max )
	{
		int ok=0, o, i, j, k, v, r, g, b, rr, gg, bb;
		int x, y, x1, y1, x2, y2, len1, len0, e1, e0, max;
		int r_min, r_max, g_min, g_max, b_min, b_max, x3, y3;
		unsigned char * gs;
		//----------------------
		// MultiColor or PixelSearch or ImageSearch Mode
		if (mode==5)
		{
		max=n; v=c*c;
		for (i=0, k=0, c=0, o=0; (j=text[o++])!='\0';)
		{
			if (j>='0' && j<='9') c=c*10+(j-'0');
			if (j=='/' || text[o]=='\0')
			{
			if (k=!k)
				s1[i]=(c>>16)*Stride+(c&0xFFFF)*4;
			else
				s0[i++]=c;
			c=0;
			}
		}
		goto StartLookUp;
		}
		//----------------------
		// Generate Lookup Table
		o=0; len1=0; len0=0;
		for (y=0; y<h; y++)
		{
		for (x=0; x<w; x++)
		{
			i=(mode==3) ? y*Stride+x*4 : y*sw+x;
			if (text[o++]=='1')
			s1[len1++]=i;
			else
			s0[len0++]=i;
		}
		}
		if (err1>=len1) len1=0;
		if (err0>=len0) len0=0;
		max=(len1>len0) ? len1 : len0;
		//----------------------
		// Color Position Mode
		// only used to recognize multicolored Verification Code
		if (mode==3) goto StartLookUp;
		//----------------------
		// Generate Two Value Image
		o=sy*Stride+sx*4; j=Stride-sw*4; i=0;
		if (mode==0)	// Color Mode
		{
		rr=(c>>16)&0xFF; gg=(c>>8)&0xFF; bb=c&0xFF;
		for (y=0; y<sh; y++, o+=j)
			for (x=0; x<sw; x++, o+=4, i++)
			{
			r=Bmp[2+o]-rr; g=Bmp[1+o]-gg; b=Bmp[o]-bb; v=r+rr+rr;
			ss[i]=((1024+v)*r*r+2048*g*g+(1534-v)*b*b<=n) ? 1:0;
			}
		}
		else if (mode==1)	// Gray Threshold Mode
		{
		c=(c+1)<<7;
		for (y=0; y<sh; y++, o+=j)
			for (x=0; x<sw; x++, o+=4, i++)
			ss[i]=(Bmp[2+o]*38+Bmp[1+o]*75+Bmp[o]*15<c) ? 1:0;
		}
		else if (mode==2)	// Gray Difference Mode
		{
		gs=(unsigned char *)(ss+sw*sh);
		x2=sx+sw; y2=sy+sh;
		for (y=sy-1; y<=y2; y++)
		{
			for (x=sx-1; x<=x2; x++, i++)
			if (x<0 || x>=zw || y<0 || y>=zh)
				gs[i]=0;
			else
			{
				o=y*Stride+x*4;
				gs[i]=(Bmp[2+o]*38+Bmp[1+o]*75+Bmp[o]*15)>>7;
			}
		}
		k=sw+2; i=0;
		for (y=1; y<=sh; y++)
			for (x=1; x<=sw; x++, i++)
			{
			o=y*k+x; n=gs[o]+c;
			ss[i]=(gs[o-1]>n || gs[o+1]>n
				|| gs[o-k]>n	 || gs[o+k]>n
				|| gs[o-k-1]>n || gs[o-k+1]>n
				|| gs[o+k-1]>n || gs[o+k+1]>n) ? 1:0;
			}
		}
		else	// (mode==4) Color Difference Mode
		{
		r=(c>>16)&0xFF; g=(c>>8)&0xFF; b=c&0xFF;
		rr=(n>>16)&0xFF; gg=(n>>8)&0xFF; bb=n&0xFF;
		r_min=r-rr; g_min=g-gg; b_min=b-bb;
		r_max=r+rr; g_max=g+gg; b_max=b+bb;
		for (y=0; y<sh; y++, o+=j)
			for (x=0; x<sw; x++, o+=4, i++)
			{
			r=Bmp[2+o]; g=Bmp[1+o]; b=Bmp[o];
			ss[i]=(r>=r_min && r<=r_max
				&& g>=g_min && g<=g_max
				&& b>=b_min && b<=b_max) ? 1:0;
			}
		}
		//----------------------
		StartLookUp:
		if (mode==5 || mode==3)
		{ x1=sx; y1=sy; x2=sx+sw-w; y2=sy+sh-h; sx=0; sy=0; }
		else
		{ x1=0; y1=0; x2=sw-w; y2=sh-h; }
		if (dir<1 || dir>8) dir=1;
		// 1 ==> Top to Bottom ( Left to Right )
		// 2 ==> Top to Bottom ( Right to Left )
		// 3 ==> Bottom to Top ( Left to Right )
		// 4 ==> Bottom to Top ( Right to Left )
		// 5 ==> Left to Right ( Top to Bottom )
		// 6 ==> Left to Right ( Bottom to Top )
		// 7 ==> Right to Left ( Top to Bottom )
		// 8 ==> Right to Left ( Bottom to Top )
		if (--dir>3) { i=y1; y1=x1; x1=i; i=y2; y2=x2; x2=i; }
		for (y3=y1; y3<=y2; y3++)
		{
		for (x3=x1; x3<=x2; x3++)
		{
			y=((dir&3)>1) ? y1+y2-y3 : y3;
			x=(dir&1) ? x1+x2-x3 : x3;
			if (dir>3) { i=y; y=x; x=i; }
			//----------------------
			e1=err1; e0=err0;
			if (mode==5)
			{
			o=y*Stride+x*4;
			for (i=0; i<max; i++)
			{
				j=o+s1[i]; c=s0[i]; r=Bmp[2+j]-((c>>16)&0xFF);
				g=Bmp[1+j]-((c>>8)&0xFF); b=Bmp[j]-(c&0xFF);
				if ((r*r>v || g*g>v || b*b>v) && (--e1)<0)
				goto NoMatch;
			}
			}
			else if (mode==3)
			{
			o=y*Stride+x*4;
			j=o+c; rr=Bmp[2+j]; gg=Bmp[1+j]; bb=Bmp[j];
			for (i=0; i<max; i++)
			{
				if (i<len1)
				{
				j=o+s1[i]; r=Bmp[2+j]-rr; g=Bmp[1+j]-gg; b=Bmp[j]-bb; v=r+rr+rr;
				if ((1024+v)*r*r+2048*g*g+(1534-v)*b*b>n && (--e1)<0)
					goto NoMatch;
				}
				if (i<len0)
				{
				j=o+s0[i]; r=Bmp[2+j]-rr; g=Bmp[1+j]-gg; b=Bmp[j]-bb; v=r+rr+rr;
				if ((1024+v)*r*r+2048*g*g+(1534-v)*b*b<=n && (--e0)<0)
					goto NoMatch;
				}
			}
			}
			else
			{
			o=y*sw+x;
			for (i=0; i<max; i++)
			{
				if (i<len1 && ss[o+s1[i]]==0 && (--e1)<0) goto NoMatch;
				if (i<len0 && ss[o+s0[i]]!=0 && (--e0)<0) goto NoMatch;
			}
			// Clear the image that has been found
			for (i=0; i<len1; i++)
				ss[o+s1[i]]=0;
			}
			allpos[ok*2]=sx+x; allpos[ok*2+1]=sy+y;
			if (++ok>=allpos_max) goto Return1;
			NoMatch:;
		}
		}
		//----------------------
		Return1:
		return ok;
	}