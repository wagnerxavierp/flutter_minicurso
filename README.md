# Flutter — Fundamentos

Este guia prático e objetivo reúne fundamentos do Flutter, Material 3 e widgets básicos; ciclo de vida de widgets e estado com Provider; navegação/rotas/diálogos; formulários, TextField e máscaras; e assincronismo com Future/Stream/StreamSubscription. Todos os tópicos têm links para a documentação oficial.

## 1) Fundamentos de Flutter, Material 3 e widgets básicos

- Ideia central: tudo é widget (UI declarativa). Widgets podem ser Stateless (sem estado) ou Stateful (com estado e ciclo de vida). A UI é (re)construída pelo método `build`.
- Estrutura mínima: `runApp(MyApp)` define a raiz da árvore; `MaterialApp` provê tema, navegação e componentes Material.

Exemplo rápido com Material 3 e widgets básicos:

```dart
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
	const MyApp({super.key});
	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			debugShowCheckedModeBanner: false,
			theme: ThemeData(
				useMaterial3: true,                    // Habilita Material 3
				colorSchemeSeed: Colors.indigo,        // Gera esquema de cores
			),
			home: const HomePage(),
		);
	}
}

class HomePage extends StatelessWidget {
	const HomePage({super.key});
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Fundamentos')),
			body: Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						const Text('Hello, world'),
						const SizedBox(height: 12),
						ElevatedButton(
							onPressed: () {},
							child: const Text('Botão'),
						),
					],
				),
			),
		);
	}
}
```

- Widgets básicos úteis (o que são e como usar):
	- `Text`: exibe uma string com estilo.
    
		```dart
		const Text(
			'Olá, mundo',
			style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
			textAlign: TextAlign.center,
		)
		```

	- `Row`: organiza widgets na horizontal.
    
		```dart
		Row(
			mainAxisAlignment: MainAxisAlignment.spaceBetween,
			children: const [
				Icon(Icons.star),
				SizedBox(width: 8),
				Text('Favorito'),
			],
		)
		```

	- `Column`: organiza widgets na vertical.
    
		```dart
		Column(
			mainAxisSize: MainAxisSize.min,
			crossAxisAlignment: CrossAxisAlignment.start,
			children: const [
				Text('Título'),
				SizedBox(height: 4),
				Text('Descrição'),
			],
		)
		```

	- `Stack`/`Positioned`: sobrepõe widgets (camadas); `Positioned` define posição dentro do `Stack`.
    
		```dart
		Stack(
			children: [
				Container(width: 120, height: 80, color: Colors.indigo.shade100),
				const Positioned(
					right: 8,
					bottom: 8,
					child: Icon(Icons.play_circle_fill, size: 32),
				),
			],
		)
		```

	- `Container`: caixa versátil para tamanho, padding, margem e decoração.
    
		```dart
		Container(
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: Colors.teal.shade50,
				borderRadius: BorderRadius.circular(8),
				border: Border.all(color: Colors.teal.shade200),
			),
			child: const Text('Conteúdo'),
		)
		```

	- `Expanded`: expande um filho para ocupar espaço disponível dentro de `Row`/`Column`/`Flex`.
    
		```dart
		Row(
			children: [
				Expanded(child: Container(height: 24, color: Colors.blue)),
				const SizedBox(width: 8),
				Expanded(flex: 2, child: Container(height: 24, color: Colors.orange)),
			],
		)
		```

	- `Scaffold`: estrutura de tela Material (app bar, body, FAB, drawer etc.).
    
		```dart
		Scaffold(
			appBar: AppBar(title: const Text('Exemplo')),
			body: const Center(child: Text('Conteúdo')),
			floatingActionButton: FloatingActionButton(
				onPressed: () {},
				child: const Icon(Icons.add),
			),
		)
		```

	- `AppBar`: barra superior com título, navegação e ações.
    
		```dart
		AppBar(
			leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
			title: const Text('Título'),
			actions: [
				IconButton(icon: const Icon(Icons.search), onPressed: () {}),
			],
		)
		```

	- `ElevatedButton`: botão de ação com elevação/realce.
    
		```dart
		ElevatedButton(
			onPressed: () {},
			child: const Text('Enviar'),
		)
		```
