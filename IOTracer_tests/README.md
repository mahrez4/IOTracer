- [Requirements](#Requirements)
  - [Ubuntu 22.04](#Ubuntu-22.04)
    - [FIO](#ubuntu-22.04-fio)
    - [Postmark](#ubuntu-22.04-postmark)
    - [Sqlite](#ubuntu-22.04-sqlite)
    - [Terasort](#ubuntu-22.04-terasort)
    - [YCSB](#ubuntu-22.04-ycsb)
      - [Java and Python2](#ubuntu-22.04-java-python2)
      - [Mongodb](#ubuntu-22.04-mongodb)
    - [Requirements-to-visualize](#ubuntu-22.04-vis-req)
  - [Fedora](#Fedora)
    - [FIO](#fedora-fio)
    - [Postmark](#fedora-postmark)
    - [Sqlite](#fedora-sqlite)
    - [Terasort](#fedora-terasort)
    - [YCSB](#fedora-ycsb)
      - [Java and Python2](#fedora-java-python2)
      - [Mongodb](#fedora-mongodb)
    - [Requirements-to-visualize](#fedora-vis-req)
- [Running Scripts](#running-scripts)


# Requirements
## Ubuntu 22.04: <a id="ubuntu-22.04"></a>

### FIO <a id="ubuntu-22.04-fio"></a>
```
sudo apt-get install fio
```
### Postmark <a id="ubuntu-22.04-postmark"></a>
already in [postmark directory](postmark_tests/postmark/) along with the source code (postmark-1_5.c)

### Sqlite <a id="ubuntu-22.04-sqlite"></a>
```
sudo apt-get install sqlite3
```

### Terasort <a id="ubuntu-22.04-terasort"></a>
hadoop is downloaded with setup_env.sh script in [terasort directory](terasort_tests/terasort_datadir)
either run setup_env.sh or any of the benchmarks which will eventually run the setup script anyway.

### YCSB <a id="ubuntu-22.04-ycsb"></a>
Binaries are in [ycsb directory](ycsb_tests/ycsb_datadir/) but java and python2 are required, as well as mongodb.
#### Java and Python2 <a id="ubuntu-22.04-java-python2"></a>
```
sudo apt-get install python2 openjdk-21-jre
```
#### Mongodb <a id="ubuntu-22.04-mongodb"></a>

```
sudo apt-get install gnupg curl
```
```
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor
```
```
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list 
```
```
sudo apt-get update
```
```
sudo apt-get install -y mongodb-org
```
OR to install a specific version

```
sudo apt-get install -y mongodb-org=7.0.7 mongodb-org-database=7.0.7 mongodb-org-server=7.0.7 mongodb-mongosh=7.0.7 mongodb-org-mongos=7.0.7 mongodb-org-tools=7.0.7
```
<details>
  <summary>To avoid updating mongodb </summary>
    echo "mongodb-org hold" | sudo dpkg --set-selections
    echo "mongodb-org-database hold" | sudo dpkg --set-selections
    echo "mongodb-org-server hold" | sudo dpkg --set-selections
    echo "mongodb-mongosh hold" | sudo dpkg --set-selections
    echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
    echo "mongodb-org-tools hold" | sudo dpkg --set-selections
</details>

### Requirements to visualize: <a id="ubuntu-22.04-vis-req"></a>

```
sudo pip install dash pandas
```

## Fedora: <a id="fedora"></a>

### FIO <a id="fedora-fio"></a>
```
dnf install -y fio
```

### Postmark <a id="fedora-postmark"></a>
already in [postmark directory](postmark_tests/postmark/) along with the source code (postmark-1_5.c)

### Sqlite <a id="fedora-sqlite"></a>
```
dnf install -y sqlite3
```

### Terasort <a id="fedora-terasort"></a>
hadoop is downloaded with setup_env.sh script in [terasort directory](terasort_tests/terasort_datadir)
either run setup_env.sh or any of the benchmarks which will eventually run the setup script anyway.

### YCSB <a id="fedora-ycsb"></a>
Binaries are in [ycsb directory](ycsb_tests/ycsb_datadir/) but java and python2 are required, as well as mongodb.
#### Java and Python2 <a id="fedora-java-python2"></a>
```
sudo dnf -y install java-21-openjdk python2
```
#### Mongodb <a id="fedora-mongodb"></a>
```
sudo nano /etc/yum.repos.d/mongodb-org-7.0.repo
```
Put this in the file:

```
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9Server/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
```

```
dnf -y install mongodb-org 
```

If you get an openssl error:

```
systemctl stop mongod

rpm -e mongodb-org mongodb-mongosh

dnf install -y mongodb-org mongodb-mongosh-shared-openssl3

systemctl start mongod 
```

### Requirements to visualize: <a id="fedora-vis-req"></a>

```
sudo pip install dash pandas
```
# Running the scripts: <a id="running-scripts"></a>

Each benchmark folder contains 4 scripts to test the different parameters (Ringbuffer, Userspace API, Kernel API, Trace Storage)

cd into the folder of choice after installing the requirements, it is important be in the folder before running the scripts.

Each script outputs the runtimes in a csv file.

Once all 4 csv files are created you can visualize the results using dash_app.py or runtimes_compare.py.

```
sudo python3 runtimes_compare.py
```

```
sudo python3 dash_app.py
```
