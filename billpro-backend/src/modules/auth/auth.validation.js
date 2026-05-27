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
    fullName: Joi.string().min(3).max(100).required().messages({
      'string.empty': 'Full name is required',
      'any.required': 'Full name is required',
      'string.min': 'Full name must be at least 3 characters',
      'string.max': 'Full name cannot exceed 100 characters',
    }),
    email: Joi.string().email().required().messages({
      'string.empty': 'Email address is required',
      'any.required': 'Email address is required',
      'string.email': 'Please enter a valid email address',
    }),
    mobile: Joi.string().pattern(/^[6-9]\d{9}$/).required().messages({
      'string.empty': 'Mobile number is required',
      'any.required': 'Mobile number is required',
      'string.pattern.base': 'Enter a valid 10-digit Indian mobile number',
    }),
    password: passwordRule.required().messages({
      'string.empty': 'Password is required',
      'any.required': 'Password is required',
    }),
    confirmPassword: Joi.string().valid(Joi.ref('password')).required().messages({
      'string.empty': 'Please confirm your password',
      'any.required': 'Please confirm your password',
      'any.only': 'Passwords do not match',
    }),
    referralCode: Joi.string().optional().allow(''),
    acceptTerms: Joi.boolean().valid(true).required().messages({
      'any.only': 'You must accept the terms and conditions',
      'any.required': 'You must accept the terms and conditions',
    }),
  }),

  verifyOTP: Joi.object({
    identifier: Joi.string().required().messages({
      'string.empty': 'Email or mobile number is required',
      'any.required': 'Email or mobile number is required',
    }),
    otp: Joi.string().length(6).pattern(/^\d+$/).required().messages({
      'string.empty': 'OTP is required',
      'any.required': 'OTP is required',
      'string.length': 'OTP must be exactly 6 digits',
      'string.pattern.base': 'OTP must only contain digits',
    }),
    purpose: Joi.string().valid('email_verify', 'mobile_verify', 'login', 'password_reset').required().messages({
      'string.empty': 'Purpose is required',
      'any.required': 'Purpose is required',
      'any.only': 'Invalid purpose type',
    }),
  }),

  login: Joi.object({
    email: Joi.string().email().required().messages({
      'string.empty': 'Email address is required',
      'any.required': 'Email address is required',
      'string.email': 'Please enter a valid email address',
    }),
    password: Joi.string().required().messages({
      'string.empty': 'Password is required',
      'any.required': 'Password is required',
    }),
  }),

  loginOTP: Joi.object({
    email: Joi.string().email().required().messages({
      'string.empty': 'Email address is required',
      'any.required': 'Email address is required',
      'string.email': 'Please enter a valid email address',
    }),
  }),

  verifyLoginOTP: Joi.object({
    email: Joi.string().email().required().messages({
      'string.empty': 'Email address is required',
      'any.required': 'Email address is required',
      'string.email': 'Please enter a valid email address',
    }),
    otp: Joi.string().length(6).pattern(/^\d+$/).required().messages({
      'string.empty': 'OTP is required',
      'any.required': 'OTP is required',
      'string.length': 'OTP must be exactly 6 digits',
      'string.pattern.base': 'OTP must only contain digits',
    }),
  }),

  forgotPassword: Joi.object({
    email: Joi.string().email().required().messages({
      'string.empty': 'Email address is required',
      'any.required': 'Email address is required',
      'string.email': 'Please enter a valid email address',
    }),
  }),

  resetPassword: Joi.object({
    token: Joi.string().required().messages({
      'string.empty': 'Reset token is required',
      'any.required': 'Reset token is required',
    }),
    password: passwordRule.required().messages({
      'string.empty': 'Password is required',
      'any.required': 'Password is required',
    }),
    confirmPassword: Joi.string().valid(Joi.ref('password')).required().messages({
      'string.empty': 'Please confirm your password',
      'any.required': 'Please confirm your password',
      'any.only': 'Passwords do not match',
    }),
  }),

  changePassword: Joi.object({
    currentPassword: Joi.string().required().messages({
      'string.empty': 'Current password is required',
      'any.required': 'Current password is required',
    }),
    newPassword: passwordRule.required().messages({
      'string.empty': 'New password is required',
      'any.required': 'New password is required',
    }),
    confirmPassword: Joi.string().valid(Joi.ref('newPassword')).required().messages({
      'string.empty': 'Please confirm your password',
      'any.required': 'Please confirm your password',
      'any.only': 'Passwords do not match',
    }),
  }),

  resendOTP: Joi.object({
    email: Joi.string().email().required().messages({
      'string.empty': 'Email address is required',
      'any.required': 'Email address is required',
      'string.email': 'Please enter a valid email address',
    }),
  }),
};

const validate = (schema) => (req, res, next) => {
  const { error } = schema.validate(req.body, { abortEarly: false });
  if (error) {
    return res.status(422).json({
      success: false,
      message: 'Validation failed',
      errors: error.details.map(d => ({ 
        field: d.path.join('.'), 
        message: d.message.replace(/"/g, '') 
      })),
    });
  }
  next();
};

module.exports = { schemas, validate };
