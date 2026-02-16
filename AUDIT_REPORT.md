# 🔒 Pre-Hosting Audit Report: Observer (ConsoleShare)

**Date:** 2026-02-16  
**Auditor Role:** Senior DevOps Engineer & Full-Stack Security Auditor  
**Project:** Observer — Real-time Coding Monitor  
**Stack:** React 18 / Vite / Django 5.2 / DRF / Django Channels / PostgreSQL  

---

## Table of Contents

1. [Project Structure & Configuration Audit](#1-project-structure--configuration-audit)
2. [Frontend (React/Vite) Deep Dive](#2-frontend-reactvite-deep-dive)
3. [Backend (Django/DRF/Channels) Deep Dive](#3-backend-djangodrfchannels-deep-dive)
4. [Code Execution Engine — CRITICAL SECURITY AUDIT](#4-code-execution-engine--critical-security-audit)
5. [Final Report & Actionable Checklist](#5-final-report--actionable-checklist)

---

## 1. Project Structure & Configuration Audit

### 1.1 Dependency Analysis

#### Frontend (`frontend/package.json`)

| Dependency | Status | Notes |
|---|---|---|
| `@monaco-editor/react` | ✅ Used | `PersonalConsole.jsx`, `CodingInterface.jsx` |
| `axios` | ✅ Used | `services/api.js` — centralized instance |
| `framer-motion` | ✅ Used | `SessionManager.jsx`, `Student/Dashboard.jsx` |
| `lucide-react` | ✅ Used | `Footer.jsx`, `Student/Dashboard.jsx` |
| `react` / `react-dom` | ✅ Core | |
| `react-router-dom` | ✅ Used | `App.jsx`, multiple components |
| `@types/react` | ⚠️ **Unnecessary** | TypeScript type definitions in a JavaScript project. **Can be removed.** |
| `@types/react-dom` | ⚠️ **Unnecessary** | TypeScript type definitions in a JavaScript project. **Can be removed.** |

**Verdict:** `@types/react` and `@types/react-dom` are dev dependencies for TypeScript type checking. Since this is a pure JavaScript project (no `.ts`/`.tsx` files), they are unnecessary.

#### Backend (`backend/requirements.txt`)

| Dependency | Status | Notes |
|---|---|---|
| `Django`, `djangorestframework`, `djangorestframework_simplejwt` | ✅ Core | |
| `channels`, `daphne` | ✅ Used | WebSocket layer |
| `django-cors-headers` | ✅ Used | CORS configuration |
| `dj-database-url` | ✅ Used | `settings.py` line 106–109 |
| `psycopg2-binary` | ✅ Used | PostgreSQL adapter |
| `python-dotenv` | ✅ Used | `.env` loading |
| `requests` | ✅ Used | GitHub API, AI service |
| `PyJWT` | ✅ Used | JWT handling |
| `Twisted`, `autobahn`, `txaio` | ✅ Required | Daphne/Channels dependencies |
| `cryptography`, `pyOpenSSL`, `cffi` | ✅ Required | SSL/crypto deps for Twisted |
| `msgpack`, `ujson`, `cbor2`, `py-ubjson` | ⚠️ **Likely unnecessary** | Autobahn serialization backends. Only `ujson` might be useful. `cbor2`, `py-ubjson`, `msgpack` are likely pulled in as optional deps but not actively used. |
| `packaging` | ⚠️ **Transitive** | Not directly used, pulled in as dependency |

**Security Vulnerabilities:** I recommend running `pip audit` (via `pip install pip-audit && pip-audit -r requirements.txt`) before deploying. Key packages to watch: `cryptography`, `Twisted`, `requests`, `urllib3`.

---

### 1.2 Configuration Files

#### `.gitignore` — ✅ **GOOD**
- ✅ Excludes `.env`, `.env.local`, `.env.*.local`
- ✅ Excludes `node_modules/`
- ✅ Excludes `venv/`, `.venv/`, `env/`
- ✅ Excludes `dist/`, `build/`, `__pycache__/`
- ✅ Excludes `*.sqlite3`, `db.sqlite3`
- ✅ Excludes IDE files (`.idea/`, `.vscode/`)
- ✅ Excludes OS files (`.DS_Store`, `Thumbs.db`)

**Issue:** Despite `.gitignore` excluding `db.sqlite3`, the file `db.sqlite3` (221KB) exists in the project root and may be tracked in git already. It should be removed from git tracking.

#### `.env.example` — ⚠️ **INCOMPLETE**

**File:** `.env.example` (root)  
**Missing variables:**
- `GITHUB_CLIENT_ID` — Required for GitHub OAuth
- `GITHUB_CLIENT_SECRET` — Required for GitHub OAuth  
- `GITHUB_REDIRECT_URI` — Required for GitHub OAuth
- `FRONTEND_URL` — Used in `settings.py` line 29
- `DEBUG` — Critical for production
- `GITHUB_ADMIN_USERNAME` — Used for archiver
- `GITHUB_ADMIN_TOKEN` — Used for archiver

**Current `.env.example` only documents:** `DJANGO_SECRET_KEY`, `ALLOWED_HOSTS`, `CORS_ALLOWED_ORIGINS`, `DATABASE_URL`, `REDIS_URL`

---

### 1.3 Build & Run Scripts

| Script | Status | Issues |
|---|---|---|
| `run_dev.sh` | ⚠️ **SECRETS EXPOSED** | **Line 29-31:** GitHub OAuth `CLIENT_ID` and `CLIENT_SECRET` are hardcoded directly in this script. |
| `backend/start_server.sh` | ⚠️ **Issues** | Line 11: Hardcoded `GITHUB_ADMIN_USERNAME="Sumit785-dot"`. Line 48-60: Uses `docker` directly instead of docker-compose. |
| `backend/build.sh` | ✅ Good | Render build script — clean and correct. |
| `render.yaml` | ✅ Good | Render deployment config is well-structured. |
| `frontend/package.json` scripts | ✅ Good | `dev`, `build`, `preview`, `lint` — all correctly defined. |

---

## 2. Frontend (React/Vite) Deep Dive

### 2.1 Environment Variables

#### 🔴 CRITICAL: Hardcoded URLs Found

| File | Line | Issue | Current Value |
|---|---|---|---|
| `frontend/.env.production` | 2 | Hardcoded production API URL | `VITE_API_URL=https://compiler-share.onrender.com/api` |
| `frontend/vite.config.js` | 27 | Hardcoded ngrok host in `allowedHosts` | `carlo-unverificative-unconfoundedly.ngrok-free.dev` |

#### WebSocket URL Analysis

**File:** `frontend/src/context/WebSocketContext.jsx`, Lines 11-12

```javascript
const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
const WS_BASE_URL = import.meta.env.VITE_WS_URL || `${protocol}//${window.location.hostname}:8001`;
```

**Assessment:** ⚠️ **Partially correct.** 
- ✅ The protocol detection (`ws:` vs `wss:`) is correct.
- ❌ The fallback uses `window.location.hostname:8001` — in production, WebSocket should go through the same host/port as HTTP (via reverse proxy). The `:8001` port will fail in production. 
- ❌ `VITE_WS_URL` is not documented in `.env.example` or `.env.production`.

**File:** `frontend/src/components/Student/PersonalConsole.jsx`, Lines 40-42

```javascript
const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
const wsUrl = `${wsProtocol}//${window.location.host}/ws/execute/...`;
```

**Assessment:** ✅ **Correct.** Uses `window.location.host` which includes the correct port and will work behind a reverse proxy.

#### API Base URL

**File:** `frontend/src/services/api.js`, Line 7

```javascript
const API_BASE_URL = import.meta.env.VITE_API_URL || '/api';
```

**Assessment:** ✅ **Good.** Falls back to relative `/api` which works behind a reverse proxy in production.

---

### 2.2 Code Quality & Unused Code

#### Unused Imports Scan

| File | Line | Import | Status |
|---|---|---|---|
| All `lucide-react` imports | Various | Checked in `Footer.jsx`, `Student/Dashboard.jsx` | ✅ All used |
| All `framer-motion` imports | Various | Checked in `SessionManager.jsx`, `Student/Dashboard.jsx` | ✅ All used |

#### Debug Console Statements (Should be removed for production)

**Frontend (34+ instances):**

| File | Type | Count |
|---|---|---|
| `WebSocketContext.jsx` | `console.log` (DEBUG), `console.warn`, `console.error` | 9 |
| `PersonalConsole.jsx` | `console.log`, `console.error` | 4 |
| `Teacher/Dashboard.jsx` | `console.log` (DEBUG), `console.error` | 6 |
| `Student/CodingInterface.jsx` | `console.log`, `console.error` | 7 |
| `Teacher/SessionManager.jsx` | `console.error` | 3 |
| `Teacher/StudentTile.jsx` | `console.error` | 1 |
| `Teacher/TeacherSettings.jsx` | `console.error` | 1 |
| `Teacher/AIChatWidget.jsx` | `console.error` | 1 |

**Backend (14+ print statements):**

| File | Line(s) | Type |
|---|---|---|
| `coding/consumers.py` | 34, 382, 384, 386, 671, 676, 678 | `print()` DEBUG statements |
| `sessions/views.py` | 279, 291, 306, 316 | `print()` DEBUG statements |
| `coding/ai_service.py` | 54, 58 | `print()` DEBUG statements |

**Recommendation:** Replace all `print()` with `logger.debug()` and remove `// DEBUG` console.log statements.

#### Context API Efficiency

| Context | Assessment |
|---|---|
| `AuthContext` | ✅ Efficient. Simple state, no unnecessary re-renders. |
| `WebSocketContext` | ✅ Good. Uses `useRef` for listeners/timers, `useCallback` for memoization. |
| `ThemeContext` | ✅ Simple and efficient. |

**Potential Issue:** The `WebSocketContext` wraps the entire app in `main.jsx`, meaning any `lastMessage` state update will potentially trigger re-renders on all consumers. However, since most components use specific `on()` listeners via `useRef`, this is mitigated.

---

### 2.3 State Management & API Calls

#### Centralized Axios Instance — ✅ **GOOD**

**File:** `frontend/src/services/api.js`
- ✅ Single axios instance with `baseURL`
- ✅ Request interceptor adds `Authorization: Bearer <token>` header (Line 19-28)
- ✅ Response interceptor handles 401 with token refresh logic (Line 31-67)
- ✅ Refresh failure correctly clears tokens and redirects to `/login`

#### WebSocket Connection Management

**`WebSocketContext.jsx`:**
- ✅ Reconnection logic with exponential backoff (Line 109: `Math.min(3000 * attempts, 15000)`)
- ✅ Max reconnect attempts = 5 (Line 25)
- ✅ Heartbeat interval = 60s (Line 62)
- ✅ Cleanup on unmount via `useEffect` return (Line 180-184)
- ✅ No reconnect on auth failure (code 4001) or normal close (code 1000)

**`PersonalConsole.jsx` (separate WebSocket):**
- ✅ Has reconnection logic (Line 91-97: reconnect after 10s)
- ❌ **No max reconnect attempts** — will retry infinitely
- ❌ **No cleanup on unmount** — the `connect()` function does not return a cleanup. The component never closes the socket on unmount.

---

### 2.4 Build Optimization

**File:** `frontend/vite.config.js`

```javascript
build: {
    outDir: 'dist',
    assetsDir: 'assets',
},
```

**Assessment:** ⚠️ **Minimal configuration.**
- ❌ No explicit code splitting configuration (Vite does automatic splitting for dynamic imports, but none are used)
- ❌ No `rollupOptions.output.manualChunks` for vendor splitting
- ❌ Monaco Editor (~4MB) is not lazy-loaded — it bloats the initial bundle significantly
- ⚠️ `base: '/static/'` for build is correct for Django serving

**Recommendation:**
```javascript
build: {
    outDir: 'dist',
    assetsDir: 'assets',
    rollupOptions: {
        output: {
            manualChunks: {
                vendor: ['react', 'react-dom', 'react-router-dom'],
                monaco: ['@monaco-editor/react'],
            }
        }
    }
}
```

---

## 3. Backend (Django/DRF/Channels) Deep Dive

### 3.1 Settings & Security (`settings.py`)

#### 🔴 CRITICAL ISSUES

| Issue | File:Line | Severity | Details |
|---|---|---|---|
| **`CORS_ORIGIN_ALLOW_ALL = True`** | `settings.py:169` | 🔴 **CRITICAL** | Overrides `CORS_ALLOWED_ORIGINS` completely. Allows ANY origin to make authenticated requests. **MUST be `False` in production.** |
| **`DEBUG` defaults to `True`** | `settings.py:20` | 🔴 **CRITICAL** | `os.environ.get('DEBUG', 'True')` — if env var is not set, DEBUG is True. Must default to `False`. |
| **`ALLOWED_HOSTS` includes `*` when DEBUG** | `settings.py:26` | 🟡 **WARNING** | Appends wildcard when DEBUG is True. Acceptable for dev, but `DEBUG` defaulting to `True` makes this dangerous. |
| **Insecure fallback `SECRET_KEY`** | `settings.py:17` | 🔴 **CRITICAL** | Fallback is `'django-insecure-dev-key-change-in-production'`. If env var is unset, this weak key is used. |
| **`InMemoryChannelLayer`** | `settings.py:87` | 🔴 **CRITICAL** for production | InMemory channel layer does NOT work with multiple workers. Must use Redis (`channels_redis`). |
| **Ngrok URLs in `CSRF_TRUSTED_ORIGINS`** | `settings.py:172-178` | 🟡 **WARNING** | Hardcoded ngrok URLs and local IPs. Should be from env vars. |

#### ✅ Good Security Practices Found

| Feature | File:Line | Details |
|---|---|---|
| Security headers enabled | `settings.py:192-194` | `XSS_FILTER`, `CONTENT_TYPE_NOSNIFF`, `X_FRAME_OPTIONS` |
| HTTPS enforcement when not DEBUG | `settings.py:197-203` | `SSL_REDIRECT`, `HSTS`, secure cookies |
| JWT Authentication as default | `settings.py:140-145` | `IsAuthenticated` as default permission |
| Token blacklisting on rotation | `settings.py:153` | `BLACKLIST_AFTER_ROTATION: True` |

---

### 3.2 🔴 CRITICAL: Hardcoded Secrets

#### `authentication/github.py`, Lines 9-11:

```python
GITHUB_CLIENT_ID = os.environ.get('GITHUB_CLIENT_ID', 'Ov23liaAfmVZc6YEUtYI')
GITHUB_CLIENT_SECRET = os.environ.get('GITHUB_CLIENT_SECRET', 'd6138f02becc866af8c62b89f467eed7ff136f14')
GITHUB_REDIRECT_URI = os.environ.get('GITHUB_REDIRECT_URI', 'https://compiler-share.onrender.com/api/auth/github/callback/')
```

**IMPACT:** GitHub OAuth Client Secret is **hardcoded as a fallback**. Even though it uses `os.environ.get()`, the secret is baked into the source code and committed to git. **This secret MUST be rotated immediately** and the fallback values removed.

#### `run_dev.sh`, Lines 29-31:

```bash
export GITHUB_CLIENT_ID="Ov23li5UwiufLxZ6Y1EQ"
export GITHUB_CLIENT_SECRET="8a41855d69c082437df197a525eb00aebab3b943"
```

**IMPACT:** Different set of GitHub OAuth credentials hardcoded in the dev script. **Must be rotated.**

#### `start_server.sh`, Line 11:

```bash
export GITHUB_ADMIN_USERNAME="Sumit785-dot"
```

**IMPACT:** Admin GitHub username hardcoded. Less critical but should be in `.env`.

---

### 3.3 Database & Models

#### Database Configuration — ✅ **GOOD**

**File:** `settings.py`, Lines 99-109

The database is correctly require `DATABASE_URL` env var and uses `dj_database_url` for parsing. Raises `ValueError` if not set (except during `collectstatic`).

#### N+1 Query Analysis

**File:** `sessions/views.py`, `TeacherDashboardView`, Lines 206-269

```python
participants = session.participants.select_related('student').order_by('student__id').all()

for participant in participants:
    snapshot = CodeSnapshot.objects.filter(...).first()  # N queries
    logs = ConsoleLog.objects.filter(...)[:10]           # N queries
    has_errors = ErrorNotification.objects.filter(...).exists()  # N queries
```

**VERDICT:** 🔴 **Classic N+1 problem.** For N students, this makes **3N + 1 queries**. With 30 students, that's **91 database queries per dashboard load.**

**Fix:** Use `Prefetch` objects:

```python
from django.db.models import Prefetch, Exists, OuterRef

participants = session.participants.select_related('student').prefetch_related(
    Prefetch('student__code_snapshots', 
             queryset=CodeSnapshot.objects.filter(session=session),
             to_attr='current_snapshots'),
    Prefetch('student__console_logs',
             queryset=ConsoleLog.objects.filter(session=session).order_by('-created_at')[:10],
             to_attr='recent_logs_cached'),
).annotate(
    has_unread_errors=Exists(
        ErrorNotification.objects.filter(
            session=session, student=OuterRef('student'), is_read=False
        )
    )
)
```

---

### 3.4 API & Authentication

#### Permission Classes — ✅ **GOOD**

| Endpoint | Permission | Assessment |
|---|---|---|
| `RegisterView` | `AllowAny` | ✅ Correct (public) |
| `LoginView` | `AllowAny` | ✅ Correct (public) |
| `LogoutView` | `IsAuthenticated` | ✅ Correct |
| `ProfileView` | `IsAuthenticated` | ✅ Correct |
| `ExecuteCodeView` | `IsAuthenticated` | ✅ Correct |
| `SaveCodeView` | `IsAuthenticated` | ✅ Correct |
| `TeacherSaveCodeView` | `IsAuthenticated` + checks `teacher=request.user` | ✅ Correct |
| `AISolveView` | `IsAuthenticated` + checks `role != 'teacher'` | ✅ Correct |
| `GitHubCallbackView` | `AllowAny` | ✅ Correct (OAuth redirect) |
| All Sessions views | `IsAuthenticated` | ✅ Correct |

#### JWT Token Refresh — ✅ **GOOD**

**Frontend:** `services/api.js`, Lines 31-67 — Correctly intercepts 401 responses, refreshes the token using the refresh endpoint, and retries the original request. On failure, clears tokens and redirects to login.

**Backend:** JWT configured with 12-hour access token lifetime and 7-day refresh token lifetime (`settings.py:149-155`). Token rotation is enabled.

---

### 3.5 Real-time Layer (Django Channels)

#### ASGI Routing — ✅ **GOOD**

**File:** `backend/config/asgi.py`

```python
application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": JWTAuthMiddlewareStack(
        URLRouter(websocket_urlpatterns)
    ),
})
```

- ✅ HTTP and WebSocket properly separated
- ✅ JWT authentication middleware wraps WebSocket routes

#### WebSocket Authentication — ✅ **GOOD**

**File:** `backend/coding/middleware.py`

- ✅ Extracts JWT token from query string (`?token=<jwt>`)
- ✅ Validates token using `AccessToken`
- ✅ Fetches user from database
- ✅ Falls back to `AnonymousUser` on failure
- ✅ Proper error logging

**Issue:** The `CodingConsumer.connect()` correctly rejects unauthenticated users (Line 40: `await self.close(code=4001)`).

#### 🔴 CRITICAL: `InteractiveExecutionConsumer` — NO AUTHENTICATION

**File:** `backend/coding/consumers.py`, Lines 539-544:

```python
class InteractiveExecutionConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.accept()  # Accepts ANY connection — no auth check!
```

**IMPACT:** The interactive code execution WebSocket endpoint (`/ws/execute/`) accepts connections **without any authentication**. Anyone who knows the URL can execute arbitrary code on the server.

**Fix:** Add authentication check:

```python
async def connect(self):
    self.user = self.scope.get('user')
    if not self.user or not self.user.is_authenticated:
        await self.close(code=4001)
        return
    await self.accept()
```

---

### 3.6 Archiver Bug

**File:** `backend/coding/archiver.py`

**Line 23:** `return f"Observer-Session-{session.session_code}-{topic}"` — References undefined variable `topic`.

**Line 131:** `args=(session.session_code, session.topic, ...)` — `CodingSession` model has NO `topic` field. This will cause an `AttributeError` at runtime.

**This archiver feature is broken** and will silently fail due to the try/except wrapper.

---

## 4. Code Execution Engine — CRITICAL SECURITY AUDIT

### 4.1 Isolation & Sandboxing

#### 🔴🔴🔴 CRITICAL VULNERABILITY: NO SANDBOXING

**File:** `backend/coding/executor.py`

**Method:** The code execution engine uses **bare `subprocess.run()` and `asyncio.create_subprocess_exec()`** to execute user-submitted code directly on the host system.

```python
# Line 78-84 (async Python execution)
process = await asyncio.create_subprocess_exec(
    'python3', '-u', temp_file,
    stdin=asyncio.subprocess.PIPE,
    stdout=asyncio.subprocess.PIPE,
    stderr=asyncio.subprocess.PIPE,
    cwd=tempfile.gettempdir()
)
```

**There is NO:**
- ❌ Docker container isolation
- ❌ chroot jail
- ❌ Dedicated low-privilege user
- ❌ seccomp profiles
- ❌ Namespace isolation
- ❌ Any form of sandboxing whatsoever

**The executed code runs with the SAME privileges as the Django process**, which typically has read/write access to the entire application codebase, database credentials, environment variables, and system files.

---

### 4.2 Command Injection Prevention

#### Analysis of Command Construction

```python
# Python execution (Line 278-283)
result = subprocess.run(
    ['python3', temp_file],  # Array form — NOT vulnerable to shell injection
    ...
)

# C compilation (Line 397-403)
subprocess.run(
    ['gcc', source_file, '-o', output_file],  # Array form — safe
    ...
)
```

**Assessment:** ✅ **Command injection via shell metacharacters is mitigated** because `subprocess.run()` and `create_subprocess_exec()` are called with **list arguments** (not string + `shell=True`). This prevents classical `; rm -rf /` injection.

**However:** The code content itself is **written to a file and executed directly**. A malicious Python script can:

```python
# User submits this as "code":
import os
os.system("cat /etc/passwd")
os.environ  # Read all environment variables (DB passwords, secrets)
import subprocess
subprocess.run(["rm", "-rf", "/home"])
```

This is not command injection — it's **arbitrary code execution by design**, which the sandboxing should prevent but doesn't.

---

### 4.3 Resource Limits

#### CPU Time Limits

| Method | Timeout | Implementation |
|---|---|---|
| `_execute_python` | `self.timeout` (5s default) | `subprocess.run(..., timeout=self.timeout)` ✅ |
| `_execute_javascript` | `self.timeout` | Same ✅ |
| `_execute_c` | `self.timeout` for both compile and run | Same ✅ |
| `_execute_cpp` | `self.timeout` | Same ✅ |
| `_execute_java` | `self.timeout` | Same ✅ |
| `start_async_interactive` | **❌ NO TIMEOUT** | `await process.wait()` with no timeout! |

**🔴 CRITICAL:** The interactive execution (`InteractiveExecutionConsumer`) has **NO timeout**. A user can submit an infinite loop that will run forever and consume server resources.

```python
# consumers.py Line 627
return_code = await process.wait()  # Waits FOREVER
```

#### Memory Limits

**File:** `settings.py`, Line 183:

```python
CODE_EXECUTION_MEMORY_LIMIT = 50 * 1024 * 1024  # 50MB
```

**VERDICT:** 🔴 **This setting EXISTS but is NEVER USED.** The executor reads `self.memory_limit` in `__init__` but never applies it to any subprocess. There are **no memory limits** enforced on executed processes.

The Python `resource` module is not imported or used anywhere. No `ulimit`, no Docker `--memory` flags, no cgroups.

---

### 4.4 Filesystem & Network Access

| Vector | Status | Details |
|---|---|---|
| **Filesystem READ** | 🔴 **UNRESTRICTED** | Executed code can read any file the Django process user can read: `/etc/passwd`, `settings.py`, `.env`, database files |
| **Filesystem WRITE** | 🔴 **UNRESTRICTED** | Can write to any writable directory. Can overwrite application files, create backdoor scripts, fill disk |
| **Network ACCESS** | 🔴 **UNRESTRICTED** | Executed code can make HTTP requests, connect to databases, send data to external servers, scan internal network |
| **Process spawning** | 🔴 **UNRESTRICTED** | Can spawn additional processes, create reverse shells |
| **Environment variables** | 🔴 **READABLE** | `os.environ` exposes `DJANGO_SECRET_KEY`, `DATABASE_URL`, `GITHUB_*` secrets |

---

### 4.5 Cleanup

#### Synchronous Execution (`_execute_*` methods)

**Assessment:** ✅ **GOOD.** All methods use `try/finally` blocks to clean up temp files:

```python
finally:
    try:
        os.unlink(temp_file)
    except:
        pass
```

Java uses `shutil.rmtree(temp_dir)` for directory cleanup. C/C++ clean up both source and binary files.

#### Async Interactive Execution

**Assessment:** ⚠️ **Partial.**

```python
# consumers.py Lines 559-570
async def disconnect(self, close_code):
    if self.process:
        try:
            self.process.terminate()
            self.process.wait(timeout=1)
        except:
            try:
                self.process.kill()
            except:
                pass
    
    for path in self.files_to_cleanup:
        ...
```

- ✅ Process is terminated on disconnect
- ✅ Files are cleaned up on disconnect
- ❌ If the WebSocket connection drops unexpectedly (server crash, network failure), cleanup may not run
- ❌ If the process spawns child processes, those are NOT cleaned up (orphan processes)
- ❌ `self.process.wait(timeout=1)` is a **synchronous blocking call** inside an async method — this can block the event loop

---

## 5. Final Report & Actionable Checklist

### 5.1 Summary

The application has a **well-structured codebase** with good practices in many areas (centralized API client, JWT auth, proper ASGI routing, clean component architecture). However, it has **critical security vulnerabilities** that make it **UNSAFE for public deployment** in its current state.

The most severe issue is the **completely unsandboxed code execution engine** — it provides arbitrary remote code execution with the privileges of the web server process. This must be addressed before any public-facing deployment.

---

### 5.2 🔴 Critical Issues (Must-Fix Before Deployment)

| # | Issue | File:Line | Fix |
|---|---|---|---|
| **C1** | **Unsandboxed code execution** | `executor.py` (entire file) | Implement Docker/Podman container isolation for ALL code execution |
| **C2** | **No authentication on `/ws/execute/`** | `consumers.py:543-544` | Add JWT auth check in `InteractiveExecutionConsumer.connect()` |
| **C3** | **`CORS_ORIGIN_ALLOW_ALL = True`** | `settings.py:169` | Remove this line or set to `False`. Use `CORS_ALLOWED_ORIGINS` only. |
| **C4** | **Hardcoded GitHub secrets** | `github.py:9-11`, `run_dev.sh:29-31` | **Rotate these credentials NOW.** Remove fallback values. Read from env vars only. |
| **C5** | **`DEBUG` defaults to `True`** | `settings.py:20` | Change default to `'False'`: `os.environ.get('DEBUG', 'False')` |
| **C6** | **No memory/CPU limits** on execution | `executor.py` | Implement via Docker `--memory`, `--cpus`, or Python `resource` module |
| **C7** | **No timeout on interactive execution** | `consumers.py:627` | Add `asyncio.wait_for(process.wait(), timeout=30)` |
| **C8** | **InMemoryChannelLayer** for production | `settings.py:87` | Use `channels_redis` with Redis. Add `channels-redis` to `requirements.txt`. |
| **C9** | **No network/filesystem isolation** for executed code | `executor.py` | Docker with `--network none` and read-only filesystem |
| **C10** | **Insecure fallback SECRET_KEY** | `settings.py:17` | Crash if not set: `SECRET_KEY = os.environ['DJANGO_SECRET_KEY']` |

---

### 5.3 Performance & Optimization Recommendations

| # | Area | Issue | Recommendation |
|---|---|---|---|
| **P1** | N+1 Queries | `TeacherDashboardView` makes 3N+1 queries | Use `select_related`, `prefetch_related`, `annotate(Exists(...))` |
| **P2** | Monaco Editor | ~4MB not code-split | Lazy load via `React.lazy()` or configure `manualChunks` in Vite |
| **P3** | WebSocket heartbeat | `get_user_data()` called on every group_send handler | Cache user data in instance variable during `connect()` |
| **P4** | Debug print statements | 14+ `print()` in backend | Replace with `logger.debug()` — prints to stdout are expensive |
| **P5** | Personal Console reconnect | Infinite reconnection attempts | Add max attempts counter and exponential backoff |
| **P6** | Frontend bundle | No vendor code splitting | Add `manualChunks` to Vite config for vendor, monaco, framer-motion |
| **P7** | Stream reading | `consumers.py:650`: reads 1 byte at a time | Read in larger chunks (e.g., `read(4096)`) for better throughput |
| **P8** | Static files | No `WhiteNoise` middleware | Add `whitenoise` for efficient static file serving without Nginx overhead |

---

### 5.4 Unused Code Cleanup List

| Type | Item | Location | Action |
|---|---|---|---|
| **DevDependency** | `@types/react` | `frontend/package.json:22` | Remove — no TypeScript in project |
| **DevDependency** | `@types/react-dom` | `frontend/package.json:23` | Remove — no TypeScript in project |
| **Dependency** | `cbor2`, `py-ubjson`, `msgpack` | `backend/requirements.txt` | Likely transitive — verify with `pipdeptree` |
| **File** | `db.sqlite3` | Root directory | Remove from git tracking: `git rm --cached db.sqlite3` |
| **File** | `test.txt` | Root directory | Remove — test artifact |
| **File** | `test_login_debug.py` | Root directory | Remove — debug test file |
| **File** | `test_ws.py` | Root directory | Remove — debug test file |
| **File** | `frontend/vercel.json` | Frontend directory | Remove if not deploying to Vercel |
| **Code** | Debug `print()` statements | `consumers.py`, `sessions/views.py`, `ai_service.py` | Replace with `logger.debug()` |
| **Code** | Debug `console.log()` statements | Multiple `.jsx` files | Remove `// DEBUG` tagged logs |
| **Code** | Broken `archiver.py` (references `session.topic`)| `backend/coding/archiver.py:23,131` | Fix or remove — currently non-functional |
| **Code** | Commented-out code | `consumers.py:248-250`, `views.py:76-82` | Remove or enable |
| **Setting** | Hardcoded ngrok URL in `vite.config.js` | `frontend/vite.config.js:27` | Remove `allowedHosts` entry |
| **Setting** | Hardcoded ngrok URLs in `CSRF_TRUSTED_ORIGINS` | `settings.py:173-178` | Move to env var or remove |

---

### 5.5 Deployment Checklist

#### Pre-Deployment

- [ ] **1. Rotate compromised secrets**
    - Regenerate GitHub OAuth `CLIENT_ID`/`CLIENT_SECRET` (both sets)
    - Generate new `DJANGO_SECRET_KEY`
    - Remove hardcoded fallback values from `github.py`
    - Remove secrets from `run_dev.sh` (use `.env` instead)
- [ ] **2. Fix `settings.py` security**
    - Set `DEBUG` default to `False`
    - Remove `CORS_ORIGIN_ALLOW_ALL = True` (Line 169)
    - Set `SECRET_KEY` to crash if unset (no fallback)
    - Clean up hardcoded ngrok URLs from `CSRF_TRUSTED_ORIGINS`
- [ ] **3. Add authentication to `/ws/execute/`**
- [ ] **4. Implement code execution sandboxing** (Docker/Podman containers)
- [ ] **5. Switch to Redis channel layer**
    - `pip install channels-redis`
    - Update `settings.py` CHANNEL_LAYERS
    - Provision Redis instance
- [ ] **6. Update `.env.example`** with ALL required variables
- [ ] **7. Remove test/debug files** (`test.txt`, `test_ws.py`, `test_login_debug.py`, `db.sqlite3`)
- [ ] **8. Run `pip audit`** to check for vulnerable dependencies
- [ ] **9. Run `npm audit`** in frontend for JS vulnerabilities

#### Deployment Steps

- [ ] **10. Set ALL environment variables** on hosting platform:
    ```
    DJANGO_SECRET_KEY=<generated>
    DEBUG=False
    ALLOWED_HOSTS=yourdomain.com
    DATABASE_URL=postgresql://user:pass@host:5432/dbname
    REDIS_URL=redis://host:6379
    CORS_ALLOWED_ORIGINS=https://yourdomain.com
    FRONTEND_URL=https://yourdomain.com
    GITHUB_CLIENT_ID=<new>
    GITHUB_CLIENT_SECRET=<new>
    GITHUB_REDIRECT_URI=https://yourdomain.com/api/auth/github/callback/
    GITHUB_ADMIN_USERNAME=<username>
    GITHUB_ADMIN_TOKEN=<token>
    VITE_API_URL=/api
    VITE_WS_URL=wss://yourdomain.com
    ```
- [ ] **11. Run database migrations**: `python manage.py migrate --noinput`
- [ ] **12. Create superuser**: `python manage.py createsuperuser`
- [ ] **13. Collect static files**: `python manage.py collectstatic --noinput`
- [ ] **14. Build frontend**: `cd frontend && npm install && npm run build`
- [ ] **15. Start ASGI server**: `daphne -b 0.0.0.0 -p $PORT config.asgi:application`
- [ ] **16. Configure reverse proxy** (Nginx):
    ```nginx
    server {
        listen 443 ssl;
        server_name yourdomain.com;
        
        location /api/ {
            proxy_pass http://127.0.0.1:8000;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        location /ws/ {
            proxy_pass http://127.0.0.1:8000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_read_timeout 86400;
        }
        
        location /static/ {
            alias /path/to/backend/staticfiles/;
        }
        
        location / {
            try_files $uri $uri/ /index.html;
            root /path/to/frontend/dist/;
        }
    }
    ```
- [ ] **17. Set up SSL/TLS** (Let's Encrypt / Certbot)
- [ ] **18. Configure process manager** (systemd / supervisord for Daphne)
- [ ] **19. Set up log rotation** and monitoring
- [ ] **20. Smoke test** all features:
    - Registration/Login
    - Session creation/joining
    - WebSocket real-time sync
    - Code execution (all 5 languages)
    - GitHub OAuth flow
    - Token refresh on session expiry

---

### 5.6 Risk Matrix

| Risk Level | Count | Items |
|---|---|---|
| 🔴 Critical | **10** | Unsandboxed execution, CORS wildcard, hardcoded secrets, no ws auth, no resource limits, DEBUG default, no timeout on interactive, InMemory channel layer, no network isolation, insecure SECRET_KEY fallback |
| 🟡 Warning | **6** | N+1 queries, incomplete .env.example, debug print statements, ngrok hardcoded, archiver broken, no personal console cleanup |
| 🟢 Good | **12** | JWT auth, API interceptors, WebSocket reconnection, permission classes, ASGI routing, security headers, HTTPS enforcement, token blacklisting, file cleanup (sync), centralized API client, proper git ignore, input validation |

**Overall Readiness: 🔴 NOT READY FOR PRODUCTION**

The application requires addressing all 10 critical issues before public deployment. The code execution engine is the highest priority — in its current state, it provides unauthenticated, unsandboxed remote code execution, which is equivalent to giving any user a shell on the server.
