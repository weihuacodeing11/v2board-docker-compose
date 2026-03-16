<?php

namespace App\Http\Middleware;

use App\Services\AuthService;
use Closure;
use Illuminate\Support\Facades\Cache;

class Admin
{
    /**
     * Handle an incoming request.
     *
     * @param \Illuminate\Http\Request $request
     * @param \Closure $next
     * @return mixed
     */
    public function handle($request, Closure $next)
    {
        // TEMPORARY: Bypass authentication for development
        $request->merge([
            'user' => [
                'id' => 1,
                'email' => 'admin@v2board.com',
                'is_admin' => true,
                'is_staff' => false
            ]
        ]);
        return $next($request);
    }
}
