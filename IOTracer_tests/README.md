## Requirements
###     Ubuntu 22.04:

#### FIO
```
sudo apt-get install fio
```
#### POSTMARK
already in [postmark directory](postmark_tests/postmark/) along with the source code (postmark-1_5.c)

#### SQLITE
```
sudo apt-get install sqlite3
```

#### Terasort
hadoop is downloaded with setup_env.sh script in [terasort directory](terasort_tests/terasort_datadir)
either run setup_env.sh or any of the benchmarks which will eventually run the setup script anyway.

#### YCSB
```
apt-get install python2 openjdk-21-jre
```
#mongodb install 22.04:


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

#### Requirements to visualize:

```
sudo pip install dash pandas
```

### Fedora:

TO DO.

## Running scripts:

Each benchmark folder contains 4 scripts to test the different parameters (Ringbuffer, Userspace API, Kernel API, Trace Storage)

cd into the folder of choice after installing the requirements, it is important be in the folder before running the scripts.

Each script outputs the runtimes in a csv file.

Once all 4 csv files are created you can visualize the results using the dash_app.py file.

```
sudo python3 dash_app.py
```
