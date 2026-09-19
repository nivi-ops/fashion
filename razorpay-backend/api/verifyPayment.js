// =====================================================
// VERIFY PAYMENT — Vercel Serverless Function
// Confirms the payment was genuinely signed by Razorpay using
// HMAC-SHA256 with the Key Secret (never exposed to the app).
// =====================================================

import crypto from 'crypto';

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, message: 'Method not allowed' });
  }

  const keySecret = process.env.RAZORPAY_KEY_SECRET;

  if (!keySecret) {
    return res.status(500).json({
      success: false,
      message: 'Server not configured: RAZORPAY_KEY_SECRET missing',
    });
  }

  const {
    razorpay_order_id: razorpayOrderId,
    razorpay_payment_id: razorpayPaymentId,
    razorpay_signature: razorpaySignature,
  } = req.body || {};

  if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
    return res.status(400).json({ success: false, message: 'Missing payment details' });
  }

  const generatedSignature = crypto
    .createHmac('sha256', keySecret)
    .update(`${razorpayOrderId}|${razorpayPaymentId}`)
    .digest('hex');

  const generatedBuf = Buffer.from(generatedSignature);
  const receivedBuf = Buffer.from(razorpaySignature);

  const isValid =
    generatedBuf.length === receivedBuf.length &&
    crypto.timingSafeEqual(generatedBuf, receivedBuf);

  if (!isValid) {
    return res.status(400).json({
      success: false,
      message: 'Payment verification failed — signature mismatch',
    });
  }

  return res.status(200).json({
    success: true,
    message: 'Payment verified successfully',
    razorpay_order_id: razorpayOrderId,
    razorpay_payment_id: razorpayPaymentId,
    verified: true,
  });
}