import 'package:hive/hive.dart';
import '../../../../core/domain/expiry_priority.dart';
import '../../domain/entities/usage_log_entry.dart';

class UsageLogModel {
  final String id;
  final String ingredientName;
  final double? quantity;
  final String? unit;
  final String action;
  final String priorityAtUsage;
  final String? recipeId;
  final DateTime timestamp;

  const UsageLogModel({
    required this.id,
    required this.ingredientName,
    this.quantity,
    this.unit,
    required this.action,
    required this.priorityAtUsage,
    this.recipeId,
    required this.timestamp,
  });

  factory UsageLogModel.fromEntity(UsageLogEntry entity) {
    return UsageLogModel(
      id: entity.id,
      ingredientName: entity.ingredientName,
      quantity: entity.quantity,
      unit: entity.unit,
      action: entity.action.name,
      priorityAtUsage: entity.priorityAtUsage.name,
      recipeId: entity.recipeId,
      timestamp: entity.timestamp,
    );
  }

  UsageLogEntry toEntity() {
    final actionEnum = UsageAction.values.firstWhere(
      (a) => a.name == action,
      orElse: () => UsageAction.used,
    );
    final priorityEnum = ExpiryPriority.values.firstWhere(
      (p) => p.name == priorityAtUsage,
      orElse: () => ExpiryPriority.medium,
    );

    return UsageLogEntry(
      id: id,
      ingredientName: ingredientName,
      quantity: quantity,
      unit: unit,
      action: actionEnum,
      priorityAtUsage: priorityEnum,
      recipeId: recipeId,
      timestamp: timestamp,
    );
  }
}

class UsageLogModelAdapter extends TypeAdapter<UsageLogModel> {
  @override
  final int typeId = 2;

  @override
  UsageLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UsageLogModel(
      id: fields[0] as String,
      ingredientName: fields[1] as String,
      quantity: fields[2] as double?,
      unit: fields[3] as String?,
      action: fields[4] as String,
      priorityAtUsage: fields[5] as String,
      recipeId: fields[6] as String?,
      timestamp: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UsageLogModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ingredientName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.action)
      ..writeByte(5)
      ..write(obj.priorityAtUsage)
      ..writeByte(6)
      ..write(obj.recipeId)
      ..writeByte(7)
      ..write(obj.timestamp);
  }
}
