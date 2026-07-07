# UniLink

UniLink is a Flutter mobile application for university club discovery, event management, social engagement, and club communication.

The current version supports three user roles: university admin, club manager, and student. Students can discover clubs, follow clubs, request membership, register for events, interact with posts, save posts, chat privately, and join club text rooms. Club managers can manage the public club profile, posts, events, members, event registrations, room invitations, payment requests, and reusable media assets. University admins can manage clubs and users from an admin dashboard.

## Main Features

- Student authentication, editable profile information, gender avatar fallback, optional profile and cover images, privacy settings, media autoplay preferences, and notification preferences.
- Club discovery with follower/member separation, follow status, member visibility, follower visibility, membership requests, and clickable club identity rows across the app.
- Club profile management with logo, cover image, gallery photos, about text, feature/code display, logo background color, background video, background music, and separate auto-open/autoplay controls.
- Posts with images, YouTube video, uploaded video, optional music, per-post media auto controls, likes, comments, saved posts, share-to-chat actions, and editable/deletable comments.
- Event creation and editing with date, time, map location, capacity, fee/currency, optional Google Form link, optional registration text/file requirements, receipts, media, and per-event media auto controls.
- Event dashboard with planned/active/finished filters, registration status control, attendance, quick approval, payments, documents, and invitation panels.
- Direct person-to-person messages with unread indicators, message privacy, and post/event attachments.
- Club text rooms for members and managers, multiple room management, room invitations, event-based invitation groups, and shareable post/event attachments.
- Manager payment tools for monthly club payments and event fees with receipt upload/review flow.
- Admin dashboard for users and clubs, including editable club name/category and category selection or custom entry.
- Responsive light/dark theme UI with reusable cards, dialogs, lists, avatars, media fields, and paginated home loading.

## Compulsory Features

### Map Integration

`flutter_map` and `latlong2` are used for event location selection and display. The default map location is XMUM. Managers choose a location by tapping the map, and the selected latitude/longitude are saved with the event and shown again in event details.

### Multimedia Integration

UniLink supports several media types:

- Images selected with `image_picker`, encoded as Base64, and stored in Firestore for profiles, clubs, posts, events, receipts, and registration files.
- YouTube links displayed in-app through `youtube_player_flutter` with thumbnails and tap-to-play behavior.
- Uploaded videos and MP3/audio files selected with `file_picker`, uploaded through the Cloudinary unsigned upload preset, then displayed or played in the app through `video_player` and `just_audio`.
- Reusable media library records stored in Firestore through the `media_assets` collection. Managers can reuse previously saved videos/music in posts, events, and the club profile.
- Separate auto-open/autoplay flags are stored for club media and for post/event media. Student settings decide whether those manager-enabled behaviors are allowed on the viewer side.

### Data Persistence

Firebase Firestore stores profiles, clubs, follows, memberships, membership requests, posts, comments, saved posts, events, registrations, notifications, room chats, direct chats, payment records, and media library records. Services and model classes convert typed Dart objects to Firestore maps and back.

## Project Structure

```text
lib/
  config/                Cloudinary and environment-style app config
  core/                  Theme and shared app-level setup
  models/                Firestore-backed data models
  providers/             Auth, theme, follow, club, and notification state
  screens/
    admin/               Admin dashboard and admin widgets
    auth/                Login and sign-up screens
    chat/                Direct chat, room chat, room settings, and share sheets
    manager/             Club manager tabs, forms, dashboards, and media library
    splash/              Splash animation components
    student/             Home, clubs, events, profile, settings, saved posts
  services/              Firebase, chat, event, payment, media, and upload logic
  widgets/               Reusable cards, avatars, map, media, audio/video widgets
Reports/
  UniLink_Academic_Report.docx
  UniLink_Academic_Report_Text.md
  build_unilink_academic_report.py
```

Large UI surfaces have been split into focused components. Examples include `event_dashboard/`, `club_detail/`, `profile/`, `settings/`, `post_detail/`, `event_registration/`, `event_card/`, `post_card/`, `media_attachment/`, `club_profile/`, and chat room dashboard folders. Shared media UI now includes reusable publish media fields, content media display, auto media launching, and manager action banners.

## Setup

1. Install Flutter and configure an Android/iOS device or emulator.
2. Install dependencies:

```bash
flutter pub get
```

3. Configure Firebase for the target platform.
4. Configure media upload in `lib/config/cloudinary_config.dart`:

```dart
static const String cloudName = 'your_cloud_name';
static const String uploadPreset = 'your_unsigned_upload_preset';
```

5. Run the app:

```bash
flutter run
```

6. Verify code quality:

```bash
flutter analyze
```

## Firebase Collections

The app uses these main Firestore collections and subcollections:

- `profiles`
- `clubs`
- `user_follows`
- `user_saved_posts`
- `club_memberships`
- `club_membership_requests`
- `club_payment_requests`
- `club_payment_receipts`
- `posts`
- `posts/{postId}/comments`
- `events`
- `event_registrations`
- `notifications/{userId}/items`
- `club_rooms`
- `club_rooms/{roomId}/messages`
- `direct_chats`
- `direct_chats/{chatId}/messages`
- `media_assets`

Important Firestore rules note: the latest app features require rules for `media_assets` and `club_membership_requests`. If these are missing in the deployed Firebase rules, media library saving/renaming and membership requests will fail even when the UI is correct.

Suggested rule shape:

```js
match /media_assets/{assetId} {
  allow read: if signedIn();
  allow create: if signedIn() && isClubManager(request.resource.data.club_id);
  allow update, delete: if signedIn()
    && (isAdmin() || isClubManager(resource.data.club_id));
}

match /club_membership_requests/{requestId} {
  allow read: if signedIn();
  allow create: if signedIn()
    && request.resource.data.user_id == request.auth.uid;
  allow update, delete: if signedIn()
    && (isAdmin() || isClubManager(resource.data.club_id));
}
```

## Media Storage Notes

- Images are currently stored as Base64 strings in Firestore for this academic/project version.
- Uploaded video and audio files are stored externally through Cloudinary; Firestore stores only the returned secure URL and metadata.
- YouTube media stores only the YouTube URL.
- The media library stores reusable metadata in `media_assets`: club id, name, URL, media kind, source type, creator id, and created date.
- Existing media library items can be renamed in the app. Deleting Cloudinary files is intentionally not implemented because secure deletion should be done through a backend, not directly from the mobile app.

## Reports

The academic report source and generated Word files are in `Reports/`.

The main Word report path is:

```text
Reports/UniLink_Academic_Report.docx
```

If that file is open/locked while regenerating, use the generated fallback file:

```text
Reports/UniLink_Academic_Report_Updated.docx
```

The editable report source is:

```text
Reports/UniLink_Academic_Report_Text.md
```

Regenerate the Word report with:

```bash
python Reports/build_unilink_academic_report.py
```

If the main `.docx` is open in Microsoft Word and cannot be overwritten, the script writes `Reports/UniLink_Academic_Report_Updated.docx` instead.

## Verification

Recommended final checks before submission:

```bash
flutter pub get
flutter analyze
flutter run
```

Also verify Firebase rules against the latest collections, especially `media_assets`, `club_membership_requests`, chat subcollections, notifications, event registrations, and payment receipts.
