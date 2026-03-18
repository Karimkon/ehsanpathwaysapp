import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ehsan_pathways/config/theme.dart';
import 'package:ehsan_pathways/core/providers/auth_provider.dart';
import 'package:ehsan_pathways/core/services/auth_service.dart';
import 'package:ehsan_pathways/core/services/content_service.dart';
import 'package:ehsan_pathways/shared/widgets/empty_state.dart';
import 'package:ehsan_pathways/shared/widgets/loading_shimmer.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _timeAgo(String? raw) {
  if (raw == null) return '';
  try {
    final dt = DateTime.parse(raw).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  } catch (_) {
    return '';
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _contentServiceProvider =
    Provider<ContentService>((ref) => ContentService());

// Identifies a comment set by type + id
typedef _CommentKey = ({String type, int id});

class _CommentState {
  final List<Map<String, dynamic>> comments;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? error;
  final bool isPosting;

  const _CommentState({
    this.comments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.error,
    this.isPosting = false,
  });

  bool get hasMore => currentPage < lastPage;

  _CommentState copyWith({
    List<Map<String, dynamic>>? comments,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    int? lastPage,
    int? total,
    String? error,
    bool? isPosting,
  }) =>
      _CommentState(
        comments: comments ?? this.comments,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        currentPage: currentPage ?? this.currentPage,
        lastPage: lastPage ?? this.lastPage,
        total: total ?? this.total,
        error: error,
        isPosting: isPosting ?? this.isPosting,
      );
}

class _CommentNotifier extends StateNotifier<_CommentState> {
  _CommentNotifier(this._service, this._authService, this._key)
      : super(const _CommentState());

  final ContentService _service;
  final AuthService _authService;
  final _CommentKey _key;

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data =
          await _service.fetchComments(_key.type, _key.id, page: 1);
      final comments = (data['data'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final meta = data['meta'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        comments: comments,
        isLoading: false,
        currentPage: (meta['current_page'] as int?) ?? 1,
        lastPage: (meta['last_page'] as int?) ?? 1,
        total: (meta['total'] as int?) ?? comments.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final data = await _service.fetchComments(
        _key.type,
        _key.id,
        page: nextPage,
      );
      final newComments = (data['data'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final meta = data['meta'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        comments: [...state.comments, ...newComments],
        isLoadingMore: false,
        currentPage: (meta['current_page'] as int?) ?? nextPage,
        lastPage: (meta['last_page'] as int?) ?? state.lastPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<bool> postComment(String body, {int? parentId}) async {
    final token = await _authService.getToken();
    if (token == null) return false;
    state = state.copyWith(isPosting: true);
    try {
      final result = await _service.postComment(
        type: _key.type,
        id: _key.id,
        body: body,
        parentId: parentId,
        authToken: token,
      );
      final newComment = result['data'] as Map<String, dynamic>?;
      if (newComment != null) {
        state = state.copyWith(
          comments: [newComment, ...state.comments],
          total: state.total + 1,
          isPosting: false,
        );
      } else {
        // Reload to get the new comment
        await loadInitial();
        state = state.copyWith(isPosting: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isPosting: false);
      return false;
    }
  }

  Future<bool> deleteComment(int commentId) async {
    final token = await _authService.getToken();
    if (token == null) return false;
    try {
      await _service.deleteComment(commentId, token);
      state = state.copyWith(
        comments: state.comments.where((c) {
          final id = c['id'] as int?;
          return id != commentId;
        }).toList(),
        total: (state.total - 1).clamp(0, 9999),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

final _commentProvider = StateNotifierProvider.family<_CommentNotifier,
    _CommentState, _CommentKey>((ref, key) {
  return _CommentNotifier(
    ref.watch(_contentServiceProvider),
    AuthService(),
    key,
  );
});

// ---------------------------------------------------------------------------
// CommentSection widget
// ---------------------------------------------------------------------------

/// Reusable comment section.
///
/// [contentType]: 'video', 'article', 'podcast', 'khutbah'
/// [contentId]: The numeric ID of the content item.
class CommentSection extends ConsumerStatefulWidget {
  const CommentSection({
    super.key,
    required this.contentType,
    required this.contentId,
  });

  final String contentType;
  final int contentId;

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _commentController = TextEditingController();
  int? _replyToId;
  String? _replyToName;
  final _scrollController = ScrollController();

  _CommentKey get _key =>
      (type: widget.contentType, id: widget.contentId);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_commentProvider(_key).notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(_commentProvider(_key).notifier).loadMore();
    }
  }

  void _setReply(int parentId, String authorName) {
    setState(() {
      _replyToId = parentId;
      _replyToName = authorName;
    });
    _commentController.text = '';
  }

  void _clearReply() {
    setState(() {
      _replyToId = null;
      _replyToName = null;
    });
  }

  Future<void> _submit() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;
    final success = await ref
        .read(_commentProvider(_key).notifier)
        .postComment(body, parentId: _replyToId);
    if (success) {
      _commentController.clear();
      _clearReply();
    }
  }

  Future<void> _delete(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete comment?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(_commentProvider(_key).notifier).deleteComment(commentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentState = ref.watch(_commentProvider(_key));
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoggedIn =
        authState.status == AuthStatus.authenticated;
    final currentUserId = authState.user?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                '${commentState.total} Comment${commentState.total == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),

        // ── Comment input ────────────────────────────────────────────────
        if (isLoggedIn) ...[
          if (_replyToName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded,
                      size: 16, color: AppTheme.primaryGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Replying to $_replyToName',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearReply,
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppTheme.primaryGreen),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // User avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    authState.user?.name.isNotEmpty == true
                        ? authState.user!.name[0].toUpperCase()
                        : 'U',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color:
                        isDark ? Colors.white : const Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    hintText: _replyToName != null
                        ? 'Write a reply...'
                        : 'Add a comment...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
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
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: commentState.isPosting ? null : _submit,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: commentState.isPosting
                        ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                        : AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: commentState.isPosting
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ] else ...[
          _SignInPrompt(isDark: isDark),
          const SizedBox(height: 16),
        ],

        // ── Comments list ────────────────────────────────────────────────
        if (commentState.isLoading)
          Column(
            children: List.generate(3, (_) => _CommentShimmer(isDark: isDark)),
          )
        else if (commentState.error != null && commentState.comments.isEmpty)
          EmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Could not load comments',
            subtitle: 'Please check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () =>
                ref.read(_commentProvider(_key).notifier).loadInitial(),
            compact: true,
          )
        else if (commentState.comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 40,
                    color: isDark
                        ? const Color(0xFF4B5563)
                        : const Color(0xFFD1D5DB),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No comments yet',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first to share your thoughts.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              ...commentState.comments.map((comment) {
                final commentId = comment['id'] as int?;
                final isOwn = currentUserId != null &&
                    (comment['user_id'] as int?) == currentUserId;
                final replies =
                    comment['replies'] as List<dynamic>? ?? [];

                return Column(
                  children: [
                    _CommentTile(
                      comment: comment,
                      isDark: isDark,
                      isOwn: isOwn,
                      indent: false,
                      onReply: isLoggedIn && commentId != null
                          ? () => _setReply(
                                commentId,
                                (comment['user']
                                        as Map<String, dynamic>?)?['name']
                                    as String? ??
                                    'Unknown',
                              )
                          : null,
                      onDelete: isOwn && commentId != null
                          ? () => _delete(commentId)
                          : null,
                    ),
                    // Replies (indented)
                    ...replies.map((r) {
                      final reply = r as Map<String, dynamic>;
                      final replyId = reply['id'] as int?;
                      final isOwnReply = currentUserId != null &&
                          (reply['user_id'] as int?) == currentUserId;
                      return _CommentTile(
                        comment: reply,
                        isDark: isDark,
                        isOwn: isOwnReply,
                        indent: true,
                        onReply: null,
                        onDelete: isOwnReply && replyId != null
                            ? () => _delete(replyId)
                            : null,
                      );
                    }),
                  ],
                );
              }),
              if (commentState.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
              if (commentState.hasMore && !commentState.isLoadingMore)
                TextButton(
                  onPressed: () =>
                      ref.read(_commentProvider(_key).notifier).loadMore(),
                  child: Text(
                    'Load more comments',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Comment tile
// ---------------------------------------------------------------------------

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isDark,
    required this.isOwn,
    required this.indent,
    required this.onReply,
    required this.onDelete,
  });

  final Map<String, dynamic> comment;
  final bool isDark;
  final bool isOwn;
  final bool indent;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final user = comment['user'] as Map<String, dynamic>?;
    final authorName = user?['name'] as String? ?? 'Anonymous';
    final body = comment['body'] as String? ?? '';
    final createdAt = comment['created_at'] as String?;
    final initial =
        authorName.isNotEmpty ? authorName[0].toUpperCase() : 'A';

    return Dismissible(
      key: ValueKey(comment['id']),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.red,
        ),
      ),
      confirmDismiss: (_) async {
        if (onDelete != null) {
          onDelete!();
        }
        return false; // Don't auto-dismiss; we handle it in state
      },
      child: GestureDetector(
        onLongPress: onDelete,
        child: Padding(
          padding: EdgeInsets.only(
            left: indent ? 40.0 : 0,
            bottom: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOwn
                      ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                      : (isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFE5E7EB)),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isOwn
                          ? AppTheme.primaryGreen
                          : (isDark ? Colors.white : const Color(0xFF374151)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          authorName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        if (isOwn) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'You',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          _timeAgo(createdAt),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark
                            ? const Color(0xFFD1D5DB)
                            : const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (onReply != null)
                          GestureDetector(
                            onTap: onReply,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.reply_rounded,
                                  size: 14,
                                  color: isDark
                                      ? const Color(0xFF6B7280)
                                      : const Color(0xFF9CA3AF),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Reply',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (onDelete != null) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: onDelete,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 14,
                                  color: Colors.red.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Delete',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign-in prompt
// ---------------------------------------------------------------------------

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.login_rounded,
            size: 20,
            color:
                isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sign in to comment',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/login'),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              backgroundColor:
                  AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Sign in',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comment shimmer
// ---------------------------------------------------------------------------

class _CommentShimmer extends StatelessWidget {
  const _CommentShimmer({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ShimmerWrap(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 34, height: 34, borderRadius: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 100, height: 12),
                  SizedBox(height: 6),
                  ShimmerBox(width: double.infinity, height: 11),
                  SizedBox(height: 4),
                  ShimmerBox(width: 200, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
