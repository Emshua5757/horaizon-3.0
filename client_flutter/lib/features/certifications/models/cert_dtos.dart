library;

/// Certification DTOs for shua.diary.cert.* operations.
/// All fields map directly to cert_repository.ts / TASK-017B data model.

class CertEntryDto {
  final String id;
  final String userId;
  final String name;
  final String issuer;
  final String examCode;
  final String credentialId;
  final String credentialUrl;
  final String? vaultDocHash;
  final String status; // 'planned'|'studying'|'exam_scheduled'|'passed'|'failed'|'expired'
  final String category;
  final int roadmapOrder;

  final DateTime? examScheduledAt;
  final String examRegistrationUrl;
  final String examVenue;

  final DateTime? studyStartedAt;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  final double? passingScore;
  final double? achievedScore;
  final String notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CertEntryDto({
    required this.id,
    required this.userId,
    required this.name,
    required this.issuer,
    required this.examCode,
    required this.credentialId,
    required this.credentialUrl,
    this.vaultDocHash,
    required this.status,
    required this.category,
    required this.roadmapOrder,
    this.examScheduledAt,
    required this.examRegistrationUrl,
    required this.examVenue,
    this.studyStartedAt,
    this.issuedAt,
    this.expiresAt,
    this.passingScore,
    this.achievedScore,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CertEntryDto.fromMap(Map<dynamic, dynamic> m) {
    return CertEntryDto(
      id:                  m['id'] as String,
      userId:              m['userId'] as String? ?? 'shua',
      name:                m['name'] as String? ?? '',
      issuer:              m['issuer'] as String? ?? '',
      examCode:            m['examCode'] as String? ?? '',
      credentialId:        m['credentialId'] as String? ?? '',
      credentialUrl:       m['credentialUrl'] as String? ?? '',
      vaultDocHash:        m['vaultDocHash'] as String?,
      status:              m['status'] as String? ?? 'planned',
      category:            m['category'] as String? ?? 'general',
      roadmapOrder:        (m['roadmapOrder'] as num?)?.toInt() ?? 0,
      examScheduledAt:     m['examScheduledAt'] != null ? DateTime.tryParse(m['examScheduledAt'] as String) : null,
      examRegistrationUrl: m['examRegistrationUrl'] as String? ?? '',
      examVenue:           m['examVenue'] as String? ?? 'online_proctored',
      studyStartedAt:      m['studyStartedAt'] != null ? DateTime.tryParse(m['studyStartedAt'] as String) : null,
      issuedAt:            m['issuedAt'] != null ? DateTime.tryParse(m['issuedAt'] as String) : null,
      expiresAt:           m['expiresAt'] != null ? DateTime.tryParse(m['expiresAt'] as String) : null,
      passingScore:        (m['passingScore'] as num?)?.toDouble(),
      achievedScore:       (m['achievedScore'] as num?)?.toDouble(),
      notes:               m['notes'] as String? ?? '',
      createdAt:           DateTime.parse(m['createdAt'] as String),
      updatedAt:           DateTime.parse(m['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id':                  id,
    'userId':              userId,
    'name':                name,
    'issuer':              issuer,
    'examCode':            examCode,
    'credentialId':        credentialId,
    'credentialUrl':       credentialUrl,
    'vaultDocHash':        vaultDocHash,
    'status':              status,
    'category':            category,
    'roadmapOrder':        roadmapOrder,
    'examScheduledAt':     examScheduledAt?.toIso8601String(),
    'examRegistrationUrl': examRegistrationUrl,
    'examVenue':           examVenue,
    'studyStartedAt':      studyStartedAt?.toIso8601String(),
    'issuedAt':            issuedAt?.toIso8601String(),
    'expiresAt':           expiresAt?.toIso8601String(),
    'passingScore':        passingScore,
    'achievedScore':       achievedScore,
    'notes':               notes,
    'createdAt':           createdAt.toIso8601String(),
    'updatedAt':           updatedAt.toIso8601String(),
  };
}

class CertResourceDto {
  final String id;
  final String certId;
  final String title;
  final String url;
  final String type; // 'course'|'practice_exam'|'documentation'|'video'|'cheatsheet'|'book'
  final String platform;
  final double estimatedHours;
  final bool isFree;
  final double cost; // PHP
  final int priority;
  final int sortOrder;

  const CertResourceDto({
    required this.id,
    required this.certId,
    required this.title,
    required this.url,
    required this.type,
    required this.platform,
    required this.estimatedHours,
    required this.isFree,
    required this.cost,
    required this.priority,
    required this.sortOrder,
  });

  factory CertResourceDto.fromMap(Map<dynamic, dynamic> m) {
    return CertResourceDto(
      id:             m['id'] as String,
      certId:         m['certId'] as String,
      title:          m['title'] as String? ?? '',
      url:            m['url'] as String? ?? '',
      type:           m['type'] as String? ?? 'course',
      platform:       m['platform'] as String? ?? '',
      estimatedHours: (m['estimatedHours'] as num?)?.toDouble() ?? 0.0,
      isFree:         m['isFree'] as bool? ?? false,
      cost:           (m['cost'] as num?)?.toDouble() ?? 0.0,
      priority:       (m['priority'] as num?)?.toInt() ?? 2,
      sortOrder:      (m['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class CertResourceProgressDto {
  final String id;
  final String resourceId;
  final int completedSections;
  final int totalSections;
  final int percentComplete;
  final DateTime? lastStudiedAt;
  final String notes;

  const CertResourceProgressDto({
    required this.id,
    required this.resourceId,
    required this.completedSections,
    required this.totalSections,
    required this.percentComplete,
    this.lastStudiedAt,
    required this.notes,
  });

  factory CertResourceProgressDto.fromMap(Map<dynamic, dynamic> m) {
    return CertResourceProgressDto(
      id:                m['id'] as String,
      resourceId:        m['resourceId'] as String,
      completedSections: (m['completedSections'] as num?)?.toInt() ?? 0,
      totalSections:     (m['totalSections'] as num?)?.toInt() ?? 0,
      percentComplete:   (m['percentComplete'] as num?)?.toInt() ?? 0,
      lastStudiedAt:     m['lastStudiedAt'] != null ? DateTime.tryParse(m['lastStudiedAt'] as String) : null,
      notes:             m['notes'] as String? ?? '',
    );
  }
}

class CertInvestmentDto {
  final String id;
  final String? certId;
  final String description;
  final String type; // 'exam_fee'|'course'|'book'|'equipment'|'other'
  final double amountPhp;
  final DateTime paidAt;
  final String? receiptVaultHash;
  final String notes;

  const CertInvestmentDto({
    required this.id,
    this.certId,
    required this.description,
    required this.type,
    required this.amountPhp,
    required this.paidAt,
    this.receiptVaultHash,
    required this.notes,
  });

  factory CertInvestmentDto.fromMap(Map<dynamic, dynamic> m) {
    return CertInvestmentDto(
      id:               m['id'] as String,
      certId:           m['certId'] as String?,
      description:      m['description'] as String? ?? '',
      type:             m['type'] as String? ?? 'exam_fee',
      amountPhp:        (m['amountPhp'] as num?)?.toDouble() ?? 0.0,
      paidAt:           DateTime.parse(m['paidAt'] as String),
      receiptVaultHash: m['receiptVaultHash'] as String?,
      notes:            m['notes'] as String? ?? '',
    );
  }
}

class CertDashboardDto {
  final int totalCerts;
  final Map<String, int> byStatus;
  final CertEntryDto? nextExam;
  final int? nextExamDaysUntil;
  final double totalInvestedPhp;
  final List<CertEntryDto> roadmap;

  const CertDashboardDto({
    required this.totalCerts,
    required this.byStatus,
    this.nextExam,
    this.nextExamDaysUntil,
    required this.totalInvestedPhp,
    required this.roadmap,
  });

  factory CertDashboardDto.fromMap(Map<dynamic, dynamic> m) {
    final nextExamMap = m['nextExam'] as Map?;
    final statusMap = (m['byStatus'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {};
    final roadmapList = (m['roadmap'] as List?)?.map((e) => CertEntryDto.fromMap(e as Map)).toList() ?? [];

    return CertDashboardDto(
      totalCerts:        (m['totalCerts'] as num?)?.toInt() ?? 0,
      byStatus:          statusMap,
      nextExam:          nextExamMap != null && nextExamMap['cert'] != null ? CertEntryDto.fromMap(nextExamMap['cert'] as Map) : null,
      nextExamDaysUntil: nextExamMap != null ? (nextExamMap['daysUntil'] as num?)?.toInt() : null,
      totalInvestedPhp:  (m['totalInvestedPhp'] as num?)?.toDouble() ?? 0.0,
      roadmap:           roadmapList,
    );
  }
}
