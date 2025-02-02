PicFind(int mode, unsigned int c, unsigned int n, int dir, unsigned char *Bmp, int Stride, int sx, int sy, int sw, int sh, unsigned char *ss, unsigned int *s1, unsigned int *s0, unsigned char *text, int w, int h, int err1, int err0, int more_err, unsigned int *allpos, int allpos_max, int new_w, int new_h)
{
	int ok, o, i, j, k, v, e1, e0, len1, len0, max, pic, shape, sort;
	int x, y, x1, y1, x2, y2, x3, y3, r, g, b, rr, gg, bb, dR, dG, dB;
	int ii, jj, RunDir, DirCount, RunCount, AllCount1, AllCount2;
	unsigned int c1, c2, *cors, *arr;
	unsigned char *ts, *gs;
	ok = 0;
	o = 0;
	v = 0;
	len1 = 0;
	len0 = 0;
	ts = ss + sw;
	gs = ss + sw * 3;
	arr = allpos + allpos_max;
	sort = (dir == 0);
	//----------------------
	if (mode == 5)
	{
		// FindPic
		if (pic = (c == 2))
		{
			cors = (unsigned int *)(text + w * h * 4);
			j = (err0 >> 10) + 1;
			n *= 2;
			for (y = 0; y < h; y += j)
			{
				for (x = 0; x < w; x += j)
				{
					o = (y * w + x) * 4;
					rr = text[2 + o];
					gg = text[1 + o];
					bb = text[o];
					for (i = 2; i < n;)
					{
						c1 = cors[i++];
						c2 = cors[i++];
						r = ((c1 >> 16) & 0xFF) - rr;
						g = ((c1 >> 8) & 0xFF) - gg;
						b = (c1 & 0xFF) - bb;
						v = (c2 < 0x1000000) ? (3 * r * r + 4 * g * g + 2 * b * b <= c2)
											 : (r * r <= ((c2 >> 16) & 0xFF) * ((c2 >> 16) & 0xFF) && g * g <= ((c2 >> 8) & 0xFF) * ((c2 >> 8) & 0xFF) && b * b <= (c2 & 0xFF) * (c2 & 0xFF));
						if (v)
							goto NoMatch1;
					}
					s1[len1] = (y * new_h / h) * Stride + (x * new_w / w) * 4;
					s0[len1++] = rr << 16 | gg << 8 | bb;
				NoMatch1:;
				}
			}
			c2 = cors[1];
			r = (c2 >> 16) & 0xFF;
			g = (c2 >> 8) & 0xFF;
			b = c2 & 0xFF;
			dR = r * r;
			dG = g * g;
			dB = b * b;
		}
		else
		{
			// FindMultiColor or FindColor
			shape = (c == 1); // FindShape
			cors = (unsigned int *)text;
			for (i = 0; i < n; i++, o += 22)
			{
				c = cors[o];
				y = c >> 16;
				x = c & 0xFFFF;
				s1[len1] = (y * new_h / h) * Stride + (x * new_w / w) * 4;
				s0[len1++] = o + cors[o + 1] * 2;
			}
			cors += 2;
		}
		goto StartLookUp;
	}
	//----------------------
	// Generate Lookup Table
	for (y = 0; y < h; y++)
	{
		for (x = 0; x < w; x++)
		{
			i = (mode == 4) ? (y * new_h / h) * Stride + (x * new_w / w) * 4 : (y * new_h / h) * sw + (x * new_w / w);
			if (text[o++] == '1')
				s1[len1++] = i;
			else
				s0[len0++] = i;
		}
	}
	//----------------------
	// Color Position Mode
	// only used to recognize multicolored Verification Code
	if (mode == 4)
	{
		y = c >> 16;
		x = c & 0xFFFF;
		c = (y * new_h / h) * Stride + (x * new_w / w) * 4;
		goto StartLookUp;
	}
	//----------------------
	// Generate Two Value Image
	o = sy * Stride + sx * 4;
	j = Stride - sw * 4;
	i = 0;
	if (mode == 1) // Color Mode
	{
		cors = (unsigned int *)(text + w * h);
		n *= 2;
		for (y = 0; y < sh; y++, o += j)
		{
			for (x = 0; x < sw; x++, o += 4, i++)
			{
				rr = Bmp[2 + o];
				gg = Bmp[1 + o];
				bb = Bmp[o];
				for (k = 0; k < n;)
				{
					c1 = cors[k++];
					c2 = cors[k++];
					r = ((c1 >> 16) & 0xFF) - rr;
					g = ((c1 >> 8) & 0xFF) - gg;
					b = (c1 & 0xFF) - bb;
					v = (c2 < 0x1000000) ? (3 * r * r + 4 * g * g + 2 * b * b <= c2)
										 : (r * r <= ((c2 >> 16) & 0xFF) * ((c2 >> 16) & 0xFF) && g * g <= ((c2 >> 8) & 0xFF) * ((c2 >> 8) & 0xFF) && b * b <= (c2 & 0xFF) * (c2 & 0xFF));
					if (v)
						break;
				}
				ts[i] = (v) ? 1 : 0;
			}
		}
	}
	else if (mode == 2) // Gray Threshold Mode
	{
		c = (c + 1) << 7;
		for (y = 0; y < sh; y++, o += j)
			for (x = 0; x < sw; x++, o += 4, i++)
				ts[i] = (Bmp[2 + o] * 38 + Bmp[1 + o] * 75 + Bmp[o] * 15 < c) ? 1 : 0;
	}
	else if (mode == 3) // Gray Difference Mode
	{
		for (y = 0; y < sh; y++, o += j)
		{
			for (x = 0; x < sw; x++, o += 4, i++)
				gs[i] = (Bmp[2 + o] * 38 + Bmp[1 + o] * 75 + Bmp[o] * 15) >> 7;
		}
		for (i = 0, y = 0; y < sh; y++)
			for (x = 0; x < sw; x++, i++)
				if (x == 0 || x == sw - 1 || y == 0 || y == sh - 1)
					ts[i] = 2;
				else
				{
					n = gs[i] + c;
					ts[i] = (gs[i - 1] > n || gs[i + 1] > n || gs[i - sw] > n || gs[i + sw] > n || gs[i - sw - 1] > n || gs[i - sw + 1] > n || gs[i + sw - 1] > n || gs[i + sw + 1] > n) ? 1 : 0;
				}
	}
//----------------------
StartLookUp:
	for (i = 0, y = 0; y < sh; y++)
	{
		for (x = 0; x < sw; x++, i++)
		{
			if (mode >= 4)
			{
				ss[i] = 4;
				continue;
			}
			r = ts[i];
			g = (x == 0 ? 3 : ts[i - 1]);
			b = (x == sw - 1 ? 3 : ts[i + 1]);
			if (more_err)
				ss[i] = 4 | (r == 2 || r == 1 || g == 1 || b == 1) << 1 | (r == 2 || r == 0 || g == 0 || b == 0);
			else
				ss[i] = 4 | (r == 2 || r == 1) << 1 | (r == 2 || r == 0);
		}
	}
	if (mode < 4 && more_err)
		sx++;
	err1 = (len1 * err1) >> 10;
	err0 = (len0 * err0) >> 10;
	if (err1 >= len1)
		len1 = 0;
	if (err0 >= len0)
		len0 = 0;
	max = (len1 > len0) ? len1 : len0;
	w = new_w;
	h = new_h;
	x1 = 0;
	y1 = 0;
	x2 = sw - w;
	y2 = sh - h;
	// 1 ==> ( Left to Right ) Top to Bottom
	// 2 ==> ( Right to Left ) Top to Bottom
	// 3 ==> ( Left to Right ) Bottom to Top
	// 4 ==> ( Right to Left ) Bottom to Top
	// 5 ==> ( Top to Bottom ) Left to Right
	// 6 ==> ( Bottom to Top ) Left to Right
	// 7 ==> ( Top to Bottom ) Right to Left
	// 8 ==> ( Bottom to Top ) Right to Left
	// 9 ==> Center to Four Sides
	if (dir == 9)
	{
		x = (x1 + x2) / 2;
		y = (y1 + y2) / 2;
		i = x2 - x1 + 1;
		j = y2 - y1 + 1;
		AllCount1 = i * j;
		i = (i > j ? i : j) + 8;
		AllCount2 = i * i;
		RunCount = 0;
		DirCount = 1;
		RunDir = 0;
		for (ii = 0; RunCount < AllCount1 && ii < AllCount2;)
		{
			for (jj = 0; jj < DirCount; jj++, ii++)
			{
				if (x >= x1 && x <= x2 && y >= y1 && y <= y2)
				{
					RunCount++;
					goto FindPos;
				FindPos_GoBak:;
				}
				if (RunDir == 0)
					y--;
				else if (RunDir == 1)
					x++;
				else if (RunDir == 2)
					y++;
				else
					x--;
			}
			if (RunDir & 1)
				DirCount++;
			RunDir = (++RunDir) & 3;
		}
		goto Return1;
	}
	if (dir < 1 || dir > 8)
		dir = 1;
	if (--dir > 3)
	{
		r = y1;
		y1 = x1;
		x1 = r;
		r = y2;
		y2 = x2;
		x2 = r;
	}
	for (y3 = y1; y3 <= y2; y3++)
	{
		for (x3 = x1; x3 <= x2; x3++)
		{
			y = (dir & 2) ? y1 + y2 - y3 : y3;
			x = (dir & 1) ? x1 + x2 - x3 : x3;
			if (dir > 3)
			{
				r = y;
				y = x;
				x = r;
			}
		//----------------------
		FindPos:
			e1 = err1;
			e0 = err0;
			o = y * sw + x;
			if (ss[o] < 4)
				goto NoMatch;
			if (mode < 4)
			{
				for (i = 0; i < max; i++)
				{
					if (i < len1 && (ss[o + s1[i]] & 2) == 0 && (--e1) < 0)
						goto NoMatch;
					if (i < len0 && (ss[o + s0[i]] & 1) == 0 && (--e0) < 0)
						goto NoMatch;
				}
			}
			else if (mode == 5)
			{
				o = (sy + y) * Stride + (sx + x) * 4;
				if (pic)
				{
					for (i = 0; i < max; i++)
					{
						j = o + s1[i];
						c = s0[i];
						r = Bmp[2 + j] - ((c >> 16) & 0xFF);
						g = Bmp[1 + j] - ((c >> 8) & 0xFF);
						b = Bmp[j] - (c & 0xFF);
						v = (c2 < 0x1000000) ? (3 * r * r + 4 * g * g + 2 * b * b > c2) : (r * r > dR || g * g > dG || b * b > dB);
						if (v && (--e1) < 0)
							goto NoMatch;
					}
				}
				else
				{
					for (i = 0; i < max; i++)
					{
						j = o + s1[i];
						rr = Bmp[2 + j];
						gg = Bmp[1 + j];
						bb = Bmp[j];
						for (j = i * 22, k = cors[j] > 0xFFFFFF, n = s0[i]; j < n;)
						{
							c1 = cors[j++];
							c2 = cors[j++];
							if (shape)
							{
								if (i == 0)
									c = rr << 16 | gg << 8 | bb;
								k = !c1;
								c1 = c;
							}
							r = ((c1 >> 16) & 0xFF) - rr;
							g = ((c1 >> 8) & 0xFF) - gg;
							b = (c1 & 0xFF) - bb;
							v = (c2 < 0x1000000) ? (3 * r * r + 4 * g * g + 2 * b * b <= c2)
												 : (r * r <= ((c2 >> 16) & 0xFF) * ((c2 >> 16) & 0xFF) && g * g <= ((c2 >> 8) & 0xFF) * ((c2 >> 8) & 0xFF) && b * b <= (c2 & 0xFF) * (c2 & 0xFF));
							if (v)
							{
								if (k)
									goto NoMatch2;
								goto MatchOK;
							}
						}
						if (k)
							goto MatchOK;
					NoMatch2:
						if ((--e1) < 0)
							goto NoMatch;
					MatchOK:;
					}
				}
			}
			else // mode==4
			{
				o = (sy + y) * Stride + (sx + x) * 4;
				j = o + c;
				rr = Bmp[2 + j];
				gg = Bmp[1 + j];
				bb = Bmp[j];
				for (i = 0; i < max; i++)
				{
					if (i < len1)
					{
						j = o + s1[i];
						r = Bmp[2 + j] - rr;
						g = Bmp[1 + j] - gg;
						b = Bmp[j] - bb;
						if (3 * r * r + 4 * g * g + 2 * b * b > n && (--e1) < 0)
							goto NoMatch;
					}
					if (i < len0)
					{
						j = o + s0[i];
						r = Bmp[2 + j] - rr;
						g = Bmp[1 + j] - gg;
						b = Bmp[j] - bb;
						if (3 * r * r + 4 * g * g + 2 * b * b <= n && (--e0) < 0)
							goto NoMatch;
					}
				}
			}
			ok++;
			if (allpos)
			{
				allpos[ok - 1] = (sy + y) << 16 | (sx + x);
				if (sort)
					arr[ok - 1] = err1 - e1;
				if (ok >= allpos_max)
					goto Return1;
			}
			// Skip areas that may overlap
			if (!sort)
			{
				r = y - h + 1;
				if (r < 0)
					r = 0;
				rr = y + h - 1;
				if (rr > sh - h)
					rr = sh - h;
				g = x - w + 1;
				if (g < 0)
					g = 0;
				gg = x + w - 1;
				if (gg > sw - w)
					gg = sw - w;
				for (i = r; i <= rr; i++)
					for (j = g; j <= gg; j++)
						ss[i * sw + j] &= 3;
			}
		NoMatch:
			if (dir == 9)
				goto FindPos_GoBak;
		}
	}
//----------------------
Return1:
	if (!sort || !allpos || w * h == 1)
		return ok;
	// Sort by smallest error
	for (i = 1; i < ok; i++)
	{
		k = arr[i];
		v = allpos[i];
		for (j = i - 1; j >= 0 && arr[j] > k; j--)
		{
			arr[j + 1] = arr[j];
			allpos[j + 1] = allpos[j];
		}
		arr[j + 1] = k;
		allpos[j + 1] = v;
	}
	// Clean up overlapping results
	w *= w;
	h *= h;
	k = ok;
	ok = 0;
	for (i = 0; i < k; i++)
	{
		c1 = allpos[i];
		x1 = c1 & 0xFFFF;
		y1 = c1 >> 16;
		for (j = 0; j < ok; j++)
		{
			c2 = allpos[j];
			x = (c2 & 0xFFFF) - x1;
			y = (c2 >> 16) - y1;
			if (x * x < w && y * y < h)
				goto NoMatch3;
		}
		allpos[ok++] = c1;
	NoMatch3:;
	}
	return ok;
}
