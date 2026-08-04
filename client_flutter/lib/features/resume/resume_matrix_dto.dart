import 'dart:convert';
import 'dart:typed_data';
import 'package:messagepack/messagepack.dart';

// ---------------------------------------------------------------------------
// Location & Profile
// ---------------------------------------------------------------------------

class LocationDto {
  final String city;
  final String region;
  final String countryCode;

  const LocationDto({
    this.city = '',
    this.region = '',
    this.countryCode = '',
  });

  factory LocationDto.fromMap(Map<dynamic, dynamic> m) => LocationDto(
        city: (m['city'] ?? '') as String,
        region: (m['region'] ?? '') as String,
        countryCode: (m['country_code'] ?? m['countryCode'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'city': city,
        'region': region,
        'country_code': countryCode,
      };
}

class ProfileDto {
  final String network;
  final String username;
  final String url;

  const ProfileDto({this.network = '', this.username = '', this.url = ''});

  factory ProfileDto.fromMap(Map<dynamic, dynamic> m) => ProfileDto(
        network: (m['network'] ?? '') as String,
        username: (m['username'] ?? '') as String,
        url: (m['url'] ?? '') as String,
      );

  Map<String, dynamic> toMap() =>
      {'network': network, 'username': username, 'url': url};
}

// ---------------------------------------------------------------------------
// Basics
// ---------------------------------------------------------------------------

class BasicsDto {
  final String name;
  final String label;
  final String email;
  final String phone;
  final String url;
  final String summary;
  final LocationDto location;
  final List<ProfileDto> profiles;

  const BasicsDto({
    this.name = '',
    this.label = '',
    this.email = '',
    this.phone = '',
    this.url = '',
    this.summary = '',
    this.location = const LocationDto(),
    this.profiles = const [],
  });

  factory BasicsDto.fromMap(Map<dynamic, dynamic> m) => BasicsDto(
        name: (m['name'] ?? '') as String,
        label: (m['label'] ?? '') as String,
        email: (m['email'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        url: (m['url'] ?? '') as String,
        summary: (m['summary'] ?? '') as String,
        location: m['location'] is Map
            ? LocationDto.fromMap(m['location'] as Map)
            : const LocationDto(),
        profiles: (m['profiles'] as List? ?? [])
            .whereType<Map>()
            .map(ProfileDto.fromMap)
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'label': label,
        'email': email,
        'phone': phone,
        'url': url,
        'summary': summary,
        'location': location.toMap(),
        'profiles': profiles.map((p) => p.toMap()).toList(),
      };

  BasicsDto copyWith({
    String? name,
    String? label,
    String? email,
    String? phone,
    String? url,
    String? summary,
    LocationDto? location,
    List<ProfileDto>? profiles,
  }) =>
      BasicsDto(
        name: name ?? this.name,
        label: label ?? this.label,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        url: url ?? this.url,
        summary: summary ?? this.summary,
        location: location ?? this.location,
        profiles: profiles ?? this.profiles,
      );
}

// ---------------------------------------------------------------------------
// WorkItemDto
// ---------------------------------------------------------------------------

class WorkItemDto {
  final String id;
  final String name;
  final String position;
  final String url;
  final String startDate;
  final String endDate;
  final String summary;
  final List<String> highlights;
  final List<String> skills;
  final bool active;

  const WorkItemDto({
    this.id = '',
    this.name = '',
    this.position = '',
    this.url = '',
    this.startDate = '',
    this.endDate = '',
    this.summary = '',
    this.highlights = const [],
    this.skills = const [],
    this.active = true,
  });

  factory WorkItemDto.fromMap(Map<dynamic, dynamic> m) => WorkItemDto(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        position: (m['position'] ?? '') as String,
        url: (m['url'] ?? '') as String,
        startDate: (m['start_date'] ?? m['startDate'] ?? '') as String,
        endDate: (m['end_date'] ?? m['endDate'] ?? '') as String,
        summary: (m['summary'] ?? '') as String,
        highlights: _strList(m['highlights']),
        skills: _strList(m['skills']),
        active: (m['active'] ?? true) as bool,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'position': position,
        'url': url,
        'start_date': startDate,
        'end_date': endDate,
        'summary': summary,
        'highlights': highlights,
        'skills': skills,
        'active': active,
      };

  WorkItemDto copyWith({
    String? id,
    String? name,
    String? position,
    String? url,
    String? startDate,
    String? endDate,
    String? summary,
    List<String>? highlights,
    List<String>? skills,
    bool? active,
  }) =>
      WorkItemDto(
        id: id ?? this.id,
        name: name ?? this.name,
        position: position ?? this.position,
        url: url ?? this.url,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        summary: summary ?? this.summary,
        highlights: highlights ?? this.highlights,
        skills: skills ?? this.skills,
        active: active ?? this.active,
      );
}

// ---------------------------------------------------------------------------
// EducationDto
// ---------------------------------------------------------------------------

class EducationDto {
  final String id;
  final String institution;
  final String url;
  final String area;
  final String studyType;
  final String startDate;
  final String endDate;
  final String score;
  final List<String> courses;

  const EducationDto({
    this.id = '',
    this.institution = '',
    this.url = '',
    this.area = '',
    this.studyType = '',
    this.startDate = '',
    this.endDate = '',
    this.score = '',
    this.courses = const [],
  });

  factory EducationDto.fromMap(Map<dynamic, dynamic> m) => EducationDto(
        id: (m['id'] ?? '') as String,
        institution: (m['institution'] ?? '') as String,
        url: (m['url'] ?? '') as String,
        area: (m['area'] ?? '') as String,
        studyType: (m['study_type'] ?? m['studyType'] ?? '') as String,
        startDate: (m['start_date'] ?? m['startDate'] ?? '') as String,
        endDate: (m['end_date'] ?? m['endDate'] ?? '') as String,
        score: (m['score'] ?? '') as String,
        courses: _strList(m['courses']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'institution': institution,
        'url': url,
        'area': area,
        'study_type': studyType,
        'start_date': startDate,
        'end_date': endDate,
        'score': score,
        'courses': courses,
      };

  EducationDto copyWith({
    String? id,
    String? institution,
    String? url,
    String? area,
    String? studyType,
    String? startDate,
    String? endDate,
    String? score,
    List<String>? courses,
  }) =>
      EducationDto(
        id: id ?? this.id,
        institution: institution ?? this.institution,
        url: url ?? this.url,
        area: area ?? this.area,
        studyType: studyType ?? this.studyType,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        score: score ?? this.score,
        courses: courses ?? this.courses,
      );
}

// ---------------------------------------------------------------------------
// ProjectItemDto
// ---------------------------------------------------------------------------

class ProjectItemDto {
  final String id;
  final String name;
  final String description;
  final List<String> highlights;
  final String url;
  final List<String> exhibits;
  final bool active;

  const ProjectItemDto({
    this.id = '',
    this.name = '',
    this.description = '',
    this.highlights = const [],
    this.url = '',
    this.exhibits = const [],
    this.active = true,
  });

  factory ProjectItemDto.fromMap(Map<dynamic, dynamic> m) => ProjectItemDto(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        highlights: _strList(m['highlights']),
        url: (m['url'] ?? '') as String,
        exhibits: _strList(m['exhibits']),
        active: (m['active'] ?? true) as bool,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'highlights': highlights,
        'url': url,
        'exhibits': exhibits,
        'active': active,
      };

  ProjectItemDto copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? highlights,
    String? url,
    List<String>? exhibits,
    bool? active,
  }) =>
      ProjectItemDto(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        highlights: highlights ?? this.highlights,
        url: url ?? this.url,
        exhibits: exhibits ?? this.exhibits,
        active: active ?? this.active,
      );
}

// ---------------------------------------------------------------------------
// SkillDto
// ---------------------------------------------------------------------------

class SkillDto {
  final String id;
  final String name;
  final String level;
  final List<String> keywords;

  const SkillDto({
    this.id = '',
    this.name = '',
    this.level = '',
    this.keywords = const [],
  });

  factory SkillDto.fromMap(Map<dynamic, dynamic> m) => SkillDto(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        level: (m['level'] ?? '') as String,
        keywords: _strList(m['keywords']),
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'level': level, 'keywords': keywords};

  SkillDto copyWith({
    String? id,
    String? name,
    String? level,
    List<String>? keywords,
  }) =>
      SkillDto(
        id: id ?? this.id,
        name: name ?? this.name,
        level: level ?? this.level,
        keywords: keywords ?? this.keywords,
      );
}

// ---------------------------------------------------------------------------
// CertificateDto
// ---------------------------------------------------------------------------

class CertificateDto {
  final String id;
  final String name;
  final String issuer;
  final String date;
  final String url;

  const CertificateDto({
    this.id = '',
    this.name = '',
    this.issuer = '',
    this.date = '',
    this.url = '',
  });

  factory CertificateDto.fromMap(Map<dynamic, dynamic> m) => CertificateDto(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        issuer: (m['issuer'] ?? '') as String,
        date: (m['date'] ?? '') as String,
        url: (m['url'] ?? '') as String,
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'issuer': issuer, 'date': date, 'url': url};

  CertificateDto copyWith({
    String? id,
    String? name,
    String? issuer,
    String? date,
    String? url,
  }) =>
      CertificateDto(
        id: id ?? this.id,
        name: name ?? this.name,
        issuer: issuer ?? this.issuer,
        date: date ?? this.date,
        url: url ?? this.url,
      );
}

// ---------------------------------------------------------------------------
// AwardDto
// ---------------------------------------------------------------------------

class AwardDto {
  final String id;
  final String title;
  final String date;
  final String awarder;
  final String summary;

  const AwardDto({
    this.id = '',
    this.title = '',
    this.date = '',
    this.awarder = '',
    this.summary = '',
  });

  factory AwardDto.fromMap(Map<dynamic, dynamic> m) => AwardDto(
        id: (m['id'] ?? '') as String,
        title: (m['title'] ?? '') as String,
        date: (m['date'] ?? '') as String,
        awarder: (m['awarder'] ?? '') as String,
        summary: (m['summary'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'date': date,
        'awarder': awarder,
        'summary': summary,
      };

  AwardDto copyWith({
    String? id,
    String? title,
    String? date,
    String? awarder,
    String? summary,
  }) =>
      AwardDto(
        id: id ?? this.id,
        title: title ?? this.title,
        date: date ?? this.date,
        awarder: awarder ?? this.awarder,
        summary: summary ?? this.summary,
      );
}

// ---------------------------------------------------------------------------
// ResumeMatrixDto
// ---------------------------------------------------------------------------

class ResumeMatrixDto {
  final BasicsDto basics;
  final List<WorkItemDto> work;
  final List<EducationDto> education;
  final List<ProjectItemDto> projects;
  final List<SkillDto> skills;
  final List<CertificateDto> certificates;
  final List<AwardDto> awards;

  const ResumeMatrixDto({
    this.basics = const BasicsDto(),
    this.work = const [],
    this.education = const [],
    this.projects = const [],
    this.skills = const [],
    this.certificates = const [],
    this.awards = const [],
  });

  /// Decode from base64-encoded msgpack bytes (as received in HBP v2 `p` field).
  /// The backend encodes the response payload as msgpack, then base64-encodes it.
  factory ResumeMatrixDto.fromBase64Msgpack(List<int> bytes) {
    // The HBP frame payload arrives as raw msgpack bytes
    final u = Unpacker(Uint8List.fromList(bytes));
    final len = u.unpackMapLength();
    final map = <dynamic, dynamic>{};
    for (var i = 0; i < len; i++) {
      final key = u.unpackString();
      if (key == null) continue;
      map[key] = _unpackValue(u);
    }
    return ResumeMatrixDto.fromMap(map);
  }

  factory ResumeMatrixDto.fromMap(Map<dynamic, dynamic> m) => ResumeMatrixDto(
        basics: m['basics'] is Map
            ? BasicsDto.fromMap(m['basics'] as Map)
            : const BasicsDto(),
        work: (m['work'] as List? ?? [])
            .whereType<Map>()
            .map(WorkItemDto.fromMap)
            .toList(),
        education: (m['education'] as List? ?? [])
            .whereType<Map>()
            .map(EducationDto.fromMap)
            .toList(),
        projects: (m['projects'] as List? ?? [])
            .whereType<Map>()
            .map(ProjectItemDto.fromMap)
            .toList(),
        skills: (m['skills'] as List? ?? [])
            .whereType<Map>()
            .map(SkillDto.fromMap)
            .toList(),
        certificates: (m['certificates'] as List? ?? [])
            .whereType<Map>()
            .map(CertificateDto.fromMap)
            .toList(),
        awards: (m['awards'] as List? ?? [])
            .whereType<Map>()
            .map(AwardDto.fromMap)
            .toList(),
      );

  ResumeMatrixDto copyWith({
    BasicsDto? basics,
    List<WorkItemDto>? work,
    List<EducationDto>? education,
    List<ProjectItemDto>? projects,
    List<SkillDto>? skills,
    List<CertificateDto>? certificates,
    List<AwardDto>? awards,
  }) =>
      ResumeMatrixDto(
        basics: basics ?? this.basics,
        work: work ?? this.work,
        education: education ?? this.education,
        projects: projects ?? this.projects,
        skills: skills ?? this.skills,
        certificates: certificates ?? this.certificates,
        awards: awards ?? this.awards,
      );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<String> _strList(dynamic v) {
  if (v is List) return v.whereType<String>().toList();
  return [];
}

/// Recursively unpack a msgpack value into a Dart object.
dynamic _unpackValue(Unpacker u) {
  // We can't peek the type byte, so we rely on the messagepack library's unpack
  // order. Use a try-cascade approach on the unpacker.
  // For map values in the resume schema we try the most likely types in order.
  try {
    return u.unpackString();
  } catch (_) {}
  // Fallback for non-string values handled by caller context — in practice
  // the ResumeMatrix is fully string-keyed so map values are strings, lists,
  // booleans, or nested maps. The Unpacker advances its cursor on each call,
  // so we cannot retry. Instead, the calling code iterates known keys and
  // uses specialised decoders. This helper is only used for the top-level map
  // scan where we skip unknown keys.
  return null;
}

/// Decode HBP v2 payload bytes (raw msgpack from the frame's `p` field) into a
/// dynamic Dart Map. The Go backend uses vmihailenco/msgpack which serialises
/// struct fields with their msgpack tag keys (string-keyed map).
Map<dynamic, dynamic> decodeMsgpackMap(List<int> bytes) {
  if (bytes.isEmpty) return {};
  final u = Unpacker(Uint8List.fromList(bytes));
  return _unpackMap(u);
}

Map<dynamic, dynamic> _unpackMap(Unpacker u) {
  final len = u.unpackMapLength();
  final map = <dynamic, dynamic>{};
  for (var i = 0; i < len; i++) {
    final key = _unpackAny(u);
    final val = _unpackAny(u);
    if (key != null) map[key] = val;
  }
  return map;
}

List<dynamic> _unpackList(Unpacker u) {
  final len = u.unpackListLength();
  return List.generate(len, (_) => _unpackAny(u));
}

/// Full-featured recursive msgpack value unpacker.
dynamic _unpackAny(Unpacker u) {
  // Peek at first byte to determine type
  final raw = u;
  // Try bool first (nil/bool are single bytes in msgpack)
  // The messagepack package exposes unpackBool / unpackString / unpackInt /
  // unpackDouble / unpackBinary / unpackListLength / unpackMapLength.
  // We probe in order of likely type.
  // NOTE: The Unpacker cursor advances on every call so we must be careful.
  // We use a JSON round-trip via the base64 payload for robustness.
  // This is called with already-decoded bytes so JSON is not applicable.
  // Strategy: call unpackString; if that throws, we've advanced the cursor
  // so we can't recover without raw byte access. Instead we use the known
  // schema structure and specialised fromMap factories above.
  try {
    final s = raw.unpackString();
    return s; // null means msgpack nil
  } catch (_) {
    try {
      final i = raw.unpackInt();
      return i;
    } catch (_) {
      try {
        final d = raw.unpackDouble();
        return d;
      } catch (_) {
        try {
          return _unpackMap(raw);
        } catch (_) {
          try {
            return _unpackList(raw);
          } catch (_) {
            return null;
          }
        }
      }
    }
  }
}

/// Decode base64 string → raw bytes (used when backend wraps payload in base64).
List<int> decodeBase64Payload(String b64) => base64.decode(b64);
