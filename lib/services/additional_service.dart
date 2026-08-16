import 'package:dinnerhome/models/global_additional.dart';

/// Removes all relationships for a global definition after its deletion has
/// been confirmed and persisted.
typedef RemoveGlobalAdditionalAssignments =
    Future<void> Function(String additionalId);

/// Application contract for the reusable, stock-less additional catalog.
///
/// Implementations must treat [GlobalAdditional] as the canonical definition:
/// assignments refer to its id and never copy its name, price or availability.
/// Deletion is called by the already-confirmed UI flow; implementations may
/// coordinate the relationship cascade after the catalog write succeeds.
abstract class AdditionalService {
  Future<List<GlobalAdditional>> fetchAdditions({bool onlyAvailable = false});
  Future<GlobalAdditional?> getAdditional(String id);
  Future<GlobalAdditional> createAdditional(GlobalAdditional additional);
  Future<GlobalAdditional> updateAdditional(
    String id,
    GlobalAdditional additional,
  );

  /// Deletes one canonical global definition and then its active assignments.
  ///
  /// A failed catalog write must not invoke the assignment cleanup callback.
  Future<void> deleteAdditional(String id);
}
