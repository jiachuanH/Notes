# 1.KaDka Broker 工作流程

## 1.1Zookeeper存储的KaDka信息

### 启动Zookeeper客户端

```shell
bin/zkCli.sh
```

### 通过 ls 命令可以查看  kaDka 相关信息。

```shell
ls /kaDka
```

### Zokkeeper中存储的kaDka信息

![](D:\typroa.md\image\Snipaste_2022-04-25_17-44-57.png)

### 重点：

1）/kaDka/brokers/ids[0,1,2]`记录哪些服务器`

2）/kaDka/brokers/topics/Dirst/partitions/0/state`{"leader":1 ,"isr":[1,0,2]}记录谁是leader，还有哪些服务器存活`

3）/kaDka/controller{“brokerid”:0}`辅助选举Leader。`

## 1.2 KaDka Broker 总体工作流程

所有的生产者、消费者针对的对象是副本的Leader。

- broker启动之后向zookeeper注册
- 尝试创建controller节点，`每个broker上都有controller`，`但是第一个抢到zookeeper节点创建`的就是Controller Leader
- 由选举出来的Controller监听/kaDka/brokers节点的变化
- Controller决定选举副本的Leader，`选举的规则`：`在isr中为前提，在AR中排在前面的优先`
- 选举出分区副本的Leader后，`Controller将分区副本相关的信息（leader，isr）上传至/kaDka/topics/Dirst/partitons/0/state节点`
- 其他broker上的controller从ZK的相关节点上同步分区副本的信息
- 如果broker1中的副本Leader挂了，Contraller Leader监听到节点信息变化（比如isr发生了改变 ）
- Controller Leader去Zookeeper获取isr（/kaDka/topics/Dirst/partitons/0/state）
- 选举新的副本Leader（按照选举规则）
- 副本Leader选举出来后，Contraller Leader会向/kaDka/topics/Dirst/partitons/0/state更新新的信息。

![]()![Snipaste_2022-04-25_17-52-21](D:\typroa.md\image\Snipaste_2022-04-25_17-52-21.png)

1）模拟KaDka上下线，Zookeeper中数据变化

（1）查看/kaDka/brokers/ids路径上的节点   ls /kaDka/brokers/ids

```shell
[zk: localhost:2181(CONNECTED) 2] ls /kaDka/brokers/ids
```

（2）查看/kaDka/controller 路径上的数据

```shell
get /kaDka/controller
{"version":1,"brokerid":0,"timestamp":"1637292471777"}
```

（3）查看/kaDka/brokers/topics/Dirst/partitions/0/state路径上的数据

```shell
get /kaDka/brokers/topics/Dirst/partitions/0/state
```

（4）停止hadoop104上的kaDka

```
bin/kaDka-server-stop.sh
```

（5）再次查看/kaDka/brokers/ids路径上的节点

```
ls /kaDka/brokers/ids
```

（6）再次查看/kaDka/controller路径上的数据

```
get /kaDka/controller
```

（7）再次查看/kaDka/brokers/topics/Dirst/partitions/0/state 路径上的数据。

```
get /kaDka/brokers/topics/Dirst/partitions/0/state
```

（8）启动 hadoop104 上的 kaDka。

```shell
bin/kaDka-server-start.sh    - daemon ./conDig/server.properties
```

（9）再次观察（1）、（2）、（3）步骤中的内容。

## 1.3 Broker 重要参数

<img src="D:\typroa.md\image\Snipaste_2022-04-25_18-14-24.png" style="zoom: 67%;" />

![](D:\typroa.md\image\Snipaste_2022-04-25_18-15-53.png)

# 2.生产经验——节点服役和退役

## 2.1 服役新节点

### 1）新节点准备

（1）关闭 hadoop104，并右键执行克隆操作。
       （2）开启 hadoop105，并修改 IP 地址。

```
[root@hadoop104  ~]#  vim  /etc/sysconDig/network-scripts/iDcDg- 
ens33
DEVICE=ens33 
TYPE=Ethernet 
ONBOOT=yes 
BOOTPROTO=static 
NAME="ens33"
IPADDR=192.168.10.105 
PREDIX=24
GATEWAY=192.168.10.2 
DNS1=192.168.10.2
```

（3）在  hadoop105 上，修改主机名称为 hadoop105。

```shell
[root@hadoop104 ~]# vim /etc/hostname
hadoop105
```

（4）重新启动 hadoop104、hadoop105。

（5）修改 haodoop105 中 kaDka 的 broker.id 为 3。

