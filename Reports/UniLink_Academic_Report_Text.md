# UniLink Mobile Application Report

## 1. Scope and Purpose

This report documents UniLink, a Flutter mobile application for university club engagement. The app helps students discover clubs, follow clubs, request membership, register for events, interact with club posts, communicate with other users, and participate in club text rooms. It also gives club managers a dedicated management area for club profiles, posts, events, members, payments, rooms, registrations, and reusable media assets.

The report focuses on the three compulsory technical features required for the project: Map Integration, Multimedia Integration, and Data Persistence. It also explains related programming concepts, the current application architecture, and the screenshots that should be inserted in the final submitted report.

## 2. Application Overview

UniLink has three main roles:

- Student: can browse clubs, follow clubs, request membership, register for events, save posts, comment, like, chat, receive notifications, and manage profile/privacy settings.
- Club manager: can edit the club profile, create posts and events, manage event registrations, manage club members, send invitations, manage club chat rooms, and review payment/receipt information.
- University admin: can manage users and clubs from the admin dashboard, including editing club names and categories.

The app is designed around reusable feature folders. Data models live in `lib/models/`, business logic and Firebase access live in `lib/services/`, shared state lives in `lib/providers/`, screens live in `lib/screens/`, and reusable UI lives in `lib/widgets/`.

## 3. Required Screenshot Captions

Use these captions under the screenshots in the final report. They cover the full design and also show the three compulsory features working in the application.

1. Splash screen showing the animated UniLink entry point before navigation.
2. Login screen showing Firebase authentication access.
3. Sign-up screen showing account creation and gender profile selection.
4. Home screen showing paginated upcoming events and recent club posts loaded from Firestore.
5. Home screen showing the Load More controls for posts and events.
6. Clubs screen showing available clubs, follower status, and club cards.
7. Club detail screen showing cover image, logo, follower count, posts, events, members, followers, and photos.
8. Club detail About tab showing the club description, gallery, optional background media, and feature/code section.
9. Club detail Members tab showing visible members and followers with direct message actions.
10. Post detail screen showing multimedia, likes, comments, save action, and share-to-chat action.
11. Comment sheet showing comment creation, edit/delete for the owner, and manager delete control.
12. Event detail screen showing event information, registration state, map location, media, payment requirement, and external form link.
13. Event registration confirmation dialog showing title confirmation, payment receipt upload, and additional requirement input.
14. Map picker screen showing a manager selecting an event location using the interactive map.
15. Compulsory Map feature screenshot: event location displayed on the map after being saved.
16. Compulsory Multimedia feature screenshot: video or music preview displayed inside the app.
17. Compulsory Data Persistence feature screenshot: saved data loaded back from Firestore, such as a saved post, event registration, or media library item.
18. Profile screen showing editable profile image, name, academic information, joined clubs, followed clubs, and request shortcuts.
19. Settings screen showing theme, privacy, visibility, message privacy, notification preferences, feed priority, club media controls, and post/event media controls.
20. Saved posts screen showing search and club filtering for saved content.
21. Direct messages list showing unread indicators for private conversations.
22. Direct chat screen showing realtime messages and a shared post or event attachment.
23. Club room chat screen showing member-only room messages and shared attachments.
24. Club room dashboard showing room list, recent activity, room editing, and event-based invitations.
25. My Club profile tab showing club logo, cover, about text, gallery, logo background controls, and club experience controls.
26. Club Experience editor showing YouTube or uploaded background video and optional background music.
27. Media Library screen showing saved videos and saved music for reuse.
28. Media attachment widget showing the choice between YouTube URL, uploaded video, MP3/audio source, auto-open video, and auto-play music.
29. Manager posts tab showing post cards with spacing, edit, delete, and media library access.
30. Manager events tab showing event cards, create/edit actions, and the event dashboard entry point.
31. Event dashboard overview showing planned, active, and finished event filters.
32. Event registrations dashboard showing attendance, pending requests, accepted students, rejected students, and quick approval actions.
33. Event payments/documents tab showing receipts, required files, and manager review controls.
34. Members tab showing club members and membership request management.
35. Membership request dashboard showing approve, reject, and payment request actions.
36. Club payment dashboard showing monthly fee requests, receipt status, and statistics.
37. Notifications screen showing event, post, room invite, payment, membership, and chat notifications.
38. Admin dashboard showing system-level club and user management.
39. Admin club editor showing name and category editing with existing or custom category input.

