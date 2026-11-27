import 'package:hive/hive.dart';

import '../../domain/entities/ingredient.dart';

class IngredientModel {
  const IngredientModel({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.expiryDate,
    required this.addedAt,
    this.status = 'active',
    this.statusChangedAt,
  });

  final String id;
  final String name;
  final double? quantity;
  final String? unit;
  final DateTime? expiryDate;
  final DateTime addedAt;
  final String status;
  final DateTime? statusChangedAt;

  factory IngredientModel.fromEntity(Ingredient entity) {
    return IngredientModel(
      id: entity.id,
      name: entity.name,
      quantity: entity.quantity,
      unit: entity.unit,
      expiryDate: entity.expiryDate,
      addedAt: entity.addedAt,
      status: entity.status.name,
      statusChangedAt: entity.statusChangedAt,
    );
  }

  Ingredient toEntity() {
    final IngredientStatus parsedStatus = switch (status) {
      'used' => IngredientStatus.used,
      'discarded' => IngredientStatus.discarded,
      _ => IngredientStatus.active,
    };

    return Ingredient(
      id: id,
      name: name,
      quantity: quantity,
      unit: unit,
      expiryDate: expiryDate,
      addedAt: addedAt,
      status: parsedStatus,
      statusChangedAt: statusChangedAt,
    );
  }

  IngredientModel copyWith({
    String? id,
    String? name,
    double? Function()? quantity,
    String? Function()? unit,
    DateTime? Function()? expiryDate,
    DateTime? addedAt,
    String? status,
    DateTime? Function()? statusChangedAt,
  }) {
    return IngredientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity != null ? quantity() : this.quantity,
      unit: unit != null ? unit() : this.unit,
      expiryDate: expiryDate != null ? expiryDate() : this.expiryDate,
      addedAt: addedAt ?? this.addedAt,
      status: status ?? this.status,
      statusChangedAt:
          statusChangedAt != null ? statusChangedAt() : this.statusChangedAt,
    );
  }
}

/// Manual TypeAdapter for [IngredientModel].
/// Tolerates missing fields for forward/backward compatibility.
class IngredientModelAdapter extends TypeAdapter<IngredientModel> {
  @override
  final int typeId = 0;

  @override
  IngredientModel read(BinaryReader reader) {
    final int numOfFields = reader.readByte();
    final Map<int, dynamic> fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return IngredientModel(
      id: fields[0] as String? ?? '',
      name: fields[1] as String? ?? '',
      quantity: fields[2] as double?,
      unit: fields[3] as String?,
      expiryDate: fields[4] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[4] as int)
          : null,
      addedAt: fields[5] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[5] as int)
          : DateTime.now(),
      status: fields[6] as String? ?? 'active',
      statusChangedAt: fields[7] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[7] as int)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, IngredientModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.expiryDate?.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.addedAt.millisecondsSinceEpoch)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.statusChangedAt?.millisecondsSinceEpoch);
  }
}
