const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const { ROLES } = require('../../config/constants');

const sessionSchema = new mongoose.Schema({
  refreshToken: { type: String },
  device: { type: String },
  ipAddress: { type: String },
  lastActive: { type: Date, default: Date.now },
  createdAt: { type: Date, default: Date.now },
}, { _id: true });

const userSchema = new mongoose.Schema({
  fullName: { type: String, required: true, trim: true, minlength: 3, maxlength: 100 },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  mobile: { type: String, required: true, unique: true, match: /^[6-9]\d{9}$/ },
  password: { type: String, required: true, select: false },
  passwordHistory: { type: [String], select: false, default: [] },

  role: { type: String, enum: Object.values(ROLES), default: ROLES.COMPANY_ADMIN },
  isEmailVerified: { type: Boolean, default: false },
  isMobileVerified: { type: Boolean, default: false },
  isActive: { type: Boolean, default: true },

  // Active company context
  activeCompanyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Company' },

  // Companies this user belongs to
  companies: [{
    companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Company' },
    role: { type: String, enum: Object.values(ROLES) },
    isOwner: { type: Boolean, default: false },
  }],

  // Security
  loginAttempts: { type: Number, default: 0 },
  lockUntil: { type: Date },
  sessions: [sessionSchema],

  // Password reset
  passwordResetToken: { type: String, select: false },
  passwordResetExpires: { type: Date, select: false },

  // Referral
  referralCode: { type: String },
  referredBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

  // OAuth
  googleId: { type: String },

  // Onboarding
  onboardingCompleted: { type: Boolean, default: false },

}, { timestamps: true });

// ─── Indexes ──────────────────────────────────────────────────────────────────
userSchema.index({ 'companies.companyId': 1 });

// ─── Virtual: is account locked ───────────────────────────────────────────────
userSchema.virtual('isLocked').get(function () {
  return !!(this.lockUntil && this.lockUntil > Date.now());
});

// ─── Pre-save: hash password ──────────────────────────────────────────────────
userSchema.pre('save', async function () {
  if (!this.isModified('password')) return;

  const salt = await bcrypt.genSalt(12);
  const hashed = await bcrypt.hash(this.password, salt);

  // Maintain password history (last 5)
  if (this.passwordHistory.length >= 5) this.passwordHistory.shift();
  this.passwordHistory.push(hashed);

  this.password = hashed;
});

// ─── Methods ──────────────────────────────────────────────────────────────────
userSchema.methods.comparePassword = async function (candidate) {
  return bcrypt.compare(candidate, this.password);
};

userSchema.methods.isPasswordReused = async function (candidate) {
  const checks = await Promise.all(
    this.passwordHistory.map(h => bcrypt.compare(candidate, h))
  );
  return checks.some(Boolean);
};

userSchema.methods.incrementLoginAttempts = async function () {
  if (this.lockUntil && this.lockUntil < Date.now()) {
    return this.updateOne({ $set: { loginAttempts: 1 }, $unset: { lockUntil: 1 } });
  }
  const updates = { $inc: { loginAttempts: 1 } };
  if (this.loginAttempts + 1 >= 5) {
    updates.$set = { lockUntil: Date.now() + 30 * 60 * 1000 }; // 30 mins
  }
  return this.updateOne(updates);
};

userSchema.methods.resetLoginAttempts = function () {
  return this.updateOne({ $set: { loginAttempts: 0 }, $unset: { lockUntil: 1 } });
};

// ─── Safe user object (no sensitive fields) ───────────────────────────────────
userSchema.methods.toSafeObject = function () {
  const obj = this.toObject();
  delete obj.password;
  delete obj.passwordHistory;
  delete obj.passwordResetToken;
  delete obj.passwordResetExpires;
  delete obj.sessions;
  return obj;
};

const User = mongoose.model('User', userSchema);
module.exports = User;
