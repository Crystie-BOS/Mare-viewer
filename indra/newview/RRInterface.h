/**
 * @file RRInterface.h
 * @author Marine Kelley
 * @brief The header for all RLV features
 *
 * $LicenseInfo:firstyear=2004&license=viewerlgpl$
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

#ifndef LL_RRINTERFACE_H
#define LL_RRINTERFACE_H

#define RR_VIEWER_NAME "RestrainedLife"
#define RR_VIEWER_NAME_NEW "RestrainedLove"
// Looking for the version number? See RRInterfaceVersion.h

#define RR_PREFIX "@"
#define RR_SHARED_FOLDER "#RLV"
#define RR_RLV_REDIR_FOLDER_PREFIX "#RLV/~"
// Length of the "#RLV/" string constant in characters.
#define RR_HRLVS_LENGTH 5

// Set to 1 for Tattoo and Alpha wearables support
#define ALPHA_AND_TATTOO 1

#define EXTREMUM 1000000.f

#define ALPHA_ALMOST_OPAQUE 0.99f

// wearable types as strings
#define WS_ALL "all"
#define WS_EYES "eyes"
#define WS_SKIN "skin"
#define WS_SHAPE "shape"
#define WS_HAIR "hair"
#define WS_GLOVES "gloves"
#define WS_JACKET "jacket"
#define WS_PANTS "pants"
#define WS_SHIRT "shirt"
#define WS_SHOES "shoes"
#define WS_SKIRT "skirt"
#define WS_SOCKS "socks"
#define WS_UNDERPANTS "underpants"
#define WS_UNDERSHIRT "undershirt"
#if ALPHA_AND_TATTOO
#define WS_ALPHA "alpha"
#define WS_TATTOO "tattoo"
#define WS_PHYSICS "physics"
#endif

//#include <set>
#include <deque>
#include <map>
#include <string>

#include "lluuid.h"
#include "llframetimer.h"

#include "llchat.h"
#include "llchatbar.h"
#include "llparcel.h"
#include "llinventorymodel.h"
#include "llviewermenu.h"
#include "llviewerjointattachment.h"
#include "llviewertexture.h"
#include "llwearable.h"
#include "llwearabletype.h"
#include "rlveffects.h"

#include "v3dmath.h"

extern bool gRRenabled;

// RLV retains its restrictions in a multimap (i.e. several entries per key), linking the restrictions to the UUIDs of the objects
typedef std::multimap<std::string, std::string> RRMAP;
typedef struct Command {
    LLUUID uuid;
    std::string command;
} Command;

// Where to attach what, when automatically reattaching an object
typedef struct AssetAndTarget {
    LLUUID uuid;
    std::string attachpt;
} AssetAndTarget;

// How to call @attach:outfit=force (useful for multi-attachments and multi-wearables
typedef enum AttachHow {
    AttachHow_replace           = 0, // default behavior
    AttachHow_under             = 1, // unusued for now
    AttachHow_over              = 2, // add on top
    AttachHow_over_or_replace   = 3, // stack if the name of the outfit begins with a special sign, otherwise replace
    AttachHow_count             = 4
} AttachHow;

// Type of the lock of a folder
typedef enum FolderLock {
    FolderLock_unlocked                 = 0, // not locked
    FolderLock_locked_with_except       = 1, // locked but with exception (i.e. will be treated as unlocked)
    FolderLock_locked_without_except    = 2, // locked without exception
    FolderLock_count                    = 3
} FolderLock;

class RRInterface
{
public:

    RRInterface ();
    ~RRInterface ();

    std::string getVersion (); // returns "RestrainedLife Viewer blah blah"
    std::string getVersion2 (); // returns "RestrainedLove Viewer blah blah"
    std::string getVersionNum (); // returns "RR_VERSION_NUM[,blacklist]"
    std::string getFirstName (std::string fullName);
    std::string getLastName (std::string fullName);
    bool isAllowed (LLUUID object_uuid, std::string action, bool log_it = true);
    bool contains (std::string action); // return true if the action is contained
    //KKA-829 This used to match at any position, giving a false positive for 'action' in 'notify:100;action' - this fix redefines it to match from index 0
    bool containsSubstr (std::string action); // return true if the action, or an action which name contains the specified name, is contained, matching from index 0
    std::string get (LLUUID object_uuid, std::string action, std::string dflt = ""); // returns the value of the @action:...=n restriction, if any (otherwise return the specified default)
    F32 getMax (std::string action, F32 dflt = EXTREMUM); // returns the max value of all the @action:...=n restrictions
    F32 getMin (std::string action, F32 dflt = -EXTREMUM); // returns the min value of all the @action:...=n restrictions
    LLColor3 getMixedColors (std::string action, LLColor3 dflt = LLColor3::black); // return the product of all the colors specified by actions "action"
    bool containsWithoutException (std::string action, std::string except = ""); // return true if the action or action+"_sec" is contained, and either there is no global exception, or there is no local exception in the case of action+"_sec"
    bool isFolderLocked(LLInventoryCategory* cat); // return true if cat has a lock specified for it or one of its parents, or not shared and @unshared is active
    FolderLock isFolderLockedWithoutException (LLInventoryCategory* cat, std::string attach_or_detach); // attach_or_detach must be equal to either "attach" or "detach"
    FolderLock isFolderLockedWithoutExceptionAux (LLInventoryCategory* cat, std::string attach_or_detach, std::deque<std::string> list_of_restrictions); // auxiliary function to isFolderLockedWithoutException
    bool isBlacklisted (std::string action, bool force); // return true if the command is blacklisted, with %f in the case of a "=force" command
    std::deque<std::string> getBlacklist (std::string filter = ""); // return the list of blacklisted commands which contain the substring specified by filter

    bool add (LLUUID object_uuid, std::string action, std::string option); // add a restriction
    bool remove (LLUUID object_uuid, std::string action, std::string option); // remove a restriction
    bool clear (LLUUID object_uuid, std::string command=""); // clear restrictions
    void replace (LLUUID what, LLUUID by); // replace a list of restrictions by restrictions linked to another UUID
    bool garbageCollector (bool all=true); // if false, don't clear rules attached to NULL_KEY as they are issued from external objects (only cleared when changing parcel)
    std::deque<std::string> parse (std::string str, std::string sep, int size_min = 0); // utility function (size_min can be specified to make sure the returned list is at least this size)
    void notify (LLUUID object_uuid, std::string action, std::string suffix); // scan the list of restrictions, when finding "notify" say the action on the specified channel

    bool parseCommand (std::string command, std::string& behaviour, std::string& option, std::string& param);
    bool handleCommand (LLUUID uuid, std::string command);
    bool fireCommands (); // execute commands buffered while the viewer was initializing (mostly useful for force-sit as when the command is sent the object is not necessarily rezzed yet)
    bool force (LLUUID object_uuid, std::string command, std::string option);
    void removeItemFromAvatar(LLViewerInventoryItem* item);

    bool answerOnChat (std::string channel, std::string msg);
    std::string crunchEmote (std::string msg, unsigned int truncateTo = 0);

    std::string getOutfitLayerAsString (LLWearableType::EType layer);
    LLWearableType::EType getOutfitLayerAsType (std::string layer);
    std::string getOutfit (std::string layer);
    std::string getAttachments (std::string attachpt);

    std::string getStatus (LLUUID object_uuid, std::string rule); // if object_uuid is null, return all
    bool forceDetach (std::string attachpt);
    bool forceDetachByUuid (std::string object_uuid);

    bool hasLockedHuds ();
    std::deque<LLInventoryItem*> getListOfLockedItems (LLInventoryCategory* root);
    std::deque<std::string> getListOfRestrictions (LLUUID object_uuid, std::string rule = "");
    std::string getInventoryList (std::string path, bool withWornInfo = false);
    std::string getWornItems (LLInventoryCategory* cat);
    LLInventoryCategory* getRlvShare (); // return pointer to #RLV folder or null if does not exist
    bool isUnderRlvShare (LLInventoryItem* item);
    bool isUnderRlvShare (LLInventoryCategory* cat);
    bool isUnderFolder (LLInventoryCategory* cat_parent, LLInventoryCategory* cat_child); // true if cat_child is a child of cat_parent
//  void renameAttachment (LLInventoryItem* item, LLViewerJointAttachment* attachment); // DEPRECATED
    LLInventoryCategory* getCategoryUnderRlvShare (std::string catName, LLInventoryCategory* root = NULL);
    LLInventoryCategory* findCategoryUnderRlvShare (std::string catName, LLInventoryCategory* root = NULL);
    std::deque<LLInventoryCategory*> findCategoriesUnderRlvShare(std::string catName, LLInventoryCategory* root = NULL);
    std::string findAttachmentNameFromPoint(LLViewerJointAttachment* attachpt);
    LLViewerJointAttachment* findAttachmentPointFromName (std::string objectName, bool exactName = false);
    LLViewerJointAttachment* findAttachmentPointFromParentName (LLInventoryItem* item);
    S32 findAttachmentPointNumber (LLViewerJointAttachment* attachment);
//  bool handle_detach_from_avatar(LLViewerJointAttachment* attachment);
    void detachObject(LLViewerObject* object);
    void detachAllObjectsFromAttachment(LLViewerJointAttachment* attachment);
    bool canDetachAllObjectsFromAttachment(LLViewerJointAttachment* attachment);
    void fetchInventory (LLInventoryCategory* root = NULL);

    bool forceAttach (std::string category, bool recursive, AttachHow how);
    bool forceDetachByName (std::string category, bool recursive);

    bool getAllowCancelTp() { return mAllowCancelTp; }
    void setAllowCancelTp(bool newval) { mAllowCancelTp = newval; }

    bool getScriptsEnabledOnce () { return mScriptsEnabledOnce; }
    void setScriptsEnabledOnce (bool newval) { mScriptsEnabledOnce = newval; }

    bool forceTeleport(std::string location, const LLVector3& vecLookAt);
    static void forceTeleportCallback(U64 hRegion, const LLVector3& posRegion, const LLVector3& vecLookAt);

    std::string stringReplace(std::string s, std::string what, std::string by, bool caseSensitive = false);
    std::string stringReplaceWholeWord(std::string s, std::string what, std::string by, bool caseSensitive = false); // same as stringReplace, but checks for neighbors of the occurrences of "what", and replace only if these neighbors are NOT alphanum characters
    // KKA-630 this is now calls getCensoredMessage to get exceptions dealt with
    std::string getDummyName (std::string name, EChatAudible audible = CHAT_AUDIBLE_FULLY); // return "someone", "unknown" etc according to the length of the name (when shownames is on)
    std::string getCensoredMessage (std::string str); // replace names by dummy names

    LLUUID getSitTargetId () { return mSitTargetId; }
    void setSitTargetId (LLUUID newval) { mSitTargetId = newval; }

    bool forceEnvironment (std::string command, std::string option); // command is "setenv_<something>", option is a list of floats (separated by "/")
    std::string getEnvironment (std::string command); // command is "getenv_<something>"

    std::string getLastLoadedPreset () { return mLastLoadedPreset; }
    void setLastLoadedPreset (std::string newval) { mLastLoadedPreset = newval; }

    bool forceDebugSetting (std::string command, std::string option); // command is "setdebug_<something>", option is a list of values (separated by "/")
    std::string getDebugSetting (std::string command); // command is "getdebug_<something>"

    std::string getFullPath (LLInventoryCategory* cat);
    std::string getFullPath (LLInventoryItem* item, std::string option = "", bool full_list = true);
    LLInventoryItem* getItemAux (LLViewerObject* attached_object, LLInventoryCategory* root);
    LLInventoryItem* getItem (LLUUID wornObjectUuidInWorld);
    void attachObjectByUUID (LLUUID assetUUID, int attachPtNumber = 0);

    bool canDetachAllSelectedObjects();
    bool isSittingOnAnySelectedObject();

    bool canAttachCategory(LLInventoryCategory* folder, bool with_exceptions = true);
    bool canAttachCategoryAux(LLInventoryCategory* folder, bool in_parent, bool in_no_mod, bool with_exceptions = true);
    bool canDetachCategory(LLInventoryCategory* folder, bool with_exceptions);
    bool canDetachCategoryAux(LLInventoryCategory* folder, bool in_parent, bool in_no_mod, bool with_exceptions);
    bool canUnwear(LLInventoryItem* item);
    bool canUnwear(LLWearableType::EType type);
    bool canWear(LLInventoryItem* item);
    bool canWear(LLWearableType::EType type, bool from_server = false);
    bool canDetach(LLInventoryItem* item);
    bool canDetach(LLViewerObject* attached_object); // CA: Now a veneer around canDetachWithExplanation
    std::string canDetachWithExplanation(LLViewerObject* attached_object); //CA: This is the original function with expanded return information. Original function name now a veneer
    bool canDetach(std::string attachpt); // CA: Now a veneer around canDetachWithExplanation
    std::string canDetachWithExplanation(std::string attachpt); //CA: This is the original function with expanded return information. Original function name now a veneer
    bool canAttach(LLViewerObject* object_to_attach, std::string attachpt, bool from_server = false); //CA: Now a veneer around canAttachWithExplanation
    std::string canAttachWithExplanation(LLViewerObject* object_to_attach, std::string attachpt, bool from_server = false); // CA: This is the original function with expanded return information
    bool canAttach(LLInventoryItem* item, bool from_server = false);
    bool canEdit(LLViewerObject* object);
    bool canTouch(LLViewerObject* object, LLVector3 pick_intersection = LLVector3::zero); // set pick_intersection to force the check on this position
    bool canTouchFar(LLViewerObject* object, LLVector3 pick_intersection = LLVector3::zero); // set pick_intersection to force the check on this position

    bool scriptsEnabled(); // returns true if scripts are enabled for us in this parcel

    void printOnChat (std::string message);
    void listRlvRestrictions(std::string substr = "");
    std::string getRlvRestrictions(std::string substr = "");

    bool checkCameraLimits (bool and_correct = false);
    bool updateCameraLimits ();
    void drawRenderLimit (bool force_opaque = false);
    void drawSphere (LLVector3 center, F32 scale, LLColor3 color, F32 alpha);

    bool updateSetsphere(); // call when receiving any @setsphere-related command (this is a feature from RLVa)

    void updateLimits();

    LLJoint* getCamDistDrawFromJoint (bool force_head_in_mouselook = true); // if force_head_in_mouselook is true, then the returned joint will be the head when the user is in mouselook, no matter what joint is actually chosen

    bool isInventoryItemNew(LLInventoryItem* item); // Return true if the item or its parent category has been received during this session
    bool IsInventoryFolderNew(LLInventoryCategory* folder); // Return true if the folder has been received during this session


    // Some cache variables to accelerate common checks
    bool mHasLockedHuds;
    bool mContainsDetach;
    bool mContainsShowinv;
    bool mContainsUnsit;
    bool mContainsStandtp;
    bool mContainsInteract;
    bool mContainsShowworldmap;
    bool mContainsShowminimap;
    bool mContainsShowloc;
    bool mContainsShownames;
    bool mContainsSetenv;
    bool mContainsSetdebug;
    bool mContainsFly;
    bool mContainsEdit;
    bool mContainsRez;
    bool mContainsShowhovertextall;
    bool mContainsShowhovertexthud;
    bool mContainsShowhovertextworld;
    bool mContainsDefaultwear;
    bool mContainsPermissive;
    bool mContainsRun;
    bool mContainsAlwaysRun;
    bool mContainsTp;
    bool mContainsCamTextures;
    bool mContainsShownametags;
    bool mContainsSetsphere;
    // CA
    bool mContainsViewScript;
    bool mContainsShowNearby;
    bool mContainsTouchattach;
    bool mContainsTouchattachself;
    bool mContainsTouchattachother;
    bool mContainsTouchhud;
    bool mContainsTouchall;
    bool mContainsViewNote;
    bool mContainsViewTexture;
    bool mContainsCamunlock; // don't use this, use mContainsLockedCamera
    bool mContainsSetcamUnlock; // don't use this, use mContainsLockedCamera
    bool mContainsLockedCamera; // this combines camunlock and setcam_unlock

    bool mHandleNoStrip;
    //bool mContainsMoveUp;
    //bool mContainsMoveDown;
    //bool mContainsMoveForward;
    //bool mContainsMoveBackward;
    //bool mContainsMoveTurnUp;
    //bool mContainsMoveTurnDown;
    //bool mContainsMoveTurnLeft;
    //bool mContainsMoveTurnRight;
    //bool mContainsMoveStrafeLeft;
    //bool mContainsMoveStrafeRight;

    F32 mCamZoomMax;
    F32 mCamZoomMin;
    F32 mCamDistMax;
    F32 mCamDistMin;
    F32 mCamDistDrawMax;
    F32 mCamDistDrawMin;
    LLColor3 mCamDistDrawColor;
    F32 mCamDistDrawAlphaMin;
    F32 mCamDistDrawAlphaMax;
    F32 mShowavsDistMax;
    F32 mTplocalMax;
    F32 mSittpMax;
    F32 mFartouchMax;
    F32 mSetsphereDistMin; // KKA-835 added
    F32 mSetsphereDistMax; // KKA-835 added
    F32 mSetsphereValueMax; // KKA-835 added
    F32 mLeastDistMaxSquared; // KKA-835 let's do the work here rather than every time in rendering
    F32SecondsImplicit mFirstFullyVisibleAt;

    LLViewerFetchedTexture* mCamTexturesCustom;

    std::string mParcelName; // for convenience (gAgent does not retain the name of the current parcel)
    LLParcel::ELandingType mParcelLandingType; // for convenience

    static bool sRRNoSetEnv;
    static bool sRestrainedLoveDebug; // was used to also control LL_INFOS() usage, now only controls the 'executes/fails command' chat feedback
    static bool sRestrainedLoveCommandLogging; // KKA-901 minimal always-on logging to aid in crash hunting, renamed and made switchable KKA-914
    static bool sRestrainedLoveLogging; // this controls the generation of LL_INFOS() output, previously controlled by RESTRAINEDLOVEDEBUG too
    static bool sRestrainedLoveHeadMouselookRenderRigged; // cached boolean
    static bool sCanOoc; // when true, the user can bypass a sendchat restriction by surrounding with (( and ))
    static std::string sRecvimMessage; // message to replace an incoming IM, when under recvim
    static std::string sSendimMessage; // message to replace an outgoing IM, when under sendim
    static std::string sBlacklist; // comma-separated list of RLV commands, add "%f" after a token to indicate it is the "=force" variant
    static F32 sLastOutfitChange; // timestamp of the last change in the outfit (including Hover on the shape)
    static U32 mCamDistNbGradients; // number of spheres to draw when restricting the camera view
    static bool sRenderLimitRenderedThisFrame; // true when already rendered the vision spheres during this rendering frame

    // Allowed debug settings (initialized in the ctor)
    std::deque<std::string> mAllowedGetDebug;
    std::deque<std::string> mAllowedSetDebug;

    // These should be private but we may want to browse them from the outside world, so let's keep them public
    RRMAP mSpecialObjectBehaviours;
    std::deque<Command> mRetainedCommands; // list of commands to execute later
    std::deque<std::string> mReceivedInventoryObjects; // list of inventory objects (items or folders) received during this session

    // When a locked attachment is kicked off by another one with llAttachToAvatar() in a script, retain its UUID here, to reattach it later
    std::deque<AssetAndTarget> mAssetsToReattach;
    LLFrameTimer mReattachTimer; // Reset each time a locked attachment is kicked by a "Wear", and on auto-reattachment timeout.
    bool mReattaching; // true when llappviewer.cpp asked for a reattachment. false when llviewerjointattachment.cpp detected a reattachment.
    bool mReattachTimeout; // true when llappviewer.cpp detects a reattachment timeout, false when llviewerjointattachment.cpp detected a reattachment.
    AssetAndTarget mJustDetached; // we need this to inhibit the removeObject event that occurs right after addObject in the case of a replacement
    AssetAndTarget mJustReattached; // we need this to inhibit the removeObject event that occurs right after addObject in the case of a replacement
    LLVector3d mLastStandingLocation; // this is the global position we had when we sat down on something, and we will be teleported back there when we stand up if we are prevented from "sit-tp by rezzing stuff"
    LLUUID mLastObjectSatOn; // UUID of object we are sitting on, or of the object we are standing up from, for standtp to know where to TP us
    bool mSnappingBackToLastStandingLocation; // true when we are teleporting back to the last standing location, in order to bypass the usual checks
    bool mUserUpdateAttachmentsUpdatesAll; // true when we've just called "Replace CurrentOutfit" and "Remove From Current Outfit" commands, false otherwise
    bool mUserUpdateAttachmentsCalledFromScript; // true when we're doing a @detachall (which now uses the "Remove From Current Outfit" method), false otherwise
    bool mUserUpdateAttachmentsFirstCall; // true the first time the method LLAgentWearables::userUpdateAttachments() is called, false afterwards
    bool mUserUpdateAttachmentsCalledManually; // true when we just did a "Add to Current Outfit" or "Replace Current Outfit", false otherwise

    LLJoint* mCamDistDrawFromJoint; // mHeadp by default, but we can set it to another joint so the user can "see" the world with vision spheres centered around that joint instead of around the head.

    bool mGarbageCollectorCalledOnce; // true when the garbageCollector() method has been called at least once since the beginning of the session

    bool mVisionRestricted; // this boolean is just a way to accelerate the chack "is our vision restricted ?" KKA-835 - now includes setsphere
    static F32 previousEastAngle; // remember it since we can't reliably read it back
    static F32 previousSunMoonPosition ; // remember it since we can't reliably read it back

    bool mSitGroundOnStandUp; // when true, automatically sit down on the ground when we're done standing up from an object (this is used for the @sitground command which must be asynchronous)

// CA KKA-915 - need to retain hooks in the latest porting of FS profiles and FS legacy search
    // WARNING: Don't rely on this to give accurate state for whether a particular restriction is on or off overall. Use it instead as a
    // hint that more detailed processing is necessary because state might have changed and then read the state explicitly.
    //
    // The behaviour signal is triggered whenever a command is successfully processed and resulted in adding or removing a behaviour
    typedef boost::signals2::signal<void (std::string, bool)> rlv_behaviour_signal_t;
    boost::signals2::connection setBehaviourCallback(const rlv_behaviour_signal_t::slot_type& cb )       { return m_OnBehaviour.connect(cb); }
protected:
    rlv_behaviour_signal_t m_OnBehaviour;
//CA
private:
    bool mScriptsEnabledOnce; // to know if we have been in a script enabled area at least once (so that no-script areas prevent detaching only when we have logged in there)
    bool mInventoryFetched; // false at first, used to fetch RL Share inventory once upon login
    bool mAllowCancelTp; // true unless forced to TP with @tpto (=> receive TP order from server, act like it is a lure from a Linden => don't show the cancel button)
    LLUUID mSitTargetId;
    std::string mLastLoadedPreset; // contains the name of the latest loaded Windlight preset
    int mLaunchTimestamp; // timestamp of the beginning of this session
    bool reallyHandleCommand (LLUUID uuid, std::string command);    // CA: the public handleCommand is now a veneer so that we can do debug output cleanly for all callers, not just chat handling
    void doRefreshEnabledState(); // gather three identical bits of code into one
};


#endif
