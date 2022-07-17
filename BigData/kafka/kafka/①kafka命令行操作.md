## Kafka命令行操作

<img src="D:\typroa.md\image\Snipaste_2022-04-19_21-43-39.png" style="zoom:50%;" />

### 1.主题命令行操作

#### 1）查看操作主题命令参数

```shell
bin/kafka-topics.sh
```

<img src="D:\typroa.md\image\Snipaste_2022-04-19_21-44-44.png" style="zoom:50%;" />

#### 2）查看当前服务器中的所有  topic

```shell
bin/kafka-topics.sh --bootstrap-server hadoop102:9092 --list
```

#### 3）创建 first topic

```shell
bin/kafka-topics.sh --bootstrap-server hadoop102:9092 --topic first --create --partitons 1 --replication-factor 3
```

#### 4）查看 first 主题的详情

```shell
bin/kafka-topics.sh --bootstrap-server hadoop102:9092 --describe --topic first
```

#### 5）修改分区数（注意：分区数只能增加，不能减少）

```shell
bin/kafka-topics.sh --bootstrap-server hadoop102:9092 --alter --topic first --partitions 3
```

#### 6）再次查看 first 主题的详情

```shell
bin/kafka-topics.sh --bootstrap-server hadoop102:9092 --describe --topic first
```

#### 7）删除 topic（学生自己演示）

```shell
bin/kafka-topics.sh --bootstrap-server hadoop102:9092 --delete --topic first
```

### 2.生产者命令行操作

#### 1）查看操作生产者命令参数

```shell
bin/kafka-console-producer.sh
```

![](D:\typroa.md\image\Snipaste_2022-04-19_21-48-25.png)

#### 2）发送消息

```shell
bin/kafka-console-producer.sh   --bootstrap-server hadoop102:9092 --topic first
```

### 3.消费者命令行操作

#### 1）查看操作消费者命令参数

```shell
bin/kafka-console-consumer.sh
```

![](D:\typroa.md\image\Snipaste_2022-04-19_21-48-25-1650376183086.png)

![](D:\typroa.md\image\Snipaste_2022-04-19_21-49-58.png)

#### 2）消费消息

（1）消费 first 主题中的数据。

```shell
bin/kafka-console-consumer.sh   --bootstrap-server hadoop102:9092 --topic first
```

（2）把主题中所有的数据都读取出来（包括历史数据）。

```shell
bin/kafka-console-consumer.sh   --bootstrap-server hadoop102:9092 --from-beginning --topic firs
```