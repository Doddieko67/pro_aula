// lib/screens/ai_physics_assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_aula/core/theme/app_theme.dart';
import 'package:pro_aula/widgets/main_bottom_navigation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// Modelo para mensajes del chat
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

// Provider para el estado del chat
final chatMessagesProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
      return ChatNotifier();
    });

final isLoadingProvider = StateProvider<bool>((ref) => false);

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void updateLastMessage(ChatMessage message) {
    if (state.isNotEmpty) {
      final newState = [...state];
      newState[newState.length - 1] = message;
      state = newState;
    }
  }

  void updateLastMessageContent(String newContent) {
    if (state.isNotEmpty) {
      final newState = [...state];
      final lastMessage = newState[newState.length - 1];
      newState[newState.length - 1] = ChatMessage(
        id: lastMessage.id,
        content: newContent,
        isUser: lastMessage.isUser,
        timestamp: lastMessage.timestamp,
        isError: lastMessage.isError,
      );
      state = newState;
    }
  }

  void clearChat() {
    state = [];
  }
}

class AIPhysicsAssistantScreen extends ConsumerStatefulWidget {
  const AIPhysicsAssistantScreen({super.key});

  @override
  ConsumerState<AIPhysicsAssistantScreen> createState() =>
      _AIPhysicsAssistantScreenState();
}

