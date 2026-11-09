import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/storage/storage_service.dart';
import '../data/niwas_ai_service.dart';
import '../models/niwas_ai_models.dart';
import '../presentation/save_properties_screen.dart';
import 'buyer_home_controller.dart';

class NiwasAiController extends GetxController {
  final NiwasAiService _aiService = NiwasAiService.instance;

  final RxList<AiChatMessage> messages = <AiChatMessage>[].obs;
  final RxBool isSending = false.obs;
  final RxnString sessionId = RxnString();
  final RxnString selectedPropertyId = RxnString();
  final Rxn<PropertySnapshotData> activeSnapshot = Rxn<PropertySnapshotData>();
  final RxBool snapshotLoading = false.obs;
  final RxnString currentMode = RxnString();

  // History & Sessions State
  final RxList<Map<String, dynamic>> savedSessions = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingHistory = false.obs;

  final ScrollController scrollController = ScrollController();
  final TextEditingController textController = TextEditingController();

  static const String modeFindHome = 'find_home';
  static const String modeCompareHomes = 'compare_homes';
  static const String modeExploreLocality = 'explore_locality';
  static const String modePriceTrends = 'price_trends';

  /// Quick prompts – city comes from the buyer's real (GPS / API) location
  List<String> get quickSuggestions {
    String city = '';
    if (Get.isRegistered<BuyerHomeController>()) {
      final loc = Get.find<BuyerHomeController>().userCurrentLocation.value;
      if (loc.isNotEmpty && loc != 'Fetching location...' && loc != 'India') {
        city = loc.split(',').first.trim();
      }
    }
    final inCity = city.isNotEmpty ? ' in $city' : ' near me';
    return [
      'Find 2 BHK$inCity',
      'Show all available rental properties$inCity',
      'Compare properties$inCity',
      'Commercial properties for lease$inCity',
      'Best residential localities$inCity',
    ];
  }

