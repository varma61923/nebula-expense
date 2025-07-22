// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 2;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      amount: fields[3] as double,
      currency: fields[4] as String,
      type: fields[5] as TransactionType,
      category: fields[6] as TransactionCategory,
      walletId: fields[7] as String,
      toWalletId: fields[8] as String?,
      date: fields[9] as DateTime,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
      tags: (fields[12] as List).cast<String>(),
      notes: fields[13] as String?,
      attachments: (fields[14] as List).cast<String>(),
      metadata: (fields[15] as Map).cast<String, dynamic>(),
      location: fields[16] as String?,
      merchant: fields[17] as String?,
      paymentMethod: fields[18] as String?,
      isRecurring: fields[19] as bool,
      recurrencePattern: fields[20] as RecurrencePattern?,
      parentTransactionId: fields[21] as String?,
      isTemplate: fields[22] as bool,
      templateName: fields[23] as String?,
      isDeleted: fields[24] as bool,
      deletedAt: fields[25] as DateTime?,
      exchangeRate: fields[26] as String?,
      originalAmount: fields[27] as double?,
      originalCurrency: fields[28] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(29)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.walletId)
      ..writeByte(8)
      ..write(obj.toWalletId)
      ..writeByte(9)
      ..write(obj.date)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.tags)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.attachments)
      ..writeByte(15)
      ..write(obj.metadata)
      ..writeByte(16)
      ..write(obj.location)
      ..writeByte(17)
      ..write(obj.merchant)
      ..writeByte(18)
      ..write(obj.paymentMethod)
      ..writeByte(19)
      ..write(obj.isRecurring)
      ..writeByte(20)
      ..write(obj.recurrencePattern)
      ..writeByte(21)
      ..write(obj.parentTransactionId)
      ..writeByte(22)
      ..write(obj.isTemplate)
      ..writeByte(23)
      ..write(obj.templateName)
      ..writeByte(24)
      ..write(obj.isDeleted)
      ..writeByte(25)
      ..write(obj.deletedAt)
      ..writeByte(26)
      ..write(obj.exchangeRate)
      ..writeByte(27)
      ..write(obj.originalAmount)
      ..writeByte(28)
      ..write(obj.originalCurrency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrencePatternAdapter extends TypeAdapter<RecurrencePattern> {
  @override
  final int typeId = 3;

  @override
  RecurrencePattern read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurrencePattern(
      type: fields[0] as RecurrenceType,
      interval: fields[1] as int,
      endDate: fields[2] as DateTime?,
      maxOccurrences: fields[3] as int?,
      daysOfWeek: (fields[4] as List?)?.cast<int>(),
      dayOfMonth: fields[5] as int?,
      monthsOfYear: (fields[6] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, RecurrencePattern obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.interval)
      ..writeByte(2)
      ..write(obj.endDate)
      ..writeByte(3)
      ..write(obj.maxOccurrences)
      ..writeByte(4)
      ..write(obj.daysOfWeek)
      ..writeByte(5)
      ..write(obj.dayOfMonth)
      ..writeByte(6)
      ..write(obj.monthsOfYear);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrencePatternAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 10;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionType.income;
      case 1:
        return TransactionType.expense;
      case 2:
        return TransactionType.transfer;
      default:
        return TransactionType.income;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    switch (obj) {
      case TransactionType.income:
        writer.writeByte(0);
        break;
      case TransactionType.expense:
        writer.writeByte(1);
        break;
      case TransactionType.transfer:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionCategoryAdapter extends TypeAdapter<TransactionCategory> {
  @override
  final int typeId = 11;

  @override
  TransactionCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionCategory.food;
      case 1:
        return TransactionCategory.transport;
      case 2:
        return TransactionCategory.entertainment;
      case 3:
        return TransactionCategory.shopping;
      case 4:
        return TransactionCategory.bills;
      case 5:
        return TransactionCategory.healthcare;
      case 6:
        return TransactionCategory.education;
      case 7:
        return TransactionCategory.travel;
      case 8:
        return TransactionCategory.investment;
      case 9:
        return TransactionCategory.salary;
      case 10:
        return TransactionCategory.business;
      case 11:
        return TransactionCategory.other;
      default:
        return TransactionCategory.food;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionCategory obj) {
    switch (obj) {
      case TransactionCategory.food:
        writer.writeByte(0);
        break;
      case TransactionCategory.transport:
        writer.writeByte(1);
        break;
      case TransactionCategory.entertainment:
        writer.writeByte(2);
        break;
      case TransactionCategory.shopping:
        writer.writeByte(3);
        break;
      case TransactionCategory.bills:
        writer.writeByte(4);
        break;
      case TransactionCategory.healthcare:
        writer.writeByte(5);
        break;
      case TransactionCategory.education:
        writer.writeByte(6);
        break;
      case TransactionCategory.travel:
        writer.writeByte(7);
        break;
      case TransactionCategory.investment:
        writer.writeByte(8);
        break;
      case TransactionCategory.salary:
        writer.writeByte(9);
        break;
      case TransactionCategory.business:
        writer.writeByte(10);
        break;
      case TransactionCategory.other:
        writer.writeByte(11);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrenceTypeAdapter extends TypeAdapter<RecurrenceType> {
  @override
  final int typeId = 4;

  @override
  RecurrenceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrenceType.daily;
      case 1:
        return RecurrenceType.weekly;
      case 2:
        return RecurrenceType.monthly;
      case 3:
        return RecurrenceType.yearly;
      default:
        return RecurrenceType.daily;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceType obj) {
    switch (obj) {
      case RecurrenceType.daily:
        writer.writeByte(0);
        break;
      case RecurrenceType.weekly:
        writer.writeByte(1);
        break;
      case RecurrenceType.monthly:
        writer.writeByte(2);
        break;
      case RecurrenceType.yearly:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      category: $enumDecode(_$TransactionCategoryEnumMap, json['category']),
      walletId: json['walletId'] as String,
      toWalletId: json['toWalletId'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      notes: json['notes'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      location: json['location'] as String?,
      merchant: json['merchant'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrencePattern: json['recurrencePattern'] == null
          ? null
          : RecurrencePattern.fromJson(
              json['recurrencePattern'] as Map<String, dynamic>),
      parentTransactionId: json['parentTransactionId'] as String?,
      isTemplate: json['isTemplate'] as bool? ?? false,
      templateName: json['templateName'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      exchangeRate: json['exchangeRate'] as String?,
      originalAmount: (json['originalAmount'] as num?)?.toDouble(),
      originalCurrency: json['originalCurrency'] as String?,
    );

Map<String, dynamic> _$TransactionModelToJson(TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'amount': instance.amount,
      'currency': instance.currency,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'category': _$TransactionCategoryEnumMap[instance.category]!,
      'walletId': instance.walletId,
      'toWalletId': instance.toWalletId,
      'date': instance.date.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'tags': instance.tags,
      'notes': instance.notes,
      'attachments': instance.attachments,
      'metadata': instance.metadata,
      'location': instance.location,
      'merchant': instance.merchant,
      'paymentMethod': instance.paymentMethod,
      'isRecurring': instance.isRecurring,
      'recurrencePattern': instance.recurrencePattern,
      'parentTransactionId': instance.parentTransactionId,
      'isTemplate': instance.isTemplate,
      'templateName': instance.templateName,
      'isDeleted': instance.isDeleted,
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'exchangeRate': instance.exchangeRate,
      'originalAmount': instance.originalAmount,
      'originalCurrency': instance.originalCurrency,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.income: 'income',
  TransactionType.expense: 'expense',
  TransactionType.transfer: 'transfer',
};

const _$TransactionCategoryEnumMap = {
  TransactionCategory.food: 'food',
  TransactionCategory.transport: 'transport',
  TransactionCategory.entertainment: 'entertainment',
  TransactionCategory.shopping: 'shopping',
  TransactionCategory.bills: 'bills',
  TransactionCategory.healthcare: 'healthcare',
  TransactionCategory.education: 'education',
  TransactionCategory.travel: 'travel',
  TransactionCategory.investment: 'investment',
  TransactionCategory.salary: 'salary',
  TransactionCategory.business: 'business',
  TransactionCategory.other: 'other',
};

RecurrencePattern _$RecurrencePatternFromJson(Map<String, dynamic> json) =>
    RecurrencePattern(
      type: $enumDecode(_$RecurrenceTypeEnumMap, json['type']),
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      maxOccurrences: (json['maxOccurrences'] as num?)?.toInt(),
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      dayOfMonth: (json['dayOfMonth'] as num?)?.toInt(),
      monthsOfYear: (json['monthsOfYear'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$RecurrencePatternToJson(RecurrencePattern instance) =>
    <String, dynamic>{
      'type': _$RecurrenceTypeEnumMap[instance.type]!,
      'interval': instance.interval,
      'endDate': instance.endDate?.toIso8601String(),
      'maxOccurrences': instance.maxOccurrences,
      'daysOfWeek': instance.daysOfWeek,
      'dayOfMonth': instance.dayOfMonth,
      'monthsOfYear': instance.monthsOfYear,
    };

const _$RecurrenceTypeEnumMap = {
  RecurrenceType.daily: 'daily',
  RecurrenceType.weekly: 'weekly',
  RecurrenceType.monthly: 'monthly',
  RecurrenceType.yearly: 'yearly',
};
