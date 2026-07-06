# Report Text - UniLink Key Features

## Figure Captions

Figure 1. UniLink home screen showing the event carousel and club posts loaded from Firebase.

Figure 2. Club detail screen showing the cover image, logo, follower count, posts, events, members, followers, and club photos.

Figure 3. Event creation screen showing the map location picker and the selected latitude/longitude saved with the event.

Figure 4. Event details screen showing a saved map location, event information, registration status, and multimedia content.

Figure 5. Post creation screen showing multimedia upload where a club manager attaches images to a post.

Figure 6. Post detail screen showing multimedia content loaded from Firebase and displayed inside the app.

Figure 7. Event registration dialog showing payment receipt upload and additional registration requirements.

Figure 8. Club chat room screen showing realtime messages and a shared event/post attachment.

Figure 9. Notifications screen showing saved notifications loaded from Firestore, including event and post navigation.

Figure 10. Profile settings screen showing privacy, follower visibility, message privacy, notification preferences, and feed priority settings.

## Feature 1: Map Integration

The app uses an interactive map to let club managers choose the physical location of an event. This is implemented with `flutter_map` for rendering map tiles and `latlong2` for representing coordinates. When the manager taps the map, the app stores the selected `LatLng` value in state. When the event is saved, the latitude and longitude are written into the event document in Firebase Firestore. Later, the event detail screen reads these values and displays the event location.

### Code Snippet

```dart
FlutterMap(
  options: MapOptions(
    initialCenter: _selectedLocation,
    initialZoom: 16,
    onTap: (_, point) {
      setState(() => _selectedLocation = point);
    },
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    MarkerLayer(
      markers: [
        Marker(
          point: _selectedLocation,
          child: const Icon(Icons.location_pin),
        ),
      ],
    ),
  ],
)
```

Line-by-line explanation:

- `FlutterMap(...)` creates the interactive map widget.
- `MapOptions(...)` configures the map behavior.
- `initialCenter: _selectedLocation` starts the map at the current selected location.
- `initialZoom: 16` gives a close campus-level view.
- `onTap: (_, point)` runs when the manager taps a location on the map.
- `setState(() => _selectedLocation = point)` updates the selected coordinate and refreshes the marker.
- `TileLayer(...)` loads visible map tiles from OpenStreetMap.
- `MarkerLayer(...)` displays a visual marker on the selected point.
- `Marker(point: _selectedLocation, ...)` keeps the marker synchronized with the saved coordinate.

## Feature 2: Multimedia Integration

The app supports multimedia by allowing clubs to upload images for posts, events, club logos, club covers, room images, profile photos, receipts, and registration attachments. Because Firebase Storage is not used in this project version, images are converted to Base64 strings and saved directly in Firestore fields. The UI then decodes the Base64 string and displays the image. Images are also tappable, so users can open them in a larger preview.

### Code Snippet

```dart
final file = await _picker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 900,
  imageQuality: 72,
);
if (file == null) return;
final encoded = base64Encode(await file.readAsBytes());
setState(() => _imageBase64 = encoded);
```

Line-by-line explanation:

- `_picker.pickImage(...)` opens the phone gallery and lets the user choose an image.
- `source: ImageSource.gallery` means the image comes from the device gallery.
- `maxWidth: 900` reduces very large images to a safer size for mobile display and Firestore storage.
- `imageQuality: 72` compresses the image to reduce data size.
- `if (file == null) return;` stops the function if the user cancels.
- `file.readAsBytes()` reads the selected image as raw bytes.
- `base64Encode(...)` converts the image bytes into a text string.
- `setState(...)` stores the encoded image in the screen state so it can be previewed and saved.

## Feature 3: Data Persistence

The app uses Firebase Firestore as the main persistence layer. Clubs, posts, events, registrations, saved posts, notifications, chat rooms, and direct messages are stored as Firestore documents. Model classes convert app objects into maps before saving, and convert Firestore maps back into Dart objects when loading. This makes the data persistent across app restarts and available across different devices.

### Code Snippet

```dart
Future<void> saveEvent(EventModel event) =>
    _events.doc(event.id).set(event.toMap());

Future<EventModel?> getEventById(String id, {String? userId}) async {
  final doc = await _events.doc(id).get();
  if (!doc.exists) return null;
  final event = EventModel.fromMap(doc.data()!);
  final events = await _withRegistrationState([event], userId);
  return events.isEmpty ? event : events.first;
}
```

Line-by-line explanation:

- `saveEvent(EventModel event)` defines a method for saving an event.
- `_events.doc(event.id)` selects the Firestore document that belongs to the event.
- `.set(event.toMap())` converts the event object into a map and writes it to Firestore.
- `getEventById(...)` defines a method for loading one event by its id.
- `await _events.doc(id).get()` reads the event document from Firestore.
- `if (!doc.exists) return null;` handles deleted or missing events safely.
- `EventModel.fromMap(doc.data()!)` converts Firestore data back into a Dart model.
- `_withRegistrationState([event], userId)` adds the current user's registration status.
- `return events.isEmpty ? event : events.first;` returns the enriched event object.

## Related Programming Concepts

The project applies separation of concerns by placing UI screens, models, providers, and services in different files. Screens handle layout and user interaction. Models represent structured data such as `EventModel`, `PostModel`, and `UserModel`. Services handle Firebase operations, such as saving events, loading posts, sending messages, and creating notifications. Providers keep shared app state such as authentication, theme settings, followed clubs, and notification counts.

State management is handled through `Provider` and local `StatefulWidget` state. `Provider` is used for cross-screen data such as the logged-in user and app settings. Local state is used for temporary UI values such as selected images, form fields, selected map coordinates, loading indicators, and visible feed limits.

Asynchronous programming is important because Firebase and image picking are non-blocking operations. The app uses `async` and `await` to load data, save documents, upload Base64 image strings, and refresh the UI after operations complete. `mounted` checks are used after asynchronous operations to avoid updating a screen that has already been closed.

Realtime behavior is implemented with Firestore streams. Chat rooms, direct messages, notifications, and club rooms can listen to Firestore snapshots. When a new message or notification is added, the UI receives the updated snapshot and rebuilds automatically.

Data validation is used before saving or registering. For example, event registration checks whether an event is full, whether payment is required, and whether additional requirements are completed. This prevents incomplete or invalid records from being saved.

The app also improves performance with incremental loading. The Home screen loads a limited set of recent posts and upcoming events, displays only ten items per section, and provides a load-more action for the next batch. This avoids rendering a very long feed at once and keeps the mobile UI responsive.
