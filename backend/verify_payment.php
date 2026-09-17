<?php

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

// =====================================================
// RAZORPAY SECRET — read from environment variable,
// NEVER hardcoded here (this file may end up on GitHub).
// =====================================================

$keySecret = getenv("RAZORPAY_KEY_SECRET");

if (!$keySecret) {

    http_response_code(500);

    echo json_encode([
        "success" => false,
        "message" => "Server not configured: RAZORPAY_KEY_SECRET missing"
    ]);

    exit;
}

// =====================================================
// READ REQUEST
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
// GET PAYMENT DATA
// =====================================================

$razorpayOrderId = trim(
    $input["razorpay_order_id"] ?? ""
);

$razorpayPaymentId = trim(
    $input["razorpay_payment_id"] ?? ""
);

$razorpaySignature = trim(
    $input["razorpay_signature"] ?? ""
);

// =====================================================
// VALIDATE
// =====================================================

if (
    empty($razorpayOrderId) ||
    empty($razorpayPaymentId) ||
    empty($razorpaySignature)
) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Missing payment details"
    ]);

    exit;
}

// =====================================================
// GENERATE SIGNATURE
// =====================================================

$generatedSignature = hash_hmac(
    "sha256",
    $razorpayOrderId . "|" . $razorpayPaymentId,
    $keySecret
);

// =====================================================
// VERIFY
// =====================================================

if (
    !hash_equals(
        $generatedSignature,
        $razorpaySignature
    )
) {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "Payment verification failed"
    ]);

    exit;
}

// =====================================================
// PAYMENT VERIFIED
// =====================================================

echo json_encode([
    "success" => true,
    "message" => "Payment verified successfully",

    "razorpay_order_id" => $razorpayOrderId,

    "razorpay_payment_id" => $razorpayPaymentId,

    "verified" => true
]);