class _AIPhysicsAssistantScreenState
    extends ConsumerState<AIPhysicsAssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _welcomeAnimationController;
  late Animation<double> _welcomeAnimation;

  // Configuración de Gemini
  late GenerativeModel _model;
  late ChatSession _chatSession;

  // Preguntas sugeridas
  final List<String> _suggestedQuestions = [
    "¿Qué es la velocidad y la aceleración?",
    "Explica la segunda ley de Newton",
    "¿Cómo funciona la refracción de la luz?",
    "¿Qué es la energía cinética?",
    "Diferencia entre trabajo y potencia",
    "¿Qué son las ondas electromagnéticas?",
  ];

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _welcomeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _welcomeAnimation = CurvedAnimation(
      parent: _welcomeAnimationController,
      curve: Curves.easeInOut,
    );
    _welcomeAnimationController.forward();

    // MODIFICACIÓN CLAVE AQUÍ: Evitar mensajes de bienvenida duplicados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentMessages = ref.read(chatMessagesProvider);
      if (currentMessages.isEmpty) {
        _addWelcomeMessage();
      }
    });
  }

  void _initializeGemini() {
    const apiKey = 'AIzaSyDPMJelJMOG8bFX-N0yGydkESt0BXQTJ1s';

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system('''
Eres un asistente especializado en física para estudiantes. Tu objetivo es explicar conceptos de física de manera clara, didáctica y comprensible.

Características que debes seguir:
- Explica conceptos desde lo básico hasta lo avanzado
- Usa ejemplos cotidianos y prácticos
- Incluye fórmulas cuando sea necesario
- Organiza las respuestas con viñetas y estructura clara
- Usa emojis ocasionalmente para hacer más amigables las explicaciones
- Si no sabes algo específico, admítelo y sugiere alternativas
- Mantén un tono amigable y educativo
- Enfócate solo en temas de física

Áreas que puedes cubrir:
- Mecánica clásica
- Termodinámica
- Electromagnetismo
- Óptica
- Ondas
- Física moderna (relatividad, mecánica cuántica)
- Problemas y ejercicios de física

Siempre termina preguntando si el estudiante quiere que profundices en algún aspecto específico o si tiene más dudas.
'''),
    );

    _chatSession = _model.startChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _welcomeAnimationController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: 'welcome',
      content:
          '¡Hola! 👋 Soy tu asistente de física con IA. Puedo ayudarte a entender conceptos de física, resolver problemas y responder todas tus dudas. ¿En qué puedo ayudarte hoy?',
      isUser: false,
      timestamp: DateTime.now(),
    );
    ref.read(chatMessagesProvider.notifier).addMessage(welcomeMessage);
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _messageController.clear();

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    ref.read(chatMessagesProvider.notifier).addMessage(userMessage);

    _scrollToBottom();

    try {
      final response = await _chatSession.sendMessage(Content.text(message));

      if (response.text != null) {
        final aiResponse = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: response.text!,
          isUser: false,
          timestamp: DateTime.now(),
        );

        ref.read(chatMessagesProvider.notifier).addMessage(aiResponse);
      } else {
        _addErrorMessage(
          'No pude generar una respuesta. ¿Podrías reformular tu pregunta?',
        );
      }
    } catch (error) {
      String errorMessage =
          'Lo siento, no pude procesar tu pregunta en este momento.';

      if (error.toString().contains('API_KEY')) {
        errorMessage =
            'Error de configuración. Por favor, verifica la configuración de la API.';
      } else if (error.toString().contains('quota')) {
        errorMessage =
            'Se ha alcanzado el límite de uso de la API. Intenta más tarde.';
      } else if (error.toString().contains('network') ||
          error.toString().contains('connection')) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet.';
      }

      _addErrorMessage(errorMessage);
      debugPrint('Error de Gemini: $error');
    }

    _scrollToBottom();
  }

  void _addErrorMessage(String errorText) {
    final errorMessage = ChatMessage(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      content: errorText,
      isUser: false,
      timestamp: DateTime.now(),
      isError: true,
    );
    ref.read(chatMessagesProvider.notifier).addMessage(errorMessage);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Chat'),
        content: const Text(
          '¿Estás seguro de que quieres borrar toda la conversación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(chatMessagesProvider.notifier).clearChat();
              ref.read(isLoadingProvider.notifier).state = false;
              _chatSession = _model.startChat();
              Navigator.pop(context);
              _addWelcomeMessage();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(isLoadingProvider);

    final bool showSuggestedQuestionsInList = messages.length <= 1;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Asistente de Física IA'),
            if (isLoading) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.golden),
                ),
              ),
            ],
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _clearChat,
            tooltip: 'Limpiar chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                (messages.isEmpty ||
                    (messages.length == 1 && messages[0].id == 'welcome'))
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () async {
                      // Funcionalidad de refresh si la necesitas
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          messages.length +
                          (showSuggestedQuestionsInList ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < messages.length) {
                          return _buildMessageCard(
                            messages[index],
                            index == messages.length - 1 &&
                                !showSuggestedQuestionsInList,
                          );
                        } else {
                          return _buildSuggestedQuestions();
                        }
                      },
                    ),
                  ),
          ),
          _buildInputArea(),
        ],
      ),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _welcomeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                // ¡AÑADIR SingleChildScrollView AQUÍ!
                child: SingleChildScrollView(
                  child: Column(
                    // <--- Esta es la Column en la línea 398
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.peachy,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          size: 48,
                          color: AppColors.vibrantRed,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '¡Hola! Soy tu tutor de física',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pregúntame sobre cualquier concepto de física, desde mecánica básica hasta física cuántica',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.golden.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.golden, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: AppColors.golden,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Potenciado por Gemini',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.golden,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ), // Fin de SingleChildScrollView
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(ChatMessage message, bool isLast) {
    final isStreaming = isLast && !message.isUser && message.content.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        margin: EdgeInsets.only(
          left: message.isUser ? 48 : 0,
          right: message.isUser ? 0 : 48,
        ),
        color: message.isError ? AppColors.error.withOpacity(0.1) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del mensaje
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: message.isError
                          ? AppColors.error.withOpacity(0.2)
                          : message.isUser
                          ? AppColors.vibrantRed.withOpacity(0.2)
                          : AppColors.golden.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      message.isError
                          ? Icons.error_outline
                          : message.isUser
                          ? Icons.person_outline
                          : Icons.psychology_outlined,
                      color: message.isError
                          ? AppColors.error
                          : message.isUser
                          ? AppColors.vibrantRed
                          : AppColors.golden,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.isError
                        ? 'Error'
                        : message.isUser
                        ? 'Tú'
                        : 'Gemini',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: message.isError
                          ? AppColors.error
                          : message.isUser
                          ? AppColors.vibrantRed
                          : AppColors.golden,
                    ),
                  ),
                  const Spacer(),
                  if (isStreaming) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.golden.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.golden,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Escribiendo...',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.golden,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      _formatTime(message.timestamp),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      message.content,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                  if (isStreaming) ...[
                    const SizedBox(width: 4),
                    _buildBlinkingCursor(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlinkingCursor() {
    return AnimatedBuilder(
      animation: _welcomeAnimationController,
      builder: (context, child) {
        return AnimatedOpacity(
          opacity: (DateTime.now().millisecondsSinceEpoch ~/ 500) % 2 == 0
              ? 1.0
              : 0.0,
          duration: const Duration(milliseconds: 500),
          child: Container(
            width: 2,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.golden,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestedQuestions() {
    return Card(
      margin: const EdgeInsets.only(top: 16, bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: AppColors.golden,
                ),
                const SizedBox(width: 8),
                Text(
                  'Preguntas sugeridas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestedQuestions.map((question) {
                return InkWell(
                  onTap: () => _sendMessage(question),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.peachy,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.golden.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      question,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Consumer(
      builder: (context, ref, child) {
        final isLoading = ref.watch(isLoadingProvider);

        return Card(
          margin: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: isLoading
                          ? 'Generando respuesta...'
                          : 'Pregúntame sobre física...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: isLoading ? null : _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () => _sendMessage(_messageController.text),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.surface,
                            ),
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Ahora';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
