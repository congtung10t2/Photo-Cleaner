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

After scanning, choose an issue type, tap thumbnails to select them, and use **Delete selected**. A "KEEP" badge marks the highest-resolution copy in each duplicate group. Deleted items go to **Recently Deleted**.

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
- `PhotoCleaner/Utilities` — pure rules (hamming distance, clustering, junk score, video thresholds) that are unit-tested
- `PhotoCleaner/Models` — asset descriptors, issue groups, scan results
- `PhotoCleaner/Views` + `ViewModels` — SwiftUI UI

## Notes

- All analysis is local; no images leave the device.
- Junk detection is heuristic (low classification confidence, few contours, flat luminance). Review before deleting.
- Simulator photo libraries are limited; accurate results require a real device with a populated library.
