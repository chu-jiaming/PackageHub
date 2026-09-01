import 'package:packagehub/models/pickup_credential.dart';
import 'package:packagehub/models/pickup_credential_draft.dart';
import 'package:packagehub/models/pickup_reminder_settings.dart';

class PickupReminderService {
  const PickupReminderService();

  List<PickupCredential> dueCredentials(
    Iterable<PickupCredential> credentials, {
    required PickupReminderSettings settings,
    DateTime? now,
  }) {
    if (!settings.enabled) return [];
    final cutoff = (now ?? DateTime.now()).subtract(Duration(days: settings.days));
    return credentials.where((credential) =>
        credential.status == PickupStatus.pending &&
        !credential.createdAt.isAfter(cutoff)).toList();
  }
}
