
2026.11.03

#### First release of the new CI system.
* Moved to a new xserver release: 25.1.11
  - 25.1.10 has been skipped due to few bugs found in early release.
  - [Release link.](https://github.com/X11Libre/xserver/releases/tag/xlibre-xserver-25.1.11)

- Added the new GHA CI system to the repository.
  - Automatic repository releases with new VERSION file records.
  - Rebuild-less auto repackaging of the conflicting/broken KDE package.
  - No dependency on any GitHub actions.
  - Lots of build information provided in build summaries and release notes.
  - \+ More...

2026.11.02

First anchor version for the upcoming new CI system.

This file is planned to be used as follows:

This file is supposed to hold a reverse chronological list of "Version Record"s
separated by ASCII group separator (GS).

"Version Record" is a string of text in this format:
["White-space"] "Version" ["\n" ["Version Description (Markdown)"]]

"Version" is the actual calender based version of the release in the following
format (Can be generated with date "+%Y.%m.%d"):
YYYY.MM.DD[.same-day-patch]  

Every time the top version record in this file gets terminated with a GS char,
a new release should be automatically built, tagged and drafted by the CI for
that version.
