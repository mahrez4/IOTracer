#!/bin/bash
HADOOP_ARCHIVE="terasort_datadir/hadoop-3.3.6.tar.gz"
HADOOP_DIR="terasort_datadir/hadoop"

if [ -f "$HADOOP_ARCHIVE" ]; then
    echo "Hadoop archive found: $HADOOP_ARCHIVE"
    if [ ! -d "$HADOOP_DIR" ]; then
	echo "Extracting Hadoop archive..."
        tar -xzf "$HADOOP_ARCHIVE"
        mv hadoop-3.3.6 $HADOOP_DIR
    else
        echo "Hadoop directory already exists: $HADOOP_DIR"
    fi
elif [ -d "$HADOOP_DIR" ]; then
    echo "Hadoop directory found: $HADOOP_DIR"
else
    echo "Downloading hadoop"
    wget  https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz 
    echo "Extracting Hadoop archive..."
    tar -xzf "$HADOOP_ARCHIVE"
    mv hadoop-3.3.6 $HADOOP_ARCHIVE
fi

export HADOOP_HOME=$(pwd)/$HADOOP_DIR
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME

export JAVA_HOME=/usr/lib/jvm/java
export PATH=$PATH:$HADOOP_HOME/bin
