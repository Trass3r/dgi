module dgi.io.jpg;

import dgi.image;

extern(C)
{
	/// Result codes for njDecode().
	enum nj_result_t
	{
		NJ_OK = 0,        // no error, decoding successful
		NJ_NO_JPEG,       // not a JPEG file
		NJ_UNSUPPORTED,   // unsupported format
		NJ_OUT_OF_MEM,    // out of memory
		NJ_INTERNAL_ERR,  // internal error
		NJ_SYNTAX_ERROR,  // syntax error
		__NJ_FINISHED,    // used internally, will never be reported
	}

	/// njInit: Initialize NanoJPEG.
	/// For safety reasons, this should be called at least one time before using
	/// using any of the other NanoJPEG functions.
	void njInit();

	/// njDecode: Decode a JPEG image.
	/// Decodes a memory dump of a JPEG file into internal buffers.
	/// Parameters:
	///   jpeg = The pointer to the memory dump.
	///   size = The size of the JPEG file.
	/// Return value: The error code in case of failure, or NJ_OK (zero) on success.
	nj_result_t njDecode(const void* jpeg, int size);

	/// njGetWidth: Return the width (in pixels) of the most recently decoded
	/// image. If njDecode() failed, the result of njGetWidth() is undefined.
	int njGetWidth();

	/// njGetHeight: Return the height (in pixels) of the most recently decoded
	/// image. If njDecode() failed, the result of njGetHeight() is undefined.
	int njGetHeight();

	/// njIsColor: Return 1 if the most recently decoded image is a color image
	/// (RGB) or 0 if it is a grayscale image. If njDecode() failed, the result
	/// of njGetWidth() is undefined.
	int njIsColor();

	/// njGetImage: Returns the decoded image data.
	/// Returns a pointer to the most recently image. The memory layout it byte-
	/// oriented, top-down, without any padding between lines. Pixels of color
	/// images will be stored as three consecutive bytes for the red, green and
	/// blue channels. This data format is thus compatible with the PGM or PPM
	/// file formats and the OpenGL texture formats GL_LUMINANCE8 or GL_RGB8.
	/// If njDecode() failed, the result of njGetImage() is undefined.
	ubyte* njGetImage();

	/// njGetImageSize: Returns the size (in bytes) of the image data returned
	/// by njGetImage(). If njDecode() failed, the result of njGetImageSize() is
	/// undefined.
	int njGetImageSize();

	/// njDone: Uninitialize NanoJPEG.
	/// Resets NanoJPEG's internal state and frees all memory that has been
	/// allocated at run-time by NanoJPEG. It is still possible to decode another
	/// image after a njDone() call.
	void njDone();
}

auto readJPG(Color)(const(char)[] filename)
{
	import std.file;

	auto data = read(filename);

	njInit();
	if (njDecode(data.ptr, cast(int)data.length))
		assert(0);

	int width = njGetWidth();
	int height = njGetHeight();

	static if (is(Color == ubyte))
		assert(!njIsColor());
	else
	{
		static assert (Color.sizeof == 3);
		assert(njIsColor());
	}

	assert(width * height * Color.sizeof == njGetImageSize());

	Color[] imgdata;
	imgdata.length = width * height;
	imgdata[] = njGetImage()[0 .. imgdata.length]; // copy
	njDone(); // now delete

	return Image!(Color)(width, height, imgdata.ptr);
}
