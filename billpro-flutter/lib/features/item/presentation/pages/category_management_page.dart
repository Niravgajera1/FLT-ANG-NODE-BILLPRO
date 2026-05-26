import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/item_category_model.dart';
import '../providers/item_provider.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  ItemCategoryModel? _editingCategory;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _startAdd() {
    setState(() {
      _editingCategory = null;
      _nameCtrl.clear();
      _descCtrl.clear();
      _showForm = true;
    });
  }

  void _startEdit(ItemCategoryModel cat) {
    setState(() {
      _editingCategory = cat;
      _nameCtrl.text = cat.name;
      _descCtrl.text = cat.description ?? '';
      _showForm = true;
    });
  }

  void _cancelForm() {
    setState(() {
      _editingCategory = null;
      _nameCtrl.clear();
      _descCtrl.clear();
      _showForm = false;
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (name.isEmpty) {
      AppToast.show(context,
          message: 'Category name is required', type: ToastType.error);
      return;
    }

    final p = context.read<ItemProvider>();

    bool success;
    if (_editingCategory != null) {
      success = await p.updateCategory(
          _editingCategory!.id, name, desc.isEmpty ? null : desc);
    } else {
      success = await p.addCategory(name, desc.isEmpty ? null : desc);
    }

    if (mounted) {
      if (success) {
        _cancelForm();
        AppToast.show(context,
            message: _editingCategory != null
                ? 'Category updated successfully'
                : 'Category added successfully',
            type: ToastType.success);
      } else {
        AppToast.show(context,
            message: p.errorMessage ?? 'Failed to save category',
            type: ToastType.error);
      }
    }
  }

  Future<void> _delete(ItemCategoryModel cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Category',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 15, height: 1.4),
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                  text: '"${cat.name}"',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const TextSpan(text: '?\n\nThis action cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final p = context.read<ItemProvider>();
      final success = await p.deleteCategory(cat.id);
      if (mounted) {
        if (success) {
          AppToast.show(context,
              message: 'Category deleted', type: ToastType.success);
        } else {
          AppToast.show(context,
              message: p.errorMessage ?? 'Failed to delete category',
              type: ToastType.error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    final categories = provider.categories;

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manage Categories',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          if (!_showForm)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                tooltip: 'Add Category',
                onPressed: _startAdd,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primarySoft,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Add/Edit Form ──
          if (_showForm) _buildForm(provider),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search categories...',
                hintStyle:
                    const TextStyle(color: AppColors.textHint, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // ── Category Count ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(
                  '${_filteredCategories(categories).length} ${_filteredCategories(categories).length == 1 ? 'Category' : 'Categories'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (provider.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: _buildList(categories, provider),
          ),
        ],
      ),
    );
  }

  List<ItemCategoryModel> _filteredCategories(List<ItemCategoryModel> cats) {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return cats;
    return cats
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            (c.description?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  Widget _buildForm(ItemProvider provider) {
    final isEditing = _editingCategory != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEditing
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: (isEditing ? AppColors.warning : AppColors.primary)
                .withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isEditing
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isEditing
                        ? Icons.edit_rounded
                        : Icons.add_circle_outline_rounded,
                    size: 18,
                    color: isEditing ? AppColors.warning : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isEditing ? 'Edit Category' : 'Add New Category',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isEditing ? AppColors.warning : AppColors.primary,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _cancelForm,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _nameCtrl,
              label: 'Category Name *',
              hint: 'e.g. Electronics, Clothing',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _descCtrl,
              label: 'Description',
              hint: 'Optional description',
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (isEditing) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelForm,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: provider.isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isEditing ? AppColors.warning : AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: provider.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(isEditing ? 'Update Category' : 'Add Category',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<ItemCategoryModel> allCategories, ItemProvider provider) {
    final filtered = _filteredCategories(allCategories);

    if (provider.isLoading && allCategories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.category_outlined,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'No categories match your search'
                  : 'No categories yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'Try a different search term'
                  : 'Tap + to add your first category',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            if (_searchCtrl.text.isEmpty) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _startAdd,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Category'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadCategories(),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final cat = filtered[i];
          final isBeingEdited = _editingCategory?.id == cat.id;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isBeingEdited
                    ? AppColors.warning.withValues(alpha: 0.5)
                    : AppColors.border,
                width: isBeingEdited ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Category Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        cat.name.isNotEmpty
                            ? cat.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name & description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (cat.description != null &&
                            cat.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              cat.description!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Edit button
                  _actionButton(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    bgColor: AppColors.primarySoft,
                    onTap: () => _startEdit(cat),
                    tooltip: 'Edit',
                  ),
                  const SizedBox(width: 6),
                  // Delete button
                  _actionButton(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.error,
                    bgColor: AppColors.error.withValues(alpha: 0.08),
                    onTap: () => _delete(cat),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
