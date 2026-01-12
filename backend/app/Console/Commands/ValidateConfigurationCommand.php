<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\DB;
use App\Services\AnalyticsService;
use App\Services\BroadcastService;
use App\Services\LoggingService;
use App\Services\WebSocketService;

class ValidateConfigurationCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'config:validate {--fix : Attempt to fix configuration issues}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Validate the configuration for enhanced backend services';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('🔍 Validating Taiga Enhanced Backend Configuration...');
        $this->newLine();

        $issues = [];
        $warnings = [];

        // Test database connection
        $this->info('📊 Testing Database Connection...');
        if ($this->testDatabaseConnection()) {
            $this->line('  ✅ Database connection successful');
        } else {
            $issues[] = 'Database connection failed';
            $this->line('  ❌ Database connection failed');
        }

        // Test Redis connection
        $this->info('📡 Testing Redis Connection...');
        if ($this->testRedisConnection()) {
            $this->line('  ✅ Redis connection successful');
        } else {
            $issues[] = 'Redis connection failed';
            $this->line('  ❌ Redis connection failed');
        }

        // Test WebSocket configuration
        $this->info('🌐 Testing WebSocket Configuration...');
        $websocketIssues = $this->testWebSocketConfiguration();
        if (empty($websocketIssues)) {
            $this->line('  ✅ WebSocket configuration valid');
        } else {
            $issues = array_merge($issues, $websocketIssues);
            foreach ($websocketIssues as $issue) {
                $this->line("  ❌ {$issue}");
            }
        }

        // Test Analytics configuration
        $this->info('📈 Testing Analytics Configuration...');
        $analyticsIssues = $this->testAnalyticsConfiguration();
        if (empty($analyticsIssues)) {
            $this->line('  ✅ Analytics configuration valid');
        } else {
            $warnings = array_merge($warnings, $analyticsIssues);
            foreach ($analyticsIssues as $issue) {
                $this->line("  ⚠️  {$issue}");
            }
        }

        // Test Logging configuration
        $this->info('📝 Testing Logging Configuration...');
        $loggingIssues = $this->testLoggingConfiguration();
        if (empty($loggingIssues)) {
            $this->line('  ✅ Logging configuration valid');
        } else {
            $warnings = array_merge($warnings, $loggingIssues);
            foreach ($loggingIssues as $issue) {
                $this->line("  ⚠️  {$issue}");
            }
        }

        // Test Queue configuration
        $this->info('⚡ Testing Queue Configuration...');
        if ($this->testQueueConfiguration()) {
            $this->line('  ✅ Queue configuration valid');
        } else {
            $warnings[] = 'Queue configuration has potential issues';
            $this->line('  ⚠️  Queue configuration has potential issues');
        }

        // Test Services instantiation
        $this->info('🔧 Testing Service Instantiation...');
        $serviceIssues = $this->testServices();
        if (empty($serviceIssues)) {
            $this->line('  ✅ All services can be instantiated');
        } else {
            $issues = array_merge($issues, $serviceIssues);
            foreach ($serviceIssues as $issue) {
                $this->line("  ❌ {$issue}");
            }
        }

        // Test File Permissions
        $this->info('📁 Testing File Permissions...');
        $permissionIssues = $this->testFilePermissions();
        if (empty($permissionIssues)) {
            $this->line('  ✅ File permissions are correct');
        } else {
            $warnings = array_merge($warnings, $permissionIssues);
            foreach ($permissionIssues as $issue) {
                $this->line("  ⚠️  {$issue}");
            }
        }

        $this->newLine();

        // Summary
        if (empty($issues) && empty($warnings)) {
            $this->info('🎉 Configuration validation completed successfully!');
            $this->line('All systems are ready for enhanced backend services.');
            return 0;
        } else {
            if (!empty($issues)) {
                $this->error('❌ Critical Issues Found:');
                foreach ($issues as $issue) {
                    $this->line("  • {$issue}");
                }
                $this->newLine();
            }

            if (!empty($warnings)) {
                $this->warn('⚠️  Warnings:');
                foreach ($warnings as $warning) {
                    $this->line("  • {$warning}");
                }
                $this->newLine();
            }

            if ($this->option('fix')) {
                $this->info('🔧 Attempting to fix issues...');
                $this->attemptFixes($issues, $warnings);
            } else {
                $this->line('Run with --fix flag to attempt automatic fixes.');
            }

            return empty($issues) ? 0 : 1;
        }
    }

    protected function testDatabaseConnection(): bool
    {
        try {
            DB::connection()->getPdo();
            return true;
        } catch (\Exception $e) {
            return false;
        }
    }

    protected function testRedisConnection(): bool
    {
        try {
            Redis::ping();
            return true;
        } catch (\Exception $e) {
            return false;
        }
    }

    protected function testWebSocketConfiguration(): array
    {
        $issues = [];

        if (!Config::get('websocket.server.host')) {
            $issues[] = 'WebSocket host not configured';
        }

        if (!Config::get('websocket.server.port')) {
            $issues[] = 'WebSocket port not configured';
        }

        if (!Config::get('websocket.auth.jwt_secret')) {
            $issues[] = 'WebSocket JWT secret not configured';
        }

        return $issues;
    }

    protected function testAnalyticsConfiguration(): array
    {
        $issues = [];

        if (!Config::get('analytics.enabled')) {
            $issues[] = 'Analytics is disabled';
        }

        if (!Config::get('analytics.real_time.enabled')) {
            $issues[] = 'Real-time analytics is disabled';
        }

        return $issues;
    }

    protected function testLoggingConfiguration(): array
    {
        $issues = [];

        if (!Config::get('logging.real_time_enabled')) {
            $issues[] = 'Real-time logging is disabled';
        }

        if (!is_writable(storage_path('logs'))) {
            $issues[] = 'Logs directory is not writable';
        }

        return $issues;
    }

    protected function testQueueConfiguration(): bool
    {
        try {
            $connection = Config::get('queue.default');
            return !empty($connection);
        } catch (\Exception $e) {
            return false;
        }
    }

    protected function testServices(): array
    {
        $issues = [];

        try {
            app(AnalyticsService::class);
        } catch (\Exception $e) {
            $issues[] = "AnalyticsService instantiation failed: {$e->getMessage()}";
        }

        try {
            app(BroadcastService::class);
        } catch (\Exception $e) {
            $issues[] = "BroadcastService instantiation failed: {$e->getMessage()}";
        }

        try {
            app(LoggingService::class);
        } catch (\Exception $e) {
            $issues[] = "LoggingService instantiation failed: {$e->getMessage()}";
        }

        return $issues;
    }

    protected function testFilePermissions(): array
    {
        $issues = [];

        $directories = [
            storage_path('logs'),
            storage_path('app'),
            storage_path('framework/cache'),
            storage_path('framework/sessions'),
            storage_path('framework/views'),
        ];

        foreach ($directories as $dir) {
            if (!is_writable($dir)) {
                $issues[] = "Directory not writable: {$dir}";
            }
        }

        return $issues;
    }

    protected function attemptFixes(array $issues, array $warnings): void
    {
        $this->line('Automatic fixes are not implemented yet.');
        $this->line('Please review the issues manually and update configuration accordingly.');
    }
}