#!/bin/bash
set -e

# GoTrack Docker Compose Management Script

COMPOSE_FILE="docker-compose.yml"

case "${1:-help}" in
    up)
        echo "🚀 Starting GoTrack stack (Kafka + PostgreSQL + GoTrack)..."
        docker-compose -f $COMPOSE_FILE up -d
        echo "✅ Stack started!"
        echo ""
        echo "Services:"
        echo "  - GoTrack:    http://localhost:19890"
        echo "  - PostgreSQL: localhost:5432 (analytics/analytics)"
        echo "  - Kafka:      localhost:9092"
        echo ""
        echo "Logs: docker-compose logs -f gotrack"
        echo "Stop: ./deploy/manage.sh down"
        ;;
    
    down)
        echo "🛑 Stopping GoTrack stack..."
        docker-compose -f $COMPOSE_FILE down
        echo "✅ Stack stopped!"
        ;;
    
    logs)
        service="${2:-gotrack}"
        echo "📋 Following logs for $service..."
        docker-compose -f $COMPOSE_FILE logs -f $service
        ;;
    
    restart)
        echo "🔄 Restarting GoTrack stack..."
        docker-compose -f $COMPOSE_FILE restart
        echo "✅ Stack restarted!"
        ;;
    
    build)
        echo "🔨 Building GoTrack image..."
        docker-compose -f $COMPOSE_FILE build gotrack
        echo "✅ Build complete!"
        ;;
    
    test-pixel)
        echo "🖼️  Testing pixel endpoint..."
        curl -v "http://localhost:19890/px.gif?e=pageview&url=https://example.com/test&ref=https://google.com"
        echo ""
        echo "Check logs with: ./deploy/manage.sh logs"
        ;;
    
    test-json)
        echo "📡 Testing JSON endpoint..."
        curl -X POST http://localhost:19890/collect \
            -H "Content-Type: application/json" \
            -d '{
                "event_id": "test-123",
                "type": "pageview",
                "url": {
                    "referrer": "https://example.com"
                },
                "device": {
                    "browser": "curl",
                    "ua": "curl/test"
                }
            }'
        echo ""
        echo "Check logs with: ./deploy/manage.sh logs"
        ;;
    
    psql)
        echo "🐘 Connecting to PostgreSQL..."
        docker-compose -f $COMPOSE_FILE exec postgres psql -U analytics -d analytics
        ;;
    
    kafka-console)
        echo "📨 Starting Kafka console consumer..."
        docker-compose -f $COMPOSE_FILE exec kafka kafka-console-consumer \
            --bootstrap-server localhost:29092 \
            --topic gotrack.events \
            --from-beginning
        ;;
    
    status)
        echo "📊 Stack status:"
        docker-compose -f $COMPOSE_FILE ps
        ;;
    
    clean)
        echo "🧹 Cleaning up volumes and containers..."
        read -p "This will delete all data. Are you sure? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose -f $COMPOSE_FILE down -v
            docker system prune -f
            echo "✅ Cleanup complete!"
        else
            echo "❌ Cleanup cancelled"
        fi
        ;;
    
    help|*)
        echo "GoTrack Management Script"
        echo ""
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  up           - Start the full stack"
        echo "  down         - Stop the stack"
        echo "  logs [svc]   - Follow logs (default: gotrack)"
        echo "  restart      - Restart all services"
        echo "  build        - Rebuild GoTrack image"
        echo "  test-pixel   - Test pixel tracking endpoint"
        echo "  test-json    - Test JSON API endpoint"
        echo "  psql         - Connect to PostgreSQL"
        echo "  kafka-console - Start Kafka console consumer"
        echo "  status       - Show service status"
        echo "  clean        - Clean up all data (destructive!)"
        echo "  help         - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 up && $0 logs"
        echo "  $0 test-pixel && $0 psql"
        echo "  $0 kafka-console"
        ;;
esac