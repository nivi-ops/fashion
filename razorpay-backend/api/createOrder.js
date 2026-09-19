// =====================================================
// CREATE ORDER — Vercel Serverless Function
// Calls Razorpay's Orders API using the Key ID + Key Secret
// (both stored as Vercel Environment Variables, never in code).
// =====================================================

export default async function handler(req, res) {
  // CORS — allow the Flutter app to call this from anywhere
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, message: 'Method not allowed' });
  }

  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;

  if (!keyId || !keySecret) {
    return res.status(500).json({
      success: false,
      message: 'Server not configured: Razorpay keys missing',
    });
  }

  const { amount, currency } = req.body || {};

  if (!amount || amount <= 0) {
    return res.status(400).json({ success: false, message: 'Invalid amount' });
  }

  const receipt = 'rcpt_' + Date.now();

  try {
    const authHeader =
      'Basic ' + Buffer.from(`${keyId}:${keySecret}`).toString('base64');

    const razorpayRes = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: authHeader,
      },
      body: JSON.stringify({
        amount,
        currency: currency || 'INR',
        receipt,
        payment_capture: 1,
      }),
    });

    const data = await razorpayRes.json();

    if (!razorpayRes.ok || !data.id) {
      return res.status(502).json({
        success: false,
        message: data?.error?.description || 'Failed to create Razorpay order',
      });
    }

    return res.status(200).json({
      success: true,
      order_id: data.id,
      amount: data.amount,
      currency: data.currency,
    });
  } catch (err) {
    return res.status(502).json({
      success: false,
      message: 'Could not reach Razorpay: ' + err.message,
    });
  }
}