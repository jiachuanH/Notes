# 一、Maxwell 概述

## 定义



- Maxwell 是由美国 Zendesk 开源，用 Java 编写的 MySQL 实时抓取软件。 实时读取 MySQL 二进制日志 Binlog，并生成 JSON 格式的消息，作为生产者发送给 **Kafka，**Kinesis、 RabbitMQ、Redis、Google Cloud Pub/Sub、文件或其它平台的应用程序。



[官网地址](http://maxwells-daemon.io/)

## 工作原理

- **Mysql主从复制**

  Master 主库将改变记录，写到二进制日志(binary log)中 

  ➢ Slave 从库向 mysql master 发送 dump 协议，将 master 主库的 binary log events 拷贝 到它的中继日志(relay log)；

  ➢ Slave 从库读取并重做中继日志中的事件，将改变的数据同步到自己的数据库





- Maxwell 的工作原理很简单，==就是把自己伪装成 MySQL 的一个 slave==，然后以 slave 的身份假装从 MySQL(master)复制数据。





- **binlog详解**

  - 记录了所有的 ==DDL 和 DML==(除 了数据查询语句)语句，以事件形式记录，还包含语句所执行的消耗的时间，MySQL 的二进 制日志是事务安全型的。

  - **作用**：1、master-slave 数据一致的目的  2、数据恢复

  - **组成**：

    [^文件名后缀为.inde]: 二进制日志索引文件
    [^文件名后缀为.00000*]: 记录数据库所有的 DDL 和 DML

  - **分类 ：**STATEMENT          MIXED               ROW。

    

    | 分类      | 介绍                                                         | 优点                                                         | 缺点                                                         |
    | --------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
    | statement | 语句级，binlog 会记录每次一执行写操作的语句。由于执行时间不同可能产生的数据就不同 例：update test set create_date=now(); | 节省空间                                                     | 有可能造成数据不一致。                                       |
    | row✔      | binlog 会记录每次操作后每行记录的变化。                      | 保持数据的绝对一致性。因为不管 sql 是什么，引用了什么函数，他只记录 执行后的效果。 | 占用较大空间。                                               |
    | mixed     | 上面两种的杂糅后的优化版但并不完美                           | 节省空间，同时兼顾了一定的一致性。                           | 还有些极个别情况依旧会造成不一致，另外 statement 和 mixed 对于需要对 binlog 监控的情况都不方便。 |

    







## 对比

| 对比         | Canal    | Maxwell               |
| ------------ | -------- | --------------------- |
| 语言         | java     | java                  |
| 数据格式     | 格式自由 | json                  |
| 采集数据模式 | 增量     | 全量/增量             |
| 数据落地     | 定制     | 支持 kafka 等多种平台 |
| HA           | 支持     | 支持                  |







# 二、安装部署



[官方文档](https://maxwells-daemon.io/quickstart/)



## Mysql准备

```sh
#修改binlog配置
Linux: /etc/my.cnf
Windows: \my.ini

👇下面为linux配置
$sudo vim /etc/my.cnf
#注意此处my.cnf有权限问题在修改权限写入配置后请务必改回原来的权限-r--r--r--

#添加如下内容
[mysqld]
server_id=1
log-bin=mysql-bin
binlog_format=row
#binlog-do-db=test_maxwell
👆为需要监控的数据库 如不加默认监控mysql数据库

#重启mysql
$ sudo systemctl restart mysqld

#进入MySQL查看binlog是否开启
mysql>show variables like 'log_bin';

#进入/var/lib/mysql 目录，查看 MySQL 生成的 binlog 文件
$cd /var/lib/mysql
$sudo ls -l

```



- **Maxwell元数据库的初始化**

```sql
#在MySQL中建立maxwell数据库用于初始化
mysql> CREATE DATABASE maxwell;

#设置 mysql 用户密码安全级别
mysql> set global validate_password_length=4;
mysql> set global validate_password_policy=0;

#分配一个账号可以操作该数据库
mysql> GRANT ALL ON maxwell.* TO 'maxwell'@'%' IDENTIFIED BY '123456';


#分配这个账号可以监控其他数据库的权限
mysql> GRANT SELECT ,REPLICATION SLAVE , REPLICATION CLIENT ON 
*.* TO maxwell@'%';

#刷新 mysql 表权限
mysql> flush privileges;

```







## Maxwell安装启动

- **解压maxwell-1.29.2.tar.gz**

  ```shell
  $ tar -zxvf maxwell-1.29.2.tar.gz -C /opt/module/
  ```





**启动**

- 方式一     命令行参数启动

  ```sh
  $ bin/maxwell --user='maxwell' --password='123456' --host='hadoop102' --producer=stdout
  ```

  | 参数       | 解释                                            |
  | ---------- | ----------------------------------------------- |
  | --user     | 连接 mysql 的用户                               |
  | --password | 连接 mysql 的用户的密码                         |
  | --host     | mysql 安装的主机名                              |
  | --producer | 生产者模式(stdout：控制台    kafka：kafka 集群) |



- 方式二   配置文件启动

  ```sh
  #拷贝
  $cp config.properties.example config.properties
  
  #修改
  $ vim config.properties
  
  #启动
  $ bin/maxwell --config ./config.properties
  ```

  



# 三、案例实战



## 监控 Mysql 数据并在控制台打印

```sh
#启动Maxwell
$ bin/maxwell --user='maxwell' --password='123456' --host='hadoop102' --producer=stdout


👇提前创建好表
#向 mysql 的 test_maxwell 库的 test 表插入一条数据，查看 maxwell 的控制台输出
mysql> insert into test values(1,'aaa');


#查看 maxwell 的控制台输出




```





## 监控 Mysql 数据输出到 kafka

### kafka消费者控制台

```sh
#启动zookeeper 和kafka
$zk start
$kf start

#命令行启动Maxwell指定kafka
$ bin/maxwell --user='maxwell' --password='123456' --host='hadoop102' --producer=kafka -kafka.bootstrap.servers=hadoop102:9092 --kafka_topic=maxwell


#启动kafka消费者查看消费数据
$ kafka-console-consumer.sh --bootstrap-server hadoop102:9092 --topic maxwell

#插入数据查看kafka控制台
mysql> insert into test values (5,'eee');

```



### 分区控制

------

> 需求：生产环境中有将不同数据库或一个数据库的不同表等发送到Kafka的不同分区



```sh
#修改 maxwell 的配置文件，定制化启动 maxwell 进程

$vim config.properties
👇以下为需要修改的内容

# tl;dr config
log_level=info
producer=kafka
kafka.bootstrap.servers=hadoop102:9092

# mysql login info
host=hadoop102
user=maxwell
password=000000

# *** kafka ***
kafka_topic=maxwell3

# *** partitioning ***   👇控制数据分区模式，可选模式有 库名，表名，主键，列名
#producer_partition_by=database # [database, table, primary_key, transaction_id, column]
producer_partition_by=database

:wq

#手动创建分区  当然也可以去kafka监控中创建名字maxwell3
$ kafka-topics.sh --zookeeper hadoop102:2181,hadoop103:2181,hadoop104:2181/kafka --create --replication-factor 2 --partitions 3 --topic maxwell3

#启动maxwell
$ bin/maxwell --config ./config.properties

#向mysql test_maxwell表插入数据
mysql> insert into test_maxwell.test values (6,'fff');


#通过监控查看分区数据
```





## 指定表输出到控制台

```sh
$ bin/maxwell --user='maxwell' --password='123456' --host='hadoop102' --filter 'exclude: *.*, include:test_maxwell.test' --producer=stdout

          👆数据库.表名字


```







## 监控 Mysql 指定表全量数据输出控制台，数据初始化



==修改 Maxwell 的元数据，触发数据初始化机制，在 mysql 的 maxwell 库中 bootstrap 表中插入一条数据，写明需要全量数据的库名和表名==



```sql
mysql> insert into maxwell.bootstrap(database_name,table_name) values('test_maxwell','test2');
```





**启动maxwel初始化时会打印Maxwell的初始化表的所有数据**















