<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Ratchet\Server\IoServer;
use Ratchet\Http\HttpServer;
use Ratchet\WebSocket\WsServer;
use App\Services\WebSocketService;
use App\Services\LoggingService;

class WebSocketServerCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'websocket:serve 
                            {--host=127.0.0.1 : The host to bind to}
                            {--port=8080 : The port to bind to}
                            {--daemon : Run as daemon}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Start the WebSocket server for real-time communication';

    protected $loggingService;

    public function __construct(LoggingService $loggingService)
    {
        parent::__construct();
        $this->loggingService = $loggingService;
    }

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $host = $this->option('host');
        $port = $this->option('port');
        $daemon = $this->option('daemon');

        $this->info("Starting WebSocket server...");
        $this->info("Host: {$host}");
        $this->info("Port: {$port}");

        try {
            // Create WebSocket application
            $webSocketApp = new WebSocketService();

            // Create server stack
            $webSocketServer = new WsServer($webSocketApp);
            $httpServer = new HttpServer($webSocketServer);
            $server = IoServer::factory($httpServer, $port, $host);

            // Log server start
            $this->loggingService->logWebSocket("WebSocket server started", [
                'host' => $host,
                'port' => $port,
                'pid' => getmypid(),
                'daemon' => $daemon,
            ]);

            $this->info("WebSocket server listening on {$host}:{$port}");
            
            if ($daemon) {
                $this->info("Running as daemon...");
                // In production, you would use a proper daemon process manager
                // like Supervisor or systemd
            }

            // Run the server
            $server->run();

        } catch (\Exception $e) {
            $this->error("Failed to start WebSocket server: " . $e->getMessage());
            $this->loggingService->logError($e, [
                'context' => 'WebSocket server startup',
                'host' => $host,
                'port' => $port,
            ]);
            
            return 1;
        }
    }
}