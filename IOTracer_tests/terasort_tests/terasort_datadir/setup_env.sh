#!/bin/bash
SCRIPTPATH="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
HADOOP_ARCHIVE=$SCRIPTPATH/hadoop-3.3.6.tar.gz
HADOOP_DIR=$SCRIPTPATH/hadoop

if [ -f "$HADOOP_ARCHIVE" ]; then
    echo "Hadoop archive found: $HADOOP_ARCHIVE"
    
    if [ ! -d "$HADOOP_DIR" ]; then
	echo "Extracting Hadoop archive..."
	wget -c -P $SCRIPTPATH https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz 
        tar -xzf "$HADOOP_ARCHIVE" --directory $SCRIPTPATH
        mv $SCRIPTPATH/hadoop-3.3.6 $HADOOP_DIR
    else
        echo "Hadoop directory already exists: $HADOOP_DIR"
    fi
elif [ -d "$HADOOP_DIR" ]; then
    echo "Hadoop directory found: $HADOOP_DIR"
else
    echo "Hadoop archive not found in $HADOOP_ARCHIVE"
    echo "Hadoop directory not found in $HADOOP_DIR"
    echo "Downloading hadoop"
    wget -P $SCRIPTPATH https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz 
    echo "Extracting Hadoop archive..."
    tar -xzf "$HADOOP_ARCHIVE" --directory $SCRIPTPATH
    mv $SCRIPTPATH/hadoop-3.3.6 $HADOOP_ARCHIVE
fi

unset HADOOP_HOME; unset HADOOP_CONF_DIR; unset HADOOP_MAPRED_HOME; unset HADOOP_COMMON_HOME; unset HADOOP_HDFS_HOME; unset YARN_HOME; unset JAVA_HOME;

export HADOOP_HOME=$HADOOP_DIR
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export HADOOP_YARN_HOME=$HADOOP_HOME

export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep java-21-openjdk)
export PATH=$PATH:$HADOOP_HOME/bin
