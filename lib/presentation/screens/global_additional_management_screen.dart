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

  bool get _isEditing => widget.existing != null;

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF594138),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2D5D0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2D5D0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFF26522), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl * 1.5),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl * 1.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit_note : Icons.add_circle_outline,
                    color: AppColors.primaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _isEditing ? 'Editar adicional' : 'Nuevo adicional',
                    style: AppTypography.h2(color: AppColors.onSurface),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalles del adicional',
                            style: AppTypography.h3(
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Se podrá añadir a cualquier plato, pedido y cobro.',
                            style: AppTypography.bodyMd(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _nameController,
                            style: AppTypography.bodyMd(
                              color: AppColors.onSurface,
                            ),
                            decoration: _inputDecoration(
                              'Nombre del adicional',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Ingresa un nombre'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _priceController,
                            style: AppTypography.bodyMd(
                              color: AppColors.onSurface,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration('Precio (€)').copyWith(
                              prefixIcon: const Icon(
                                Icons.euro_rounded,
                                size: 18,
                                color: AppColors.primaryContainer,
                              ),
                            ),
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
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE2D5D0),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.point_of_sale_outlined,
                                  color: AppColors.primaryContainer,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Disponible para pedidos y Caja',
                                        style: AppTypography.bodyMd(
                                          color: AppColors.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _available
                                            ? 'El personal puede añadirlo ahora.'
                                            : 'No se mostrará al tomar pedidos.',
                                        style: AppTypography.bodyMd(
                                          color: AppColors.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _available,
                                  onChanged: (value) =>
                                      setState(() => _available = value),
                                  activeThumbColor: AppColors.primaryContainer,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.xl * 1.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancelar',
                      style: AppTypography.statusBadge(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    label: Text(
                      _isEditing ? 'Guardar cambios' : 'Crear adicional',
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
