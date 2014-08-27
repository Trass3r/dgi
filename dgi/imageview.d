module dgi.imageview;
import std.range;

import std.functional; // for binaryFun etc.

// this is only needed cause of row/col below
private
enum isImageViewBase(T) = is(typeof(T.init.w) : size_t) &&
                      is(typeof(T.init.h) : size_t) &&
                      is(typeof(T.init[0,0]));
/**
 *  an image view provides w and h properties for width and height
 *  as well as indexing for accessing individual pixels
 */
enum isImageView(T) = isImageViewBase!T &&
                      isRandomAccessRange!(typeof(T.init.row(0))) &&
                      isRandomAccessRange!(typeof(T.init.col(0)));

/// get the underlying pixel type of this image view
alias PixelType(T) = typeof(T.init[0,0]);

/// a writable image additionally provides write access via indexing
enum isWritableImageView(T) = isImageView!T &&
                              is(typeof(T.init[0,0] = PixelType!T.init));


/**
 *  generic implementations of row and col methods for most image views
 *  provides RandomAccessRanges for a particular row or column on top of opIndex
 *
 *  A few types with direct access to the pixels in memory can provide actual slices instead.
 */
auto row(T)(T img, uint y)
	if (isImageViewBase!T)
{
	// TODO: maybe code a custom Range later
	import std.algorithm;
	return iota(img.w).map!(x => img[x, y]);
}

/// ditto
auto col(T)(T img, uint x)
	if (isImageViewBase!T)
{
	import std.algorithm;
	return iota(img.h).map!(y => img[x, y]);
}

/// procedural image based on lambda function or string formula with x and y variables
auto synthetic(alias formula)(uint w, uint h)
{
	alias fun   = binaryFun!(formula, "x", "y");
	alias Pixel = typeof(fun(0, 0));

	struct Synthetic
	{
		uint w, h;
		Pixel opIndex(int x, int y) const
		{
			assert(x < w && y < h);
			return fun(x, y);
		}

		Pixel[] row(int y)
		{
			auto ret = new Pixel[w];
			foreach (int x; 0 .. w)
				ret[x] = this[x, y];
			return ret;
		}
	}

	return Synthetic(w, h);
}

/// creates an image of uniform color
auto solid(Pixel)(Pixel value, uint width, uint height)
{
	return synthetic!((x,y) => value)(width, height);
}

/*
auto iota(Pixel)(Pixel start, Pixel end, uint width, uint height)
{
	return synthetic!((x,y) => value)(width, height);
}*/

version(unittest)
/// 3x2 image with entries [1,2,3;4,5,6]
enum testImage = synthetic!((x,y) => y*3+x + 1)(3, 2);
// TODO: immutable views?

unittest
{
	assert(testImage[0,0] == 1);
	assert(testImage[2,0] == 3);
	assert(testImage[0,1] == 4);
	assert(testImage[2,1] == 6);

	auto ones = solid(1, 2, 2);
	assert(ones[0, 1] == 1);
}


/*
/// compile-time sub-image view
auto subImageView(T, uint dx, uint dy, uint width, uint height)(T img)
	if (isImageView!T)
{
	return TransformedView!(T, "x + dx", "y + dy")(img);
}
*/

/// runtime version of subview
auto subImageView(T)(T img, uint dx, uint dy, uint width, uint height)
	if (isImageView!T)
{
	static struct SubImageView
	{
		private T v;
		private uint dx, dy;
		uint w, h;

		auto opIndex(int x, int y) const
		{
			return v[x + dx, y + dy];
		}

		static if (isWritableImageView!T)
		void opIndexAssign(PixelType!T p, int x, int y)
		{
			v[x + dx, y + dy] = p;
		}
	}

	return SubImageView(img, dx, dy, width, height);
}

unittest
{
	auto a = synthetic!"x"(10, 1).subImageView(8, 0, 2, 1);
	assert(a[0, 0] == 8);
}

private struct MappedView(alias mapping, T)
{
//	private alias fun   = unaryFun!(formula);
//	private alias Pixel = typeof(fun(0, 0));

	private T img;
	@property auto w() const { return img.w; }
	@property auto h() const { return img.h; }

	auto opIndex(int x, int y) const
	{
		return unaryFun!(mapping, false, "c")(img[x, y]);
	}

	// TODO: how to deal with writable views?
/*	static if (isWritableImageView!T)
	void opIndexAssign(PixelType!T p, int x, int y)
	{
		img[x, y] = p;
	}
*/
}

/// apply the given function to all pixels
/// either a lambda or a string using parameter 'c'
auto map(alias mapping, T)(T img)
	if (isImageView!T)
{
	return MappedView!(mapping, T)(img);
}

/*
import std.algorithm : reduce;
auto arrayView(T)(T img)
	if (isImageView!T)
{

}
*/
/*
auto reducde(alias fun, T)(T img)
{
}
*/

unittest
{
	auto a = testImage.map!"c * 5";
	assert(a[2, 0] == 15);
}

