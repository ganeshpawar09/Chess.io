import asyncHandler from "express-async-handler";
import User from "../models/User.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { ApiError } from "../utils/ApiError.js";
import bcrypt from "bcryptjs";

// Helper function to generate access token
const generateAccessToken = async (userId) => {
  try {
    const user = await User.findById(userId);
    const AccessToken = user.generateAccessToken(); // Assuming this method is defined in your schema
    user.accessToken = AccessToken;
    await user.save({ validateBeforeSave: false });
    return AccessToken;
  } catch (error) {
    throw new ApiError(
      500,
      "Something went wrong while generating Access Token"
    );
  }
};

// Signup functionality
export const signup = asyncHandler(async (req, res) => {
  const { username, email, password, country, languagePreferred } = req.body;

  const existingUser = await User.findOne({ email });
  if (existingUser) {
    throw new ApiError(400, "User already exists with this email");
  }

  const hashedPassword = await bcrypt.hash(password, 10);
  const user = await User.create({
    username,
    email,
    password: hashedPassword,
    country,
    languagePreferred,
  });

  const AccessToken = await generateAccessToken(user._id);

  res
    .status(201)
    .json(
      new ApiResponse(201, { user, AccessToken }, "User created successfully")
    );
});

// Login functionality
export const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  const user = await User.findOne({ email });
  if (!user || !(await bcrypt.compare(password, user.password))) {
    throw new ApiError(401, "Invalid email or password");
  }

  const AccessToken = await generateAccessToken(user._id);

  res
    .status(200)
    .json(new ApiResponse(200, { user, AccessToken }, "Login successful"));
});

// Get user profile by username
export const getUserProfile = asyncHandler(async (req, res) => {
  const { username } = req.params;
  const user = await User.findOne({ username })
    .populate("friends")
    .populate("opponentHistory.opponentId");
  if (!user) {
    throw new ApiError(404, "User not found");
  } else {
    res.status(200).json(new ApiResponse(200, user));
  }
});

// Update user profile
export const updateUserProfile = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const updateData = req.body;
  const user = await User.findByIdAndUpdate(userId, updateData, { new: true });
  if (!user) {
    throw new ApiError(404, "User not found");
  } else {
    res.status(200).json(new ApiResponse(200, user));
  }
});

// Delete user
export const deleteUser = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const user = await User.findByIdAndDelete(userId);
  if (!user) {
    throw new ApiError(404, "User not found");
  } else {
    res
      .status(200)
      .json(new ApiResponse(200, null, "User deleted successfully"));
  }
});

// Get all users
export const getAllUsers = asyncHandler(async (req, res) => {
  const users = await User.find()
    .populate("friends")
    .populate("opponentHistory.opponentId");
  res.status(200).json(new ApiResponse(200, users));
});

// Add a friend
export const addFriend = asyncHandler(async (req, res) => {
  const { userId, friendId } = req.body;
  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(404, "User not found");
  }
  user.friends.push(friendId);
  await user.save();
  res.status(200).json(new ApiResponse(200, user));
});

// Update game stats
export const updateGameStats = asyncHandler(async (req, res) => {
  const { userId, gameType, stats } = req.body;
  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(404, "User not found");
  }
  user.gameStats[gameType] = stats;
  await user.save();
  res.status(200).json(new ApiResponse(200, user));
});
