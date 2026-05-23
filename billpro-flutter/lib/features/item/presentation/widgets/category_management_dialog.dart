import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/models/item_category_model.dart';
import '../providers/item_provider.dart';

class CategoryManagementDialog extends StatefulWidget {
  const CategoryManagementDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ItemProvider>(),
        child: const CategoryManagementDialog(),
      ),
    );
  }

  @override
  State<CategoryManagementDialog> createState() => _CategoryManagementDialogState();
}

class _CategoryManagementDialogState extends State<CategoryManagementDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  ItemCategoryModel? _editingCategory;

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
    super.dispose();
  }

  void _edit(ItemCategoryModel cat) {
    setState(() {
      _editingCategory = cat;
      _nameCtrl.text = cat.name;
      _descCtrl.text = cat.description ?? '';
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingCategory = null;
      _nameCtrl.clear();
      _descCtrl.clear();
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    
    if (name.isEmpty) {
      AppToast.show(context, message: 'Category Name is required', type: ToastType.error);
      return;
    }
    
    final p = context.read<ItemProvider>();
    
    bool success;
    if (_editingCategory != null) {
      success = await p.updateCategory(_editingCategory!.id, name, desc);
    } else {
      success = await p.addCategory(name, desc);
    }

    if (mounted) {
      if (success) {
        _cancelEdit();
        AppToast.show(context, message: 'Category saved successfully', type: ToastType.success);
      } else {
        AppToast.show(context, message: p.errorMessage ?? 'Failed to save', type: ToastType.error);
      }
    }
  }

  Future<void> _delete(ItemCategoryModel cat) async {
    final p = context.read<ItemProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${cat.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: AppColors.error))
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await p.deleteCategory(cat.id);
      if (success) {
        AppToast.show(context, message: 'Category deleted', type: ToastType.success);
      } else {
        AppToast.show(context, message: p.errorMessage ?? 'Failed to delete', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ItemProvider>();
    
    return Dialog(
      backgroundColor: AppColors.bgMain,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Manage Categories', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Form
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editingCategory != null ? 'Edit Category' : 'Add New Category',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _nameCtrl,
                      label: 'Category Name *',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _descCtrl,
                      label: 'Description',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_editingCategory != null) ...[
                          TextButton(
                            onPressed: _cancelEdit,
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ElevatedButton(
                          onPressed: p.isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: p.isSaving 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(_editingCategory != null ? 'Update' : 'Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1, color: AppColors.border),
              
              // List
              Expanded(
                child: p.categories.isEmpty
                  ? const Center(child: Text('No categories found.', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: p.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final cat = p.categories[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ListTile(
                            title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: cat.description != null && cat.description!.isNotEmpty
                                ? Text(cat.description!, style: const TextStyle(fontSize: 12))
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                  onPressed: () => _edit(cat),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                                  onPressed: () => _delete(cat),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
