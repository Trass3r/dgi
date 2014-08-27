module test;

import std.stdio;
import std.random;
import std.file;
import std.complex;
import std.conv;
import std.math;

import derelict.sdl2.sdl;

import dgi.imageview;
import dgi.image;
import dgi.fft;
import dgi.io.png;
import dgi.io.jpg;
import dgi.algorithm;

struct ARGB
{
	ubyte b,g,r,a;

	this(int i)
	{
		this = cast(ubyte)(i + 50);
	}

	this(ubyte b)
	{
		this = b;
	}

	// HACK:
	this(float f)
	{
		assert(f >= 0 && f <= 1, to!string(f));
		this = cast(ubyte)(255 * f);
	}

	import std.complex;
	this(Complex!float f)
	{
		this = cast(ubyte)(255 * abs(f));
	}

	void opAssign(ubyte v)
	{
		r = g = b = v;
		a = 255;
	}
}

void main(string[] args)
{
	enum w = 1024, h = 1024;

	DerelictSDL2.load();

	SDL_Init(SDL_INIT_TIMER | SDL_INIT_VIDEO);
	scope(exit) SDL_Quit();

	SDL_Window* window = SDL_CreateWindow("test",
	                                      SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
	                                      w, h,
	                                      SDL_WINDOW_RESIZABLE);
	assert(window, "Error while loading window!");
	scope(exit) SDL_DestroyWindow(window);

/*
	SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED|SDL_RENDERER_PRESENTVSYNC);
	assert(renderer, "Failed to create renderer!");

	// draw in black (r,g,b all zero, alpha full), clear the whole window, put the cleared window on the screen
	SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
	SDL_RenderClear(renderer);
	SDL_RenderPresent(renderer);

	SDL_Texture* texture = SDL_CreateTexture(renderer,
	                                         SDL_PIXELFORMAT_ARGB8888,
	                                         SDL_TEXTUREACCESS_STREAMING,
	                                         w, h);
*/

	SDL_Surface* screen = SDL_GetWindowSurface(window);
	assert(screen);

	auto img = readJPG!ubyte(args[1]);

	auto waves = synthetic!"cast(float)sin(2*PI/25 * sqrt(cast(float)(x*x+y*y)))*0.5f + 0.5f"(w, h).transpose();
	std.file.write("waves.png", waves.map!"cast(ubyte)(255*c)".toPNG());
	auto wavesf = fft2d(waves);

	SDL_LockSurface(screen);
	auto screenImg = interleavedView(screen.w, screen.h, cast(ARGB*)screen.pixels);
	// TODO: HACK: actually would be sqrt(w)*sqrt(h), but here it's = w
	//wavesf.map!(c => abs(c)/w).copyTo(screenImg);
	img.subImageView(1312, 1200, w, h).diffx.copyTo(screenImg);
	SDL_UnlockSurface(screen);

	uint frameNumber, totalTime, lastTime;
	while (true)
	{
/*		SDL_LockSurface(screen);
		foreach (i; 0 .. screen.w * screen.h)
			(cast(ARGB*)screen.pixels)[i] = (uniform(0, 2) ? 255 : 0);
		SDL_UnlockSurface(screen);
*/		SDL_UpdateWindowSurface(window);
		++frameNumber;

		uint time = SDL_GetTicks();
		totalTime += time - lastTime;
		if (totalTime > 1000) {
			writeln("FPS: ", frameNumber / (totalTime / 1000.0));
			totalTime = frameNumber = 0;
		}
		lastTime = time;
	}
}