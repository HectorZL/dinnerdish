import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/global_additional.dart';
import '../../providers/providers.dart';
import '../theme/app_theme.dart';

class GlobalAdditionalManagementScreen extends ConsumerStatefulWidget {
  const GlobalAdditionalManagementScreen({super.key});

  @override
  ConsumerState<GlobalAdditionalManagementScreen> createState() =>
      _GlobalAdditionalManagementScreenState();
}

class _GlobalAdditionalManagementScreenState
    extends ConsumerState<GlobalAdditionalManagementScreen> {
  List<GlobalAdditional> _additions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAdditions();
  }

  Future<void> _loadAdditions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final additions = await ref
          .read(additionalServiceProvider)
          .fetchAdditions();
      if (!mounted) return;
      setState(() {
        _additions = additions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showForm({GlobalAdditional? existing}) async {
    final result = await showDialog<GlobalAdditional>(
      context: context,
      builder: (_) => _GlobalAdditionalFormDialog(existing: existing),
    );
    if (result == null) return;

    try {
      final service = ref.read(additionalServiceProvider);
      if (existing == null) {
        await service.createAdditional(result);
      } else {
        await service.updateAdditional(existing.id, result);
      }
      await _loadAdditions();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el adicional: $error')),
      );
    }
  }

  Future<void> _toggleAvailability(GlobalAdditional addition) async {
    try {
      await ref
          .read(additionalServiceProvider)
          .updateAdditional(
            addition.id,
            addition.copyWith(available: !addition.available),
          );
      await _loadAdditions();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el adicional: $error')),
      );
    }
  }

  Future<void> _delete(GlobalAdditional addition) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar adicional'),
        content: Text('¿Eliminar "${addition.name}" del catálogo global?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(additionalServiceProvider).deleteAdditional(addition.id);
      await _loadAdditions();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el adicional: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: _showForm,
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo adicional'),
            ),
      body: Row(
        children: [
          if (isDesktop) const StitchAdminSidebar(activeTab: 'Adicionales'),
          Expanded(
            child: Column(
              children: [
                StitchTopAppBar(
                  title: 'Adicionales globales',
                  showBack: !isDesktop,
                  onBack: () => context.go('/admin/menu'),
                  actions: [
                    if (isDesktop)
                      TextButton.icon(
                        onPressed: _showForm,
                        icon: const Icon(
                          Icons.add,
                          color: AppColors.primaryContainer,
                        ),
                        label: const Text(
                          'Nuevo adicional',
                          style: TextStyle(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadAdditions,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_additions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_circle_outline, size: 56),
            const SizedBox(height: 12),
            Text('No hay adicionales configurados', style: AppTypography.h3()),
            const SizedBox(height: 8),
            const Text(
              'Crea arroz, patacones u otras porciones para todo el menú.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _showForm,
              icon: const Icon(Icons.add),
              label: const Text('Crear adicional'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _additions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final addition = _additions[index];
        return StitchCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: addition.available
                  ? AppColors.primaryFixed
                  : Colors.grey.shade200,
              child: Icon(
                Icons.restaurant,
                color: addition.available
                    ? AppColors.primaryContainer
                    : Colors.grey,
              ),
            ),
            title: Text(
              addition.name,
              style: AppTypography.bodyLg(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${(addition.priceCents / 100).toStringAsFixed(2)} € · ${addition.available ? 'Disponible' : 'No disponible'}',
            ),
            onTap: () => _showForm(existing: addition),
            trailing: Wrap(
              spacing: 2,
              children: [
                IconButton(
                  tooltip: addition.available ? 'Desactivar' : 'Activar',
                  onPressed: () => _toggleAvailability(addition),
                  icon: Icon(
                    addition.available
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () => _showForm(existing: addition),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  color: AppColors.error,
                  onPressed: () => _delete(addition),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlobalAdditionalFormDialog extends StatefulWidget {
  final GlobalAdditional? existing;

  const _GlobalAdditionalFormDialog({this.existing});

  @override
  State<_GlobalAdditionalFormDialog> createState() =>
      _GlobalAdditionalFormDialogState();
}

class _GlobalAdditionalFormDialogState
    extends State<_GlobalAdditionalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late bool _available;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _priceController = TextEditingController(
      text: widget.existing == null
          ? ''
          : (widget.existing!.priceCents / 100).toStringAsFixed(2),
    );
    _available = widget.existing?.available ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final price = double.parse(_priceController.text.replaceAll(',', '.'));
    final additional = GlobalAdditional(
      id:
          widget.existing?.id ??
          'additional-${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      priceCents: (price * 100).round(),
      available: _available,
    );
    Navigator.of(context).pop(additional);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Nuevo adicional' : 'Editar adicional',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa un nombre'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Precio'),
              validator: (value) {
                final parsed = double.tryParse(
                  (value ?? '').replaceAll(',', '.'),
                );
                if (parsed == null || parsed < 0) {
                  return 'Ingresa un precio válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Disponible para pedidos y Caja'),
              value: _available,
              onChanged: (value) => setState(() => _available = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
