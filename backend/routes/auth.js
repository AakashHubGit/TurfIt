require("dotenv").config();
const express = require("express");
const User = require("../model/User");
const OffUser = require("../model/OffUser");
const Admin = require("../model/Admin");
const bcrypt = require("bcryptjs");
const { body, validationResult } = require("express-validator");
var jwt = require("jsonwebtoken");
const fetchuser = require("../middleware/fetchUser");
const fetchadmin = require("../middleware/fetchAdmin");
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

router.get("/getoffuser/:id", async (req, res) => {
  try {
    const user = await OffUser.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    res.json(user);
  } catch (error) {
    console.error(error.message);
    res.status(500).send("Unexpected error occurred");
  }
});

router.get("/offusers", async (req, res) => {
  try {
    const offUsers = await OffUser.find({}, "name number"); // Select only 'name' and 'number' fields
    res.json(offUsers);
  } catch (error) {
    console.error("Error fetching OffUsers:", error);
    res.status(500).json({ message: "Internal server error" });
  }
});

router.post(
  "/createadmin",
  [
    // Validating Admin Details
    body("email", "Enter a valid email").isEmail(),
    body("name", "Username should have minimum 3 characters").isLength({
      min: 3,
    }),
    body("password", "Password should have minimum 6 characters").isLength({
      min: 6,
    }),
  ],
  async (req, res) => {
    let success = false;

    // Checking for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log(errors);
      return res.status(400).json({ success, errors: errors.array() });
    }

    const { email, name, password } = req.body;

    try {
      // Check if admin with the same email already exists
      let admin = await Admin.findOne({ email });
      if (admin) {
        return res
          .status(400)
          .json({ success, error: "This email is already in use" });
      }

      // Hash the password
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(password, salt);

      // Create a new admin
      admin = await Admin.create({
        name,
        email,
        password: hashedPassword,
      });

      // Generate JWT token
      const data = { admin: { id: admin.id } };
      const authToken = jwt.sign(data, process.env.JWT_SECRET);
      success = true;
      res.json({ success, authToken, data });
    } catch (error) {
      console.error(error.message);
      res.status(500).send("Unexpected error occurred");
    }
  }
);

router.post(
  "/loginadmin",
  [
    // Validating Admin Login Details
    body("email", "Enter a valid email").isEmail(),
    body("password", "Password cannot be empty").exists(),
  ],
  async (req, res) => {
    let success = false;

    // Checking for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success, errors: errors.array() });
    }

    const { email, password } = req.body;
    console.log(email);
    try {
      // Check if admin exists
      const admin = await Admin.findOne({ email });
      if (!admin) {
        return res.status(400).json({ success, error: "Invalid credentials" });
      }

      // Check if passwords match
      const isMatch = await bcrypt.compare(password, admin.password);
      if (!isMatch) {
        return res.status(400).json({ success, error: "Invalid credentials" });
      }

      // Generate JWT token
      const data = { admin: { id: admin.id } };
      const authtoken = jwt.sign(data, process.env.JWT_SECRET);
      success = true;
      res.json({ success, authtoken });
    } catch (error) {
      console.error(error.message);
      res.status(500).send("Unexpected error occurred");
    }
  }
);

// Route 3: Get Admin Details
router.get("/getadmin", fetchadmin, async (req, res) => {
  try {
    // Fetch admin details
    adminId = req.admin.id;
    const admin = await Admin.findById(adminId).select("-password");
    console.log(admin);
    res.json(admin);
  } catch (error) {
    console.error(error.message);
    res.status(500).send(`Unexpected error occurred ${req.admin}`);
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
