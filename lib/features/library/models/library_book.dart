/// A scanned book in the library, as the API describes it.
class LibraryBook {
  const LibraryBook({
    required this.slug,
    required this.title,
    required this.arabicTitle,
    this.author,
    this.arabicAuthor,
    this.description,
    required this.category,
    required this.pageCount,
    required this.fileSize,
    required this.fileSizeLabel,
    this.coverUrl,
    required this.pdfUrl,
    this.isDownloadable = true,
    this.downloadCount = 0,
    this.progressPage,
    this.progressPercent,
  });

  final String slug;
  final String title;
  final String arabicTitle;
  final String? author;
  final String? arabicAuthor;
  final String? description;
  final String category;
  final int pageCount;
  final int fileSize;
  final String fileSizeLabel;
  final String? coverUrl;
  final String pdfUrl;
  final bool isDownloadable;
  final int downloadCount;

  /// Present only where the reader has opened the book before.
  final int? progressPage;
  final int? progressPercent;

  bool get hasProgress => (progressPage ?? 0) > 1;

  factory LibraryBook.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] as Map<String, dynamic>?;

    return LibraryBook(
      slug: json['slug'] as String,
      title: json['title'] as String? ?? '',
      arabicTitle: json['arabic_title'] as String? ?? '',
      author: json['author'] as String?,
      arabicAuthor: json['arabic_author'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'hadith',
      pageCount: (json['page_count'] as num?)?.toInt() ?? 0,
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      fileSizeLabel: json['file_size_label'] as String? ?? '',
      coverUrl: json['cover_url'] as String?,
      pdfUrl: json['pdf_url'] as String? ?? '',
      isDownloadable: json['is_downloadable'] as bool? ?? true,
      downloadCount: (json['download_count'] as num?)?.toInt() ?? 0,
      // "continue reading" flattens these onto the book; the detail endpoint
      // nests them under `progress`.
      progressPage: (progress?['page'] ?? json['page']) as int?,
      progressPercent: (progress?['percent'] ?? json['percent']) as int?,
    );
  }

  LibraryBook copyWith({int? progressPage, int? progressPercent}) => LibraryBook(
        slug: slug,
        title: title,
        arabicTitle: arabicTitle,
        author: author,
        arabicAuthor: arabicAuthor,
        description: description,
        category: category,
        pageCount: pageCount,
        fileSize: fileSize,
        fileSizeLabel: fileSizeLabel,
        coverUrl: coverUrl,
        pdfUrl: pdfUrl,
        isDownloadable: isDownloadable,
        downloadCount: downloadCount,
        progressPage: progressPage ?? this.progressPage,
        progressPercent: progressPercent ?? this.progressPercent,
      );
}

/// One shelf of the library.
class LibraryCategory {
  const LibraryCategory({
    required this.slug,
    required this.label,
    required this.arabic,
  });

  final String slug;
  final String label;
  final String arabic;

  factory LibraryCategory.fromJson(Map<String, dynamic> json) => LibraryCategory(
        slug: json['slug'] as String,
        label: json['label'] as String? ?? '',
        arabic: json['arabic'] as String? ?? '',
      );
}
