/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        ink: { DEFAULT: "#3B3556", dark: "#EAE6F7" },
        primary: "#A78BFA",
        interval: {
          coral: "#F38181",
          yellow: "#FCE38A",
          mint: "#EAFFD0",
          aqua: "#95E1D3",
          sky: "#A8D8EA",
          lavender: "#C9B6E4",
        },
      },
    },
  },
  plugins: [],
};
