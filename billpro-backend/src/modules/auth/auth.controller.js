const authService = require("./auth.service");
const {
  sendSuccess,
  sendCreated,
  sendError,
} = require("../../utils/responseHelper");

const register = async (req, res, next) => {
  try {
    const result = await authService.register(req.body);
    return sendCreated(
      res,
      result,
      "Registration successful. Please verify your email.",
    );
  } catch (err) {
    next(err);
  }
};

const verifyOTP = async (req, res, next) => {
  try {
    const result = await authService.verifyUserOTP(req.body);
    return sendSuccess(res, result);
  } catch (err) {
    next(err);
  }
};

const login = async (req, res, next) => {
  try {
    const result = await authService.loginWithPassword({
      ...req.body,
      ipAddress: req.ip,
      userAgent: req.get("User-Agent"),
    });

    // Set refresh token in HTTP-only cookie
    res.cookie("refreshToken", result.refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
    });

    return sendSuccess(
      res,
      {
        accessToken: result.accessToken,
        user: result.user,
      },
      "Login successful",
    );
  } catch (err) {
    next(err);
  }
};

const sendLoginOTP = async (req, res, next) => {
  try {
    const result = await authService.loginWithOTP(req.body);
    return sendSuccess(res, result);
  } catch (err) {
    next(err);
  }
};

const verifyLoginOTP = async (req, res, next) => {
  try {
    const result = await authService.verifyLoginOTP({
      ...req.body,
      ipAddress: req.ip,
      userAgent: req.get("User-Agent"),
    });
    res.cookie("refreshToken", result.refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 30 * 24 * 60 * 60 * 1000,
    });
    return sendSuccess(
      res,
      { accessToken: result.accessToken, user: result.user },
      "Login successful",
    );
  } catch (err) {
    next(err);
  }
};

const refreshToken = async (req, res, next) => {
  try {
    const token = req.cookies?.refreshToken || req.body?.refreshToken;
    if (!token)
      return res
        .status(401)
        .json({ success: false, message: "Refresh token required" });

    const result = await authService.refreshAccessToken(token);
    res.cookie("refreshToken", result.refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 30 * 24 * 60 * 60 * 1000,
    });
    return sendSuccess(res, { accessToken: result.accessToken });
  } catch (err) {
    next(err);
  }
};

const logout = async (req, res, next) => {
  try {
    const refreshToken = req.cookies?.refreshToken;
    await authService.logout(req.user.id, req.token, refreshToken);
    res.clearCookie("refreshToken");
    return sendSuccess(res, {}, "Logged out successfully");
  } catch (err) {
    next(err);
  }
};

const forgotPassword = async (req, res, next) => {
  try {
    await authService.forgotPassword(req.body.email);
    return sendSuccess(
      res,
      {},
      "If this email is registered, a reset link has been sent.",
    );
  } catch (err) {
    next(err);
  }
};

const resetPassword = async (req, res, next) => {
  try {
    await authService.resetPassword(req.body);
    return sendSuccess(res, {}, "Password reset successfully");
  } catch (err) {
    next(err);
  }
};

const changePassword = async (req, res, next) => {
  try {
    await authService.changePassword(req.user.id, req.body);
    return sendSuccess(res, {}, "Password changed successfully");
  } catch (err) {
    next(err);
  }
};

const getMe = async (req, res, next) => {
  try {
    const User = require("../users/user.model");
    const user = await User.findById(req.user.id).populate(
      "companies.companyId",
      "legalName tradeName gstin logoUrl",
    );
    if (!user)
      return res
        .status(404)
        .json({ success: false, message: "User not found" });
    return sendSuccess(res, user.toSafeObject());
  } catch (err) {
    next(err);
  }
};

module.exports = {
  register,
  verifyOTP,
  login,
  sendLoginOTP,
  verifyLoginOTP,
  refreshToken,
  logout,
  forgotPassword,
  resetPassword,
  changePassword,
  getMe,
};
