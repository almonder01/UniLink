# UniLink

UniLink is a Flutter mobile application for university club discovery, event management, student engagement, and club communication.

The app supports student profiles, club following, member management, event registration, event dashboards, post interactions, saved posts, notifications, direct messages, and club chat rooms.

## Main Features

- Student authentication and editable profiles.
- Club discovery, following, member lists, and membership requests.
- Manager-facing club profile editing with logo, cover, photos, and about text.
- Event creation and editing with date, time, location map, capacity, fees, and optional registration requirements.
- Event dashboard for registrations, attendance, payments, documents, and event filtering.
- Posts with images, likes, comments, saved posts, and chat sharing.
- Direct person-to-person messages and member-only club rooms.
- Notifications for events, posts, payments, rooms, chats, and requests.
- Light and dark theme support with responsive cards and lists.

## Compulsory Features

- Map Integration: `flutter_map` and `latlong2` are used for event location selection and display. The default map location is XMUM.
- Multimedia Integration: images are selected through `image_picker`, compressed, encoded as Base64, saved in Firestore, and displayed through reusable image widgets.
- Data Persistence: Firebase Firestore stores profiles, clubs, posts, events, registrations, notifications, chats, follows, saved posts, and payment records.

## Project Structure

```text
lib/
  core/                  Theme and shared app-level setup
  models/                Firestore-backed data models
  providers/             App state providers
  screens/
    admin/               Admin dashboard views
    auth/                Login and sign-up screens
    chat/                Direct chat and club room screens
    manager/             Club manager tabs, dashboards, and forms
    student/             Student home, club, event, profile, and settings screens
  services/              Firebase and app business logic
  widgets/               Reusable cards, avatars, media, map, and shared UI
Reports/
  UniLink_Academic_Report.docx
  UniLink_Academic_Report_Text.md
  build_unilink_academic_report.py
```

Large screens and cards are split into small widgets inside feature folders, for example `event_dashboard/`, `club_detail/`, `profile/`, `settings/`, `post_detail/`, `event_registration/`, `event_card/`, and `post_card/`.

## Setup

1. Install Flutter and configure a device or emulator.
2. Run:

```bash
flutter pub get
flutter analyze
flutter run
```

3. Configure Firebase for the target platform before running against a real backend.
4. Make sure Firestore rules match `firestore.rules`.

## Firebase Notes

The project uses Firestore collections such as:

- `profiles`
- `clubs`
- `posts`
- `events`
- `event_registrations`
- `notifications`
- `club_rooms`
- `direct_chats`
- `user_follows`
- `saved_posts`

Images are currently stored as Base64 strings in Firestore for this project version. For production-scale media, Firebase Storage should be used.

## Reports

The academic report is available in `Reports/UniLink_Academic_Report.docx`.

The editable report source text is in `Reports/UniLink_Academic_Report_Text.md`, and the report can be regenerated with:

```bash
python Reports/build_unilink_academic_report.py
```

## Verification

Final code verification:

```bash
flutter analyze
```

The current project is organized for maintainability: duplicated UI blocks have been extracted into widgets, shared helpers are centralized, and each major feature has a dedicated folder for its smaller components.
