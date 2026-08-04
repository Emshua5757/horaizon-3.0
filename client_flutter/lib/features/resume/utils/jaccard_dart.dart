import '../resume_matrix_dto.dart';

/// Pure Dart port of Go's `pkg/ai/tailor.go` — `Tokenize` + `JaccardSimilarity`.
///
/// Kept functionally identical to the Go version so client-side scores match
/// the Pi 5's server-side filtered result (within floating-point precision).
///
/// Time Complexity:  O(n + m) where n = resume tokens, m = JD tokens.
/// Space Complexity: O(n + m) for the two token sets.

/// English stopwords — identical set to Go's `tailor.go`.
const _stopwords = {
  'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
  'of', 'with', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have',
  'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
  'may', 'might', 'shall', 'can', 'need', 'dare', 'ought', 'used',
};

/// Tokenizes [text] into a lowercase word set, removing punctuation and
/// stopwords.
///
/// O(n) where n = word count.
Set<String> tokenize(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 2 && !_stopwords.contains(w))
      .toSet();
}

/// Jaccard similarity: |A ∩ B| / |A ∪ B|.
///
/// Returns 0.0 when both sets are empty.
/// O(|A| + |B|).
double jaccardSimilarity(Set<String> a, Set<String> b) {
  if (a.isEmpty && b.isEmpty) return 0.0;
  final intersection = a.intersection(b).length;
  final union = a.union(b).length;
  if (union == 0) return 0.0;
  return intersection / union;
}

/// Computes a live Jaccard score between [matrix] resume content and [jobDesc].
///
/// Concatenates all meaningful resume text (work highlights, project
/// descriptions + highlights, skill keywords) and tokenizes both sides.
///
/// Call with a 400ms debounce — NOT on every keystroke.
///
/// O(n + m) where n = resume token count, m = JD token count.
double scoreResumeAgainstJd(ResumeMatrixDto matrix, String jobDesc) {
  final buf = StringBuffer();

  for (final w in matrix.work) {
    buf.writeAll(w.highlights, ' ');
    buf.write(' ');
    buf.write(w.summary);
    buf.write(' ');
  }
  for (final p in matrix.projects) {
    buf.write(p.description);
    buf.write(' ');
    buf.writeAll(p.highlights, ' ');
    buf.write(' ');
  }
  for (final s in matrix.skills) {
    buf.writeAll(s.keywords, ' ');
    buf.write(' ');
  }

  final setA = tokenize(buf.toString());
  final setB = tokenize(jobDesc);
  return jaccardSimilarity(setA, setB);
}
