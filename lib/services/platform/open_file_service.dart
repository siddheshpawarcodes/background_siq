import 'package:open_filex/open_filex.dart';

import '../../core/errors/failures.dart';
import '../../core/result/result.dart';

/// Opens a file in the OS default handler (SRS §11.5 "reopen exported file",
/// §11.6 "auto-open output folder").
class OpenFileService {
  const OpenFileService();

  Future<Result<void>> open(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type == ResultType.done) return const Result.ok(null);
    return Result.err(UnknownFailure(debugDetail: 'open failed: ${result.message}'));
  }
}
