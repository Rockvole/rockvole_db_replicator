#! /bin/bash
dart_path=/work/installs/dart-sdk-2.13
rockvole_path=/work/projects/dart/rockvole_db

cd $rockvole_path
echo "$@"
if [ $1 = "addentry" ]; then
  RVH=$3
  export RVH
  $dart_path/bin/dart --no-sound-null-safety lib/rockvole_helper.dart $1 $2 $4 1>&2
else
  $dart_path/bin/dart --no-sound-null-safety lib/rockvole_helper.dart "$@" 1>&2
fi
