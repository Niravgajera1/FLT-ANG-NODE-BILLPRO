const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../users/user.model');
const { storeOTP, verifyOTP, sendOTPViaSMS } = require('../../utils/otpService');
const { blacklistToken } = require('../../config/redis');
const { createAuditLog } = require('../../middleware/auditLog');
const logger = require('../../utils/logger');

// ─── Token Generation ─────────────────────────────────────────────────────────

const generateTokens = (user) => {
  const payload = {
    id: user._id,
    email: user.email,
    role: user.role,
    activeCompanyId: user.activeCompanyId,
  };

  const accessToken = jwt.sign(payload, process.env.JWT_ACCESS_SECRET, {
    expiresIn: process.env.JWT_ACCESS_EXPIRES || '8h',
  });

  const refreshToken = jwt.sign(
    { id: user._id },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRES || '30d' }
  );

  return { accessToken, refreshToken };
};

// ─── Registration ─────────────────────────────────────────────────────────────

const register = async ({ fullName, email, mobile, password, referralCode }) => {
  // Check uniqueness
  const existing = await User.findOne({ $or: [{ email }, { mobile }] });
  if (existing) {
    if (existing.email === email) throw Object.assign(new Error('Email already registered'), { statusCode: 409 });
    throw Object.assign(new Error('Mobile number already registered'), { statusCode: 409 });
  }

  const user = await User.create({ fullName, email, mobile, password });

  // Send verification OTP
  const emailOTP = await storeOTP(email, 'email_verify');

  // Send email OTP via email service instead of SMS
  const { sendOTPEmail } = require('../../utils/emailService');
  await sendOTPEmail(email, emailOTP, 'registration');

  logger.info(`New user registered: ${email}`);
  return { userId: user._id, message: 'OTP sent to your email for verification' };
};

// ─── OTP Verification ─────────────────────────────────────────────────────────

const verifyUserOTP = async ({ identifier, otp, purpose, type }) => {
  const result = await verifyOTP(identifier, otp, purpose);
  if (!result.valid) throw Object.assign(new Error(result.reason), { statusCode: 400 });

  if (type === '1' || type === 1) {
    const user = await User.findOne({ email: identifier });
    if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });

    const resetToken = crypto.randomBytes(32).toString('hex');
    const hashedToken = crypto.createHash('sha256').update(resetToken).digest('hex');

    user.passwordResetToken = hashedToken;
    user.passwordResetExpires = Date.now() + 10 * 60 * 1000; // 10 minutes expiry
    await user.save({ validateBeforeSave: false });

    return { message: 'OTP verified successfully', token: resetToken };
  }

  if (purpose === 'password_reset') {
    return { message: 'OTP verified successfully' };
  }

  const field = purpose === 'email_verify' ? 'isEmailVerified' : 'isMobileVerified';
  const query = purpose === 'email_verify' ? { email: identifier } : { mobile: identifier };

  await User.updateOne(query, { $set: { [field]: true } });
  return { message: 'Verified successfully' };
};

// ─── Login ────────────────────────────────────────────────────────────────────

const loginWithPassword = async ({ email, password, ipAddress, userAgent }) => {
  const user = await User.findOne({ email }).select('+password +passwordHistory');
  if (!user) throw Object.assign(new Error('Invalid email or password'), { statusCode: 401 });

  if (!user.isEmailVerified) {
    throw Object.assign(new Error('Please verify your email address before logging in'), { statusCode: 403 });
  }

  if (user.isLocked) {
    throw Object.assign(new Error('Account locked due to multiple failed attempts. Try again in 30 minutes.'), { statusCode: 423 });
  }

  const isMatch = await user.comparePassword(password);
  if (!isMatch) {
    await user.incrementLoginAttempts();
    throw Object.assign(new Error('Invalid email or password'), { statusCode: 401 });
  }

  if (!user.isActive) throw Object.assign(new Error('Account is deactivated'), { statusCode: 403 });

  await user.resetLoginAttempts();
  const { accessToken, refreshToken } = generateTokens(user);

  // Store session
  user.sessions.push({ refreshToken, device: userAgent, ipAddress });
  if (user.sessions.length > 10) user.sessions.shift(); // Keep last 10 sessions
  await user.save();

  await createAuditLog({
    userId: user._id.toString(),
    action: 'LOGIN',
    module: 'auth',
    ipAddress,
    userAgent,
  });

  return { accessToken, refreshToken, user: user.toSafeObject() };
};

const loginWithOTP = async ({ email }) => {
  const user = await User.findOne({ email });
  if (!user) throw Object.assign(new Error('Email not registered'), { statusCode: 404 });

  if (!user.isEmailVerified) {
    throw Object.assign(new Error('Please verify your email address before logging in'), { statusCode: 403 });
  }

  const otp = await storeOTP(email, 'login');
  const { sendOTPEmail } = require('../../utils/emailService');
  await sendOTPEmail(email, otp, 'login');

  return { message: 'OTP sent to your registered email address' };
};

