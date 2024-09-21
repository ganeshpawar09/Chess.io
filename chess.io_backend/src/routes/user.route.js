import { Router } from "express";
import {
  signup,
  login,
  getUserProfile,
  updateUserProfile,
  deleteUser,
  getAllUsers,
  addFriend,
  updateGameStats,
} from "../controllers/userController.js";

const userRouter = Router();

// Signup
userRouter.post("/signup", signup);

// Login
userRouter.post("/login", login);

// Get user profile by username
userRouter.get("/users/:username", getUserProfile);

// Update user profile
userRouter.put("/users/:userId", updateUserProfile);

// Delete user
userRouter.delete("/users/:userId", deleteUser);

// Get all users
userRouter.get("/users", getAllUsers);

// Add a friend
userRouter.post("/users/friends", addFriend);

// Update game stats
userRouter.put("/users/stats", updateGameStats);

export default userRouter;
