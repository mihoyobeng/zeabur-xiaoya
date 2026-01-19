FROM ubuntu:22.04

# ✅ 核心修改 1：【致命修复】将目录改为脚本白名单合法目录 /xiaoya （唯一根治方案）
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV XIAOYA_HOME=/xiaoya          # 从 /opt/xiaoya → 改为 /xiaoya （必改）
ENV MEDIA_DIR=/xiaoya/media      # 同步修改媒体库路径（必改）
ENV EMBY_VERSION=4.9.0.42
ENV EMBY_IMAGE=amilys/embyserver
ENV CRON_ENABLE=yes

# 第一步：安装依赖+时区配置，完全不变
RUN apt update && apt install -yq \
    curl \
    wget \
    sudo \
    docker.io \
    cron \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# ✅ 核心修改 2：同步创建合法目录 /xiaoya 及其子目录，权限配置不变
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && mkdir -p ${XIAOYA_HOME}/{alist,data,scripts,docker} ${MEDIA_DIR} \
    && chmod -R 775 ${XIAOYA_HOME} ${MEDIA_DIR} \
    && chown -R root:root ${XIAOYA_HOME} ${MEDIA_DIR}

# ✅ 保留 Zeabur 网络友好的国内脚本地址，无 exit22 报错，完全不变
RUN curl -fsSL https://ddsrem.com/xiaoya_install.sh -o ${XIAOYA_HOME}/xiaoya_install.sh

# 赋予脚本执行权限，完全不变
RUN chmod +x ${XIAOYA_HOME}/xiaoya_install.sh

# Emby预配置文件，完全不变（写法正确，无需修改）
RUN echo "# Emby Config for Zeabur Auto Build" > ${XIAOYA_HOME}/emby_config.txt \
    && echo "1. disable" >> ${XIAOYA_HOME}/emby_config.txt \
    && echo "2. bridge" >> ${XIAOYA_HOME}/emby_config.txt \
    && echo "3. ${EMBY_IMAGE}" >> ${XIAOYA_HOME}/emby_config.txt \
    && echo "4. ${EMBY_VERSION}" >> ${XIAOYA_HOME}/emby_config.txt \
    && echo "5. ${MEDIA_DIR}" >> ${XIAOYA_HOME}/emby_config.txt

# ✅ 核心修改 3：执行脚本时 cd 到【根目录 /】（因为小雅目录是 /xiaoya，上级目录就是根目录）
RUN cd / && bash ${XIAOYA_HOME}/xiaoya_install.sh << EOF
1
1
3
1
4
1
EOF

# ✅ 同样修改：cd 到根目录执行脚本安装Emby+爬虫
RUN cd / && bash ${XIAOYA_HOME}/xiaoya_install.sh << EOF
2
1
2
5
1
EOF

# 暴露端口，完全不变
EXPOSE 5678 8096 22 443

# ✅ 同步固化合法工作目录
WORKDIR ${XIAOYA_HOME}

# 启动命令，完全不变（完美兼容新目录）
CMD ["/bin/bash", "-e", "-c", "dockerd > /var/log/dockerd.log 2>&1 & sleep 5 && ./start_all.sh && cron -f"]
