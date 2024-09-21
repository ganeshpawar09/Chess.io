import mongoose from "mongoose";
const Schema = mongoose.Schema;

// Define the schema for individual moves
const MoveSchema = new Schema({
  moveNumber: {
    type: Number,
    required: true,
  },
  from: {
    type: String,
    required: true,
  },
  to: {
    type: String,
    required: true,
  },
  piece: {
    type: String,
    required: true,
  },
  capturedPiece: {
    type: String,
    default: null,
  },
  timestamp: {
    type: Date,
    required: true,
  },
});

// Define the main Game schema
const GameSchema = new Schema({
  playerWhite: {
    type: Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  playerBlack: {
    type: Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  whiteWin: {
    type: Number,
    default: 0,
  },
  whiteDraw: {
    type: Number,
    default: 0,
  },
  whiteLose: {
    type: Number,
    default: 0,
  },
  whiteLan: {
    type: String,
    default: "English",
  },
  blackLan: {
    type: String,
    default: "English",
  },
  blackWin: {
    type: Number,
    default: 0,
  },
  blackLose: {
    type: Number,
    default: 0,
  },
  blackDraw: {
    type: Number,
    default: 0,
  },
  currentTurn: {
    type: String,
    enum: ["white", "black"],
    required: true,
  },
  startTime: {
    type: Date,
    default: Date.now,
  },
  endTime: {
    type: Date,
    default: null,
  },
  gameIsOver: {
    type: Boolean,
    default: false,
  },
  moves: [MoveSchema],
  gameType: {
    type: String,
    enum: ["bullet", "blitz", "rapid"],
    required: true,
  },
  chessBoardState: {
    type: String,
    required: true,
  },
  result: {
    type: String,
    enum: ["white_win", "black_win", "draw", "abandoned"],
  },
  chat: [
    {
      type: Schema.Types.ObjectId,
      ref: "Chat",
    },
  ],
});

export const Game = mongoose.model("Game", GameSchema);
