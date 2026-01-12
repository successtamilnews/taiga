<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use App\Services\AnalyticsService;

class AnalyticsMiddleware
{
    protected $analyticsService;

    public function __construct(AnalyticsService $analyticsService)
    {
        $this->analyticsService = $analyticsService;
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

        // Record analytics event
        $this->analyticsService->recordEvent(
            auth()->id() ?? 0,
            $this->getEventType($request),
            [
                'method' => $request->method(),
                'path' => $request->path(),
                'response_time' => $responseTime,
                'status_code' => $response->getStatusCode(),
                'user_agent' => $request->userAgent(),
                'ip_address' => $request->ip(),
                'referer' => $request->header('referer'),
            ],
            $this->getUserType($request)
        );

        return $response;
    }

    protected function getEventType(Request $request): string
    {
        $method = strtolower($request->method());
        $path = $request->path();

        if (str_contains($path, 'api/')) {
            return 'api_request';
        }

        if ($method === 'get') {
            return 'page_view';
        }

        return 'user_action';
    }

    protected function getUserType(Request $request): string
    {
        if (!auth()->check()) {
            return 'anonymous';
        }

        return auth()->user()->user_type ?? 'customer';
    }
}