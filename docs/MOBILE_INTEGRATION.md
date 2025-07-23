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

The WebSocket connection provides real-time terminal access to development environments.

### WebSocket URL Format
```
wss://api.devpocket.io/api/v1/ws/terminal/{environment_id}?token={jwt_token}
```

### Message Protocol

**Client to Server Messages:**
```json
{
  "type": "input",
  "data": "ls -la\n"
}
```

**Server to Client Messages:**
```json
{
  "type": "output",
  "data": "total 64\ndrwxr-xr-x  10 user user 4096 Jan 15 10:00 .\n"
}
```

**Resize Terminal:**
```json
{
  "type": "resize",
  "cols": 80,
  "rows": 24
}
```

### WebSocket Implementation

**iOS (Swift) - WebSocket Client:**
```swift
import Foundation

class TerminalWebSocket: NSObject {
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private let environmentId: String
    
    var onReceiveData: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?
    
    init(environmentId: String) {
        self.environmentId = environmentId
        super.init()
    }
    
    func connect() {
        guard let token = TokenManager.getToken(for: "access_token"),
              let url = URL(string: "wss://api.devpocket.io/api/v1/ws/terminal/\(environmentId)?token=\(token)") else {
            return
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        self.urlSession = session
        
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        receiveMessage()
        onConnect?()
    }
    
    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        onDisconnect?()
    }
    
    func send(command: String) {
        let message = ["type": "input", "data": command]
        guard let data = try? JSONSerialization.data(withJSONObject: message) else { return }
        
        webSocket?.send(.data(data)) { [weak self] error in
            if let error = error {
                self?.onError?(error)
            }
        }
    }
    
    func resize(cols: Int, rows: Int) {
        let message = ["type": "resize", "cols": cols, "rows": rows] as [String : Any]
        guard let data = try? JSONSerialization.data(withJSONObject: message) else { return }
        
        webSocket?.send(.data(data)) { _ in }
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let type = json["type"] as? String,
                       type == "output",
                       let output = json["data"] as? String {
                        self?.onReceiveData?(output)
                    }
                case .string(let text):
                    print("Received string: \(text)")
                @unknown default:
                    break
                }
                self?.receiveMessage()
                
            case .failure(let error):
                self?.onError?(error)
            }
        }
    }
}

extension TerminalWebSocket: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        onDisconnect?()
    }
}
```

**Android (Kotlin) - WebSocket Client:**
```kotlin
import okhttp3.*
import okio.ByteString
import org.json.JSONObject

class TerminalWebSocket(
    private val context: Context,
    private val environmentId: String
) {
    private var webSocket: WebSocket? = null
    private val client = OkHttpClient()
    private val tokenManager = TokenManager(context)
    
    var onReceiveData: ((String) -> Unit)? = null
    var onError: ((Throwable) -> Unit)? = null
    var onConnect: (() -> Unit)? = null
    var onDisconnect: (() -> Unit)? = null
    
    fun connect() {
        val token = tokenManager.getToken("access_token") ?: return
        val url = "wss://api.devpocket.io/api/v1/ws/terminal/$environmentId?token=$token"
        
        val request = Request.Builder()
            .url(url)
            .build()
        
        webSocket = client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                onConnect?.invoke()
            }
            
            override fun onMessage(webSocket: WebSocket, text: String) {
                try {
                    val json = JSONObject(text)
                    if (json.getString("type") == "output") {
                        val data = json.getString("data")
                        onReceiveData?.invoke(data)
                    }
                } catch (e: Exception) {
                    onError?.invoke(e)
                }
            }
            
            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                onError?.invoke(t)
            }
            
            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                onDisconnect?.invoke()
            }
        })
    }
    
    fun send(command: String) {
        val message = JSONObject().apply {
            put("type", "input")
            put("data", command)
        }
        webSocket?.send(message.toString())
    }
    
    fun resize(cols: Int, rows: Int) {
        val message = JSONObject().apply {
            put("type", "resize")
            put("cols", cols)
            put("rows", rows)
        }
        webSocket?.send(message.toString())
    }
    
    fun disconnect() {
        webSocket?.close(1000, "User disconnected")
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

You can test WebSocket connections using `wscat`:

```bash
npm install -g wscat

# Connect to WebSocket
wscat -c "ws://localhost:8000/api/v1/ws/terminal/<environment-id>?token=<jwt-token>"

# Send commands
> {"type": "input", "data": "ls -la\n"}
```

## Troubleshooting

### Common Issues

1. **Token Expired**
   - Solution: Implement automatic token refresh
   - Use refresh token to get new access token

2. **WebSocket Connection Drops**
   - Solution: Implement reconnection logic with exponential backoff
   - Check network connectivity before reconnecting

3. **Rate Limiting**
   - Solution: Implement request queuing
   - Show user-friendly message with retry time

4. **SSL Certificate Issues**
   - Solution: Ensure proper certificate validation
   - Use certificate pinning in production

## Support

For additional support or questions:
- API Documentation: http://localhost:8000/docs
- GitHub Issues: https://github.com/devpocket/mobile-sdk/issues
- Email: support@devpocket.io