#!/bin/bash
#
# Script to build JAR file containing code to augment/extend Solr.

if [ $(basename $PWD) != "priv" ]
then
    cd priv
fi

SOLR_LIB=solr-war/WEB-INF/lib

javac -cp "$SOLR_LIB/*" java/com/basho/yokozuna/handler/*.java java/com/basho/yokozuna/query/*.java
jar cvf yokozuna.jar -C java/ .

mkdir java_lib
cp yokozuna.jar java_lib
