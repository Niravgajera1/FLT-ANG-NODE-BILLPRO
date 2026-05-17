const getOTPEmailTemplate = (otp, purpose, expiryMinutes) => {
  let title = 'BillPro Verification';
  let heading = 'Verification Required';
  let description = `Please use the code below to complete your request.`;
  let warningMessage = 'If you did not make this request, you can safely ignore this email.';
  let themeColor = '#4f46e5'; // default Indigo

  if (purpose === 'registration') {
    title = 'Welcome to BillPro!';
    heading = 'Verify Your Email';
    description = 'Thank you for signing up with BillPro. To activate your account and verify your email address, please use the one-time verification code below:';
    warningMessage = 'If you did not register for a BillPro account, you can safely ignore this email.';
    themeColor = '#10b981'; // Emerald Green
  } else if (purpose === 'login') {
    title = 'BillPro Login Verification';
    heading = 'Login Verification Code';
    description = 'We detected a login attempt for your BillPro account. To verify your identity and complete the login, please use the verification code below:';
    warningMessage = 'If you did not request this login code, please secure your account immediately by changing your password.';
    themeColor = '#4f46e5'; // Indigo
  } else if (purpose === 'password_reset') {
    title = 'BillPro Password Reset';
    heading = 'Reset Your Password';
    description = 'You requested a password reset for your BillPro account. Use the one-time password (OTP) code below to proceed with setting up a new password:';
    warningMessage = 'If you did not request a password reset, you can safely ignore this email. Your password will remain secure and unchanged.';
    themeColor = '#f59e0b'; // Amber/Orange
  }

  return `
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
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
        background-color: ${themeColor};
        padding: 30px 20px;
        text-align: center;
        transition: background-color 0.3s ease;
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
      .content h2 {
        color: #0f172a;
        font-size: 20px;
        font-weight: 600;
        margin-top: 0;
        margin-bottom: 15px;
      }
      .content p {
        font-size: 15px;
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
        <h2>${heading}</h2>
        <p>${description}</p>
        
        <div class="otp-box">
          <p class="otp-code">${otp}</p>
        </div>
        
        <p>This code is valid for <strong>${expiryMinutes} minutes</strong>. Please do not share this code with anyone.</p>
        <p style="font-size: 13px; color: #64748b; font-style: italic;">${warningMessage}</p>
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
