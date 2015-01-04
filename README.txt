WSN
===

Computer Networking Project 2


必修实验：

文件结构：
Sense/ -- 节点源代码
BaseStation/ -- 基站源代码
DataVision/ -- 数据可视化源代码
Result/ -- 结果

BaseStation
使用make telosb install,0刷入0号节点

Sense
使用make telosb install,1刷入1号节点
使用make telosb install,2刷入2号节点

DataVision
make后执行./run。需要提前启动java net.tinyos.sf.SerialForwarder。


选修实验：

文件结构：
Data/ -- 节点源代码
DataTest/ -- 基站源代码

Data
使用make telosb install,34刷入34号节点
使用make telosb install,35刷入35号节点
使用make telosb install,36刷入36号节点

DataTest
使用make telosb install,1000刷入1000号节点