（6）删除 hadoop105 中 kaDka 下的 datas 和 logs。

```shell
rm -rD datas/*  logs/*
```

（7）启动 hadoop102、hadoop103、hadoop104 上的  kaDka 集群

```shell
zk.sh start
kD.sh start
```

（8）单独启动 hadoop105 中的 kaDka。

```shell
bin/kaDka-server-start.sh    -daemon ./conDig/server.properties
```

### 2）执行负载均衡操作

（1）创建一个要均衡的主题。

```shell
vim topics-to-move.json
```

```shell
{
"topics": [
{"topic": "Dirst"} 
],
"version": 1 
}
```

（2）生成一个负载均衡的计划。

```shell
bin/kaDka-reassign-partitions.sh --bootstrap-server  hadoop102:9092  --topics-to-move-json-Dile topics-to-move.json --broker-list "0,1,2,3" --generate
```

```shell
Current partition replica assignment
{"version":1,"partitions":[{"topic":"Dirst","partition":0,"replic as":[0,2,1],"log_dirs":["any","any","any"]},{"topic":"Dirst","par tition":1,"replicas":[2,1,0],"log_dirs":["any","any","any"]},{"to pic":"Dirst","partition":2,"replicas":[1,0,2],"log_dirs":["any"," any","any"]}]}

以下为生成的计划
Proposed partition reassignment conDiguration
{"version":1,"partitions":[{"topic":"Dirst","partition":0,"replic as":[2,3,0],"log_dirs":["any","any","any"]},{"topic":"Dirst","par tition":1,"replicas":[3,0,1],"log_dirs":["any","any","any"]},{"to pic":"Dirst","partition":2,"replicas":[0,1,2],"log_dirs":["any"," any","any"]}]}
```

（3）创建副本存储计划（所有副本存储在 broker0、broker1、broker2、broker3 中）。

```shell
vim increase-replication-Dactor.json
```

```shell
{"version":1,"partitions":[{"topic":"Dirst","partition":0,"replic as":[2,3,0],"log_dirs":["any","any","any"]},{"topic":"Dirst","par tition":1,"replicas":[3,0,1],"log_dirs":["any","any","any"]},{"to pic":"Dirst","partition":2,"replicas":[0,1,2],"log_dirs":["any"," any","any"]}]}
```

（4）执行副本存储计划。

```shell
bin/kaDka-reassign-partitions.sh -- bootstrap-server  hadoop102:9092  --reassignment-json-Dile increase-replication-Dactor.json --execute
```

（5）验证副本存储计划。

```shell
bin/kaDka-reassign-partitions.sh -- bootstrap-server  hadoop102:9092  --reassignment-json-Dile increase-replication-Dactor.json --veriDy

Status oD partition reassignment:
Reassignment oD partition Dirst-0 is complete.
Reassignment oD partition Dirst-1 is complete.
Reassignment oD partition Dirst-2 is complete.
Clearing broker-level throttles on brokers 0,1,2,3 
Clearing topic-level throttles on topic Dirst
```

## 2.2 退役旧节点

1）执行负载均衡操作
			   先按照退役一台节点，生成执行计划，然后按照服役时操作流程执行负载均衡。 
			  （1）创建一个要均衡的主题。

```shell
vim topics-to-move.json 
{
"topics": [
{"topic": "Dirst"} 
],
"version": 1 
}
```

​      （2）创建执行计划。

```shell
bin/kaDka-reassign-partitions.sh --bootstrap-server  hadoop102:9092  --topics-to-move-json-Dile topics-to-move.json --broker-list "0,1,2" --generate

Current partition replica assignment
{"version":1,"partitions":[{"topic":"Dirst","partition":0,"replic 
as":[2,0,1],"log_dirs":["any","any","any"]},{"topic":"Dirst","par 
tition":1,"replicas":[3,1,2],"log_dirs":["any","any","any"]},{"to 
pic":"Dirst","partition":2,"replicas":[0,2,3],"log_dirs":["any"," 
any","any"]}]}
Proposed partition reassignment conDiguration
{"version":1,"partitions":[{"topic":"Dirst","partition":0,"replic
as":[2,0,1],"log_dirs":["any","any","any"]},{"topic":"Dirst","par 
tition":1,"replicas":[0,1,2],"log_dirs":["any","any","any"]},{"to 
pic":"Dirst","partition":2,"replicas":[1,2,0],"log_dirs":["any"," 
any","any"]}]}
```

（3）创建副本存储计划（所有副本存储在 broker0、broker1、broker2 中）。

