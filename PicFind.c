int __attribute__((__stdcall__)) PicFind(
  int mode, unsigned int c, unsigned int n
  , int offsetX, int offsetY, unsigned char * Bmp
  , int Stride, int sx, int sy, int sw, int sh
  , unsigned char * gs, char * ss, char * text
  , int * s1, int * s0, int * input, int num
  , unsigned int * allpos, int allpos_max)
{
  int o, i, j, x, y, r, g, b, rr, gg, bb, max, e1, e0, ok;
  int o1, x1, y1, w1, h1, sx1, sy1, len1, len0, err1, err0;
  int o2, x2, y2, w2, h2, sx2, sy2, len21, len20, err21, err20;
  int r_min, r_max, g_min, g_max, b_min, b_max;
  //----------------------
  ok=0; w1=input[1]; h1=input[2];
  len1=input[3]; len0=input[4];
  err1=input[5]; err0=input[6];
  max=len1>len0 ? len1 : len0;
  //----------------------
  // Generate Lookup Table
  for (j=0; j<num; j+=7)
  {
    o=o1=o2=input[j]; w2=input[j+1]; h2=input[j+2];
    for (y=0; y<h2; y++)
    {
      for (x=0; x<w2; x++)
      {
        i=(mode==3) ? y*Stride+x*4 : y*sw+x;
        if (text[o++]=='1')
          s1[o1++]=i;
        else
          s0[o2++]=i;
      }
    }
  }
  // Color Position Mode
  // This mode is not support combination lookup
  // only used to recognize multicolored Verification Code
  if (mode==3)
  {
    c=(c/w1)*Stride+(c%w1)*4;
    sx1=sx+sw-w1; sy1=sy+sh-h1;
    for (y=sy; y<=sy1; y++)
    {
      for (x=sx; x<=sx1; x++)
      {
        o=y*Stride+x*4; e1=err1; e0=err0;
        j=o+c; rr=Bmp[2+j]; gg=Bmp[1+j]; bb=Bmp[j];
        for (i=0; i<max; i++)
        {
          if (i<len1)
          {
            j=o+s1[i]; r=Bmp[2+j]-rr; g=Bmp[1+j]-gg; b=Bmp[j]-bb;
            if (3*r*r+4*g*g+2*b*b>n && (--e1)<0)
              goto NoMatch3;
          }
          if (i<len0)
          {
            j=o+s0[i]; r=Bmp[2+j]-rr; g=Bmp[1+j]-gg; b=Bmp[j]-bb;
            if (3*r*r+4*g*g+2*b*b<=n && (--e0)<0)
              goto NoMatch3;
          }
        }
        allpos[ok++]=y<<16|x;
        if (ok>=allpos_max)
          goto Return1;
        NoMatch3:
        continue;
      }
    }
    goto Return1;
  }
  // Generate Two Value Image
  o=sy*Stride+sx*4; j=Stride-4*sw; i=0;
  if (mode==0)  // Color Mode
  {
    rr=(c>>16)&0xFF; gg=(c>>8)&0xFF; bb=c&0xFF;
    for (y=0; y<sh; y++, o+=j)
      for (x=0; x<sw; x++, o+=4, i++)
      {
        r=Bmp[2+o]-rr; g=Bmp[1+o]-gg; b=Bmp[o]-bb;
        ss[i]=(3*r*r+4*g*g+2*b*b<=n) ? 1:0;
      }
  }
  else if (mode==1)  // Gray Threshold Mode
  {
    c=(c+1)*128;
    for (y=0; y<sh; y++, o+=j)
      for (x=0; x<sw; x++, o+=4, i++)
        ss[i]=(Bmp[2+o]*38+Bmp[1+o]*75+Bmp[o]*15<c) ? 1:0;
  }
  else if (mode==2)  // Gray Difference Mode
  {
    for (y=0; y<sh; y++, o+=j)
    {
      for (x=0; x<sw; x++, o+=4, i++)
      {
        gs[i]=(Bmp[2+o]*38+Bmp[1+o]*75+Bmp[o]*15)>>7;
        ss[i]=0;
      }
    }
    sx1=sw-2; sy1=sh-2;
    for (y=1; y<=sy1; y++)
      for (x=1; x<=sx1; x++)
      {
        i=y*sw+x; j=gs[i]+c;
        if ( gs[i-1]>j || gs[i+1]>j
          || gs[i-sw]>j || gs[i+sw]>j
          || gs[i-sw-1]>j || gs[i-sw+1]>j
          || gs[i+sw-1]>j || gs[i+sw+1]>j )
            ss[i]=1;
      }
  }
  else // (mode==4) Color Difference Mode
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
  // Start Lookup
  sx1=sw-w1; sy1=sh-h1;
  for (y=0; y<=sy1; y++)
  {
    for (x=0; x<=sx1; x++)
    {
      o=y*sw+x; e1=err1; e0=err0;
      if (e0==len0)
      {
        for (i=0; i<len1; i++)
          if (ss[o+s1[i]]!=1 && (--e1)<0)
            goto NoMatch1;
      }
      else
      {
        for (i=0; i<max; i++)
        {
          if (i<len1 && ss[o+s1[i]]!=1 && (--e1)<0)
            goto NoMatch1;
          if (i<len0 && ss[o+s0[i]]!=0 && (--e0)<0)
            goto NoMatch1;
        }
      }
      //------------------
      // Combination lookup
      if (num>7)
      {
        x1=x+w1-1; y1=y-offsetY; if (y1<0) y1=0;
        for (j=7; j<num; j+=7)
        {
          o2=input[j]; w2=input[j+1]; h2=input[j+2];
          len21=input[j+3]; len20=input[j+4];
          err21=input[j+5]; err20=input[j+6];
          sx2=sw-w2; i=x1+offsetX; if (i<sx2) sx2=i;
          sy2=sh-h2; i=y+offsetY; if (i<sy2) sy2=i;
          for (x2=x1; x2<=sx2; x2++)
          {
            for (y2=y1; y2<=sy2; y2++)
            {
              o1=y2*sw+x2; e1=err21; e0=err20;
              for (i=0; i<len21; i++)
              {
                if (ss[o1+s1[o2+i]]!=1 && (--e1)<0)
                  goto NoMatch2;
              }
              if (e0!=len20)
              {
                for (i=0; i<len20; i++)
                  if (ss[o1+s0[o2+i]]!=0 && (--e0)<0)
                    goto NoMatch2;
              }
              goto MatchOK;
              NoMatch2:
              continue;
            }
          }
          goto NoMatch1;
          MatchOK:
          x1=x2+w2-1;
        }
      }
      //------------------
      allpos[ok++]=(sy+y)<<16|(sx+x);
      if (ok>=allpos_max)
        goto Return1;
      // Clear the image that has been found
      for (i=0; i<len1; i++)
        ss[o+s1[i]]=0;
      NoMatch1:
      continue;
    }
  }
  Return1:
  return ok;
}
