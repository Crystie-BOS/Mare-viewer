#pragma once

// ─────────────────────────────────────────────────────────────────────────────
// IUpscaler  –  MARE Phase 3 abstract upscaler / TAA interface.
//
// Concrete backends derive from this class and implement the three pure-virtual
// methods.  The factory IUpscaler::create() returns the backend currently
// selected by viewer settings.
//
// Phase 3 Step 1 backend:  MARETAAUpscaler  (internal OpenGL TAA, no SDK)
// Phase 3 Step 2 backend:  MARENISUpscaler  (NIS – NVIDIA Image Scaling, spatial only)
// Phase 3 Step 3 backend:  MAREFSR2Upscaler (FSR 2 – AMD FidelityFX SR 2, temporal)
// ─────────────────────────────────────────────────────────────────────────────

#include "stdtypes.h"
#include <memory>

class LLRenderTarget;

class IUpscaler
{
public:
    virtual ~IUpscaler() = default;

    // Allocate (or reallocate) GPU resources at the given render resolution.
    // Call once on startup, and again whenever the window resizes.
    virtual bool initialize(U32 renderW, U32 renderH) = 0;

    // Release all GPU resources.  Safe to call even when not yet initialized.
    virtual void destroy() = 0;

    // Convenience: destroy() then initialize().
    virtual bool resize(U32 renderW, U32 renderH)
    {
        destroy();
        return initialize(renderW, renderH);
    }

    // Run the TAA / upscale pass for one frame.
    //
    //  colorSrc    – scene HDR color (already flushed; texture is readable).
    //               May be the SAME render target as outputDst; the
    //               implementation reads the TEXTURE first, then blits the
    //               final result into the FBO, so no GL conflict arises.
    //  depthSrc    – scene depth buffer (deferredScreen with depth attachment).
    //               Used by FSR 2 for reprojection.  Pass nullptr for TAA/NIS.
    //  velocitySrc – per-pixel NDC motion vectors (RG16F, Phase 2 velocity
    //               buffer).
    //  outputDst   – receives the temporally-accumulated result.
    //  jitterX/Y   – sub-pixel jitter applied to the current frame (NDC).
    //  cameraCut   – discard temporal history (teleport, first frame).
    virtual void apply(
        LLRenderTarget* colorSrc,
        LLRenderTarget* depthSrc,
        LLRenderTarget* velocitySrc,
        LLRenderTarget* outputDst,
        F32             jitterX,
        F32             jitterY,
        bool            cameraCut) = 0;

    // True while GPU resources are valid and apply() may be called.
    virtual bool isReady() const = 0;

    // Factory – returns the preferred backend.
    // Currently always returns a MARETAAUpscaler.
    static std::unique_ptr<IUpscaler> create();
};
