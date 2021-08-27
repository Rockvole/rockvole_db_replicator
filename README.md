## rockvole_db_replicator

A database library which provides you with CRUD methods to access your database. This library will create additional transaction tables.
These transaction tables can be used to replay your database transactions on other servers or phones, thus replicating the database remotely.

To see an example of this - see the rockvole_replicator_todo demonstration android app.<br/>
[GitHub](https://github.com/Rockvole/rockvole_replicator_todo).

## Usage

A simple usage example:

```dart
import 'package:rockvole_db_replicator/rockvole_db.dart';

main() {
  var awesome = Awesome();
}
```
