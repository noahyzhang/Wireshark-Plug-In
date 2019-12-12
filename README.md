## 基于Lua的wireshark插件 --- Export H264 to file

**The wireshark plug-in dissector the data of H264 and OPUS, extracts, sorts and frames the data in H264 format, and finally saves it to the local stream in H264 format. **

### 一、需求分析

- 我们的视频会议的视频数据采用的RTP包，我们在RTP的payload中填充了我们自定义的数据。RTP包的payload中第一个字节是PT，接下来二个字节是SequenceNumber，如果是视频包，后面的才是视频H264格式的数据。
- 由于这种结构导致wireshark无法正确解析更上一层的数据。只能解析到RTP数据包这一层。如下图。

- ![./Image/1.png]

- 有时，我们需要分析H264的报文，因此一款插件来解析RTP包中的payload来显示出H264的数据就非常的有必要。如下图

  ![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/2.png]

### 二、实现功能

1. 解析了H264视频数据的三种格式的包，NAL unit、FU-A、STAP-A
2. 解析了视频包fec重传包、NACK包
3. 解析了音频包、音频的fec包
4. 将wireshark抓到的包，进行过滤提取H264的数据包，对这些数据包进行排序、组帧、保存到本地。

### 三、操作说明

1. 首先将**wireshark-plug-in**项目克隆到本地。打开**dist**目录，会看到有四个lua文件。![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/3.png]

2. 将这四个lua文件放到wireshark根目录下，比如我的wireshark放在**D:\ \wireshark\ **下，就把四个lua文件放在“D:\ \wireshark\”下。![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/4.png]

3. 接下来，在wireshark的根目录下，找到 “init.lua”,使用记事本或者notepad++或者其他工具打开它，在这个lua文件的开头修改 “enable_lua” 为 “true”，让wireshark支持lua插件。注：不同版本的wireshark略有不同，一定要看“enable_lua = true ”这句代码上面的注释。![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/5.png]

4. 把“init.lua” 这个lua文件拉到最后一行，增添四行代码。如下图。从700行到704行。![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/6.png]

5. 这时，“init.lua”这个文件操作完了，一定要保存，保存，保存。
6. 以上操作完成之后打开wireshark软件。进行实时抓取RTP包，或者打开已经保存的RTP包。
7. 对于有些版本的wireshark，我们需要继续手动将lua脚本导入wireshark中。如下图，点击重新载入lua插件。![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/7.png]

**注：一般不会出现问题。如果出现BUG，别担心，大概率是一个乌龙事件，我们只需要重新载入Lua插件就行。**

### 四：解析协议

- 首先熟悉一下RTP包的上层都有哪些协议。![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/8.png]
- 如下图，Red Protocol 代表的解析的RTP包的 payload。**payload前三个字节分别是rtp的pt和sequence number。**接下来就是H264的数据，如下图，这个包就是H264包的sps、pps格式的数据包。 ![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/9.png]

- 如下图，H264数据包中FU-A的包。还有STAP-A包类同。![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/10.png]

- 如下图，是视频包的FEC包。可以看到PT是109![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/11.png]

- 如下图，是视频包的NACK包，可以看到RTP的PT是107.![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/12.png]

- 如下图，是抓取到的音频包，可以看到RTP的PT 是97.![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/13.png]

- 如下图，是音频包的FEC包，可以看到对应的PT是101.![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/14.png]

**注：对音频包的NACK包，由于wireshark对于RTP的字段100已经有了定义，无法对同一字段做两次定义，所以暂时没有解析音频包的NACK包。**

### 五、导出H264数据到文件

- 点击wireshark界面”工具“菜单，会看到”Export H264 to file" 这个选项，点击它。![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/15.png]

- 会弹出一个对话框，有三个选项，“Export All”选项的意思是导出所有的H264的数据，“Export Completed Frames (Drop uncompleted frames)”选项的意思是导出具有完整帧的H264数据（丢弃不完整的帧）。![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/16.png]

- 根据自己的需求去导出需要的H264数据。当对话框出现“generated OK”时，意味着导出H264数据完毕。导出的H264文件存放在wireshark工作目录下。如下图，![https://github.com/zhangyi-13572252156/Wireshark-Plug-In/raw/master/Image/17.png]

- 导出的以“.h264”为后缀的文件，我们可以使用“VLC media player“软件去播放，或者使用ffplay去播放。

**注：导出的文件命名标记了哪路流，如：”from_47.99.123.92_5004to172.18.40.57_44348_dropped.h264“代表这个文件保存的是从”IP地址47.99.123.92，端口5004发往IP地址172.18.40.57，端口44348“的哪路流。”dropped“代表的是这个文件保存的具有完整帧的H264数据。”all“代表的是这个文件保存的是全部的H264数据。另：有几路流，就会有几个文件去保存这几路流。**
