// lib/services/ai_theme_service.dart
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIThemeService {
  static const String _apiKey = 'AIzaSyDPMJelJMOG8bFX-N0yGydkESt0BXQTJ1s';
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

    // Modelo Imagen 3 para generación de imágenes
    _imageModel = GenerativeModel(
      model: 'imagen-3',
      apiKey: _apiKey,
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

  /// Genera una imagen usando Gemini Imagen 3
  Future<Uint8List?> generateImage(String themeTitle, String themeContent) async {
    try {
      // Crear prompt para imagen educativa
      final prompt = '''
Educational physics diagram for: $themeTitle

Create a clear, scientific illustration showing the key concepts. Include:
- Visual representation of physics principles
- Clean, professional educational style
- Labels and annotations in Spanish
- White or light background
- Suitable for students learning physics

Focus on clarity and educational value.''';

      debugPrint('Generating image with Gemini Imagen 3...');
      
      try {
        // Generar imagen con Imagen 3
        final response = await _imageModel.generateContent([
          Content.text(prompt),
        ]);

        // Por ahora, la API de Imagen 3 en Flutter aún está en desarrollo
        // Usar mensaje de depuración y fallback
        debugPrint('Imagen 3 response received: ${response.text ?? "No text response"}');
        
        // Imagen 3 aún no está completamente soportada en el SDK de Flutter
        // Usar servicio alternativo confiable por ahora
        debugPrint('Using fallback image generation service');
        return await _generateImageWithPollinations(themeTitle, themeContent);
        
      } catch (e) {
        debugPrint('Imagen 3 not available yet in Flutter SDK: $e');
        // Usar servicio alternativo
        return await _generateImageWithPollinations(themeTitle, themeContent);
      }
    } catch (e) {
      debugPrint('Error generating image: $e');
      return null;
    }
  }

  /// Genera imagen usando Pollinations AI como respaldo
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
      
      debugPrint('Generating image with Pollinations (fallback): $cleanPrompt');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'ProAula-EducationApp/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('Pollinations image generated successfully');
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

  /// Genera solo la imagen del tema
  Future<Map<String, dynamic>> generateVisualContent(String themeTitle, String themeContent) async {
    try {
      // Solo generar la imagen
      final imageData = await generateImage(themeTitle, themeContent);

      return {
        'imageData': imageData,
        'hasImage': imageData != null,
      };
    } catch (e) {
      debugPrint('Error generating visual content: $e');
      return {
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