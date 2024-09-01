#ifndef KOKUA_KOKUASTREAMINFO_H
#define KOKUA_KOKUASTREAMINFO_H

#include "llfloater.h"

class KokuaFloaterStreamInfo : public LLFloater
{
    friend class LLFloaterReg;
public:

    bool postBuild();
    static void UpdateStreamInfo(const std::string artist_title = "");
    KokuaFloaterStreamInfo(const LLSD& seed);
    virtual ~KokuaFloaterStreamInfo() {}
private:
};

#endif