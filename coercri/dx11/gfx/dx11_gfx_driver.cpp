/*
 * FILE:
 *   dx11_gfx_driver.cpp
 *
 * AUTHOR:
 *   Stephen Thompson <stephen@solarflare.org.uk>
 *
 * CREATED:
 *   18-Oct-2011
 *
 * COPYRIGHT:
 *   Copyright (C) Stephen Thompson, 2008 - 2011.
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

#include "dx11_gfx_driver.hpp"
#include "dx11_graphic.hpp"
#include "dx11_window.hpp"
#include "primitive_batch.hpp"
#include "../core/dx_error.hpp"
#include "../core/load_dx11_dlls.hpp"
#include "../../gfx/pixel_array.hpp"

#include "boost/scoped_array.hpp"

#include <map>

#include <windows.h>
#ifdef MB_RIGHT
#undef MB_RIGHT
#endif

namespace Coercri {

    extern std::string g_win_proc_error_msg;

    namespace {
        struct CmpDisplayMode {
            bool operator()(const GfxDriver::DisplayMode &lhs, const GfxDriver::DisplayMode &rhs) const
            {
                return
                    lhs.width < rhs.width ? true :
                    lhs.width > rhs.width ? false :
                    lhs.height < rhs.height;
            }
        };

        struct EqDisplayMode {
            bool operator()(const GfxDriver::DisplayMode &lhs, const GfxDriver::DisplayMode &rhs) const
            {
                return lhs.width == rhs.width
                    && lhs.height == rhs.height;
            }
        };
    }
    
    //
    // Constructor (and related functions)
    //
    
    DX11GfxDriver::DX11GfxDriver(D3D_DRIVER_TYPE driver_type,
                                 UINT flags,
                                 D3D_FEATURE_LEVEL feature_level)
        : icon_id(-1)
    {        
        // Open DirectX
        if (!LoadDX11()) {
            throw CoercriError("DirectX 11 is not available on this machine.");
        }
        
        // Create device
        createDevice(driver_type, flags, feature_level);

        // Find the default display adapter
        IDXGIAdapter *pAdapter = 0;
        HRESULT hr = m_psFactory->EnumAdapters(0, &pAdapter);
        if (FAILED(hr)) {
            throw DXError("IDXGIFactory::EnumAdapters failed", hr);
        }
        ComPtrWrapper<IDXGIAdapter> psAdapter(pAdapter);

        // Find the primary "output" (i.e. monitor) on this adapter
        IDXGIOutput *pOutput = 0;
        hr = pAdapter->EnumOutputs(0, &pOutput);
        if (FAILED(hr)) {
            throw DXError("IDXGIAdapter::EnumOutputs failed", hr);
        }
        m_psOutput.reset(pOutput);
        
        // Setup the PrimitiveBatch class
        m_psPrimitiveBatch.reset(new PrimitiveBatch(m_psDevice.get(), m_psDeviceContext.get()));
    }
        
    // Create the D3D device and immediate context
    void DX11GfxDriver::createDevice(D3D_DRIVER_TYPE driver_type,
                                     UINT flags,
                                     D3D_FEATURE_LEVEL feature_level)
    {
        ID3D11Device *pDevice = 0;
        D3D_FEATURE_LEVEL dummy_feature_level;
        ID3D11DeviceContext *pDeviceContext = 0;
        HRESULT hr = D3D11CreateDevice_Wrapper(0,   // use default adapter
                                               driver_type,
                                               0,  // no software rasterizer DLL available
                                               flags,   // whether to enable debug mode
                                               &feature_level,
                                               1,  // number of feature levels
                                               D3D11_SDK_VERSION,
                                               &pDevice,
                                               &dummy_feature_level,
                                               &pDeviceContext);
        if (FAILED(hr)) {
            throw DXError("D3D11CreateDevice failed", hr);
        }

        m_psDevice.reset(pDevice);
        m_psDeviceContext.reset(pDeviceContext);

        // Get the factory (will be needed later when we create a swap chain)
        IDXGIDevice * pDXGIDevice;
        hr = m_psDevice->QueryInterface(__uuidof(IDXGIDevice), (void **)&pDXGIDevice);
        if (FAILED(hr)) {
            throw DXError("QueryInterface for IDXGIDevice failed", hr);
        }
        ComPtrWrapper<IDXGIDevice> psDXGIDevice(pDXGIDevice); // ensure it gets Released
      
        IDXGIAdapter * pDXGIAdapter;
        hr = pDXGIDevice->GetParent(__uuidof(IDXGIAdapter), (void **)&pDXGIAdapter);
        if (FAILED(hr)) {
            throw DXError("GetParent of DXGIDevice failed", hr);
        }
        ComPtrWrapper<IDXGIAdapter> psDXGIAdapter(pDXGIAdapter); // ensure it gets Released

        IDXGIFactory * pFactory;
        hr = pDXGIAdapter->GetParent(__uuidof(IDXGIFactory), (void **)&pFactory);
        if (FAILED(hr)) {
            throw DXError("GetParent of DXGIAdapter failed", hr);
        }
        m_psFactory.reset(pFactory);
    }

    DX11GfxDriver::DisplayMode DX11GfxDriver::getDesktopMode()
    {
        DXGI_OUTPUT_DESC output_desc;
        HRESULT hr = m_psOutput->GetDesc(&output_desc);
        if (FAILED(hr)) {
            throw DXError("IDXGIOutput::GetDesc failed", hr);
        }
        DisplayMode dm;
        dm.width = output_desc.DesktopCoordinates.right - output_desc.DesktopCoordinates.left;
        dm.height = output_desc.DesktopCoordinates.bottom - output_desc.DesktopCoordinates.top;
        return dm;
    }


    //
    // Destructor
    //

    DX11GfxDriver::~DX11GfxDriver()
    {
        m_psDeviceContext->ClearState();
    }


    //
    // Window creation
    //

    boost::shared_ptr<Window> DX11GfxDriver::createWindow(int width, int height,
                                                          bool resizable, bool fullscreen,
                                                          const std::string &title)
    {
        boost::shared_ptr<Window> win(new DX11Window(width, height, resizable, fullscreen, title, icon_id, *this));
        return win;
    }


    //
    // Graphic creation
    //

    boost::shared_ptr<Graphic> DX11GfxDriver::createGraphic(boost::shared_ptr<const PixelArray> pixels,
                                                            int hx, int hy)
    {
        if (pixels->getHeight() == 0 || pixels->getWidth() == 0) {
            throw CoercriError("Attempting to create zero-sized graphic");
        }

        boost::shared_ptr<Graphic> g(new DX11Graphic(m_psDevice.get(), pixels, hx, hy));
        return g;
    }


    //
    // Event handling
    //

    bool DX11GfxDriver::pollEvents()
    {
        bool did_something = false;
        
        // Process all available messages
        MSG msg;
        while (PeekMessage(&msg, 0, 0, 0, PM_REMOVE)) {
            did_something = true;

            TranslateMessage(&msg);
            DispatchMessage(&msg);  // this will call the window proc, and from there, window listeners will be called.

            std::string err_msg = g_win_proc_error_msg;
            g_win_proc_error_msg.clear();

            if (!err_msg.empty()) {
                // Exception occurred...
                throw CoercriError(std::string("Exception during WndProc: ") + err_msg);
            }
        }

        return did_something;
    }


    //
    // Windows icon handling
    //

    void DX11GfxDriver::setWindowsIcon(int resource_id)
    {
        icon_id = resource_id;
    }
        
}
