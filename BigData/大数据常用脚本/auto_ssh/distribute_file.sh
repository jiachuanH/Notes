#!/bin/bash

# 说明：
# 脚本会将auto_ssh文件夹上传到服务器上，并在各节点上生成ssh key，并将公钥拷贝到集群各节点上


# 1 在ip.txt中输入各节点ip地址，一行一个ip
# 2 修改scp_to_cluster.sh和copy_id.sh的服务器用户名和密码

# 3 运行如下命令
# chmod 777 ./*
#./distribute_file.sh ../auto_ssh /root/script


# 作者 example500@163.com

while read ip
do
    ./scp_to_cluster.sh  $ip $1 $2
    #echo "-->服务器路径ip:$ip-------脚本路径：$1-------服务器路径：$2"

done < ip.txt