- Material 3: use `ThemeData(useMaterial3: true)`. Afeta cores (`ColorScheme`), tipografia (material2021) e estilos de diversos componentes.

Leitura recomendada:
- Building UIs with Flutter: https://docs.flutter.dev/ui
- Catálogo de widgets: https://docs.flutter.dev/ui/widgets
- API ThemeData.useMaterial3: https://api.flutter.dev/flutter/material/ThemeData/useMaterial3.html
- Biblioteca Material: https://api.flutter.dev/flutter/material/

## 2) Ciclo de Vida de Widgets e Gerenciamento de Estado com Provider

### Ciclo de vida essencial (StatefulWidget/State)
- `createState()`: cria o `State` associado.
- `initState()`: inicializações que rodam uma vez (assinar streams, criar controllers). Chame `super.initState()`.
- `didChangeDependencies()`: chamado quando `InheritedWidgets` mudam (ex.: `Localizations`, `Theme`).
- `build()`: descreve a UI.
- `didUpdateWidget(oldWidget)`: quando o pai recria este widget com novas props.
- `setState(() { ... })`: marca o `State` para reconstruir a UI.
- `deactivate()`/`dispose()`: limpeza (cancelar timers/streams/controllers). Chame `super.dispose()`.

Exemplo de ciclo + limpeza:

```dart
class TickerCounter extends StatefulWidget {
	const TickerCounter({super.key});
	@override
	State<TickerCounter> createState() => _TickerCounterState();
}

class _TickerCounterState extends State<TickerCounter> {
	late final StreamSubscription<int> _sub;
	int _value = 0;

	@override
	void initState() {
		super.initState();
		final stream = Stream.periodic(const Duration(seconds: 1), (i) => i + 1);
		_sub = stream.listen((v) {
			if (!mounted) return;
			setState(() => _value = v);
		});
	}

	@override
	void dispose() {
		_sub.cancel();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) => Text('$_value');
}
```

### Provider (estado reativo com ChangeNotifier)
- Defina um modelo que estenda `ChangeNotifier`.
- Exponha com `ChangeNotifierProvider` na árvore.
- Consuma com `context.watch<T>()`, `context.read<T>()` ou `Consumer<T>()`.

Exemplo:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Counter extends ChangeNotifier {
	int value = 0;
	void increment() { value++; notifyListeners(); }
}

void main() {
	runApp(
		ChangeNotifierProvider(
			create: (_) => Counter(),
			child: const MyApp(),
		),
	);
}

class MyApp extends StatelessWidget {
	const MyApp({super.key});
	@override
	Widget build(BuildContext context) => MaterialApp(
				theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
				home: const CounterPage(),
			);
}

class CounterPage extends StatelessWidget {
	const CounterPage({super.key});
	@override
	Widget build(BuildContext context) {
		final count = context.watch<Counter>().value; // reativa
		return Scaffold(
			appBar: AppBar(title: const Text('Provider + ChangeNotifier')),
			body: Center(child: Text('Contador: $count')),
			floatingActionButton: FloatingActionButton(
				onPressed: () => context.read<Counter>().increment(), // não reativa
				child: const Icon(Icons.add),
			),
		);
	}
}
```

Leitura recomendada:
- Introdução a estado: https://docs.flutter.dev/development/data-and-backend/state-mgmt/intro
- Provider (guia oficial do pacote): https://pub.dev/packages/provider

## 3) Navegação, Rotas e Diálogos

### Navegação básica (push/pop)

```dart
Navigator.push(
	context,
	MaterialPageRoute(builder: (_) => const SecondPage()),
);

// ...

Navigator.pop(context);
```

### Rotas nomeadas

Observação: rotas nomeadas têm limitações e não são mais a abordagem recomendada para a maioria dos apps, mas seguem para referência.

```dart
MaterialApp(
	initialRoute: '/',
	routes: {
		'/': (_) => const FirstScreen(),
		'/second': (_) => const SecondScreen(),
	},
);

// Navegar
Navigator.pushNamed(context, '/second');

