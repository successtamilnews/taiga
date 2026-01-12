#!/bin/bash

# Taiga WebSocket Server Startup Script
# This script starts the WebSocket server and manages its lifecycle

set -e

# Configuration
WEBSOCKET_HOST=${WEBSOCKET_HOST:-127.0.0.1}
WEBSOCKET_PORT=${WEBSOCKET_PORT:-8080}
PID_FILE="/var/run/taiga-websocket.pid"
LOG_FILE="/var/log/taiga-websocket.log"
APP_PATH="/path/to/taiga/backend"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

check_requirements() {
    log "Checking requirements..."
    
    # Check if PHP is installed
    if ! command -v php &> /dev/null; then
        error "PHP is not installed or not in PATH"
    fi
    
    # Check if Laravel artisan exists
    if [ ! -f "$APP_PATH/artisan" ]; then
        error "Laravel artisan not found at $APP_PATH/artisan"
    fi
    
    # Check if Redis is running
    if ! redis-cli ping &> /dev/null; then
        error "Redis server is not running"
    fi
    
    log "All requirements satisfied"
}

start_websocket() {
    log "Starting WebSocket server..."
    
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        warn "WebSocket server is already running (PID: $(cat $PID_FILE))"
        return 1
    fi
    
    cd "$APP_PATH"
    
    # Start the WebSocket server in background
    nohup php artisan websocket:serve \
        --host="$WEBSOCKET_HOST" \
        --port="$WEBSOCKET_PORT" \
        --daemon \
        > "$LOG_FILE" 2>&1 &
    
    echo $! > "$PID_FILE"
    
    # Wait a moment and check if process started successfully
    sleep 2
    if kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        log "WebSocket server started successfully on $WEBSOCKET_HOST:$WEBSOCKET_PORT (PID: $(cat $PID_FILE))"
        return 0
    else
        error "Failed to start WebSocket server"
    fi
}

stop_websocket() {
    log "Stopping WebSocket server..."
    
    if [ ! -f "$PID_FILE" ]; then
        warn "PID file not found. WebSocket server may not be running."
        return 1
    fi
    
    PID=$(cat "$PID_FILE")
    
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        
        # Wait for graceful shutdown
        for i in {1..30}; do
            if ! kill -0 "$PID" 2>/dev/null; then
                break
            fi
            sleep 1
        done
        
        # Force kill if still running
        if kill -0 "$PID" 2>/dev/null; then
            warn "Graceful shutdown failed, force killing process..."
            kill -9 "$PID"
        fi
        
        rm -f "$PID_FILE"
        log "WebSocket server stopped successfully"
    else
        warn "Process not found (PID: $PID)"
        rm -f "$PID_FILE"
    fi
}

restart_websocket() {
    log "Restarting WebSocket server..."
    stop_websocket
    sleep 2
    start_websocket
}

status_websocket() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        log "WebSocket server is running (PID: $(cat $PID_FILE))"
        
        # Check if port is accessible
        if nc -z "$WEBSOCKET_HOST" "$WEBSOCKET_PORT" 2>/dev/null; then
            log "Port $WEBSOCKET_PORT is accessible"
        else
            warn "Port $WEBSOCKET_PORT is not accessible"
        fi
        
        return 0
    else
        warn "WebSocket server is not running"
        return 1
    fi
}

show_logs() {
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE"
    else
        warn "Log file not found at $LOG_FILE"
    fi
}

# Main script logic
case "${1:-}" in
    start)
        check_requirements
        start_websocket
        ;;
    stop)
        stop_websocket
        ;;
    restart)
        check_requirements
        restart_websocket
        ;;
    status)
        status_websocket
        ;;
    logs)
        show_logs
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the WebSocket server"
        echo "  stop    - Stop the WebSocket server"
        echo "  restart - Restart the WebSocket server"
        echo "  status  - Check WebSocket server status"
        echo "  logs    - Show WebSocket server logs"
        echo ""
        echo "Configuration:"
        echo "  WEBSOCKET_HOST: $WEBSOCKET_HOST"
        echo "  WEBSOCKET_PORT: $WEBSOCKET_PORT"
        echo "  PID_FILE: $PID_FILE"
        echo "  LOG_FILE: $LOG_FILE"
        echo "  APP_PATH: $APP_PATH"
        exit 1
        ;;
esac