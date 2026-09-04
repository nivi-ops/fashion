<?php
// update_address.php
// Updates an existing saved address, matched by id.
// Expects a JSON POST body:
// {
//   "id": "a1734567890",           // required — which address to update
//   "user_id": "9876543210",       // optional — for ownership check
//   "label": "Home",
//   "address_line": "12, Gandhi Street",
//   "city": "Chennai",
//   "pincode": "600001",
//   "phone": "9876543210",
//   "latitude": 13.0827,
//   "longitude": 80.2707
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
$user_id     = $data['user_id'] ?? null; // optional ownership check
$label       = $data['label'];
$addressLine = $data['address_line'];
$city        = $data['city'];
$pincode     = $data['pincode'];
$phone       = $data['phone']       ?? null;
$latitude    = isset($data['latitude'])  ? (float)$data['latitude']  : null;
$longitude   = isset($data['longitude']) ? (float)$data['longitude'] : null;

// First check the address actually exists (and belongs to this user,
// if a user_id was sent) before updating.
if ($user_id !== null) {
    $check = $conn->prepare('SELECT id FROM addresses WHERE id = ? AND user_id = ?');
    $check->bind_param('ss', $id, $user_id);
} else {
    $check = $conn->prepare('SELECT id FROM addresses WHERE id = ?');
    $check->bind_param('s', $id);
}
$check->execute();
$exists = $check->get_result()->num_rows > 0;
$check->close();

if (!$exists) {
    http_response_code(404);
    echo json_encode(['success' => false, 'error' => 'Address not found.']);
    $conn->close();
    exit;
}

$stmt = $conn->prepare(
    'UPDATE addresses
     SET label = ?, address_line = ?, city = ?, pincode = ?, phone = ?, latitude = ?, longitude = ?
     WHERE id = ?'
);
$stmt->bind_param(
    'sssssdds',
    $label, $addressLine, $city, $pincode, $phone, $latitude, $longitude, $id
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