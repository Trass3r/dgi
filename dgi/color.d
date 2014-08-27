module dgi.color;

struct Channel(T, T min = T.min, T max = T.max)
{
	alias Type = T;
	enum minValue = min;
	enum maxValue = max;
	T x;
	alias x this;
	
	T opUnary(string op : "~")() const
	{
		return maxValue - x + minValue;
	}
	
	auto opBinary(string op : "*")(Channel o) const
	{
		return x * o.x / maxValue;
	}

	U convertTo(U)() const
	{

	}
}

alias bits32f = Channel!(float, 0.0f, 1.0f);


T convertColor(T, T2)(T2 pixel)
{
	static if (isRGB!T2)
}

T convertChannel(T, T2)(T2 ch)
{
	
}

alias Tuple(T...) = T;

//! RGB color space
struct RGB(ChannelType)
{

	//Tuple!("r", "g", "b") t;
	//alias t this;
}

struct Gray(ChannelType)
{
	ChannelType l; // luminance
}
