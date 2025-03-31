#!/bin/bash
docker compose down           # 停止并删除旧容器
docker compose up -d --build  # 自动执行以下操作：
                              # 1. 如果镜像不存在 → 根据 docker-compose.yml 中的 build 配置构建镜像
                              # 2. 挂载文件卷
                              # 3. 以守护进程模式启动容器
