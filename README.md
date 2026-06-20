# High-Performance Feed

A highly optimized, infinite-scrolling social feed in Flutter, backed by Supabase.

## Submission Notes
This repository contains the complete implementation for the Flutter High-Performance Feed assignment. All deliverables and technical constraints have been successfully met, including:
- **State Management**: Optimistic UI using Riverpod (`AsyncNotifier`) and `RxDart` for debouncing spam clicks.
- **Memory Protection**: OOM prevention using `memCacheWidth` calculated via `MediaQuery.devicePixelRatio`.
- **GPU Protection**: Raster caching via `RepaintBoundary` to maintain 60/120fps during rapid scrolling despite heavy shadows.
- **Graceful Degradation**: Offline error handling and automatic state rollbacks.

---

## Deliverables Met

### Riverpod State Management Approach
The application utilizes **Riverpod** for robust, reactive state management, specifically focusing on an optimistic UI architecture. 
- **`FeedNotifier` (`AsyncNotifier`)**: Manages the feed's list of posts. It handles pagination through `fetchNextPage()` and pull-to-refresh via `refresh()`. It exposes an `updatePost` method to allow targeted local mutations.
- **`LikeService` (Optimistic UI & Debouncing)**: When a user taps "Like," the service instantly mutates the post's state via `FeedNotifier.updatePost`, providing immediate visual feedback (heart turns red, count increments). Concurrently, the action is dispatched to an `RxDart` `PublishSubject`.
- **Spam Clicker Prevention**: The `PublishSubject` groups events by `postId` and applies a `debounceTime` of 500ms. This ensures that if a user taps the button 15 times in 2 seconds, only the final network request is sent to the Supabase RPC, preventing database desynchronization and unnecessary network overhead.
- **Offline Revert**: If the Supabase RPC fails (e.g., the device is offline), the `LikeService` catches the exception, calculates the previous state, and rolls back the UI via `FeedNotifier`. It also updates an `ErrorNotifier`, which is actively listened to by the `FeedScreen` to display a user-friendly `SnackBar` indicating the failure.

### GPU & RAM Protection Implementations

#### RepaintBoundary (GPU Protection)
The `PostCard` widget features a heavy `BoxShadow` with a large blur radius to simulate a high-end UI design. To prevent the Flutter engine from continually recalculating this expensive shadow math during rapid scrolling (Jank Test), the entire card is wrapped in a `RepaintBoundary`. 
- **Verification**: By running the app in Profile mode and using Flutter DevTools (Performance view), we can observe that the raster thread is not overloaded during rapid scrolling, as the `RepaintBoundary` instructs the engine to cache the rasterized representation of the widget.

#### memCacheWidth (RAM Protection / OOM Prevention)
We use `CachedNetworkImage` to load the `media_thumb_url` in the feed. To ensure the decoded image footprint in RAM exactly matches the UI display size, we explicitly set the `memCacheWidth` property.
- **Calculation**: `final cacheWidth = (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).toInt();`
- **Verification**: Using the Flutter DevTools Memory Profiler, we can inspect the image cache footprint and confirm that the images are strictly bounded in memory, preventing Out-Of-Memory (OOM) crashes even when the infinite feed grows to hundreds of items.

### Hero Animation & Tiered Loading
Tapping a `PostCard` triggers a `Hero` animation to the `DetailScreen`. The detail screen immediately renders the cached `media_thumb_url` as a placeholder, whilst asynchronously fetching and fading in the `media_mobile_url` (1080x1080). A Floating Action Button is provided to explicitly fetch the `media_raw_url` (4K) only upon user request, saving cellular data.

## Getting Started

### 1. Configure Environment
Create a `.env` file in the root of the project:
```env
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_publishable_anon_key
```

### 2. Python Seeder (Optional)
If you need to seed the database, run the provided python script:
```bash
python3 -m venv venv
source venv/bin/activate
pip install supabase Pillow
# Add images to input_images/ and run:
python3 seed.py
```

### 3. Run the App
To accurately test the RepaintBoundary and memory management, it is recommended to run the app in profile mode (which prevents debug-mode jank):
```bash
flutter run --profile
```