const verifyLoginOTP = async ({ email, otp, ipAddress, userAgent }) => {
  const result = await verifyOTP(email, otp, 'login');
  if (!result.valid) throw Object.assign(new Error(result.reason), { statusCode: 400 });

  const user = await User.findOne({ email });
  if (!user || !user.isActive) throw Object.assign(new Error('User not found'), { statusCode: 404 });

  const { accessToken, refreshToken } = generateTokens(user);
  user.sessions.push({ refreshToken, device: userAgent, ipAddress });
  await user.save();

  return { accessToken, refreshToken, user: user.toSafeObject() };
};

// ─── Token Refresh ────────────────────────────────────────────────────────────

const refreshAccessToken = async (refreshToken) => {
  let decoded;
  try {
    decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
  } catch {
    throw Object.assign(new Error('Invalid or expired refresh token'), { statusCode: 401 });
  }

  const user = await User.findById(decoded.id);
  if (!user || !user.isActive) throw Object.assign(new Error('User not found'), { statusCode: 404 });

  const sessionExists = user.sessions.some(s => s.refreshToken === refreshToken);
  if (!sessionExists) throw Object.assign(new Error('Session not found'), { statusCode: 401 });

  const { accessToken, refreshToken: newRefresh } = generateTokens(user);

  // Rotate refresh token
  user.sessions = user.sessions.map(s =>
    s.refreshToken === refreshToken ? { ...s.toObject(), refreshToken: newRefresh } : s
  );
  await user.save();

  return { accessToken, refreshToken: newRefresh };
};

// ─── Logout ───────────────────────────────────────────────────────────────────

const logout = async (userId, accessToken, refreshToken) => {
  const expiresIn = 8 * 60 * 60; // 8 hours (access token TTL)
  await blacklistToken(accessToken, expiresIn);

  await User.updateOne(
    { _id: userId },
    { $pull: { sessions: { refreshToken } } }
  );
};

// ─── Password Reset ───────────────────────────────────────────────────────────

const forgotPassword = async (email) => {
  const user = await User.findOne({ email });
  if (!user) {
    throw Object.assign(new Error('User not found'), { statusCode: 404 });
  }

  // Generate 6-digit OTP for password reset
  const otp = await storeOTP(email, 'password_reset');

  // Send email OTP
  const { sendOTPEmail } = require('../../utils/emailService');
  await sendOTPEmail(email, otp, 'password_reset');

  logger.info(`Password reset OTP generated for ${email}`);
};

const resetPassword = async ({ token, password }) => {
  const hashedToken = crypto.createHash('sha256').update(token).digest('hex');
  const user = await User.findOne({
    passwordResetToken: hashedToken,
    passwordResetExpires: { $gt: Date.now() },
  }).select('+passwordHistory +password');

  if (!user) throw Object.assign(new Error('Token is invalid or has expired'), { statusCode: 400 });

  const isReused = await user.isPasswordReused(password);
  if (isReused) throw Object.assign(new Error('Cannot reuse last 1 password'), { statusCode: 400 });

  user.password = password;
  user.passwordResetToken = undefined;
  user.passwordResetExpires = undefined;
  await user.save();
};

const changePassword = async (userId, { currentPassword, newPassword }) => {
  const user = await User.findById(userId).select('+password +passwordHistory');
  if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });

  const isMatch = await user.comparePassword(currentPassword);
  if (!isMatch) throw Object.assign(new Error('Current password is incorrect'), { statusCode: 400 });

  const isReused = await user.isPasswordReused(newPassword);
  if (isReused) throw Object.assign(new Error('Cannot reuse last 1 password'), { statusCode: 400 });

  user.password = newPassword;
  await user.save();
};

const resendVerificationOTP = async (email) => {
  const user = await User.findOne({ email });
  if (!user) {
    throw Object.assign(new Error('User not found'), { statusCode: 404 });
  }

  if (user.isEmailVerified) {
    throw Object.assign(new Error('Email is already verified'), { statusCode: 400 });
  }

  // Generate new OTP
  const emailOTP = await storeOTP(email, 'email_verify');

  // Send email
  const { sendOTPEmail } = require('../../utils/emailService');
  await sendOTPEmail(email, emailOTP, 'registration');

  return { message: 'Verification OTP resent successfully' };
};

module.exports = {
  register,
  verifyUserOTP,
  loginWithPassword,
  loginWithOTP,
  verifyLoginOTP,
  refreshAccessToken,
  logout,
  forgotPassword,
  resetPassword,
  changePassword,
  resendVerificationOTP,
  generateTokens,
};
