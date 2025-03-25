# Shallow Water Demo by Stephen Thompson

This archive contains the source code for my Shallow Water Demo.

This is an old project, from back in 2014, but it should still be
runnable on current machines.

For more information on the demo itself, and pre-built binaries,
please refer to http://www.solarflare.org.uk/shallow_water_demo/index.html.


# Compiling

A Visual Studio 2008 solution file is provided ("shallow_water.sln" in
the "msvc" directory). Compiling should be straightforward, although
you will need to have the latest DirectX SDK correctly installed on
your machine. (You might also have to upgrade the solution files to a
more recent Visual Studio version, although Visual Studio should offer
to do this automatically.)

To run the compiled exe, make sure you set Working Directory to 
"$(SolutionDir)\..", otherwise the data files will not be found.


# Roadmap

The source consists of three projects:

1) Coercri -- This is a simple wrapper library around operating system
functions (graphics, sounds and so on) which I use in several of my
projects. Here I have included only the parts relevant to the shallow
water demo (which is mostly the graphics functionality and Guichan
interfacing in this case).

2) Guichan -- This is an open source GUI library which was used to
create the buttons and sliders at the right-hand side of the screen.

3) Shallow_Water -- This is the main project containing the shallow
water simulations. Briefly, the main files are as follows:

 - engine.cpp -- Main "engine" for the simulation, contains all the
   code that drives the GPU. The bulk of the code is found here.

 - kp07.hlsl -- Contains shaders for doing the numerical simulation of
   the shallow water equations on the GPU.

 - shallow_water.fx -- Contains shaders for creating the graphical
   appearance of the land and water surfaces.

 - gui_manager.cpp -- Creates the GUI at the right-hand side of the
   screen.

 - settings.cpp -- Stores and manages simulation settings.

 - terrain_heightfield.cpp -- Contains formulas for determining the
   shape of the terrain.


# Version History

2025: Fixed some minor C++ compilation errors. Converted this README
file to Markdown (.md) format. Added the project to GitHub.

2012--2014: Original version(s). 


# Copyright / Legal Information

The Shallow Water Demo is copyright (C) Stephen Thompson, 2012-14.

Permission is granted to copy any of the files in the Shallow Water
Demo provided that the terms of the GNU General Public Licence,
Version 3, are followed. Please see GPL.txt for the full text of
this licence.

In addition, certain parts of this distribution, if separated from
the rest of the Shallow Water Demo, may be copied under alternative
licensing terms. These parts are:

* The "Guichan" library (contents of the "guichan_0.8.1" folder)
  which was not written by me and therefore comes with its own
  licensing terms. See README_Guichan.txt for details.

* The files in the "coercri" folder which has a separate licence
  (the Boost Software Licence version 1.0). The details of this
  licence can be found within the files themselves.


# Contact

I can be contacted by email at stephen@solarflare.org.uk.
