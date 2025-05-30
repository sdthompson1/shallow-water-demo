/*
 * FILE:
 *   bitmap_font.cpp
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

#include "bitmap_font.hpp"
#include "gfx_context.hpp"
#include "kern_table.hpp"
#include "pixel_array.hpp"

#include <cstring>

namespace Coercri {

    BitmapFont::BitmapFont(boost::shared_ptr<PixelArray> pixels)
    {
        std::memset(&characters[0], 0, sizeof(characters));
        
        const int w = pixels->getWidth();
        text_height = pixels->getHeight() - 1; // top row is not part of the font proper.

        int ch = 32;
        int ofs = 0;

        for (int i = 0; i < w; ++i) {
            const Color &pixel = (*pixels)(i, 0);
            if (pixel.r==255 && pixel.g==0 && pixel.b==255) {                
                
                if (ch != 32) {
                    // Normal (non-space) character
                    const int width = i - ofs;
                
                    characters[ch] = static_cast<Character*>(std::malloc(sizeof(Character) + width*text_height));
                    characters[ch]->width = width;
                    characters[ch]->height = text_height;
                    characters[ch]->xofs = characters[ch]->yofs = 0;
                    characters[ch]->xadvance = width;
                
                    for (int y = 0; y < text_height; ++y) {
                        for (int x = 0; x < width; ++x) {
                            const Color &col = (*pixels)(x + ofs, y + 1);
                            unsigned char a = 255;
                            if (col.r == 0 && col.g == 0 && col.b == 0) {
                                a = 0;
                            }
                            characters[ch]->pixels[y * width + x] = a;
                        }
                    }
                }

                if (ch == 33) {

                    // Spaces are a special case: width is determined
                    // from the offset of character 33, and no data is
                    // stored
                    
                    characters[32] = static_cast<Character*>(std::malloc(sizeof(Character)));
                    characters[32]->xadvance = ofs;
                }

                // Advance to next character
                ++ch;
                for (; i < w; ++i) {
                    const Color& pix2 = (*pixels)(i, 0);
                    if (pix2.r == 0 && pix2.g == 0 && pix2.b == 0) {
                        ofs = i;
                        break;
                    }
                }
            }
        }
    }

    BitmapFont::BitmapFont(boost::shared_ptr<KernTable> kern, int height)
        : kern_table(kern), text_height(height)
    {
        std::memset(&characters[0], 0, sizeof(characters));
    }

    void BitmapFont::setupCharacter(char c, int width, int height, int xofs, int yofs, int xadvance)
    {
        int ch = static_cast<int>(static_cast<unsigned char>(c));
        if (ch == 32) {
            characters[ch] = static_cast<Character*>(std::malloc(sizeof(Character)));
        } else {
            characters[ch] = static_cast<Character*>(std::calloc(sizeof(Character) + width*height, 1));
        }
        characters[ch]->width = width;
        characters[ch]->height = height;
        characters[ch]->xofs = xofs;
        characters[ch]->yofs = yofs;
        characters[ch]->xadvance = xadvance;
    }

    void BitmapFont::plotPixel(char c, int x, int y, unsigned char alpha)
    {
        int ch = static_cast<int>(static_cast<unsigned char>(c));

        if (ch == 0 || ch == 32) return;
        if (x < 0 || x >= characters[ch]->width) return;
        if (y < 0 || y >= characters[ch]->height) return;
        
        int idx = y * characters[ch]->width + x;
        characters[ch]->pixels[idx] = alpha;
    }
    
    BitmapFont::~BitmapFont()
    {
        for (int i = 0; i < 256; ++i) {
            if (characters[i]) {
                free(characters[i]);
            }
        }
    }
    
    void BitmapFont::drawText(GfxContext &dest, int x, int y, const std::string &text, Color col) const
    {
        bool use_input_alpha = (col.a != 255);
        int input_alpha = col.a;
        
        char previous = 0;

        static std::vector<Pixel> pixel_buf;
        pixel_buf.clear();
        
        for (std::string::const_iterator it = text.begin(); it != text.end(); ++it) {

            const char c = *it;

            if (c > 0 && c < 256) {

                // apply kerning if required
                if (previous && kern_table) {
                    x += kern_table->getKern(previous, c);
                }
                
                if (c != 32) {  // non-space character

                    const int width = characters[c]->width;
                    const int height = characters[c]->height;
                    const int xofs = characters[c]->xofs;
                    const int yofs = characters[c]->yofs;                    
                    
                    for (int j = 0; j < height; ++j) {
                        for (int i = 0; i < width; ++i) {
                            unsigned char font_alpha = characters[c]->pixels[j * width + i];
                            if (font_alpha > 0) {
                            
                                if (use_input_alpha) {
                                    col.a = static_cast<unsigned char>(int(font_alpha) * input_alpha / 255);
                                } else {
                                    col.a = font_alpha;
                                }

                                pixel_buf.push_back(Pixel(x + xofs + i, y + yofs + j, col));
                            }
                        }
                    }
                }
                
                x += characters[c]->xadvance;
                previous = c;
            }
        }

        if (!pixel_buf.empty()) {
            dest.plotPixelBatch(&pixel_buf[0], pixel_buf.size());
        }
    }

    void BitmapFont::getTextSize(const std::string &text, int &w, int &h) const
    {
        w = 0;
        char previous = 0;
        for (std::string::const_iterator it = text.begin(); it != text.end(); ++it) {
            const char c = *it;
            if (c > 0 && c < 256) {
                if (previous && kern_table) {
                    w += kern_table->getKern(previous, c);
                }
                w += characters[*it]->xadvance;
                previous = c;
            }
        }
        h = text_height;
    }

    int BitmapFont::getTextHeight() const
    {
        return text_height;
    }
}
