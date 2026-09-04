<?php
// add_address.php
// Creates a new saved delivery address.
// Expects a JSON POST body (matches how Flutter's http package posts):
// {
//   "id": "a1734567890",
//   "user_id": "9876543210",      // optional — AppState.instance.userId
//   "label": "Home",
//   "address_line": "12, Gandhi Street",
//   "city": "Chennai",
//   "pincode": "600001",
//   "phone": "9876543210",        // optional
//   "latitude": 13.0827,          // optional
//   "longitude": 80.2707          // optional
// }
// Responds: {"success": true, "address": {...}} or {"success": false, "error": "..."}

header('Content-Type: application/json');
require_once 'db.php'; // must expose mysqli connection as $conn

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || empty($data['id']) || empty($data['label']) ||
    empty($data['address_line']) || empty($data['city']) || empty($data['pincode'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing required fields (id, label, address_line, city, pincode).']);
    exit;
}

$id          = $data['id'];
$user_id     = $data['user_id']     ?? null;
$label       = $data['label'];
$addressLine = $data['address_line'];
$city        = $data['city'];
$pincode     = $data['pincode'];
$phone       = $data['phone']       ?? null;
$latitude    = isset($data['latitude'])  ? (float)$data['latitude']  : null;
$longitude   = isset($data['longitude']) ? (float)$data['longitude'] : null;

$stmt = $conn->prepare(
    'INSERT INTO addresses (id, user_id, label, address_line, city, pincode, phone, latitude, longitude)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
);
$stmt->bind_param(
    'sssssssdd',
    $id, $user_id, $label, $addressLine, $city, $pincode, $phone, $latitude, $longitude
);

if ($stmt->execute()) {
    echo json_encode([
        'success' => true,
        'address' => [
            'id' => $id,
            'label' => $label,
            'address_line' => $addressLine,
            'city' => $city,
            'pincode' => $pincode,
            'phone' => $phone,
            'latitude' => $latitude,
            'longitude' => $longitude,
        ],
    ]);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $stmt->error]);
}

$stmt->close();
$conn->close();