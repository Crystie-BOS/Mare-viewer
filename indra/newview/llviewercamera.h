/**
 * @file llviewercamera.h
 * @brief LLViewerCamera class header file
 *
 * $LicenseInfo:firstyear=2002&license=viewerlgpl$
 * Second Life Viewer Source Code
 * Copyright (C) 2010, Linden Research, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation;
 * version 2.1 of the License only.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Linden Research, Inc., 945 Battery Street, San Francisco, CA  94111  USA
 * $/LicenseInfo$
 */

#ifndef LL_LLVIEWERCAMERA_H
#define LL_LLVIEWERCAMERA_H

#include "llcamera.h"
#include "llsingleton.h"
#include "lltimer.h"
#include "m4math.h"
#include "llcoord.h"
#include "lltrace.h"
#include "glm/glm.hpp"

class LLViewerObject;
const bool FOR_SELECTION = true;
const bool NOT_FOR_SELECTION = false;

class alignas(16) LLViewerCamera : public LLCamera, public LLSimpleton<LLViewerCamera>
{
    LL_ALIGN_NEW
public:
    LLViewerCamera();

    typedef enum
    {
        CAMERA_WORLD = 0,
        CAMERA_SUN_SHADOW0,
        CAMERA_SUN_SHADOW1,
        CAMERA_SUN_SHADOW2,
        CAMERA_SUN_SHADOW3,
        CAMERA_SPOT_SHADOW0,
        CAMERA_SPOT_SHADOW1,
        CAMERA_WATER0,
        CAMERA_WATER1,
        NUM_CAMERAS
    } eCameraID;

    static eCameraID sCurCameraID;

    bool updateCameraLocation(const LLVector3 &center,
                                const LLVector3 &up_direction,
                                const LLVector3 &point_of_interest);

    static void updateFrustumPlanes(LLCamera& camera, bool ortho = false, bool zflip = false, bool no_hacks = false);
    void setPerspective(bool for_selection, S32 x, S32 y_from_bot, S32 width, S32 height, bool limit_select_distance, F32 z_near = 0, F32 z_far = 0);

    const LLMatrix4 &getProjection() const;
    const LLMatrix4 &getModelview() const;

    // Warning!  These assume the current global matrices are correct
    void projectScreenToPosAgent(const S32 screen_x, const S32 screen_y, LLVector3* pos_agent ) const;
    bool projectPosAgentToScreen(const LLVector3 &pos_agent, LLCoordGL &out_point, const bool clamp = true) const;
    bool projectPosAgentToScreenEdge(const LLVector3 &pos_agent, LLCoordGL &out_point) const;

    F32     getCosHalfFov() const { return mCosHalfCameraFOV; }
    F32     getAverageSpeed() const { return mAverageSpeed; }
    F32     getAverageAngularSpeed() const { return mAverageAngularSpeed; }
    LLVector3 getVelocityDir() const {return mVelocityDir;}
    static LLTrace::CountStatHandle<>* getVelocityStat()           {return &sVelocityStat; }
    static LLTrace::CountStatHandle<>* getAngularVelocityStat()  {return &sAngularVelocityStat; }

    void getPixelVectors(const LLVector3 &pos_agent, LLVector3 &up, LLVector3 &right);
    LLVector3 roundToPixel(const LLVector3 &pos_agent);

    // Sets the current matrix
    /* virtual */ void setView(F32 vertical_fov_rads); // NOTE: broadcasts to simulator
    void setViewNoBroadcast(F32 vertical_fov_rads);  // set FOV without broadcasting to simulator (for temporary local cameras)
    F32 getDefaultFOV() const { return mCameraFOVDefault; }
    void setDefaultFOV(F32 fov) ;

    bool isDefaultFOVChanged();

    bool cameraUnderWater() const;
    bool areVertsVisible(LLViewerObject* volumep, bool all_verts);

    const LLVector3& getPointOfInterest() const { return mLastPointOfInterest; }
    F32 getPixelMeterRatio() const              { return mPixelMeterRatio; }
    S32 getScreenPixelArea() const              { return mScreenPixelArea; }

    void setZoomParameters(F32 factor, S16 subregion) { mZoomFactor = factor; mZoomSubregion = subregion; }
    F32 getZoomFactor() const { return mZoomFactor; }
    S16 getZoomSubRegion() const { return mZoomSubregion; }

    // MARE: TAA / upscaler infrastructure (Phase 1)
    // Call once at the top of each frame (before setup3DRender) to capture the
    // previous VP matrix and advance the Halton jitter sequence.
    void beginFrame();
    F32  getJitterX() const              { return mJitterX; }
    F32  getJitterY() const              { return mJitterY; }
    const glm::mat4& getPrevViewProj() const { return mPrevViewProjMatrix; }
    bool hadCameraJump()  const              { return mCameraJumped; }      // MARE: Phase 2 Step 5
    bool getCameraMoved() const              { return mCameraMoved; }       // MARE: true when camera panned/walked this frame

protected:
    void calcProjection(const F32 far_distance) const;

    static LLTrace::CountStatHandle<> sVelocityStat;
    static LLTrace::CountStatHandle<> sAngularVelocityStat;

    LLVector3 mVelocityDir ;
    F32       mAverageSpeed ;
    F32       mAverageAngularSpeed ;
    mutable LLMatrix4   mProjectionMatrix;  // Cache of perspective matrix
    mutable LLMatrix4   mModelviewMatrix;
    F32                 mCameraFOVDefault;
    F32                 mPrevCameraFOVDefault;
    F32                 mCosHalfCameraFOV;
    LLVector3           mLastPointOfInterest;
    F32                 mPixelMeterRatio; // Divide by distance from camera to get pixels per meter at that distance.
    S32                 mScreenPixelArea; // Pixel area of entire window
    F32                 mZoomFactor;
    S16                 mZoomSubregion;

    // MARE: TAA / upscaler infrastructure (Phase 1)
    U32       mJitterFrame;         // Halton sequence counter; wraps naturally
    F32       mJitterX;             // sub-pixel NDC jitter X; 0 when upscaler disabled
    F32       mJitterY;             // sub-pixel NDC jitter Y; 0 when upscaler disabled
    glm::mat4 mPrevViewProjMatrix;  // view-projection matrix captured end of previous frame
    LLVector3 mPrevCamOrigin;       // MARE: Phase 2 Step 5 — camera world position at start of previous frame
    bool      mCameraJumped = false;// MARE: Phase 2 Step 5 — true when a teleport / jump was detected this frame
    bool      mCameraMoved  = false;// MARE: true when camera panned/walked this frame (TAA camera-cut trigger)

public:
};


#endif // LL_LLVIEWERCAMERA_H