## 4. Feature 1 - Map Integration

### What the Feature Does

UniLink uses the map feature to manage event locations. When a club manager creates or edits an event, the manager can open a map picker, tap the venue location, and save that coordinate with the event. Students later see the selected event location in the event details page through a map preview.

The project uses:

- `flutter_map` for rendering the interactive map.
- `latlong2` for representing latitude and longitude values.
- XMUM as the default coordinate when the event does not already have a saved location.

### How It Was Built

The location picker is implemented in `lib/screens/manager/event_location_picker_screen.dart`. The map preview is implemented in `lib/widgets/event_map_preview.dart`. The selected latitude and longitude are stored inside the event model and saved to Firestore through the event service.

Short code snippet:

```dart
late LatLng _selectedLocation;

@override
void initState() {
  super.initState();
  _selectedLocation =
      widget.initialLocation ?? const LatLng(2.8329, 101.7077);
}

FlutterMap(
  options: MapOptions(
    initialCenter: _selectedLocation,
    initialZoom: 16,
    onTap: (_, point) => setState(() => _selectedLocation = point),
  ),
);
```

Line-by-line explanation:

- `late LatLng _selectedLocation;` declares the selected map coordinate for the screen.
- `initState()` initializes the coordinate before the UI is built.
- `widget.initialLocation` is used when the event already has a saved location, such as during event editing.
- `const LatLng(2.8329, 101.7077)` is the fallback XMUM coordinate.
- `FlutterMap(...)` displays the interactive map widget.
- `MapOptions(...)` configures the starting center, zoom level, and map behavior.
- `initialCenter: _selectedLocation` makes the map open at the selected or default location.
- `initialZoom: 16` gives a close view suitable for campus venue selection.
- `onTap: (_, point) => setState(...)` updates the selected coordinate when the manager taps the map and refreshes the UI.

The selected coordinate is then stored in the `EventModel` fields `latitude` and `longitude`, which allows the same location to be loaded later in the student event detail page.

## 5. Feature 2 - Multimedia Integration

### What the Feature Does

UniLink supports multiple multimedia flows:

- Images for profiles, club logos, club covers, galleries, posts, events, receipts, and registration files.
- YouTube videos for posts, events, and club background video.
- Uploaded direct videos for posts, events, and club background video.
- Uploaded MP3/audio or audio links for post music, event music, and club background music.
- Reusable saved media through the manager Media Library.
- Separate auto-open video and auto-play music controls for club profile media, posts, and events.

The app normally displays a thumbnail or preview first, then opens playback when the user taps it. Managers can also enable auto-open video and auto-play music for posts, events, and club profile media. Student privacy settings decide whether those automatic behaviors are allowed on the viewer side, so the publisher and viewer both have control.

### How It Was Built

The reusable media form is implemented in `lib/widgets/media_attachment_fields.dart`. Post and event publishing also use `lib/widgets/publish_media_attachment_fields.dart`, which wraps the shared media fields with the auto-open video and auto-play music switches. Student detail pages use shared content media widgets so post and event media render consistently. The app uses:

- `youtube_player_flutter` for YouTube playback inside the app.
- `file_picker` for selecting audio/video files.
- `http` for Cloudinary upload requests.
- `video_player` for uploaded/direct video playback.
- `just_audio` for background audio playback.

Short code snippet from the Cloudinary upload flow:

```dart
final uri = Uri.parse(
  'https://api.cloudinary.com/v1_1/'
  '${CloudinaryConfig.cloudName}/$resourceType/upload',
);

final request = http.MultipartRequest('POST', uri)
  ..fields['upload_preset'] = CloudinaryConfig.uploadPreset;

request.files.add(await http.MultipartFile.fromPath('file', file.path!));
final response = await request.send();
```

Line-by-line explanation:

