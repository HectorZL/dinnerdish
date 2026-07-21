import 'package:dinnerhome/models/global_additional.dart';

abstract class AdditionalService {
  Future<List<GlobalAdditional>> fetchAdditions({bool onlyAvailable = false});
  Future<GlobalAdditional?> getAdditional(String id);
  Future<GlobalAdditional> createAdditional(GlobalAdditional additional);
  Future<GlobalAdditional> updateAdditional(
    String id,
    GlobalAdditional additional,
  );
  Future<void> deleteAdditional(String id);
}
