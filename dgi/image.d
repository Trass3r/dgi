module dgi.image;

import dgi.imageview;


/// standard interleaved image
struct Image(Pixel)
{
	static assert(!is(Pixel == void), "TODO: later");
	Pixel* ptr;
	uint w, h;
	private uint stride; // TODO: get rid? and provide opSlice?

	// in bytes?
	/*	@property size_t length() const
	{
		return stride * h;
	}
*/

	//@disable this(this);

	this(uint width, uint height)
	{
		w = width;
		h = height;
		ptr = new Pixel[width*height].ptr;
		stride = width * cast(uint)Pixel.sizeof;
	}

	this(uint width, uint height, Pixel* data)
	{
		this(width, height, data, width * cast(uint)Pixel.sizeof);
	}

	this(uint width, uint height, Pixel* data, uint stride)
	{
		w = width;
		h = height;
		ptr = data;
		this.stride = stride;
	}

	Pixel[] row(int y) const
	{
		// TODO: how ugly -.-
		return (cast(Pixel*)(cast(ubyte*)ptr + y*stride))[0 .. w];
	}

	Pixel opIndex(int x, int y) const
	{
		//return ptr[y*stride + x];
		return row(y)[x];
	}

	void opIndexAssign(Pixel p, int x, int y)
	{
		//ptr[y*stride + x] = p;
		row(y)[x] = p;
	}

	void opIndexUnary(string op)(int x, int y)
	{
		mixin(op ~ "row(y)[x];");
	}

	void opIndexOpAssign(string op)(Pixel p, int x, int y)
	{
		mixin("row(y)[x] " ~ op ~ "= p;");
	}
}

Image!(PixelType!T) eval(T)(T view)
	if (isImageView!T)
{
	auto img = Image!(PixelType!T)(view.w, view.h);
	//@mem(img.data.ptr, FLOAT32, 1, view.w, view.h, view.w*4)

	for (uint y = 0; y < view.h; ++y)
		for (uint x = 0; x < view.w; ++x)
			img[x, y] = view[x, y];

	return img;
}

/// creates an ImageView wrapper for a standard interleaved in-memory image
auto interleavedView(PixelType)(uint width, uint height, PixelType* data)
{
	return Image!PixelType(width, height, data);
}

unittest
{
	static assert(isImageView!(Image!ubyte));

	ubyte[4] data;
	auto iv = interleavedView(2, 2, &data);
	static assert(isImageView!(typeof(iv)));

	auto img = iv.eval();
}