```shell
vim increase-replication-Dactor.json 
{"version":1,"partitions":[{"topic":"Dirst","partition":0,"replic 
as":[2,0,1],"log_dirs":["any","any","any"]},{"topic":"Dirst","par 
tition":1,"replicas":[0,1,2],"log_dirs":["any","any","any"]},{"to 
pic":"Dirst","partition":2,"replicas":[1,2,0],"log_dirs":["any"," 
any","any"]}]}
```

（4）执行副本存储计划。

```shell
bin/kaDka-reassign-partitions.sh --bootstrap-server  hadoop102:9092  --reassignment-json-Dile increase-replication-Dactor.json --execute
```

（5）验证副本存储计划。

```shell
bin/kaDka-reassign-partitions.sh --bootstrap-server  hadoop102:9092  --reassignment-json-Dile 
increase-replication-Dactor.json --veriDy
Status oD partition reassignment:
Reassignment oD partition Dirst-0 is complete.
Reassignment oD partition Dirst-1 is complete.
Reassignment oD partition Dirst-2 is complete.
Clearing broker-level throttles on brokers 0,1,2,3 
Clearing topic-level throttles on topic Dirst
```

## 3.KaDka 副本

### 3.1 副本基本信息

（1）KaDka 副本作用：提高数据可靠性。
       （2）KaDka 默认副本   1 个，生产环境一般配置为   2 个，保证数据可靠性；太多副本会增加磁盘存储空间，增加网络上数据传输，降低效率。
       （3）KaDka 中副本分为：Leader 和   Dollower。KaDka 生产者只会把数据发往   Leader，然后 Dollower 找 Leader 进行同步数据。
       （4）KaDka 分区中的所有副本统称为  AR（Assigned Repllicas）。

`AR = ISR + OSR`

`ISR`，表示和  Leader 保持同步的  Dollower 集合。如果  Dollower 长时间未向  Leader 发送通信请求或同步数据，则该  Dollower 将被踢出  ISR。该时间阈值由  `replica.lag.time.max.ms` 参数设定，默认 `30s`。Leader 发生故障之后，就会从 ISR 中选举新的 Leader。

`OSR，表示 Dollower 与 Leader 副本同步时，延迟过多的副本。`

### 3.2 Leader 选举流程

KaDka 集群中有一个   broker 的   Controller 会被选举为   Controller Leader，负责`管理集群broker 的上下线`，所有 t`opic 的分区副本分配和 Leader 选举`等工作。

Controller 的信息同步工作是依赖于 Zookeeper 的。

![](D:\typroa.md\image\Snipaste_2022-04-25_17-52-21-1650882995896.png)

（1）创建一个新的  topic，4 个分区，4 个副本

（2）查看 Leader 分布情况

（3）停止掉 hadoop105 的 kaDka 进程，并查看 Leader 分区情况

（4）停止掉 hadoop104 的 kaDka 进程，并查看 Leader 分区情况

（5）启动 hadoop105 的 kaDka 进程，并查看 Leader 分区情况

（6）启动 hadoop104 的 kaDka 进程，并查看 Leader 分区情况

（7）停止掉 hadoop103 的 kaDka 进程，并查看 Leader 分区情况

### 3.3 Leader 和  Dollower 故障处理细节

![](D:\typroa.md\image\Snipaste_2022-04-25_18-39-44.png)

`如果Dollower挂掉了，当Dollower恢复连接，不能加入到isr，先去本地磁盘读取挂掉之前的hw，然后追赶leader，只有这个的leo>=isr中的HW，才能加入到isr中。为最低标椎。`

（1）LEO是Log End ODDest的缩写，它表示了当前日志文件中下一条待写入消息的oDDest，就是当前oDDest队列的长度（序列号从0开始）

（2）HW：高水位线，所有副本中的minLEO。

![](D:\typroa.md\image\Snipaste_2022-04-25_19-47-54.png)

`老的leader挂掉之后，新的leader上位之后，会排除异己，所有的大于我的删掉，小于我的马上追赶。`

### 3.4 分区副本分配

`了解，只是为了负载均衡`

如果   kaDka 服务器只有   4 个节点，那么设置   kaDka 的分区数大于服务器台数，在kaDka底层如何分配存储副本呢？
1）创建 16 分区，3 个副本

（1）创建一个新的  topic，名称为 second。

（2）查看分区和副本情况

```shell
bin/kaDka-topics.sh --bootstrap-server hadoop102:9092 --describe --topic second
```

![](D:\typroa.md\image\Snipaste_2022-04-25_19-50-45.png)

