#!/bin/bash

# 文件不存在，就创建
if [ ! -f ~/.ssh/id_rsa.pub ];    then
    
    # 创建文件夹
    [[ -d ~/.ssh ]] || mkdir ~/.ssh
    # 生成ssh key，不用输入回车
    ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa
    echo "================== gen ssh key done..."

else 
    echo "==================  ssh key exist..."
fi


sleep 1


# 读取ip列表，向各节点分发认证文件，（不能在expect脚本中循环遍历文件，需要用shell把ip传过去）
while read ip
do
    $(cd "$(dirname "$0")"; pwd)/copy_id.sh  $ip

done < $(cd "$(dirname "$0")"; pwd)/ip.txt





