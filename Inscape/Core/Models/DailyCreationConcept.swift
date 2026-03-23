// DailyCreationConcept.swift

import Foundation

struct DailyCreationConcept: Identifiable {
    let id = UUID()
    let name: String
    let prompt: String
    let reflection: String

    static let all: [DailyCreationConcept] = [
        // Emotions & Regulation
        DailyCreationConcept(
            name: "Calm in the storm",
            prompt: "Create an image of calmness that can exist even within a storm.",
            reflection: "Where do you find calm when life feels chaotic?"
        ),
        DailyCreationConcept(
            name: "The shape of joy",
            prompt: "Imagine joy as a shape or symbol and bring it to life.",
            reflection: "What small things spark joy for you today?"
        ),
        DailyCreationConcept(
            name: "A safe space for sadness",
            prompt: "Design a safe container where sadness can rest without judgment.",
            reflection: "How do you give yourself space to feel sadness without trying to fix or avoid it?"
        ),
        DailyCreationConcept(
            name: "Anger as fire, but contained",
            prompt: "Visualize anger as a fire — powerful but safely held.",
            reflection: "What healthy ways do you release anger?"
        ),
        DailyCreationConcept(
            name: "Waves of anxiety flowing and fading",
            prompt: "Create waves that rise and then gently fade into calm water.",
            reflection: "What helps your worries fade over time?"
        ),
        DailyCreationConcept(
            name: "Gratitude as a growing garden",
            prompt: "Illustrate gratitude as a colorful garden that grows when tended.",
            reflection: "What is one thing you are grateful for today?"
        ),
        DailyCreationConcept(
            name: "Hope as a rising sun",
            prompt: "Show hope as a bright sun emerging over the horizon.",
            reflection: "Where in your life do you feel hope shining through?"
        ),
        DailyCreationConcept(
            name: "The balance of light and dark",
            prompt: "Create an image with both light and shadow in harmony.",
            reflection: "How do you balance the good and difficult parts of life?"
        ),
        DailyCreationConcept(
            name: "Loneliness as an empty room or open field",
            prompt: "Visualize loneliness as a space — vast, empty, or waiting.",
            reflection: "What do you wish could enter that space?"
        ),
        DailyCreationConcept(
            name: "The colors of curiosity",
            prompt: "Bring curiosity to life as colors exploring a canvas.",
            reflection: "What are you most curious about right now?"
        ),
        // Resilience & Strength
        DailyCreationConcept(
            name: "A mountain that cannot be moved",
            prompt: "Create a mountain that stands strong no matter the weather.",
            reflection: "What gives you strength when life tests you?"
        ),
        DailyCreationConcept(
            name: "The bridge across challenges",
            prompt: "Show a bridge carrying you across difficulties to the other side.",
            reflection: "What helps you cross tough times?"
        ),
        DailyCreationConcept(
            name: "A broken object made whole",
            prompt: "Visualize something cracked, mended with golden light.",
            reflection: "What parts of you have grown stronger after breaking?"
        ),
        DailyCreationConcept(
            name: "Rising from ashes",
            prompt: "Show renewal as something beautiful emerging from ashes.",
            reflection: "What in your life is ready to be renewed?"
        ),
        DailyCreationConcept(
            name: "The shield of resilience",
            prompt: "Design a shield made of colors, symbols, or textures of strength.",
            reflection: "What protects your well-being?"
        ),
        DailyCreationConcept(
            name: "Roots deep underground",
            prompt: "Illustrate strong roots anchoring beneath the surface.",
            reflection: "What anchors you when life feels unstable?"
        ),
        DailyCreationConcept(
            name: "The lighthouse guiding through fog",
            prompt: "Show a lighthouse sending light through confusion.",
            reflection: "Who or what is your guiding light?"
        ),
        DailyCreationConcept(
            name: "The tree that bends but does not break",
            prompt: "Visualize a tree swaying but standing tall in a storm.",
            reflection: "How have you been flexible yet strong?"
        ),
        DailyCreationConcept(
            name: "Climbing the next step on the ladder",
            prompt: "Create an image of a ladder or steps leading upward.",
            reflection: "What is your next step forward?"
        ),
        DailyCreationConcept(
            name: "An armor of kindness",
            prompt: "Imagine armor not of steel, but of compassion and kindness.",
            reflection: "How does kindness make you stronger?"
        ),
        // Identity & Self-Discovery
        DailyCreationConcept(
            name: "The mirror that reflects your inner self",
            prompt: "Show a mirror that reveals not your face, but your essence.",
            reflection: "What do you see when you look inward?"
        ),
        DailyCreationConcept(
            name: "The path of your journey",
            prompt: "Create a winding path that represents your life journey.",
            reflection: "Where have you come from, and where are you going?"
        ),
        DailyCreationConcept(
            name: "The mask you wear and the face beneath",
            prompt: "Visualize a mask being lifted to reveal your true self.",
            reflection: "When do you feel most authentic?"
        ),
        DailyCreationConcept(
            name: "A map of your emotions",
            prompt: "Turn your current feelings into a map or landscape.",
            reflection: "Where are you on that map today?"
        ),
        DailyCreationConcept(
            name: "The many colors of your personality",
            prompt: "Show yourself as a spectrum of colors and patterns.",
            reflection: "What parts of you shine brightest right now?"
        ),
        DailyCreationConcept(
            name: "The child within",
            prompt: "Visualize your inner child as a character, symbol, or place.",
            reflection: "What does your inner child need today?"
        ),
        DailyCreationConcept(
            name: "The symbol that represents you",
            prompt: "Create a personal symbol that feels like 'you.'",
            reflection: "Why did you choose this symbol?"
        ),
        DailyCreationConcept(
            name: "A crossroads of choices",
            prompt: "Show a crossroads where different paths unfold.",
            reflection: "What choices are you facing now?"
        ),
        DailyCreationConcept(
            name: "Who am I today?",
            prompt: "Visualize yourself as you feel right now, through shapes or colors.",
            reflection: "What word best describes yourself today?"
        ),
        DailyCreationConcept(
            name: "The future self calling you forward",
            prompt: "Show an image of your future self reaching out to you.",
            reflection: "What qualities do you want to grow into?"
        ),
        // Connection & Relationships
        DailyCreationConcept(
            name: "A circle of support",
            prompt: "Visualize your circle of people who support you.",
            reflection: "Who is in your circle right now?"
        ),
        DailyCreationConcept(
            name: "The string that ties two people together",
            prompt: "Show an invisible string that connects hearts.",
            reflection: "Who do you feel most connected to?"
        ),
        DailyCreationConcept(
            name: "Building a bridge between hearts",
            prompt: "Create a bridge of compassion between two people.",
            reflection: "What bridges do you want to build?"
        ),
        DailyCreationConcept(
            name: "The dance of give and take",
            prompt: "Show connection as a dance of balance.",
            reflection: "Where in your life do you give and receive?"
        ),
        DailyCreationConcept(
            name: "A hug turned into colors",
            prompt: "Visualize the feeling of a hug as colors and textures.",
            reflection: "When was the last time you felt truly held?"
        ),
        DailyCreationConcept(
            name: "The shared flame of friendship",
            prompt: "Show friendship as a flame shared between candles.",
            reflection: "Who brings warmth to your life?"
        ),
        DailyCreationConcept(
            name: "Community as a woven tapestry",
            prompt: "Visualize community as a tapestry of threads.",
            reflection: "What threads connect you to others?"
        ),
        DailyCreationConcept(
            name: "Two trees growing side by side",
            prompt: "Show two trees growing together with roots intertwined.",
            reflection: "What relationships help you grow?"
        ),
        DailyCreationConcept(
            name: "Healing through connection",
            prompt: "Visualize connection as a force that heals.",
            reflection: "Who helps you heal?"
        ),
        DailyCreationConcept(
            name: "A hand reaching out of the darkness",
            prompt: "Show a hand reaching toward light or connection.",
            reflection: "When have you reached out or been reached for?"
        ),
        // Mindfulness & Healing
        DailyCreationConcept(
            name: "The breath as a flowing river",
            prompt: "Visualize each breath as a flowing river.",
            reflection: "What helps you return to your breath?"
        ),
        DailyCreationConcept(
            name: "Mandala of the present moment",
            prompt: "Create a mandala that captures this moment.",
            reflection: "What do you notice right now in your body or mind?"
        ),
        DailyCreationConcept(
            name: "The calm lake of awareness",
            prompt: "Show awareness as a still, calm lake.",
            reflection: "How does calmness show up in your life?"
        ),
        DailyCreationConcept(
            name: "Letting go as falling leaves",
            prompt: "Visualize letting go as autumn leaves drifting away.",
            reflection: "What could you release today?"
        ),
        DailyCreationConcept(
            name: "The healing light within",
            prompt: "Create an image of light shining from inside you.",
            reflection: "Where do you feel your inner strength?"
        ),
        DailyCreationConcept(
            name: "Silence as a soft blanket",
            prompt: "Show silence as something soft and comforting.",
            reflection: "How do you find moments of silence?"
        ),
        DailyCreationConcept(
            name: "The garden of inner peace",
            prompt: "Visualize peace as a garden within you.",
            reflection: "What grows in your inner garden?"
        ),
        DailyCreationConcept(
            name: "Body as a temple, mind as a sky",
            prompt: "Show your body as a temple and your mind as open sky.",
            reflection: "What practices honor your body and mind?"
        ),
        DailyCreationConcept(
            name: "The cycle of sleep and renewal",
            prompt: "Visualize rest as a cycle of night and renewal.",
            reflection: "What restores you most deeply?"
        ),
        DailyCreationConcept(
            name: "The wave that carries stress away",
            prompt: "Show stress being carried out to sea by a gentle wave.",
            reflection: "What helps you let stress go?"
        ),
    ]
}
