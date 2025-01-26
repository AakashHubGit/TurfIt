const mongoose = require("mongoose");
const { Schema } = mongoose;

const UserSchema = new Schema({
  name: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },
  password: {
    type: String,
    required: true,
  },
  number: {
    type: String,
    required: false,
  },
  date: {
    type: Date,
    default: Date.now,
  },
  adminId: {
    type: [mongoose.Schema.Types.ObjectId],
    ref: "admin",
    required: false,
  },
});
const User = mongoose.model("user", UserSchema);

module.exports = User;
