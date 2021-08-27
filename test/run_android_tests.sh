#! /bin/bash

flutter run test/test_sqflite_basics.dart > /work/tmp/test_basics.log

flutter run test/test_sqflite_exceptions.dart > /work/tmp/test_exceptions.log

flutter run test/test_sqflite_transactions.dart > /work/tmp/test_transactions.log

geany /work/tmp/test_basics.log /work/tmp/test_exceptions.log /work/tmp/test_transactions.log &
