# UniLink Mobile Application Report

## Scope

This formal report documents UniLink, a Flutter mobile application for university clubs. It explains the three compulsory features: Map Integration, Multimedia Integration, and Data Persistence. It also includes figure captions for screenshots and an analysis of related programming concepts.

## Required Figure Captions

1. Splash or login screen showing the first entry point of UniLink.
2. Sign up screen showing account creation and gender profile selection.
3. Home screen showing upcoming events and recent club posts loaded from Firestore.
4. Clubs screen showing available clubs and follow status.
5. Club detail screen showing cover image, logo, follower count, posts, events, members, followers, and photos.
6. Event detail screen showing event information, registration state, map location, and media gallery.
7. Map picker screen showing the selected event location on the interactive map.
8. Post detail screen showing post multimedia, likes, comments, and saved-post actions.
9. Event registration confirmation dialog showing payment receipt and additional requirement inputs.
10. Notifications screen showing event, post, room invite, payment, and request notifications loaded from Firestore.
11. Profile screen showing user information, editable profile image, joined clubs, followed clubs, and request shortcuts.
12. Settings screen showing privacy, follower visibility, member visibility, message privacy, notification preferences, and feed priority settings.
13. Saved posts screen showing search and club filtering for saved content.
14. Direct messages list showing unread indicators for private conversations.
15. Direct chat screen showing realtime messages and a shared post or event attachment.
16. Club room chat screen showing member-only room messages and a shared event or post.
17. Club room dashboard showing rooms, recent speakers, room editing, and event-based invite options.
18. My Club profile tab showing club logo, cover, about text, photos, and logo background controls.
19. Manager posts tab showing post cards with edit and delete actions.
20. Manager events tab showing event cards, event creation, editing, and dashboard entry.
21. Event dashboard overview showing planned, active, and finished events with filters.
22. Event registrations dashboard showing attendance, pending requests, accepted students, rejected students, and quick approval actions.
23. Event payments and documents tab showing registration receipts, required files, and manager review actions.
24. Members tab showing club members and membership request management.
25. Club payment dashboard showing monthly fee requests, receipt upload status, and daily or monthly statistics.
26. Admin dashboard showing system-level clubs and users management.
27. Compulsory map feature working in the app: event location displayed on the map.
28. Compulsory multimedia feature working in the app: image selected, previewed, saved, and displayed.
29. Compulsory data persistence feature working in the app: data saved to Firestore and loaded back in the UI.

## Feature 1: Map Integration

The app uses `flutter_map` and `latlong2` to let club managers choose event locations. The default coordinate is XMUM: latitude 2.8329 and longitude 101.7077. When the manager taps the map, the selected coordinate is stored in state. When the event is saved, the latitude and longitude are written to Firestore and later displayed in the event detail screen.

## Feature 2: Multimedia Integration

The app supports image upload for posts, events, clubs, profiles, rooms, receipts, and registration requirement files. Images are picked from the device gallery, compressed, read as bytes, converted to Base64, and saved in Firestore. The UI decodes the saved Base64 strings and displays images in cards, details, galleries, and avatars.

## Feature 3: Data Persistence

Firebase Firestore stores profiles, clubs, posts, events, event registrations, notifications, club rooms, direct chats, follows, and saved posts. Model classes convert typed Dart objects to maps before saving and convert Firestore data back into Dart objects when loading. Transactions are used for event registration counters so capacity checks and counter increments remain consistent.

## Related Programming Concepts

- Separation of concerns: screens, widgets, models, services, and providers have different responsibilities.
- Object modeling: model classes define the structure of app data.
- Asynchronous programming: Firebase and image operations use async and await.
- State management: Provider stores shared app state while StatefulWidget state handles local form values.
- Realtime streams: chats, comments, and notifications update through Firestore snapshots.
- Transactions: event registration uses atomic updates for counters and capacity.
- Role-based behavior: students, managers, members, followers, and admins see different actions.
- Validation: forms check dates, URLs, fees, capacity, and required registration information.
- Responsive UI: cards and layouts use flexible constraints to avoid overflow on different devices.