  @override
  void onInit() {
    super.onInit();
    loadSavedSessions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args is Map) {
        if (args['propertyId'] != null) {
          selectedPropertyId.value = args['propertyId'].toString();
        }
        if (args['mode'] != null) {
          setMode(args['mode'].toString());
        }
      }
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    textController.dispose();
    super.onClose();
  }

  Future<void> loadSavedSessions() async {
    try {
      final list = await StorageService.instance.getSavedAiSessions();
      savedSessions.value = list;
    } catch (_) {}
  }

  /// Loads full conversation history for a given session using GET /v1/sessions/{session_id}/history
  Future<void> loadSessionHistory(String sessId) async {
    if (sessId.trim().isEmpty) return;
    isLoadingHistory.value = true;
    sessionId.value = sessId.trim();
    messages.clear();

    try {
      final rawList = await _aiService.getSessionHistory(sessId.trim());
      if (rawList.isNotEmpty) {
        final parsedMessages = <AiChatMessage>[];
        for (int i = 0; i < rawList.length; i++) {
          final item = rawList[i];
          final role = item['role']?.toString() ?? (item['sender'] == 'user' ? 'user' : 'assistant');
          final content = item['content']?.toString() ?? item['message']?.toString() ?? item['reply']?.toString() ?? '';
          
          List<AiPropertyCard> propertyCards = [];
          if (item['properties'] is List) {
            propertyCards = (item['properties'] as List)
                .whereType<Map<String, dynamic>>()
                .map((p) => AiPropertyCard.fromJson(p))
                .toList();
          }

          List<AiSource> sources = [];
          if (item['sources'] is List) {
            sources = (item['sources'] as List)
                .whereType<Map<String, dynamic>>()
                .map((s) => AiSource.fromJson(s))
                .toList();
          }

          parsedMessages.add(
            AiChatMessage(
              id: item['id']?.toString() ?? item['_id']?.toString() ?? '${sessId}_$i',
              role: role,
              content: content,
              properties: propertyCards,
              sources: sources,
            ),
          );
        }
        messages.value = parsedMessages;
      }
    } catch (_) {
    } finally {
      isLoadingHistory.value = false;
      scrollToBottom();
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String getModeTitle(String? mode) {
    switch (mode) {
      case modeFindHome:
        return 'Find My Home';
      case modeCompareHomes:
        return 'Compare Homes';
      case modeExploreLocality:
        return 'Explore Locality';
      case modePriceTrends:
        return 'Price Trends';
      default:
        return 'Niwas AI';
    }
  }

  String getOpeningQuestion(String mode) {
    switch (mode) {
      case modeFindHome:
        return 'Aap kis type ka property dhoondh rahe hain? Location, budget aur basic requirements bataiye — main aapke liye suitable properties find karta hoon.';
      case modeCompareHomes:
        final hasSaved = _hasSavedProperties();
        if (!hasSaved) {
          return 'Aapne abhi koi property comparison ke liye select nahi ki hai. Properties search karke 2 ya more options choose karein.';
        }
        return 'Kaunsi properties compare karni hain? 2 ya more properties select karein — main price, location, size, amenities aur key differences compare kar dunga.';
      case modeExploreLocality:
        return 'Kis locality ke baare mein jaan-na chahte hain? Main aapko property options, connectivity, nearby facilities aur local insights dikha sakta hoon.';
      case modePriceTrends:
        return 'Kis area ya property type ka price trend dekhna chahte hain? Location select karein aur main available DigiNiwas data ke basis par price movement aur current asking-price range dikhaunga.';
      default:
        return 'Namaste! Main Niwas AI hoon, aapka personal real estate AI assistant. Main aapki kya madad kar sakta hoon?';
    }
  }

  bool _hasSavedProperties() {
    try {
      if (Get.isRegistered<BuyerHomeController>()) {
        final buyerCtrl = Get.find<BuyerHomeController>();
        return buyerCtrl.savedPropertiesList.isNotEmpty;
      }
    } catch (_) {}
    return false;
  }

  List<String> getQuickChips(String mode) {
    switch (mode) {
      case modeFindHome:
        return [
          'Buy / Rent',
          'House / Plot / Flat / Commercial',
          'Select Location',
          'Set Budget',
        ];
      case modeCompareHomes:
        return [
          'Select Saved Properties',
          'Compare Price',
          'Compare Location',
          'Compare Features',
        ];
      case modeExploreLocality:
        return [
          'Select Locality',
          'Nearby Schools',
          'Hospitals & Markets',
          'Properties Available',
        ];
      case modePriceTrends:
        return [
          'Select Location',
          'Plot Prices',
          'House Prices',
          'Commercial Prices',
        ];
      default:
        return quickSuggestions;
    }
  }

  String? getExamplePrompt(String mode) {
    switch (mode) {
      case modeFindHome:
        return '3 BHK house in Ambala under ₹70 lakh.';
      case modeCompareHomes:
        return 'Compare 2 BHK and 3 BHK properties in Ambala';
      case modeExploreLocality:
        return 'Tell me about Model Town, Ambala.';
      case modePriceTrends:
        return 'Show me plot price trends in Sector 9, Ambala.';
      default:
        return null;
    }
  }

  void setMode(String? mode) {
    if (mode == null || mode.isEmpty) {
      if (currentMode.value != null) currentMode.value = null;
      return;
    }
    if (currentMode.value == mode && messages.isNotEmpty) {
      return;
    }
    currentMode.value = mode;
    messages.clear();
    final question = getOpeningQuestion(mode);
    messages.add(AiChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      role: 'assistant',
      content: question,
    ));
    scrollToBottom();
  }

  void handleChipTap(String chip) {
    switch (chip) {
      case 'Buy / Rent':
        textController.text = 'Looking to Buy/Rent ';
        break;
      case 'House / Plot / Flat / Commercial':
        textController.text = 'Looking for House/Flat/Plot in ';
        break;
      case 'Select Location':
        if (currentMode.value == modePriceTrends) {
          textController.text = 'Show me plot price trends in Sector 9, Ambala.';
        } else {
          textController.text = 'Tell me about Model Town, Ambala';
        }
        break;
      case 'Set Budget':
        textController.text = '3 BHK house in Ambala under ₹70 lakh.';
        break;
      case 'Select Saved Properties':
        if (!_hasSavedProperties()) {
          messages.add(AiChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: 'assistant',
            content: 'Aapne abhi koi property comparison ke liye select nahi ki hai. Properties search karke 2 ya more options choose karein.',
          ));
          scrollToBottom();
        } else {
          Get.to(() => SavedPropertiesScreen());
        }
        break;
      case 'Compare Price':
        sendUserMessage('Compare price difference between top properties in Ambala');
        break;
      case 'Compare Location':
        sendUserMessage('Compare location and connectivity of properties in Ambala');
        break;
      case 'Compare Features':
        sendUserMessage('Compare amenities, size and features of top properties');
        break;
      case 'Select Locality':
        textController.text = 'Tell me about Model Town, Ambala';
        break;
      case 'Nearby Schools':
        sendUserMessage('Tell me about top schools near Model Town, Ambala');
        break;
      case 'Hospitals & Markets':
        sendUserMessage('What are the nearby hospitals and markets in Model Town, Ambala?');
        break;
      case 'Properties Available':
        sendUserMessage('What properties are available in Model Town, Ambala?');
        break;
      case 'Plot Prices':
        sendUserMessage('Show me plot price trends in Sector 9, Ambala.');
        break;
      case 'House Prices':
        sendUserMessage('Show me house price trends in Sector 9, Ambala.');
        break;
      case 'Commercial Prices':
        sendUserMessage('Show me commercial property price trends in Sector 9, Ambala.');
        break;
      default:
        sendUserMessage(chip);
    }
  }

  Future<void> sendUserMessage([String? customPrompt]) async {
    final text = (customPrompt ?? textController.text).trim();
    if (text.isEmpty || isSending.value) return;

    if (customPrompt == null) {
      textController.clear();
    }

    // 1. Add user message
    final userMsg = AiChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: text,
    );
    messages.add(userMsg);
    scrollToBottom();

    // 2. Set loading
    isSending.value = true;

    // 3. Call Niwas AI API
    final result = await _aiService.sendChatMessage(
      message: text,
      sessionId: sessionId.value,
      propertyId: selectedPropertyId.value,
    );

    isSending.value = false;

    if (result['success'] == true) {
      final newSessionId = result['session_id']?.toString();
      if (newSessionId != null && newSessionId.isNotEmpty) {
        sessionId.value = newSessionId;
        // Persist session locally and update history
        await StorageService.instance.saveAiSession(sessionId: newSessionId, title: text);
        await loadSavedSessions();
      }

      final assistantMsg = AiChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: result['reply']?.toString() ?? '',
        properties: (result['properties'] as List<AiPropertyCard>?) ?? [],
        sources: (result['sources'] as List<AiSource>?) ?? [],
      );

      messages.add(assistantMsg);
    } else {
      final errorMessage = result['error']?.toString() ??
          'Niwas AI server se connect nahi ho pa raha hai. Kripya apna internet connection check karein ya thodi der baad dobara prayas karein.';
      final assistantMsg = AiChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: errorMessage,
      );
      messages.add(assistantMsg);
    }

    scrollToBottom();
  }

  Future<void> startNewChat() async {
    sessionId.value = null;
    currentMode.value = null;
    messages.clear();
  }

  Future<void> deleteSession(String sessId) async {
    if (sessId.trim().isEmpty) return;
    await _aiService.deleteSession(sessId);
    await StorageService.instance.removeAiSession(sessId);
    await loadSavedSessions();
    if (sessionId.value == sessId) {
      startNewChat();
    }
  }

  Future<void> fetchPropertySnapshot(String propertyId, BuildContext context) async {
    snapshotLoading.value = true;
    activeSnapshot.value = null;

    final snapshot = await _aiService.getPropertySnapshot(propertyId);
    snapshotLoading.value = false;
    activeSnapshot.value = snapshot;
  }
}
