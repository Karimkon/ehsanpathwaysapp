import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:ehsan_pathways/core/providers/auth_provider.dart';
import 'package:ehsan_pathways/features/notes/notes_provider.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';

const Color _green = Color(0xFF16A34A);
const Color _gold = Color(0xFFF59E0B);

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);

    // Guard: show login prompt if not authenticated
    if (auth.status != AuthStatus.authenticated) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
        appBar: AppBar(
          title: Text('My Notes',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 24, fontWeight: FontWeight.w700)),
          centerTitle: false,
          backgroundColor:
              isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const LoginPrompt(feature: 'notes'),
      );
    }

    final noteState = ref.watch(noteListProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: Text(
          'My Notes',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF8FAF8),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: noteState.isLoading && noteState.notes.isEmpty
          ? const SingleChildScrollView(child: ShimmerList(itemCount: 6))
          : noteState.error != null && noteState.notes.isEmpty
              ? EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Failed to load',
                  subtitle: noteState.error!,
                  actionLabel: 'Retry',
                  onAction: () =>
                      ref.read(noteListProvider.notifier).fetchNotes(),
                )
              : noteState.notes.isEmpty
                  ? EmptyState(
                      icon: Icons.note_alt_outlined,
                      title: 'No notes yet',
                      subtitle:
                          'Take notes while watching videos or reading articles to remember key insights.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: noteState.notes.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _NoteCard(
                          note: noteState.notes[index],
                          isDark: isDark,
                          onEdit: () => _showEditSheet(
                              context, ref, noteState.notes[index]),
                          onDelete: () => _confirmDelete(
                              context, ref, noteState.notes[index]),
                        );
                      },
                    ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Note note) {
    final controller = TextEditingController(text: note.content);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Edit Note',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: controller,
                maxLines: 6,
                autofocus: true,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  hintText: 'Write your note...',
                  hintStyle: GoogleFonts.inter(
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _green, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(ctx);
                    await ref
                        .read(noteListProvider.notifier)
                        .updateNote(note.id, text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Note note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Note',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Text(
          'Are you sure you want to delete this note?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(noteListProvider.notifier).deleteNote(note.id);
            },
            child: Text('Delete',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Note Card
// ---------------------------------------------------------------------------

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  final Note note;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  IconData get _typeIcon {
    switch (note.notableType) {
      case 'video':
        return Icons.play_circle_rounded;
      case 'pathway':
        return Icons.route_rounded;
      case 'khutbah':
        return Icons.mosque_rounded;
      default:
        return Icons.note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_typeIcon, size: 16, color: _green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.typeLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _green,
                      ),
                    ),
                    Text(
                      dateFormat.format(note.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),

              if (note.formattedTimestamp.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 12, color: _gold),
                      const SizedBox(width: 4),
                      Text(
                        note.formattedTimestamp,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _gold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Actions
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('Edit', style: GoogleFonts.inter(fontSize: 14)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            size: 18, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text('Delete',
                            style: GoogleFonts.inter(
                                fontSize: 14, color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Note content
          Text(
            note.content,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
