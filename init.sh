#!/bin/bash
if [ -d "/home/frappe/frappe-bench/apps/builder" ]; then
    echo "Existing bench found. Upgrading configuration and starting..."
    cd frappe-bench
    
    # Ensure the host binds globally on container redeploys
    bench set-config -g host 0.0.0.0
    bench config default-site builder.localhost
    
    bench start
else
    echo "First time setup: Initializing Frappe Bench..."
    bench init --skip-redis-config-generation frappe-bench --version develop
    cd frappe-bench
    
    # Force the Frappe webserver to listen to external Docker network traffic
    bench set-config -g host 0.0.0.0
    
    bench set-mariadb-host mariadb
    bench set-redis-cache-host redis:6379
    bench set-redis-queue-host redis:6379
    bench set-redis-socketio-host redis:6379
    
    # Strip background execution conflicts
    sed -i '/redis/d' ./Procfile
    sed -i '/watch/d' ./Procfile
    
    # Install Builder App
    bench get-app builder
    bench new-site builder.localhost --install-app builder --db-root-password 123 --admin-password admin
    bench --site builder.localhost set-config ignore_csrf 1
    
    # Tell Frappe to serve this site for ANY domain mapped in Dokploy
    bench config default-site builder.localhost
    
    bench start
fi
