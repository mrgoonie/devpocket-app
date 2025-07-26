# DevPocket Mobile Integration Guide

This guide provides comprehensive instructions for integrating the DevPocket API and WebSocket connections into mobile applications for iOS and Android.

## Table of Contents

1. [Overview](#overview)
2. [API Base Configuration](#api-base-configuration)
3. [Authentication](#authentication)
4. [API Integration](#api-integration)
5. [WebSocket Integration](#websocket-integration)
6. [Error Handling](#error-handling)
7. [Best Practices](#best-practices)
8. [Platform-Specific Examples](#platform-specific-examples)

## Overview

DevPocket provides a RESTful API for managing development environments and WebSocket connections for real-time terminal access. The API uses JWT tokens for authentication and supports both traditional email/password and Google OAuth authentication.

### Key Features
- JWT-based authentication with refresh tokens
- RESTful API for environment management
- WebSocket connections for real-time terminal access
- Rate limiting (100 requests per minute)
- Comprehensive error responses

## API Base Configuration

### Base URLs
```
Production: https://api.devpocket.io
Development: http://localhost:8000
```

### Headers
All API requests should include:
```http
Content-Type: application/json
Authorization: Bearer <jwt-token>
```

## Authentication

### 1. User Registration

**Endpoint:** `POST /api/v1/auth/register`

**Request Body:**
```json
{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "SecurePassword123!",
  "full_name": "John Doe"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 1800,
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "username": "johndoe",
    "email": "john@example.com",
    "full_name": "John Doe",
    "is_active": true,
    "is_verified": false,
    "subscription_plan": "free",
    "created_at": "2024-01-15T10:00:00Z"
  }
}
```

### 2. User Login

**Endpoint:** `POST /api/v1/auth/login`

**Request Body:**
```json
{
  "username_or_email": "john@example.com",
  "password": "SecurePassword123!"
}
```

**Response:** Same as registration

### 3. Token Refresh

**Endpoint:** `POST /api/v1/auth/refresh`

**Request Body:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

### 4. Google OAuth

**Step 1: Get OAuth URL**
```
GET /api/v1/auth/google
```

**Step 2: Handle Callback**
After Google authentication, the user will be redirected to your app with an authorization code. Exchange it:

```
GET /api/v1/auth/google/callback?code=<authorization_code>
```

### Token Storage Best Practices

**iOS (Swift):**
```swift
import Security

class TokenManager {
    static func saveToken(_ token: String, for key: String) {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func getToken(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        if let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
```

**Android (Kotlin):**
```kotlin
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

class TokenManager(context: Context) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()
    
    private val sharedPreferences = EncryptedSharedPreferences.create(
        context,
        "devpocket_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )
    
    fun saveToken(token: String, key: String) {
        sharedPreferences.edit().putString(key, token).apply()
    }
    
    fun getToken(key: String): String? {
        return sharedPreferences.getString(key, null)
    }
}
```

## API Integration

### Environment Management

#### 1. List Environments

**Endpoint:** `GET /api/v1/environments`

**Response:**
```json
[
  {
    "id": "507f1f77bcf86cd799439011",
    "name": "my-python-env",
    "template": "python",
    "status": "running",
    "resources": {
      "cpu": "500m",
      "memory": "1Gi",
      "storage": "10Gi"
    },
    "external_url": "https://env-abc123.devpocket.io",
    "web_port": 8080,
    "created_at": "2024-01-15T10:00:00Z",
    "last_accessed": "2024-01-15T12:30:00Z",
    "cpu_usage": 25.5,
    "memory_usage": 45.2,
    "storage_usage": 10.8
  }
]
```

#### 2. Create Environment

**Endpoint:** `POST /api/v1/environments`

**Request Body:**
```json
{
  "name": "my-nodejs-app",
  "template": "nodejs",
  "resources": {
    "cpu": "1000m",
    "memory": "2Gi",
    "storage": "20Gi"
  },
  "environment_variables": {
    "NODE_ENV": "development",
    "PORT": "3000"
  }
}
```

#### 3. Start/Stop Environment

**Start:** `POST /api/v1/environments/{environment_id}/start`  
**Stop:** `POST /api/v1/environments/{environment_id}/stop`

#### 4. Delete Environment

**Endpoint:** `DELETE /api/v1/environments/{environment_id}`

### Mobile SDK Examples

**iOS (Swift) - API Client:**
```swift
import Foundation
import Combine

class DevPocketAPI {
    static let shared = DevPocketAPI()
    private let baseURL = "https://api.devpocket.io"
    private var cancellables = Set<AnyCancellable>()
    
    private var authToken: String? {
        return TokenManager.getToken(for: "access_token")
    }
    
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) -> AnyPublisher<T, Error> {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, Error> {
        let body = try? JSONEncoder().encode([
            "username_or_email": email,
            "password": password
        ])
        
        return makeRequest(
            endpoint: "/api/v1/auth/login",
            method: "POST",
            body: body
        )
    }
    
    func getEnvironments() -> AnyPublisher<[Environment], Error> {
        return makeRequest(endpoint: "/api/v1/environments")
    }
}
```

**Android (Kotlin) - API Client:**
```kotlin
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import okhttp3.OkHttpClient
import okhttp3.Interceptor

class DevPocketAPI(private val context: Context) {
    private val tokenManager = TokenManager(context)
    
    private val authInterceptor = Interceptor { chain ->
        val original = chain.request()
        val token = tokenManager.getToken("access_token")
        
        val request = original.newBuilder().apply {
            token?.let {
                header("Authorization", "Bearer $it")
            }
            header("Content-Type", "application/json")
        }.build()
        
        chain.proceed(request)
    }
    
    private val client = OkHttpClient.Builder()
        .addInterceptor(authInterceptor)
        .build()
    
    private val retrofit = Retrofit.Builder()
        .baseUrl("https://api.devpocket.io")
        .client(client)
        .addConverterFactory(GsonConverterFactory.create())
        .build()
    
    val authService: AuthService = retrofit.create(AuthService::class.java)
    val environmentService: EnvironmentService = retrofit.create(EnvironmentService::class.java)
}

interface AuthService {
    @POST("/api/v1/auth/login")
    suspend fun login(@Body credentials: LoginRequest): AuthResponse
    
    @POST("/api/v1/auth/register")
    suspend fun register(@Body user: RegisterRequest): AuthResponse
}

interface EnvironmentService {
    @GET("/api/v1/environments")
    suspend fun getEnvironments(): List<Environment>
    
    @POST("/api/v1/environments")
    suspend fun createEnvironment(@Body env: CreateEnvironmentRequest): Environment
}
```

## WebSocket Integration

The DevPocket API provides two WebSocket endpoints for real-time interaction with development environments:

1. **Terminal WebSocket** - Interactive terminal access
2. **Logs WebSocket** - Real-time log streaming

### WebSocket URL Formats

**Terminal Access:**
```
wss://api.devpocket.io/api/v1/ws/terminal/{environment_id}?token={jwt_token}
```

**Log Streaming:**
```
wss://api.devpocket.io/api/v1/ws/logs/{environment_id}?token={jwt_token}&follow=true
```

### Authentication

WebSocket connections require authentication via JWT token passed as a query parameter. The token must be valid and the user must have access to the specified environment.

**Authentication Failure Response:**
- Connection closes with code `1008` and reason "Authentication failed"

### Rate Limiting

- **Connection Limit:** Maximum concurrent WebSocket connections per user
- **Message Rate Limit:** Maximum messages per minute per connection
- Exceeded limits result in temporary message rejection or connection closure

### Terminal WebSocket Protocol

#### Client to Server Messages

**Terminal Input:**
```json
{
  "type": "input",
  "data": "ls -la\n"
}
```

**Terminal Resize:**
```json
{
  "type": "resize",
  "cols": 80,
  "rows": 24
}
```

**Keepalive Ping:**
```json
{
  "type": "ping"
}
```

#### Server to Client Messages

**Welcome Message (on connection):**
```json
{
  "type": "welcome",
  "message": "Connected to my-python-env",
  "environment": {
    "id": "507f1f77bcf86cd799439011",
    "name": "my-python-env",
    "template": "python",
    "status": "running"
  }
}
```

**Terminal Output:**
```json
{
  "type": "output",
  "data": "total 64\ndrwxr-xr-x  10 user user 4096 Jan 15 10:00 .\n"
}
```

**Error Message:**
```json
{
  "type": "error",
  "message": "Rate limit exceeded. Please slow down."
}
```

**Keepalive Pong:**
```json
{
  "type": "pong"
}
```

### Log Streaming WebSocket Protocol

#### Server to Client Messages

**Log Entry:**
```json
{
  "type": "log",
  "timestamp": "2024-01-15T12:30:45.123Z",
  "level": "info",
  "message": "Application started successfully"
}
```

#### Log Levels
- `debug` - Debug information
- `info` - General information
- `warning` - Warning messages
- `error` - Error messages

### Connection Management

#### Connection States
1. **Connecting** - Establishing WebSocket connection
2. **Connected** - Active connection, ready for messages
3. **Disconnected** - Connection closed normally
4. **Error** - Connection failed or encountered error

#### Reconnection Strategy
- Automatic reconnection with exponential backoff
- Maximum 5 reconnection attempts
- Initial delay: 2 seconds, doubles with each attempt
- Connection reset on successful reconnection

#### Keepalive Mechanism
- Client should send ping messages every 30 seconds
- Server responds with pong messages
- Missing pong responses indicate connection issues

### WebSocket Implementation

**iOS (Swift) - Enhanced WebSocket Client:**
```swift
import Foundation
import Combine

protocol WebSocketMessage {
    var type: String { get }
}

struct TerminalOutputMessage: WebSocketMessage {
    let type = "output"
    let data: String
}

struct WelcomeMessage: WebSocketMessage {
    let type = "welcome"
    let message: String
    let environment: EnvironmentInfo
}

struct ErrorMessage: WebSocketMessage {
    let type = "error"
    let message: String
}

struct EnvironmentInfo {
    let id: String
    let name: String
    let template: String
    let status: String
}

class DevPocketWebSocket: NSObject {
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case error(Error)
    }
    
    enum WebSocketType {
        case terminal(String) // environment_id
        case logs(String, Bool) // environment_id, follow
    }
    
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private let wsType: WebSocketType
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    
    @Published var connectionState: ConnectionState = .disconnected
    @Published var messages: [WebSocketMessage] = []
    
    private let messageSubject = PassthroughSubject<WebSocketMessage, Never>()
    var messagePublisher: AnyPublisher<WebSocketMessage, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    init(type: WebSocketType) {
        self.wsType = type
        super.init()
    }
    
    func connect() {
        guard connectionState != .connecting else { return }
        
        connectionState = .connecting
        
        guard let token = TokenManager.getToken(for: "access_token"),
              let url = buildWebSocketURL(token: token) else {
            connectionState = .error(WebSocketError.authenticationFailed)
            return
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        self.urlSession = session
        
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        receiveMessage()
    }
    
    private func buildWebSocketURL(token: String) -> URL? {
        let baseURL = "wss://api.devpocket.io/api/v1/ws"
        
        switch wsType {
        case .terminal(let envId):
            return URL(string: "\(baseURL)/terminal/\(envId)?token=\(token)")
        case .logs(let envId, let follow):
            return URL(string: "\(baseURL)/logs/\(envId)?token=\(token)&follow=\(follow)")
        }
    }
    
    func disconnect() {
        stopPingTimer()
        stopReconnectTimer()
        webSocket?.cancel(with: .goingAway, reason: nil)
        connectionState = .disconnected
    }
    
    func sendTerminalInput(_ command: String) {
        sendMessage([
            "type": "input",
            "data": command
        ])
    }
    
    func resizeTerminal(cols: Int, rows: Int) {
        sendMessage([
            "type": "resize",
            "cols": cols,
            "rows": rows
        ])
    }
    
    func sendPing() {
        sendMessage(["type": "ping"])
    }
    
    private func sendMessage(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              webSocket?.state == .running else { return }
        
        webSocket?.send(.data(data)) { [weak self] error in
            if let error = error {
                self?.handleError(error)
            }
        }
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleReceivedMessage(message)
                self?.receiveMessage() // Continue listening
                
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
    
    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) {
        let data: Data?
        
        switch message {
        case .data(let messageData):
            data = messageData
        case .string(let text):
            data = text.data(using: .utf8)
        @unknown default:
            return
        }
        
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }
        
        let wsMessage = parseMessage(type: type, json: json)
        DispatchQueue.main.async {
            self.messages.append(wsMessage)
            self.messageSubject.send(wsMessage)
        }
    }
    
    private func parseMessage(type: String, json: [String: Any]) -> WebSocketMessage {
        switch type {
        case "output":
            return TerminalOutputMessage(data: json["data"] as? String ?? "")
            
        case "welcome":
            let envData = json["environment"] as? [String: Any] ?? [:]
            let environment = EnvironmentInfo(
                id: envData["id"] as? String ?? "",
                name: envData["name"] as? String ?? "",
                template: envData["template"] as? String ?? "",
                status: envData["status"] as? String ?? ""
            )
            return WelcomeMessage(
                message: json["message"] as? String ?? "",
                environment: environment
            )
            
        case "error":
            return ErrorMessage(message: json["message"] as? String ?? "Unknown error")
            
        case "pong":
            // Handle keepalive response
            return PongMessage()
            
        case "log":
            return LogMessage(
                timestamp: json["timestamp"] as? String ?? "",
                level: json["level"] as? String ?? "info",
                message: json["message"] as? String ?? ""
            )
            
        default:
            return UnknownMessage(type: type, data: json)
        }
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.connectionState = .error(error)
        }
        scheduleReconnect()
    }
    
    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("Max reconnection attempts reached")
            return
        }
        
        let delay = pow(2.0, Double(reconnectAttempts))
        reconnectAttempts += 1
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
}

extension DevPocketWebSocket: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async {
            self.connectionState = .connected
            self.reconnectAttempts = 0
        }
        startPingTimer()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        stopPingTimer()
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
        
        if closeCode != .goingAway {
            scheduleReconnect()
        }
    }
}

// Additional message types
struct PongMessage: WebSocketMessage {
    let type = "pong"
}

struct LogMessage: WebSocketMessage {
    let type = "log"
    let timestamp: String
    let level: String
    let message: String
}

struct UnknownMessage: WebSocketMessage {
    let type: String
    let data: [String: Any]
}

enum WebSocketError: Error {
    case authenticationFailed
    case connectionFailed
    case invalidMessage
}
```

**Android (Kotlin) - Enhanced WebSocket Client:**
```kotlin
import android.content.Context
import android.os.Handler
import android.os.Looper
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import okhttp3.*
import org.json.JSONObject
import java.util.concurrent.TimeUnit

sealed class WebSocketMessage(val type: String)

data class TerminalOutputMessage(
    val data: String
) : WebSocketMessage("output")

data class WelcomeMessage(
    val message: String,
    val environment: EnvironmentInfo
) : WebSocketMessage("welcome")

data class ErrorMessage(
    val message: String
) : WebSocketMessage("error")

data class LogMessage(
    val timestamp: String,
    val level: String,
    val message: String
) : WebSocketMessage("log")

class PongMessage : WebSocketMessage("pong")

data class EnvironmentInfo(
    val id: String,
    val name: String,
    val template: String,
    val status: String
)

enum class ConnectionState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    ERROR
}

sealed class WebSocketType {
    data class Terminal(val environmentId: String) : WebSocketType()
    data class Logs(val environmentId: String, val follow: Boolean = true) : WebSocketType()
}

class DevPocketWebSocket(
    private val context: Context,
    private val wsType: WebSocketType
) {
    private var webSocket: WebSocket? = null
    private val tokenManager = TokenManager(context)
    private val handler = Handler(Looper.getMainLooper())
    private var pingRunnable: Runnable? = null
    private var reconnectRunnable: Runnable? = null
    private var reconnectAttempts = 0
    private val maxReconnectAttempts = 5
    
    private val client = OkHttpClient.Builder()
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()
    
    private val _connectionState = MutableStateFlow(ConnectionState.DISCONNECTED)
    val connectionState: StateFlow<ConnectionState> = _connectionState.asStateFlow()
    
    private val _messages = MutableSharedFlow<WebSocketMessage>()
    val messages: SharedFlow<WebSocketMessage> = _messages.asSharedFlow()
    
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    fun connect() {
        if (_connectionState.value == ConnectionState.CONNECTING) return
        
        _connectionState.value = ConnectionState.CONNECTING
        
        val token = tokenManager.getToken("access_token")
        if (token == null) {
            _connectionState.value = ConnectionState.ERROR
            return
        }
        
        val url = buildWebSocketURL(token)
        val request = Request.Builder().url(url).build()
        
        webSocket = client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                _connectionState.value = ConnectionState.CONNECTED
                reconnectAttempts = 0
                startPingTimer()
            }
            
            override fun onMessage(webSocket: WebSocket, text: String) {
                handleMessage(text)
            }
            
            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                _connectionState.value = ConnectionState.ERROR
                stopPingTimer()
                scheduleReconnect()
            }
            
            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                _connectionState.value = ConnectionState.DISCONNECTED
                stopPingTimer()
                
                if (code != 1000) { // Not normal closure
                    scheduleReconnect()
                }
            }
        })
    }
    
    private fun buildWebSocketURL(token: String): String {
        val baseUrl = "wss://api.devpocket.io/api/v1/ws"
        return when (wsType) {
            is WebSocketType.Terminal -> 
                "$baseUrl/terminal/${wsType.environmentId}?token=$token"
            is WebSocketType.Logs -> 
                "$baseUrl/logs/${wsType.environmentId}?token=$token&follow=${wsType.follow}"
        }
    }
    
    private fun handleMessage(text: String) {
        scope.launch {
            try {
                val json = JSONObject(text)
                val type = json.getString("type")
                
                val message = when (type) {
                    "output" -> TerminalOutputMessage(
                        data = json.optString("data", "")
                    )
                    
                    "welcome" -> {
                        val envJson = json.optJSONObject("environment")
                        val environment = EnvironmentInfo(
                            id = envJson?.optString("id") ?: "",
                            name = envJson?.optString("name") ?: "",
                            template = envJson?.optString("template") ?: "",
                            status = envJson?.optString("status") ?: ""
                        )
                        WelcomeMessage(
                            message = json.optString("message", ""),
                            environment = environment
                        )
                    }
                    
                    "error" -> ErrorMessage(
                        message = json.optString("message", "Unknown error")
                    )
                    
                    "log" -> LogMessage(
                        timestamp = json.optString("timestamp", ""),
                        level = json.optString("level", "info"),
                        message = json.optString("message", "")
                    )
                    
                    "pong" -> PongMessage()
                    
                    else -> return@launch // Ignore unknown message types
                }
                
                _messages.emit(message)
            } catch (e: Exception) {
                // Log error but don't crash
                e.printStackTrace()
            }
        }
    }
    
    fun sendTerminalInput(command: String) {
        sendMessage(JSONObject().apply {
            put("type", "input")
            put("data", command)
        })
    }
    
    fun resizeTerminal(cols: Int, rows: Int) {
        sendMessage(JSONObject().apply {
            put("type", "resize")
            put("cols", cols)
            put("rows", rows)
        })
    }
    
    fun sendPing() {
        sendMessage(JSONObject().apply {
            put("type", "ping")
        })
    }
    
    private fun sendMessage(message: JSONObject) {
        webSocket?.send(message.toString())
    }
    
    private fun scheduleReconnect() {
        if (reconnectAttempts >= maxReconnectAttempts) {
            return
        }
        
        val delay = (2.0.pow(reconnectAttempts) * 1000).toLong()
        reconnectAttempts++
        
        reconnectRunnable = Runnable {
            connect()
        }
        
        handler.postDelayed(reconnectRunnable!!, delay)
    }
    
    private fun startPingTimer() {
        stopPingTimer()
        pingRunnable = object : Runnable {
            override fun run() {
                sendPing()
                handler.postDelayed(this, 30000) // 30 seconds
            }
        }
        handler.postDelayed(pingRunnable!!, 30000)
    }
    
    private fun stopPingTimer() {
        pingRunnable?.let {
            handler.removeCallbacks(it)
            pingRunnable = null
        }
    }
    
    private fun stopReconnectTimer() {
        reconnectRunnable?.let {
            handler.removeCallbacks(it)
            reconnectRunnable = null
        }
    }
    
    fun disconnect() {
        stopPingTimer()
        stopReconnectTimer()
        webSocket?.close(1000, "User disconnected")
        _connectionState.value = ConnectionState.DISCONNECTED
        scope.cancel()
    }
}

// Usage example for terminal
class TerminalWebSocketManager(context: Context, environmentId: String) {
    private val webSocket = DevPocketWebSocket(
        context, 
        WebSocketType.Terminal(environmentId)
    )
    
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    fun startTerminalSession(
        onOutput: (String) -> Unit,
        onConnectionChange: (ConnectionState) -> Unit,
        onWelcome: (WelcomeMessage) -> Unit
    ) {
        // Collect connection state changes
        scope.launch {
            webSocket.connectionState.collect { state ->
                onConnectionChange(state)
            }
        }
        
        // Collect messages
        scope.launch {
            webSocket.messages.collect { message ->
                when (message) {
                    is TerminalOutputMessage -> onOutput(message.data)
                    is WelcomeMessage -> onWelcome(message)
                    is ErrorMessage -> {
                        // Handle error
                        println("Terminal error: ${message.message}")
                    }
                    else -> {
                        // Handle other message types
                    }
                }
            }
        }
        
        webSocket.connect()
    }
    
    fun sendCommand(command: String) {
        webSocket.sendTerminalInput(command)
    }
    
    fun resizeTerminal(cols: Int, rows: Int) {
        webSocket.resizeTerminal(cols, rows)
    }
    
    fun disconnect() {
        webSocket.disconnect()
        scope.cancel()
    }
}

// Usage example for logs
class LogsWebSocketManager(context: Context, environmentId: String) {
    private val webSocket = DevPocketWebSocket(
        context,
        WebSocketType.Logs(environmentId, follow = true)
    )
    
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    fun startLogStream(
        onLog: (LogMessage) -> Unit,
        onConnectionChange: (ConnectionState) -> Unit
    ) {
        scope.launch {
            webSocket.connectionState.collect { state ->
                onConnectionChange(state)
            }
        }
        
        scope.launch {
            webSocket.messages.collect { message ->
                when (message) {
                    is LogMessage -> onLog(message)
                    is ErrorMessage -> {
                        println("Log stream error: ${message.message}")
                    }
                    else -> {
                        // Handle other message types
                    }
                }
            }
        }
        
        webSocket.connect()
    }
    
    fun disconnect() {
        webSocket.disconnect()
        scope.cancel()
    }
}
```

## Error Handling

### API Error Response Format
```json
{
  "detail": "Error message",
  "status_code": 400,
  "error_code": "INVALID_CREDENTIALS"
}
```

### Common Error Codes
- `401 Unauthorized` - Invalid or expired token
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation error
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

### Error Handling Examples

**iOS (Swift):**
```swift
enum DevPocketError: Error {
    case unauthorized
    case forbidden
    case notFound
    case validationError(String)
    case rateLimitExceeded(retryAfter: Int)
    case serverError
    case networkError
    
    init(from response: HTTPURLResponse, data: Data?) {
        switch response.statusCode {
        case 401:
            self = .unauthorized
        case 403:
            self = .forbidden
        case 404:
            self = .notFound
        case 422:
            let message = data.flatMap { try? JSONDecoder().decode(ErrorResponse.self, from: $0) }?.detail ?? "Validation error"
            self = .validationError(message)
        case 429:
            let retryAfter = Int(response.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
            self = .rateLimitExceeded(retryAfter: retryAfter)
        case 500...599:
            self = .serverError
        default:
            self = .networkError
        }
    }
}
```

**Android (Kotlin):**
```kotlin
sealed class DevPocketError : Exception() {
    object Unauthorized : DevPocketError()
    object Forbidden : DevPocketError()
    object NotFound : DevPocketError()
    data class ValidationError(val details: String) : DevPocketError()
    data class RateLimitExceeded(val retryAfter: Int) : DevPocketError()
    object ServerError : DevPocketError()
    object NetworkError : DevPocketError()
}

fun handleApiError(response: Response<*>): DevPocketError {
    return when (response.code()) {
        401 -> DevPocketError.Unauthorized
        403 -> DevPocketError.Forbidden
        404 -> DevPocketError.NotFound
        422 -> {
            val errorBody = response.errorBody()?.string()
            val details = try {
                JSONObject(errorBody ?: "").getString("detail")
            } catch (e: Exception) {
                "Validation error"
            }
            DevPocketError.ValidationError(details)
        }
        429 -> {
            val retryAfter = response.headers()["Retry-After"]?.toIntOrNull() ?: 60
            DevPocketError.RateLimitExceeded(retryAfter)
        }
        in 500..599 -> DevPocketError.ServerError
        else -> DevPocketError.NetworkError
    }
}
```

## Best Practices

### 1. Token Management
- Store tokens securely using platform-specific secure storage
- Implement automatic token refresh before expiration
- Clear tokens on logout
- Handle token expiration gracefully

### 2. Network Optimization
- Implement request caching for frequently accessed data
- Use pagination for list endpoints
- Compress request/response data when possible
- Implement retry logic with exponential backoff

### 3. WebSocket Management
- Implement automatic reconnection with backoff
- Handle connection state changes
- Queue messages when offline
- Implement heartbeat/ping mechanism

### 4. Security
- Always use HTTPS/WSS in production
- Validate SSL certificates
- Implement certificate pinning for added security
- Never store passwords in plain text

### 5. User Experience
- Show loading states during API calls
- Provide offline functionality where possible
- Cache environment data locally
- Implement pull-to-refresh patterns

## Platform-Specific Examples

### iOS Terminal View Integration

```swift
import UIKit

class TerminalViewController: UIViewController {
    @IBOutlet weak var terminalTextView: UITextView!
    @IBOutlet weak var commandTextField: UITextField!
    
    private var webSocket: TerminalWebSocket?
    private let environmentId: String
    
    init(environmentId: String) {
        self.environmentId = environmentId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTerminal()
        connectWebSocket()
    }
    
    private func setupTerminal() {
        terminalTextView.backgroundColor = .black
        terminalTextView.textColor = .green
        terminalTextView.font = UIFont(name: "Menlo", size: 12)
        terminalTextView.isEditable = false
        
        commandTextField.delegate = self
    }
    
    private func connectWebSocket() {
        webSocket = TerminalWebSocket(environmentId: environmentId)
        
        webSocket?.onReceiveData = { [weak self] data in
            DispatchQueue.main.async {
                self?.terminalTextView.text += data
                self?.scrollToBottom()
            }
        }
        
        webSocket?.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.showError(error.localizedDescription)
            }
        }
        
        webSocket?.connect()
    }
    
    private func scrollToBottom() {
        let bottom = NSMakeRange(terminalTextView.text.count - 1, 1)
        terminalTextView.scrollRangeToVisible(bottom)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension TerminalViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let command = textField.text, !command.isEmpty else { return true }
        
        webSocket?.send(command: command + "\n")
        terminalTextView.text += "> \(command)\n"
        textField.text = ""
        
        return true
    }
}
```

### Android Terminal View Integration

```kotlin
import android.os.Bundle
import android.view.KeyEvent
import android.view.inputmethod.EditorInfo
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class TerminalActivity : AppCompatActivity() {
    private lateinit var terminalTextView: TextView
    private lateinit var commandEditText: EditText
    private lateinit var webSocket: TerminalWebSocket
    
    private val environmentId: String by lazy {
        intent.getStringExtra("environment_id") ?: ""
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_terminal)
        
        terminalTextView = findViewById(R.id.terminalTextView)
        commandEditText = findViewById(R.id.commandEditText)
        
        setupTerminal()
        connectWebSocket()
    }
    
    private fun setupTerminal() {
        terminalTextView.apply {
            setBackgroundColor(Color.BLACK)
            setTextColor(Color.GREEN)
            typeface = Typeface.MONOSPACE
            textSize = 12f
        }
        
        commandEditText.setOnEditorActionListener { _, actionId, event ->
            if (actionId == EditorInfo.IME_ACTION_SEND || 
                event?.keyCode == KeyEvent.KEYCODE_ENTER) {
                sendCommand()
                true
            } else {
                false
            }
        }
    }
    
    private fun connectWebSocket() {
        webSocket = TerminalWebSocket(this, environmentId)
        
        webSocket.onReceiveData = { data ->
            runOnUiThread {
                terminalTextView.append(data)
                scrollToBottom()
            }
        }
        
        webSocket.onError = { error ->
            runOnUiThread {
                showError(error.message ?: "Unknown error")
            }
        }
        
        webSocket.connect()
    }
    
    private fun sendCommand() {
        val command = commandEditText.text.toString()
        if (command.isNotEmpty()) {
            webSocket.send("$command\n")
            terminalTextView.append("> $command\n")
            commandEditText.text.clear()
        }
    }
    
    private fun scrollToBottom() {
        val scrollView = terminalTextView.parent as? ScrollView
        scrollView?.fullScroll(ScrollView.FOCUS_DOWN)
    }
    
    private fun showError(message: String) {
        AlertDialog.Builder(this)
            .setTitle("Error")
            .setMessage(message)
            .setPositiveButton("OK", null)
            .show()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        webSocket.disconnect()
    }
}
```

## Testing

### API Testing with cURL

```bash
# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username_or_email": "test@example.com", "password": "password123"}'

# Get environments
curl -X GET http://localhost:8000/api/v1/environments \
  -H "Authorization: Bearer <jwt-token>"

# Create environment
curl -X POST http://localhost:8000/api/v1/environments \
  -H "Authorization: Bearer <jwt-token>" \
  -H "Content-Type: application/json" \
  -d '{"name": "test-env", "template": "python"}'
```

### WebSocket Testing

**Command Line Testing with wscat:**
```bash
npm install -g wscat

# Test terminal WebSocket
wscat -c "ws://localhost:8000/api/v1/ws/terminal/<environment-id>?token=<jwt-token>"

# Test commands:
> {"type": "input", "data": "ls -la\n"}
> {"type": "resize", "cols": 80, "rows": 24}
> {"type": "ping"}

# Test log streaming WebSocket
wscat -c "ws://localhost:8000/api/v1/ws/logs/<environment-id>?token=<jwt-token>&follow=true"
```

**Advanced Testing with Node.js:**
```javascript
const WebSocket = require('ws');
const jwt = require('jsonwebtoken');

class WebSocketTester {
    constructor(baseUrl, token) {
        this.baseUrl = baseUrl;
        this.token = token;
    }
    
    async testTerminalConnection(environmentId) {
        return new Promise((resolve, reject) => {
            const ws = new WebSocket(`${this.baseUrl}/api/v1/ws/terminal/${environmentId}?token=${this.token}`);
            const timeout = setTimeout(() => {
                ws.close();
                reject(new Error('Connection timeout'));
            }, 5000);
            
            ws.on('open', () => {
                clearTimeout(timeout);
                console.log('Terminal WebSocket connected');
                
                // Send test ping
                ws.send(JSON.stringify({ type: 'ping' }));
            });
            
            ws.on('message', (data) => {
                const message = JSON.parse(data.toString());
                console.log('Received:', message);
                
                if (message.type === 'welcome') {
                    console.log('Welcome message received:', message.environment);
                } else if (message.type === 'pong') {
                    console.log('Ping/pong successful');
                    ws.close();
                    resolve(true);
                }
            });
            
            ws.on('error', (error) => {
                clearTimeout(timeout);
                reject(error);
            });
            
            ws.on('close', (code, reason) => {
                console.log(`Connection closed: ${code} - ${reason}`);
            });
        });
    }
    
    async testLogStreaming(environmentId) {
        return new Promise((resolve, reject) => {
            const ws = new WebSocket(`${this.baseUrl}/api/v1/ws/logs/${environmentId}?token=${this.token}&follow=true`);
            let logCount = 0;
            
            const timeout = setTimeout(() => {
                ws.close();
                resolve(logCount > 0);
            }, 10000);
            
            ws.on('message', (data) => {
                const message = JSON.parse(data.toString());
                if (message.type === 'log') {
                    logCount++;
                    console.log(`Log ${logCount}:`, message.message);
                }
            });
            
            ws.on('error', (error) => {
                clearTimeout(timeout);
                reject(error);
            });
        });
    }
}

// Usage
async function runTests() {
    const tester = new WebSocketTester('ws://localhost:8000', 'your-jwt-token');
    
    try {
        await tester.testTerminalConnection('environment-id');
        console.log('Terminal test passed');
        
        await tester.testLogStreaming('environment-id');
        console.log('Log streaming test passed');
    } catch (error) {
        console.error('Test failed:', error);
    }
}

runTests();
```

**Load Testing with Artillery:**
```yaml
# artillery-websocket-test.yml
config:
  target: 'ws://localhost:8000'
  phases:
    - duration: 60
      arrivalRate: 10
  variables:
    jwt_token: 'your-jwt-token'
    environment_id: 'test-environment'
      
scenarios:
  - name: "Terminal WebSocket Load Test"
    weight: 70
    engine: ws
    beforeRequest: "setAuthToken"
    flow:
      - connect:
          url: "/api/v1/ws/terminal/{{ environment_id }}?token={{ jwt_token }}"
      - send:
          payload:
            type: "ping"
      - wait: 1
      - send:
          payload:
            type: "input"
            data: "echo 'load test'\n"
      - wait: 2
      - disconnect
      
  - name: "Log Streaming Load Test"
    weight: 30
    engine: ws
    flow:
      - connect:
          url: "/api/v1/ws/logs/{{ environment_id }}?token={{ jwt_token }}&follow=true"
      - wait: 5
      - disconnect
```

**Performance Monitoring:**
```javascript
class WebSocketMonitor {
    constructor() {
        this.metrics = {
            connectionsOpened: 0,
            connectionsClosed: 0,
            messagesReceived: 0,
            messagesSent: 0,
            errors: 0,
            avgLatency: 0,
            latencyMeasurements: []
        };
    }
    
    startMonitoring(ws) {
        ws.on('open', () => {
            this.metrics.connectionsOpened++;
            console.log('Metrics:', this.metrics);
        });
        
        ws.on('close', () => {
            this.metrics.connectionsClosed++;
        });
        
        ws.on('message', () => {
            this.metrics.messagesReceived++;
        });
        
        ws.on('error', () => {
            this.metrics.errors++;
        });
    }
    
    measureLatency(ws) {
        const start = Date.now();
        ws.send(JSON.stringify({ type: 'ping', timestamp: start }));
        
        ws.on('message', (data) => {
            const message = JSON.parse(data.toString());
            if (message.type === 'pong' && message.timestamp) {
                const latency = Date.now() - message.timestamp;
                this.metrics.latencyMeasurements.push(latency);
                this.updateAverageLatency();
            }
        });
    }
    
    updateAverageLatency() {
        const measurements = this.metrics.latencyMeasurements;
        this.metrics.avgLatency = measurements.reduce((a, b) => a + b, 0) / measurements.length;
    }
}
```

## WebSocket Message Handling Best Practices

### Message Queuing for Offline Support

**iOS (Swift):**
```swift
class MessageQueue {
    private var pendingMessages: [WebSocketMessage] = []
    private let maxQueueSize = 100
    
    func enqueue(_ message: WebSocketMessage) {
        if pendingMessages.count >= maxQueueSize {
            pendingMessages.removeFirst()
        }
        pendingMessages.append(message)
    }
    
    func flush(to webSocket: DevPocketWebSocket) {
        pendingMessages.forEach { message in
            webSocket.send(message)
        }
        pendingMessages.removeAll()
    }
    
    var count: Int {
        return pendingMessages.count
    }
}
```

**Android (Kotlin):**
```kotlin
class MessageQueue {
    private val pendingMessages = mutableListOf<WebSocketMessage>()
    private val maxQueueSize = 100
    
    fun enqueue(message: WebSocketMessage) {
        if (pendingMessages.size >= maxQueueSize) {
            pendingMessages.removeAt(0)
        }
        pendingMessages.add(message)
    }
    
    fun flush(webSocket: DevPocketWebSocket) {
        pendingMessages.forEach { message ->
            webSocket.send(message)
        }
        pendingMessages.clear()
    }
    
    val count: Int get() = pendingMessages.size
}
```

### Connection Health Monitoring

**iOS (Swift):**
```swift
class ConnectionHealthMonitor {
    private var lastPongReceived: Date?
    private var pingInterval: TimeInterval = 30.0
    private var timeoutInterval: TimeInterval = 10.0
    
    func recordPongReceived() {
        lastPongReceived = Date()
    }
    
    func isConnectionHealthy() -> Bool {
        guard let lastPong = lastPongReceived else {
            return false
        }
        return Date().timeIntervalSince(lastPong) < (pingInterval + timeoutInterval)
    }
    
    func shouldReconnect() -> Bool {
        return !isConnectionHealthy()
    }
}
```

**Android (Kotlin):**
```kotlin
class ConnectionHealthMonitor {
    private var lastPongReceived: Long = 0
    private val pingInterval = 30_000L // 30 seconds
    private val timeoutInterval = 10_000L // 10 seconds
    
    fun recordPongReceived() {
        lastPongReceived = System.currentTimeMillis()
    }
    
    fun isConnectionHealthy(): Boolean {
        if (lastPongReceived == 0L) return false
        return System.currentTimeMillis() - lastPongReceived < (pingInterval + timeoutInterval)
    }
    
    fun shouldReconnect(): Boolean {
        return !isConnectionHealthy()
    }
}
```

## Advanced WebSocket Features

### Binary Data Transmission

For file transfers or binary data:

**iOS (Swift):**
```swift
extension DevPocketWebSocket {
    func sendBinaryData(_ data: Data) {
        webSocket?.send(.data(data)) { error in
            if let error = error {
                print("Binary send error: \(error)")
            }
        }
    }
    
    private func handleBinaryMessage(_ data: Data) {
        // Handle binary data (file chunks, images, etc.)
        // Emit through a separate binary data stream
        binaryDataSubject.send(data)
    }
}
```

**Android (Kotlin):**
```kotlin
fun sendBinaryData(data: ByteArray) {
    webSocket?.send(ByteString.of(*data))
}

private fun handleBinaryMessage(bytes: ByteString) {
    // Handle binary data
    _binaryData.emit(bytes.toByteArray())
}
```

### WebSocket Subprotocol Support

**iOS (Swift):**
```swift
func connectWithSubprotocol(_ subprotocol: String) {
    var request = URLRequest(url: url)
    request.setValue(subprotocol, forHTTPHeaderField: "Sec-WebSocket-Protocol")
    
    webSocket = urlSession.webSocketTask(with: request)
    webSocket?.resume()
}
```

**Android (Kotlin):**
```kotlin
fun connectWithSubprotocol(subprotocol: String) {
    val request = Request.Builder()
        .url(url)
        .addHeader("Sec-WebSocket-Protocol", subprotocol)
        .build()
    
    webSocket = client.newWebSocket(request, listener)
}
```

## Troubleshooting

### Connection Issues Diagnostic

**Diagnostic Checklist:**
1. **Network Connectivity**
   - Test basic internet connectivity
   - Check if API endpoint is reachable
   - Verify DNS resolution

2. **Authentication**
   - Validate JWT token format
   - Check token expiration
   - Verify token permissions

3. **WebSocket Specific**
   - Test WebSocket endpoint accessibility
   - Check for proxy/firewall blocking
   - Verify WebSocket protocol version support

**iOS Diagnostic Implementation:**
```swift
struct DiagnosticResult {
    let test: String
    let passed: Bool
    let details: String?
}

class WebSocketDiagnostics {
    static func runDiagnostics(for environmentId: String) async -> [DiagnosticResult] {
        var results: [DiagnosticResult] = []
        
        // Test 1: Network connectivity
        do {
            let (_, response) = try await URLSession.shared.data(from: URL(string: "https://api.devpocket.io/health")!)
            let httpResponse = response as! HTTPURLResponse
            results.append(DiagnosticResult(
                test: "Network Connectivity",
                passed: httpResponse.statusCode == 200,
                details: "Status: \(httpResponse.statusCode)"
            ))
        } catch {
            results.append(DiagnosticResult(
                test: "Network Connectivity",
                passed: false,
                details: error.localizedDescription
            ))
        }
        
        // Test 2: Token validation
        if let token = TokenManager.getToken(for: "access_token") {
            // Parse JWT to check expiration
            let parts = token.components(separatedBy: ".")
            if parts.count == 3 {
                if let data = Data(base64Encoded: parts[1].padding(toLength: ((parts[1].count + 3) / 4) * 4, withPad: "=", startingAt: 0)),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let exp = json["exp"] as? TimeInterval {
                    let isValid = Date().timeIntervalSince1970 < exp
                    results.append(DiagnosticResult(
                        test: "Token Validity",
                        passed: isValid,
                        details: isValid ? "Valid" : "Expired"
                    ))
                }
            }
        } else {
            results.append(DiagnosticResult(
                test: "Token Availability",
                passed: false,
                details: "No token found"
            ))
        }
        
        // Test 3: WebSocket connection
        do {
            let testWS = DevPocketWebSocket(type: .terminal(environmentId))
            await testWS.connect()
            
            // Wait for connection or timeout
            try await withTimeout(5.0) {
                while testWS.connectionState != .connected {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
            }
            
            testWS.disconnect()
            
            results.append(DiagnosticResult(
                test: "WebSocket Connection",
                passed: true,
                details: "Connection successful"
            ))
        } catch {
            results.append(DiagnosticResult(
                test: "WebSocket Connection",
                passed: false,
                details: error.localizedDescription
            ))
        }
        
        return results
    }
}
```

**Android Diagnostic Implementation:**
```kotlin
data class DiagnosticResult(
    val test: String,
    val passed: Boolean,
    val details: String?
)

class WebSocketDiagnostics {
    companion object {
        suspend fun runDiagnostics(environmentId: String): List<DiagnosticResult> {
            val results = mutableListOf<DiagnosticResult>()
            
            // Test 1: Network connectivity
            try {
                val response = OkHttpClient().newCall(
                    Request.Builder()
                        .url("https://api.devpocket.io/health")
                        .build()
                ).execute()
                
                results.add(DiagnosticResult(
                    test = "Network Connectivity",
                    passed = response.isSuccessful,
                    details = "Status: ${response.code}"
                ))
            } catch (e: Exception) {
                results.add(DiagnosticResult(
                    test = "Network Connectivity",
                    passed = false,
                    details = e.message
                ))
            }
            
            // Test 2: Token validation
            val tokenManager = TokenManager(context)
            val token = tokenManager.getToken("access_token")
            
            if (token != null) {
                try {
                    val parts = token.split(".")
                    if (parts.size == 3) {
                        val payload = String(Base64.decode(parts[1], Base64.DEFAULT))
                        val json = JSONObject(payload)
                        val exp = json.getLong("exp")
                        val isValid = System.currentTimeMillis() / 1000 < exp
                        
                        results.add(DiagnosticResult(
                            test = "Token Validity",
                            passed = isValid,
                            details = if (isValid) "Valid" else "Expired"
                        ))
                    }
                } catch (e: Exception) {
                    results.add(DiagnosticResult(
                        test = "Token Validity",
                        passed = false,
                        details = "Invalid token format"
                    ))
                }
            } else {
                results.add(DiagnosticResult(
                    test = "Token Availability",
                    passed = false,
                    details = "No token found"
                ))
            }
            
            // Test 3: WebSocket connection
            try {
                val testWS = DevPocketWebSocket(context, WebSocketType.Terminal(environmentId))
                testWS.connect()
                
                // Wait for connection with timeout
                withTimeoutOrNull(5000) {
                    while (testWS.connectionState.value != ConnectionState.CONNECTED) {
                        delay(100)
                    }
                }
                
                testWS.disconnect()
                
                results.add(DiagnosticResult(
                    test = "WebSocket Connection",
                    passed = true,
                    details = "Connection successful"
                ))
            } catch (e: Exception) {
                results.add(DiagnosticResult(
                    test = "WebSocket Connection",
                    passed = false,
                    details = e.message
                ))
            }
            
            return results
        }
    }
}
```

### Common Issues and Solutions

1. **Token Expired**
   - **Symptoms:** WebSocket closes with code 1008, "Authentication failed"
   - **Solution:** Implement automatic token refresh before WebSocket connection
   ```swift
   func connectWithTokenRefresh() async {
       if await !isTokenValid() {
           await refreshToken()
       }
       connect()
   }
   ```

2. **WebSocket Connection Drops**
   - **Symptoms:** Frequent disconnections, connection state changes
   - **Solution:** Implement exponential backoff reconnection
   ```swift
   private func scheduleReconnect() {
       let delay = min(pow(2.0, Double(reconnectAttempts)), 60.0)
       DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
           self.connect()
       }
   }
   ```

3. **Rate Limiting**
   - **Symptoms:** Error messages about rate limits
   - **Solution:** Implement message throttling
   ```swift
   class MessageThrottle {
       private var lastMessageTime: Date = Date()
       private let minInterval: TimeInterval = 0.1
       
       func canSendMessage() -> Bool {
           let now = Date()
           if now.timeIntervalSince(lastMessageTime) >= minInterval {
               lastMessageTime = now
               return true
           }
           return false
       }
   }
   ```

4. **SSL Certificate Issues**
   - **Symptoms:** Connection fails with SSL errors
   - **Solution:** Implement certificate pinning
   ```swift
   class CertificatePinner: NSURLSessionDelegate {
       func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
           // Implement certificate validation
       }
   }
   ```

5. **Memory Leaks**
   - **Symptoms:** App memory usage increases over time
   - **Solution:** Proper cleanup and weak references
   ```swift
   class WebSocketManager {
       weak var delegate: WebSocketDelegate?
       
       deinit {
           disconnect()
           // Clean up all references
       }
   }
   ```

## Performance Optimization

### Connection Pooling
```swift
class WebSocketConnectionPool {
    private var connections: [String: DevPocketWebSocket] = [:]
    private let maxConnections = 10
    
    func getConnection(for environmentId: String) -> DevPocketWebSocket {
        if let existing = connections[environmentId] {
            return existing
        }
        
        // Clean up old connections if at limit
        if connections.count >= maxConnections {
            let oldestKey = connections.keys.first!
            connections[oldestKey]?.disconnect()
            connections.removeValue(forKey: oldestKey)
        }
        
        let newConnection = DevPocketWebSocket(type: .terminal(environmentId))
        connections[environmentId] = newConnection
        return newConnection
    }
    
    func closeAll() {
        connections.values.forEach { $0.disconnect() }
        connections.removeAll()
    }
}
```

### Message Batching
```kotlin
class MessageBatcher {
    private val batchSize = 10
    private val batchTimeout = 100L // milliseconds
    private val pendingMessages = mutableListOf<String>()
    private var batchTimer: Timer? = null
    
    fun addMessage(message: String, webSocket: DevPocketWebSocket) {
        synchronized(pendingMessages) {
            pendingMessages.add(message)
            
            if (pendingMessages.size >= batchSize) {
                flushBatch(webSocket)
            } else {
                scheduleBatchFlush(webSocket)
            }
        }
    }
    
    private fun scheduleBatchFlush(webSocket: DevPocketWebSocket) {
        batchTimer?.cancel()
        batchTimer = Timer().apply {
            schedule(batchTimeout) {
                flushBatch(webSocket)
            }
        }
    }
    
    private fun flushBatch(webSocket: DevPocketWebSocket) {
        synchronized(pendingMessages) {
            if (pendingMessages.isNotEmpty()) {
                val batch = pendingMessages.joinToString("\n")
                webSocket.send(batch)
                pendingMessages.clear()
            }
            batchTimer?.cancel()
        }
    }
}
```

## Security Considerations

### Certificate Pinning
```swift
class SecureWebSocketDelegate: NSURLSessionDelegate {
    private let pinnedCertificates: [SecCertificate]
    
    init(pinnedCertificates: [SecCertificate]) {
        self.pinnedCertificates = pinnedCertificates
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let serverCertData = SecCertificateCopyData(serverCertificate)
        
        for pinnedCert in pinnedCertificates {
            let pinnedCertData = SecCertificateCopyData(pinnedCert)
            if CFEqual(serverCertData, pinnedCertData) {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }
        
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}
```

### Token Security
```kotlin
class SecureTokenManager(context: Context) {
    private val keyAlias = "DevPocketWebSocketKey"
    private val keyStore = AndroidKeyStore()
    
    init {
        generateSecretKey()
    }
    
    private fun generateSecretKey() {
        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        
        val keyGenParameterSpec = KeyGenParameterSpec.Builder(
            keyAlias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
        .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
        .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
        .setUserAuthenticationRequired(true)
        .setUserAuthenticationValidityDurationSeconds(300)
        .build()
        
        keyGenerator.init(keyGenParameterSpec)
        keyGenerator.generateKey()
    }
    
    fun encryptToken(token: String): String {
        val secretKey = keyStore.getKey(keyAlias, null) as SecretKey
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey)
        
        val encryptedData = cipher.doFinal(token.toByteArray())
        val iv = cipher.iv
        
        return Base64.encodeToString(iv + encryptedData, Base64.DEFAULT)
    }
    
    fun decryptToken(encryptedToken: String): String {
        val data = Base64.decode(encryptedToken, Base64.DEFAULT)
        val iv = data.sliceArray(0..11)
        val encryptedData = data.sliceArray(12 until data.size)
        
        val secretKey = keyStore.getKey(keyAlias, null) as SecretKey
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        
        val spec = GCMParameterSpec(128, iv)
        cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
        
        val decryptedData = cipher.doFinal(encryptedData)
        return String(decryptedData)
    }
}
```

## Support

For additional support or questions:
- API Documentation: http://localhost:8000/docs
- WebSocket Testing Tool: https://devpocket.io/ws-test
- GitHub Issues: https://github.com/devpocket/mobile-sdk/issues
- Community Discord: https://discord.gg/devpocket
- Email: support@devpocket.io

### Emergency Debugging
If experiencing critical WebSocket issues in production:
1. Enable debug logging: Set environment variable `WEBSOCKET_DEBUG=true`
2. Collect diagnostic information using the diagnostic tools provided
3. Check server logs for rate limiting or authentication errors
4. Verify network connectivity and proxy configurations
5. Test with a minimal WebSocket client to isolate issues