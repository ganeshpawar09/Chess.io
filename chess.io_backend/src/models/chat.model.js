import mongoose from "mongoose";

const chatSchema = new mongoose.Schema({
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  translatedMessage: {
    type: String,
  },
});

export const Chat = mongoose.model("Chat", chatSchema);
