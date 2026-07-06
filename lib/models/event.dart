class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final String clubId;
  final String clubName;
  final String? clubLogoColor;
  final String? clubLogoImageBase64;
  final bool clubShowLogoBackground;
  final String coverColor;
  final String? coverImageBase64;
  final List<String> photoBase64List;
  final DateTime eventDate;
  final double? feeAmount;
  final String feeCurrency;
  final int? maxParticipants;
  final String? externalFormUrl;
  final String? registrationRequirementPrompt;
  final bool requiresRegistrationText;
  final bool requiresRegistrationFile;
  final int registeredCount;
  final int attendedCount;
  bool isRegistered;
  final String? registrationStatus;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    required this.clubId,
    required this.clubName,
    this.clubLogoColor,
    this.clubLogoImageBase64,
    this.clubShowLogoBackground = true,
    required this.coverColor,
    this.coverImageBase64,
    this.photoBase64List = const [],
    required this.eventDate,
    this.feeAmount,
    this.feeCurrency = 'RM',
    this.maxParticipants,
    this.externalFormUrl,
    this.registrationRequirementPrompt,
    this.requiresRegistrationText = false,
    this.requiresRegistrationFile = false,
    this.registeredCount = 0,
    this.attendedCount = 0,
    this.isRegistered = false,
    this.registrationStatus,
  });

  bool get requiresPayment => feeAmount != null && feeAmount! > 0;
  bool get isPendingApproval => registrationStatus == 'pending';
  bool get isRegistrationApproved => registrationStatus == 'approved';
  bool get hasCapacityLimit => maxParticipants != null && maxParticipants! > 0;
  bool get isFull => hasCapacityLimit && registeredCount >= maxParticipants!;
  bool get hasExternalForm => (externalFormUrl ?? '').trim().isNotEmpty;
  bool get hasRegistrationRequirement =>
      requiresRegistrationText || requiresRegistrationFile;
  int? get remainingSlots {
    if (!hasCapacityLimit) return null;
    final remaining = maxParticipants! - registeredCount;
    return remaining < 0 ? 0 : remaining;
  }

  String get feeLabel {
    if (!requiresPayment) return 'Free';
    return feeCurrency == 'USD'
        ? '\$${feeAmount!.toStringAsFixed(2)}'
        : 'RM ${feeAmount!.toStringAsFixed(2)}';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'clubId': clubId,
        'clubName': clubName,
        'clubLogoColor': clubLogoColor ?? 'FF6366F1',
        if (clubLogoImageBase64 != null)
          'clubLogoImageBase64': clubLogoImageBase64,
        'clubShowLogoBackground': clubShowLogoBackground,
        'coverColor': coverColor,
        if (coverImageBase64 != null) 'coverImageBase64': coverImageBase64,
        'photoBase64List': photoBase64List,
        'eventDate': eventDate.toIso8601String(),
        'feeAmount': feeAmount,
        'feeCurrency': feeCurrency,
        'maxParticipants': maxParticipants,
        if (externalFormUrl != null) 'externalFormUrl': externalFormUrl,
        if (registrationRequirementPrompt != null)
          'registrationRequirementPrompt': registrationRequirementPrompt,
        'requiresRegistrationText': requiresRegistrationText,
        'requiresRegistrationFile': requiresRegistrationFile,
        'registeredCount': registeredCount,
        'attendedCount': attendedCount,
      };

  factory EventModel.fromMap(Map<String, dynamic> map) => EventModel(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        location: map['location'] as String,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        clubId: map['clubId'] as String,
        clubName: map['clubName'] as String,
        clubLogoColor: map['clubLogoColor'] as String?,
        clubLogoImageBase64: map['clubLogoImageBase64'] as String?,
        clubShowLogoBackground: map['clubShowLogoBackground'] as bool? ?? true,
        coverColor: map['coverColor'] as String? ?? 'FF6366F1',
        coverImageBase64: map['coverImageBase64'] as String?,
        photoBase64List: List<String>.from(map['photoBase64List'] ?? const []),
        eventDate: DateTime.parse(map['eventDate'] as String),
        feeAmount: (map['feeAmount'] as num?)?.toDouble(),
        feeCurrency: map['feeCurrency'] as String? ?? 'RM',
        maxParticipants: (map['maxParticipants'] as num?)?.toInt(),
        externalFormUrl: map['externalFormUrl'] as String?,
        registrationRequirementPrompt:
            map['registrationRequirementPrompt'] as String?,
        requiresRegistrationText:
            map['requiresRegistrationText'] as bool? ?? false,
        requiresRegistrationFile:
            map['requiresRegistrationFile'] as bool? ?? false,
        registeredCount: (map['registeredCount'] as num?)?.toInt() ?? 0,
        attendedCount: (map['attendedCount'] as num?)?.toInt() ?? 0,
      );

  EventModel copyWith({
    String? title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    String? coverColor,
    String? coverImageBase64,
    List<String>? photoBase64List,
    DateTime? eventDate,
    double? feeAmount,
    String? feeCurrency,
    int? maxParticipants,
    String? externalFormUrl,
    String? registrationRequirementPrompt,
    bool? requiresRegistrationText,
    bool? requiresRegistrationFile,
    int? registeredCount,
    int? attendedCount,
    bool? isRegistered,
    String? registrationStatus,
  }) =>
      EventModel(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        location: location ?? this.location,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        clubId: clubId,
        clubName: clubName,
        clubLogoColor: clubLogoColor,
        clubLogoImageBase64: clubLogoImageBase64,
        clubShowLogoBackground: clubShowLogoBackground,
        coverColor: coverColor ?? this.coverColor,
        coverImageBase64: coverImageBase64 ?? this.coverImageBase64,
        photoBase64List: photoBase64List ?? this.photoBase64List,
        eventDate: eventDate ?? this.eventDate,
        feeAmount: feeAmount ?? this.feeAmount,
        feeCurrency: feeCurrency ?? this.feeCurrency,
        maxParticipants: maxParticipants ?? this.maxParticipants,
        externalFormUrl: externalFormUrl ?? this.externalFormUrl,
        registrationRequirementPrompt:
            registrationRequirementPrompt ?? this.registrationRequirementPrompt,
        requiresRegistrationText:
            requiresRegistrationText ?? this.requiresRegistrationText,
        requiresRegistrationFile:
            requiresRegistrationFile ?? this.requiresRegistrationFile,
        registeredCount: registeredCount ?? this.registeredCount,
        attendedCount: attendedCount ?? this.attendedCount,
        isRegistered: isRegistered ?? this.isRegistered,
        registrationStatus: registrationStatus ?? this.registrationStatus,
      );
}