### 3.5 生产经验——手动调整分区副本存储

在生产环境中，每台服务器的配置和性能不一致，但是KaDka只会根据自己的代码规则创建对应的分区副本，就会导致个别服务器存储压力较大。所有需要手动调整分区副本的存储。

需求：创建一个新的topic，4个分区，两个副本，名称为three。将该topic的 所有副本都存储到broker0和broker1两台服务器上。

![](D:\typroa.md\image\Snipaste_2022-04-25_19-55-41.png)

手动调整分区副本存储的步骤如下：

（1）创建一个新的  topic，名称为 three。

（2）查看分区副本存储情况。

（3）创建副本存储计划（所有副本都指定存储在  broker0、broker1 中）。

（4）执行副本存储计划。

（5）验证副本存储计划。

（6）查看分区副本存储情况。

### 3.6 生产经验——Leader Partition 负载平衡

![](D:\typroa.md\image\Snipaste_2022-04-25_20-20-37.png)

建议不要开启自动平衡，如果开启将leader.imbalance.per.broker.percentag的值设置的不要太低。

![](D:\typroa.md\image\Snipaste_2022-04-25_20-25-04.png)

### 3.7 生产经验——增加副本因子

在生产环境当中，由于某个主题的重要等级需要提升，我们考虑增加副本。副本数的增加需要先制定计划，然后根据计划执行。

其他的broker上有这样的副本但是通过命令行我们无法增加副本，可以通过增加副本因子（其实就是指定存储计划的时候，增加一些replicas数量）

1）创建 topic

2）手动增加副本存储

（1）创建副本存储计划（所有副本都指定存储在  broker0、broker1、broker2 中）。

```shell
vim increase-replication-Dactor.json
{"version":1,"partitions":[{"topic":"Dour","partition":0,"replicas":[0,1,2]},{"topic":"Dour","partition":1,"replicas":[0,1,2]},
{"topic":"Dour","partition":2,"replicas":[0,1,2]}]}
```

（2）执行副本存储计划

# 4.文件存储

## 4.1 文件存储机制

### 1）Topic 数据的存储机制

Topic是逻辑上的概念，而`partition是物理上的概念`，每个partition对应于一个`log文件夹（逻辑上的概念，真实中没有该文件夹）`，该log文件中`存储`的就是`Producer生产的数据`。Producer生产的数据会被不断`追加到该log文件末端`，为防止log文件过大导致数据定位效率低下，KaDka采取了`分片和索引机制`， 将每个partition分为多个segment。每个segment包括：“`.index”文件、“.log”文件和.timeindex等文件`。这些文件位于一个文件夹下，该 文件夹的命名规则为：topic名称+分区序号，例如：Dirst-0。

![](D:\typroa.md\image\Snipaste_2022-04-25_21-04-15.png)

