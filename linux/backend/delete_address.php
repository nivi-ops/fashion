<?php
// delete_address.php
// Deletes a saved address by id.
// Expects a JSON POST body:
// {
//   "id": "a1734567890",       // required
//   "user_id": "9876543210"    // optional — for ownership check
// }
// Responds: {"success": true} or {"success": false, "error": "..."}

header('Content-Type: application/json');
require_once 'db.php'; // must expose mysqli connection as $conn

$data = json_decode(file_get_contents('php://input'), true);

if (!$data || empty($data['id'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing required field: id.']);
    exit;
}

$id      = $data['id'];
$user_id = $data['user_id'] ?? null; // optional ownership check

if ($user_id !== null) {
    $stmt = $conn->prepare('DELETE FROM addresses WHERE id = ? AND user_id = ?');
    $stmt->bind_param('ss', $id, $user_id);
} else {
    $stmt = $conn->prepare('DELETE FROM addresses WHERE id = ?');
    $stmt->bind_param('s', $id);
}

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        echo json_encode(['success' => true]);
    } else {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Address not found.']);
    }
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $stmt->error]);
}

$stmt->close();
$conn->close();