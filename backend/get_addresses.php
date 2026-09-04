<?php
// get_addresses.php
// Returns saved addresses as a JSON array (matches get_products.php's
// response shape — a raw JSON list, which is what fetchProducts()-style
// code in api_service.dart expects).
//
// Optional query param: ?user_id=9876543210
// If provided, only that user's addresses are returned. If omitted,
// ALL addresses are returned (fine while the app has no login wired —
// tighten this once user_id is always sent).

header('Content-Type: application/json');
require_once 'db.php'; // must expose mysqli connection as $conn

$userId = isset($_GET['user_id']) ? $_GET['user_id'] : null;

if ($userId !== null) {
    $stmt = $conn->prepare('SELECT * FROM addresses WHERE user_id = ? ORDER BY created_at DESC');
    $stmt->bind_param('s', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
} else {
    $result = $conn->query('SELECT * FROM addresses ORDER BY created_at DESC');
}

$addresses = [];
while ($row = $result->fetch_assoc()) {
    $addresses[] = [
        'id' => $row['id'],
        'label' => $row['label'],
        'address_line' => $row['address_line'],
        'city' => $row['city'],
        'pincode' => $row['pincode'],
        'phone' => $row['phone'],
        'latitude' => $row['latitude'] !== null ? (float)$row['latitude'] : null,
        'longitude' => $row['longitude'] !== null ? (float)$row['longitude'] : null,
    ];
}

echo json_encode($addresses);

if (isset($stmt)) {
    $stmt->close();
}
$conn->close();