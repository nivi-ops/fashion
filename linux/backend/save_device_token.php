<?php
header('Content-Type: application/json');
require 'db.php';

$token = $_POST['token'] ?? '';
if (!$token) {
    echo json_encode(['success' => false, 'message' => 'No token']);
    exit;
}

$stmt = $conn->prepare("INSERT INTO device_tokens (token) VALUES (?) ON DUPLICATE KEY UPDATE token = token");
$stmt->bind_param("s", $token);
$stmt->execute();

echo json_encode(['success' => true]);