import 'package:flutter/material.dart';

import '../models/character.dart';
import '../services/character_api.dart';

class CharactersScreen extends StatefulWidget {
  const CharactersScreen({required this.onLogout, super.key});

  final VoidCallback onLogout;

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  final _api = CharacterApi();
  final _searchController = TextEditingController();
  final _characters = <Character>[];
  final _localOverrides = <int, Character>{};
  final _locallyDeletedIds = <int>{};
  bool _isLoading = true;
  String? _errorMessage;
  String _statusFilter = 'Todos';
  int _nextLocalId = -1;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  @override
  void dispose() {
    _api.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCharacters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final characters = await _api.fetchAllCharacters();
      if (!mounted) return;
      setState(() {
        _characters
          ..removeWhere((character) => character.id > 0)
          ..addAll(
            characters.map(
              (character) => _localOverrides[character.id] ?? character,
            ),
          );
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'No se pudo cargar el catálogo. Revisa tu conexión e inténtalo de nuevo.\n$error';
        _isLoading = false;
      });
    }
  }

  List<Character> get _filteredCharacters {
    final query = _searchController.text.trim().toLowerCase();
    return _characters.where((character) {
      if (_locallyDeletedIds.contains(character.id)) return false;
      final matchesSearch =
          query.isEmpty ||
          character.name.toLowerCase().contains(query) ||
          character.species.toLowerCase().contains(query) ||
          character.origin.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'Todos' ||
          character.status.toLowerCase() == _statusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _openEditor({Character? character}) async {
    final result = await showDialog<Character>(
      context: context,
      builder: (_) => CharacterEditorDialog(character: character),
    );
    if (result == null || !mounted) return;

    setState(() {
      if (character == null) {
        _characters.insert(0, result.copyWith(id: _nextLocalId--));
      } else {
        final index = _characters.indexWhere((item) => item.id == character.id);
        if (index != -1) {
          _characters[index] = result;
          if (result.id > 0) _localOverrides[result.id] = result;
        }
      }
    });
    _showMessage(
      character == null
          ? 'Personaje agregado a esta sesión.'
          : 'Cambios guardados en esta sesión.',
    );
  }

  Future<void> _confirmDelete(Character character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar personaje'),
        content: Text('¿Deseas quitar a ${character.name} de este catálogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _locallyDeletedIds.add(character.id));
    _showMessage('Personaje quitado de esta sesión.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'alive':
        return const Color(0xFFB8E94E);
      case 'dead':
        return const Color(0xFFFF6B78);
      default:
        return const Color(0xFFFFC857);
    }
  }

  @override
  Widget build(BuildContext context) {
    final characters = _filteredCharacters;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PERSONAJES',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: const Color(0xFFB8E94E),
        foregroundColor: const Color(0xFF10151C),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCharacters,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explora el multiverso',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLoading
                          ? 'Conectando con la base de datos interdimensional...'
                          : '${characters.length} personajes encontrados',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .6),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar nombre, especie u origen',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpiar búsqueda',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final status in [
                          'Todos',
                          'Alive',
                          'Dead',
                          'unknown',
                        ])
                          ChoiceChip(
                            label: Text(
                              status == 'unknown' ? 'Unknown' : status,
                            ),
                            selected: _statusFilter == status,
                            onSelected: (_) =>
                                setState(() => _statusFilter = status),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Las altas, ediciones y eliminaciones se guardan solo durante esta sesión; la API externa es de consulta.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .46),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFB8E94E)),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorView(
                  message: _errorMessage!,
                  onRetry: _loadCharacters,
                ),
              )
            else if (characters.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No hay personajes para mostrar.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final columns = width >= 1000
                        ? 5
                        : width >= 760
                        ? 4
                        : width >= 520
                        ? 3
                        : 2;
                    return SliverGrid.builder(
                      itemCount: characters.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: width < 380 ? .67 : .72,
                      ),
                      itemBuilder: (context, index) => _CharacterCard(
                        character: characters[index],
                        statusColor: _statusColor(characters[index].status),
                        onTap: () => _showDetails(characters[index]),
                        onEdit: () => _openEditor(character: characters[index]),
                        onDelete: () => _confirmDelete(characters[index]),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDetails(Character character) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CharacterDetailsScreen(
          character: character,
          statusColor: _statusColor(character.status),
          onEdit: () {
            Navigator.pop(context);
            _openEditor(character: character);
          },
        ),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({
    required this.character,
    required this.statusColor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Character character;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF1A222C),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CharacterImage(image: character.image),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xDD10151C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            character.status,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') onEdit();
                        if (action == 'delete') onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                      icon: const Icon(Icons.more_vert),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${character.species} · ${character.gender}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .58),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterImage extends StatelessWidget {
  const _CharacterImage({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    if (image.isEmpty) {
      return const ColoredBox(
        color: Color(0xFF26313D),
        child: Icon(Icons.person, size: 64),
      );
    }
    return Image.network(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFF26313D),
        child: Icon(Icons.broken_image_outlined, size: 48),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: Color(0xFF26313D),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}

class CharacterDetailsScreen extends StatelessWidget {
  const CharacterDetailsScreen({
    required this.character,
    required this.statusColor,
    required this.onEdit,
    super.key,
  });

  final Character character;
  final Color statusColor;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DETALLES'),
        actions: [
          IconButton(
            tooltip: 'Editar personaje',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _CharacterImage(image: character.image),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  character.name,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.circle, size: 11, color: statusColor),
                    const SizedBox(width: 8),
                    Text('${character.status} · ${character.species}'),
                  ],
                ),
                const SizedBox(height: 20),
                _DetailRow(label: 'Género', value: character.gender),
                _DetailRow(
                  label: 'Tipo',
                  value: character.type.isEmpty
                      ? 'No especificado'
                      : character.type,
                ),
                _DetailRow(label: 'Origen', value: character.origin),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: .55)),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class CharacterEditorDialog extends StatefulWidget {
  const CharacterEditorDialog({this.character, super.key});

  final Character? character;

  @override
  State<CharacterEditorDialog> createState() => _CharacterEditorDialogState();
}

class _CharacterEditorDialogState extends State<CharacterEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _species;
  late final TextEditingController _gender;
  late final TextEditingController _origin;
  late final TextEditingController _image;
  late String _status;

  @override
  void initState() {
    super.initState();
    final character = widget.character;
    _name = TextEditingController(text: character?.name ?? '');
    _species = TextEditingController(text: character?.species ?? '');
    _gender = TextEditingController(text: character?.gender ?? '');
    _origin = TextEditingController(text: character?.origin ?? '');
    _image = TextEditingController(text: character?.image ?? '');
    _status = character?.status ?? 'Alive';
  }

  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    _gender.dispose();
    _origin.dispose();
    _image.dispose();
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio.'
      : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.character;
    Navigator.pop(
      context,
      Character(
        id: existing?.id ?? 0,
        name: _name.text.trim(),
        species: _species.text.trim(),
        gender: _gender.text.trim(),
        origin: _origin.text.trim(),
        image: _image.text.trim(),
        status: _status,
        type: existing?.type ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.character == null ? 'Agregar personaje' : 'Editar personaje',
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editorField(_name, 'Nombre'),
                _editorField(_species, 'Especie'),
                _editorField(_gender, 'Género'),
                _editorField(_origin, 'Origen'),
                TextFormField(
                  controller: _image,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL de imagen (opcional)',
                  ),
                  validator: (value) {
                    final url = value?.trim() ?? '';
                    if (url.isEmpty) return null;
                    final uri = Uri.tryParse(url);
                    if (uri == null ||
                        !uri.hasAuthority ||
                        !['http', 'https'].contains(uri.scheme)) {
                      return 'Ingresa una URL http o https válida.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'Alive', child: Text('Alive')),
                    DropdownMenuItem(value: 'Dead', child: Text('Dead')),
                    DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }

  Widget _editorField(
    TextEditingController controller,
    String label, {
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: required ? _required : null,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
