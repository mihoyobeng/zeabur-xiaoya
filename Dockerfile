FROM ubuntu:22.04

# 环境变量配置：规避交互式安装提示，预设核心路径与版本（无需后续手动配置）
# 小雅媒体库目录（绝对路径，可按需修改）
ENV DEBIAN_FRONTEND=noninteractive
ENV XIAOYA_HOME=/opt/xiaoya
ENV MEDIA_DIR=/opt/xiaoya/media
# 预设Emby指定版本
ENV EMBY_VERSION=4.9.0.42
# Zeabur X86架构适配的Emby镜像
ENV EMBY_IMAGE=amilys/embyserver
# 启用定时爬虫功能
ENV CRON_ENABLE=yes

# 第一步：安装小雅运行所需依赖工具
RUN apt update && apt install -y \
    curl \
    wget \
    sudo \
    docker.io \
    cron \
    vim \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*  # 清理apt缓存，减小镜像体积（此处注释合法，因在RUN行内，属于shell注释）

# 第二步：创建小雅工作目录与媒体库目录（确保目录存在且有读写权限）
RUN mkdir -p ${XIAOYA_HOME} \
    && mkdir -p ${MEDIA_DIR} \
    && chmod -R 755 ${XIAOYA_HOME} \
    && chmod -R 777 ${MEDIA_DIR}

# 第三步：拉取小雅原版安装脚本，保存到小雅工作目录
RUN curl --insecure -fsSL https://ddsrem.com/xiaoya_install.sh -o ${XIAOYA_HOME}/xiaoya_install.sh

# 第四步：赋予脚本执行权限，确保后续可正常运行
RUN chmod +x ${XIAOYA_HOME}/xiaoya_install.sh

# 第五步：预配置emby_config.txt（替代原交互式图形化配置2 4，适配Zeabur环境）
# 直接生成配置文件，无需手动选择，对应原配置要求：①关闭 ②Bridge模式 ③指定镜像 ④4.9.0.42 ⑤媒体库路径
RUN echo "# Emby Config for Zeabur Auto Build" > ${XIAOYA_HOME}/emby_config.txt \
    && echo "1. disable" >> ${XIAOYA_HOME}/emby_config.txt \
    && echo "2. bridge" >> ${XIAOYA_HOME}/emby_config.txt \
    && echo "3. ${EMBY_IMAGE}" >> ${XIAOYA_HOME}/emby_config.txt \
    && echo "4. ${EMBY_VERSION}" >> ${XIAOYA_HOME}/emby_config.txt \
    && echo "5. ${MEDIA_DIR}" >> ${XIAOYA_HOME}/emby_config.txt

# 第六步：非交互式执行小雅安装脚本，先安装Alist核心组件（1 1 / 3 1 / 4 1）
# 用EOF传入交互指令，替代手动输入，适配GitHub自动构建（无人工干预）
RUN bash ${XIAOYA_HOME}/xiaoya_install.sh << EOF
1
1
3
1
4
1
EOF

# 第七步：非交互式安装Emby全家桶与定时爬虫（2 1 / 2 5 1）
# 读取预配置的emby_config.txt，自动完成Emby部署，无需手动操作
RUN bash ${XIAOYA_HOME}/xiaoya_install.sh << EOF
2
1
2
5
1
EOF

# 第八步：暴露核心端口（Zeabur会自动识别，用于公网访问映射）
# Alist核心访问端口（必暴露）
EXPOSE 5678
# Emby核心访问端口（必暴露）
EXPOSE 8096
# 备用终端端口（可选）
EXPOSE 22
# 备用HTTPS端口（可选）
EXPOSE 443

# 第九步：启动命令（保持容器运行，启动小雅所有服务+定时爬虫cron）
# 确保容器不退出，同时加载小雅全部服务与定时任务
# 修正：使用shell解析环境变量，将${XIAOYA_HOME}替换为\$XIAOYA_HOME（或直接使用完整路径）
CMD ["bash", "-c", "cd $XIAOYA_HOME && ./start_all.sh && cron -f"]
