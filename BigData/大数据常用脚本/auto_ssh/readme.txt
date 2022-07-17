
一键配置集群各节点ssh免密码登录

首先确保每个节点已经安装了expect ，确保服务器/root/script路径存在
修改每个节点ssh配置
vi /etc/ssh/ssh_config 
-------------------------------
#    StrictHostKeyChecking ask 
-------------------------------
StrictHostKeyChecking no（取消注释并改为no）


说明：
脚本会将auto_ssh文件夹上传到服务器上，并在各节点上生成ssh key，并将公钥拷贝到集群各节点上


1 在ip.txt中输入各节点ip地址，一行一个ip
2 修改scp_to_cluster.sh和copy_id.sh的服务器用户名和密码

3 运行如下命令
# chmod 777 ./*
#./distribute_file.sh ../auto_ssh /root/script


作者 example500@163.com



