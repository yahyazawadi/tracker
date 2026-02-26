// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CycleEntryAdapter extends TypeAdapter<CycleEntry> {
  @override
  final int typeId = 0;

  @override
  CycleEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CycleEntry(
      date: fields[0] as DateTime,
      notes: fields[1] as String?,
      photoPaths: (fields[2] as List).cast<String>(),
      flowIntensity: fields[3] as String?,
      flowDescription: fields[4] as String?,
      phase: fields[5] as String?,
      symptoms: (fields[6] as Map).cast<String, bool>(),
      moodRating: fields[7] as int?,
      energyLevel: fields[8] as int?,
      painLevel: fields[9] as int?,
      overallFeeling: fields[10] as String?,
      isPredicted: fields[11] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, CycleEntry obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.notes)
      ..writeByte(2)
      ..write(obj.photoPaths)
      ..writeByte(3)
      ..write(obj.flowIntensity)
      ..writeByte(4)
      ..write(obj.flowDescription)
      ..writeByte(5)
      ..write(obj.phase)
      ..writeByte(6)
      ..write(obj.symptoms)
      ..writeByte(7)
      ..write(obj.moodRating)
      ..writeByte(8)
      ..write(obj.energyLevel)
      ..writeByte(9)
      ..write(obj.painLevel)
      ..writeByte(10)
      ..write(obj.overallFeeling)
      ..writeByte(11)
      ..write(obj.isPredicted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
