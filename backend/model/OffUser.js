const mongoose = require("mongoose");
const { Schema } = mongoose;

const UserSchema = new Schema({
  name: {
    type: String,
    required: true,
  },
  number: {
    type: Number,
    required: false,
  },
  date: {
    type: Date,
    default: Date.now,
  },
});
const OffUser = mongoose.model("offuser", UserSchema);

module.exports = OffUser;