// Voltar
Navigator.pop(context);
```

### Retornando dados ao voltar

```dart
final result = await Navigator.push<String>(
	context,
	MaterialPageRoute(builder: (_) => const SelectionScreen()),
);
// ... use 'result' (verifique context.mounted após awaits)
```

### Diálogos (showDialog + AlertDialog)

```dart
final confirmed = await showDialog<bool>(
	context: context,
	builder: (ctx) => AlertDialog(
		title: const Text('Confirmar'),
		content: const Text('Deseja continuar?'),
		actions: [
			TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
			FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
		],
	),
);
// confirmed pode ser true/false/null
```

Leitura recomendada:
- Navegação básica: https://docs.flutter.dev/cookbook/navigation/navigation-basics
- Rotas nomeadas: https://docs.flutter.dev/cookbook/navigation/named-routes
- Retornar dados: https://docs.flutter.dev/cookbook/navigation/returning-data
- API showDialog/AlertDialog: https://api.flutter.dev/flutter/material/showDialog.html e https://api.flutter.dev/flutter/material/AlertDialog-class.html

## 4) Formulários, TextField e Máscaras de Entrada

### Form + validação

```dart
class LoginForm extends StatefulWidget {
	const LoginForm({super.key});
	@override
	State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
	final _formKey = GlobalKey<FormState>();
	final _emailCtrl = TextEditingController();

	@override
	void dispose() {
		_emailCtrl.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Form(
			key: _formKey,
			child: Column(
				children: [
					TextFormField(
						controller: _emailCtrl,
						decoration: const InputDecoration(labelText: 'Email'),
						validator: (v) {
							if (v == null || v.isEmpty) return 'Informe o email';
							if (!v.contains('@')) return 'Email inválido';
							return null;
						},
					),
					const SizedBox(height: 12),
					ElevatedButton(
						onPressed: () {
							if (_formKey.currentState!.validate()) {
								ScaffoldMessenger.of(context).showSnackBar(
									const SnackBar(content: Text('Enviando...')),
								);
							}
						},
						child: const Text('Enviar'),
					),
				],
			),
		);
	}
}
```

### TextField e input formatters

- Use `TextField` ou `TextFormField` com `InputDecoration` para rótulo, dica e erro.
- Para restringir caracteres/tamanho, use `TextInputFormatter` (oficial).
- Dicas: `FilteringTextInputFormatter`, `LengthLimitingTextInputFormatter`. Para caracteres complexos/emoji, considere o pacote `characters`.

Exemplos de máscara simples sem pacote externo:

```dart
TextFormField(
	keyboardType: TextInputType.number,
	inputFormatters: const [
		FilteringTextInputFormatter.digitsOnly,   // apenas dígitos
		LengthLimitingTextInputFormatter(11),     // ex: telefone BR sem formatação
	],
	decoration: const InputDecoration(
		labelText: 'Telefone (somente números)',
	),
)
```

Formatter customizado (pontual) com `TextInputFormatter.withFunction`:

```dart
final cpfMask = TextInputFormatter.withFunction((oldValue, newValue) {
	final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
	final b = StringBuffer();
	for (var i = 0; i < digits.length && i < 11; i++) {
		b.write(digits[i]);
		if (i == 2 || i == 5) b.write('.');
		if (i == 8) b.write('-');
	}
	final text = b.toString();
	return TextEditingValue(
		text: text,
		selection: TextSelection.collapsed(offset: text.length),
	);
});

// Uso:
TextField(
	inputFormatters: [cpfMask],
	decoration: const InputDecoration(labelText: 'CPF'),
)
```

Observação: para máscaras complexas (telefone com DDI/DDDs variados, monetária com locale, etc.), uma alternativa prática é usar uma biblioteca da comunidade, mas isso sai do escopo da documentação oficial. Se preferir ficar só no core, implemente via `TextInputFormatter`.

Leitura recomendada:
- Text input: https://docs.flutter.dev/cookbook/forms/text-input
- Form + validação: https://docs.flutter.dev/cookbook/forms/validation
- `TextInputFormatter` (API): https://api.flutter.dev/flutter/services/TextInputFormatter-class.html

## 5) Assincronismo: Future, Stream e StreamSubscription

### Future + async/await

```dart
Future<String> fetchUser() async {
	await Future.delayed(const Duration(milliseconds: 500));
	return 'Dash';
}

