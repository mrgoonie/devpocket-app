import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../providers/environment_provider.dart';
import 'brutalist_button.dart';

class CreateEnvironmentSheet extends StatefulWidget {
  final EnvironmentProvider environmentProvider;

  const CreateEnvironmentSheet({
    super.key,
    required this.environmentProvider,
  });

  @override
  State<CreateEnvironmentSheet> createState() => _CreateEnvironmentSheetState();
}

class _CreateEnvironmentSheetState extends State<CreateEnvironmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedTemplate;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppTheme.neonGreen, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Create New Environment',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Environment Name',
                        hintText: 'My Awesome Project',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Template selection
                    const Text(
                      'Choose Template',
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Template options
                    Expanded(
                      child: _buildTemplateGrid(),
                    ),

                    const SizedBox(height: 24),

                    // Create button
                    BrutalistButton(
                      onPressed: (_selectedTemplate != null &&
                              !widget.environmentProvider.isCreating)
                          ? _createEnvironment
                          : null,
                      isLoading: widget.environmentProvider.isCreating,
                      child: const Text('CREATE ENVIRONMENT'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateGrid() {
    final templates = _getTemplateOptions();

    if (templates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.mutedText,
            ),
            SizedBox(height: 16),
            Text(
              'No templates available',
              style: TextStyle(
                color: AppTheme.mutedText,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: TextStyle(
                color: AppTheme.mutedText,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final isSelected = _selectedTemplate == template['id'];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTemplate = template['id'];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.neonBlue.withValues(alpha: 0.1)
                  : AppTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.neonBlue : AppTheme.darkBorder,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  template['icon'] as IconData,
                  size: 32,
                  color:
                      isSelected ? AppTheme.neonBlue : AppTheme.secondaryText,
                ),
                const SizedBox(height: 8),
                Text(
                  template['name'],
                  style: TextStyle(
                    color:
                        isSelected ? AppTheme.neonBlue : AppTheme.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getTemplateOptions() {
    // Check if we have actual templates from the API
    final apiTemplates = widget.environmentProvider.templates;

    if (apiTemplates.isNotEmpty) {
      return apiTemplates
          .map((template) => {
                'id': template.name,
                'name': template.displayName.isNotEmpty
                    ? template.displayName
                    : template.name,
                'icon': _getIconForTemplate(template.name),
              })
          .toList();
    }

    // Fallback to hardcoded templates if API templates are not available
    return [
      {
        'id': 'nodejs',
        'name': 'Node.js',
        'icon': Icons.javascript,
      },
      {
        'id': 'python',
        'name': 'Python',
        'icon': Icons.code,
      },
      {
        'id': 'react',
        'name': 'React',
        'icon': Icons.web,
      },
      {
        'id': 'flutter',
        'name': 'Flutter',
        'icon': Icons.phone_android,
      },
    ];
  }

  IconData _getIconForTemplate(String templateName) {
    switch (templateName.toLowerCase()) {
      case 'nodejs':
      case 'node':
        return Icons.javascript;
      case 'python':
        return Icons.code;
      case 'react':
        return Icons.web;
      case 'flutter':
        return Icons.phone_android;
      case 'golang':
      case 'go':
        return Icons.memory;
      case 'rust':
        return Icons.settings;
      default:
        return Icons.developer_mode;
    }
  }

  void _createEnvironment() async {
    if (!_formKey.currentState!.validate() || _selectedTemplate == null) {
      return;
    }

    try {
      await widget.environmentProvider.createEnvironment(
        name: _nameController.text.trim(),
        template: _selectedTemplate!,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Environment created successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = widget.environmentProvider.error ?? 'Failed to create environment';
        _showErrorDialog(errorMessage);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: AppTheme.errorColor,
              width: 2,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.darkBackground,
                foregroundColor: AppTheme.primaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(
                    color: AppTheme.darkBorder,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
