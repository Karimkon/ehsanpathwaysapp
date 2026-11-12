import 'package:ehsan_pathways/core/json_read.dart';
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
      slug: (jStr(json['slug']) ?? ''),
      title: jStr(json['title']) ?? '',
      arabicTitle: jStr(json['arabic_title']) ?? '',
      author: jStr(json['author']),
      arabicAuthor: jStr(json['arabic_author']),
      description: jStr(json['description']),
      category: jStr(json['category']) ?? 'hadith',
      pageCount: (jNum(json['page_count']))?.toInt() ?? 0,
      fileSize: (jNum(json['file_size']))?.toInt() ?? 0,
      fileSizeLabel: jStr(json['file_size_label']) ?? '',
      coverUrl: jStr(json['cover_url']),
      pdfUrl: jStr(json['pdf_url']) ?? '',
      isDownloadable: jBool(json['is_downloadable']) ?? true,
      downloadCount: (jNum(json['download_count']))?.toInt() ?? 0,
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
        slug: (jStr(json['slug']) ?? ''),
        label: jStr(json['label']) ?? '',
        arabic: jStr(json['arabic']) ?? '',
      );
}
