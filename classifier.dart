import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Caminhos dos arquivos do modelo e vocabulário
/// OBS: os arquivos precisam estar declarados no pubspec.yaml
const _modelFile = 'assets/text_classification.tflite';
const _vocabFile = 'assets/vocab';

/// Comprimento máximo da sentença (padrão 256, igual ao modelo de treino)
const int _sentenceLen = 256;

/// Tokens especiais utilizados no vocabulário
const String start = '<START>';
const String pad = '<PAD>';
const String unk = '<UNKNOWN>';

/// Classe responsável por carregar o modelo e realizar as classificações
class Classifier {
  /// Dicionário de palavras (vocabulário)
  final _dict = <String, int>{};

  /// Interpretador do modelo TensorFlow Lite
  late Interpreter _interpreter;

  /// Inicializa o classificador:
  /// - Carrega o modelo TFLite
  /// - Carrega o vocabulário
  Future<void> init() async {
    await Future.wait([_loadModel(), _loadDictionary()]);
  }

  /// Carrega o modelo TFLite da pasta assets
  Future<void> _loadModel() async {
    final options = InterpreterOptions();

    // Usa XNNPackDelegate no Android para otimização de CPU
    if (Platform.isAndroid) {
      options.addDelegate(XNNPackDelegate());
    }

    // Usa GpuDelegate no iOS para aceleração de GPU
    if (Platform.isIOS) {
      options.addDelegate(GpuDelegate());
    }

    // Carrega o modelo .tflite dos assets com as opções configuradas
    _interpreter = await Interpreter.fromAsset(_modelFile, options: options);
  }

  /// Carrega o arquivo de vocabulário (palavra -> índice)
  Future<void> _loadDictionary() async {
    // Lê o arquivo 'vocab' como texto
    final vocab = await rootBundle.loadString(_vocabFile);

    // Cada linha do vocabulário possui o formato "palavra índice"
    _dict.addEntries(
      vocab
          .split('\n') // separa por linha
          .map((e) => e.trim().split(' ')) // separa palavra e índice
          .where((e) => e.length == 2) // garante linhas válidas
          .map(
            (e) => MapEntry(e[0], int.parse(e[1])),
          ), // converte para MapEntry
    );
  }

  /// Converte o texto de entrada em uma sequência de números (tokenização)
  List<List<double>> tokenizeInputText(String text) {
    // Divide o texto por espaço (simples tokenização)
    final toks = text.split(' ');

    // Cria um vetor fixo de tamanho _sentenceLen com os índices das palavras
    final vec = List<double>.generate(_sentenceLen, (index) {
      // Se o índice for maior que o tamanho da frase, aplica padding
      if (index >= toks.length) {
        return _dict[pad]!.toDouble();
      }

      // Palavra atual
      final tok = toks[index];

      // Retorna o índice da palavra ou o índice de <UNKNOWN>
      return _dict.containsKey(tok)
          ? _dict[tok]!.toDouble()
          : _dict[unk]!.toDouble();
    });

    // O modelo espera uma lista bidimensional [1, sentenceLen]
    return [vec];
  }

  /// Executa a inferência (classificação do texto)
  /// Retorna uma lista com duas probabilidades [negativo, positivo]
  List<double> classify(String rawText) {
    // Tokeniza o texto
    final input = tokenizeInputText(rawText);

    // Cria a estrutura do output esperada pelo modelo (2 classes)
    final output = <List<double>>[List<double>.filled(2, 0)];

    // Executa o modelo
    _interpreter.run(input, output);

    // Retorna as probabilidades
    return [output[0][0], output[0][1]];
  }
}
