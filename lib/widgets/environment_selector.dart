import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../models/environment.dart';
import '../models/enums.dart';

class EnvironmentSelector extends StatelessWidget {
  final List<Environment> environments;
  final Environment? currentEnvironment;
  final Function(Environment) onEnvironmentChanged;
  final VoidCallback onCreateNew;

  const EnvironmentSelector({
    super.key,
    required this.environments,
    required this.currentEnvironment,
    required this.onEnvironmentChanged,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    if (environments.isEmpty) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: environments.length + 1, // +1 for "Add New" button
        itemBuilder: (context, index) {
          if (index == environments.length) {
            return _buildAddNewButton();
          }
          
          final environment = environments[index];
          final isSelected = currentEnvironment?.id == environment.id;
          
          return _buildEnvironmentChip(
            environment: environment,
            isSelected: isSelected,
            onTap: () => onEnvironmentChanged(environment),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppTheme.mutedText,
            size: 16,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'No environments yet',
              style: TextStyle(
                color: AppTheme.mutedText,
                fontSize: 12,
              ),
            ),
          ),
          _buildAddNewButton(),
        ],
      ),
    );
  }

  Widget _buildEnvironmentChip({
    required Environment environment,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    Color statusColor;
    switch (environment.status) {
      case EnvironmentStatus.running:
        statusColor = AppTheme.successColor;
        break;
      case EnvironmentStatus.creating:
        statusColor = AppTheme.warningColor;
        break;
      case EnvironmentStatus.stopped:
        statusColor = AppTheme.errorColor;
        break;
      case EnvironmentStatus.terminated:
        statusColor = AppTheme.errorColor;
        break;
      case EnvironmentStatus.error:
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = AppTheme.mutedText;
    }

    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.neonGreen.withValues(alpha: 0.1) 
                : AppTheme.darkCard,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected 
                  ? AppTheme.neonGreen 
                  : AppTheme.darkBorder,
              width: 2,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppTheme.neonGreen.withValues(alpha: 0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (controller) {
                if (environment.status == EnvironmentStatus.creating) {
                  controller.repeat();
                }
              }).shimmer(
                duration: 1.5.seconds,
                color: statusColor.withValues(alpha: 0.5),
              ),
              
              const SizedBox(width: 8),
              
              // Environment name
              Text(
                environment.name,
                style: TextStyle(
                  color: isSelected 
                      ? AppTheme.neonGreen 
                      : AppTheme.primaryText,
                  fontWeight: isSelected 
                      ? FontWeight.bold 
                      : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              
              // Template badge
              if (environment.templateId.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getTemplateColor(environment.templateId),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    environment.templateId.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryBlack,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddNewButton() {
    return GestureDetector(
      onTap: onCreateNew,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: AppTheme.neonPink,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              color: AppTheme.neonPink,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              'NEW',
              style: TextStyle(
                color: AppTheme.neonPink,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(
      duration: 200.ms,
      curve: Curves.elasticOut,
    );
  }

  Color _getTemplateColor(String template) {
    switch (template.toLowerCase()) {
      case 'nodejs':
      case 'node':
        return AppTheme.neonGreen;
      case 'python':
        return AppTheme.neonBlue;
      case 'react':
        return AppTheme.neonYellow;
      case 'flutter':
        return AppTheme.neonPurple;
      case 'go':
        return AppTheme.neonPink;
      default:
        return AppTheme.secondaryText;
    }
  }
}