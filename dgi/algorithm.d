module dgi.algorithm;

import dgi.image;
import std.math;
import dgi.imageview;

Image!ubyte houghTransform(Image!ubyte img, uint width, uint height) pure nothrow
in
{
	assert((height & 1) == 0, "height argument must be even.");
}
body
{
	auto result = Image!ubyte(width, height);
	//result.clear(Gray.white);
	result.ptr[0 .. width*height] = 255;

	immutable double rMax = hypot(img.w, img.h);
	immutable double dr = rMax / (height / 2.0);
	immutable double dTh = PI / width;

	foreach (immutable y; 0 .. img.h)
	{
		foreach (immutable x; 0 .. img.w)
		{
			if (img[x, y] == 255)//Gray.white)
				continue;
			foreach (immutable iTh; 0 .. width)
			{
				immutable double th = dTh * iTh;
				immutable double r = x * cos(th) + y * sin(th);
				immutable iry = height / 2 - cast(int)floor(r / dr + 0.5);
				if (result[iTh, iry] > 0)
					--result[iTh, iry];
			}
		}
	}
	return result;
}

unittest
{
	import dgi.io.png;
	import std.file;

	ubyte[] data = [0,0,1,0,0,0,0,0,
	                0,1,0,1,1,0,0,0,
	                1,0,0,0,0,1,1,0,
	                1,0,0,0,0,0,0,1,
	                1,0,0,0,0,0,0,1,
	                0,1,0,0,0,0,0,1,
	                0,0,1,0,0,0,1,0,
	                0,0,0,1,1,1,0,0];
	auto input = interleavedView(8, 8, data.ptr);
	std.file.write("hough.png", input.houghTransform(256, 256).toPNG());
}


/// transforms an image
/// xexpr and yexpr have access to parameters 'x', 'y', img.'w' and img.'h'
/// wexpr and hexpr have access to parameters img.'w' and img.'h'
/// shared among functions here
private struct Algorithm(T, string idxexpr = "img[x, y]", string wexpr = "w", string hexpr = "h")
{
	private T img;
	
	@property auto w() const
	{
		auto w = img.w;
		auto h = img.h;
		return mixin(wexpr);
	}
	
	@property auto h() const
	{
		auto w = img.w;
		auto h = img.h;
		return mixin(hexpr);
	}

	auto opIndex(int x, int y) const
	{
		auto w = img.w; // TODO: correct to provide original ones or need transformed?
		auto h = img.h;
		return mixin(idxexpr);
	}
/*
	static if (isWritableImageView!T)
		void opIndexAssign(PixelType!T p, int x, int y)
	{
		auto w = img.w;
		auto h = img.h;

		mixin(idxexpr) = p;
	}
*/
}

/// vertical gradient
auto diffx(T)(T img)
	if (isImageView!T)
{
	return Algorithm!(T, "img[x+1, y] - img[x, y]", "w-1", "h")(img);
}

/// horizontal gradient
auto diffy(T)(T img)
	if (isImageView!T)
{
	return Algorithm!(T, "img[x, y+1] - img[x, y]", "w", "h-1")(img);
}


template reduce(fun...)
{
	auto reduce(T)(T img)
		if (isImageView!T)
	{
		for (int y = 0; y < src.h; ++y)
			for (int x = 0; x < src.w; ++x)
				// HACK: color conversion
				dest[x, y] = src[x, y];
	}
}

alias sum = reduce!"a + b";

unittest
{

}