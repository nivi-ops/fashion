<?php
require_once 'db.php';
header('Content-Type: application/json');

// ✅ FIX: db.php already handles connection (works on both local XAMPP
// and Railway, since db.php has localhost/root fallback + Railway env var
// support built in). No need for separate getenv() logic here.

$target = $_POST['target'] ?? '';

// Table/column names - unga schema la vera peru irundha idha maathunga:
// orders table:   id, name, mobile, product, amount, status, created_at, source, measurement, voice_note, notes
// contacts table: id, name, phone, email, service, message, created_at

try {
    switch ($target) {

        case 'orders_all':
            // Orders page + Revenue page "Clear" button idha call pannum
            $conn->query("DELETE FROM orders");
            break;

        case 'orders_custom':
            // Customized Order page "Clear" button
            $conn->query("DELETE FROM orders WHERE source = 'custom-order'");
            break;

        case 'contacts_boutique':
            // Boutique Contact Form page "Clear" button
            $conn->query("DELETE FROM contacts WHERE service IS NULL OR service NOT LIKE '%catering%'");
            break;

        case 'contacts_catering':
            // Catering Contact Form page "Clear" button
            $conn->query("DELETE FROM contacts WHERE service LIKE '%catering%'");
            break;

        case 'notifications_all':
            // Send Notification page "Clear All Notifications" button
            $conn->query("DELETE FROM notifications");
            break;

        case 'data_requests_all':
            // "Request My Data Submissions" section — Clear Data Requests button
            $conn->query("DELETE FROM data_requests");
            break;

        case 'grievances_all':
            // "Grievance Redressal Complaints" section — Clear Grievances button
            $conn->query("DELETE FROM grievances");
            break;

        case 'deactivated_all':
            // "De-activated Accounts" section — Clear De-activated button
            $conn->query("DELETE FROM deactivated_accounts");
            break;

        case 'deleted_accounts_all':
            // "Deleted Accounts" section — Clear Deleted button
            $conn->query("DELETE FROM deleted_accounts");
            break;

        case 'all_demo_data':
            // Dashboard "Clear All Demo Data" button — orders + contacts rendayum clear pannum
            // Products table touch pannadhu.
            $conn->query("DELETE FROM orders");
            $conn->query("DELETE FROM contacts");
            break;

        default:
            echo json_encode(['status' => 'error', 'message' => 'Invalid target']);
            exit;
    }

    if ($conn->error) {
        echo json_encode(['status' => 'error', 'message' => $conn->error]);
    } else {
        echo json_encode(['status' => 'success']);
    }

} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}

$conn->close();