Future<void> load() async {
	try {
		final name = await fetchUser();
		debugPrint('Olá, $name');
	} catch (e) {
		debugPrint('Erro: $e');
	}
}
```

### Stream: consumindo com `await for`

```dart
Stream<int> ticks() async* {
	for (var i = 1; i <= 5; i++) {
		await Future.delayed(const Duration(milliseconds: 300));
		yield i;
	}
}

Future<void> sum() async {
	var total = 0;
	await for (final v in ticks()) {
		total += v;
	}
	debugPrint('Soma: $total');
}
```

### StreamSubscription: listen, pause/resume/cancel e limpeza em `dispose`

```dart
class Clock extends StatefulWidget {
	const Clock({super.key});
	@override
	State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
	late final StreamSubscription<int> _sub;
	int _v = 0;

	@override
	void initState() {
		super.initState();
		final s = Stream.periodic(const Duration(seconds: 1), (i) => i).take(10);
		_sub = s.listen((n) {
			if (!mounted) return;
			setState(() => _v = n);
		});
	}

	@override
	void dispose() {
		_sub.cancel(); // sempre cancelar
		super.dispose();
	}

	@override
	Widget build(BuildContext context) => Text('$_v');
}
```

### Dicas
- Sempre tratar erros (try/catch em `async/await` ou `onError` no `listen`).
- Cancele `StreamSubscription` no `dispose`.
- Em callbacks assíncronos que usam `BuildContext`, verifique `context.mounted` após `await`s.

Leitura recomendada:
- Futures, async, await: https://dart.dev/libraries/async/async-await
- Streams (await for, listen, operadores): https://dart.dev/libraries/async/using-streams
- `StreamSubscription` (API): https://api.flutter.dev/flutter/dart-async/StreamSubscription-class.html

## Referências oficiais usadas

- Fundamentos/widgets/lifecycle: https://docs.flutter.dev/ui
- Catálogo de widgets: https://docs.flutter.dev/ui/widgets
- Material 3 (API): https://api.flutter.dev/flutter/material/ThemeData/useMaterial3.html
- Navegação:
	- Básico: https://docs.flutter.dev/cookbook/navigation/navigation-basics
	- Nomeadas: https://docs.flutter.dev/cookbook/navigation/named-routes
	- Retornar dados: https://docs.flutter.dev/cookbook/navigation/returning-data
	- Diálogos (API): https://api.flutter.dev/flutter/material/showDialog.html e https://api.flutter.dev/flutter/material/AlertDialog-class.html
- Formulários e texto:
	- Text input: https://docs.flutter.dev/cookbook/forms/text-input
	- Validação: https://docs.flutter.dev/cookbook/forms/validation
	- Formatadores: https://api.flutter.dev/flutter/services/TextInputFormatter-class.html
- Estado:
	- Introdução a estado: https://docs.flutter.dev/development/data-and-backend/state-mgmt/intro
	- Provider (página do pacote): https://pub.dev/packages/provider
- Assíncrono (Dart):
	- Futures: https://dart.dev/libraries/async/async-await
	- Streams: https://dart.dev/libraries/async/using-streams
	- StreamSubscription: https://api.flutter.dev/flutter/dart-async/StreamSubscription-class.html

---

Com este conjunto você consegue: montar UIs com Material 3, entender quando usar Stateless/Stateful, gerenciar estado de forma escalável com Provider, navegar entre telas (incluindo retorno de dados) e exibir diálogos, construir formulários com validação e entrada formatada, e integrar operações assíncronas com Future/Stream de forma segura no ciclo de vida do Flutter.




# On-Device ML

## Dependências

- `tflite_flutter: ^0.11.0`: Biblioteca para executar modelos TensorFlow Lite no dispositivo.

- Adicionar ativos no assets (text_classification.tflite, vocab):
link oficial text_classification.tflite: https://storagegoogleapis.com/download.tensorflow.org/models/tflite/text_classification/text_classification.tflite

```yaml
flutter:
  assets:
    - assets/models/text_classification.tflite
    - assets/models/vocab
```
