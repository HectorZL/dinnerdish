import 'package:hive/hive.dart';
import 'package:dinnerhome/exceptions/validation_exception.dart';

part 'additional_source.g.dart';

/// Identifies where an additional definition comes from.
///
/// Keeping this value on every relationship prevents a special additional
/// from being interpreted as a reusable global catalog entry.
@HiveType(typeId: 21)
enum AdditionalSource {
  @HiveField(0)
  global,
  @HiveField(1)
  special,
}

AdditionalSource additionalSourceFromJson(Object? value) {
  if (value is String) {
    for (final source in AdditionalSource.values) {
      if (source.name == value) return source;
    }
  }
  throw InvalidAssignmentException(
    'El origen del adicional debe ser global o especial.',
  );
}
