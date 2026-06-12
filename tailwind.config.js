/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        ink: { DEFAULT: "#3B3556", dark: "#EAE6F7" },
        primary: "#A78BFA",
        pastel: {
          pink: "#FBCFE8",
          peach: "#FED7AA",
          mint: "#BBF7D0",
          sky: "#BAE6FD",
          lavender: "#DDD6FE",
          butter: "#FEF3C7",
        },
      },
    },
  },
  plugins: [],
};