- `Uri.parse(...)` builds the upload URL for the configured media account.
- `CloudinaryConfig.cloudName` keeps the cloud name in one configuration file instead of hard-coding it in every screen.
- `$resourceType/upload` allows the service to upload video, audio, or automatic media types.
- `http.MultipartRequest('POST', uri)` creates a multipart HTTP request suitable for file upload.
- `upload_preset` identifies the unsigned preset that allows uploads without exposing a secret key in the mobile app.
- `http.MultipartFile.fromPath('file', file.path!)` attaches the selected local file to the request.
- `await request.send()` sends the request asynchronously and waits for the upload result.

After the upload succeeds, the app stores only the returned secure URL in Firestore. This keeps Firestore documents smaller than storing videos directly. Images are still stored as Base64 in Firestore for this project version because they are small enough for the academic demo and simpler to display across profile, club, post, and event surfaces.

### Media Library

The Media Library is backed by the `media_assets` collection. It stores reusable media metadata: club id, display name, URL, media kind, source type, creator id, and creation date. Managers can reuse saved videos or saved music in multiple posts, events, and club profile fields.

Short code snippet:

```dart
final id = MediaAssetService.idFor(
  clubId: clubId,
  url: cleanUrl,
  mediaKind: mediaKind,
  sourceType: sourceType,
);

final doc = await _assets.doc(id).get();
if (doc.exists) return;
```

Line-by-line explanation:

- `MediaAssetService.idFor(...)` creates a stable id based on club id, URL, media kind, and source type.
- `clubId` ensures each club has its own reusable media list.
- `url` is the YouTube, direct video, or audio URL.
- `mediaKind` separates videos from audio/music.
- `sourceType` separates YouTube, uploaded videos, and MP3/audio sources.
- `_assets.doc(id).get()` checks whether the same asset was saved before.
- `if (doc.exists) return;` prevents duplicate media records from being created.

## 6. Feature 3 - Data Persistence

### What the Feature Does

Data Persistence means the app does not lose user actions after leaving a screen or reopening the app. UniLink uses Firebase Firestore as the main persistent database. It stores accounts, profiles, clubs, follows, memberships, membership requests, posts, comments, saved posts, events, registrations, notifications, chats, payments, receipts, and media library records.

### How It Was Built

Each main data type has a model class and one or more services. For example:

- `PostModel` converts post information to and from Firestore maps.
- `EventModel` stores event details, location coordinates, media links, registration options, fee settings, and counters.
- `MediaAsset` stores reusable video/audio metadata.
- `DatabaseService`, `EventService`, `SavedPostService`, `MediaAssetService`, `DirectChatService`, and other service classes hide Firestore queries from the UI.

Short code snippet from the media asset save flow:

```dart
final asset = MediaAsset(
  id: id,
  clubId: clubId,
  name: name.trim().isEmpty ? _defaultName(mediaKind, sourceType) : name,
  url: cleanUrl,
  mediaKind: mediaKind,
  sourceType: sourceType,
  createdBy: createdBy,
  createdAt: DateTime.now(),
);

await _assets.doc(id).set(asset.toMap());
```

Line-by-line explanation:

- `final asset = MediaAsset(...)` creates a typed Dart object before saving.
- `id: id` assigns the stable Firestore document id.
- `clubId: clubId` links the media item to one club.
- `name: ...` stores a custom name or a default generated name if the manager leaves it empty.
- `url: cleanUrl` stores the reusable media URL.
- `mediaKind: mediaKind` records whether the asset is video or audio.
- `sourceType: sourceType` records whether the asset came from YouTube, uploaded video, or audio/MP3.
- `createdBy: createdBy` optionally records the manager who added the asset.
- `createdAt: DateTime.now()` records the creation time for sorting newest first.
- `asset.toMap()` converts the Dart object into a Firestore-compatible map.
- `_assets.doc(id).set(...)` writes the document to Firestore.

### Realtime and Async Persistence

Direct chats, club room messages, notifications, comments, and dashboard data use asynchronous Firestore reads or realtime streams. This means the UI can update when data changes without manual refresh. The app also uses Firestore counters and transactions in event registration and membership management so counts remain consistent.

## 7. Important Firebase Configuration Notes

