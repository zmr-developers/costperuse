class UsageLog {
  final int? id;
  final int purchaseId;
  final String usageDate;
  final String? notes;

  UsageLog({this.id, required this.purchaseId, required this.usageDate, this.notes});

  Map<String, dynamic> toMap() => {
    'id': id,
    'purchaseId': purchaseId,
    'usageDate': usageDate,
    'notes': notes,
  };

  factory UsageLog.fromMap(Map<String, dynamic> map) => UsageLog(
    id: map['id'],
    purchaseId: map['purchaseId'],
    usageDate: map['usageDate'],
    notes: map['notes'],
  );
}
