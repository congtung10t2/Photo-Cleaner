# PhotoCleaner

An on-device iOS app that scans the photo library and groups:

- Duplicate photos (64-bit difference hash + Hamming-distance clustering)
- Junk photos with no clear subject (Vision classification + contour count + luminance statistics)
- Very short videos (0–1 s)
- Duplicate videos (thumbnail hash + dimensions + duration)

## Requirements

- Xcode 16+ (built and verified with Xcode 27 beta), iOS 17+ deployment target
- XcodeGen (`brew install xcodegen`) if you need to regenerate the project file

## Open and run

Open `PhotoCleaner.xcodeproj`, select the `PhotoCleaner` scheme, choose a device or simulator, and run. Grant photo library access on the first launch, then tap **Scan Photo Library**.

Before scanning, choose the amount: **100 items**, a **custom amount**, or **Full library** (the final option). Each scan analyzes that slice of the library; **Next N** continues from where the previous batch stopped, and results accumulate across batches. Scanned item IDs are saved with SwiftData, so later scans only check items that have not been analyzed yet. **Restart scanning** clears that history and checks everything again.

**Scan & Browse** (10/20 items per batch) scans a small batch and immediately opens a full-screen review of *every* picture in it — not just flagged ones — so you can remove any picture while reviewing, then scan the next batch. Deleted items go to **Recently Deleted**.

After scanning, choose an issue type or **All Issues** to review everything together, then tap thumbnails to select them. A "KEEP" badge marks the highest-resolution copy in each duplicate group. Enable **Review before deleting** to walk through each selected item full-screen and decide Keep or Delete individually; otherwise the standard confirmation dialog is used. **Swipe Review** walks through every flagged item instead: X removes it immediately, ✓ keeps it and moves on. Deleted items go to **Recently Deleted**.

## Regenerating the Xcode project

Sources are listed in `project.yml`; the checked-in `.xcodeproj` is generated from it:

```bash
xcodegen generate
```

## Verification

```bash
xcodebuild -project PhotoCleaner.xcodeproj -scheme PhotoCleaner \
  -destination 'generic/platform=iOS Simulator' build

xcodebuild -project PhotoCleaner.xcodeproj -scheme PhotoCleaner \
  -destination 'platform=iOS Simulator,name=iPhone 17e' test
```

## Structure

- `PhotoCleaner/Services` — PhotoKit access, image hashing, Vision analysis, video analysis, scan orchestration, deletion
- `PhotoCleaner/Utilities` — pure rules (hamming distance, clustering, batch slicing, junk score, video thresholds) that are unit-tested
- `PhotoCleaner/Models` — asset descriptors, per-asset analysis, scan scope, issue groups, scan results
- `PhotoCleaner/Views` + `ViewModels` — SwiftUI UI, including scope selector and full-screen review flow

## Notes

- All analysis is local; no images leave the device.
- Junk detection is heuristic (low classification confidence, few contours, flat luminance). Review before deleting.
- Simulator photo libraries are limited; accurate results require a real device with a populated library.
