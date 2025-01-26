require("dotenv").config();
const express = require("express");
const User = require("../model/User");
const bcrypt = require("bcryptjs");
const { body, validationResult } = require("express-validator");
var jwt = require("jsonwebtoken");
const fetchuser = require("../middleware/fetchUser");
const router = express.Router();
const url = process.env.BASE_URL;

router.use(express.json());

router.post(
  "/createuser",
  [
    //Validating User Details
    body("email", "Enter a valid e-mail").isEmail(),
    body("name", "Username: minimum 3 characters").isLength({ min: 3 }),
    body("password", "Password: minimum 6 characters").isLength({ min: 6 }),
  ],
  async (req, res) => {
    let success = false;
    //If there are errors , return bad requests and also errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success, errors: errors.array() });
    }
    //Check if the email already exists
    try {
      let user = await User.findOne({ email: req.body.email });
      if (user) {
        return res.status(400).json({ error: "This email is already in use" });
      }
      const salt = await bcrypt.genSalt(10);

      secPass = await bcrypt.hash(req.body.password, salt);
      //Create User
      user = await User.create({
        name: req.body.name,
        email: req.body.email,
        number: req.body.number,
        password: secPass,
      });
      const data = {
        user: {
          id: user.id,
        },
      };
      const authToken = jwt.sign(data, process.env.JWT_SECRET);
      success = true;
      // res.json(user)
      res.json({ success, authToken: authToken });
    } catch (error) {
      //Display Errors
      console.error(error.message);
      res.status(500).send("Unexpected error occurred ");
    }
  }
);

router.post(
  "/loginuser",
  [
    //Validating User Details
    body("email", "Enter a valid e-mail").isEmail(),
    body("password", "Password cannot be empty").exists(),
  ],
  async (req, res) => {
    let success = false;
    //If there are errors , return bad requests and also errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    const { email, password } = req.body;
    try {
      let user = await User.findOne({ email });
      if (!user) {
        return res.status(400).json({ success, error: "Wrong Credentials" });
      }

      const passCompare = await bcrypt.compare(password, user.password);
      if (!passCompare) {
        success = false;
        return res.status(400).json({ success, error: "Wrong Credentials" });
      }
      const data = {
        user: {
          id: user.id,
        },
      };
      const authtoken = jwt.sign(data, process.env.JWT_SECRET);
      success = true;
      res.json({ success, authtoken });
    } catch (error) {
      console.error(error.message);
      res.status(500).send("Unexpected error occurred ");
    }
  }
);

router.put("/updatenumber", fetchuser, async (req, res) => {
  const { number } = req.body;

  try {
    // Find the user by their ID
    let user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Update the number attribute
    user.number = number;

    // Save the updated user
    await user.save();

    res.json({ success: true, message: "Number updated successfully" });
  } catch (error) {
    console.error(error.message);
    res.status(500).send("Unexpected error occurred");
  }
});

router.get("/getuser/:id", async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    res.json(user);
  } catch (error) {
    console.error(error.message);
    res.status(500).send("Unexpected error occurred");
  }
});

router.post("/decode", (req, res) => {
  const { authToken, userId } = req.body; // Access userId from the request body
  console.log(authToken);
  console.log(userId); // Log userId
  // Verify and decode the JWT token
  try {
    const decodedToken = jwt.decode(authToken, { complete: true });
    res.json(decodedToken);
  } catch (error) {
    res.status(400).json({ error: "Invalid JWT token" });
  }
});

module.exports = router;
