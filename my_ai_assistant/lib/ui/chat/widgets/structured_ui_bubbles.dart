import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';
import '../../theme/glass_theme.dart';
import '../../common/glass_widgets.dart';

import 'dart:convert';
class StructuredUIBubble extends StatelessWidget {
  final dynamic data;
  final String type;
  const StructuredUIBubble({super.key, required this.data, required this.type});

  @override
  Widget build(BuildContext context) {
    var activeData = data;
    if (data is String) {
      try { activeData = jsonDecode(data); } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: GlassDecorations.surface(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, size: 16, color: GlassColors.primary),
              const SizedBox(width: 12),
              Text('TACTICAL DATA VIEW', style: GlassText.labelSM().copyWith(color: GlassColors.primary, letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 16),
          if (type == 'table' && activeData is List) _buildTable(activeData)
          else if (type == 'status_summary' && activeData is Map) _buildSummary(Map<String, dynamic>.from(activeData as Map))
          else if (type == 'plan_review' && activeData is List) _buildPlanReview(activeData)
          else if (type == 'empty_state') _buildEmptyState(activeData)
          else Text(data.toString()),
        ],
      ),
    );
  }

  Widget _buildPlanReview(List<dynamic> items) {
    return Column(
      children: items.map((item) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(item as Map);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: GlassColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_outlined, size: 14, color: GlassColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['title']?.toString() ?? 'Plan Item', style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.bold)),
                    if (m['description'] != null)
                      Text(m['description'].toString(), style: GlassText.secondary().copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(dynamic data) {
    final Map<String, dynamic> m = data is Map ? Map<String, dynamic>.from(data) : {};
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(Icons.inbox_outlined, size: 48, color: GlassColors.onSurfaceVariant.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(m['message']?.toString() ?? 'No strategic data found.', style: GlassText.bodyMD().copyWith(color: GlassColors.onSurfaceVariant)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTable(List<dynamic> rows) {
    if (rows.isEmpty) return const Text('No data');
    final keys = (rows.first as Map).keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        horizontalMargin: 0,
        columns: keys.map((k) => DataColumn(label: Text(k.toString().toUpperCase(), style: GlassText.labelSM().copyWith(fontSize: 10)))).toList(),
        rows: rows.map((row) {
          final m = row as Map;
          return DataRow(cells: keys.map((k) => DataCell(Text(m[k].toString(), style: GlassText.bodyMD()))).toList());
        }).toList(),
      ),
    );
  }

  Widget _buildSummary(Map<String, dynamic> stats) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: stats.entries.map((e) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: GlassColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(e.value.toString(), style: GlassText.headlineLG().copyWith(fontSize: 24)),
            Text(e.key.toUpperCase(), style: GlassText.labelSM().copyWith(fontSize: 8, color: GlassColors.primary.withOpacity(0.5))),
          ],
        ),
      )).toList(),
    );
  }
}
