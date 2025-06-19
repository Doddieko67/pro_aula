// lib/services/ai_theme_service.dart
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIThemeService {
  static const String _apiKey = 'AIzaSyA2Iani8wy51jBPnXQpTG0_IK9oAEWmeiE';
  late final GenerativeModel _model;
  late final GenerativeModel _imageModel;

  AIThemeService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system('''
Eres un asistente especializado en generar contenido educativo para temas de física.

Cuando te pidan generar un diagrama o imagen conceptual, debes:
1. Crear una descripción detallada del diagrama en texto
2. Incluir explicaciones de cada elemento visual
3. Sugerir cómo se vería visualmente el concepto
4. Usar emojis y símbolos ASCII para representar elementos cuando sea posible

Cuando te hagan preguntas hipotéticas sobre un tema ("¿Qué pasaría si...?"), debes:
1. Explicar el concepto físico involucrado
2. Describir las consecuencias o cambios
3. Dar ejemplos prácticos
4. Mantener las explicaciones claras y educativas
5. Usar un tono conversacional y amigable

Siempre enfócate en la física y mantén las respuestas concisas pero informativas.
'''),
    );

    // Modelo específico para generación de imágenes
    _imageModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system('''
Eres un generador de prompts para crear imágenes educativas de física.

Cuando recibas un tema de física, genera un prompt detallado en inglés para crear una imagen educativa que incluya:
1. Estilo: "Educational illustration", "Scientific diagram", "Physics concept visualization"
2. Elementos visuales específicos del tema
3. Colores educativos y profesionales
4. Etiquetas y anotaciones relevantes
5. Perspectiva clara y didáctica

El prompt debe ser conciso pero detallado, enfocado en la educación y claridad visual.
'''),
    );
  }

  /// Genera un diagrama conceptual para un tema específico
  Future<String> generateDiagram(String themeTitle, String themeContent) async {
    try {
      final prompt = '''
Basándote en el tema de física: "$themeTitle"

Contenido del tema:
$themeContent

Genera un diagrama conceptual detallado que incluya:
1. Una descripción visual del diagrama principal
2. Elementos clave que debe contener
3. Explicación de las relaciones entre elementos
4. Representación ASCII o con emojis cuando sea posible
5. Colores sugeridos para diferentes partes
6. Etiquetas importantes que debería tener

Haz que sea educativo y fácil de entender para estudiantes.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo generar el diagrama. Intenta de nuevo.';
    } catch (e) {
      debugPrint('Error generating diagram: $e');
      return 'Error al generar el diagrama: ${e.toString()}';
    }
  }

  /// Responde preguntas hipotéticas sobre el tema
  Future<String> answerHypothetical(String question, String themeTitle, String themeContent) async {
    try {
      final prompt = '''
Tema de física: "$themeTitle"

Contenido del tema:
$themeContent

Pregunta hipotética del estudiante: "$question"

Responde de manera educativa explicando:
1. Los principios físicos involucrados
2. Qué cambiaría o pasaría en el escenario planteado
3. Ejemplos prácticos o comparaciones
4. Consecuencias físicas del cambio propuesto

Mantén la respuesta clara, concisa y educativa.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo generar una respuesta. Intenta reformular tu pregunta.';
    } catch (e) {
      debugPrint('Error answering hypothetical: $e');
      return 'Error al procesar tu pregunta: ${e.toString()}';
    }
  }

  /// Genera explicaciones adicionales sobre conceptos específicos
  Future<String> explainConcept(String concept, String themeTitle, String themeContent) async {
    try {
      final prompt = '''
Tema de física: "$themeTitle"

Contenido del tema:
$themeContent

El estudiante quiere que expliques más sobre: "$concept"

Proporciona una explicación detallada que incluya:
1. Definición clara del concepto
2. Cómo se relaciona con el tema principal
3. Ejemplos cotidianos
4. Fórmulas relevantes (si aplica)
5. Analogías útiles para entender el concepto

Usa un lenguaje accesible y educativo.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo generar la explicación. Intenta de nuevo.';
    } catch (e) {
      debugPrint('Error explaining concept: $e');
      return 'Error al explicar el concepto: ${e.toString()}';
    }
  }

  /// Genera un prompt para crear una imagen educativa del tema
  Future<String> generateImagePrompt(String themeTitle, String themeContent) async {
    try {
      final prompt = '''
Tema de física: "$themeTitle"

Contenido del tema:
$themeContent

Genera un prompt en inglés para crear una imagen educativa que visualice este concepto de física. 
El prompt debe ser detallado y específico para generar una imagen clara y educativa.
''';

      final response = await _imageModel.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo generar el prompt para la imagen.';
    } catch (e) {
      debugPrint('Error generating image prompt: $e');
      return 'Error al generar prompt de imagen: ${e.toString()}';
    }
  }

  /// Genera una imagen usando diferentes servicios de IA
  Future<Uint8List?> generateImage(String themeTitle, String themeContent) async {
    try {
      // Intentar primero con Pollinations AI (gratuito)
      final imageData = await _generateImageWithPollinations(themeTitle, themeContent);
      if (imageData != null) {
        return imageData;
      }

      // Si Pollinations falla, intentar con otros servicios
      debugPrint('Pollinations failed, trying alternatives...');
      
      return null;
    } catch (e) {
      debugPrint('Error generating image: $e');
      return null;
    }
  }

  /// Genera imagen usando Pollinations AI (servicio gratuito)
  Future<Uint8List?> _generateImageWithPollinations(String themeTitle, String themeContent) async {
    try {
      // Generar un prompt optimizado usando Gemini
      final promptResponse = await _model.generateContent([Content.text('''
Genera un prompt en inglés de máximo 150 caracteres para crear una imagen educativa de física sobre: "$themeTitle"

El prompt debe incluir:
- "educational physics diagram"
- Conceptos clave del tema
- "clean style", "scientific illustration"
- "white background"

Hazlo conciso y específico para generación de imágenes.
''')]);

      final prompt = promptResponse.text ?? 'educational physics diagram $themeTitle clean style white background';
      
      // Limpiar y optimizar el prompt para URL
      final cleanPrompt = prompt
          .replaceAll('"', '')
          .replaceAll('\n', ' ')
          .trim();

      // URL de Pollinations AI
      final url = 'https://image.pollinations.ai/prompt/${Uri.encodeComponent(cleanPrompt)}?width=800&height=600&model=flux';
      
      debugPrint('Generating image with prompt: $cleanPrompt');
      debugPrint('Pollinations URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'ProAula-EducationApp/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('Image generated successfully, size: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        debugPrint('Pollinations error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error with Pollinations: $e');
      return null;
    }
  }

  /// Genera contenido visual completo (descripción + imagen conceptual)
  Future<Map<String, dynamic>> generateVisualContent(String themeTitle, String themeContent) async {
    try {
      // Generar descripción visual en español
      final descriptionPrompt = '''
Tema de física: "$themeTitle"

Contenido del tema:
$themeContent

Genera una descripción visual detallada de cómo se vería un diagrama o ilustración educativa de este tema.
Incluye:
1. 🎨 Elementos visuales principales
2. 🏷️ Etiquetas y anotaciones importantes  
3. 🌈 Colores sugeridos para diferentes elementos
4. 📐 Disposición espacial y perspectiva
5. 💡 Elementos destacados para facilitar el aprendizaje

Describe todo en español de manera clara y educativa.
''';

      final descriptionResponse = await _model.generateContent([Content.text(descriptionPrompt)]);
      final description = descriptionResponse.text ?? 'No se pudo generar la descripción visual.';

      // Generar diagrama ASCII/Unicode artístico
      final diagramPrompt = '''
Tema de física: "$themeTitle"

Crea un diagrama visual usando caracteres ASCII/Unicode que represente este concepto de física.
Usa símbolos como:
- Flechas: → ← ↑ ↓ ↗ ↘ ↙ ↖
- Formas: ■ □ ● ○ ◆ ◇ ▲ △ ▼ ▽
- Líneas: ─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼
- Símbolos: ⚡ 🌊 ⭐ 🔥 ❄️ ⚛️ 🔬 ⚙️

Hazlo educativo y claro, con etiquetas en español.
''';

      final diagramResponse = await _model.generateContent([Content.text(diagramPrompt)]);
      final asciiDiagram = diagramResponse.text ?? 'No se pudo generar el diagrama.';

      // Intentar generar imagen (placeholder por ahora)
      final imageData = await generateImage(themeTitle, themeContent);

      return {
        'description': description,
        'asciiDiagram': asciiDiagram,
        'imageData': imageData,
        'hasImage': imageData != null,
      };
    } catch (e) {
      debugPrint('Error generating visual content: $e');
      return {
        'description': 'Error al generar contenido visual: ${e.toString()}',
        'asciiDiagram': 'Error generando diagrama: ${e.toString()}',
        'imageData': null,
        'hasImage': false,
      };
    }
  }

  /// Genera contenido educativo general sobre el tema
  Future<String> generateEducationalContent(String themeTitle, String themeContent, String requestType) async {
    try {
      final prompt = '''
Tema de física: "$themeTitle"

Contenido del tema:
$themeContent

Tipo de contenido solicitado: "$requestType"

Genera contenido educativo apropiado que complemente el tema principal.
Si es sobre diagramas, describe visualmente cómo se vería.
Si es una pregunta, responde de manera educativa y clara.
Si es una explicación, hazla detallada pero comprensible.

Mantén el enfoque en la física y la educación.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No se pudo generar el contenido solicitado.';
    } catch (e) {
      debugPrint('Error generating educational content: $e');
      return 'Error al generar contenido: ${e.toString()}';
    }
  }
}