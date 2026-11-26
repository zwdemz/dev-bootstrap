#!/bin/bash
# ============================================================
# dev-bootstrap - Database clients module
# ============================================================
# 只安装客户端，不启动服务端，避免和已有数据库冲突。
# 需要服务端时建议用 Docker：
#   docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=... -p 3306:3306 mysql:8
#   docker run -d --name postgres -e POSTGRES_PASSWORD=... -p 5432:5432 postgres:16
#   docker run -d --name redis -p 6379:6379 redis:7

install_db() {
  section "Database Clients"

  apt_update
  run_sudo apt install -y default-mysql-client postgresql-client redis-tools sqlite3 2>&1 | tail -1

  done_section "Database Clients"
  echo "  mysql:  $(mysql --version 2>/dev/null | head -1 || echo 'N/A')"
  echo "  psql:   $(psql --version 2>/dev/null || echo 'N/A')"
  echo "  redis:  $(redis-cli --version 2>/dev/null || echo 'N/A')"
  echo "  sqlite: $(sqlite3 --version 2>/dev/null | head -1 || echo 'N/A')"
}
