// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalletModelAdapter extends TypeAdapter<WalletModel> {
  @override
  final int typeId = 0;

  @override
  WalletModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WalletModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      currency: fields[3] as String,
      balance: fields[4] as double,
      type: fields[5] as WalletType,
      colorHex: fields[6] as String,
      iconName: fields[7] as String,
      isHidden: fields[8] as bool,
      isLocked: fields[9] as bool,
      lockPin: fields[10] as String?,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
      metadata: (fields[13] as Map).cast<String, dynamic>(),
      initialBalance: fields[14] as double,
      parentWalletId: fields[15] as String?,
      tags: (fields[16] as List).cast<String>(),
      isArchived: fields[17] as bool,
      notes: fields[18] as String?,
      budgetLimits: (fields[19] as Map).cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, WalletModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.currency)
      ..writeByte(4)
      ..write(obj.balance)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.colorHex)
      ..writeByte(7)
      ..write(obj.iconName)
      ..writeByte(8)
      ..write(obj.isHidden)
      ..writeByte(9)
      ..write(obj.isLocked)
      ..writeByte(10)
      ..write(obj.lockPin)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.metadata)
      ..writeByte(14)
      ..write(obj.initialBalance)
      ..writeByte(15)
      ..write(obj.parentWalletId)
      ..writeByte(16)
      ..write(obj.tags)
      ..writeByte(17)
      ..write(obj.isArchived)
      ..writeByte(18)
      ..write(obj.notes)
      ..writeByte(19)
      ..write(obj.budgetLimits);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WalletStatsAdapter extends TypeAdapter<WalletStats> {
  @override
  final int typeId = 1;

  @override
  WalletStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WalletStats(
      walletId: fields[0] as String,
      totalIncome: fields[1] as double,
      totalExpenses: fields[2] as double,
      currentBalance: fields[3] as double,
      transactionCount: fields[4] as int,
      lastTransactionDate: fields[5] as DateTime,
      categoryExpenses: (fields[6] as Map).cast<String, double>(),
      monthlyExpenses: (fields[7] as Map).cast<String, double>(),
      averageTransactionAmount: fields[8] as double,
      calculatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WalletStats obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.walletId)
      ..writeByte(1)
      ..write(obj.totalIncome)
      ..writeByte(2)
      ..write(obj.totalExpenses)
      ..writeByte(3)
      ..write(obj.currentBalance)
      ..writeByte(4)
      ..write(obj.transactionCount)
      ..writeByte(5)
      ..write(obj.lastTransactionDate)
      ..writeByte(6)
      ..write(obj.categoryExpenses)
      ..writeByte(7)
      ..write(obj.monthlyExpenses)
      ..writeByte(8)
      ..write(obj.averageTransactionAmount)
      ..writeByte(9)
      ..write(obj.calculatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletModel _$WalletModelFromJson(Map<String, dynamic> json) => WalletModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      currency: json['currency'] as String? ?? AppConstants.defaultCurrency,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      type: $enumDecodeNullable(_$WalletTypeEnumMap, json['type']) ??
          WalletType.personal,
      colorHex: json['colorHex'] as String? ?? '#4A90E2',
      iconName: json['iconName'] as String? ?? 'wallet',
      isHidden: json['isHidden'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      lockPin: json['lockPin'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      parentWalletId: json['parentWalletId'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      isArchived: json['isArchived'] as bool? ?? false,
      notes: json['notes'] as String?,
      budgetLimits: (json['budgetLimits'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
    );

Map<String, dynamic> _$WalletModelToJson(WalletModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'currency': instance.currency,
      'balance': instance.balance,
      'type': _$WalletTypeEnumMap[instance.type]!,
      'colorHex': instance.colorHex,
      'iconName': instance.iconName,
      'isHidden': instance.isHidden,
      'isLocked': instance.isLocked,
      'lockPin': instance.lockPin,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'metadata': instance.metadata,
      'initialBalance': instance.initialBalance,
      'parentWalletId': instance.parentWalletId,
      'tags': instance.tags,
      'isArchived': instance.isArchived,
      'notes': instance.notes,
      'budgetLimits': instance.budgetLimits,
    };

const _$WalletTypeEnumMap = {
  WalletType.personal: 'personal',
  WalletType.business: 'business',
  WalletType.savings: 'savings',
  WalletType.investment: 'investment',
  WalletType.hidden: 'hidden',
};

WalletStats _$WalletStatsFromJson(Map<String, dynamic> json) => WalletStats(
      walletId: json['walletId'] as String,
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      currentBalance: (json['currentBalance'] as num).toDouble(),
      transactionCount: (json['transactionCount'] as num).toInt(),
      lastTransactionDate:
          DateTime.parse(json['lastTransactionDate'] as String),
      categoryExpenses: (json['categoryExpenses'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      monthlyExpenses: (json['monthlyExpenses'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      averageTransactionAmount:
          (json['averageTransactionAmount'] as num).toDouble(),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );

Map<String, dynamic> _$WalletStatsToJson(WalletStats instance) =>
    <String, dynamic>{
      'walletId': instance.walletId,
      'totalIncome': instance.totalIncome,
      'totalExpenses': instance.totalExpenses,
      'currentBalance': instance.currentBalance,
      'transactionCount': instance.transactionCount,
      'lastTransactionDate': instance.lastTransactionDate.toIso8601String(),
      'categoryExpenses': instance.categoryExpenses,
      'monthlyExpenses': instance.monthlyExpenses,
      'averageTransactionAmount': instance.averageTransactionAmount,
      'calculatedAt': instance.calculatedAt.toIso8601String(),
    };
