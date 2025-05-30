/*
 * FILE:
 *   gfx_context.cpp
 *
 * AUTHOR:
 *   Stephen Thompson <stephen@solarflare.org.uk>
 *
 * COPYRIGHT:
 *   Copyright (C) Stephen Thompson, 2008 - 2009.
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

#include "font.hpp"
#include "gfx_context.hpp"
#include "rectangle.hpp"

namespace Coercri {

    void GfxContext::drawLine(int x0, int y0, int x1, int y1, Color col)
    {
        // Use Bresenham's algorithm
        const bool steep = std::abs(y1 - y0) > std::abs(x1 - x0);
        if (steep) {
            std::swap(x0, y0);
            std::swap(x1, y1);
        }
        if (x0 > x1) {
            std::swap(x0, x1);
            std::swap(y0, y1);
        }
        const int deltax = x1 - x0;
        const int deltay = std::abs(y1 - y0);
        int y = y0;
        int error = 0;
        const int ystep = y0 < y1 ? 1 : -1;
        const int errstep = (deltay + deltay);
        const int errmax = (deltax + deltax);
        for (int x = x0; x <= x1; ++x) {
            if (steep) {
                plotPixel(y, x, col);
            } else {
                plotPixel(x, y, col);
            }
            error += errstep;
            if (error >= deltax) {
                y += ystep;
                error -= errmax;
            }
        }
    }

    void GfxContext::drawRectangle(const Rectangle &rect, Color col)
    {
        if (rect.isDegenerate()) return;

        const int left = rect.getLeft();
        const int right = rect.getRight() - 1;
        const int top = rect.getTop();
        const int bottom = rect.getBottom() - 1;

        if (top == bottom) {
            drawLine(left, top, right, top, col);
        } else if (left == right) {
            drawLine(left, top, left, bottom, col);
        } else {
            drawLine(left, top, right, top, col);
            drawLine(left, bottom, right, bottom, col);
            if (bottom > top+1) {
                drawLine(left, top+1, left, bottom-1, col);
                drawLine(right, top+1, right, bottom-1, col);
            }
        }
    }

    void GfxContext::fillRectangle(const Rectangle &rect, Color col)
    {
        if (rect.isDegenerate()) return;

        const int left = rect.getLeft();
        const int right = rect.getRight() - 1;

        for (int y = rect.getTop(); y < rect.getBottom(); ++y) {
            drawLine(left, y, right, y, col);
        }
    }

    void GfxContext::drawText(int x, int y, const Font &font, const std::string &text, Color col)
    {
        font.drawText(*this, x, y, text, col);
    }

    void GfxContext::plotPixelBatch(const Pixel *buf, int num_pixels)
    {
        for (int i = 0; i < num_pixels; ++i) {
            plotPixel(buf[i].x, buf[i].y, buf[i].col);
        }
    }
}
