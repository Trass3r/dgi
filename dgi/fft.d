module dgi.fft;

import dgi.image;

import std.complex;
import std.array;
import std.range;
import std.algorithm;
import std.math;

@property bool isPowerOf2(size_t N) pure nothrow
{
	return (N & (N - 1)) == 0;
}

uint nearestPowerOf2(uint N) pure nothrow
{
	--N;
	N |= N >> 1;
	N |= N >> 2;
	N |= N >> 4;
	N |= N >> 8;
	N |= N >> 16;
	return ++N;
}

enum Dir
{
	Forward = -1,
	Inverse = 1
}

auto fft1(Dir dir = Dir.Forward, T)(in T[] x) /*pure nothrow*/
{
	immutable N = x.length;
	if (N <= 1)
		return x;
	const ev = fft1!dir(x.stride(2).array);
	const od = fft1!dir(x[1 .. $].stride(2).array);
	alias E = std.complex.expi;
	auto l = iota(N / 2).map!(k => ev[k] + T(E(dir * 2*PI * k/N)) * od[k]);
	auto r = iota(N / 2).map!(k => ev[k] - T(E(dir * 2*PI * k/N)) * od[k]);
	return l.chain(r).array;
}

struct FFT(uint N, T = float)
{
static if (N > 1)
	FFT!(N/2, T) next;

public:
	void apply(T* data)
	{
static if (N > 1)
{
		next.apply(data);
		next.apply(data + N);
		
		T tempr,tempi,c,s;
		
		for (uint i=0; i<N; i += 2)
		{
			c =  cos(i*PI/N);
			s = -sin(i*PI/N);
			tempr = data[i+N]*c - data[i+N+1]*s;
			tempi = data[i+N]*s + data[i+N+1]*c;
			data[i+N]   = data[i]-tempr;
			data[i+N+1] = data[i+1]-tempi;
			data[i]   += tempr;
			data[i+1] += tempi;
		}
}
	}
}

private template tuple(T...)
{
	alias tuple = T;
}

private template ctiota(uint end)
{
	static if (end == 0)
		enum ctiota = 0;
	else
		alias ctiota = tuple!(ctiota!(end-1), end);
}


void fft2(T)(in T[] x)
{
	import core.bitop;

	assert(x.length.isPowerOf2);
	switch(bsf(x.length))
	{
		foreach(uint N; ctiota!(31))
		{
		case N:
			FFT!(2^^N,float) f;
			f.apply(cast(float*)x.ptr);
			break;
		}
		default:
			assert(0);
	}
}

import dgi.imageview;
auto fft2d(View)(View v)
	if(isImageView!View)
{
	// TODO: color?, PixelType!View
	auto ret = Image!(Complex!float)(v.w, v.h);

	import std.numeric, std.typecons;
	auto f = scoped!Fft(v.w);
	//Complex!float[] transf = uninitializedArray!(Complex!float[])(v.w);
	for (uint y = 0; y < v.h; ++y)
	{
		f.fft(v.row(y), ret.row(y));
	}

	auto f2 = scoped!Fft(v.h);
	for (uint x = 0; x < v.w; ++x)
	{
		f2.fft(v.col(x), ret.col(x));
	}

	return ret;
}


bool approxEquali(T)(Complex!T a, Complex!T b)
{
	return approxEqual(a.re, b.re) && approxEqual(a.im, b.im);
}

unittest
{
	//asm {int 3;}
/*	auto x = [1.0f,2,3,4,5,6,7,8].map!complex.array;
	auto res = fft1(x);

	auto expected = [complex(36f, 0f), complex(-4f, 9.65685424949238f), complex(-4f, 4f), complex(-4f, 1.65685424949238f),
	                 complex(-4f, 0f), complex(-4f, 1.65685424949238f), complex(-4f, 4f), complex(-4f, 9.65685424949238f)];
	assert(expected[0] == res[0]);
	foreach (i, e; res)
		assert(approxEquali(e, expected[i]));
	fft2(x);
	foreach (i, e; x)
		assert(approxEquali(e, expected[i]));
*/
}