The latest code uses the following important collections:

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

If Firestore security rules do not include `media_assets`, the Media Library will not be able to save or rename reusable videos/music. If rules do not include `club_membership_requests`, the membership request workflow will not persist correctly. These two collections should be checked before final deployment.

Cloudinary is used only for uploaded video/audio storage. The mobile app stores the returned URL in Firestore. Secure deletion from Cloudinary is not implemented in the mobile app because that should be done through a backend service.

## 8. Related Programming Concepts

### Separation of Concerns

The codebase separates UI, state, models, and services. Screens focus on layout and user actions. Services focus on Firebase, chat, event, payment, and upload logic. Models define the structure of data. Shared widgets keep repeated interface elements reusable.

### Object Modeling

Classes such as `UserModel`, `ClubModel`, `PostModel`, `EventModel`, `MediaAsset`, `DirectChat`, and `ChatMessage` provide typed access to Firestore data. This reduces mistakes compared with passing unstructured maps throughout the UI.

### Asynchronous Programming

Firebase, file picking, image processing, Cloudinary upload, and media loading all use asynchronous operations. The code uses `async`, `await`, futures, and streams so the app can remain responsive while data is loading.

### State Management

Provider is used for app-level state such as authentication, theme, club follow state, club data, and notifications. Local form state remains inside `StatefulWidget` classes when the state belongs only to one screen.

### Realtime Streams

Direct messages, room messages, notifications, and some dashboard data use Firestore snapshots. This allows the app to show new messages, unread counts, and updates without requiring a full screen reload.

### Transactions and Counters

Event registration and membership management involve counters such as registered count, attended count, and member count. Transactions are used where consistency matters so the app does not accept invalid state when multiple users act at the same time.

### Role-Based Access

The UI changes depending on whether the user is a student, club manager, member, follower, or university admin. For example, only managers can edit club posts/events, manage members, and open event dashboards, while students can register, follow, comment, and request membership.

### Responsive UI and Maintainability

Cards, lists, dashboards, and dialogs use flexible layouts so text and media fit on different phone sizes. Large screens were divided into smaller widgets and feature folders, which makes maintenance easier and reduces duplicated UI.

### External API Integration

The app integrates with multiple external packages and services. `flutter_map` provides the map UI, Cloudinary handles uploaded audio/video storage, YouTube URLs are played inside the app, and Firebase stores persistent app data.

## 9. Final Code Structure and Maintainability

The final codebase is organized for maintenance:

- Event dashboard widgets are under `lib/screens/manager/event_dashboard/`.
- Club profile manager widgets are under `lib/screens/manager/club_profile/`.
- Student club detail widgets are under `lib/screens/student/club_detail/`.
- Profile widgets are under `lib/screens/student/profile/`.
- Settings widgets are under `lib/screens/student/settings/`.
- Post detail widgets are under `lib/screens/student/post_detail/`.
- Event detail widgets are under `lib/screens/student/event_detail/`.
- Event registration dialog pieces are under `lib/screens/student/widgets/event_registration/`.
- Chat room dashboard widgets are under `lib/screens/chat/club_room_dashboard/`.
- Room settings widgets are under `lib/screens/chat/room_settings/`.
- Post card sub-widgets are under `lib/widgets/post_card/`.
- Event card sub-widgets are under `lib/widgets/event_card/`.
- Media attachment sub-widgets are under `lib/widgets/media_attachment/`.
- Shared post/event media widgets are under `lib/widgets/content_media_section.dart`, `lib/widgets/content_auto_media_launcher.dart`, and `lib/widgets/publish_media_attachment_fields.dart`.

This structure supports the "divide and maintain" approach: each class or widget has a narrower purpose, repeated UI is extracted, and feature-specific components are grouped near the screen that uses them.

## 10. Conclusion

UniLink now includes a complete club engagement workflow: discovery, following, membership requests, event registration, dashboards, payments, posts, multimedia, chats, room invitations, profile controls, and admin management. The three compulsory requirements are implemented as real app features rather than isolated demos. Maps are used for event venues, multimedia is used across posts/events/clubs, and Firestore persists user and manager activity throughout the application.
