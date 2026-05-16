const Joi = require('joi');

const passwordRule = Joi.string()
  .min(8)
  .max(100)
  .pattern(/^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?])/)
  .messages({
    'string.pattern.base': 'Password must have at least 1 uppercase letter, 1 number, and 1 special character',
    'string.min': 'Password must be at least 8 characters',
  });

const schemas = {
  register: Joi.object({
    fullName:     Joi.string().min(3).max(100).required(),
    email:        Joi.string().email().required(),
    mobile:       Joi.string().pattern(/^[6-9]\d{9}$/).required().messages({
      'string.pattern.base': 'Enter a valid 10-digit Indian mobile number',
    }),
    password:     passwordRule.required(),
    confirmPassword: Joi.string().valid(Joi.ref('password')).required().messages({
      'any.only': 'Passwords do not match',
    }),
    referralCode: Joi.string().optional().allow(''),
    acceptTerms:  Joi.boolean().valid(true).required().messages({
      'any.only': 'You must accept the terms and conditions',
    }),
  }),

  verifyOTP: Joi.object({
    identifier: Joi.string().required(),
    otp:        Joi.string().length(6).pattern(/^\d+$/).required(),
    purpose:    Joi.string().valid('email_verify', 'mobile_verify', 'login', 'password_reset').required(),
  }),

  login: Joi.object({
    email:    Joi.string().email().required(),
    password: Joi.string().required(),
  }),

  loginOTP: Joi.object({
    mobile: Joi.string().pattern(/^[6-9]\d{9}$/).required(),
  }),

  forgotPassword: Joi.object({
    email: Joi.string().email().required(),
  }),

  resetPassword: Joi.object({
    token:           Joi.string().required(),
    password:        passwordRule.required(),
    confirmPassword: Joi.string().valid(Joi.ref('password')).required(),
  }),

  changePassword: Joi.object({
    currentPassword: Joi.string().required(),
    newPassword:     passwordRule.required(),
    confirmPassword: Joi.string().valid(Joi.ref('newPassword')).required(),
  }),
};

const validate = (schema) => (req, res, next) => {
  const { error } = schema.validate(req.body, { abortEarly: false });
  if (error) {
    return res.status(422).json({
      success: false,
      message: 'Validation failed',
      errors: error.details.map(d => ({ field: d.path.join('.'), message: d.message })),
    });
  }
  next();
};

module.exports = { schemas, validate };
