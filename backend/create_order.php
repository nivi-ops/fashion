<?php

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

// =====================================================
// RAZORPAY KEYS
// =====================================================
// IMPORTANT:
// Secret key Flutter code-la podaadha.
// PHP server-la mattum vechuko.
$keyId = "YOUR_RAZORPAY_KEY_ID";
$keySecret = "YOUR_RAZORPAY_KEY_SECRET";

// =====================================================
// READ JSON FROM FLUTTER
// =====================================================

$input = json_decode(file_get_contents("php://input"), true);

if (!$input) {
    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Invalid JSON request"
    ]);

    exit;
}

// =====================================================
// GET AMOUNT
// =====================================================

$amount = isset($input["amount"])
    ? (float)$input["amount"]
    : 0;

if ($amount <= 0) {
    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Invalid amount"
    ]);

    exit;
}

// Razorpay amount = paise
$amountPaise = (int)round($amount * 100);

// =====================================================
// RECEIPT
// =====================================================

$receipt = "SS_" . date("YmdHis") . "_" . rand(1000, 9999);

// =====================================================
// RAZORPAY API
// =====================================================

$url = "https://api.razorpay.com/v1/orders";

$data = [
    "amount" => $amountPaise,
    "currency" => "INR",
    "receipt" => $receipt,
    "notes" => [
        "source" => "safeguard_app"
    ]
];

$ch = curl_init($url);

curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);

curl_setopt($ch, CURLOPT_USERPWD, $keyId . ":" . $keySecret);

curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Content-Type: application/json"
]);

curl_setopt(
    $ch,
    CURLOPT_POSTFIELDS,
    json_encode($data)
);

$response = curl_exec($ch);

$httpCode = curl_getinfo(
    $ch,
    CURLINFO_HTTP_CODE
);

$curlError = curl_error($ch);

curl_close($ch);

// =====================================================
// CURL ERROR
// =====================================================

if ($response === false || !empty($curlError)) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Razorpay connection failed",
        "error" => $curlError
    ]);

    exit;
}

// =====================================================
// RAZORPAY RESPONSE
// =====================================================

$result = json_decode($response, true);

if ($httpCode >= 200 && $httpCode < 300) {

    echo json_encode([
        "success" => true,

        "order_id" => $result["id"],

        "amount" => $result["amount"],

        "currency" => $result["currency"],

        "receipt" => $result["receipt"],

        "status" => $result["status"],

        // Flutter needs Key ID for Checkout
        "key_id" => $keyId
    ]);

    exit;
}

// =====================================================
// RAZORPAY ERROR
// =====================================================

http_response_code($httpCode);

echo json_encode([
    "success" => false,
    "message" => "Razorpay order creation failed",
    "razorpay_response" => $result
]);