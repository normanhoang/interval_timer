import Foundation

enum Encouragements {
    static let all: [String] = [
        "You're a beast!",
        "Absolutely crushed it!",
        "That's the spirit!",
        "You're on fire! 🔥",
        "Phenomenal effort!",
        "Pure determination right there!",
        "You earned that sweat!",
        "That's champion-level work!",
        "Look at you go!",
        "You're unstoppable!",
        "Incredible intensity!",
        "Keep that energy going!",
        "You're stronger than yesterday!",
        "That was next level!",
        "Absolutely killing it!",
        "Your body's a temple!",
        "Pure power and grace!",
        "You're a fitness machine!",
        "That's what dedication looks like!",
        "You just leveled up!",
        "Superhero strength right there!",
        "That's the kind of grit that wins!",
        "You're glowing with that glow-up!",
        "Pure velocity and heart!",
        "You're writing your own success story!",
        "That's legendary effort!",
        "You're building an empire!",
        "Nothing can stop you!",
        "You just proved what's possible!",
        "That's the definition of a champion!",
    ]

    static func random() -> String {
        all.randomElement() ?? all[0]
    }
}
