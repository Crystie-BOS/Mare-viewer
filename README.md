# MARE Viewer

**A Full-Time Restrained Love Viewer for Second Life, designed for the mare roleplay community.**

---

## Important Disclaimer

> **This software is not provided or supported by Linden Lab, the makers of Second Life.**
>
> MARE Viewer is an independent third-party viewer. Use at your own risk.
>
> MARE Viewer is not affiliated with, endorsed by, or in any way connected to Linden Lab or its products.

---

## Adult Content and Age Notice

MARE Viewer is designed specifically for **adult consensual RLV (Restrained Love Viewer) roleplay** within Second Life, in the context of mare and pony roleplay communities that use RLV-capable collars.

- **This viewer is intended for adults aged 18 and over only.**
- It is not appropriate for general-purpose use or for underage users.
- It is designed for consensual restraint and submission roleplay. All use is subject to Second Life's Terms of Service and Community Standards.

---

## What is MARE Viewer?

MARE Viewer is a Full-Time Restrained Love Viewer (FTRLV) — a Second Life viewer in which RLV (Restrained Love Viewer) is always active and cannot be disabled by the user. It is built on the [Kokua viewer](https://github.com/NickyPerian/kokua), which is itself based on the official Linden Lab open source viewer.

MARE Viewer is designed for participants in mare and pony roleplay communities in Second Life, where a worn RLV collar controls the viewer's behavior. The viewer's deliberate limitations are features, not bugs — they are part of what makes consensual RLV roleplay work.

---

## Who is it for?

- Second Life users who participate in mare/pony roleplay
- Users who wear RLV-capable collars and want a viewer that enforces those restrictions fully
- Community owners and operators who want a viewer that is always in FTRLV mode

This viewer is **not** a general-purpose viewer and is not recommended for users who do not understand or consent to RLV restrictions.

---

## Feature Differences from Standard Viewers

The following features behave differently in MARE Viewer compared to a standard Second Life viewer. These differences are **intentional and permanent** — they cannot be toggled off by the user.

As required by the [Linden Lab Third-Party Viewer Policy Section 1c.3](https://secondlife.com/corporate/third-party-viewers), these limitations are disclosed here:

| Feature | Standard Viewer | MARE Viewer |
|---------|----------------|-------------|
| Friends list | Visible and functional | Hidden and displayed as offline/unavailable |
| Friend online/offline notifications | Shown as popups | Suppressed |
| Group messages | Shown normally | Suppressed when RLV IM blocking is active |
| Inbound IM popups | Shown normally | Suppressed when RLV IM blocking is active |
| Environment / sky settings | User can set a personal environment | Locked to sim/shared environment when collar sends `@setenv=n` |
| RLV mode | Optional, user can toggle | Always active, cannot be disabled |

These restrictions are deliberate design choices for the intended use case.

---

## Disclaimer / Not Affiliated with Linden Lab

MARE Viewer is an independent third-party viewer created under the [Linden Lab Third-Party Viewer Policy](https://secondlife.com/corporate/third-party-viewers).

- MARE Viewer is **not** made by, affiliated with, or supported by Linden Lab
- "Second Life" is a trademark of Linden Research, Inc.
- Linden Lab does not review, endorse, or certify third-party viewers

---

## Support

Please use [GitHub Issues](../../issues) to report bugs or ask questions. There is no official support channel beyond this repository.

---

## Building from Source

MARE Viewer is built using the same toolchain as Kokua and the Linden Lab viewer. Please refer to [Kokua's build documentation](https://github.com/NickyPerian/kokua) for the general build process.

Brief summary for Windows (Visual Studio 2022 / MSVC 17):

```
autobuild configure -A 64 -c ReleaseOS -- -DLL_TESTS:BOOL=OFF -DPACKAGE:BOOL=FALSE -DOPENAL:BOOL=TRUE -DRLV_ALWAYS_ON:BOOL=TRUE
autobuild build -A 64 -c ReleaseOS --no-configure
```

Set `AUTOBUILD_VARIABLES_FILE` to point to your viewer-build-variables file before running.

---

## License

MARE Viewer source code is licensed under the GNU Lesser General Public License v2.1 (LGPL-2.1), the same as the Linden Lab viewer and Kokua, in compliance with the [Linden Lab Third-Party Viewer Policy Section 3b](https://secondlife.com/corporate/third-party-viewers).

See [LICENSE](LICENSE) for the full license text.

---

## Links

- [Linden Lab Third-Party Viewer Policy](https://secondlife.com/corporate/third-party-viewers)
- [Kokua upstream repository](https://github.com/NickyPerian/kokua)
- [Linden Lab open source viewer](https://github.com/secondlife/viewer)
- [Linden Lab Privacy Policy](https://www.lindenlab.com/privacy)
