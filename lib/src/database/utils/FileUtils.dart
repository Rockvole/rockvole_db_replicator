import 'dart:io';

class FileUtils {
/*
  static void removeLineFromFile(String file, String regex) {
    Matcher matcher = null;
    try {
      File inFile = File(file);

      if (!inFile.isFile()) {
        logger.error("File '"+file+"' does not exist");
      }

      //Construct the new file that will later be renamed to the original filename.
      File tempFile = File(inFile.getAbsolutePath() + ".tmp");

      BufferedReader br = BufferedReader(FileReader(file));
      PrintWriter pw = PrintWriter(FileWriter(tempFile));

      String line = null;

      //Read from the original file and write to the new
      //unless content matches data to be removed.
      while ((line = br.readLine()) != null) {
        matcher = Pattern.compile(regex).matcher(line);
        if (!matcher.find()) {

          pw.println(line);
          pw.flush();
        }
      }
      pw.close();
      br.close();

      //Delete the original file
      if (!inFile.delete()) {
        System.out.println("Could not delete file");
        return;
      }

      //Rename the new file to the filename the original file had.
      if (!tempFile.renameTo(inFile))
        System.out.println("Could not rename file");

    } catch (FileNotFoundException e) {
    } catch (IOException e) {
    logger.error("DB", e);
    }
  }
*/
  static Future<bool> deleteEmptyFile(String filename) async {
    File readFile = File(filename);
    if (!await FileSystemEntity.isFile(filename))
      throw ArgumentError(filename + " is not a file");
    if ((await readFile.length()) == 0 && (await readFile.exists())) {
      try {
        await readFile.delete();
        return true;
      } catch (e) {
        print("Could not delete file " + (await readFile).path);
      }
    }
    return false;
  }

  static Future<void> trimBlankLines(String filename) async {
    File readFile = File(filename);
    if (!await FileSystemEntity.isFile(filename))
      throw ArgumentError(filename + " is not a file");
    File tmpFile = File(readFile.path + ".tmp");

    List<String> readLines = readFile.readAsLinesSync();
    bool isBlankLine;
    for (var line in readLines) {
      if (line != null) {
        isBlankLine = true;
        line.runes.forEach((int rune) {
          String character = String.fromCharCode(rune);
          if (character != ' ') isBlankLine = false;
        });
        if (!isBlankLine) {
          tmpFile.writeAsStringSync(line);
        }
      }
    }
// ---------------------------------------------------------- DELETE ORIGINAL FILE
    readFile.deleteSync();
    tmpFile.renameSync(readFile.path);
  }

  Set<String> getAllFileNames(String directory, String extension) {
    Set<String> fileNames = Set<String>();
    Directory dir = Directory(directory);

    dir
        .list(recursive: false, followLinks: false)
        .listen((FileSystemEntity entity) {
      if (FileSystemEntity.isFileSync(entity.path)) {
        if (entity.path.endsWith(extension)) fileNames.add(entity.path);
      }
    });
    return fileNames;
  }
}
