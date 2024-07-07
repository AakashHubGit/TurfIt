require("dotenv").config();
const mongoose = require("mongoose");
const mongoURI = process.env.MONGO_URI;

const connectToMongo = async () => {
  mongoose
    .connect(mongoURI)
    .then(() => {
      console.log("success");
    })
    .catch((err) => {
      console.log(err);
    });
};

module.exports = connectToMongo;

// MONGO_URI= mongodb+srv://teamprojects2902:startup@cluster0.wccp0eu.mongodb.net/turfit?retryWrites=true&w=majority&appName=Cluster0
// BASE_URL = http://localhost:3000
// JWT_SECRET= BookTurfFromTurfit
// TWILIO_SID= ACdf0e2267b88a3eec8cf294c267bd2dbf
// TWILIO_AUTH= 6003ae468973c7545e4feacff38a761d
