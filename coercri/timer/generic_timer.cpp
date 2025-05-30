/*
 * FILE:
 *   generic_timer.cpp
 *
 * AUTHOR:
 *   Stephen Thompson <stephen@solarflare.org.uk>
 *
 * CREATED:
 *   21-Oct-2011
 *   
 * COPYRIGHT:
 *   Copyright (C) Stephen Thompson, 2008 - 2013.
 *
 *   This file is part of the "Coercri" software library. Usage of "Coercri"
 *   is permitted under the terms of the Boost Software License, Version 1.0, 
 *   the text of which is displayed below.
 *
 *   Boost Software License - Version 1.0 - August 17th, 2003
 *
 *   Permission is hereby granted, free of charge, to any person or organization
 *   obtaining a copy of the software and accompanying documentation covered by
 *   this license (the "Software") to use, reproduce, display, distribute,
 *   execute, and transmit the Software, and to prepare derivative works of the
 *   Software, and to permit third-parties to whom the Software is furnished to
 *   do so, all subject to the following:
 *
 *   The copyright notices in the Software and this entire statement, including
 *   the above license grant, this restriction and the following disclaimer,
 *   must be included in all copies of the Software, in whole or in part, and
 *   all derivative works of the Software, unless such copies or derivative
 *   works are solely in the form of machine-executable object code generated by
 *   a source language processor.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
 *   SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
 *   FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
 *   ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 *
 */

#include "generic_timer.hpp"

#ifdef WIN32
#include <windows.h>
#ifdef min
#undef min
#endif
#ifdef max
#undef max
#endif
#endif

#ifdef __linux__
#include <time.h>
#include <unistd.h>
#endif

namespace Coercri {

    GenericTimer::GenericTimer()
    {
#ifdef WIN32
        // Apparently there are problems with QueryPerformanceCounter on some systems,
        // so we use timeBeginPeriod / timeGetTime / timeEndTime instead.
        // Request 1ms resolution.
        timeBeginPeriod(1);
#endif
    }

    GenericTimer::~GenericTimer()
    {
#ifdef WIN32
        timeEndPeriod(1);
#endif        
    }

    unsigned int GenericTimer::getMsec()
    {
#ifdef WIN32
        return timeGetTime();

#elif defined(__linux__)
        struct timespec now;
        clock_gettime(CLOCK_MONOTONIC, &now);
        return (now.tv_sec * 1000u) + (now.tv_nsec / 1000000u);

#else
#error "Timer not implemented for this operating system!"
#endif
    }    

    void GenericTimer::sleepMsec(int msec)
    {
#ifdef WIN32
        Sleep(msec);
#elif defined(__linux__)
        usleep(msec * 1000);
#endif
    }

}
