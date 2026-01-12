<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use App\Services\LoggingService;

class LoggingMiddleware
{
    protected $loggingService;

    public function __construct(LoggingService $loggingService)
    {
        $this->loggingService = $loggingService;
    }

    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $startTime = microtime(true);
        
        $response = $next($request);
        
        $endTime = microtime(true);
        $responseTime = ($endTime - $startTime) * 1000; // Convert to milliseconds

        // Log API request
        $this->loggingService->logApi(
            $request->method(),
            $request->path(),
            $responseTime,
            $response->getStatusCode(),
            [
                'request_id' => $request->header('X-Request-ID', uniqid()),
                'user_id' => auth()->id(),
                'user_type' => auth()->check() ? auth()->user()->user_type : 'anonymous',
                'request_size' => strlen($request->getContent()),
                'response_size' => strlen($response->getContent()),
                'memory_usage' => memory_get_usage(true),
                'query_count' => $this->getQueryCount(),
            ]
        );

        // Log performance metrics if enabled
        if (config('logging.performance_tracking')) {
            $this->loggingService->logPerformance(
                'api_response_time',
                $responseTime,
                [
                    'endpoint' => $request->path(),
                    'method' => $request->method(),
                    'threshold' => 1000, // 1 second
                    'unit' => 'ms',
                ]
            );
        }

        // Log security events if needed
        if ($this->shouldLogSecurityEvent($request, $response)) {
            $this->logSecurityEvent($request, $response);
        }

        return $response;
    }

    protected function getQueryCount(): int
    {
        return count(\DB::getQueryLog());
    }

    protected function shouldLogSecurityEvent(Request $request, Response $response): bool
    {
        // Log failed authentication attempts
        if ($response->getStatusCode() === 401) {
            return true;
        }

        // Log permission denied
        if ($response->getStatusCode() === 403) {
            return true;
        }

        // Log suspicious activity (too many requests from same IP)
        if ($this->isSuspiciousActivity($request)) {
            return true;
        }

        return false;
    }

    protected function logSecurityEvent(Request $request, Response $response): void
    {
        $eventType = match($response->getStatusCode()) {
            401 => 'authentication_failed',
            403 => 'authorization_failed',
            default => 'suspicious_activity'
        };

        $this->loggingService->logSecurity($eventType, [
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
            'endpoint' => $request->path(),
            'method' => $request->method(),
            'status_code' => $response->getStatusCode(),
            'attempted_user_id' => $request->input('email') ?? $request->input('username'),
        ]);
    }

    protected function isSuspiciousActivity(Request $request): bool
    {
        // Simple rate limiting check - in production, use proper rate limiting
        $ipAddress = $request->ip();
        $cacheKey = "rate_limit:{$ipAddress}";
        
        $requestCount = cache()->get($cacheKey, 0);
        
        if ($requestCount > 100) { // More than 100 requests per minute
            return true;
        }
        
        cache()->put($cacheKey, $requestCount + 1, 60); // 1 minute
        
        return false;
    }
}