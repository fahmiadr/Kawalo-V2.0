/// Ekstensi berkas huruf kecil tanpa titik pemisah, atau string kosong.
String attachmentFileExtension(String file) {
  final cleanPath = file.split('?').first;
  final dotIndex = cleanPath.lastIndexOf('.');
  if (dotIndex != -1 && dotIndex < cleanPath.length - 1) {
    return cleanPath.substring(dotIndex + 1).toLowerCase();
  }
  return '';
}

/// Nama berkas bersih tanpa query parameter.
String attachmentFileName(String file) {
  final cleanPath = file.split('?').first;
  final slashIndex = cleanPath.lastIndexOf('/');
  if (slashIndex != -1 && slashIndex < cleanPath.length - 1) {
    return cleanPath.substring(slashIndex + 1);
  }
  return file;
}

/// Nama ringkas format berkas untuk subtitle tile berkas.
String attachmentFormatLabel(String file) {
  final extension = attachmentFileExtension(file);
  switch (extension) {
    case 'pdf':
      return 'PDF';
    case 'doc':
    case 'docx':
      return 'Word';
    case 'xls':
    case 'xlsx':
      return 'Excel';
    case 'ppt':
    case 'pptx':
      return 'PowerPoint';
    case 'csv':
      return 'CSV';
    case 'txt':
      return 'Text';
    case 'json':
      return 'JSON';
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'webp':
    case 'gif':
      return 'Image';
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
      return 'Archive';
    default:
      return extension.isNotEmpty ? extension.toUpperCase() : 'Dokumen';
  }
}
