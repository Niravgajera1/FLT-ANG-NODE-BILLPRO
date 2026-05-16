const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema({
  userId:     { type: String, required: true },
  companyId:  { type: String },
  action:     { type: String, required: true },   // CREATE | UPDATE | DELETE | VIEW | LOGIN | LOGOUT
  module:     { type: String, required: true },   // users | purchase | sales | etc.
  recordId:   { type: String },
  oldData:    { type: mongoose.Schema.Types.Mixed },
  newData:    { type: mongoose.Schema.Types.Mixed },
  ipAddress:  { type: String },
  userAgent:  { type: String },
  timestamp:  { type: Date, default: Date.now },
}, {
  // Immutable — no updates or deletes allowed on audit logs
  timestamps: false,
});

// Index for fast querying
auditLogSchema.index({ companyId: 1, timestamp: -1 });
auditLogSchema.index({ userId: 1, timestamp: -1 });
auditLogSchema.index({ module: 1, action: 1 });

const AuditLog = mongoose.model('AuditLog', auditLogSchema);

/**
 * Express middleware to auto-log write operations
 * Usage: router.post('/', auditMiddleware('purchase', 'CREATE'), controller)
 */
const auditMiddleware = (module, action) => {
  return (req, res, next) => {
    const originalJson = res.json.bind(res);

    res.json = (body) => {
      // Log only on successful responses (2xx)
      if (res.statusCode >= 200 && res.statusCode < 300 && req.user) {
        AuditLog.create({
          userId:    req.user.id,
          companyId: req.companyId,
          action,
          module,
          recordId:  body?.data?._id || body?.data?.id,
          ipAddress: req.ip || req.connection.remoteAddress,
          userAgent: req.get('User-Agent'),
        }).catch(err => console.error('Audit log error:', err));
      }
      return originalJson(body);
    };

    next();
  };
};

/**
 * Direct audit log creation (use in service layer for detailed logging)
 */
const createAuditLog = async (data) => {
  try {
    await AuditLog.create(data);
  } catch (err) {
    console.error('Audit log creation failed:', err.message);
  }
};

module.exports = { AuditLog, auditMiddleware, createAuditLog };
