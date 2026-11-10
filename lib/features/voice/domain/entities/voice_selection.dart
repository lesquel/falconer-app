import '../../../settings/domain/entities/app_settings.dart';
import 'voice_catalog.dart';
import 'voice_model.dart';

/// Every model the user can pick: the catalog, then the user's own.
List<VoiceModel> allVoiceModels(AppSettings s) => [...voiceCatalog, ...s.customVoiceModels];

/// The model [s] selects, when it is known.
VoiceModel? selectedVoiceModel(AppSettings s) =>
    allVoiceModels(s).where((m) => m.id == s.voiceModelId).firstOrNull;
