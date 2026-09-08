<?php
header('Content-Type: application/json');
require 'db.php'; // uses $conn (mysqli)

$title   = isset($_POST['title']) ? trim($_POST['title']) : '';
$message = isset($_POST['message']) ? trim($_POST['message']) : '';
$type    = isset($_POST['type']) ? trim($_POST['type']) : 'general';

// Table's type column is ENUM('order','promotion','class','general')
$allowedTypes = ['order', 'promotion', 'class', 'general'];
if (!in_array($type, $allowedTypes)) {
    $type = 'general';
}

if ($title === '' || $message === '') {
    echo json_encode(['status' => 'error', 'message' => 'Title and Message are required']);
    exit;
}

$stmt = $conn->prepare("INSERT INTO notifications (title, message, type, created_at) VALUES (?, ?, ?, NOW())");
if (!$stmt) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare failed: ' . $conn->error]);
    exit;
}

$stmt->bind_param("sss", $title, $message, $type);

if ($stmt->execute()) {
    $insertId = $stmt->insert_id;

    // ---- Send the actual push via FCM, directly from PHP (no Cloud Function needed) ----
    $pushResult = sendFcmPush($title, $message, $type);

    echo json_encode([
        'status' => 'success',
        'id' => $insertId,
        'push' => $pushResult, // for debugging; remove later if you want
    ]);
} else {
    echo json_encode(['status' => 'error', 'message' => $stmt->error]);
}

$stmt->close();
$conn->close();

// =====================================================================
// FCM HTTP v1 push helper — uses a service account JSON key to get an
// OAuth2 access token (via a signed JWT), then calls the FCM v1 send
// endpoint targeting the topic that matches $type. No paid plan, no
// external libraries — just PHP's built-in openssl + curl.
// =====================================================================
function sendFcmPush($title, $body, $type) {
    // 🔧 EDIT THIS: absolute path to the service account JSON you downloaded
    $serviceAccountPath = __DIR__ . '/firebase-service-account.json';

    if (!file_exists($serviceAccountPath)) {
        return ['ok' => false, 'error' => 'service account file not found'];
    }

    $serviceAccount = json_decode(file_get_contents($serviceAccountPath), true);
    $projectId = $serviceAccount['project_id'];

    $accessToken = getFcmAccessToken($serviceAccount);
    if (!$accessToken) {
        return ['ok' => false, 'error' => 'failed to get access token'];
    }

    $topicMap = [
        'general'   => 'general_announcements',
        'order'     => 'order_updates',
        'promotion' => 'promotions',
        'class'     => 'class_reminders',
    ];
    $topic = $topicMap[$type] ?? $topicMap['general'];

    $payload = [
        'message' => [
            'topic' => $topic,
            'notification' => [
                'title' => $title,
                'body'  => $body,
            ],
            'data' => [
                'type' => $type,
            ],
        ],
    ];

    $ch = curl_init("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send");
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Authorization: Bearer {$accessToken}",
        "Content-Type: application/json",
    ]);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlErr = curl_error($ch);
    curl_close($ch);

    return [
        'ok' => $httpCode === 200,
        'http_code' => $httpCode,
        'response' => $response,
        'curl_error' => $curlErr,
    ];
}

// Builds + signs a JWT with the service account's private key, exchanges
// it for a short-lived OAuth2 access token. Pure PHP, uses the openssl
// extension (built into PHP by default — no composer install needed).
function getFcmAccessToken($serviceAccount) {
    $now = time();
    $header = ['alg' => 'RS256', 'typ' => 'JWT'];
    $claims = [
        'iss'   => $serviceAccount['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud'   => 'https://oauth2.googleapis.com/token',
        'iat'   => $now,
        'exp'   => $now + 3600,
    ];

    $b64 = function ($data) {
        return rtrim(strtr(base64_encode(json_encode($data)), '+/', '-_'), '=');
    };

    $headerEncoded = $b64($header);
    $claimsEncoded = $b64($claims);
    $signingInput = "{$headerEncoded}.{$claimsEncoded}";

    $privateKey = openssl_pkey_get_private($serviceAccount['private_key']);
    if (!$privateKey) {
        return null;
    }

    openssl_sign($signingInput, $signature, $privateKey, 'SHA256');
    $signatureEncoded = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');

    $jwt = "{$signingInput}.{$signatureEncoded}";

    $ch = curl_init('https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion'  => $jwt,
    ]));
    $response = curl_exec($ch);
    curl_close($ch);

    $result = json_decode($response, true);
    return $result['access_token'] ?? null;
}