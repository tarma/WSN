WSN
===

Computer Networking Project 2

文件结构：
Sense/ -- 节点源代码
BaseStation/ -- 基站源代码
DataVision/ -- 数据可视化源代码

BaseStation
使用make telosb install,0刷入0号节点

Sense
使用make telosb install,1刷入1号节点
使用make telosb install,2刷入2号节点

DataVision
make后执行./run。需要提前启动java net.tinyos.sf.SerialForwarder。

