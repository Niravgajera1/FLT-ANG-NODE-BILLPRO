const getOTPEmailTemplate = (otp, purposeStr, expiryMinutes) => {
  return `
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BillPro OTP Verification</title>
    <style>
      body {
        font-family: 'Inter', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        background-color: #f4f7f6;
        margin: 0;
        padding: 0;
        color: #333333;
      }
      .container {
        max-width: 600px;
        margin: 40px auto;
        background-color: #ffffff;
        border-radius: 8px;
        overflow: hidden;
        box-shadow: 0 4px 15px rgba(0,0,0,0.05);
      }
      .header {
        background-color: #4f46e5;
        padding: 30px 20px;
        text-align: center;
      }
      .header h1 {
        color: #ffffff;
        margin: 0;
        font-size: 24px;
        font-weight: 600;
        letter-spacing: 1px;
      }
      .content {
        padding: 40px 30px;
        text-align: center;
      }
      .content p {
        font-size: 16px;
        line-height: 1.6;
        color: #555555;
        margin-bottom: 25px;
      }
      .otp-box {
        background-color: #f8fafc;
        border: 2px dashed #cbd5e1;
        border-radius: 6px;
        padding: 15px;
        display: inline-block;
        margin-bottom: 30px;
      }
      .otp-code {
        font-size: 32px;
        font-weight: 700;
        color: #0f172a;
        letter-spacing: 5px;
        margin: 0;
      }
      .footer {
        background-color: #f8fafc;
        padding: 20px;
        text-align: center;
        font-size: 13px;
        color: #64748b;
        border-top: 1px solid #e2e8f0;
      }
      .footer p {
        margin: 5px 0;
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <h1>BillPro</h1>
      </div>
      <div class="content">
        <h2>Authentication Request</h2>
        <p>You requested a one-time password (OTP) for <strong>${purposeStr}</strong>. Please use the verification code below to proceed.</p>
        
        <div class="otp-box">
          <p class="otp-code">${otp}</p>
        </div>
        
        <p>This code is valid for <strong>${expiryMinutes} minutes</strong>. Please do not share this code with anyone.</p>
        <p>If you didn't request this code, you can safely ignore this email.</p>
      </div>
      <div class="footer">
        <p>&copy; ${new Date().getFullYear()} BillPro. All rights reserved.</p>
        <p>This is an automated message, please do not reply.</p>
      </div>
    </div>
  </body>
  </html>
  `;
};

module.exports = {
  getOTPEmailTemplate,
};
