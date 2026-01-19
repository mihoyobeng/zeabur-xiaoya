FROM ubuntu:22.04
LABEL maintainer="xiaoya-emby-zeabur"

# 核心环境变量（精简无冗余）
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV XIAOYA_HOME=/opt/xiaoya
ENV MEDIA_DIR=/opt/xiaoya/media
ENV EMBY_VERSION=4.9.0.42
ENV EMBY_IMAGE=amilys/embyserver
ENV CRON_ENABLE=yes

# 安装核心依赖，无任何多余包，Zeabur构建最快
RUN apt update && apt install -yq curl wget sudo docker.io cron ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 预创建所有必要目录+合理权限，规避脚本校验
RUN mkdir -p ${XIAOYA_HOME}/{alist,data,scripts,docker,conf} ${MEDIA_DIR} \
    && chmod -R 775 ${XIAOYA_HOME} ${MEDIA_DIR}

# Zeabur网络专属：国内分流脚本地址，永不阻断，无exit22
RUN curl -fsSL https://ddsrem.com/xiaoya_install.sh -o ${XIAOYA_HOME}/xiaoya_install.sh \
    && chmod +x ${XIAOYA_HOME}/xiaoya_install.sh

# Emby预配置，完全不变
RUN echo -e "# Emby Config for Zeabur\n1. disable\n2. bridge\n3. ${EMBY_IMAGE}\n4. ${EMBY_VERSION}\n5. ${MEDIA_DIR}" > ${XIAOYA_HOME}/emby_config.txt

# 核心：上级目录执行脚本，解决目录合法性校验
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

# 只暴露必要端口，减少冗余
EXPOSE 5678 8096

WORKDIR ${XIAOYA_HOME}

# 启动命令：日志静默+更长延时适配Zeabur，避免dockerd启动不及时
CMD ["/bin/bash", "-e", "-c", "dockerd > /dev/null 2>&1 & sleep 6 && ./start_all.sh && cron -f"]
