<!DOCTYPE html>
<html>

<head>
    <link rel="stylesheet" href="/assets/admin/components.chunk.css?v={{$version}}">
    <link rel="stylesheet" href="/assets/admin/umi.css?v={{$version}}">
    <link rel="stylesheet" href="/assets/admin/custom.css?v={{$version}}">
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,minimum-scale=1,user-scalable=no">
    <title>{{$title}}</title>
    <!-- <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Nunito+Sans:300,400,400i,600,700"> -->
    <script>
        // Set fake token immediately to bypass frontend auth check
        localStorage.setItem('authorization', 'bypass_token_for_development');

        // BRUTAL FIX: Block all redirects and reloads
        window.addEventListener('beforeunload', function(e) {
            e.preventDefault();
            e.returnValue = '';
            return '';
        });

        // Override location methods to prevent redirects
        var originalReplace = window.location.replace;
        var originalAssign = window.location.assign;
        var originalReload = window.location.reload;

        window.location.replace = function(url) {
            if (url && url.includes('login')) {
                console.log('Blocked redirect to login:', url);
                return;
            }
            return originalReplace.call(window.location, url);
        };

        window.location.assign = function(url) {
            if (url && url.includes('login')) {
                console.log('Blocked redirect to login:', url);
                return;
            }
            return originalAssign.call(window.location, url);
        };

        window.location.reload = function() {
            console.log('Blocked page reload');
            return;
        };

        // Override history methods
        var originalPushState = history.pushState;
        var originalReplaceState = history.replaceState;

        history.pushState = function(state, title, url) {
            if (url && url.includes('login')) {
                console.log('Blocked history push to login:', url);
                return;
            }
            return originalPushState.apply(history, arguments);
        };

        history.replaceState = function(state, title, url) {
            if (url && url.includes('login')) {
                console.log('Blocked history replace to login:', url);
                return;
            }
            return originalReplaceState.apply(history, arguments);
        };
    </script>
    <script>window.routerBase = "/";</script>
    <script>
        window.settings = {
            title: '{{$title}}',
            theme: {
                sidebar: '{{$theme_sidebar}}',
                header: '{{$theme_header}}',
                color: '{{$theme_color}}',
            },
            version: '{{$version}}',
            background_url: '{{$background_url}}',
            logo: '{{$logo}}',
            secure_path: '{{$secure_path}}'
        }
    </script>
    <script>
        // Force save auth_data to localStorage after login
        (function() {
            const originalFetch = window.fetch;
            window.fetch = function(...args) {
                return originalFetch.apply(this, args).then(response => {
                    const clonedResponse = response.clone();
                    if (args[0] && args[0].includes('/passport/auth/login')) {
                        clonedResponse.json().then(data => {
                            if (data && data.data && data.data.auth_data) {
                                localStorage.setItem('authorization', data.data.auth_data);
                            }
                        }).catch(() => {});
                    }
                    return response;
                });
            };

            const originalOpen = XMLHttpRequest.prototype.open;
            const originalSend = XMLHttpRequest.prototype.send;
            XMLHttpRequest.prototype.open = function(method, url, ...rest) {
                this._url = url;
                return originalOpen.apply(this, [method, url, ...rest]);
            };
            XMLHttpRequest.prototype.send = function(...args) {
                this.addEventListener('load', function() {
                    if (this._url && this._url.includes('/passport/auth/login') && this.status === 200) {
                        try {
                            const data = JSON.parse(this.responseText);
                            if (data && data.data && data.data.auth_data) {
                                localStorage.setItem('authorization', data.data.auth_data);
                            }
                        } catch (e) {}
                    }
                });
                return originalSend.apply(this, args);
            };
        })();
    </script>
</head>

<body>
<div id="root"></div>
<script src="/assets/admin/vendors.async.js?v={{$version}}"></script>
<script src="/assets/admin/components.async.js?v={{$version}}"></script>
<script src="/assets/admin/umi.js?v={{$version}}"></script>
</body>

</html>
