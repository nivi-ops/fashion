<?php
// upload_product.php
// Admin panel product upload endpoint.
// Expects JSON POST body (from Flutter app) OR multipart form-data if an image file is sent.

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight (some HTTP clients send OPTIONS first)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'db.php'; // must provide $conn (mysqli connection)

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Database connection failed: " . $conn->connect_error]);
    exit();
}

// ---- Read input ----
// Supports both JSON body (Flutter http.post with jsonEncode) and form-data (if image file sent)
$input = [];

if (isset($_SERVER['CONTENT_TYPE']) && strpos($_SERVER['CONTENT_TYPE'], 'application/json') !== false) {
    $input = json_decode(file_get_contents("php://input"), true);
    if ($input === null) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "Invalid JSON received"]);
        exit();
    }
} else {
    // multipart/form-data (used when uploading an image file directly)
    $input = $_POST;
}

// ---- Required fields ----
$name        = trim($input['name'] ?? '');
$category    = trim($input['category'] ?? '');
$description = trim($input['description'] ?? '');
$stockStatus = trim($input['stock_status'] ?? 'Available');
$visible     = trim($input['visible'] ?? 'yes');

// ---- Optional array/JSON fields ----
// Product highlights sent as JSON array string, e.g. ["Pure cotton","Hand embroidered"]
$highlightsRaw = $input['highlights'] ?? '[]';
$highlights = is_array($highlightsRaw) ? $highlightsRaw : json_decode($highlightsRaw, true);
if (!is_array($highlights)) { $highlights = []; }
$highlightsJson = json_encode($highlights);

// Price tags sent as JSON array of {tag, price}, e.g. [{"tag":"S","price":400}]
$priceTagsRaw = $input['price_tags'] ?? '[]';
$priceTags = is_array($priceTagsRaw) ? $priceTagsRaw : json_decode($priceTagsRaw, true);
if (!is_array($priceTags)) { $priceTags = []; }
$priceTagsJson = json_encode($priceTags);

// Base price (fallback if no price tags used)
$price = isset($input['price']) ? floatval($input['price']) : 0;

// ---- Validation ----
if ($name === '' || $description === '') {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Product name and description are required"]);
    exit();
}

// ---- Image handling ----
// Case 1: image uploaded as a file (multipart/form-data with key "image")
// Case 2: image_url passed directly (e.g. already-hosted image link)
$imagePath = trim($input['image_url'] ?? '');

if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
    $uploadDir = __DIR__ . '/uploads/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }
    $ext = pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION);
    $safeName = uniqid('product_', true) . '.' . $ext;
    $destination = $uploadDir . $safeName;

    if (move_uploaded_file($_FILES['image']['tmp_name'], $destination)) {
        $imagePath = 'uploads/' . $safeName;
    } else {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Image upload failed"]);
        exit();
    }
}

// ---- Insert into database ----
$stmt = $conn->prepare(
    "INSERT INTO products (name, category, description, highlights, price_tags, price, stock_status, visible, image, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())"
);

if (!$stmt) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Prepare failed: " . $conn->error]);
    exit();
}

$stmt->bind_param(
    "sssssdsss",
    $name,
    $category,
    $description,
    $highlightsJson,
    $priceTagsJson,
    $price,
    $stockStatus,
    $visible,
    $imagePath
);

if ($stmt->execute()) {
    echo json_encode([
        "success" => true,
        "message" => "Product uploaded successfully",
        "product_id" => $stmt->insert_id
    ]);
} else {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Insert failed: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>