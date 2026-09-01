import 'dart:io';

const _pubspecPath = 'pubspec.yaml';
const _appVersionPath = 'lib/constants/app_version.dart';
const _maxAndroidVersionCode = 2100000000;

final RegExp _versionNamePattern = RegExp(
  r'^(\d+\.\d+\.\d+)-xarleyn\.([1-9]\d*)$',
);
final RegExp _pubspecVersionPattern = RegExp(
  r'^version:\s*([^\s+]+)\+(\d+)\s*$',
  multiLine: true,
);
final RegExp _appVersionPattern = RegExp(r"const String appVersion = '[^']+';");

class ProjectVersion {
  const ProjectVersion(this.name, this.buildNumber);

  final String name;
  final int buildNumber;

  @override
  String toString() => '$name+$buildNumber';
}

ProjectVersion parsePubspecVersion(String contents) {
  final match = _pubspecVersionPattern.firstMatch(contents);
  if (match == null) {
    throw const FormatException(
      'Expected a top-level version in the form version: 1.2.3+4.',
    );
  }

  final name = match.group(1)!;
  final buildNumber = int.parse(match.group(2)!);
  validateVersion(name, buildNumber);
  return ProjectVersion(name, buildNumber);
}

void validateVersion(String name, int buildNumber) {
  if (!_versionNamePattern.hasMatch(name)) {
    throw FormatException(
      'Invalid version name "$name". Expected the fork version format, for '
      'example 1.2.3-xarleyn.1.',
    );
  }
  if (buildNumber < 1 || buildNumber > _maxAndroidVersionCode) {
    throw RangeError.range(
      buildNumber,
      1,
      _maxAndroidVersionCode,
      'buildNumber',
    );
  }
}

String nextForkVersionName(String currentName) {
  final match = _versionNamePattern.firstMatch(currentName);
  if (match == null) {
    validateVersion(currentName, 1);
    throw StateError('Unreachable version validation state.');
  }
  final revision = int.parse(match.group(2)!);
  return '${match.group(1)}-xarleyn.${revision + 1}';
}

String replacePubspecVersion(String contents, ProjectVersion version) {
  parsePubspecVersion(contents);
  validateVersion(version.name, version.buildNumber);
  return contents.replaceFirst(
    _pubspecVersionPattern,
    'version: ${version.name}+${version.buildNumber}',
  );
}

String replaceAppVersion(String contents, String versionName) {
  validateVersion(versionName, 1);
  if (!_appVersionPattern.hasMatch(contents)) {
    throw const FormatException(
      'Could not find the appVersion constant in $_appVersionPath.',
    );
  }
  return contents.replaceFirst(
    _appVersionPattern,
    "const String appVersion = '$versionName';",
  );
}

Never _usage([String? error]) {
  if (error != null) {
    stderr.writeln(error);
    stderr.writeln();
  }
  stderr.writeln('Usage:');
  stderr.writeln('  dart run tool/version.dart check');
  stderr.writeln('  dart run tool/version.dart sync');
  stderr.writeln('  dart run tool/version.dart bump [version-name]');
  exitCode = error == null ? 0 : 64;
  throw const _UsageException();
}

void main(List<String> arguments) {
  try {
    if (arguments.isEmpty || arguments.length > 2) {
      _usage(arguments.isEmpty ? null : 'Too many arguments.');
    }

    final command = arguments.first;
    final pubspecFile = File(_pubspecPath);
    final appVersionFile = File(_appVersionPath);
    final pubspecContents = pubspecFile.readAsStringSync();
    final appVersionContents = appVersionFile.readAsStringSync();
    final current = parsePubspecVersion(pubspecContents);

    switch (command) {
      case 'check':
        final expected = replaceAppVersion(appVersionContents, current.name);
        if (expected != appVersionContents) {
          throw StateError(
            'Version mismatch: $_pubspecPath contains ${current.name}, but '
            '$_appVersionPath does not. Run the sync command.',
          );
        }
        stdout.writeln('Version is consistent: $current');
      case 'sync':
        if (arguments.length != 1) {
          _usage('The sync command does not accept a version name.');
        }
        appVersionFile.writeAsStringSync(
          replaceAppVersion(appVersionContents, current.name),
        );
        stdout.writeln('Synchronized app version: $current');
      case 'bump':
        final nextName = arguments.length == 2
            ? arguments[1]
            : nextForkVersionName(current.name);
        final next = ProjectVersion(nextName, current.buildNumber + 1);
        validateVersion(next.name, next.buildNumber);
        pubspecFile.writeAsStringSync(
          replacePubspecVersion(pubspecContents, next),
        );
        appVersionFile.writeAsStringSync(
          replaceAppVersion(appVersionContents, next.name),
        );
        stdout.writeln('Bumped app version: $current -> $next');
      default:
        _usage('Unknown command "$command".');
    }
  } on _UsageException {
    return;
  } on FileSystemException catch (error) {
    stderr.writeln('Version update failed: ${error.message}');
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln('Version update failed: ${error.message}');
    exitCode = 1;
  } on RangeError catch (error) {
    stderr.writeln('Version update failed: $error');
    exitCode = 1;
  } on StateError catch (error) {
    stderr.writeln('Version update failed: ${error.message}');
    exitCode = 1;
  }
}

class _UsageException implements Exception {
  const _UsageException();
}
