class ProcessResult {
  final int exitCode;
  final Object stdout;
  final Object stderr;

  ProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  factory ProcessResult.fromJson(Map<String, dynamic> json) {
    return ProcessResult(
      exitCode: json['exitCode'] as int,
      stdout: json['stdout'] ?? '',
      stderr: json['stderr'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exitCode': exitCode,
      'stdout': stdout.toString(),
      'stderr': stderr.toString(),
    };
  }
} 