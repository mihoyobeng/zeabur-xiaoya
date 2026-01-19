FROM ubuntu:22.04
LABEL maintainer="xiaoya-emby-zeabur"

# 核心环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV XIAOYA_HOME=/opt/xiaoya
ENV MEDIA_DIR=/opt/xiaoya/media
ENV EMBY_VERSION=4.9.0.42
ENV EMBY_IMAGE=amilys/embyserver
ENV CRON_ENABLE=yes

# 安装核心依赖，无冗余
RUN apt update && apt install -yq curl wget sudo docker.io cron ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 预创建所有需要的目录+提权，解决脚本目录校验
RUN mkdir -p ${XIAOYA_HOME}/{alist,data,scripts,docker,conf} ${MEDIA_DIR} \
    && chmod -R 775 ${XIAOYA_HOME} ${MEDIA_DIR} \
    && chown -R root:root ${XIAOYA_HOME} ${MEDIA_DIR}

# 拉取官方原版脚本，稳定无阉割
RUN curl -fsSL --retry 3 --connect-timeout 10 https://raw.githubusercontent.com/XiaoyaPro/xiaoya/master/xiaoya_install.sh -o ${XIAOYA_HOME}/xiaoya_install.sh \
    && chmod +x ${XIAOYA_HOME}/xiaoya_install.sh

# 预配置Emby，写法不变
RUN echo "# Emby Config for Zeabur Auto Build" > ${XIAOYA_HOME}/emby_config.txt \
    && echo "1. disable" >> ${XIAOYA_HOME}/emby_config.txt \
    && echo "2. bridge" >> ${XIAOYA_HOME}/emby_config.txt \
    && echo "3. ${EMBY_IMAGE}" >> ${XIAOYA_HOME}/emby_config.txt \
    && echo "4. ${EMBY_VERSION}" >> ${XIAOYA_HOME}/emby_config.txt \
    && echo "5. ${MEDIA_DIR}" >> ${XIAOYA_HOME}/emby_config.txt

# 核心修复：切换到上级目录执行脚本，解决目录合法性校验
RUN cd /opt && bash ${XIAOYA_HOME}/xiaoya_install.sh << EOF
1
1
3
1
4
1
EOF

RUN cd /opt && bash ${XIAOYA_HOME}/xiaoya_install.sh << EOF
2
1
2
5
1
EOF

# 暴露端口
EXPOSE 5678 8096

# 工作目录
WORKDIR ${XIAOYA_HOME}

# 启动命令：dockerd后台启动+延时初始化+小雅服务+前台cron保活
CMD ["/bin/bash", "-e", "-c", "dockerd > /dev/null 2>&1 & sleep 6 && ./start_all.sh && cron -f"]