/// transforms an image
/// xexpr and yexpr have access to parameters 'x', 'y', img.'w' and img.'h'
/// wexpr and hexpr have access to parameters img.'w' and img.'h'
/// shared among functions here
private struct TransformedView(T, string xexpr = "x", string yexpr = "y", string wexpr = "w", string hexpr = "h")
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
		auto xt = mixin(xexpr);
		auto yt = mixin(yexpr);

		return img[xt, yt];
	}

	auto opIndex(float x, float y) const
	{
		auto w = img.w; // TODO: correct to provide original ones or need transformed?
		auto h = img.h;
		auto xt = mixin(xexpr);
		auto yt = mixin(yexpr);
		
		return img[xt, yt];
	}

	static if (isWritableImageView!T)
	void opIndexAssign(PixelType!T p, int x, int y)
	{
		auto w = img.w;
		auto h = img.h;
		auto xt = mixin(xexpr);
		auto yt = mixin(yexpr);

		img[xt, yt] = p;
	}
}

struct WarpedView
{
	alias TransformedView this;

	auto opIndex(int x, int y) const
	{
		auto w = img.w; // TODO: correct to provide original ones or need transformed?
		auto h = img.h;
		auto xt = mixin(xexpr);
		auto yt = mixin(yexpr);
		
		return img[xt, yt];
	}
}

/// flips the x and y axis of the image
auto transpose(T)(T img)
	if (isImageView!T)
{
	return TransformedView!(T, "y", "x", "h", "w")(img);
}

/// rotate 90 degrees ccw
auto rot90(T)(T img)
	if (isImageView!T)
{
	return TransformedView!(T, "y", "x", "h", "w")(img); // TODO:
}

/// flip image upside down
auto flipud(T)(T img)
	if (isImageView!T)
{
	return TransformedView!(T, "x", "h-y-1")(img);
}

/// flip image left to right
auto fliplr(T)(T img)
	if (isImageView!T)
{
	return TransformedView!(T, "w-x-1", "y")(img);
}

unittest
{
	auto t = testImage.transpose();
	assert(t.h == testImage.w);
	assert(t[1,2] == testImage[2,1]);

	auto flipped = testImage.flipud();
	assert(flipped.w == testImage.w);
	assert(flipped[1,0] == testImage[1,1]);

	auto flipped2 = testImage.fliplr();
	assert(flipped2.w == testImage.w);
	assert(flipped2[0,1] == testImage[2,1]);
}

private int myround(float f)
{
	// TODO:
	assert(f >= -0.5);
	return cast(int)(f+0.5);
}

private int myfloor(float f)
{
	// TODO:
	return cast(int)f;
}

private int myceil(float f)
{
	// TODO:
	return cast(int)f + 1;
}

auto nearestNeighbor(T)(T img, float x, float y)
{
	static assert(isImageView!T);
	// 0 is middle of pixel
	return img[myround(x), myround(y)];
}

auto bilinearInterp(T)(T img, float x, float y)
{
	static assert(isImageView!T);
	int x0 = myfloor(x);
	int y0 = myfloor(y);
	x -= x0; // now in [0,1]
	y -= y0;

	auto R1 = (1-x) * img[x0, y0]   + x * img[x0+1, y0];   // upper middle point
	auto R2 = (1-x) * img[x0, y0+1] + x * img[x0+1, y0+1]; // lower middle point
	return (1-y) * R1 + y * R2;
}

unittest
{
	import dgi.image;
	auto img = interleavedView(2, 2, [0, 1, 1, 0.5f]);

	Image output = Image!float(100, 100);
	for (int y = 0; y < 100; ++y)
		for (int x = 0; x < 100; ++x)
			output[x, y] = bilinearInterp(img, x / 100.0f, y / 100.0f);
	//output.map!(c => bilinearInterp()).eval();
}

/*
auto rotate(T)(T img, float a)
{
	static assert(isImageView!T);

	return TransformedView!(T n)
}*/

private struct BorderExtend(alias c, T)
{
	private T img;
	@property auto w() const { return img.w; }
	@property auto h() const { return img.h; }
	
	auto opIndex(int x, int y) const
	{
		if (x < 0 | y < 0 || x >= img.w || y >= img.h)
			return mixin(c);

		return img[x, y];
	}
}

auto constExtend(alias c = 0, T)(T img)
{
	return BorderExtend!(c, T)(img);
}

/// copy pixels of one image view to 
void copyTo(T, U)(T src, U dest)
	if (isImageView!T && isWritableImageView!U)
{
	for (int y = 0; y < src.h; ++y)
		for (int x = 0; x < src.w; ++x)
			             // HACK: color conversion
			dest[x, y] = PixelType!U(src[x, y]);
}

unittest
{
	import std.math;

	auto waves = synthetic!"cast(float)sin(2*PI/25 * sqrt(cast(float)(x*x+y*y)))*0.5f + 0.5f"(100, 100);
	static assert(isImageView!(typeof(waves)));
}