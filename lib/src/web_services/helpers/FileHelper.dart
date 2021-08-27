import 'package:rockvole_db/rockvole_db.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class FileHelper {
  static String getDateString() {
    DateTime now = DateTime.now();
    DateFormat sdf = DateFormat("yyyy_MM_dd");
    return sdf.format(now);
  }

  static void multipleFileTrim(String directory, String extension) {
    FileUtils fu = FileUtils();
    Set<String> fileNames = fu.getAllFileNames(directory, extension);
    Iterator<String> iter = fileNames.iterator;
    while (iter.moveNext()) {
      try {
        FileUtils.trimBlankLines(directory + "/" + iter.current);
      } on ArgumentError catch (e) {
        print(e);
      }
    }
  }

  static void deleteMultipleEmptyFiles(String directory) {
    FileUtils fu = FileUtils();
    Set<String> fileNames = fu.getAllFileNames(directory, ".csv");
    Iterator<String> iter = fileNames.iterator;
    while (iter.moveNext()) {
      try {
        FileUtils.deleteEmptyFile(directory + "/" + iter.current);
      } on ArgumentError catch (e) {
        print(e);
      }
    }
  }

  static Future<void> createEmptyDirectory(String directory) async {
    print("DELETE TODAYS DATABASE DIRECTORY " + directory);
    await deleteDirectory(directory);
    print("CREATE EMPTY DIRECTORY " + directory);

    // Creates dir/ and dir/subdir/.
    try {
      await Directory(directory).create(recursive: true)
          // The created directory is returned as a Future.
          .then((Directory dir) {
        print(dir.path);
      });
    } on Exception catch (e) {
      print("Failed to create directory " + directory);
    }
  }

  static Future<void> deleteDirectory(String directory) async {
    try {
      await Directory(directory).delete(recursive: false);
    } on Exception catch (e) {
      print(e);
    }
  }

  static Future<bool> doesFileExist(String filename) async {
    File f = File(filename);
    if (await f.exists()) {
      return true;
    }
    return false;
  }

  static Future<void> createSymbolicDirectory(
      String linkDirectory, String sourceDirectory) async {
    print("DELETE SYMBOLIC LINK");
    Link link = Link(linkDirectory);
    try {
      await link.delete();
    } on Exception catch (e) {
      print("DIRECTORY NOT FOUND " + linkDirectory);
    }
    print("CREATE SYMBOLIC LINK");
    Link createLink = Link(linkDirectory);
    try {
      await createLink.create(sourceDirectory);
    } on Exception catch (e) {
      print(e);
    }
  }
}
