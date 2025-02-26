require("dotenv").config();
const jwt = require("jsonwebtoken");

const fetchUser = (req, res, next) => {
  // Get the user from the JWT token and add id to the request
  const token = req.header("authToken");

  if (!token) {
    return res.status(401).json({ error: "Please provide a valid token" });
  }

  try {
    const data = jwt.verify(token, process.env.JWT_SECRET);
    req.user = data.user;
    console.log(req.user);
    next();
  } catch (error) {
    console.error(error.message);
    res.status(401).json({ error: "Token verification failed" });
  }
};

module.exports = fetchUser;