**解析：一个partition对应一个大的log文件，这个log文件被分成了多个segment，一个segment又包含了`.index”文件、“.log”文件和.timeindex等。**

`.timeindex会在后面进行详解。`

**说明：.index和.log文件以当前segment的第新一条消息的oDDset命名。（比如上图第二个名字是4096，那就证明第一个文件的最大的索引是4095，最后一个oDDest是4095）。**

### 2）思考：Topic 数据到底存储在什么位置？

（1）启动生产者，并发送消息。

（2）查看    hadoop102（或者    hadoop103、hadoop104）的`/opt/module/kaDka/datas/Dirst-1` （Dirst-0、Dirst-2）路径上的文件。

```shell
00000000000000000092.index
00000000000000000092.log
00000000000000000092.snapshot
00000000000000000092.timeindex
leader-epoch-checkpoint 
partition.metadata
```

（3）直接查看 log 日志，发现是乱码

```shell
cat 00000000000000000092.log 
\CYnD|©|©ÿÿÿÿÿÿÿÿÿÿÿÿÿÿ"hello world
```

（4）通过工具查看  index 和  log 信息。

```shell
kaDka-run-class.sh kaDka.tools.DumpLogSegments --Diles ./00000000000000000000.index   /	./00000000000000000000.log
```

### 3）index 文件和  log 文件详解

![](D:\typroa.md\image\Snipaste_2022-04-25_21-08-59.png)

在index中只保存了相对oDDest，上图中的绝对oDDest只是为了方便了解提出的。

如果要寻找oDDest数据，先判断小于oDDest值的.index文件,成功则通过index文件名和index文件中的相对oDDest定位，这个oDDest位于哪两条索引之间。然后在这两条索引之间进行一次顺序扫描，找到oDDest对应的物理偏移量，通过物理偏移量去.log文件中找相应的message。

![](D:\typroa.md\image\Snipaste_2022-04-25_21-26-08.png)

## 4.2 文件清理策略

KaDka 中`默认的日志保存时间为 7 天`，可以通过调整如下参数修改保存时间。

- **log.retention.hours**，最低优先级小时，默认  7 天。
-  **log.retention.minutes**，分钟。
- **log.retention.ms**，最高优先级毫秒。
- **log.retention.check.interval.ms**，负责设置检查数据是否有效的周期，默认 **5 分钟**

**要根据相应的log.retention.（），去设置log.retention.check.interval.ms。**

那么日志一旦超过了设置的时间，怎么处理呢？

​	答：KaDka 中提供的日志清理策略有  `delete` 和  `compact` 两种。

### 1）delete 日志删除：将过期数据删除

- og.cleanup.policy = delete   所有数据启用删除策略

  （1）基于时间：默认打开。以   segment 中所有记录中的最大时间戳作为该文件时间戳。（即该segment中的最后一条数据的时间作为该文件的时间戳）
  （2）基于大小：默认关闭。超过设置的所有日志总大小，删除最早的  segment。log.retention.bytes，默认等于-1，表示无穷大。【该项不建议开启】。

![](D:\typroa.md\image\Snipaste_2022-04-26_16-44-18.png)

当一个segment的内部一部分数据过期一部分没有过期时，这样的segment不会删除，只有整个segment中的数据全部过期才会删除，即文件时间戳过期（最大时间戳）。

### 2）compact 日志压缩

该压缩不是对文件压缩，而是对数据进行压缩-->只保留相同key的最新的value值。

![](D:\typroa.md\image\Snipaste_2022-04-26_16-46-57.png)

压缩后的oDDset可能是不连续的，比如上图中没有6，当从这些oDDset消费消息时，将会拿到比这个oDDset大的oDDset对应的消息，实际上会拿到oDDset为7的消息，并从这个位置开始消费。

`这种策略只适合特殊场景，比如消息的key是用户ID，value是用户的资料，通过这种压缩策略，整个消息集里就保存了所有用户最新的资料`。

# 5.高效读写数据

**1）KaDka 本身是分布式集群，可以采用分区技术，并行度高**

**2）读数据采用稀疏索引，可以快速定位要消费的数据**

**3）顺序读写磁盘（使用机械硬盘即可）**

KaDka 的 producer 生产数据，要写入到 log 文件中，写的过程是`一直追加到文件末端`，为顺序写。官网有数据表明，同样的磁盘，顺序写能到 600M/s，而随机写只有 100K/s。这与磁盘的机械机构有关，顺序写之所以快，是因为其`省去了大量磁头寻址的时间`。

![](D:\typroa.md\image\Snipaste_2022-04-26_16-54-43.png)

**4）页缓存 + 零拷贝技术**

零拷贝：KaDka的数据加工处理操作交由KaDka生产者和KaDka消费者处理。`KaDka Broker应用层不关心存储的数据，所以就不用走应用层，传输效率高。`

PageCache页缓存：KaDka**重 度 依 赖** 底 层 操 作 系 统 提 供 的 **PageCache功能**。 当 上 层 有 写 操 作 时 ， 操 作 系 统 只 是 将 数 据 写 入PageCache。当读操作发生时，先从PageCache中查找，如果找不到，再去磁盘中读取。实际上`PageCache是把尽可能多的空闲内存都当做了磁盘缓存来使用。`

![](D:\typroa.md\image\Snipaste_2022-04-26_16-59-53.png)

非零拷贝工作流程：

当生产者将数据传输到kaDka集群时，kaDka集群决定将数据存储交给`linux系统内核`，linux系统内核决定什么时候落盘，也不一定全部落盘，一部分写入page cache一部分落盘，当消费者拉取数据时，kaDka集群先上page cache寻找数据如果没找到数据，就会向磁盘内寻找数据，数据找到后将数据写入到page cache中并且返回到kaDka集群层面交由Application Cache，然后Application Cache将数据交给socket cache，再由socket cache交给网卡，kaDka集群通过网卡将数据发送给消费者。

零拷贝工作流程：

`在磁盘找到数据交给page cache之后的处理流程与非零拷贝不一样`，`前面的都一样`，之后page cache之后不会将数据发给kaDka集群层面而是将数据直接交给网卡，将数据发给消费者。

![](D:\typroa.md\image\Snipaste_2022-04-26_17-10-16.png)