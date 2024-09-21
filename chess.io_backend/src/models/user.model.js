import mongoose from "mongoose";

const userSchema = new mongoose.Schema({
  socketId: {
    type: String,
  },
  username: {
    type: String,
    unique: true,
    required: true,
  },
  email: {
    type: String,
    unique: true,
    required: true,
  },
  password: {
    type: String,
    required: true,
  },
  profilePicture: {
    type: String,
  },
  bio: {
    type: String,
  },
  joinedAt: {
    type: Date,
    default: Date.now,
  },
  lastLogin: {
    type: Date,
  },
  isOnline: {
    type: Boolean,
    default: false,
  },
  role: {
    type: String,
    enum: ["user", "admin"],
    default: "user",
  },
  languagePreferred: {
    type: String,
  },
  country: {
    type: String,
  },
  followers: {
    type: Number,
    default: 0,
  },
  profileViews: {
    type: Number,
    default: 0,
  },
  waiting: {
    type: Boolean,
    default: false,
  },
  accessToken: {
    type: String,
  },
  friends: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
  ],
  opponentHistory: [
    {
      opponentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
      winCount: {
        type: Number,
        default: 0,
      },
      loseCount: {
        type: Number,
        default: 0,
      },
      drawCount: {
        type: Number,
        default: 0,
      },
    },
  ],
  pastMatches: [
    {
      gameId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Game",
      },
      opponentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
      result: {
        type: String,
        enum: ["win", "lose", "draw"],
      },
      date: {
        type: Date,
      },
      totalMoves: {
        type: Number,
      },
      gameType: {
        type: String,
        enum: ["bullet", "blitz", "rapid"],
      },
      ratingChange: {
        type: Number,
      },
    },
  ],
  gameStats: {
    bullet: {
      currentRating: {
        type: Number,
        default: 0,
      },
      highestRating: {
        type: Number,
        default: 0,
      },
      highestRatedOpponentWin: {
        type: Number,
      },
      dailyRecords: [
        {
          date: {
            type: Date,
          },
          winCount: {
            type: Number,
            default: 0,
          },
          loseCount: {
            type: Number,
            default: 0,
          },
          drawCount: {
            type: Number,
            default: 0,
          },
        },
      ],
    },
    blitz: {
      currentRating: {
        type: Number,
        default: 0,
      },
      highestRating: {
        type: Number,
        default: 0,
      },
      highestRatedOpponentWin: {
        type: Number,
      },
      dailyRecords: [
        {
          date: {
            type: Date,
          },
          winCount: {
            type: Number,
            default: 0,
          },
          loseCount: {
            type: Number,
            default: 0,
          },
          drawCount: {
            type: Number,
            default: 0,
          },
        },
      ],
    },
    rapid: {
      currentRating: {
        type: Number,
        default: 0,
      },
      highestRating: {
        type: Number,
        default: 0,
      },
      highestRatedOpponentWin: {
        type: Number,
      },
      dailyRecords: [
        {
          date: {
            type: Date,
          },
          winCount: {
            type: Number,
            default: 0,
          },
          loseCount: {
            type: Number,
            default: 0,
          },
          drawCount: {
            type: Number,
            default: 0,
          },
        },
      ],
    },
  },
  lastGame: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Game",
  },
  lastGameStatus: {
    type: String,
    enum: ["ongoing", "completed"],
  },
});
userSchema.methods.generateAccessToken = function () {
  return jwt.sign(
    {
      _id: this._id,
      username: this.username,
      email: this.email,
    },
    process.env.ACCESS_TOKEN_SECRET,
    {
      expiresIn: process.env.ACCESS_TOKEN_EXPIRY,
    }
  );
};

export const User = mongoose.model("User", userSchema);
