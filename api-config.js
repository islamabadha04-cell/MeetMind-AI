/**
 * ==============================================================================
 * MeetMind AI — Central API Configuration & Staging Gateway
 * ==============================================================================
 * Manages environment-aware API resolution, remote staging endpoints,
 * authentication token injection, request timeouts, and health indicators.
 */

(function(window) {
  'use strict';

  // Environment Detection
  const hostname = window.location.hostname;
  const isLocalhost = hostname === 'localhost' || 
                      hostname === '127.0.0.1' || 
                      hostname.startsWith('192.168.') ||
                      hostname === '';

  const isPreview = hostname.includes('preview-v4') || 
                    hostname.includes('--') ||
                    window.location.search.includes('env=staging');

  const isProduction = hostname === 'meetmind-ai-74519.web.app' || 
                       hostname === 'meetmind-ai-74519.firebaseapp.com';

  // Configured Endpoints
  const DEFAULT_LOCAL_URL = 'http://localhost:8000/api/v1';
  const DEFAULT_STAGING_URL = 'https://supports-incidents-jail-admissions.trycloudflare.com/api/v1';
  const DEFAULT_PRODUCTION_URL = 'https://api.meetmind.ai/api/v1';

  // Resolved Backend Base URL
  function resolveApiBaseUrl() {
    // 1. Explicit window override (e.g. injected via script or test harness)
    if (window.MEETMIND_BACKEND_URL && typeof window.MEETMIND_BACKEND_URL === 'string') {
      return window.MEETMIND_BACKEND_URL.replace(/\/+$/, '');
    }

    // 2. User/developer manual override stored in localStorage
    try {
      const stored = localStorage.getItem('meetmind_custom_backend_url');
      if (stored) return stored.replace(/\/+$/, '');
    } catch (e) {}

    // 3. Localhost development environment
    if (isLocalhost) {
      return DEFAULT_LOCAL_URL;
    }

    // 4. Firebase Hosting Preview Channel
    if (isPreview) {
      return (window.MEETMIND_STAGING_BACKEND_URL || DEFAULT_STAGING_URL).replace(/\/+$/, '');
    }

    // 5. Production Environment (Untouched & Protected)
    if (isProduction) {
      return (window.MEETMIND_PRODUCTION_BACKEND_URL || DEFAULT_PRODUCTION_URL).replace(/\/+$/, '');
    }

    // 6. Fail-safe default for remote environments
    return (window.MEETMIND_STAGING_BACKEND_URL || DEFAULT_STAGING_URL).replace(/\/+$/, '');
  }

  const MeetMindAPI = {
    version: '4.0.1',
    environment: isLocalhost ? 'development' : (isPreview ? 'staging' : (isProduction ? 'production' : 'preview')),
    isLocalhost,
    isPreview,
    isProduction,

    getBackendUrl: resolveApiBaseUrl,

    /**
     * Central API Fetch with timeout, token injection, and structured error handling.
     * @param {string} endpoint - Relative path (e.g. '/integrations' or '/meetings') or full URL.
     * @param {object} options - Standard fetch options plus timeoutMs.
     */
    fetch: async function(endpoint, options = {}) {
      const baseUrl = resolveApiBaseUrl();
      
      // Safety validation: prevent remote preview from silently calling localhost
      if (!isLocalhost && baseUrl.includes('localhost')) {
        console.error('❌ Configuration Error: Hosted preview cannot connect to localhost backend.');
        MeetMindAPI.notifyHealth('error', 'Misconfigured backend URL (points to localhost on remote host)');
        throw new Error('Remote backend configuration error: Cannot target localhost from hosted preview.');
      }

      // Build target URL
      let targetUrl = endpoint;
      if (!endpoint.startsWith('http://') && !endpoint.startsWith('https://')) {
        const cleanPath = endpoint.startsWith('/') ? endpoint : '/' + endpoint;
        // Normalize if endpoint already includes /api/v1
        if (cleanPath.startsWith('/api/v1/')) {
          const subPath = cleanPath.substring('/api/v1'.length);
          targetUrl = baseUrl + subPath;
        } else {
          targetUrl = baseUrl + cleanPath;
        }
      }

      // Prepare headers
      const headers = Object.assign({}, options.headers || {});
      
      // Inject Authorization token if not already present
      if (!headers['Authorization'] && !headers['authorization']) {
        try {
          const token = localStorage.getItem('meetmind_token');
          if (token) {
            headers['Authorization'] = 'Bearer ' + token;
          } else if (window.MeetMindFirebase && window.MeetMindFirebase.currentUser) {
            // Attempt retrieving Firebase ID Token
            const fbUser = window.MeetMindFirebase.currentUser;
            if (fbUser.getIdToken) {
              const idToken = await fbUser.getIdToken();
              if (idToken) headers['Authorization'] = 'Bearer ' + idToken;
            }
          }
        } catch (e) {}
      }

      // Setup AbortController for request timeout (default 35s, 60s for large uploads)
      const timeoutMs = options.timeoutMs || (options.body instanceof FormData ? 60000 : 35000);
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

      const fetchOptions = Object.assign({}, options, {
        headers,
        signal: controller.signal
      });

      try {
        const response = await fetch(targetUrl, fetchOptions);
        clearTimeout(timeoutId);

        // Update health status
        if (response.ok) {
          MeetMindAPI.notifyHealth('online', 'Connected to Staging Backend');
        } else if (response.status >= 500) {
          MeetMindAPI.notifyHealth('degraded', `Backend returned HTTP ${response.status}`);
        }

        return response;
      } catch (err) {
        clearTimeout(timeoutId);
        const isTimeout = err.name === 'AbortError';
        const errorMsg = isTimeout ? `Request timed out after ${timeoutMs / 1000}s` : (err.message || 'Network connection failed');
        
        console.warn(`[MeetMindAPI] Network failure calling ${targetUrl}: ${errorMsg}`);
        MeetMindAPI.notifyHealth('offline', errorMsg);
        
        throw new Error(errorMsg);
      }
    },

    /**
     * Checks backend health and updates UI indicator
     */
    checkHealth: async function() {
      const baseUrl = resolveApiBaseUrl();
      const healthUrl = baseUrl.replace(/\/api\/v1\/?$/, '') + '/health';
      try {
        const controller = new AbortController();
        const tid = setTimeout(() => controller.abort(), 6000);
        const res = await fetch(healthUrl, { signal: controller.signal });
        clearTimeout(tid);
        if (res.ok) {
          const data = await res.json();
          MeetMindAPI.notifyHealth('online', `Remote Cloud API v${data.version || '4.0.1'} (${data.environment || 'staging'})`);
          return { online: true, data };
        } else {
          MeetMindAPI.notifyHealth('degraded', `HTTP ${res.status}`);
          return { online: false, status: res.status };
        }
      } catch (e) {
        MeetMindAPI.notifyHealth('offline', 'Unreachable');
        return { online: false, error: e.message };
      }
    },

    notifyHealth: function(status, detail) {
      window.dispatchEvent(new CustomEvent('meetmind:api-health', {
        detail: { status, detail, timestamp: Date.now() }
      }));

      // Update DOM indicator if available
      const badge = document.getElementById('backendHealthBadge');
      const text = document.getElementById('backendHealthText');
      if (badge && text) {
        badge.className = 'backend-health-pill health-' + status;
        text.textContent = status === 'online' ? (detail || 'Staging Online') : (status === 'offline' ? 'Backend Offline' : 'Degraded');
      }
    }
  };

  // Expose globally
  window.MeetMindAPI = MeetMindAPI;

  // Run initial health check on DOM load
  if (typeof document !== 'undefined') {
    document.addEventListener('DOMContentLoaded', () => {
      setTimeout(() => MeetMindAPI.checkHealth(), 800);
    });
  }

})(typeof window !== 'undefined' ? window : this);
