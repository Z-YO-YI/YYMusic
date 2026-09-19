# YYMusic local compatibility patch

Source: the published just_audio_windows 0.2.3 archive, not upstream master.
The original hosted archive SHA256 is recorded in upstream.json and was verified
before copying all 12 published files. MIT LICENSE and Windows CMakeLists.txt
retain the previously audited byte fingerprints. CHANGELOG.md gains a final LF;
all other upstream files are byte-identical except the patch described below.

YYMusic patch (Phase 7J13D / ADR-150): after a successful
concatenatingRemoveRange, call the existing broadcastState before acknowledging
the method. Removing played items can change CurrentItemIndex without changing
the current MediaPlaybackItem. Do not rely solely on CurrentItemChanged to
publish the new index. The existing broadcaster reads real WinRT state; no
index is invented, and no seek, pause, reload or extra player is introduced.

The Dart backend still rejects missing rebases, invalid/advancing indices,
errors and disposal. The source gate reconstructs and hashes the original file
after removing the exact annotated patch. Actual acceptance requires the
unchanged native sequence probe on a GitHub-built Windows Profile artifact.

Keep this delta minimal. Any upstream upgrade requires a new source, license,
native build and device review. Do not edit the global Pub cache. This local
package is not intended for publishing to pub.dev.
